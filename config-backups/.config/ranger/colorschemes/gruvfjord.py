from __future__ import absolute_import, division, print_function

from ranger.colorschemes.default import Default
from ranger.gui.color import (
    black,
    blue,
    cyan,
    green,
    magenta,
    red,
    white,
    yellow,
    default,
    normal,
    bold,
    reverse,
    dim,
    BRIGHT,
)


class Scheme(Default):
    progress_bar_color = cyan

    def use(self, context):
        fg, bg, attr = Default.use(self, context)

        if context.reset:
            return fg, bg, attr

        if context.in_browser:
            if context.border:
                if context.active_pane:
                    fg = yellow + BRIGHT
                    attr = bold
                elif context.inactive_pane:
                    fg = blue
                    attr = dim
                else:
                    fg = white
                    attr = dim

            if context.directory and not context.inactive_pane:
                fg = blue + BRIGHT
                attr |= bold

            if context.inactive_pane and not context.border:
                fg = blue
                attr &= ~bold

            if context.selected:
                fg = black
                bg = blue + BRIGHT if context.inactive_pane else yellow + BRIGHT
                attr = bold
                if context.directory:
                    fg = black

            if context.marked and not context.selected:
                fg = yellow + BRIGHT
                attr |= bold

            if context.cut and not context.selected:
                fg = red + BRIGHT
                attr |= bold

            if context.copied and not context.selected:
                fg = cyan + BRIGHT
                attr |= bold

            if context.link:
                fg = cyan + BRIGHT if context.good else red + BRIGHT
                attr |= bold

            if context.executable and not any(
                (context.media, context.container, context.fifo, context.socket)
            ):
                fg = cyan
                attr |= bold

            if context.media and context.image:
                fg = cyan + BRIGHT
            elif context.media:
                fg = magenta + BRIGHT
            elif context.container:
                fg = red

        elif context.in_titlebar:
            attr |= bold
            if context.hostname:
                fg = red + BRIGHT if context.bad else cyan + BRIGHT
            elif context.directory:
                fg = blue + BRIGHT
            elif context.tab:
                fg = black if context.good else white
                bg = blue + BRIGHT if context.good else blue
            elif context.link:
                fg = cyan + BRIGHT

        elif context.in_statusbar:
            if context.permissions:
                if context.good:
                    fg = cyan + BRIGHT
                elif context.bad:
                    fg = red + BRIGHT

            if context.marked:
                fg = black
                bg = yellow + BRIGHT
                attr |= bold

            if context.frozen:
                fg = black
                bg = cyan + BRIGHT
                attr |= bold

            if context.message and context.bad:
                fg = red + BRIGHT
                attr |= bold

            if context.loaded:
                bg = self.progress_bar_color

            if context.vcsinfo:
                fg = blue + BRIGHT
                attr &= ~bold
            if context.vcscommit:
                fg = yellow + BRIGHT
                attr &= ~bold
            if context.vcsdate:
                fg = cyan
                attr &= ~bold

        elif context.in_taskview:
            if context.title:
                fg = blue + BRIGHT
                attr |= bold
            if context.selected:
                fg = black
                bg = yellow + BRIGHT
                attr = bold
            if context.loaded:
                if context.selected:
                    fg = black
                else:
                    bg = self.progress_bar_color

        if context.vcsfile and not context.selected:
            attr &= ~bold
            if context.vcsconflict:
                fg = magenta + BRIGHT
            elif context.vcsuntracked:
                fg = cyan + BRIGHT
            elif context.vcschanged:
                fg = red + BRIGHT
            elif context.vcsunknown:
                fg = red
            elif context.vcsstaged:
                fg = green
            elif context.vcssync:
                fg = green + BRIGHT
            elif context.vcsignored:
                fg = default

        elif context.vcsremote and not context.selected:
            attr &= ~bold
            if context.vcssync or context.vcsnone:
                fg = green + BRIGHT
            elif context.vcsbehind:
                fg = red + BRIGHT
            elif context.vcsahead:
                fg = blue + BRIGHT
            elif context.vcsdiverged:
                fg = magenta + BRIGHT
            elif context.vcsunknown:
                fg = red

        return fg, bg, attr
