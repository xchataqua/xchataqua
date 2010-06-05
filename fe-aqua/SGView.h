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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

//////////////////////////////////////////////////////////////////////

@class SGMetaView;

@interface SGView : NSView
{
  @protected
    NSMutableArray  *metaViews;
    BOOL	    first_layout;
    BOOL	    pending_layout;
    BOOL 	    in_my_layout;
    BOOL	    in_dtor;
    BOOL        auto_size_to_fit;
    BOOL        needs_size_to_fit;
}

- (id) initWithFrame:(NSRect) frameRect;

- (void) layoutNow;

// Methods for subclasses

- (void) queue_layout;			// Mark as needing a layout.. (delayed)
- (void) layout_maybe;                  // Layout only if queued
- (NSArray *)    metaViews;
- (SGMetaView *) find_view:(NSView *) the_view;
- (void) setOrder:(NSUInteger)order forView:(NSView *) the_view;
- (NSUInteger) viewOrder:(NSView *) the_view;
- (void) setAutoSizeToFit:(BOOL) sf;

// Override these if needed

- (SGMetaView *) newMetaView:(NSView *) view;
- (void) do_layout;			// This is where the work is done
- (void) sizeToFit;
- (void) subview_did_resize:(NSNotification *)notification;

@end

@interface SGMetaView : NSObject
{
  @public
    NSView *view;
    NSRect  prefSize;
    NSRect  lastSize;
}

- (id)initWithView:(NSView *) the_view;
- (id) initWithCoder:(NSCoder *) decoder;
- (void) encodeWithCoder:(NSCoder *) encoder;
- (NSView *) view;
- (NSRect) prefSize;
- (void) setFrame:(NSRect) frame;	// Use this method from subclasses "layout ()"
                                    // to avoid infinite recursion.  Redraws too.

// Private stuff

- (void) reset_prefSize;

@end
