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

#import "XATabView.h"

//////////////////////////////////////////////////////////////////////

@implementation XATabView

- (id<XATabViewDelegate>) delegate {
	return (id<XATabViewDelegate>)[super delegate];
}

- (void) setDelegate:(id<XATabViewDelegate>)delegate {
	[super setDelegate:(id)delegate];
}

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    
    in_close_item = nil;
    
    [self setControlSize:NSSmallControlSize];
    
    return self;
}

- (XATabViewItem *) mouseInClose:(NSEvent *) e
{
    NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

    NSArray *items = [self tabViewItems];
    
    for (NSUInteger i = 0; i < [items count]; i++ )
    {
        XATabViewItem *item = [items objectAtIndex:i];
        
        if ([item mouseInClose:p])
            return item;
    }
    
    return nil;
}

- (void) mouseDown:(NSEvent *) e
{
    in_close_item = [self mouseInClose:e];

    if (!in_close_item)
        [super mouseDown:e];
}

- (void) mouseUp:(NSEvent *) e
{
    if (in_close_item && [self mouseInClose:e] == in_close_item)
    {
        [[self delegate] tabWantsToClose:in_close_item];
        in_close_item = nil;
    }
    else
        [super mouseUp:e];
}

@end

//////////////////////////////////////////////////////////////////////

static NSImage *close_image;
static NSMutableDictionary *label_dict;

@implementation XATabViewItem

- (id) initWithIdentifier:(id) identifier
{
    [super initWithIdentifier:identifier];
    
    if (!close_image)
    {
        close_image = [[NSImage imageNamed:@"close.tiff"] retain];
        [close_image setFlipped:true];
        label_dict = [[NSMutableDictionary
                dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                forKey:NSFontAttributeName] retain];
    }
    
    close_rect.size = [close_image size];
    color = nil;
    
    return self;
}

- (void) dealloc
{
    if (color)
    	[color release];
    [super dealloc];
}

- (void) setTitleColor:(NSColor *) c
{
    if (color != c)
    {
	if (color)
	    [color release];
	color = [c retain]; 
	[self setLabel:[self label]];
    }
}

- (BOOL) mouseInClose:(NSPoint) p
{
    return NSMouseInRect (p, close_rect, YES);
}

- (NSSize) sizeOfLabel:(BOOL) shouldTruncateLabel
{
    CGFloat width = [[self label] sizeWithAttributes:label_dict].width;
    CGFloat height = [@"X" sizeWithAttributes:label_dict].height;
    width += [close_image size].width + 3;
    if (height < [close_image size].height)
        height = [close_image size].height;
    NSSize sz = { width, height };
    return sz;
}

- (void) drawLabel:(BOOL) shouldTruncateLabel inRect:(NSRect) tabRect
{
    close_rect.origin = tabRect.origin;
    
    NSPoint p;
    NSRect r;
    
    r.origin.x = 0;
    r.origin.y = 0;
    r.size = [close_image size];
   
    p.x = tabRect.origin.x;
    p.y = tabRect.origin.y + (tabRect.size.height - [close_image size].height) / 2;
    
    [close_image drawAtPoint:p fromRect:r operation:NSCompositeSourceOver fraction:1];

    p.y = tabRect.origin.y;    
    p.x += [close_image size].width + 5;

    [label_dict setObject:(color?color:[NSColor blackColor]) forKey:NSForegroundColorAttributeName];

    [[self label] drawAtPoint:p withAttributes:label_dict];
}

@end
