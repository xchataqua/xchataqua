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


@class SGWrapView;
@class XATabViewItem;
@class XATabViewGroup;
@class XATabViewOutlineView;

#define XATabViewTypeOutline ((NSTabViewType) 99)

@protocol XATabViewDelegate;
@interface XATabView : NSView<NSOutlineViewDelegate, NSOutlineViewDataSource, NSSplitViewDelegate, XAEventChain> {
    NSTabViewType tabViewType;
    // tabs
    XATabViewOutlineView *_tabOutlineView;
    SGWrapView *_tabButtonView;
    // items
    NSMutableArray *_groups;
    NSMutableArray *_tabViewItems;
    XATabViewItem *_selectedTabViewItem;
    //
    IBOutlet SGBoxView *_chatViewContainer;
@public
    id<NSObject,XATabViewDelegate> _delegate;
}

@property(nonatomic, assign) IBOutlet id delegate;
@property(nonatomic, retain) IBOutlet XATabViewOutlineView *tabOutlineView;
@property(nonatomic, retain) id chatView;
@property(nonatomic, readonly) XATabViewItem *selectedTabViewItem;
@property(nonatomic, readonly) NSArray *tabViewItems;

// NSTabView emulation methods
- (void) addTabViewItem:(XATabViewItem *) tabViewItem;
- (void) removeTabViewItem:(XATabViewItem *) tabViewItem;
- (void) selectTabViewItem:(XATabViewItem *) tabViewItem;
- (void) selectTabViewItemAtIndex:(NSInteger) index;
- (void) selectNextTabViewItem:(id)sender;
- (void) selectPreviousTabViewItem:(id)sender;
- (XATabViewItem *) tabViewItemAtIndex:(NSInteger) index;
- (XATabViewItem *) selectedTabViewItem;
- (void) setTabViewType:(NSTabViewType) tabViewType;
- (NSInteger) indexOfTabViewItem:(XATabViewItem *) tabViewItem;

// XATabView only methods
- (void) addTabViewItem:(XATabViewItem *) tabViewItem toGroup:(NSInteger) group;
- (void) setHideCloseButtons:(BOOL) hidem;
- (void) setName:(NSString *) name forGroup:(NSInteger) group;
- (void) setOutlineWidth:(CGFloat) width;
- (XATabViewGroup *)groupForIdentifier:(NSInteger)identifier;
- (void)redrawTabItems;

@end

@protocol XATabViewDelegate
- (void) tabView:(XATabView *)tabView didSelectTabViewItem:(XATabViewItem *)tabViewItem;
- (void) tabViewDidResizeOutlne:(int) width;
@end

#pragma mark -

@class XATabViewButton;

@interface XATabViewItem : NSObject
{
    NSView *_view;
    NSInteger _titleColorIndex;
    XATabView* _tabView;
    NSString* _label;
    NSInteger _groupIdentifier;
    id _initialFirstResponder;
    XATabViewButton *_tabButton;
@public    // TODO - fix this
    IBOutlet NSMenu *contextMenu;
}

@property(nonatomic, assign) NSInteger titleColorIndex;
@property(nonatomic, readonly) NSColor *titleColor;
@property(nonatomic, retain) NSString *label;
@property(nonatomic, assign) NSInteger groupIdentifier;
@property(nonatomic, retain) NSView *view;
@property(nonatomic, assign) XATabView *tabView;
@property(nonatomic, readonly) XATabViewButton *tabButton;
@property(nonatomic, assign) id initialFirstResponder;
@property(nonatomic, readonly, getter=isFrontTab) BOOL frontTab;

- (id)initWithIdentifier:(id) identifier;
- (void)setHideCloseButton:(BOOL) hidem;
- (void)redrawTitle;

- (IBAction)performClose:(id)sender;
- (IBAction)link_delink:(id)sender;

@end
