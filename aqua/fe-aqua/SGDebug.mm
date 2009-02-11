/* X-Chat Aqua
 * Copyright (C) 2006 Steve Green
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

#include <stdio.h>
#include <objc/objc.h>
extern "C" {
#include <mach-o/nlist.h>
#include <mach-o/dyld.h>
}
#import <SGDebug.h>

typedef int (*ObjCLogProc) (BOOL, const char *, const char *, SEL);
typedef void (*LogObjcMessageSendsProc) (ObjCLogProc logProc);
typedef void (*InstrumentObjcMessageSendsProc) ();

static int mylog (BOOL isClassMethod, const char *objectsClass, const char *implementingClass, SEL selector)
{
        printf("%c[%s %s]\n",
                isClassMethod ? '+' : '-',
                //objectsClass,
                implementingClass,
                (char *) selector);
        return 0;
}

@implementation SGDebug

// Xcode3 can't build it
+ (void) setTraceEnabled:(BOOL) enable
{
    struct nlist nl[3];
    nl[0].n_un.n_name = "_logObjcMessageSends";
    nl[1].n_un.n_name = "_instrumentObjcMessageSends";      // This one is exported
    nl[2].n_un.n_name = NULL;
    int sts = nlist("/usr/lib/libobjc.dylib", nl);
    if (sts != 0)
        return;

    // This flushes the method cache and enables the log
    InstrumentObjcMessageSendsProc proc2 = (InstrumentObjcMessageSendsProc) nl[1].n_value;
    proc2 ();

    // This redirects the log to mylog
    LogObjcMessageSendsProc proc = (LogObjcMessageSendsProc) nl[0].n_value;
    proc (enable ? mylog : 0);
}

@end

