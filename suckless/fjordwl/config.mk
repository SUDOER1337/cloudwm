_VERSION = 0.8
VERSION  = `git describe --tags --dirty 2>/dev/null || echo $(_VERSION)`

LOCAL_WLR_PREFIX ?= $(HOME)/.local/wlroots-0.19

# paths
PREFIX = /usr/local
MANDIR = $(PREFIX)/share/man
DATADIR = $(PREFIX)/share

ifneq ($(wildcard $(LOCAL_WLR_PREFIX)/lib/pkgconfig/wlroots-0.19.pc),)
PKG_CONFIG = PKG_CONFIG_PATH="$(LOCAL_WLR_PREFIX)/lib/pkgconfig:$(LOCAL_WLR_PREFIX)/share/pkgconfig:$$PKG_CONFIG_PATH" pkg-config
WLR_INCS = `$(PKG_CONFIG) --cflags wlroots-0.19`
WLR_LIBS = -Wl,-rpath,$(LOCAL_WLR_PREFIX)/lib `$(PKG_CONFIG) --libs wlroots-0.19`
else
PKG_CONFIG = pkg-config

WLR_INCS = `$(PKG_CONFIG) --cflags wlroots-0.19`
LIBDISPLAY_INFO_LIBS = `$(PKG_CONFIG) --silence-errors --libs libdisplay-info`
WLR_LIBS = `$(PKG_CONFIG) --libs wlroots-0.19` $(LIBDISPLAY_INFO_LIBS)
endif

# Allow using an alternative wlroots installation
# This has to have all the includes required by wlroots, e.g:
# Assuming wlroots git repo is "${PWD}/wlroots" and you only ran "meson setup build && ninja -C build"
#WLR_INCS = -I/usr/include/pixman-1 -I/usr/include/elogind -I/usr/include/libdrm \
#	-I$(PWD)/wlroots/include
# Set -rpath to avoid using the wrong library.
#WLR_LIBS = -Wl,-rpath,$(PWD)/wlroots/build -L$(PWD)/wlroots/build -lwlroots-0.19

# Assuming you ran "meson setup --prefix ${PWD}/0.19 build && ninja -C build install"
#WLR_INCS = -I/usr/include/pixman-1 -I/usr/include/elogind -I/usr/include/libdrm \
#	-I$(PWD)/wlroots/0.19/include/wlroots-0.19
#WLR_LIBS = -Wl,-rpath,$(PWD)/wlroots/0.19/lib64 -L$(PWD)/wlroots/0.19/lib64 -lwlroots-0.19

# XWayland is enabled by default in this vendored build.
# Comment these lines to build a Wayland-only fjordwl binary.
XWAYLAND = -DXWAYLAND
XLIBS = xcb xcb-icccm

# fjordwl itself only uses C99 features, but wlroots' headers use anonymous unions (C11).
# To avoid warnings about them, we do not use -std=c99 and instead of using the
# gmake default 'CC=c99', we use cc.
CC = cc
