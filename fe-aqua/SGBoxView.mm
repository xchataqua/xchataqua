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

#include <stdarg.h>
#import "SGBoxView.h"

//////////////////////////////////////////////////////////////////////

static void DP (const char *fmt, ...)
{
#if 0
	va_list ap;
	va_start(ap, fmt);
	//vprintf (fmt, ap);
    NSLogv ([NSString stringWithUTF8String:fmt], ap);
	va_end(ap);
#endif
}

//////////////////////////////////////////////////////////////////////

@interface sgbox_meta_view : SGMetaView
{
    short	just;
}

- (id) initWithView:(NSView *) view;
- (void) set_justification:(short) new_just;
- (short) justification;
- (NSComparisonResult) less_than_x:(id) other;
- (NSComparisonResult) less_than_y:(id) other;

@end

@implementation sgbox_meta_view

- (id)initWithView:(NSView *) the_view;
{
    [super initWithView:the_view];
    
    just = SGBoxMinorDefaultJustification;
    
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];
    self->just = [decoder decodeIntForKey:@"justification"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[super encodeWithCoder:encoder];
    [encoder encodeInt:self->just forKey:@"justification"];
}

- (void) set_justification:(short) new_just
{
    just = new_just;
}

- (short) justification
{
    return just;
}

- (NSComparisonResult) less_than_x:(id) other
{
    sgbox_meta_view *ov = (sgbox_meta_view *) other;
    
    NSRect me = [view frame];
    NSRect him = [ov->view frame];

    return me.origin.x < him.origin.x ? NSOrderedAscending :
           me.origin.x > him.origin.x ? NSOrderedDescending :
                                        NSOrderedSame;
}

- (NSComparisonResult) less_than_y:(id) other
{
    sgbox_meta_view *ov = (sgbox_meta_view *) other;
    
    NSRect me = [view frame];
    NSRect him = [ov->view frame];
    
    return me.origin.y < him.origin.y ? NSOrderedAscending :
           me.origin.y > him.origin.y ? NSOrderedDescending :
                                        NSOrderedSame;
}

@end

@implementation SGBoxView

- (void) SGBoxViewPrivateInit
{
    self->minorjust = SGBoxMinorCenterJustification;
    self->majorjust = SGBoxMajorFirstJustification;
    self->minormargin = 0;
    self->majorinnermargin = 0;
    self->majorouttermargin = 0;
    self->orient = SGBoxHorizontal;
    self->order = SGBoxFIFO;
}

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    [self SGBoxViewPrivateInit];    
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];

    self->minorjust = [decoder decodeIntForKey:@"minorjust"];
    self->majorjust = [decoder decodeIntForKey:@"majorjust"];
    self->minormargin = [decoder decodeIntForKey:@"minormargin"];
    self->majorinnermargin = [decoder decodeIntForKey:@"majorinnermargin"];
    self->majorouttermargin = [decoder decodeIntForKey:@"majorouttermargin"];
    self->orient = [decoder decodeIntForKey:@"orient"];
    self->order = [decoder decodeIntForKey:@"order"];
    self->stretch = [decoder decodeObjectForKey:@"stretch"];
    
    [self queue_layout];
    
	return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[super encodeWithCoder:encoder];
    [encoder encodeInt:self->minorjust forKey:@"minorjust"];
    [encoder encodeInt:self->majorjust forKey:@"majorjust"];
    [encoder encodeInt:self->minormargin forKey:@"minormargin"];
    [encoder encodeInt:self->majorinnermargin forKey:@"majorinnermargin"];
    [encoder encodeInt:self->majorouttermargin forKey:@"majorouttermargin"];
    [encoder encodeInt:self->orient forKey:@"orient"];
    [encoder encodeInt:self->order forKey:@"order"];
    [encoder encodeConditionalObject:self->stretch forKey:@"stretch"];
}

static NSRect flip (NSRect r)
{
    NSRect rr;
    rr.origin.x = r.origin.y;
    rr.origin.y = r.origin.x;
    rr.size.width = r.size.height;
    rr.size.height = r.size.width;
    return rr;
}

- (void) sizeToFit
{
    [super sizeToFit];
    
    NSSize sz;
    sz.height = 0;
    sz.width = majorouttermargin + majorouttermargin;
    
    for (unsigned int i = 0; i < [meta_views count]; i ++)
    {
        SGMetaView *meta_view = [meta_views objectAtIndex:i];
        NSRect r = [meta_view prefSize];
        if (orient == SGBoxVertical)
            r = flip (r);
        sz.width += r.size.width;
        if (r.size.height > sz.height)
            sz.height = r.size.height;
    }
    
    if ([meta_views count] > 1)
        sz.width += [meta_views count] * majorinnermargin;
        
    sz.height += minormargin + minormargin;

    if (orient == SGBoxVertical)
    {
        float xx = sz.width;
        sz.width = sz.height;
        sz.height = xx;
    }
    
    [self setFrameSize:sz];
    
    // This is needed to cleanup after one of our children
    // but I don't know why.
    //[[self superview] setNeedsDisplay:YES];
}

- (id) newMetaView:(NSView *) view
{
    return [[[sgbox_meta_view alloc] initWithView:view] autorelease];
}

- (void) justify:(NSRect *) b inMe:(NSRect *) r with:(short) justification
{
    if (justification == SGBoxMinorDefaultJustification)
        justification = minorjust;
        
    switch (justification)
    {
        case SGBoxMinorCenterJustification:
            b->origin.y = floor (r->origin.y + (r->size.height - b->size.height) / 2 + .5);
            break;

        case SGBoxMinorLastJustification:
            b->origin.y = r->origin.y + r->size.height - b->size.height;
            break;
            
        case SGBoxMinorFirstJustification:
            b->origin.y = r->origin.y;
            break;
            
        case SGBoxMinorFullJustification:
            b->origin.y = r->origin.y;
            b->size.height = r->size.height;
            break;
    }
}

- (void) do_layout
{
	DP ("Layout box view 0x%x\n", self);
	
    if ([meta_views count] < 1)
        return;
        
    //
    // Keep the "x" order of the object as layed out in IB.  On the first layout,
    // we sort our list by the "x" value of the object.  From here on, any added
    // views will always be at the end
    //
    //if (first_layout)
    //    [meta_views sortUsingSelector:orient == SGBoxHorizontal ? 
    //        @selector (less_than_x:) : @selector (less_than_y:)];   

    NSRect r = [self bounds];
    
	DP ("I am %f %f %f %f 0x%x\n", r.origin.x, r.origin.y, r.size.width, r.size.height, self);
    DP ("I have %d children\n", [meta_views count]);
    
    if (orient == SGBoxVertical)
        r = flip (r);

    r.origin.x += majorouttermargin;
    r.origin.y += minormargin;
    r.size.width -= majorouttermargin + majorouttermargin;
    r.size.height -= minormargin + minormargin;

    // Start from the left.. go until the end or we hit the "stretch" view.
    // If our majorjust is center or full, stretch makes no sense..
    // TBD: Clean this crap up..  Too much repeated code!!
    
    bool will_stretch = majorjust != SGBoxMajorCenterJustification &&
                        majorjust != SGBoxMajorFullJustification &&
                        stretch != nil;
                      
    float lx = r.origin.x;
    
    int first;
    int stop;
    int incr;
    
    if (order == SGBoxFIFO)
    {
        first = 0;
        stop = [meta_views count];
        incr = 1;
    }
    else
    {
        first = [meta_views count] - 1;
        stop = -1;
        incr = -1;
    }
    
    int i;    
    for (i = first; i != stop; i += incr)
    {
        id meta_view = [meta_views objectAtIndex:i];
        
        if (will_stretch && stretch == [meta_view view])
            break;
            
        if (![[meta_view view] isHidden])
        {
            NSRect b = [meta_view prefSize];
        
            if (orient == SGBoxVertical)
                b = flip (b);
    
            b.origin.x = lx;
            [self justify:&b inMe:&r with:[meta_view justification]];
            
            lx += b.size.width + majorinnermargin;

            if (orient == SGBoxVertical)
                b = flip (b);
    
            DP ("Setting 0x%x to %f %f %f %f\n",
                meta_view, b.origin.x, b.origin.y, b.size.width, b.size.height);
                
            [meta_view setFrame:b];
        }
    }
    
    if (!will_stretch && majorjust == SGBoxMinorCenterJustification)
    {
        int leftovers = (int) (r.origin.x + r.size.width - lx + majorinnermargin);
        int shift = leftovers / 2;
        
        for (unsigned int i = 0; i < [meta_views count]; i ++)
        {
            id meta_view = [meta_views objectAtIndex:i];
            if (![[meta_view view] isHidden])
            {
                NSRect b = [[meta_view view] frame];
                if (orient == SGBoxVertical)
                    b = flip (b);
                b.origin.x += shift;
                if (orient == SGBoxVertical)
                    b = flip (b);

                DP ("Setting 0x%x to %f %f %f %f\n",
                    meta_view, b.origin.x, b.origin.y, b.size.width, b.size.height);

                [meta_view setFrame:b];
            }
        }
        
        return;
    }
    
    // and then from the right

    float rx = r.origin.x + r.size.width;

    if (i != stop)
    for (int j = stop - incr; j != i; j -= incr)
    {
        id meta_view = [meta_views objectAtIndex:j];
        
        if (stretch == [meta_view view])
            break;
            
        if (![[meta_view view] isHidden])
        {
            NSRect b = [meta_view prefSize];

            if (orient == SGBoxVertical)
                b = flip (b);
        
            b.origin.x = rx - b.size.width;
            [self justify:&b inMe:&r with:[meta_view justification]];
            
            rx -= b.size.width + majorinnermargin;

            if (orient == SGBoxVertical)
                b = flip (b);

            DP ("Setting 0x%x to %f %f %f %f\n",
                meta_view, b.origin.x, b.origin.y, b.size.width, b.size.height);

            [meta_view setFrame:b];
        }
    }
    
    // the stretch view goes from lx to rx
    
    if (i != stop)
    {
        // We do this one.. visible or not.  Is this a good idea?
        
        id meta_view = [meta_views objectAtIndex:i];
        
        NSRect b = [meta_view prefSize];

        if (orient == SGBoxVertical)
            b = flip (b);

        b.origin.x = lx;
        [self justify:&b inMe:&r with:[meta_view justification]];
        b.size.width = rx - lx;
        
        if (orient == SGBoxVertical)
            b = flip (b);

        DP ("Setting 0x%x to %f %f %f %f\n",
            meta_view, b.origin.x, b.origin.y, b.size.width, b.size.height);

        [meta_view setFrame:b];
    }
}

- (void) setOrientation:(int) new_orient
{
    self->orient = new_orient;
    [self queue_layout];
}
    
- (void) setStretchView:(NSView *) view
{
    self->stretch = view;
    [self queue_layout];
}

- (NSView *) stretchView
{
    return stretch;
}

- (void) setMajorJustification:(short) new_just
{
    majorjust = new_just;
    [self queue_layout];
}

- (short) majorJustification;
{
    return majorjust;
}

- (void) setMinorDefaultJustification:(short) new_just
{
    minorjust = new_just;
    [self queue_layout];
}

- (short) minorJustification
{
    return minorjust;
}

- (void) setMinorJustificationFor:(NSView *) view to:(short) new_just
{
    sgbox_meta_view *mv = (sgbox_meta_view *) [self find_view:view];
    if (mv)
        [mv set_justification:new_just];
    [self queue_layout];
}

- (void) setMinorMargin:(short) v
{
    self->minormargin = v;
    [self queue_layout];
}

- (void) setMajorInnerMargin:(short) h
{
    self->majorinnermargin = h;
    [self queue_layout];
}

- (short) majorInnerMargin
{
    return majorinnermargin;
}

- (void) setMajorOutterMargin:(short) h
{
    self->majorouttermargin = h;
    [self queue_layout];
}

- (short) majorOutterMargin
{
    return majorouttermargin;
}

- (void) setOrder:(int) new_order
{
    self->order = new_order;
    [self queue_layout];
}

- (int) orientation
{
    return orient;
}

- (int) order
{
    return order;
}

@end
