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

#import "SGRequest.h"

@interface SGRequestPrivate : NSObject
{
    IBOutlet id label;
    IBOutlet id text;
}

- (IBAction) doCancel:(id)sender;
- (IBAction) doOk:(id)sender;

- (NSString *) stringForRequest;
- (void) setValue:(NSString *) value;

@end

#pragma mark -

@implementation SGRequestPrivate

- (id) initWithString:(NSString *) title
{
    self = [super init];
    if (self != nil) {
        [NSBundle loadNibNamed:@"SGRequest" owner:self];
        [[label window] setTitle:title];
        [label setStringValue:title];
        [[label window] center];
    }
    return self;
}

- (void) dealloc
{
//    [[label window] autorelease];
    [super dealloc];
}

- (void) setValue:(NSString *) value
{
    [text setStringValue:value];
}

- (NSString *)stringForRequest
{
    [[label window] makeKeyAndOrderFront:self];
    NSModalSession session = [NSApp beginModalSessionForWindow:[label window]];
    NSInteger ret;
    while ((ret = [NSApp runModalSession:session]) == NSRunContinuesResponse)
        ;
    [NSApp endModalSession:session];     
    [[label window] close];
    
    return ret ? [text stringValue] : nil;
}

- (void) doCancel:(id)sender
{
    [NSApp stopModalWithCode:0];
}

- (void) doOk:(id)sender
{
    [NSApp stopModalWithCode:1];
}

@end

#pragma mark -

@implementation SGRequest

+ (NSString *) stringByRequestWithTitle:(NSString *) title
{
    return [SGRequest stringByRequestWithTitle:title defaultValue:nil];
}

+ (NSString *) stringByRequestWithTitle:(NSString *) title defaultValue:(NSString *) def
{
    SGRequestPrivate *request = [[[SGRequestPrivate alloc] initWithString:title] autorelease];
    if (def)
        [request setValue:def];
    return [request stringForRequest];
}

@end
