/* See LICENSE file for copyright and license details. */

// --- Appearance ---
#include <X11/XF86keysym.h>
static const unsigned int borderpx        = 3;  //border size in pixels
static const int          user_bh         = 26; //bar height , 0 = auto
static const int          swallowfloating = 0;
static const unsigned int snap            = 1;
static const unsigned int gappoh          = 20;
static const unsigned int gappov          = 25;
static const unsigned int gappih          = 2;
static const unsigned int gappiv          = 2;
static int                smartgaps       = 0;
static const int          showbar         = 1;
static const int          topbar          = 1;
static const int          horizpadbar     = 2;
static const int          vertpadbar      = 1;
static const int          vertpad         = 0;
static const int          sidepad         = 0;
static const char         buttonbar[]     = " ";

// --- System Tray ---
static const unsigned int systraypinning          = 0;
static const unsigned int systrayonleft           = 0;
static const unsigned int systrayspacing          = 8;
static const int          systraypinningfailfirst = 1;
static const unsigned int systrayiconsize         = 16;
static const int          showsystray             = 1;

static const char *fonts[] = {
    "Iosevka Nerd Font:size=11:style=ExtraBold", "Noto Sans Thai:size=11",
    "Noto Color Emoji:pixelsize=10:antialias=true:autohint=true",
    "Material Design Icons Desktop:size=11"};
static const char dmenufont[] = "Iosevka Nerd Font:size=11:style=ExtraBold";

// --- Backgrounds and UI ---

static const char col_back[]  = "#292828";
static const char col_tagfg[] = "#c0b091";

static const char col_gray1[] = "#353535";
static const char col_gray2[] = "#444444";
static const char col_gray3[] = "#C0AF8B";
static const char col_gray4[] = "#9A8B78";

// --- Accent Colors ---

static const char col_1[] = "#7A8160";
static const char col_2[] = "#725548";
static const char col_3[] = "#7D6D51";
static const char col_4[] = "#6F6C5E";
static const char col_5[] = "#556C59";
static const char col_6[] = "#7A7468";

static const char *colors[][3] = {
    //-------------|fg---------|bg--------|border
    [SchemeNorm] = {col_gray3, col_back,  col_gray2},
    [SchemeBtn]  = {col_gray3, col_gray2, col_gray2},
    [SchemeLt]   = {col_gray4, col_back,  col_gray2},
    [SchemeSel]  = {col_gray4, col_5,     col_5},
};

static const char *tagsel[][2] = {
    {col_tagfg, col_1}, {col_tagfg, col_2}, {col_tagfg, col_3},
    {col_tagfg, col_4}, {col_tagfg, col_5}, {col_tagfg, col_6},
};

// --- Scratchpads ---
typedef struct
{
    const char *name;
    const void *cmd;
} Sp;

const char *spcmd1[]      = {"st", "-n", "spterm", "-g", "120x28", NULL};
const char *spcmd2[]      = {"st", "-n", "spmpd", "-e", "ncmpcpp", NULL};
static Sp   scratchpads[] = {
    {"spterm", spcmd1},
    {"spmpd", spcmd2},
};

// --- Tags ---

static char *tags[] = {"[ 󰇧  Web ]", "[   Term ]",  "[   Make ]",
                       "[ 󱌣  Dev ]", "[ 󰍡  Talk ]", "[ 󰠮  Note ]"};

static char *alttags[] = {"[ 󰇧  Web ·]",  "[   Term ·]",
                          "[   Make ·]",  "[ 󱌣  Dev ·]",
                          "[ 󰍡  Talk ·]", "[ 󰠮  Note ·]"};

static const unsigned int ulinepad     = 0;
static const unsigned int ulinestroke  = 0;
static const unsigned int ulinevoffset = 0;
static const int          ulineall     = 0;

/* rules */
static const Rule rules[] = {
    {"rmpc-float", NULL, NULL, 0, 1, -1 },
    {"Virt-viewer", NULL, NULL, 1 << 8, 0, 0, 1, -1},
    {"Thunar", NULL, NULL, 0, 1, 0, 0, -1},
    {"Nemo", NULL, NULL, 0, 1, 0, 0, -1},
    {NULL, NULL, "File Operation Progress", 0, 1, -1},
    {NULL, NULL, "Properties", 0, 1, -1},
    {"discord", NULL, NULL, 0, 1, -1},
    {"discord", "discord", NULL, 1 << 4, 0, -1},
    {
        "steam",
        "steamwebhelper",
        NULL,
        1 << 5,
        0,
    },
    {"Gimp", NULL, NULL, 0, 1, 0, 0, -1},
    {"zen-browser", NULL, NULL, 1 << 8, 0, 0, -1, -1},
    {"St", "st-256color", NULL, 0, 0, 1, 0, -1},
    {NULL, NULL, "Event Tester", 0, 0, 0, 1, -1},
    {NULL, "spterm", NULL, SPTAG(0), 1, 1, 0, -1},
    {NULL, "spmpd", NULL, SPTAG(1), 1, 1, 0, -1},
};

/* layout(s) */
static const float mfact          = 0.55;
static const int   nmaster        = 1;
static const int   resizehints    = 0;
static const int   lockfullscreen = 1;

#define FORCE_VSPLIT 1
#include "vanitygaps.c"

/* setgaps(ov, oh, ih, iv)
 * ov = outer vertical gap   (top + bottom screen edge)
 * oh = outer horizontal gap (left + right screen edge)
 * ih = inner horizontal gap (between side-by-side windows)
 * iv = inner vertical gap   (between stacked windows)
 */

// least gap
static void setgaps1(const Arg *arg)
{
    setgaps(22, 92, 2, 2);
}

// gappy
static void setgaps2(const Arg *arg)
{
    setgaps(8, 8, 2, 2);
}

// really gappy
static void setgaps3(const Arg *arg)
{
    setgaps(20, 25, 2, 2);
}

static const Layout layouts[] = {
    {"[@]", spiral},  {"[]", tile}, {"//", NULL},
    {"[\\]", dwindle}, {"[M]", monocle},
    {"|M|", centeredmaster},
    {NULL, NULL},
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY, TAG)                                                      \
    {MODKEY, KEY, view, {.ui = 1 << TAG}},                                     \
        {MODKEY | ControlMask, KEY, toggleview, {.ui = 1 << TAG}},             \
        {MODKEY | ShiftMask, KEY, tag, {.ui = 1 << TAG}},                      \
        {MODKEY | ControlMask | ShiftMask, KEY, toggletag, {.ui = 1 << TAG}},

/* SHCMD wrapper */
#define SHCMD(cmd)                                                             \
    {                                                                          \
        .v = (const char *[])                                                  \
        {                                                                      \
            "/bin/sh", "-c", cmd, NULL                                         \
        }                                                                      \
    }

/* commands (use $HOME for portability) */

static const char *rofi_runner[] = {
    "sh", "-c", "$HOME/.config/rofi/runner/runner.sh", NULL};
static const char *rofi_emoji[] = {"sh", "-c",
                                   "$HOME/.config/rofi/emoji/emoji.sh", NULL};
static const char *rofi_powermenu[] = {
    "sh", "-c", "$HOME/.config/rofi/powermenu/powermenu.sh", NULL};
static const char *rofi_calc[] = {"sh", "-c", "$HOME/.config/rofi/calc/calc.sh",
                                  NULL};
static const char *rofi_utility[] = {
    "sh", "-c", "$HOME/.config/rofi/utility/utility.sh", NULL};
static const char *rofi_brightness[] = {
    "sh", "-c", "$HOME/.config/rofi/brightness/brightness.sh", NULL};
static const char *rofi_note[] = {"sh", "-c", "$HOME/.config/rofi/note/note.sh",
                                  NULL};
static const char *rofi_stretchly[] = {
    "sh", "-c", "$HOME/.config/rofi/stretchly/stretchly.sh", NULL};
static const char *rofi_wallpaper[] = {
    "sh", "-c", "$HOME/.config/rofi/wallpaper/wallpaper.sh", NULL};
static const char *rofi_bluetooth[] = {
    "sh", "-c", "$HOME/.config/rofi/bluetooth/rofi-bluetooth", NULL};
static const char *rofi_clipboard[] = {
    "sh", "-c", "$HOME/.config/rofi/clipboard/clipboard.sh", NULL};
static const char *rofi_media[] = {
    "sh", "-c", "$HOME/.config/rofi/media/media.sh", NULL};

/* playerctl commands */
static const char *playerctl_playpause[] = {"playerctl", "play-pause", NULL};
static const char *playerctl_next[]      = {"playerctl", "next", NULL};
static const char *playerctl_prev[]      = {"playerctl", "previous", NULL};
static const char *playerctl_stop[]      = {"playerctl", "stop", NULL};

/* flameshot commands */
static const char *flameshot_gui[] = {"flameshot", "gui", NULL};

/* XF86 volume controls (PipeWire via wpctl) */
static const char *vol_up[]   = {"wpctl", "set-volume",           "--limit",
                                 "1.0",   "@DEFAULT_AUDIO_SINK@", "1%+",
                                 NULL};
static const char *vol_down[] = {"wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
                                 "1%-", NULL};
static const char *vol_mute[] = {"wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@",
                                 "toggle", NULL};

/* keybindings */
static const Key keys[] = {

    /* Rofi Menus */
    {MODKEY | ShiftMask, XK_o, spawn, {.v = rofi_utility}},
    {MODKEY, XK_r, spawn, {.v = rofi_runner}},
    {MODKEY, XK_period, spawn, {.v = rofi_emoji}},
    {MODKEY, XK_c, spawn, {.v = rofi_calc}},
    {ControlMask | Mod1Mask, XK_Delete, spawn, {.v = rofi_powermenu}},
    {ControlMask | Mod1Mask, XK_b, spawn, {.v = rofi_bluetooth}},
    {ControlMask | ShiftMask, XK_b, spawn, {.v = rofi_brightness}},
    {ControlMask | Mod1Mask, XK_s, spawn, {.v = rofi_stretchly}},
    {MODKEY | ShiftMask, XK_w, spawn, {.v = rofi_wallpaper}},
    {MODKEY, XK_v, spawn, {.v = rofi_clipboard}},
    {MODKEY, XK_n, spawn, {.v = rofi_note}},
    /* Flameshot */
    {MODKEY | ShiftMask, XK_s, spawn, {.v = flameshot_gui}},
    {MODKEY, XK_p, spawn, {.v = flameshot_gui}},

    /* Media controls */
    {0, XF86XK_AudioPlay, spawn, {.v = playerctl_playpause}},
    {0, XF86XK_AudioNext, spawn, {.v = playerctl_next}},
    {0, XF86XK_AudioPrev, spawn, {.v = playerctl_prev}},
    {0, XF86XK_AudioStop, spawn, {.v = playerctl_stop}},

    /* Volume controls */
    {0, XF86XK_AudioRaiseVolume, spawn, {.v = vol_up}},
    {0, XF86XK_AudioLowerVolume, spawn, {.v = vol_down}},
    {0, XF86XK_AudioMute, spawn, {.v = vol_mute}},

    /* Applications */
    {MODKEY, XK_b, spawn, SHCMD("zen-browser")},
    {MODKEY, XK_e, spawn, SHCMD("nemo")},
    {MODKEY | ShiftMask, XK_e, spawn, SHCMD("thunar")},
    {MODKEY, XK_t, spawn, SHCMD("kitty")},
    {MODKEY, XK_o, spawn, SHCMD("obsidian")},
    {Mod1Mask | ShiftMask, XK_r, spawn, {.v = rofi_media}},

    /* warpd: keyboard pointer (z/x/c cluster) */
    {Mod1Mask | ShiftMask, XK_z, spawn, SHCMD("warpd --hint")},
    {Mod1Mask | ShiftMask, XK_x, spawn, SHCMD("warpd --grid")},
    {Mod1Mask | ShiftMask, XK_c, spawn, SHCMD("warpd --normal")},

    /*Bar*/
    {MODKEY, XK_0, togglebar, {0}},

    /* Window management */
    {MODKEY, XK_f, togglefloating, {0}},
    {MODKEY | ShiftMask, XK_l, cyclelayout, {.i = +1}},
    {MODKEY, XK_j, focusstack, {.i = +1}},
    {MODKEY, XK_k, focusstack, {.i = -1}},
    {MODKEY, XK_i, incnmaster, {.i = +1}},
    {MODKEY, XK_h, setmfact, {.f = -0.05}},
    {MODKEY, XK_l, setmfact, {.f = +0.05}},
    {MODKEY, XK_F11, togglefullscr, {0}},
    {MODKEY, XK_Return, zoom, {0}},
    {Mod1Mask, XK_Tab, spawn, SHCMD("$HOME/.config/rofi/windows/windows.sh")},
    {MODKEY | ShiftMask, XK_q, killclient, {0}},

    {MODKEY, XK_g, setgaps1, {0}},    
    {MODKEY | ShiftMask, XK_g, setgaps2, {0}},
    {MODKEY | ControlMask, XK_g, setgaps3, {0}},

    /*{MODKEY|ShiftMask,             XK_q,      quit,           {0}},*/

    /* Tags */
    TAGKEYS(XK_1, 0) TAGKEYS(XK_2, 1) TAGKEYS(XK_3, 2) TAGKEYS(XK_4, 3)
        TAGKEYS(XK_5, 4) TAGKEYS(XK_6, 5)};

/* button definitions */
static const Button buttons[] = {
    {ClkLtSymbol, 0, Button1, setlayout, {0}},
    {ClkLtSymbol, 0, Button3, setlayout, {.v = &layouts[2]}},
    {ClkClientWin, MODKEY, Button1, movemouse, {0}},
    {ClkClientWin, MODKEY, Button2, togglefloating, {0}},
    {ClkClientWin, MODKEY, Button3, resizemouse, {0}},
    {ClkTagBar, 0, Button1, view, {0}},
    {ClkTagBar, 0, Button3, toggleview, {0}},
    {ClkTagBar, MODKEY, Button1, tag, {0}},
    {ClkTagBar, MODKEY, Button3, toggletag, {0}},
};
