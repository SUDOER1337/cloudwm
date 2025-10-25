```
   _____  _       ____   _    _  _____ __          __ __  __ 
  / ____|| |     / __ \ | |  | ||  __ \\ \        / /|  \/  |
 | |     | |    | |  | || |  | || |  | |\ \  /\  / / | \  / |
 | |     | |    | |  | || |  | || |  | | \ \/  \/ /  | |\/| |
 | |____ | |____| |__| || |__| || |__| |  \  /\  /   | |  | |
  \_____||______|\____/  \____/ |_____/    \/  \/    |_|  |_|
                                                             
```

Forked from [`namishh's bedwm`](https://github.com/namishh/dwm)

Compositor: ```picom```

Terminal: ```kitty```

Lock screen: slock with readpw() and draw_time() modded originally from ['DPatel0211's dotfiles](https://github.com/DPatel0211/dotfiles)

Fonts: Cozette, Iosevka Nerd Font, JetBrainsMono Nerd Fonts

GTK theme: ```Carbon-Square``` a honestly pretty terrible dark only boxy gtk theme using oomox

Cursor theme: ```Bibata-Modern-Classic```

Icons: YAMIS

Dotfiles: Configuration files, scripts, wallpapers & more


Launchers: My Editted ['adi1090x collection of Rofi custom Applets, Launchers & Powermenus'](https://github.com/adi1090x/rofi)

# Themes

```cp ~/cloudwm/Themes/Carbon-Square in ~/.themes/ #run this to put the gtk theme into```
> Zen Browser custom .css (just feel line of userChrome.css to make it square tho)
> Discord theme based on System24 for Betterdiscord 

## Recommandation

```nwg-look``` for gtk settings

## Installation

Run the installation script:

```bash
./setup.sh

```

## Patches
+ ActualFullscreen
+ AltTagsDecoration
+ Alwayscenter
+ BarPadding
+ BarHeight
+ Cfacts
+ CycleLayouts
+ NoTitle
+ RainbowTags
+ ScratchPads
+ Status2d
+ StatusButton
+ StatusPadding
+ StatusCmd
+ Swallow
+ Systray-Iconsize
+ UnderlineTags
+ Vanitygaps

All configuration is done by editing the source code files:

    config.h – Main configuration file

    scripts/ – Helper scripts for automation

After making changes:
```
cd ~/cloudwm && sudo make clean install
```
Feel free to forks!
