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

#import "SGWrapView.h"

//////////////////////////////////////////////////////////////////////

@interface SGWrapViewMetaView : SGMetaView
{
  @public
    NSRect pending_frame;
}

- (id) initWithView:(NSView *) view;

@end

@implementation SGWrapViewMetaView

- (id)initWithView:(NSView *) the_view;
{
    [super initWithView:the_view];
    return self;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGWrapView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    return self;
}

- (id) newMetaView:(NSView *) view
{
    return [[[SGWrapViewMetaView alloc] initWithView:view] autorelease];
}

- (void) shift:(NSUInteger)start to:(NSUInteger)stop by:(NSUInteger)unit
{
    for (NSUInteger i = start; i <= stop; i++)
    {
        SGWrapViewMetaView *metaView = [metaViews objectAtIndex:i];
        if (! [[metaView view] isHidden])
            metaView->pending_frame.origin.x += unit;
    }
}

- (void) do_wrap_layout
{
	NSRect rect = [self bounds];
	
	CGFloat lx = rect.origin.x;
	CGFloat ly = rect.origin.y;
	
	rows = 0;
	
	NSUInteger this_row = 0;
	CGFloat maxHeight = 0;

	rect.size.height = 0;
    
    if ([metaViews count])
    {
        rows = 1;
        
        for (NSUInteger i = 0; i < [metaViews count]; i ++)
        {
            SGWrapViewMetaView *metaView = [metaViews objectAtIndex:i];
     
            if ([[metaView view] isHidden])
                continue;

            NSRect b = [metaView prefSize];
        
            if (i != this_row && lx + b.size.width > rect.origin.x + rect.size.width)
            {
                [self shift:this_row to:i - 1 by:floor((rect.size.width - (lx - rect.origin.x)) / 2)];
                this_row = i;
                ly += maxHeight;
                lx = rect.origin.x;
                rect.size.height += maxHeight;
                maxHeight = 0;
                rows ++;
            }
            
            b.origin.x = lx;
            b.origin.y = ly;
            
            lx += b.size.width;
            
            if (b.size.height > maxHeight)
                maxHeight = b.size.height;
                
            metaView->pending_frame = b;
        }
        
        [self shift:this_row to:[metaViews count]-1 by:floor( (rect.size.width - (lx-rect.origin.x))/2 )];

        for (NSUInteger i = 0; i < [metaViews count]; i ++)
        {
            SGWrapViewMetaView *metaView = [metaViews objectAtIndex:i];
            if (![[metaView view] isHidden])
                [metaView setFrame:metaView->pending_frame];
        }
        
        rect.size.height += maxHeight;
    }

    // Set our frame size to accomodate the child views.
    // N O T E: We could be rotated so the height is the width, etc..
    //          We are ASSUMING +/- 90 degree rotation only!
    
    if ([self boundsRotation] != 0)
    {
        CGFloat x = rect.size.width;
        rect.size.width = rect.size.height;
        rect.size.height = x;
    }
    
    [self setFrameSize:rect.size];
}

- (void) do_layout
{
    [self do_wrap_layout];
}

- (BOOL) isFlipped
{
    return YES;
}

- (NSUInteger) rowCount
{
    return rows;
}

#if 0
- (void) drawRect:(NSRect) aRect
{
    [super drawRect:aRect];

    [[NSColor redColor] set];
    [[NSGraphicsContext currentContext] setShouldAntialias:false];
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:[self bounds]];
    [p setLineWidth:5];
    [p stroke];
}
#endif

@end
