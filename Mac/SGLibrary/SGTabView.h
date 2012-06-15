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

#import "SGBoxView.h"

@class SGTabViewItem;
@class SGWrapView;

#define SGOutlineTabs ((NSTabViewType) 99)

@protocol SGTabViewDelegate;
@interface SGTabView : NSView<NSOutlineViewDelegate, NSOutlineViewDataSource, NSSplitViewDelegate> {
    SGWrapView      *_tabButtonView;
    NSOutlineView   *_tabOutlineView;
    NSMutableArray  *_tabViewItems;
    SGTabViewItem   *_selectedTabViewItem;
    IBOutlet SGBoxView *_chatViewContainer;
    
@public    // TODO - fix this
    NSMutableArray  *groups;    // For outline view only
    id<NSObject,SGTabViewDelegate> _delegate;
    NSTabViewType   tabViewType;
    bool            hideClose;
}

@property(nonatomic, assign) IBOutlet id delegate;
@property(nonatomic, retain) IBOutlet NSOutlineView *tabOutlineView;
@property(nonatomic, retain) id chatView;
@property(nonatomic, readonly) SGTabViewItem *selectedTabViewItem;

// NSTabView emulation methods
- (void) addTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) removeTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) selectTabViewItem:(SGTabViewItem *) tabViewItem;
- (void) selectTabViewItemAtIndex:(NSInteger) index;
- (void) selectNextTabViewItem:(id)sender;
- (void) selectPreviousTabViewItem:(id)sender;
- (SGTabViewItem *) tabViewItemAtIndex:(NSInteger) index;
- (SGTabViewItem *) selectedTabViewItem;
- (NSArray *) tabViewItems;
- (void) setTabViewType:(NSTabViewType) tabViewType;
- (NSInteger) indexOfTabViewItem:(SGTabViewItem *) tabViewItem;

// SGTabView only methods
- (void) addTabViewItem:(SGTabViewItem *) tabViewItem toGroup:(NSInteger) group;
- (void) setHideCloseButtons:(BOOL) hidem;
- (void) setName:(NSString *) name forGroup:(NSInteger) group;
- (NSString *) groupName:(NSInteger) group;
- (void) setOutlineWidth:(CGFloat) width;

@end

@protocol SGTabViewDelegate
- (void) tabWantsToClose:(SGTabViewItem *) item;
- (void) tabView:(SGTabView *)tabView didSelectTabViewItem:(SGTabViewItem *)tabViewItem;
- (void) tabViewDidResizeOutlne:(int) width;
@end

#pragma mark -

@class SGTabViewButton;

@interface SGTabViewItem : NSObject
{
    NSView      *_view;
    NSColor     *_titleColor;
    id          _initialFirstResponder;
@public    // TODO - fix this
    SGTabViewButton *button;
    NSString    *label;
    SGTabView   *parent;
    NSInteger   group;
    IBOutlet NSMenu *ctxMenu;
}

@property(nonatomic, retain) NSColor *titleColor;
@property(nonatomic, retain) NSString *label;
@property(nonatomic, retain) NSView *view;
@property(nonatomic, readonly) SGTabView *tabView;
@property(nonatomic, assign) id initialFirstResponder;
@property(nonatomic, readonly, getter=isFrontTab) BOOL frontTab;

- (id)initWithIdentifier:(id) identifier;
- (void)setHideCloseButton:(BOOL) hidem;

- (IBAction)doClose:(id)sender;
- (IBAction)link_delink:(id)sender;

@end
