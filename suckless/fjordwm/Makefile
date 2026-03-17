# fjordwm - cloud window manager
# See LICENSE file for copyright and license details.

include config.mk

SRC = drw.c dwm.c util.c
OBJ = ${SRC:.c=.o}

all: options fjordwm

options:
	@echo fjordwm build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.h config.mk

config.h:
	cp config.def.h $@

fjordwm: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

clean:
	rm -f fjordwm ${OBJ} fjordwm-${VERSION}.tar.gz

dist: clean
	mkdir -p fjordwm-${VERSION}
	cp -R LICENSE Makefile README config.def.h config.mk\
		fjordwm.1 fjordwm.desktop start-fjordwm drw.h util.h ${SRC} fjordwm.png transient.c fjordwm-${VERSION}
	tar -cf fjordwm-${VERSION}.tar fjordwm-${VERSION}
	gzip fjordwm-${VERSION}.tar
	rm -rf fjordwm-${VERSION}

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f fjordwm ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/fjordwm
	cp -f start-fjordwm ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/start-fjordwm
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < fjordwm.1 > ${DESTDIR}${MANPREFIX}/man1/fjordwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/fjordwm.1
	mkdir -p ${DESTDIR}${DATADIR}/xsessions
	cp -f fjordwm.desktop ${DESTDIR}${DATADIR}/xsessions/fjordwm.desktop
	chmod 644 ${DESTDIR}${DATADIR}/xsessions/fjordwm.desktop

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/fjordwm\
		${DESTDIR}${PREFIX}/bin/start-fjordwm\
		${DESTDIR}${MANPREFIX}/man1/fjordwm.1\
		${DESTDIR}${DATADIR}/xsessions/fjordwm.desktop

.PHONY: all options clean dist install uninstall
