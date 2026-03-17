#define COLOR(hex)    { ((hex >> 24) & 0xFF) / 255.0f, \
                        ((hex >> 16) & 0xFF) / 255.0f, \
                        ((hex >> 8) & 0xFF) / 255.0f, \
                        (hex & 0xFF) / 255.0f }

/* appearance */
static const int sloppyfocus               = 1;
static const int bypass_surface_visibility = 0;
static const int smartgaps                 = 0;
static const int monoclegaps               = 0;
static const unsigned int borderpx         = 3;
static const unsigned int gappih           = 2;
static const unsigned int gappiv           = 2;
static const unsigned int gappoh           = 20;
static const unsigned int gappov           = 25;
static const float rootcolor[]             = COLOR(0x292828ff);
static const float bordercolor[]           = COLOR(0x444444ff);
static const float focuscolor[]            = COLOR(0x556c59ff);
static const float urgentcolor[]           = COLOR(0x725548ff);
static const float fullscreen_bg[]         = COLOR(0x121111ff);
static int enableautoswallow               = 1;
static float swallowborder                 = 1.0f;

/* tags counts , amount of tags */
#define TAGCOUNT (6)

/* logging */
static int log_level = WLR_ERROR;

static const Rule rules[] = {
	/* app_id/class            title                    tags mask  isfloating  isterm  noswallow  monitor  scratch */
	{ "spterm",                NULL,                    0,         1,          1,      1,          -1,      't' },
	{ "spmusic",               NULL,                    0,         1,          1,      1,          -1,      'm' },
	{ "zen-browser",           NULL,                    1 << 0,    0,          0,      0,          -1,      0 },
	{ "firefox",               NULL,                    1 << 0,    0,          0,      0,          -1,      0 },
	{ "org.pwmt.zathura",      NULL,                    1 << 2,    0,          0,      0,          -1,      0 },
	{ "Zathura",               NULL,                    1 << 2,    0,          0,      0,          -1,      0 },
	{ "VSCodium",              NULL,                    1 << 3,    0,          0,      0,          -1,      0 },
	{ "code-oss",              NULL,                    1 << 3,    0,          0,      0,          -1,      0 },
	{ "Code",                  NULL,                    1 << 3,    0,          0,      0,          -1,      0 },
	{ "discord",               NULL,                    1 << 4,    0,          0,      0,          -1,      0 },
	{ "vesktop",               NULL,                    1 << 4,    0,          0,      0,          -1,      0 },
	{ "obsidian",              NULL,                    1 << 5,    0,          0,      0,          -1,      0 },
	{ "steam",                 NULL,                    1 << 5,    0,          0,      0,          -1,      0 },
	{ "thunar",                NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "nemo",                  NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "virt-viewer",           NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "Virt-viewer",           NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "pavucontrol",           NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "nm-connection-editor",  NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "blueman-manager",       NULL,                    0,         1,          0,      1,          -1,      0 },
	{ NULL,                    "File Operation Progress", 0,       1,          0,      1,          -1,      0 },
	{ NULL,                    "Properties",            0,         1,          0,      1,          -1,      0 },
	{ "org.gimp.GIMP",         NULL,                    0,         1,          0,      1,          -1,      0 },
	{ "Gimp",                  NULL,                    0,         1,          0,      1,          -1,      0 },
};

/* layout(s) */
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[]=",      tile },
	{ "><>",      NULL },
	{ "[M]",      monocle },
};

/* setgaps(ov, oh, ih, iv)
 * ov = outer vertical gap   (top + bottom screen edge)
 * oh = outer horizontal gap (left + right screen edge)
 * ih = inner horizontal gap (between side-by-side windows)
 * iv = inner vertical gap   (between stacked windows)
 */
static void
setgaps1(const Arg *arg)
{
	setgaps(22, 92, 2, 2);
}

static void
setgaps2(const Arg *arg)
{
	setgaps(8, 8, 2, 2);
}

static void
setgaps3(const Arg *arg)
{
	setgaps(20, 25, 2, 2);
}

/* monitors */
static const MonitorRule monrules[] = {
	/* name       mfact  nmaster scale layout       rotate/reflect              mode_w mode_h hz   x    y */
	{ "HDMI-A-1", 0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL, 1920,  1080,  120, -1,  -1 },
	{ NULL,       0.55f, 1,      1,    &layouts[0], WL_OUTPUT_TRANSFORM_NORMAL,    0,     0,    0, -1,  -1 },
};

/* keyboard */
static const struct xkb_rule_names xkb_rules = {
	.layout = "us,th",
	.options = "grp:win_space_toggle",
};

static const int repeat_rate = 25;
static const int repeat_delay = 600;

/* trackpad */
static const int tap_to_click = 1;
static const int tap_and_drag = 1;
static const int drag_lock = 1;
static const int natural_scrolling = 0;
static const int disable_while_typing = 1;
static const int left_handed = 0;
static const int middle_button_emulation = 0;
static const enum libinput_config_scroll_method scroll_method = LIBINPUT_CONFIG_SCROLL_2FG;
static const enum libinput_config_click_method click_method = LIBINPUT_CONFIG_CLICK_METHOD_BUTTON_AREAS;
static const uint32_t send_events_mode = LIBINPUT_CONFIG_SEND_EVENTS_ENABLED;
static const enum libinput_config_accel_profile accel_profile = LIBINPUT_CONFIG_ACCEL_PROFILE_ADAPTIVE;
static const double accel_speed = 0.0;
static const enum libinput_config_tap_button_map button_map = LIBINPUT_CONFIG_TAP_MAP_LRM;

#define MODKEY WLR_MODIFIER_LOGO

#define TAGKEYS(KEY, SKEY, TAG) \
	{ MODKEY,                                 KEY,            view,            {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL,               KEY,            toggleview,      {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_SHIFT,              SKEY,           tag,             {.ui = 1 << TAG} }, \
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, SKEY,      toggletag,       {.ui = 1 << TAG} }

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *runnercmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/runner/runner.sh", NULL};
static const char *controlcentercmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/controlcenter/controlcenter.sh", NULL};
static const char *emojicmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/emoji/emoji.sh", NULL};
static const char *calccmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/calc/calc.sh", NULL};
static const char *powermenucmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/powermenu/powermenu.sh", NULL};
static const char *brightnesscmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/brightness/brightness.sh", NULL};
static const char *wallpapercmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/wallpaper/wallpaper.sh", NULL};
static const char *clipboardcmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/clipboard/clipboard.sh", NULL};
static const char *windowscmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/windows/windows.sh", NULL};
static const char *notecmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/note/note.sh", NULL};
static const char *mediacmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/media/media.sh", NULL};
static const char *stretchlycmd[] = {"sh", "-c", "$HOME/fjordwm/rofi/stretchly/stretchly.sh", NULL};
static const char *swayncpanelcmd[] = {"swaync-client", "--open-panel", NULL};
static const char *terminalcmd[] = {"sh", "-c", "if command -v foot >/dev/null 2>&1; then exec foot; else exec kitty; fi", NULL};
static const char *scratchtermcmd[] = {
	"t", "sh", "-c",
	"if command -v foot >/dev/null 2>&1; then exec foot --app-id spterm --title spterm; "
	"else exec kitty --class spterm --title spterm; fi",
	NULL
};
static const char *scratchmusiccmd[] = {
	"m", "sh", "-c",
	"if command -v foot >/dev/null 2>&1; then exec foot --app-id spmusic --title spmusic -e ncmpcpp; "
	"else exec kitty --class spmusic --title spmusic ncmpcpp; fi",
	NULL
};
static const char *lockcmd[] = {"sh", "-c", "$HOME/fjordwm/scripts/wayland-lock.sh", NULL};
static const char *shotfullcmd[] = {"sh", "-c", "$HOME/fjordwm/scripts/wayland-screenshot.sh full", NULL};

static const char *playpausecmd[] = {"playerctl", "play-pause", NULL};
static const char *nextcmd[] = {"playerctl", "next", NULL};
static const char *prevcmd[] = {"playerctl", "previous", NULL};
static const char *stopcmd[] = {"playerctl", "stop", NULL};

static const char *volupcmd[] = {"wpctl", "set-volume", "--limit", "1.0", "@DEFAULT_AUDIO_SINK@", "1%+", NULL};
static const char *voldowncmd[] = {"wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "1%-", NULL};
static const char *volmutecmd[] = {"wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle", NULL};

static const Key keys[] = {
	/* launchers */
	{ MODKEY,                                 XKB_KEY_r,           spawn,               {.v = runnercmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_O,           spawn,               {.v = controlcentercmd} },
	{ MODKEY,                                 XKB_KEY_period,      spawn,               {.v = emojicmd} },
	{ MODKEY,                                 XKB_KEY_c,           spawn,               {.v = calccmd} },
	{ MODKEY,                                 XKB_KEY_d,           spawn,               {.v = swayncpanelcmd} },
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,     XKB_KEY_Delete,      spawn,               {.v = powermenucmd} },
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT,   XKB_KEY_B,           spawn,               {.v = brightnesscmd} },
	{ WLR_MODIFIER_ALT|WLR_MODIFIER_SHIFT,    XKB_KEY_r,           spawn,               {.v = mediacmd} },
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,     XKB_KEY_s,           spawn,               {.v = stretchlycmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_W,           spawn,               {.v = wallpapercmd} },
	{ MODKEY,                                 XKB_KEY_v,           spawn,               {.v = clipboardcmd} },
	{ MODKEY,                                 XKB_KEY_n,           spawn,               {.v = notecmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_l,           spawn,               {.v = lockcmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_S,           spawn,               SHCMD("grim -g \"$(slurp)\" ~/Pictures/shot-$(date +%F-%T).png") },
	{ MODKEY,                                 XKB_KEY_p,           spawn,               {.v = shotfullcmd} },
	{ WLR_MODIFIER_ALT,                       XKB_KEY_Tab,         spawn,               {.v = windowscmd} },

	/* media keys */
	{ 0,                                      XKB_KEY_XF86AudioPlay,        spawn, {.v = playpausecmd} },
	{ 0,                                      XKB_KEY_XF86AudioNext,        spawn, {.v = nextcmd} },
	{ 0,                                      XKB_KEY_XF86AudioPrev,        spawn, {.v = prevcmd} },
	{ 0,                                      XKB_KEY_XF86AudioStop,        spawn, {.v = stopcmd} },
	{ 0,                                      XKB_KEY_XF86AudioRaiseVolume, spawn, {.v = volupcmd} },
	{ 0,                                      XKB_KEY_XF86AudioLowerVolume, spawn, {.v = voldowncmd} },
	{ 0,                                      XKB_KEY_XF86AudioMute,        spawn, {.v = volmutecmd} },

	/* applications */
	{ MODKEY,                                 XKB_KEY_b,           spawn,               SHCMD("zen-browser") },
	{ MODKEY,                                 XKB_KEY_e,           spawn,               SHCMD("nemo") },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_E,           spawn,               SHCMD("thunar") },
	{ MODKEY,                                 XKB_KEY_t,           spawn,               {.v = terminalcmd} },
	{ MODKEY,                                 XKB_KEY_o,           spawn,               SHCMD("obsidian") },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_B,           focusortogglescratch,{.v = scratchtermcmd} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_V,           focusortogglescratch,{.v = scratchmusiccmd} },
	{ WLR_MODIFIER_ALT|WLR_MODIFIER_SHIFT,    XKB_KEY_z,           spawn,               SHCMD("warpd --hint") },
	{ WLR_MODIFIER_ALT|WLR_MODIFIER_SHIFT,    XKB_KEY_x,           spawn,               SHCMD("warpd --grid") },
	{ WLR_MODIFIER_ALT|WLR_MODIFIER_SHIFT,    XKB_KEY_c,           spawn,               SHCMD("warpd --normal") },

	/* window management */
	{ MODKEY,                                 XKB_KEY_j,           focusstack,          {.i = +1} },
	{ MODKEY,                                 XKB_KEY_k,           focusstack,          {.i = -1} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_J,           movestack,           {.i = +1} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_K,           movestack,           {.i = -1} },
	{ MODKEY,                                 XKB_KEY_i,           incnmaster,          {.i = +1} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_D,           incnmaster,          {.i = -1} },
	{ MODKEY,                                 XKB_KEY_h,           setmfact,            {.f = -0.05f} },
	{ MODKEY,                                 XKB_KEY_l,           setmfact,            {.f = +0.05f} },
	{ MODKEY,                                 XKB_KEY_g,           setgaps1,            {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_G,           setgaps2,            {0} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_g,           setgaps3,            {0} },
	{ MODKEY|WLR_MODIFIER_ALT,                XKB_KEY_g,           togglegaps,          {0} },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_G,      defaultgaps,         {0} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_equal,       incgaps,             {.i = +1} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_minus,       incgaps,             {.i = -1} },
	{ MODKEY|WLR_MODIFIER_ALT,                XKB_KEY_j,           incigaps,            {.i = +1} },
	{ MODKEY|WLR_MODIFIER_ALT,                XKB_KEY_k,           incigaps,            {.i = -1} },
	{ MODKEY|WLR_MODIFIER_ALT,                XKB_KEY_h,           incogaps,            {.i = +1} },
	{ MODKEY|WLR_MODIFIER_ALT,                XKB_KEY_l,           incogaps,            {.i = -1} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_a,           toggleswallow,       {0} },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_A,      toggleautoswallow,   {0} },
	{ MODKEY,                                 XKB_KEY_Return,      zoom,                {0} },
	{ MODKEY,                                 XKB_KEY_Tab,         view,                {0} },
	{ MODKEY,                                 XKB_KEY_f,           togglefloating,      {0} },
	{ MODKEY,                                 XKB_KEY_F11,         togglefullscreen,    {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_q,           killclient,          {0} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_t,           setlayout,           {.v = &layouts[0]} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_f,           setlayout,           {.v = &layouts[1]} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_m,           setlayout,           {.v = &layouts[2]} },
	{ MODKEY,                                 XKB_KEY_space,       setlayout,           {0} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_space,       togglefloating,      {0} },
	{ MODKEY,                                 XKB_KEY_0,           view,                {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_SHIFT,              XKB_KEY_parenright,  tag,                 {.ui = ~0} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_comma,       focusmon,            {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_CTRL,               XKB_KEY_period,      focusmon,            {.i = WLR_DIRECTION_RIGHT} },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_less,   tagmon,              {.i = WLR_DIRECTION_LEFT} },
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_greater, tagmon,             {.i = WLR_DIRECTION_RIGHT} },
	TAGKEYS(          XKB_KEY_1,              XKB_KEY_exclam,                         0),
	TAGKEYS(          XKB_KEY_2,              XKB_KEY_at,                             1),
	TAGKEYS(          XKB_KEY_3,              XKB_KEY_numbersign,                     2),
	TAGKEYS(          XKB_KEY_4,              XKB_KEY_dollar,                         3),
	TAGKEYS(          XKB_KEY_5,              XKB_KEY_percent,                        4),
	TAGKEYS(          XKB_KEY_6,              XKB_KEY_asciicircum,                    5),
	{ MODKEY|WLR_MODIFIER_CTRL|WLR_MODIFIER_SHIFT, XKB_KEY_q,   quit,                {0} },

	/* Ctrl-Alt-Backspace and Ctrl-Alt-Fx used to be handled by the X server */
	{ WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT,     XKB_KEY_Terminate_Server, quit,         {0} },
#define CHVT(n) { WLR_MODIFIER_CTRL|WLR_MODIFIER_ALT, XKB_KEY_XF86Switch_VT_##n, chvt, {.ui = (n)} }
	CHVT(1), CHVT(2), CHVT(3), CHVT(4), CHVT(5), CHVT(6),
	CHVT(7), CHVT(8), CHVT(9), CHVT(10), CHVT(11), CHVT(12),
};

static const Button buttons[] = {
	{ MODKEY, BTN_LEFT,   moveresize,     {.ui = CurMove} },
	{ MODKEY, BTN_MIDDLE, togglefloating, {0} },
	{ MODKEY, BTN_RIGHT,  moveresize,     {.ui = CurResize} },
};
