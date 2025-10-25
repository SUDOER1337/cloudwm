/* user and group to drop privileges to */
static const char *user  = "nobody";
static const char *group = "nobody";

static const char *colorname[NUMCOLS] = {
	[INIT] =   "#bbbbbb",     /* after initialization */
	[INPUT] =  "#bbbbbb",   /* during input */
	[FAILED] = "#CC3333",   /* wrong password */
};

static const char *lock_message = "";
static const char *wrong_message = "";
static const char *message_font = "Cozette:pixelsize=12:antialias=false:autohint=false";

/* treat a cleared input like a wrong password (color) */
static const int failonclear = 1;

/*Enable blur*/
#define BLUR
/*Set blur radius*/
static const int blurRadius=25;

/*Enable dimming*/
#define DIM
/*Set dim factor (0-255, higher = more dim)*/
static const int dimAlpha = 100; // 90 was prior
/*Enable Pixelation*/
//#define PIXELATION
/*Set pixelation radius*/
static const int pixelSize=0;

/*Font settings for the time text*/
//static const float textsize=30;
//static const char* textfamily="JetBrains Maple Mono";
//static const double textcolorred=255; // prior 255 for all three
//static const double textcolorgreen=255;
//static const double textcolorblue=255;

/* Time display settings */
static const char *time_font   = "Iosevka Nerd Font:style=Bold:size=85";
static const char *time_color  = "#bbbbbb";      /* lighter so it stands out */
static const char *time_format = "%H|%M|%S";        /* 24-hour format */
static const int time_y_off    = 0;              /* pixels relative to center */

/* Date display settings */
static const char *date_font   = "Iosevka Nerd Font:style=Regular:size=25";
static const char *date_color  = "#bbbbbb";      /* softer contrast */
static const char *date_format = "%a %d.%m.%Y";  /* re-enabled for clarity */
static const int date_y_off    = 60;             /* pixels relative to center */

/* Input indicator settings */
/*static const int indicator_y_off = 600; pixels relative to screen center */

// Refresh intervals (in seconds)
static const int tw_refr_int = 10;   // thread_wrapper() interval. Should be the lowest one.
static const int tm_refr_int = 10;   // interval for draw_time()
static const int dt_refr_int = 3600; // interval for draw_date()
