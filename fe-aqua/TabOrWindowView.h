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

#if 0
#define TABVIEW MyTabView
#define TABVIEWITEM MyTabViewItem
#import "MyTabView.h"
#else
#define TABVIEW SGTabView
#define TABVIEWITEM SGTabViewItem
#import "SGTabView.h"
#endif

@class TABVIEWITEM;

@interface TabOrWindowView : NSView 
{
    NSWindow		*window;
    TABVIEWITEM		*this_item;
    NSObject		*delegate;
    NSString		*title;
    NSString		*tab_title;
    NSView			*ifr;
    struct server	*server;
}

+ (void) cycleWindow:(int) direction;
+ (bool) selectTab:(unsigned) n;
+ (void) link_delink;		// Frontmost view
+ (void) updateGroupNameForServer:(struct server *) server;

//+ (void) setTabPosition:(NSTabViewType) type;
//+ (void) setHideCloseButtons:(bool) hidem;
+ (void) prefsChanged;
+ (void) setTransparency:(int) trans;
//+ (NSArray *) views;

- (void) link_delink:(id) sender;

- (void) setServer:(struct server *) server;

- (void) becomeTabAndShow:(BOOL) show;
- (void) becomeWindowAndShow:(BOOL) show;
- (void) becomeTab:(BOOL) tab andShow:(BOOL) show;

- (void) makeKeyAndOrderFront:(id) sender;

- (void) close;
- (void) setTitle:(NSString *) title;
- (void) setTabTitle:(NSString *) title;
- (void) setTabTitleColor:(NSColor *) c;
- (BOOL) isFrontTab;

- (void) setDelegate:(id) delegate;
- (id)   delegate;
- (NSString *) title;
- (void) setInitialFirstResponder:(NSView *) r;

@end

@interface NSObject (TabOrWindowViewDelegate)
- (void) windowWillClose:(NSNotification *) notification;
- (void) windowDidBecomeKey:(NSNotification *) notification;
@end
