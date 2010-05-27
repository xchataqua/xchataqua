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

#import <SGRequest.h>

@interface SGRequestPrivate : NSObject
{
    id label;
    id text;
}

- (NSString *) doit;
- (void) setValue:(NSString *) val;

@end

@implementation SGRequestPrivate

- (id) initWithString:(NSString *) title
{
    [super init];
    
    [NSBundle loadNibNamed:@"SGRequest" owner:self];
    
    [[label window] setTitle:title];
    [label setStringValue:title];
    [[label window] center];
    
    return self;
}

- (void) dealloc
{
    [[label window] autorelease];
    [super dealloc];
}

- (void) setValue:(NSString *) val
{
    [text setStringValue:val];
}

- (NSString *) doit
{
    [[label window] makeKeyAndOrderFront:self];
    NSModalSession session = [NSApp beginModalSessionForWindow:[label window]];
    int ret;
    while ((ret = [NSApp runModalSession:session]) == NSRunContinuesResponse)
	;
    [NSApp endModalSession:session];     
    [[label window] close];
    
    return ret ? [text stringValue] : nil;
}

- (void) do_cancel:(id) sender
{
    [NSApp stopModalWithCode:0];
}

- (void) do_ok:(id) sender
{
    [NSApp stopModalWithCode:1];
}

@end

@implementation SGRequest

+ (NSString *) requestWithString:(NSString *) title
{
    SGRequestPrivate *r = [[[SGRequestPrivate alloc] initWithString:title] autorelease];
    return [r doit];
}

+ (NSString *) requestWithString:(NSString *) title defaultValue:(NSString *) def
{
    SGRequestPrivate *r = [[[SGRequestPrivate alloc] initWithString:title] autorelease];
    if (def)
        [r setValue:def];
    return [r doit];
}

@end
