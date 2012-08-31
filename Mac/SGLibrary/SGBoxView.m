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

#define DEBUG_BOXVIEW NO

#import "SGDebug.h"
#import "SGBoxView.h"

@interface SGBoxMetaView : SGMetaView {
    SGBoxMinorJustification    justification;
}
@property (nonatomic, assign) SGBoxMinorJustification justification;

@end

@implementation SGBoxMetaView
@synthesize justification;

- (id)initWithView:(NSView *) the_view;
{
    self = [super initWithView:the_view];
    if (self != nil) {
        justification = SGBoxMinorJustificationDefault;
    }
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
    self = [super initWithCoder:decoder];
    if (self != nil) {
        self->justification = (SGBoxMinorJustification)[decoder decodeIntForKey:@"justification"];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:self->justification forKey:@"justification"];
}


@end

#pragma mark -

NSRect NSRectFlip (NSRect rect)
{
    return NSMakeRect(rect.origin.y,rect.origin.x,rect.size.height,rect.size.width);
}

@implementation SGBoxView
@synthesize stretchView,orientation,order;
@synthesize majorJustification,minorJustification;
@synthesize minorMargin,majorInnerMargin,majorOutterMargin;

- (id) initWithFrame:(NSRect) frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {
        self->minorJustification = SGBoxMinorJustificationCenter;
        self->majorJustification = SGBoxMajorJustificationFirst;
        self->minorMargin = 0.0f;
        self->majorInnerMargin = 0.0f;
        self->majorOutterMargin = 0.0f;
        self->orientation = SGBoxOrientationHorizontal;
        self->order = SGBoxOrderFIFO;
    }
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
    self = [super initWithCoder:decoder];
    if (self != nil) {
        // load data from user defiend runtime attributes
        [self queue_layout];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:self->minorJustification     forKey:@"minorjust"];
    [encoder encodeInt:self->majorJustification     forKey:@"majorjust"];
    [encoder encodeFloat:self->minorMargin          forKey:@"minormargin"];
    [encoder encodeFloat:self->majorInnerMargin     forKey:@"majorinnermargin"];
    [encoder encodeFloat:self->majorOutterMargin    forKey:@"majorouttermargin"];
    [encoder encodeInt:self->orientation forKey:@"orient"];
    [encoder encodeInt:self->order forKey:@"order"];
    [encoder encodeConditionalObject:self->stretchView forKey:@"stretch"];
}

- (void) sizeToFit
{
    [super sizeToFit];
    
    NSSize size = NSMakeSize(majorOutterMargin+majorOutterMargin, 0.0f);
    
    for (SGMetaView *metaView in metaViews) {
        NSRect r = [metaView prefSize];
        if (orientation == SGBoxOrientationVertical)
            r = NSRectFlip (r);
        size.width += r.size.width;
        if (r.size.height > size.height)
            size.height = r.size.height;
    }
    
    if ([metaViews count] > 1)
        size.width += [metaViews count] * majorInnerMargin;
        
    size.height += minorMargin + minorMargin;

    if (orientation == SGBoxOrientationVertical)
    {
        size = NSMakeSize(size.height, size.width);
    }
    
    [self setFrameSize:size];
    
    // This is needed to cleanup after one of our children
    // but I don't know why.
    //[[self superview] setNeedsDisplay:YES];
}

- (id) metaViewWithView:(NSView *) view
{
    return [[[SGBoxMetaView alloc] initWithView:view] autorelease];
}

- (void) justify:(NSRect *) b inMe:(NSRect *) r with:(SGBoxMinorJustification) justification
{
    if (justification == SGBoxMinorJustificationDefault)
        justification = minorJustification;
        
    switch (justification)
    {
        case SGBoxMinorJustificationCenter:
            b->origin.y = floor (r->origin.y + (r->size.height - b->size.height) / 2 + .5);
            break;

        case SGBoxMinorJustificationLast:
            b->origin.y = r->origin.y + r->size.height - b->size.height;
            break;
            
        case SGBoxMinorJustificationFirst:
            b->origin.y = r->origin.y;
            break;
            
        case SGBoxMinorJustificationFull:
            b->origin.y = r->origin.y;
            b->size.height = r->size.height;
            break;
        default: break; // SGBoxMinorJustificationDefault
    }
}

- (void) do_layout
{
    SGLog (DEBUG_BOXVIEW, @"Layout box view %p\n", self);
    
    if ([metaViews count] < 1) return;
        
    //
    // Keep the "x" order of the object as layed out in IB.  On the first layout,
    // we sort our list by the "x" value of the object.  From here on, any added
    // views will always be at the end
    //
    //if (first_layout)
    //    [metaViews sortUsingSelector:orientation == SGBoxOrientationHorizontal ? 
    //        @selector (less_than_x:) : @selector (less_than_y:)];   

    NSRect r = [self bounds];
    
    SGLog (DEBUG_BOXVIEW, @"I am %f %f %f %f %p\n", r.origin.x, r.origin.y, r.size.width, r.size.height, self);
    SGLog (DEBUG_BOXVIEW, @"I have %ld children\n", [metaViews count]);
    
    if (orientation == SGBoxOrientationVertical)
        r = NSRectFlip(r);

    r.origin.x += majorOutterMargin;
    r.origin.y += minorMargin;
    r.size.width -= majorOutterMargin + majorOutterMargin;
    r.size.height-= minorMargin + minorMargin;

    // Start from the left.. go until the end or we hit the "stretch" view.
    // If our majorjust is center or full, stretch makes no sense..
    // TBD: Clean this crap up..  Too much repeated code!!
    
    bool will_stretch = majorJustification != SGBoxMajorJustificationCenter &&
                        majorJustification != SGBoxMajorJustificationFull &&
                        stretchView != nil;
                      
    CGFloat lx = r.origin.x;
    
    NSInteger first, stop, incr;
    
    if (order == SGBoxOrderFIFO)
    {
        first = 0;
        stop = [metaViews count];
        incr = 1;
    }
    else
    {
        first = [metaViews count] - 1;
        stop = -1;
        incr = -1;
    }
    
    NSInteger i;
    for (i = first; i != stop; i += incr)
    {
        id metaView = [metaViews objectAtIndex:i];
        
        if (will_stretch && stretchView == [metaView view])
            break;
            
        if (![[metaView view] isHidden])
        {
            NSRect b = [metaView prefSize];
        
            if (orientation == SGBoxOrientationVertical)
                b = NSRectFlip (b);
    
            b.origin.x = lx;
            [self justify:&b inMe:&r with:[metaView justification]];
            
            lx += b.size.width + majorInnerMargin;

            if (orientation == SGBoxOrientationVertical)
                b = NSRectFlip (b);
    
            SGLog (DEBUG_BOXVIEW, @"Setting %p to %f %f %f %f\n",
                     metaView, b.origin.x, b.origin.y, b.size.width, b.size.height);
                
            [metaView setFrame:b];
        }
    }
    
    if (!will_stretch && majorJustification == SGBoxMajorJustificationCenter)
    {
        CGFloat shift = (r.origin.x + r.size.width - lx + majorInnerMargin) / 2;
        
        for (NSUInteger i = 0; i < [metaViews count]; i ++)
        {
            id metaView = [metaViews objectAtIndex:i];
            if (![[metaView view] isHidden])
            {
                NSRect b = [[metaView view] frame];
                if (orientation    == SGBoxOrientationVertical)
                    b = NSRectFlip (b);
                b.origin.x += shift;
                if (orientation == SGBoxOrientationVertical)
                    b = NSRectFlip (b);

                SGLog (DEBUG_BOXVIEW, @"Setting %p to %f %f %f %f\n",
                         metaView, b.origin.x, b.origin.y, b.size.width, b.size.height);

                [metaView setFrame:b];
            }
        }
        
        return;
    }
    
    // and then from the right

    CGFloat rx = r.origin.x + r.size.width;

    if (i != stop)
    for (NSInteger j = stop - incr; j != i; j -= incr)
    {
        id metaView = [metaViews objectAtIndex:j];
        
        if (stretchView == [metaView view])
            break;
            
        if (![[metaView view] isHidden])
        {
            NSRect b = [metaView prefSize];

            if (orientation == SGBoxOrientationVertical)
                b = NSRectFlip (b);
        
            b.origin.x = rx - b.size.width;
            [self justify:&b inMe:&r with:[metaView justification]];
            
            rx -= b.size.width + majorInnerMargin;

            if (orientation == SGBoxOrientationVertical)
                b = NSRectFlip (b);

            SGLog (DEBUG_BOXVIEW, @"Setting %p to %f %f %f %f\n",
                     metaView, b.origin.x, b.origin.y, b.size.width, b.size.height);

            [metaView setFrame:b];
        }
    }
    
    // the stretch view goes from lx to rx
    
    if (i != stop)
    {
        // We do this one.. visible or not.  Is this a good idea?
        
        id metaView = [metaViews objectAtIndex:i];
        
        NSRect b = [metaView prefSize];

        if (orientation == SGBoxOrientationVertical)
            b = NSRectFlip (b);

        b.origin.x = lx;
        [self justify:&b inMe:&r with:[metaView justification]];
        b.size.width = rx - lx;
        
        if (orientation == SGBoxOrientationVertical)
            b = NSRectFlip (b);

        SGLog (DEBUG_BOXVIEW, @"Setting %p to %f %f %f %f\n",
                 metaView, b.origin.x, b.origin.y, b.size.width, b.size.height);

        [metaView setFrame:b];
    }
}

#pragma mark Property Interface
    
- (void) setStretchView:(NSView *) view
{
    self->stretchView = view;
    [self queue_layout];
}

- (void) setMajorJustification:(SGBoxMajorJustification) aJustification
{
    majorJustification = aJustification;
    [self queue_layout];
}

- (void) setMinorDefaultJustification:(SGBoxMinorJustification) aJustification
{
    minorJustification = aJustification;
    [self queue_layout];
}

- (void) setMinorJustificationFor:(NSView *) view to:(SGBoxMinorJustification) aJustification
{
    SGBoxMetaView *mv = (SGBoxMetaView *) [self findViewFor:view];
    if (mv)
        [mv setJustification:aJustification];
    [self queue_layout];
}

- (void) setMinorMargin:(SGBoxMargin) v
{
    self->minorMargin = v;
    [self queue_layout];
}

- (void) setMajorInnerMargin:(SGBoxMargin) h
{
    self->majorInnerMargin = h;
    [self queue_layout];
}

- (void) setMajorOutterMargin:(SGBoxMargin) h
{
    self->majorOutterMargin = h;
    [self queue_layout];
}

- (void) setOrientation:(SGBoxOrientation)newOrientation
{
    self->orientation = newOrientation;
    [self queue_layout];
}

- (void) setOrder:(SGBoxOrder)newOrder
{
    self->order = newOrder;
    [self queue_layout];
}

@end
