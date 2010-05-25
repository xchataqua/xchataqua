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

#import <AppKit/AppKit.h>
#import <SGWrapView.h>
#import <SGBoxView.h>

//////////////////////////////////////////////////////////////////////

@class SGTabViewItem;

#define SGOutlineTabs ((NSTabViewType) 99)

@interface SGTabView : SGBoxView
{
  @public	// TODO - fix this
    SGWrapView		*hbox;
	NSOutlineView	*outline;
	int				outline_width;
    SGTabViewItem	*selected_tab;
    NSMutableArray	*tabs;
	NSMutableArray	*groups;	// For outline view only
    id				delegate;
    NSTabViewType	tabViewType;
    bool			hide_close;
}

// NSTabView emulation methods
- (void) addTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) removeTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) selectTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) selectTabViewItemAtIndex:(NSInteger) index;
- (void) selectNextTabViewItem:(id) sender;
- (void) selectPreviousTabViewItem:(id) sender;
- (SGTabViewItem *) tabViewItemAtIndex:(NSInteger) index;
- (SGTabViewItem *) selectedTabViewItem;
- (NSArray *) tabViewItems;
- (id) delegate;
- (void) setDelegate:(id) anObject;
- (void) setTabViewType:(NSTabViewType) tabViewType;
- (NSInteger) numberOfTabViewItems;
- (int) indexOfTabViewItem:(SGTabViewItem *) tabViewItem;

// SGTabView only methods
- (void) addTabViewItem:(SGTabViewItem *) tabViewItem toGroup:(int) group;
- (void) setHideCloseButtons:(bool) hidem;
- (void) setName:(NSString *) name forGroup:(int) group;
- (NSString *) groupName:(int) group;
- (void) setOutlineWidth:(int) width;

@end

@interface NSObject (SGTabViewDelegate)
- (void) tabWantsToClose:(SGTabViewItem *) item;
- (void) tabView:(SGTabView *)tabView didSelectTabViewItem:(SGTabViewItem *)tabViewItem;
- (void) tabViewDidResizeOutlne:(int) width;
@end

//////////////////////////////////////////////////////////////////////

@class SGTabViewButton;

@interface SGTabViewItem : NSObject
{
  @public	// TODO - fix this
    SGTabViewButton *button;
	NSColor		*color;
	NSString	*label;
    NSView      *view;
    SGTabView   *parent;
    int         group;
    id		    initial_first_responder;
	NSMenu		*ctxMenu;
}

- (id) initWithIdentifier:(id) identifier;
- (void) setLabel:(NSString *) label;
- (NSString *) label;
- (void) setTitleColor:(NSColor *) c;
- (NSColor *) titleColor;
- (void) setView:(NSView *) view;
- (id) view;
- (id) initialFirstResponder;
- (void) setInitialFirstResponder:(NSView *) view;
- (void) setHideCloseButton:(bool) hidem;
- (SGTabView *) tabView;
- (BOOL) isFrontTab;

@end

//////////////////////////////////////////////////////////////////////

