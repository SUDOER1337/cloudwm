.POSIX:
.SUFFIXES:

include config.mk

# flags for compiling
FJORDWLCPPFLAGS = -I. -DWLR_USE_UNSTABLE -D_POSIX_C_SOURCE=200809L \
	-DVERSION=\"$(VERSION)\" $(XWAYLAND)
FJORDWLDEVCFLAGS = -g -Wpedantic -Wall -Wextra -Wdeclaration-after-statement \
	-Wno-unused-parameter -Wshadow -Wunused-macros -Werror=strict-prototypes \
	-Werror=implicit -Werror=return-type -Werror=incompatible-pointer-types \
	-Wfloat-conversion

# CFLAGS / LDFLAGS
PKGS      = wayland-server xkbcommon libinput $(XLIBS)
FJORDWLCFLAGS = `$(PKG_CONFIG) --cflags $(PKGS)` $(WLR_INCS) $(FJORDWLCPPFLAGS) $(FJORDWLDEVCFLAGS) $(CFLAGS)
LDLIBS    = `$(PKG_CONFIG) --libs $(PKGS)` $(WLR_LIBS) -lm $(LIBS)

all: fjordwl
fjordwl: dwl.o util.o dwl-ipc-unstable-v2-protocol.o
	$(CC) dwl.o util.o dwl-ipc-unstable-v2-protocol.o $(FJORDWLCFLAGS) $(LDFLAGS) $(LDLIBS) -o $@
dwl.o: dwl.c client.h config.def.h config.mk cursor-shape-v1-protocol.h \
	pointer-constraints-unstable-v1-protocol.h wlr-layer-shell-unstable-v1-protocol.h \
wlr-output-power-management-unstable-v1-protocol.h xdg-shell-protocol.h \
	dwl-ipc-unstable-v2-protocol.h
util.o: util.c util.h
dwl-ipc-unstable-v2-protocol.o: dwl-ipc-unstable-v2-protocol.c dwl-ipc-unstable-v2-protocol.h

# wayland-scanner is a tool which generates C headers and rigging for Wayland
# protocols, which are specified in XML. wlroots requires you to rig these up
# to your build system yourself and provide them in the include path.
WAYLAND_SCANNER   = `$(PKG_CONFIG) --variable=wayland_scanner wayland-scanner`
WAYLAND_PROTOCOLS = `$(PKG_CONFIG) --variable=pkgdatadir wayland-protocols`
CURSOR_SHAPE_PROTOCOL = $(WAYLAND_PROTOCOLS)/staging/cursor-shape/cursor-shape-v1.xml
POINTER_CONSTRAINTS_PROTOCOL = $(WAYLAND_PROTOCOLS)/unstable/pointer-constraints/pointer-constraints-unstable-v1.xml
XDG_SHELL_PROTOCOL = $(WAYLAND_PROTOCOLS)/stable/xdg-shell/xdg-shell.xml

ifeq ($(wildcard $(CURSOR_SHAPE_PROTOCOL)),)
CURSOR_SHAPE_PROTOCOL = protocols/cursor-shape-v1.xml
endif

ifeq ($(wildcard $(POINTER_CONSTRAINTS_PROTOCOL)),)
POINTER_CONSTRAINTS_PROTOCOL = protocols/pointer-constraints-unstable-v1.xml
endif

ifeq ($(wildcard $(XDG_SHELL_PROTOCOL)),)
XDG_SHELL_PROTOCOL = /usr/share/qt6/wayland/protocols/xdg-shell/xdg-shell.xml
endif

cursor-shape-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		$(CURSOR_SHAPE_PROTOCOL) $@
pointer-constraints-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		$(POINTER_CONSTRAINTS_PROTOCOL) $@
wlr-layer-shell-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) enum-header \
		protocols/wlr-layer-shell-unstable-v1.xml $@
wlr-output-power-management-unstable-v1-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		protocols/wlr-output-power-management-unstable-v1.xml $@
xdg-shell-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		$(XDG_SHELL_PROTOCOL) $@
dwl-ipc-unstable-v2-protocol.h:
	$(WAYLAND_SCANNER) server-header \
		protocols/dwl-ipc-unstable-v2.xml $@
dwl-ipc-unstable-v2-protocol.c:
	$(WAYLAND_SCANNER) private-code \
		protocols/dwl-ipc-unstable-v2.xml $@

clean:
	rm -f fjordwl *.o *-protocol.h *-protocol.c

dist: clean
	mkdir -p fjordwl-$(VERSION)
	cp -R LICENSE* Makefile CHANGELOG.md README.md client.h config.def.h \
		config.mk protocols fjordwl.1 fjordwl.desktop start-fjordwl dwl.c util.c util.h \
		fjordwl-$(VERSION)
	tar -caf fjordwl-$(VERSION).tar.gz fjordwl-$(VERSION)
	rm -rf fjordwl-$(VERSION)

install: fjordwl
	mkdir -p $(DESTDIR)$(PREFIX)/bin
	rm -f $(DESTDIR)$(PREFIX)/bin/fjordwl $(DESTDIR)$(PREFIX)/bin/dwl
	cp -f fjordwl $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/fjordwl
	ln -sf fjordwl $(DESTDIR)$(PREFIX)/bin/dwl
	cp -f start-fjordwl $(DESTDIR)$(PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/start-fjordwl
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	cp -f fjordwl.1 $(DESTDIR)$(MANDIR)/man1
	chmod 644 $(DESTDIR)$(MANDIR)/man1/fjordwl.1
	mkdir -p $(DESTDIR)$(DATADIR)/wayland-sessions
	cp -f fjordwl.desktop $(DESTDIR)$(DATADIR)/wayland-sessions/fjordwl.desktop
	chmod 644 $(DESTDIR)$(DATADIR)/wayland-sessions/fjordwl.desktop
uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/fjordwl $(DESTDIR)$(PREFIX)/bin/dwl $(DESTDIR)$(PREFIX)/bin/start-fjordwl \
		$(DESTDIR)$(MANDIR)/man1/fjordwl.1 \
		$(DESTDIR)$(DATADIR)/wayland-sessions/fjordwl.desktop

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CPPFLAGS) $(FJORDWLCFLAGS) -o $@ -c $<
