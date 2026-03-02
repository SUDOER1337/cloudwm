# cloudwm - cloud window manager
# See LICENSE file for copyright and license details.

include config.mk

SRC = drw.c dwm.c util.c
OBJ = ${SRC:.c=.o}

all: options cloudwm

options:
	@echo cloudwm build options:
	@echo "CFLAGS   = ${CFLAGS}"
	@echo "LDFLAGS  = ${LDFLAGS}"
	@echo "CC       = ${CC}"

.c.o:
	${CC} -c ${CFLAGS} $<

${OBJ}: config.h config.mk

config.h:
	cp config.def.h $@

cloudwm: ${OBJ}
	${CC} -o $@ ${OBJ} ${LDFLAGS}

clean:
	rm -f cloudwm ${OBJ} cloudwm-${VERSION}.tar.gz

dist: clean
	mkdir -p cloudwm-${VERSION}
	cp -R LICENSE Makefile README config.def.h config.mk\
		cloudwm.1 drw.h util.h ${SRC} cloudwm.png transient.c cloudwm-${VERSION}
	tar -cf cloudwm-${VERSION}.tar cloudwm-${VERSION}
	gzip cloudwm-${VERSION}.tar
	rm -rf cloudwm-${VERSION}

install: all
	mkdir -p ${DESTDIR}${PREFIX}/bin
	cp -f cloudwm ${DESTDIR}${PREFIX}/bin
	chmod 755 ${DESTDIR}${PREFIX}/bin/cloudwm
	mkdir -p ${DESTDIR}${MANPREFIX}/man1
	sed "s/VERSION/${VERSION}/g" < cloudwm.1 > ${DESTDIR}${MANPREFIX}/man1/cloudwm.1
	chmod 644 ${DESTDIR}${MANPREFIX}/man1/cloudwm.1

uninstall:
	rm -f ${DESTDIR}${PREFIX}/bin/cloudwm\
		${DESTDIR}${MANPREFIX}/man1/cloudwm.1

.PHONY: all options clean dist install uninstall
