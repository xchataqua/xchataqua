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

typedef enum
{
	SGFormViewAttachmentNone,
	SGFormViewAttachmentForm,
	SGFormViewAttachmentView,
	SGFormViewAttachmentOppositeView,
	SGFormViewAttachmentCenter,
}	SGFormViewAttachment;

typedef enum
{
	/* N O T E:  These numbers ARE NOT ARBITRARY!! */
	SGFormViewEdgeBottom = 0,
	SGFormViewEdgeLeft = 1,
	SGFormViewEdgeTop = 2,
	SGFormViewEdgeRight = 3,
}	SGFormViewEdge;
#define SGFormViewEdgeCount 4

@interface SGFormView : SGView

- (void) constrain:(NSView *)child edge:(SGFormViewEdge)edge attachment:(SGFormViewAttachment)attachment relativeTo:(NSView *)view offset:(int)offset;

// These methods are used to assign a string identifier to subviews.
// This is used only in the interface builder palette.
- (void) setIdentifier:(NSString *)identifier forView:(NSView *)view;
- (NSString *) identifierForView:(NSView *)view;

- (BOOL) constraintsForEdge:(NSView *)child edge:(SGFormViewEdge)edge attachment:(SGFormViewAttachment *)attachment_return relativeTo:(NSView **)view_return offset:(int *)offset_return;

// This function exists to bootstrap the contraints for all of the views
// such that the view remains relative to 'view'.  When/if I write an interface
// builder palette, this method could go away.
- (void) bootstrapRelativeTo:(NSView *) view;

@end
