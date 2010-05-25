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

#import "SGTokenizer.h"


@implementation SGTokenizer

- (id) initWithString:(NSString *) stringToTokenize;
{
	self = [super init];
	
	[self setString:stringToTokenize];
	
	return self;
}

- (void) dealloc
{
	[tmp release];
	[super dealloc];
}

- (void) setString:(NSString *) stringToTokenize
{
	[tmp release];
	tmp = [stringToTokenize retain];
	ptr = 0;
}

- (NSString *) getNextToken:(const char *) delimit
{
    if (!tmp)
        return nil;

	int slen = [tmp length];
	
	if (slen == 0 || ptr >= slen)
		return nil;

    while (ptr < slen && strchr (delimit, [tmp characterAtIndex:ptr])) ptr++;       // Skip leading tokens
    int start = ptr;
    while (ptr < slen && !strchr (delimit, [tmp characterAtIndex:ptr])) ptr++;      // find the end

    int len = ptr - start;

    if (len == 0)
        return nil;

    if (ptr < slen) ptr++;		// Eat the delimiter

    return [tmp substringWithRange:NSMakeRange(start, len)];
}

- (NSString *) remainder
{
    return [tmp substringFromIndex:ptr];
}

@end