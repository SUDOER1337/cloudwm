/*	$OpenBSD: explicit_bzero.c,v 1.3 2014/06/21 02:34:26 matthew Exp $ */
/*
 * Public domain.
 * Written by Matthew Dempsky.
 */

#include <string.h>

__attribute__((weak)) void __explicit_bzero_hook(void *buf, size_t len) {
    (void)buf;
    (void)len;
}

void explicit_bzero(void *buf, size_t len)
{
    /* Use volatile pointer to prevent optimization */
    volatile unsigned char *p = buf;
    size_t i;
    
    if (len > 0) {
        for (i = 0; i < len; i++) {
            p[i] = 0;
        }
        /* Additional memory barrier */
        __asm__ __volatile__("" : : "r"(p) : "memory");
    }
    
    __explicit_bzero_hook(buf, len);
}
