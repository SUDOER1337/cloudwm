#include <ncurses.h>
#include <SDL2/SDL.h>
#include <SDL2/SDL_mixer.h>
#include <stdlib.h>
#include <string.h>
#include <dirent.h>
#include <unistd.h>
#include <sys/stat.h>
#include <ctype.h>

#define ROWS 16
#define COLS 5
#define WAV_NAME_LEN 256
#define BPM 120
#define RECENT_MAX 9

typedef struct {
    char wav_file[WAV_NAME_LEN];
    int active;
    Mix_Chunk* sound;
    int recent_index;
    int playing;
} Cell;

Cell tracker[ROWS][COLS];
int cur_row = 0, cur_col = 0;
int running = 1;

char recent_sounds[RECENT_MAX][WAV_NAME_LEN];
int recent_count = 0;
int current_recent = 0;

// ------------------ UTILS ------------------
int is_audio_file(const char* name) {
    const char* ext = strrchr(name, '.');
    if(!ext) return 0;
    return (!strcasecmp(ext, ".wav") || !strcasecmp(ext, ".ogg") || !strcasecmp(ext, ".mp3"));
}

void add_recent(const char* path) {
    for(int i=0;i<recent_count;i++) {
        if(strcmp(recent_sounds[i], path)==0) {
            current_recent = i+1;
            return;
        }
    }
    if(recent_count<RECENT_MAX) {
        strncpy(recent_sounds[recent_count], path, WAV_NAME_LEN-1);
        recent_sounds[recent_count][WAV_NAME_LEN-1]=0;
        recent_count++;
        current_recent = recent_count;
    } else {
        for(int i=0;i<RECENT_MAX-1;i++) strncpy(recent_sounds[i], recent_sounds[i+1], WAV_NAME_LEN);
        strncpy(recent_sounds[RECENT_MAX-1], path, WAV_NAME_LEN-1);
        recent_sounds[RECENT_MAX-1][WAV_NAME_LEN-1]=0;
        current_recent = RECENT_MAX;
    }
}

// ------------------ GRID ------------------
void draw_grid(int step) {
    clear();
    int grid_width = COLS*6;
    int start_y = 2; // vertical offset
    int start_x = (COLS*6 < COLS*6 ? 0 : (COLS*6 - grid_width)/2);

    // App title
    mvprintw(start_y-2, start_x, " [ TUI Tracker ] ");

    for(int r=0;r<ROWS;r++) {
        for(int c=0;c<COLS;c++) {
            int y = start_y + r;
            int x = start_x + c*6;

            if(tracker[r][c].playing) attron(COLOR_PAIR(1));
            else if(r==cur_row && c==cur_col) attron(COLOR_PAIR(2));
            else if(tracker[r][c].active) attron(COLOR_PAIR(3));

            mvprintw(y, x, tracker[r][c].active ? "[%d]" : "[ ]", tracker[r][c].recent_index);

            attroff(COLOR_PAIR(1));
            attroff(COLOR_PAIR(2));
            attroff(COLOR_PAIR(3));
        }
    }

    mvprintw(start_y + ROWS + 1, start_x, "hjkl: move | a: toggle | i: insert | 1-9: recent | space: play/pause | ctrl+c: quit");
    mvprintw(start_y + ROWS + 2, start_x, "Status: %s | Current recent: %d", running?"Playing":"Paused", current_recent);
    refresh();
}

// ------------------ SEQUENCER ------------------
void play_step(int step) {
    for(int c=0;c<COLS;c++) {
        tracker[step][c].playing = 0;
        if(tracker[step][c].active && tracker[step][c].sound) {
            Mix_PlayChannel(-1, tracker[step][c].sound,0);
            tracker[step][c].playing = 1;
        }
    }
}

// ------------------ FILE BROWSER ------------------
int file_browser(char* out_path, size_t max_len, const char* start_dir) {
    char current_dir[512];
    strncpy(current_dir,start_dir,sizeof(current_dir)-1);
    current_dir[sizeof(current_dir)-1]=0;
    int selection=0;
    char search[128]="";
    int search_mode=0;
    char last_preview[512] = "";

    while(1) {
        struct dirent **namelist;
        int n = scandir(current_dir,&namelist,NULL,alphasort);
        if(n<0) return 0;

        int valid_count=0;
        char* entries[n];
        for(int i=0;i<n;i++) {
            struct stat st;
            char path[512];
            snprintf(path,sizeof(path),"%s/%s",current_dir,namelist[i]->d_name);
            stat(path,&st);
            int is_dir = S_ISDIR(st.st_mode);
            int match = (strlen(search)==0 || strcasestr(namelist[i]->d_name,search)!=NULL);
            if((is_dir || is_audio_file(namelist[i]->d_name)) && match) {
                entries[valid_count] = namelist[i]->d_name;
                valid_count++;
            }
        }

        clear();
        mvprintw(0, 0, "Browsing: %s", current_dir);
        mvprintw(1, 0, "Search: %s%s", search, search_mode?"_":"");
        for(int i=0;i<valid_count;i++) {
            if(i==selection) attron(A_REVERSE);
            mvprintw(2+i, 0, "%s", entries[i]);
            if(i==selection) attroff(A_REVERSE);
        }
        mvprintw(LINES-1,0,"hjkl: nav | /: search | enter: preview/select | backspace: up | q: quit");
        refresh();

        int ch = getch();
        if(search_mode) {
            if(ch=='\n') search_mode=0;
            else if(ch==127 || ch==KEY_BACKSPACE) {
                int len=strlen(search);
                if(len>0) search[len-1]=0;
            } else if(ch>=32 && ch<=126) {
                int len=strlen(search);
                if(len<sizeof(search)-1) { search[len]=ch; search[len+1]=0; }
            }
        } else {
            if(ch=='q') return 0;
            switch(ch) {
                case 'j': if(selection<valid_count-1) selection++; break;
                case 'k': if(selection>0) selection--; break;
                case 'h': {
                    char* last = strrchr(current_dir,'/');
                    if(last && last!=current_dir) *last=0;
                    selection=0;
                    search[0]=0;
                    last_preview[0]=0;
                    break;
                }
                case 'l':
                case '\n': {
                    struct stat st;
                    char path[512];
                    snprintf(path,sizeof(path),"%s/%s",current_dir,entries[selection]);
                    stat(path,&st);
                    if(S_ISDIR(st.st_mode)) {
                        strncpy(current_dir,path,sizeof(current_dir)-1);
                        current_dir[sizeof(current_dir)-1]=0;
                        selection=0;
                        search[0]=0;
                        last_preview[0]=0;
                    } else {
                        if(strcmp(path,last_preview)==0) {
                            strncpy(out_path,path,max_len-1);
                            out_path[max_len-1]=0;
                            return 1;
                        } else {
                            Mix_Chunk* preview = Mix_LoadWAV(path);
                            if(preview) {
                                Mix_PlayChannel(-1, preview, 0);
                                Mix_FreeChunk(preview);
                            }
                            strncpy(last_preview,path,sizeof(last_preview)-1);
                            last_preview[sizeof(last_preview)-1]=0;
                        }
                    }
                    break;
                }
                case '/': search_mode=1; search[0]=0; break;
            }
        }
    }
}


// ------------------ INSERT WAV ------------------
void insert_wav(const char* path) {
    if(strlen(path)==0) return;
    if(tracker[cur_row][cur_col].sound) Mix_FreeChunk(tracker[cur_row][cur_col].sound);
    tracker[cur_row][cur_col].sound = Mix_LoadWAV(path);
    if(!tracker[cur_row][cur_col].sound) {
        mvprintw(LINES-2,0,"Failed to load: %s", path); clrtoeol(); refresh();
        return;
    }
    strncpy(tracker[cur_row][cur_col].wav_file,path,WAV_NAME_LEN-1);
    tracker[cur_row][cur_col].wav_file[WAV_NAME_LEN-1]=0;
    add_recent(path);
    tracker[cur_row][cur_col].recent_index=current_recent;
}

// ------------------ MAIN ------------------
int main() {
    initscr(); cbreak(); noecho(); keypad(stdscr,TRUE);

    if(has_colors()) {
        start_color();
        use_default_colors();
        init_pair(1, COLOR_BLACK, COLOR_GREEN);   // playing
        init_pair(2, COLOR_WHITE, COLOR_BLUE);    // cursor
        init_pair(3, COLOR_YELLOW, -1);           // active
    }

    if(SDL_Init(SDL_INIT_AUDIO)<0){ endwin(); printf("SDL failed: %s\n",SDL_GetError()); return 1;}
    if(Mix_OpenAudio(44100,MIX_DEFAULT_FORMAT,2,1024)<0){ endwin(); printf("Mix failed: %s\n",Mix_GetError()); return 1;}
    memset(tracker,0,sizeof(tracker));

    int ch, step=0;
    int delay_ms = 60000 / BPM / 4;
    nodelay(stdscr,TRUE);

    while(1) {
        ch = getch();
        if(ch!=ERR) {
            switch(ch) {
                case 'h': if(cur_col>0) cur_col--; break;
                case 'l': if(cur_col<COLS-1) cur_col++; break;
                case 'k': if(cur_row>0) cur_row--; break;
                case 'j': if(cur_row<ROWS-1) cur_row++; break;
                case 'a':
                    if(current_recent>0) {
                        tracker[cur_row][cur_col].active = !tracker[cur_row][cur_col].active;
                        tracker[cur_row][cur_col].recent_index=current_recent;
                        strncpy(tracker[cur_row][cur_col].wav_file,recent_sounds[current_recent-1],WAV_NAME_LEN-1);
                        tracker[cur_row][cur_col].wav_file[WAV_NAME_LEN-1]=0;
                        if(tracker[cur_row][cur_col].sound) Mix_FreeChunk(tracker[cur_row][cur_col].sound);
                        tracker[cur_row][cur_col].sound=Mix_LoadWAV(recent_sounds[current_recent-1]);
                    }
                    break;
                case 'i': {
                    char path[WAV_NAME_LEN]="";
                    char* home = getenv("HOME");
                    char music_dir[512];
                    snprintf(music_dir, sizeof(music_dir), "%s/Music", home ? home : ".");
                    nodelay(stdscr,FALSE);
                    echo();
                    if(file_browser(path,sizeof(path), music_dir)) insert_wav(path);
                    noecho(); nodelay(stdscr,TRUE);
                    break;
                }
                case '1': case '2': case '3': case '4': case '5':
                case '6': case '7': case '8': case '9':
                    if((ch-'0') <= recent_count) current_recent=ch-'0';
                    break;
                case ' ': 
                    running = !running; 
                    if(running) play_step(step);
                    break;
            }
        }

        if(running) {
            play_step(step);
            step=(step+1)%ROWS;
        }

        draw_grid(step);
        usleep(delay_ms*1000);
    }

quit:
    for(int r=0;r<ROWS;r++)
        for(int c=0;c<COLS;c++)
            if(tracker[r][c].sound) Mix_FreeChunk(tracker[r][c].sound);
    Mix_CloseAudio();
    SDL_Quit();
    endwin();
    return 0;
}
