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

#import "SGView.h"

//////////////////////////////////////////////////////////////////////
    
@interface PendingLayouts : NSObject
{
    NSMutableArray *penders;
}
@end

@implementation PendingLayouts

- (id) init
{
    self = [super init];
    penders = [[NSMutableArray arrayWithCapacity:10] retain];
    return self;
}

- (void) dealloc
{
    [penders release];
    [super dealloc];
}

- (void) addPendingLayout:(NSView *) v
{
    if ([penders count] == 0)
    {
#if 1
        [[NSRunLoop currentRunLoop] performSelector:@selector (do_layouts)
            target:self argument:NULL order:0
            modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];
#else
        [NSApp addAfterEvent:self sel:@selector (do_layouts)];
#endif
    }
    
    [penders addObject:v];
}

- (void) do_layouts
{
    while ([penders count])
    {
        SGView *v = [penders lastObject];
        [v retain];
        [penders removeLastObject];
        [v layout_maybe];
        [v release];
    }
}

+ (void) addPendingLayout:(SGView *) v
{
    static PendingLayouts *pl;
    if (!pl)
        pl = [[PendingLayouts alloc] init];
    [pl addPendingLayout:v];
}

@end

//////////////////////////////////////////////////////////////////////

@interface NSViewOverride : NSView
@end

@implementation NSViewOverride

- (void) setHidden:(BOOL) flag
{
    [super setHidden:flag];
    
    if ([[[self superview] class] isSubclassOfClass:[SGView class]])
        [(SGView *) [self superview] queue_layout];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGMetaView

- (id)initWithView:(NSView *) the_view;
{
    self->view = the_view;
    [self reset_pref_size];
    [view retain];
    
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
	view = [[decoder decodeObjectForKey:@"view"] retain];
	last_size = [decoder decodeRectForKey:@"last_size"];
	pref_size = [decoder decodeRectForKey:@"pref_size"];
	return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[encoder encodeConditionalObject:view forKey:@"view"];
	[encoder encodeRect:last_size forKey:@"last_size"];
	[encoder encodeRect:pref_size forKey:@"pref_size"];
}

- (void) dealloc
{
    [view release];
    [super dealloc];
}

- (void) setView:(NSView *) newView
{
    [view release];
    view = newView;
    [view retain];
}

- (void) setFrame:(NSRect) frame
{
	//NSLog (@"%x %f %f %f %f", meta_view, frame.origin.x,
	//	frame.origin.y, frame.size.width, frame.size.height);
		
    frame = NSIntegralRect (frame);
    self->last_size = frame;
    [self->view setFrame:frame];
    [self->view setNeedsDisplay:true];            
}

- (void) reset_pref_size
{
    self->pref_size = [view frame];
}

- (NSView *) view { return self->view; }
- (NSRect) prefSize { return self->pref_size; }

@end

//////////////////////////////////////////////////////////////////////

@implementation SGView

+ (void) initialize
{
    if (self == [SGView class])
        [NSViewOverride poseAsClass:[NSView class]];
}

- (void) SGViewPrivateInit
{
	[self setAutoresizesSubviews:YES];
	
	meta_views = [[NSMutableArray alloc] init];
    self->first_layout = true;
    self->pending_layout = false;
    self->in_my_layout = false;
    self->in_dtor = false;
}

- (id) initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
	[self SGViewPrivateInit];
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];
	[self SGViewPrivateInit];
	self->first_layout = false;	// This feels right
	[meta_views release];
	meta_views = [[NSMutableArray alloc] initWithCoder:decoder];
    for (unsigned i = 0; i < [meta_views count]; i ++)
        [self didAddSubview:[[meta_views objectAtIndex:i] view]];
    return self;
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[super encodeWithCoder:encoder];
	[meta_views encodeWithCoder:encoder];
}

- (void) dealloc
{
    in_dtor = true;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [meta_views release];
    [super dealloc];
}

- (void) do_layout
{
}

- (void) setAutoSizeToFit:(bool) sf
{
    auto_size_to_fit = sf;
}

- (void) sizeToFit
{
    needs_size_to_fit = false;
}

- (void) layoutNow
{    
    pending_layout = false;
    in_my_layout = true;
    
    if (needs_size_to_fit)
        [self sizeToFit];
        
    [self do_layout];
    [self setNeedsDisplay:true];

    in_my_layout = false;
    first_layout = false;
}

- (void) layout_maybe
{
    if (pending_layout)
        [self layoutNow];
}

#if 0
static void noDisplay (NSView *v)
{
    [v setNeedsDisplay:NO];
    NSArray *sub = [v subviews];
    for (unsigned i = 0; i < [sub count]; i ++)
        noDisplay ([sub objectAtIndex:i]);
}
#endif

- (void) queue_layout
{
#if 1
    [self layoutNow];
#else
    if (!pending_layout)
    {
        [PendingLayouts addPendingLayout:self];
        pending_layout = true;
    }
#endif
}

- (void) drawRect:(NSRect) aRect
{
    // Don't let views draw if they have pending layouts
    //[self layout_maybe];
    //if (pending_layout)
        //return;
        
    [super drawRect:aRect];

#if 0
    [[NSColor redColor] set];
    [[NSGraphicsContext currentContext] setShouldAntialias:false];
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:[self bounds]];
    [p setLineWidth:5];
    [p stroke];
#endif
}

- (SGMetaView *) find_view:(NSView *) the_view
{
    unsigned int i = [self viewOrder:the_view];
    if (i == ~ (unsigned) 0)
        return NULL;
    return [meta_views objectAtIndex:i];
}

- (void) setOrder:(unsigned) order
          forView:(NSView *) the_view
{
    unsigned int i = [self viewOrder:the_view];
    if (i == ~ (unsigned) 0)
        return;
    id metaview = [meta_views objectAtIndex:i];
    [metaview retain];
    [meta_views removeObjectAtIndex:i];
    if (order > [meta_views count])
        [meta_views addObject:metaview];
    else
        [meta_views insertObject:metaview atIndex:order];
    [metaview release];
    [self queue_layout];
}

- (unsigned) viewOrder:(NSView *) the_view
{
    for (unsigned int i = 0; i < [meta_views count]; i ++)
    {
        id meta_view = [meta_views objectAtIndex:i];
        if ([meta_view view] == the_view)
            return i;
    }
    return ~0;
}

//- (void) resizeSubviewsWithOldSize:(NSSize) oldBoundsSize Broken with rotation!
- (void) i_did_resize
{
    if (in_my_layout)
        return;

    // We are being given new dimensions and/or location.
    // If we're being asked to move, then don't do a layout.
    // TBD: This might make sense.. not sure now.
    //if (! NSEqualSizes (oldBoundsSize, [self frame].size))
        [self layoutNow];
}

- (void) setFrame:(NSRect) frameRect
{
    [super setFrame:frameRect];
    [self i_did_resize];
}

- (void) setFrameSize:(NSSize) newSize
{
    [super setFrameSize:newSize];
    [self i_did_resize];
}

- (BOOL) isFlipped
{
    return NO;
}

- (BOOL) isOpaque
{
    return NO;
}

- (void) subview_did_resize:(NSNotification *)notification
{
    // A child view just changed size.  If we are in layout, then we
    // can assume he's changed because we told him to.
    // Sepcifically, we don't want to change the pref_size unless
    // someone other than us changed him.
    
    // in_my_layout is not enough info.. SGViews that change other
    // SGViews that change themselvs causes in_my_layout to be true
    // when we really _do_ want a resize.  See below..
    
    //if (in_my_layout)
        //return;
        
    NSView *subview = (NSView *) [notification object];
    SGMetaView *meta_view = [self find_view:subview];
    
    if (in_my_layout && (
        NSEqualRects (meta_view->last_size, [subview frame]) ||
        NSEqualRects (meta_view->pref_size, [subview frame])))
    {
        return;
    }

    [meta_view reset_pref_size];
    
    if (auto_size_to_fit)
        needs_size_to_fit = true;
        
    [self queue_layout];
}

- (SGMetaView *) newMetaView:(NSView *) view
{
    return [[[SGMetaView alloc] initWithView:view] autorelease];
}

- (NSArray *) metaViews
{
    return meta_views;
}

- (void) didAddSubview:(NSView *) subview
{
    [super didAddSubview:subview];

    if ([self find_view:subview] == NULL)
        [meta_views addObject:[self newMetaView:subview]];

    [subview setPostsFrameChangedNotifications:true];
    [[NSNotificationCenter defaultCenter] addObserver:self 
        selector:@selector (subview_did_resize:)
        name:NSViewFrameDidChangeNotification object:subview];
    
    if (auto_size_to_fit)
        needs_size_to_fit = true;

    [self queue_layout];
}

- (void) willRemoveSubview:(NSView *) subview
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
        name:NSViewFrameDidChangeNotification object:subview];

    [super willRemoveSubview:subview];

    if (in_dtor)
        return;
            
    id meta_view = [self find_view:subview];
    [meta_views removeObject:meta_view];
    
    if (auto_size_to_fit)
        needs_size_to_fit = true;

    [self queue_layout];
}

- (void) replaceSubview:(NSView *)oldView 
				   with:(NSView *)newView
{
	// We are about to remove oldView and add newView.
	// We'll need to stuff our metadata back in
	
	SGMetaView *meta_view = [self find_view:oldView];

	if (meta_view)
        [meta_view setView:newView];
    
    [super replaceSubview:oldView with:newView];
}

@end
