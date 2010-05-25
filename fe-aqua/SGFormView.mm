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

NSPoint center_of (NSView *v)
{
    NSRect r = [v frame];
    return NSMakePoint (r.origin.x + r.size.width / 2,
                        r.origin.y + r.size.height / 2);
}

//////////////////////////////////////////////////////////////////////

enum
{
    STATE_RESET,
    STATE_VISITED,
    STATE_DONE
};

@class SGFormMetaView;

struct SGFormConstraint
{
    int location;
    int attachment;
    int offset;
    int factor;
    int state;
    SGFormMetaView *child;
};

//////////////////////////////////////////////////////////////////////

@interface SGFormMetaView : SGMetaView
{
  @public
    SGFormConstraint constraints [4];
	NSString *identifier;		// Used only for IB
}

- (void) set_final_bounds:(SGFormView *) sender;
- (void) get_initial_bounds;
- (void) setIdentifier:(NSString *) identifier;
- (NSString *) identifier;

@end

@implementation SGFormMetaView

- (void) initPrivate
{
	identifier = nil;
	
    for (int i = 0; i < 4; i ++)
    {
		self->constraints[i].location = 0;
		self->constraints[i].attachment = SGFormView_ATTACH_NONE;
		self->constraints[i].offset = 0;
		self->constraints[i].factor = i < 2 ? 1 : -1;
		self->constraints[i].state = STATE_RESET;
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
	for (int i = 0; i < 4; i ++)
    {
		self->constraints[i].location =
			[decoder decodeIntForKey:[NSString stringWithFormat:@"location_%d", i]];
		self->constraints[i].attachment =
			[decoder decodeIntForKey:[NSString stringWithFormat:@"attachment_%d", i]];
		self->constraints[i].offset =
			[decoder decodeIntForKey:[NSString stringWithFormat:@"offset_%d", i]];
		self->constraints[i].child =
			[decoder decodeObjectForKey:[NSString stringWithFormat:@"child_%d", i]];
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
	for (int i = 0; i < 4; i ++)
    {
		[encoder encodeInt:self->constraints[i].location
			forKey:[NSString stringWithFormat:@"location_%d", i]];
		[encoder encodeInt:self->constraints[i].attachment
			forKey:[NSString stringWithFormat:@"attachment_%d", i]];
		[encoder encodeInt:self->constraints[i].offset
			forKey:[NSString stringWithFormat:@"offset_%d", i]];
		[encoder encodeConditionalObject:self->constraints[i].child
			forKey:[NSString stringWithFormat:@"child_%d", i]];
    }
}

- (void) set_final_bounds:(SGFormView *) sender
{
    NSRect rect;
    
    rect.origin.x = (float) constraints [SGFormView_EDGE_LEFT].location;
    rect.origin.y = (float)constraints [SGFormView_EDGE_BOTTOM].location;
    rect.size.width = (float)constraints [SGFormView_EDGE_RIGHT].location - rect.origin.x + 1;
    rect.size.height = (float) constraints [SGFormView_EDGE_TOP].location - rect.origin.y + 1;

    [self setFrame:rect];
}

- (void) get_initial_bounds
{
    NSRect r = [self prefSize];
    
    constraints [SGFormView_EDGE_BOTTOM].location = (int) r.origin.y;
    constraints [SGFormView_EDGE_LEFT].location = (int) r.origin.x;
    constraints [SGFormView_EDGE_TOP].location = (int) r.origin.y + (int) r.size.height - 1;
    constraints [SGFormView_EDGE_RIGHT].location = (int) r.origin.x + (int) r.size.width - 1;
}

- (void) setIdentifier:(NSString *) new_ident
{
	[identifier release];
	identifier = [new_ident retain];
}

- (NSString *) identifier
{
	return identifier;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGFormView

- (void) constrain:(NSView *)      	      child
              edge:(SGFormViewEdge) 	  edge
        attachment:(SGFormViewAttachment) attachment
        relativeTo:(NSView *)             widget
            offset:(int)                  offset
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view: child];
    
    if (!form_child)
        return;

    form_child->constraints[edge].location = 0;
    form_child->constraints[edge].attachment = attachment;
    form_child->constraints[edge].offset = offset;
    form_child->constraints[edge].child = (SGFormMetaView *) [self find_view:widget];

    [self queue_layout];
}

- (void) setIdentifier:(NSString *) identifier
			   forView:(NSView *) view
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:view];
    if (!form_child)
        return;
	[form_child setIdentifier:identifier];
}

- (NSString *) identifierForView:(NSView *) view
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:view];
    if (!form_child) 
		return nil;
	return [form_child identifier];
}

- (BOOL) constraintsForEdge:(NSView *)			     view
					   edge:(SGFormViewEdge)	     edge
				 attachment:(SGFormViewAttachment *) attachment_return
				 relativeTo:(NSView **)              view_return
					 offset:(int *)                  offset_return
{
    SGFormMetaView *form_child = (SGFormMetaView *) [self find_view:view];
    if (!form_child)
        return NO;
	
	*attachment_return = (SGFormViewAttachment) form_child->constraints[edge].attachment;
	*offset_return = form_child->constraints[edge].offset;

	SGFormMetaView *relative_child = form_child->constraints[edge].child;
	*view_return = relative_child ? relative_child->view : nil;
	
	return YES;
}

- (void) bootstrapRelativeTo:(NSView *) relative_view
{
    NSPoint rc = center_of (relative_view);
    
    NSArray *mviews = [self metaViews];
    
    for (unsigned int i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        
        if ([view view] == relative_view)
            continue;
     
        NSPoint op = center_of ([view view]);
        
        [self constrain:[view view]
                edge:SGFormView_EDGE_LEFT
                attachment:SGFormView_ATTACH_CENTER
                relativeTo:relative_view
                offset:(int) (op.x - rc.x)];
        
        [self constrain:[view view]
                edge:SGFormView_EDGE_TOP
                attachment:SGFormView_ATTACH_CENTER
                relativeTo:relative_view
                offset:(int) (op.y - rc.y)];
    }
}

- (SGMetaView *) newMetaView:(NSView *) view
{
    return [[[SGFormMetaView alloc] initWithView:view] autorelease];
}

- (bool) edge_should_move_too:(SGFormMetaView *) fc
                         edge:(int) edge
{
    // Should edge move if the opposite edge moves.  e.g. If the LEFT
    // edge moves 10 pixels, should the RIGHT edge move too?

    // Simply stated, an edge can move if there are no constraints for
    // that edge or the constraints for that edge are relative to itself
    // (specifies a width) or the edge has not been layed out yet.

    int attachment = fc->constraints [edge].attachment;

    return (attachment == SGFormView_ATTACH_NONE) ||
	   (fc->constraints [edge].state != STATE_DONE) ||
	   (attachment == SGFormView_ATTACH_VIEW &&
	    fc->constraints [edge].child == fc);
}

- (void) move_edge:(jmp_buf) env
                fc:(SGFormMetaView *) fc
              edge:(int) edge
             where:(int) where
         my_bounds:(int *) my_bounds
recompute_our_size:(bool) recompute_our_size
{
    int diff = where - fc->constraints [edge].location;

    int opposite_edge = edge ^ 2;

    if ([self edge_should_move_too:fc edge:opposite_edge])
		fc->constraints [opposite_edge].location += diff;
    else
    {
		// Special Case:  If we are in "recompute" mode and we shrink
		// because of this constraint, then we need to expand the form
		// to accomodate us instead of shrinking the child.

		if (recompute_our_size)
		{
			int delta = diff * fc->constraints [opposite_edge].factor;

			if (delta < 0)
			{
				if (edge == SGFormView_EDGE_TOP || edge == SGFormView_EDGE_BOTTOM)
					my_bounds [SGFormView_EDGE_BOTTOM] += -delta;
				else
					my_bounds [SGFormView_EDGE_RIGHT] += -delta;
				
				longjmp (env, 1);
			}
		}
    }

    fc->constraints [edge].location += diff;
}

- (int) layout_edge:(jmp_buf) env
                 fc:(SGFormMetaView *) fc
               edge:(int) edge
          my_bounds:(int *) my_bounds
 recompute_our_size:(bool) recompute_our_size
{
    SGFormConstraint *ec = &fc->constraints [edge];

	//NSLog (@"%d", ec->attachment);
	
    if (ec->attachment != SGFormView_ATTACH_NONE && ec->state != STATE_DONE)
    {
		if (ec->state == STATE_VISITED)
			printf ("FormLayout.layout: Circular dependency!\n");
		else
		{
			int location = 0;

			ec->state = STATE_VISITED;

			//
			// At this point, we can do the work.
			//

			switch (ec->attachment)
			{
				case SGFormView_ATTACH_FORM:
					location = my_bounds [edge];
					break;

				case SGFormView_ATTACH_VIEW:
					location = ec->factor +	// This IS correct
						   [self layout_edge:env
										  fc:ec->child
										edge:edge ^ 2
								   my_bounds:my_bounds
						  recompute_our_size:recompute_our_size];
					break;

				case SGFormView_ATTACH_OPPOSITE_VIEW:
					location = [self layout_edge:env
											  fc:ec->child
											edge:edge
									   my_bounds:my_bounds
							  recompute_our_size:recompute_our_size];
					break;

				case SGFormView_ATTACH_CENTER:
				{
					int center;

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

						int edge1 = ec->child->constraints [edge^2].location;
						int edge2 = ec->child->constraints [edge].location;
						int half = (edge1 - edge2) / 2;
						center = ec->child->constraints [edge].location +
							 half;
					}

					// We depend on the opposite edge so lets lay him out
					// first.

					[self layout_edge:env
								   fc:fc
								 edge:edge ^ 2
							my_bounds:my_bounds
				   recompute_our_size:recompute_our_size];

					int size = fc->constraints [edge ^ 2].location -
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

			ec->state = STATE_DONE;
		}
    }

    return fc->constraints [edge].location;
}

- (void) layout_child:(jmp_buf) env 
                   fc:(SGFormMetaView *) fc
            my_bounds:(int *) my_bounds
   recompute_our_size:(bool) recompute_our_size
{
    for (int edge = 0; edge < 4; edge ++)
	[self layout_edge:env 
				   fc:fc
				 edge:edge
			my_bounds:my_bounds
   recompute_our_size:recompute_our_size];
}

- (void) do_layout:(int *) my_bounds
recompute_our_size:(bool) recompute_our_size
{
    for (int count = 0; count < 10000; )
    {
		bool it_worked = 1;

		// 
		// Reset the state of all edges.
		//

		NSArray *mviews = [self metaViews];

		for (unsigned int i = 0; i < [mviews count]; i ++)
		{
			SGFormMetaView *view = [mviews objectAtIndex:i];

			for (int edge = 0; edge < 4; edge ++)
				view->constraints [edge].state = STATE_RESET;
		}

		for (unsigned int i = 0; i < [mviews count]; i ++)
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
				it_worked = 0;
				count ++;
				break;
			}
		}

		if (it_worked)
			break;
    }
}

- (void) do_layout
{
    NSRect r = [self bounds];

    int my_bounds [4] = { (int) r.origin.y, (int) r.origin.x,
                          (int) r.origin.y + (int) r.size.height - 1,
                          (int) r.origin.x + (int) r.size.width - 1 };

	//NSLog (@"new form size %x %d %d %d %d", self,
	//	my_bounds[0],my_bounds[1],my_bounds[2],my_bounds[3]);

    NSArray *mviews = [self metaViews];
    
    for (unsigned int i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        [view get_initial_bounds];
    }

    [self do_layout:my_bounds recompute_our_size:false];

    for (unsigned int i = 0; i < [mviews count]; i ++)
    {
        SGFormMetaView *view = [mviews objectAtIndex:i];
        [view set_final_bounds:self];
    }
}

#if 0
- (void) replaceSubview:(NSView *)oldView 
				   with:(NSView *)newView
{
	// We are about to remove oldView and add newView.
	// We'll need to stuff our metadata back in
	
	SGFormMetaView *meta_view = [self find_view:oldView];

	if (meta_view)
	{
		[meta_view retain];
		[super replaceSubview:oldView with:newView];
		SGFormMetaView *new_meta_view = [self find_view:newView];
		if (new_meta_view)
		{
			for (int i = 0; i < 4; i ++)
				new_meta_view->constraints[i] = meta_view->constraints[i];
			[new_meta_view setIdentifier:[meta_view identifier]];
		}
		[meta_view release];
	}
}
#endif

@end
