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

#include "../common/xchat.h"
#include "../common/xchatc.h"

#import "RawLogWindow.h"

@implementation RawLogWindow

- (id) RawLogWindowInit {
	[self setServer:current_sess->server];
	[self setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Rawlog (%s)", @"xchat", @""), self->server->servername]];
	[self setTabTitle:NSLocalizedStringFromTable(@"rawlog", @"xchataqua", @"")];
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	return [self RawLogWindowInit];
}

- (id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	return [self RawLogWindowInit];
}

- (void) log:(const char *) msg length:(NSInteger) len outbound:(BOOL) outbound
{
	NSString * s, * str;
	if(msg[len-1]=='\n')
		--len;
	
	s   = [[NSString alloc] initWithBytes:msg length:len encoding:NSUTF8StringEncoding];
	str = [NSString stringWithFormat:@"%c %@\n", outbound ? '>' : '<', s];
	[s release];

	[logTextView replaceCharactersInRange:NSMakeRange([[logTextView textStorage] length], 0) withString:str];
	[logTextView scrollRangeToVisible:NSMakeRange([[logTextView textStorage] length], 0)];
}

@end
