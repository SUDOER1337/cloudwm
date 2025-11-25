/* See LICENSE file for copyright and license details. */

/* appearance */
#include <X11/XF86keysym.h>
static const unsigned int borderpx = 2;
static const int user_bh = 27;
static const int swallowfloating = 0;
static const unsigned int snap = 1;
static const unsigned int gappih = 5;
static const unsigned int gappiv = 5;
static const unsigned int gappoh = 5;
static const unsigned int gappov = 5;
static const char buttonbar[] = "󰅣 ";
static int smartgaps = 0;
static const int showbar = 1;
static const int topbar = 1;
static const int horizpadbar = 2;
static const int vertpadbar = 2;
static const int vertpad = 0;
static const int sidepad = 0;

/*systray*/
static const unsigned int systraypinning = 0;
static const unsigned int systrayonleft = 0;
static const unsigned int systrayspacing = 4;
static const int systraypinningfailfirst = 1;
static const unsigned int systrayiconsize = 16;
static int showsystray = 1;

static const char *fonts[] = {
    "Iosevka Nerd Font:size=11:style=Bold",
    "Noto Sans Thai:size=11",
    "Noto Color Emoji:pixelsize=10:antialias=true:autohint=true",
    "Material Design Icons Desktop:size=11"
};
static const char dmenufont[] = "Iosevka Nerd Font:size=12";

/* Backgrounds and UI */
static const char col_back[]   = "#303030";
static const char col_gray1[]  = "#383838";
static const char col_gray2[]  = "#444444";
static const char col_gray3[]  = "#B0B0B0";
static const char col_gray4[]  = "#E0E0E0";

static const char col_blue[]   = "#81A1C1";
static const char col_orange[] = "#D4AF7F";
static const char col_red[]    = "#BF616A";
static const char col_green[]  = "#A3BE8C";
static const char col_cyan[]   = "#8FBCBB";
static const char col_yellow[] = "#D4AF7F";
static const char col_magenta[]= "#B48EAD";

static const char *colors[][3] = {
  /*               fg           bg         border   */
    [SchemeNorm] = { col_gray3, col_back,  col_gray2 },
    [SchemeBtn]  = { col_blue,  col_gray1, col_gray2 },
    [SchemeLt]   = { col_gray4, col_back,  col_gray2 },
    [SchemeSel]  = { col_gray4, col_blue,  col_gray4 },
};

static const char *tagsel[][2] = {
    { col_green, col_back }, 
    { col_red, col_back }, 
    { col_yellow, col_back },
    { col_blue,  col_back }, 
    { col_magenta, col_back }, 
    { col_cyan, col_back },
};

/* scratchpads */
typedef struct {
    const char *name;
    const void *cmd;
} Sp;

const char *spcmd1[] = {"st", "-n", "spterm", "-g", "120x28", NULL};
const char *spcmd2[] = {"st", "-n", "spmpd", "-e", "ncmpcpp", NULL};
static Sp scratchpads[] = {
    {"spterm", spcmd1},
    {"spmpd", spcmd2},
};

/* tagging */
static char *tags[]    = {"  Internet", "  Terminal", "  Works", "󰍡  Chat"};
static char *alttags[] = {"[   Internet ]", "[   Terminal ]", "[    Works ]", "[ 󰍡  Chat ]"};
static const unsigned int ulinepad = 2;
static const unsigned int ulinestroke = 2;
static const unsigned int ulinevoffset = 0;
static const int ulineall = 0;

/* rules */
static const Rule rules[] = {
    {"discord",   "discord",       NULL,   1 << 3,       0,           -1 },
    {"steam",     "steamwebhelper",NULL,   1 << 5,       0,},
    {"Gimp", NULL, NULL, 0, 1, 0, 0, -1},
    {"zen-browser", NULL, NULL, 1 << 8, 0, 0, -1, -1},
    {"st-256color", NULL, NULL, 0, 0, 1, 0, -1},
    {NULL, NULL, "Event Tester", 0, 0, 0, 1, -1},
    {NULL, "spterm", NULL, SPTAG(0), 1, 1, 0, -1},
    {NULL, "spmpd", NULL, SPTAG(1), 1, 1, 0, -1},
};

/* layout(s) */
static const float mfact     = 0.55;
static const int nmaster     = 1;
static const int resizehints = 1;
static const int lockfullscreen = 1;

#define FORCE_VSPLIT 1
#include "vanitygaps.c"

static const Layout layouts[] = {
    {"[@]", spiral}, {"[]", tile}, {"//", NULL}, {"[\\]", dwindle},
    {"[M]", monocle}, {"|M|", centeredmaster}, {NULL, NULL},
};

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY, TAG) \
    { MODKEY,                       KEY, view,       {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask,           KEY, toggleview, {.ui = 1 << TAG} }, \
    { MODKEY|ShiftMask,             KEY, tag,        {.ui = 1 << TAG} }, \
    { MODKEY|ControlMask|ShiftMask, KEY, toggletag,  {.ui = 1 << TAG} },

/* SHCMD wrapper */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands (use $HOME for portability) */
static const char *rofi_launcher[]      = {"sh", "-c", "$HOME/cloudwm/rofi/launchers/launcher.sh", NULL};
static const char *rofi_emoji[]         = {"sh", "-c", "$HOME/cloudwm/rofi/emoji/emoji.sh", NULL};
static const char *rofi_powermenu[]     = {"sh", "-c", "$HOME/cloudwm/rofi/powermenu/powermenu.sh", NULL};
static const char *rofi_calc[]          = {"sh", "-c", "$HOME/cloudwm/rofi/calc/calc.sh", NULL};
static const char *rofi_controlcenter[] = {"sh", "-c", "$HOME/cloudwm/rofi/controlcenter/controlcenter.sh", NULL};
static const char *rofi_brightness[]    = {"sh", "-c", "$HOME/cloudwm/rofi/brightness/brightness.sh", NULL};
static const char *rofi_note[]          = {"sh", "-c", "$HOME/cloudwm/rofi/note/note.sh", NULL};
static const char *rofi_stretchly[]     = {"sh", "-c", "$HOME/cloudwm/rofi/stretchly/stretchly.sh", NULL};
static const char *rofi_bluetooth[]     = {"sh", "-c", "$HOME/cloudwm/rofi/bluetooth/rofi-bluetooth", NULL};
static const char *rofi_clipboard[] = { "rofi", "-modi", "clipboard:greenclip print", "-show", "clipboard", "-run-command", "{cmd}", NULL };
/* playerctl commands */
static const char *playerctl_playpause[] = { "playerctl", "play-pause", NULL };
static const char *playerctl_next[]      = { "playerctl", "next", NULL };
static const char *playerctl_prev[]      = { "playerctl", "previous", NULL };
static const char *playerctl_stop[]      = { "playerctl", "stop", NULL };

/* flameshot commands */
static const char *flameshot_gui[]  = {"flameshot", "gui", NULL};

/* XF86 volume controls */
static const char *vol_up[]    = {"pactl", "set-sink-volume", "@DEFAULT_SINK@", "+5%", NULL};
static const char *vol_down[]  = {"pactl", "set-sink-volume", "@DEFAULT_SINK@", "-5%", NULL};
static const char *vol_mute[]  = {"pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle", NULL};

/*Language Switcher*/
static const char *toggle_layout_cmd[] = { "/bin/sh", "-c", "$HOME/cloudwm/scripts/toggle-layout.sh", NULL };

/* keybindings */
static const Key keys[] = {
    
    /* Reload sxhkd */
    { MODKEY,                       XK_F5,    spawn, {.v = (const char*[]){ "pkill", "-USR1", "-x", "sxhkd", NULL } } },

    /* Rofi Menus */
    {MODKEY,                       XK_o,      spawn, {.v = rofi_controlcenter}},
    {MODKEY,                       XK_r,      spawn, {.v = rofi_launcher}},
    {MODKEY,                       XK_period, spawn, {.v = rofi_emoji}},
    {MODKEY,                       XK_c,      spawn, {.v = rofi_calc}},
    {ControlMask|Mod1Mask,         XK_Delete, spawn, {.v = rofi_powermenu}},
    {ControlMask|Mod1Mask,         XK_b,      spawn, {.v = rofi_bluetooth}},
    {ControlMask|ShiftMask,        XK_b,      spawn, {.v = rofi_brightness}},
    {ControlMask|Mod1Mask,         XK_s,      spawn, {.v = rofi_stretchly}},
    {MODKEY,                       XK_v,      spawn, {.v = rofi_clipboard}},
    {MODKEY,                       XK_n,      spawn, {.v = rofi_note}},

    /* Flameshot */
    {MODKEY|ShiftMask,             XK_s,      spawn, {.v = flameshot_gui}},

    /* Media controls */
    {0, XF86XK_AudioPlay,   spawn, {.v = playerctl_playpause}},
    {0, XF86XK_AudioNext,   spawn, {.v = playerctl_next}},
    {0, XF86XK_AudioPrev,   spawn, {.v = playerctl_prev}},
    {0, XF86XK_AudioStop,   spawn, {.v = playerctl_stop}},

    /* Volume controls */
    {0, XF86XK_AudioRaiseVolume, spawn, {.v = vol_up}},
    {0, XF86XK_AudioLowerVolume, spawn, {.v = vol_down}},
    {0, XF86XK_AudioMute,        spawn, {.v = vol_mute}},
    
    /*Meta + Space*/
    {MODKEY,                       XK_space,  spawn,          {.v = toggle_layout_cmd}},

    /* Applications */
    {MODKEY,                       XK_b,      spawn, SHCMD("zen-browser")},
    {MODKEY,                       XK_e,      spawn, SHCMD("nemo")},
    {MODKEY|ShiftMask,             XK_e,      spawn, SHCMD("thunar")},
    {MODKEY,                       XK_t,      spawn, SHCMD("kitty")},
    
    /*Bar*/
    {MODKEY,                       XK_0,      togglebar,       {0}},
    {MODKEY,                       XK_y,      togglesystray,   {0}},

    /* Window management */
    {MODKEY|ShiftMask,             XK_l,      cyclelayout,    {.i = +1}},
    {MODKEY,                       XK_j,      focusstack,     {.i = +1}},
    {MODKEY,                       XK_k,      focusstack,     {.i = -1}},
    {MODKEY,                       XK_i,      incnmaster,     {.i = +1}},
    {MODKEY,                       XK_h,      setmfact,       {.f = -0.05}},
    {MODKEY,                       XK_l,      setmfact,       {.f = +0.05}},
    {MODKEY,                       XK_F11,    togglefullscr,  {0}},
    {MODKEY,                       XK_Return, zoom,           {0}},
    {Mod1Mask,                     XK_Tab,    view,           {0}},
    {MODKEY,                       XK_q,      killclient,     {0}},
    {MODKEY|ShiftMask,             XK_q,      quit,           {0}},

    /* Tags */
    TAGKEYS(XK_1, 0) TAGKEYS(XK_2, 1) TAGKEYS(XK_3, 2)
    TAGKEYS(XK_4, 3)
};

/* button definitions */
static const Button buttons[] = {
    {ClkLtSymbol,   0,              Button1, setlayout,      {0}},
    {ClkLtSymbol,   0,              Button3, setlayout,      {.v = &layouts[2]}},
    {ClkClientWin,  MODKEY,         Button1, movemouse,      {0}},
    {ClkClientWin,  MODKEY,         Button2, togglefloating, {0}},
    {ClkClientWin,  MODKEY,         Button3, resizemouse,    {0}},
    {ClkTagBar,     0,              Button1, view,           {0}},
    {ClkTagBar,     0,              Button3, toggleview,     {0}},
    {ClkTagBar,     MODKEY,         Button1, tag,            {0}},
    {ClkTagBar,     MODKEY,         Button3, toggletag,      {0}},
};

