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

#import "SGFormView.h"

//////////////////////////////////////////////////////////////////////
@interface NSView (SGFormViewAdditions)
- (NSPoint) pointOfCenter;
@end

@implementation NSView (SGFormViewAdditions)

- (NSPoint) pointOfCenter
{
	NSRect frame = [self frame];
    return NSMakePoint (frame.origin.x + frame.size.width / 2,
                        frame.origin.y + frame.size.height/ 2);
}

@end
//////////////////////////////////////////////////////////////////////

typedef enum
{
    SGFormMetaViewStateReset,
    SGFormMetaViewStateVisited,
    SGFormMetaViewStateDone
}	SGFormMetaViewState;

@class SGFormMetaView;

typedef struct SGFormConstraint
{
    CGFloat location;
    SGFormViewAttachment attachment;
    CGFloat offset;
    NSInteger factor;
    SGFormMetaViewState state;
    SGFormMetaView *child;
}	SGFormConstraint;

//////////////////////////////////////////////////////////////////////

@interface SGFormMetaView : SGMetaView
{
  @public
    SGFormConstraint constraints[SGFormViewEdgeCount];
	NSString *identifier;		// Used only for IB
}

@property (nonatomic, retain) NSString *identifier;

- (void) setFinalBounds:(SGFormView *) sender;
- (void) getInitialBounds;

@end

@implementation SGFormMetaView
@synthesize identifier;

- (void) initPrivate
{
	identifier = nil;
	
    for (NSInteger i = 0; i < SGFormViewEdgeCount; i ++)
    {
		self->constraints[i].location = 0.0f;
		self->constraints[i].attachment = SGFormViewAttachmentNone;
		self->constraints[i].offset = 0.0f;
		self->constraints[i].factor = i < 2 ? 1 : -1;
		self->constraints[i].state = SGFormMetaViewStateReset;
		self->constraints[i].child = nil;
    }
}

- (id) initWithView:(NSView *) the_view
{
    [super initWithView:the_view];
	[self initPrivate];
    return self;
}

- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];
	[self initPrivate];
	[self setIdentifier:[decoder decodeObjectForKey:@"identifier"]];
	for (NSInteger i = 0; i < SGFormViewEdgeCount; i ++)
    {
		self->constraints[i].location	= [decoder decodeFloatForKey:[NSString stringWithFormat:@"location_%f", i]];
		self->constraints[i].attachment = [decoder decodeIntForKey:[NSString stringWithFormat:@"attachment_%d", i]];
		self->constraints[i].offset		= [decoder decodeFloatForKey:[NSString stringWithFormat:@"offset_%f", i]];
		self->constraints[i].child		= [decoder decodeObjectForKey:[NSString stringWithFormat:@"child_%d", i]];
    }
	return self;
}

- (void) dealloc
{
	[identifier release];
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *) encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:identifier forKey:@"identifier"];
	for (NSInteger i = 0; i < SGFormViewEdgeCount; i ++)
    {
		[encoder encodeFloat:self->constraints[i].location			forKey:[NSString stringWithFormat:@"location_%f", i]];
		[encoder encodeInt:self->constraints[i].attachment			forKey:[NSString stringWithFormat:@"attachment_%d", i]];
		[encoder encodeInt:self->constraints[i].offset				forKey:[NSString stringWithFormat:@"offset_%f", i]];
		[encoder encodeConditionalObject:self->constraints[i].child	forKey:[NSString stringWithFormat:@"child_%d", i]];
    }
}

- (void) setFinalBounds:(SGFormView *) sender
{
    NSRect rect;
    
    rect.origin.x	= constraints[SGFormViewEdgeLeft].location;
    rect.origin.y	= constraints[SGFormViewEdgeBottom].location;
    rect.size.width = constraints[SGFormViewEdgeRight].location - rect.origin.x;
    rect.size.height= constraints[SGFormViewEdgeTop].location - rect.origin.y;

    [self setFrame:rect];
}

- (void) getInitialBounds
{
    NSRect r = [self prefSize];
    constraints[SGFormViewEdgeBottom].location	= r.origin.y;
    constraints[SGFormViewEdgeLeft].location	= r.origin.x;
    constraints[SGFormViewEdgeTop].location		= (r.origin.y+r.size.height);
    constraints[SGFormViewEdgeRight].location	= (r.origin.x+r.size.width );
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGFormView

- (void) constrain:(NSView *)child edge:(SGFormViewEdge)edge attachment:(SGFormViewAttachment)attachment relativeTo:(NSView *)view offset:(CGFloat)offset
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view: child];
    
    if (!form_child)
        return;

    form_child->constraints[edge].location = 0.0f;
    form_child->constraints[edge].attachment = attachment;
    form_child->constraints[edge].offset = offset;
    form_child->constraints[edge].child = (SGFormMetaView *) [self find_view:view];

    [self queue_layout];
}

- (void) setIdentifier:(NSString *) identifier forView:(NSView *) view
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:view];
    if (!form_child) return;
	[form_child setIdentifier:identifier];
}

- (NSString *) identifierForView:(NSView *) view
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:view];
    if (!form_child) 
		return nil;
	return [form_child identifier];
}

- (BOOL) constraintsForEdge:(NSView *)child edge:(SGFormViewEdge)edge attachment:(SGFormViewAttachment *)attachment_return relativeTo:(NSView **)view_return offset:(CGFloat *)offset_return
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:child];
    if (!form_child) return NO;
	
	*attachment_return = (SGFormViewAttachment) form_child->constraints[edge].attachment;
	*offset_return = form_child->constraints[edge].offset;

	SGFormMetaView *relative_child = form_child->constraints[edge].child;
	*view_return = relative_child ? relative_child->view : nil;
	
	return YES;
}

- (void) bootstrapRelativeTo:(NSView *) relative_view
{
    NSPoint rc = [relative_view pointOfCenter];
    
    NSArray *mviews = [self metaViews];
    
    for (NSUInteger i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        
        if ([view view] == relative_view)
            continue;
     
        NSPoint op = [(NSView *)view pointOfCenter];
        
        [self constrain:[view view]
				   edge:SGFormViewEdgeLeft
			 attachment:SGFormViewAttachmentCenter
			 relativeTo:relative_view
				 offset:(CGFloat) (op.x - rc.x)];
        
        [self constrain:[view view]
				   edge:SGFormViewEdgeTop
			 attachment:SGFormViewAttachmentCenter
			 relativeTo:relative_view
				 offset:(CGFloat) (op.y - rc.y)];
    }
}

- (SGMetaView *) newMetaView:(NSView *) view
{
    return [[[SGFormMetaView alloc] initWithView:view] autorelease];
}

- (bool) edge_should_move_too:(SGFormMetaView *)fc edge:(SGFormViewEdge) edge
{
    // Should edge move if the opposite edge moves.  e.g. If the LEFT
    // edge moves 10 pixels, should the RIGHT edge move too?

    // Simply stated, an edge can move if there are no constraints for
    // that edge or the constraints for that edge are relative to itself
    // (specifies a width) or the edge has not been layed out yet.

    SGFormViewAttachment attachment = fc->constraints[edge].attachment;

    return (attachment == SGFormViewAttachmentNone)
		|| (fc->constraints[edge].state != SGFormMetaViewStateDone)
		|| (attachment == SGFormViewAttachmentView && fc->constraints[edge].child == fc);
}

- (void) move_edge:(jmp_buf) env
                fc:(SGFormMetaView *) fc
              edge:(SGFormViewEdge) edge
             where:(CGFloat) where
         my_bounds:(CGFloat *) my_bounds
recompute_our_size:(BOOL) recompute_our_size
{
    CGFloat diff = where - fc->constraints [edge].location;

    SGFormViewEdge opposite_edge = edge ^ 2;

    if ([self edge_should_move_too:fc edge:opposite_edge])
		fc->constraints [opposite_edge].location += diff;
    else
    {
		// Special Case:  If we are in "recompute" mode and we shrink
		// because of this constraint, then we need to expand the form
		// to accomodate us instead of shrinking the child.

		if (recompute_our_size)
		{
			CGFloat delta = diff * fc->constraints[opposite_edge].factor;

			if (delta < 0)
			{
				if (edge == SGFormViewEdgeTop || edge == SGFormViewEdgeBottom)
					my_bounds[SGFormViewEdgeBottom]-= delta;
				else
					my_bounds[SGFormViewEdgeRight] -= delta;
				
				longjmp (env, 1);
			}
		}
    }

    fc->constraints[edge].location += diff;
}

- (int) layout_edge:(jmp_buf) env
                 fc:(SGFormMetaView *) fc
               edge:(SGFormViewEdge) edge
          my_bounds:(CGFloat *) my_bounds
 recompute_our_size:(BOOL) recompute_our_size
{
    SGFormConstraint *ec = &fc->constraints[edge];

	//NSLog (@"%d", ec->attachment);
	
    if (ec->attachment != SGFormViewAttachmentNone && ec->state != SGFormMetaViewStateDone)
    {
		if (ec->state == SGFormMetaViewStateVisited)
			printf ("FormLayout.layout: Circular dependency!\n");
		else
		{
			CGFloat location = 0;

			ec->state = SGFormMetaViewStateVisited;

			//
			// At this point, we can do the work.
			//

			switch (ec->attachment)
			{
				case SGFormViewAttachmentForm:
					location = my_bounds[edge];
					break;

				case SGFormViewAttachmentView:
					location = ec->factor +	// This IS correct
						   [self layout_edge:env
										  fc:ec->child
										edge:edge ^ 2
								   my_bounds:my_bounds
						  recompute_our_size:recompute_our_size];
					break;

				case SGFormViewAttachmentOppositeView:
					location = [self layout_edge:env
											  fc:ec->child
											edge:edge
									   my_bounds:my_bounds
							  recompute_our_size:recompute_our_size];
					break;

				case SGFormViewAttachmentCenter:
				{
					CGFloat center;

					if (ec->child == nil)	// Center on form
					{
						center = (my_bounds [edge ^ 2] -
							  my_bounds [edge]) / 2;
						if (center < 0) center = -center;
					}
					else
					{
						[self layout_edge:env 
									   fc:ec->child
									 edge:edge ^ 2 
								my_bounds:my_bounds
					   recompute_our_size:recompute_our_size];
							   
						[self layout_edge:env
									   fc:ec->child
									 edge:edge
								my_bounds:my_bounds
					   recompute_our_size:recompute_our_size];

						/* It might be tempting to use the return of
						 * layout_edge rather than the next 2 lines
						 * of code.  Bad idea because the second call to
						 * layout_edge may move the first edge.
						 */

						CGFloat edge1 = ec->child->constraints[edge^2].location;
						CGFloat edge2 = ec->child->constraints[edge].location;
						CGFloat half = (edge1 - edge2) / 2;
						center = ec->child->constraints[edge].location + half;
					}

					// We depend on the opposite edge so lets lay him out
					// first.

					[self layout_edge:env
								   fc:fc
								 edge:edge ^ 2
							my_bounds:my_bounds
				   recompute_our_size:recompute_our_size];

					CGFloat size = fc->constraints [edge ^ 2].location -
						   fc->constraints [edge].location + 1;

					location = center - size / 2;

					break;
				}

				default:
					printf ("FormLayout: Unknown attachment type!\n");
			}

			location += ec->offset * ec->factor;

			[self move_edge:env
						 fc:fc
					   edge:edge
					  where:location
				  my_bounds:my_bounds
		 recompute_our_size:recompute_our_size];

			ec->state = SGFormMetaViewStateDone;
		}
    }

    return fc->constraints [edge].location;
}

- (void) layout_child:(jmp_buf) env 
                   fc:(SGFormMetaView *) fc
            my_bounds:(CGFloat *) my_bounds
   recompute_our_size:(BOOL) recompute_our_size
{
    for (NSInteger edge = 0; edge < SGFormViewEdgeCount; edge ++)
		[self layout_edge:env 
					   fc:fc
					 edge:edge
				my_bounds:my_bounds
	   recompute_our_size:recompute_our_size];
}

- (void) do_layout:(CGFloat *) my_bounds recompute_our_size:(BOOL) recompute_our_size
{
    for (NSInteger count = 0; count < 10000; )
    {
		BOOL worked = YES;

		// 
		// Reset the state of all edges.
		//

		NSArray *mviews = [self metaViews];

		for (NSUInteger i = 0; i < [mviews count]; i ++)
		{
			SGFormMetaView *view = [mviews objectAtIndex:i];

			for (NSInteger edge = 0; edge < SGFormViewEdgeCount; edge ++)
				view->constraints [edge].state = SGFormMetaViewStateReset;
		}

		for (NSUInteger i = 0; i < [mviews count]; i ++)
		{
			SGFormMetaView *view = [mviews objectAtIndex:i];

			// Attempt to avoid laying out of hidden children.
			// An edge from a visible child may depend on an edge
			// from a hidden child, but that should be handled by
			// the recursion in layout_child.

			if ([[view view] isHidden])
				continue;

			jmp_buf env;

			if (setjmp (env) == 0)
				[self layout_child:env 
								fc:view
						 my_bounds:my_bounds
				recompute_our_size:recompute_our_size];
			else
			{
				worked = NO;
				count ++;
				break;
			}
		}

		if (worked)
			break;
    }
}

- (void) do_layout
{
    NSRect r = [self bounds];

	CGFloat my_bounds [4] = {
		r.origin.y,
		r.origin.x,
		r.origin.y + r.size.height,
		r.origin.x + r.size.width ,
	};

	//NSLog (@"new form size %x %d %d %d %d", self,
	//	my_bounds[0],my_bounds[1],my_bounds[2],my_bounds[3]);

    NSArray *mviews = [self metaViews];
    
    for (NSUInteger i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        [view getInitialBounds];
    }

    [self do_layout:my_bounds recompute_our_size:NO];

    for (NSUInteger i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        [view setFinalBounds:self];
    }
}

#if 0
- (void) replaceSubview:(NSView *)oldView with:(NSView *)newView
{
	// We are about to remove oldView and add newView.
	// We'll need to stuff our metadata back in
	
	SGFormMetaView *metaView = [self find_view:oldView];

	if (metaView)
	{
		[metaView retain];
		[super replaceSubview:oldView with:newView];
		SGFormMetaView *new_metaView = [self find_view:newView];
		if (new_metaView)
		{
			for (NSInteger i = 0; i < SGFormViewEdgeCount; i ++)
				new_metaView->constraints[i] = metaView->constraints[i];
			[new_metaView setIdentifier:[metaView identifier]];
		}
		[metaView release];
	}
}
#endif

@end
