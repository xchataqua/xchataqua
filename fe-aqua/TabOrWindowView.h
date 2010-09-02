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

#import <Cocoa/Cocoa.h>

#import "SG.h"

@protocol TabOrWindowViewDelegate;
@class SGTabViewItem;
@interface TabOrWindowView : NSView
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSWindowDelegate>
#endif
{
	id			   delegate;
	NSWindow		*window;
	SGTabViewItem	*tabViewItem;
	NSString		*title;
	NSString		*tabTitle;
	NSView			*initialFirstResponder;
	struct server	*server;
}

@property (assign) id delegate;
@property (retain) NSString *title, *tabTitle;

+ (void) cycleWindow:(int) direction;
+ (BOOL) selectTabByIndex:(NSUInteger)index;
+ (void) link_delink;		// Frontmost view
+ (void) updateGroupNameForServer:(struct server *) server;

+ (void) preferencesChanged;
+ (void) setTransparency:(NSInteger)transparency;

- (void) link_delink:(id) sender;

- (void) setServer:(struct server *) server;

- (void) becomeTabAndShow:(BOOL) show;
- (void) becomeWindowAndShow:(BOOL) show;
- (void) becomeTab:(BOOL) tab andShow:(BOOL) show;

- (void) makeKeyAndOrderFront:(id) sender;

- (void) close;
- (void) setTabTitleColor:(NSColor *) color;
- (BOOL) isFrontTab;

- (void) setInitialFirstResponder:(NSView *) responder;

@end

@protocol TabOrWindowViewDelegate
- (void) windowWillClose:(NSNotification *) notification;
- (void) windowDidBecomeKey:(NSNotification *) notification;
@end
