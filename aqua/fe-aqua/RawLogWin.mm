/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
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

#import "AquaChat.h"

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/server.h"
#include "../common/network.h"
#include "../common/dcc.h"
}

#import "SG.h"
#import "RawLogWin.h"

//////////////////////////////////////////////////////////////////////

@implementation RawLogWin

- (id) initWithServer:(struct server *) the_serv
{
    [super init];

    self->serv = the_serv;
	self->serv->gui->rawlog = self;
    
    [NSBundle loadNibNamed:@"RawLog" owner:self];

    [raw_log_view setServer:serv];
    [raw_log_view setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Rawlog (%s)", @"xchat", @""), self->serv->servername]];
    [raw_log_view setTabTitle:NSLocalizedStringFromTable(@"rawlog", @"xchataqua", @"")];
    [raw_log_view setDelegate:self];

    return self;
}

- (void) dealloc
{
    [raw_log_view setDelegate:NULL];
    [raw_log_view close];
    [raw_log_view autorelease];
    [super dealloc];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    serv->gui->rawlog = NULL;
    [self release];
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [raw_log_view becomeTabAndShow:true];
    else
        [raw_log_view becomeWindowAndShow:true];
}

- (void) log:(const char *) msg len:(int) len outbound:(bool) outbound
{
	NSString * s, * str;
	if(msg[len-1]=='\n')
		--len;
	
    s   = [[NSString alloc] initWithBytes:msg length:len encoding:NSUTF8StringEncoding];
	str = [NSString stringWithFormat:@"%c %@\n", outbound ? '>' : '<', s];
	[s release];

    [log_text replaceCharactersInRange:NSMakeRange([[log_text textStorage] length], 0) withString:str];
    [log_text scrollRangeToVisible:NSMakeRange([[log_text textStorage] length], 0)];
}

- (void) do_save:(id) sender
{
}

@end
