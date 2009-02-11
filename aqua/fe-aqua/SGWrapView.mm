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

- (void) SGWrapViewPrivateInit
{
}

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    [self SGWrapViewPrivateInit];    
    return self;
}

- (id) newMetaView:(NSView *) view
{
    return [[[SGWrapViewMetaView alloc] initWithView:view] autorelease];
}

- (void) shift:(unsigned) start
            to:(unsigned) stop
            by:(unsigned) by
{
    for (unsigned i = start; i <= stop; i ++)
    {
        SGWrapViewMetaView *meta_view = [meta_views objectAtIndex:i];
        if (! [[meta_view view] isHidden])
            meta_view->pending_frame.origin.x += by;
    }
}

- (void) do_wrap_layout
{
    NSRect r = [self bounds];

    float lx = r.origin.x;
    float ly = r.origin.y;

    rows = 0;
    
    unsigned this_row = 0;
    float max_h = 0;

    r.size.height = 0;
    
    if ([meta_views count])
    {
        rows = 1;
        
        for (unsigned i = 0; i < [meta_views count]; i ++)
        {
            SGWrapViewMetaView *meta_view = [meta_views objectAtIndex:i];
     
            if ([[meta_view view] isHidden])
                continue;

            NSRect b = [meta_view prefSize];
        
            if (i != this_row && lx + b.size.width > r.origin.x + r.size.width)
            {
                [self shift:this_row to:i - 1 by:floor((r.size.width - (lx - r.origin.x)) / 2)];
                this_row = i;
                ly += max_h;
                lx = r.origin.x;
                r.size.height += max_h;
                max_h = 0;
                rows ++;
            }
            
            b.origin.x = lx;
            b.origin.y = ly;
            
            lx += b.size.width;
            
            if (b.size.height > max_h)
                max_h = b.size.height;
                
            meta_view->pending_frame = b;
        }
        
        [self shift:this_row to:[meta_views count] - 1 by:floor((r.size.width - (lx - r.origin.x)) / 2)];

        for (unsigned i = 0; i < [meta_views count]; i ++)
        {
            SGWrapViewMetaView *meta_view = [meta_views objectAtIndex:i];
            if (![[meta_view view] isHidden])
                [meta_view setFrame:meta_view->pending_frame];
        }
        
        r.size.height += max_h;
    }

    // Set our frame size to accomodate the child views.
    // N O T E: We could be rotated so the height is the width, etc..
    //          We are ASSUMING +/- 90 degree rotation only!
    
    if ([self boundsRotation] != 0)
    {
        float x = r.size.width;
        r.size.width = r.size.height;
        r.size.height = x;
    }
    
    [self setFrameSize:r.size];
}

- (void) do_layout
{
    [self do_wrap_layout];
}

- (BOOL) isFlipped
{
    return YES;
}

- (unsigned) rowCount
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
