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

#include <Carbon/Carbon.h>
#include <dlfcn.h>

#include "cfgfiles.h"

#import "AquaChat.h"
#import "ColorPalette.h"
#import "SGGuiUtility.h"
#import "SGWrapView.h"
#import "XATabView.h"
#import "CLTabViewButtonCell.h"
#import "TabOrWindowView.h"

//! @abstract   Cell of each row of outline tab mode
@interface XATabViewOutlineCell : NSTextFieldCell {
    BOOL _hasCloseButton;
    NSButtonCell *closeCell; // not shown now...
}

@property (nonatomic, assign) BOOL hasCloseButton;

@end

NSImage *XATabViewOutlineCellCloseImage;

@implementation XATabViewOutlineCell
@synthesize hasCloseButton=_hasCloseButton;

+ (void)initialize {
    if (self == [XATabViewOutlineCell class]) {
        XATabViewOutlineCellCloseImage = [[NSImage imageNamed:@"close.tiff"] retain];
    }
}

- (id)initTextCell:(NSString *)aString {
    self = [super initTextCell:aString];
    if (self != nil) {
        closeCell = [[NSButtonCell alloc] initImageCell:XATabViewOutlineCellCloseImage];
        [closeCell setButtonType:NSMomentaryLightButton];
        [closeCell setImagePosition:NSImageOnly];
        [closeCell setBordered:NO];
        [closeCell setHighlightsBy:NSContentsCellMask];
    }
    return self;
}

- (void) dealloc
{
    [closeCell release];
    [super dealloc];
}

- (id) copyWithZone:(NSZone *) zone
{
    XATabViewOutlineCell *copy = [super copyWithZone:zone];
    copy->closeCell = [closeCell copyWithZone:zone];
    return copy;
}

- (void)performClose:(id)sender {
    [[closeCell target] performSelector:[closeCell action]];
}

- (NSRect) calculateCloseRectWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect r;
    
    r.size = XATabViewOutlineCellCloseImage.size;
    r.origin.x = cellFrame.origin.x;
    r.origin.y = cellFrame.origin.y + floor ((cellFrame.size.height - r.size.height) / 2);
    
    return r;
}

- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
    NSRect closeRect = NSZeroRect;

    if (self.hasCloseButton) {
        closeRect = [self calculateCloseRectWithFrame:cellFrame inView:controlView];
        cellFrame.origin.x += closeRect.size.width + 2.0f;
    }

    [super drawInteriorWithFrame:cellFrame inView:controlView];

    // Gotta draw the icon last because highlighted cells have a
    // blue background which will cover the image otherwise.                  
    if (self.hasCloseButton) {
        [closeCell drawInteriorWithFrame:closeRect inView:controlView];
    }
}

- (BOOL)mouseDown:(NSEvent *)theEvent cellFrame:(NSRect)cellFrame controlView:(NSView *)controlView
      closeAction:(SEL)closeAction closeTarget:(id)closeTarget {
    if (!self.hasCloseButton) {
        return NO;
    }

    [closeCell setAction:closeAction];
    [closeCell setTarget:closeTarget];
        
    NSPoint point = [theEvent locationInWindow];
    NSPoint where = [controlView convertPoint:point fromView:nil];
    NSRect closeRect = [self calculateCloseRectWithFrame:cellFrame inView:controlView];
        
    if (NSPointInRect (where, closeRect))
    {
        [SGGuiUtility trackButtonCell:closeCell withEvent:theEvent inRect:closeRect controlView:controlView];
        return YES;
    }
    
    return NO;
}

@end

#pragma mark -

//! @abstract   Channel view for outline tab mode
@interface XATabViewOutlineView : NSOutlineView<XAEventChain>

- (void)selectRowForTabViewItem:(XATabViewItem *)tabViewItem;

@end

@implementation XATabViewOutlineView

- (BOOL) acceptsFirstResponder
{
    return NO;
}

// Grab mouse down and deal with the close button without selecting
// the item.  We have to find the item, the column, and the data cell.
// If all the classes look right, we'll call the delegate to prep the
// cell and then let the cell deal with tracking the close button.
// (if it has one).
- (void) mouseDown:(NSEvent *) theEvent
{
    NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:where];
    NSInteger col = [self columnAtPoint:where];
    
    if (row >= 0 && col >= 0)
    {
        id item = [self itemAtRow:row];

        if ([item isKindOfClass:[XATabViewItem class]])
        {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:col];
            XATabViewOutlineCell *cell = [tableColumn dataCell];
            
            if ([cell isKindOfClass:[XATabViewOutlineCell class]])
            {
                [[self delegate] outlineView:self willDisplayCell:cell forTableColumn:tableColumn item:item];
                if ([cell mouseDown:theEvent 
                          cellFrame:[self frameOfCellAtColumn:col row:row]
                        controlView:self
                        closeAction:@selector(performClose:)
                        closeTarget:item])
                {
                    return;
                }
            }
        }
    }
    
    [super mouseDown:theEvent];
}

- (NSMenu *) menuForEvent:(NSEvent *) theEvent
{
    NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSInteger row = [self rowAtPoint:where];
    NSInteger col = [self columnAtPoint:where];
    
    if (row >= 0 && col >= 0)
    {
        id item = [self itemAtRow:row];

        if ([item isKindOfClass:[XATabViewItem class]]) {
            return ((XATabViewItem *)item)->contextMenu;
        }
    }
    
    return [super menuForEvent:theEvent];
}

/*
 * Applies the currently set preferences when changed
 *
 * When the user presses "Apply" or "Ok" in the Preferences window,
 * applyPreferences: is called to actually make them live. Mostly this matters
 * for fonts and colors and other visually apparent changes.
 *
 * The call chain for this is a bit fuzzy: not sure how it's propogated to
 * every object that needs it.
 *
 */
- (void)applyPreferences:(id)sender {
    CGFloat fontSize = prefs.style_namelistgad ? [AquaChat sharedAquaChat].font.pointSize * 0.9 : [NSFont smallSystemFontSize];
    if (prefs.tab_small) {
        fontSize *= 0.86;
    }
    NSFont *font = [NSFont systemFontOfSize:fontSize];
    XATabViewOutlineCell *dataCell = [[self.tableColumns objectAtIndex:0] dataCell];
    dataCell.font = font;
    
    NSLayoutManager *layoutManager=[[NSLayoutManager new] autorelease];
    [self setRowHeight:[layoutManager defaultLineHeightForFont:font] * 1.2 + 1];
    
    ColorPalette *p = [[AquaChat sharedAquaChat] palette];
    if (prefs.style_namelistgad) {
        dataCell.textColor = [p getColor:XAColorForeground];
        self.backgroundColor = [p getColor:XAColorBackground];
    } else {
        dataCell.textColor = [NSColor textColor];
        self.backgroundColor = [NSColor textBackgroundColor];
    }
    [self drawRect:self.bounds];
}

- (void)selectRowForTabViewItem:(XATabViewItem *)tabViewItem {
    NSInteger row = [self rowForItem:tabViewItem];
    [self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

@end

#pragma mark -

//! @abstract   Group information, usually server. Or utility windows group.
@interface XATabViewGroup: NSObject {
    NSMutableArray *_tabItems;
    NSInteger _identifier; // from xchat core
    NSString *_name;
}

@property(nonatomic, retain) NSString *name;
@property(nonatomic, readonly) NSInteger identifier;
@property(nonatomic, readonly) NSMutableArray *tabItems;

@end

@implementation XATabViewGroup
@synthesize tabItems=_tabItems;
@synthesize name=_name;
@synthesize identifier=_identifier;

- (id)initWithIdentifier:(NSInteger)identifier {
    self = [super init];
    if (self != nil) {
        _tabItems = [[NSMutableArray alloc] init];
        _identifier = identifier;
    }
    return self;
}

- (void) dealloc
{
    self.name = nil;
    [_tabItems release];
    [super dealloc];
}

@end

#pragma mark -

//! @abstract   Button for tab mode
@interface XATabViewButton: NSButton

- (void) setHideCloseButton:(BOOL) hideit;

@end

@implementation XATabViewButton

+ (Class)cellClass {
    return [CLTabViewButtonCell class];
}

/* CL: undocumented method used to update the cell when the window is activated/deactivated */
- (void)_windowChangedKeyState
{
    [self updateCell:[self cell]];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        [self setButtonType:NSOnOffButton];
        
        CLTabViewButtonCell *cell = [[[[self class] cellClass] alloc] init];
        [self setCell:cell];
        [cell setControlSize:NSSmallControlSize];
        [cell release];
        
        CGFloat fontSize = [NSFont smallSystemFontSize];
        if (prefs.tab_small) {
            fontSize *= 0.86;
        }
        [self setFont:[NSFont systemFontOfSize:fontSize]];
        [self setImagePosition:NSNoImage];
        [self setBezelStyle:NSShadowlessSquareBezelStyle];
        [self sizeToFit];
    }
    return self;
}

- (void) setHideCloseButton:(BOOL) hideit
{
    [[self cell] setHideCloseButton:hideit];
    [self sizeToFit];
}

- (void)setHasLeftCap:(BOOL)hasCap {
    [[self cell] setHasLeftCap:hasCap];
}

- (void)setHasRightCap:(BOOL)hasCap {
    [[self cell] setHasRightCap:hasCap];
}

- (void)setTitleColor:(NSColor *)color {
    [[self cell] setTitleColor:color];
    [self setNeedsDisplay:true];
}

- (void)mouseDown:(NSEvent *)event {
    [[self cell] mouseDown:event controlView:self];
}

- (BOOL) isFlipped
{
    return NO;
}

@end

#pragma mark -

NSNib *XATabViewItemTabMenuNib;

@implementation XATabViewItem
@synthesize view=_view;
@synthesize label=_label;
@synthesize groupIdentifier=_groupIdentifier;
@synthesize tabView=_tabView;
@synthesize tabButton=_tabButton;
@synthesize titleColorIndex=_titleColorIndex;
@synthesize initialFirstResponder=_initialFirstResponder;

+ (void)initialize {
    if (self == [XATabViewItem class]) {
        XATabViewItemTabMenuNib = [[NSNib alloc] initWithNibNamed:@"TabMenu" bundle:nil];
    }
}

- (id) initWithIdentifier:(id) identifier
{
    self = [super init];
    if (self != nil) {    
        [XATabViewItemTabMenuNib instantiateNibWithOwner:self topLevelObjects:nil];
        self->_titleColorIndex = XAColorForeground;
    }
    return self;
}

- (void) dealloc
{
    self.label = nil;
    self.view = nil;
    [self->_tabButton release];
    [contextMenu release];
    [super dealloc];
}

- (void)makeButton:(SGWrapView *)box order:(NSUInteger)order {
    self->_tabButton = [[XATabViewButton alloc] init]; // ???: not released here?
    [self->_tabButton setAction:@selector(performSelect:)];
    [self->_tabButton setTarget:self];
    [self->_tabButton setHideCloseButton:prefs.xa_hide_tab_close_buttons];
    id cell = [self->_tabButton cell];
    [cell setCloseAction:@selector(performClose:)];
    [cell setCloseTarget:self];
    [cell setMenu:contextMenu];
    [cell setDelegate:self];
    
    [box addSubview:self->_tabButton];
    [box setOrder:order forView:self->_tabButton];

    if (prefs.tab_layout == 0) {
        [self redrawTitle];
    }
}

- (void)removeButton
{
    if (self->_tabButton != nil)
    {
        [self->_tabButton removeFromSuperview];
        [self->_tabButton release];
        self->_tabButton = nil;
    }
}

- (BOOL)isFrontTab {
    return self.tabView.selectedTabViewItem == self;
}

- (void) setHideCloseButton:(BOOL) hidem
{
    [self->_tabButton setHideCloseButton:hidem];
}

- (void)redrawTitle {
    if (prefs.tab_layout == 0) {
        [self->_tabButton setTitle:self->_label];
        [self->_tabButton sizeToFit];
    } else {
        [self.tabView.tabOutlineView reloadData];
    }
}

- (NSColor *)titleColor {
    if (!prefs.style_namelistgad && self.titleColorIndex == XAColorForeground) {
        return [NSColor blackColor];
    }
    return [[[AquaChat sharedAquaChat] palette] getColor:self.titleColorIndex];
}

- (void)setTitleColorIndex:(NSInteger)index {
    if (_titleColorIndex == index) return;
    self->_titleColorIndex = index;
    [self redrawTitle];
}

- (void)performClose:(id)sender {
    [(TabOrWindowView *)self.view close];
}

- (void)link_delink:(id)sender {
    if (self.tabView) {
        [self.tabView.delegate link_delink:self];
    }
}

- (void)performSelect:(id)sender {
    if (self.tabView) {
        [self->_tabButton setIntegerValue:1];
        [self.tabView selectTabViewItem:self];
    }
}

- (void)setLabel:(NSString *)label {
    [_label autorelease];
    _label = [label retain];
    
    [self redrawTitle];
}

- (void) setSelected:(BOOL) selected
{
    if (self->_tabButton) {
        [self->_tabButton setIntegerValue:selected];
    }
}

- (void) setView:(NSView *)view
{
    [_view removeFromSuperview];
    [_view release];

    _view = [view retain];

    if ([self isFrontTab]) {
        self.tabView.chatView = view;
    }
}

@end

#pragma mark -

@implementation XATabView
@synthesize delegate=_delegate;
@synthesize tabOutlineView=_tabOutlineView;
@synthesize selectedTabViewItem=_selectedTabViewItem;
@synthesize tabViewItems=_tabViewItems;

- (void)XATabViewInit {
    self->_tabViewItems = [[NSMutableArray alloc] init];
    self->_groups = [[NSMutableArray alloc] init];
    [_chatViewContainer setMinorDefaultJustification:SGBoxMinorJustificationFull];
}

- (id) initWithFrame:(NSRect) frameRect
{
    self = [super initWithFrame:frameRect];
    if (self != nil) {
        [self XATabViewInit];
        [self makeOutline];
        [self makeTabs];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self XATabViewInit];
    return self;
}

- (void)awakeFromNib {
    [self makeOutline];
    [self makeTabs];
}

- (void)dealloc {
    self.chatView = nil;
    self.tabOutlineView = nil;
    [_tabViewItems release];
    [_groups release];
    [super dealloc];
}

- (void)applyPreferences:sender {
    [_tabOutlineView applyPreferences:sender];
    
    if ( prefs.tab_layout == 2 ) {
        tabViewType = XATabViewTypeOutline;
    } else {
        switch ( prefs._tabs_position ) {
            case 0: tabViewType = NSBottomTabsBezelBorder; break;
            case 1: tabViewType = NSTopTabsBezelBorder; break;
            case 2: tabViewType = NSRightTabsBezelBorder; break;
            case 3: tabViewType = NSLeftTabsBezelBorder; break;
            default:tabViewType = NSBottomTabsBezelBorder; break;
        }
    }
    
    [self setTabViewType:tabViewType];
    [self setHideCloseButtons:prefs.xa_hide_tab_close_buttons];
    [self setOutlineWidth:prefs.xa_outline_width];
    [self redrawTabItems];
}

- (void) setOutlineWidth:(CGFloat) width
{
    prefs.xa_outline_width = width;
    if (width < 50.0f) {            // Just because
        width = 50.0f;
    }
    if (self->tabViewType != XATabViewTypeOutline) return;
    
    NSScrollView *outlineScroll = [_tabOutlineView enclosingScrollView];
    [outlineScroll setFrameSize:NSMakeSize(width, [outlineScroll frame].size.height)];
}

- (id)chatView {
    for (id view in self->_chatViewContainer.subviews) {
        if (view == self->_tabButtonView) continue;
        return view;
    }
    return nil;
}

- (void)setChatView:(id)chatView {
    if (chatView == nil) return;
    while (_chatViewContainer.subviews.count > 0) {
        [[_chatViewContainer.subviews objectAtIndex:0] removeFromSuperview];
    }
    if (xchat_is_quitting) return; // optimization..?

    [chatView setFrame:_chatViewContainer.bounds];
    [_chatViewContainer addSubview:chatView];
    [_chatViewContainer setStretchView:chatView];
    
    dassert(_tabButtonView);
    
    if (self->tabViewType != XATabViewTypeOutline) {
        [_chatViewContainer addSubview:_tabButtonView];
    }
}

- (XATabViewGroup *)groupForIdentifier:(NSInteger)identifier {
    XATabViewGroup *group = nil;
    
    for (XATabViewGroup *aGroup in _groups) {
        if (aGroup.identifier == identifier) {
            group = aGroup;
            break;
        }
    }
    
    if (group == nil) {
        group = [[XATabViewGroup alloc] initWithIdentifier:identifier];
        [_groups addObject:group];
        [group release];
        
        [self redrawTabItems];
        [_tabOutlineView expandItem:group];
    }
    
    return group;
}

- (void)setName:(NSString *)name forGroup:(NSInteger)identifier {
    [[self groupForIdentifier:identifier] setName:name];
    [self redrawTabItems];
}

- (void)setHideCloseButtons:(BOOL)hide {
    for (XATabViewItem *tab in self.tabViewItems) {
        [tab setHideCloseButton:hide];
    }
}

- (void)setTabButtonCaps {
    for (XATabViewGroup *group in _groups) {
        for (XATabViewItem *tabItem in group.tabItems) {
            [tabItem.tabButton setHasLeftCap:NO];
            [tabItem.tabButton setHasRightCap:NO];
        }
        XATabViewItem *firstItem = [group.tabItems objectAtIndex:0];
        [firstItem.tabButton setHasLeftCap:YES];
        XATabViewItem *lastItem = [group.tabItems lastObject];
        [lastItem.tabButton setHasRightCap:YES];
    }
}

- (void)makeTabs {
    _tabButtonView = [[SGWrapView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
    _tabButtonView.autoresizingMask = NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewMinYMargin|NSViewHeightSizable|NSViewMaxYMargin;
    
    NSArray *tabViewItems = self.tabViewItems;
    for (NSUInteger i = 0; i < tabViewItems.count; i ++)
    {
        XATabViewItem *tab = [tabViewItems objectAtIndex:i];
        [tab makeButton:_tabButtonView order:i];
    }
    
    [self setTabButtonCaps];
    
    // No prefs?
    [_selectedTabViewItem setSelected:YES];
}

- (void) makeOutline
{
    [_tabOutlineView enclosingScrollView].frame = NSMakeRect(.0, .0, prefs.xa_outline_width, self.frame.size.height);    
    
    [_tabOutlineView setOutlineTableColumn:[_tabOutlineView.tableColumns objectAtIndex:0]];
    [_tabOutlineView reloadData];
        
    for (XATabViewGroup *group in _groups) {
        [_tabOutlineView expandItem:group];
    }
    
    [_tabOutlineView selectRowForTabViewItem:self.selectedTabViewItem];
}

- (void) setTabViewType:(NSTabViewType) new_tabViewType
{
    self->tabViewType = new_tabViewType;

    if (tabViewType == XATabViewTypeOutline) {
        [self setOutlineWidth:prefs.xa_outline_width];
    } else {
        SGBoxOrientation newOrientation;
        SGBoxOrder newOrder;
        float rotation;
        
        switch (tabViewType)
        {
            case NSBottomTabsBezelBorder:
                newOrientation = SGBoxOrientationVertical;
                newOrder = SGBoxOrderLIFO;
                rotation = 0.0;
                break;
                
            case NSRightTabsBezelBorder:
                newOrientation = SGBoxOrientationHorizontal;
                newOrder = SGBoxOrderFIFO;
                rotation = 90.0;
                break;
                
            case NSLeftTabsBezelBorder:
                newOrientation = SGBoxOrientationHorizontal;
                newOrder = SGBoxOrderLIFO;
                rotation = -90.0;
                break;
                
            case NSTopTabsBezelBorder:
            default:
                newOrientation = SGBoxOrientationVertical;
                newOrder = SGBoxOrderFIFO;
                rotation = 0.0;
                break;
        }
        
        [_chatViewContainer setOrientation:newOrientation];
        [_chatViewContainer setOrder:newOrder];
        
        NSScrollView *outlineScrollView = [_tabOutlineView enclosingScrollView];
        [outlineScrollView setFrameSize:NSMakeSize(1.0, outlineScrollView.frame.size.height)];
        
        [_tabButtonView setBoundsRotation:rotation];
        NSSize size = _tabButtonView.frame.size;
        if ((rotation == 0.0) ^ (size.height < size.width)) {
            // restart is better than this...
            size = NSMakeSize(size.height, size.width);
        }
        if (rotation == 0.0) {
            size = NSMakeSize(_chatViewContainer.bounds.size.width, size.height);
        } else {
            size = NSMakeSize(size.width, _chatViewContainer.bounds.size.height);
        }
        [_tabButtonView setFrameSize:size];
        [_tabButtonView queue_layout];
    }
    self.chatView = self.chatView; // force reload in bad convention
}

- (XATabViewItem *)tabViewItemAtIndex:(NSInteger)index {
    if (index < 0 || index >= self.tabViewItems.count) return nil;
    return [self.tabViewItems objectAtIndex:index];
}

- (NSInteger) indexOfTabViewItem:(XATabViewItem *) tabViewItem
{
    return [self.tabViewItems indexOfObject:tabViewItem];
}

- (void) addTabViewItem:(XATabViewItem *) tabViewItem
{
    [self addTabViewItem:tabViewItem toGroup:0];
}

- (void)removeTabViewItem:(XATabViewItem *)tabViewItem {
    if (tabViewItem.tabView != self) return;
    
    [tabViewItem.view removeFromSuperview];
    [tabViewItem removeButton];
    tabViewItem.tabView = nil;

    if (_selectedTabViewItem == tabViewItem)
    {
        _selectedTabViewItem = nil;

        if (self.tabViewItems.count > 1 && !xchat_is_quitting) {
            // If there is another tab on the right of the tab being closed, and it's in the same group, choose it;
            // Else, if there is another tab on the left of the tab being closed, and it's in the same group, choose it;
            // Else, choose the tab on the right unless it's the last tab;
            // Else, choose the tab on the left.
            NSUInteger tabIndex = [self.tabViewItems indexOfObject:tabViewItem];
            NSUInteger lastTabIndex = self.tabViewItems.count - 1;
            NSUInteger selectedIndex;
            if (tabIndex < lastTabIndex && [[self.tabViewItems objectAtIndex:tabIndex + 1] groupIdentifier] == tabViewItem.groupIdentifier) {
                selectedIndex = tabIndex + 1;
            } else if (tabIndex > 0 && [[self.tabViewItems objectAtIndex:tabIndex - 1] groupIdentifier] == tabViewItem.groupIdentifier) {
                selectedIndex = tabIndex - 1;
            } else {
                selectedIndex = tabIndex == lastTabIndex ? tabIndex - 1 : tabIndex + 1;
            }
            [self selectTabViewItemAtIndex:selectedIndex];
        }
    }
    
    [_tabViewItems removeObject:tabViewItem];
    
    XATabViewGroup *group = [self groupForIdentifier:tabViewItem.groupIdentifier];
    [group.tabItems removeObject:tabViewItem];
    if (group.tabItems.count == 0) {
        [_groups removeObject:group];
    }
    
    if (xchat_is_quitting) return;

    [_tabOutlineView reloadData];
    // Removing items above the current item muck up the selected item in the outline
    [self.tabOutlineView selectRowForTabViewItem:self.selectedTabViewItem];
    
    [self setTabButtonCaps];
}

- (void) selectNextTabViewItem:(id)sender
{
    NSInteger n = [self indexOfTabViewItem:self.selectedTabViewItem] + 1;
    if (n < self.tabViewItems.count) {
        [self selectTabViewItemAtIndex:n];
    }
}

- (void) selectPreviousTabViewItem:(id)sender
{
    NSInteger n = [self indexOfTabViewItem:self.selectedTabViewItem] - 1;
    if (n >= 0) {
        [self selectTabViewItemAtIndex:n];
    }
}

- (void) selectTabViewItemAtIndex:(NSInteger) index
{
    [self selectTabViewItem:[self tabViewItemAtIndex:index]];
}

- (void)selectTabViewItem:(XATabViewItem *)tabViewItem {
    if (tabViewItem == _selectedTabViewItem) return;
    
    if (_selectedTabViewItem)
    {
        [_selectedTabViewItem.view removeFromSuperview];
        [_selectedTabViewItem setSelected:NO];
    }

    self.chatView = tabViewItem.view;

    _selectedTabViewItem = tabViewItem;
    [_selectedTabViewItem setSelected:YES];
    
    NSInteger row = [_tabOutlineView rowForItem:tabViewItem];
    [_tabOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
    if (_selectedTabViewItem.view)
    {
        id responder = _selectedTabViewItem.initialFirstResponder;
        if (responder) {
            [[self window] makeFirstResponder:responder];
        }
    }
        
    if ([_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)]) {
        [_delegate performSelector:@selector(tabView:didSelectTabViewItem:)
                        withObject:self
                        withObject:_selectedTabViewItem];
    }
    
    [_chatViewContainer layout_maybe];
}

- (BOOL) mouseDownCanMoveWindow
{
    return NO;
}

- (void)redrawTabItems {
    for (XATabViewItem *item in self.tabViewItems) {
        [item redrawTitle];
    }
    for (XATabViewGroup *group in self->_groups) {
        [self.tabOutlineView reloadData];
    }
}

#define kBackgroundStyleGroup   0
#define kBackgroundStyleCL      1
#define kBackgroundStyleTheme   2
enum {
    kTabBorderInset = 9 /* the exact value which matches the NSBox look is 11; however, since we have very little space between the box and the window border, using 9 gives a better visual balance */
};
#define BACKGROUND_VERSION  kBackgroundStyleCL

#if BACKGROUND_VERSION == kBackgroundStyleTheme
typedef OSStatus 
    (*ThemeDrawSegmentProc)(
        const HIRect *                  inBounds,
        const HIThemeSegmentDrawInfo *  inDrawInfo,
        CGContextRef                    inContext,
        HIThemeOrientation              inOrientation);
#endif

- (void) drawBackground
{
    if (self->tabViewType == XATabViewTypeOutline)
        return;
        
    NSRect r = _selectedTabViewItem.view.frame;
    //NSRect br = [hbox frame];
#if BACKGROUND_VERSION == kBackgroundStyleGroup
    //  const float dy = 12;    // floor (br.size.height / [hbox rowCount] / 2)
    //  const float dx = 12;    // floor (br.size.width / [hbox rowCount] / 2)
    const float dr = 12;
#elif BACKGROUND_VERSION == kBackgroundStyleTheme
    const float d2 = -3;
    const float dr = kTabBorderInset - d2 - 1;
    r = NSInsetRect(r, d2, d2);
#elif BACKGROUND_VERSION == kBackgroundStyleCL
    const float dr = kTabBorderInset;
#endif

    switch (tabViewType)
    {
        case NSBottomTabsBezelBorder:
            r.origin.y -= dr;
        case NSTopTabsBezelBorder:
        default:
            r.size.height += dr;
            break;
            
        case NSLeftTabsBezelBorder:
            r.origin.x -= dr;
        case NSRightTabsBezelBorder:
            r.size.width += dr;
            break;
    }
    
#if BACKGROUND_VERSION == kBackgroundStyleTheme
    // Doesn't look right on 10.3
    HIRect paneRect = NSRectToCGRect(r);
    HIThemeTabPaneDrawInfo drawInfo;
    drawInfo.version = 1;
    drawInfo.state = [[self window] isMainWindow] ? kThemeStateActive : kThemeStateInactive;
    drawInfo.direction = kThemeTabNorth;
    drawInfo.size = kHIThemeTabSizeNormal;
    drawInfo.kind = kHIThemeTabKindNormal;
    drawInfo.adornment = kHIThemeTabPaneAdornmentNormal;
    
    OSStatus err = HIThemeDrawTabPane(&paneRect, &drawInfo, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                                      [self isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted);
    if (err != noErr) [NSException raise:NSGenericException format:@"XATabView: HIThemeDrawTabPane returned %d", err];
#elif BACKGROUND_VERSION == kBackgroundStyleGroup
    HIRect paneRect = NSRectToCGRect(r);
    HIThemeGroupBoxDrawInfo drawInfo;
    drawInfo.version = 1;
    drawInfo.state = [[self window] isMainWindow] ? kThemeStateActive : kThemeStateInactive;
    drawInfo.kind = kHIThemeGroupBoxKindPrimary;
    
    HIThemeDrawGroupBox(&paneRect, &drawInfo, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                        [self isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted);
#elif BACKGROUND_VERSION == kBackgroundStyleCL
    [[[NSColor blackColor] colorWithAlphaComponent:0.05] set];
    [NSBezierPath fillRect:r];
    
    [NSBezierPath setDefaultLineWidth:1];
    [[NSGraphicsContext currentContext] setShouldAntialias:false];
    
    r = NSInsetRect(r,-0.5,-0.5);
    [[[NSColor grayColor] colorWithAlphaComponent:0.25] set];
    [NSBezierPath strokeRect:r];
    r = NSInsetRect(r,-1,-1);
    [[[NSColor grayColor] colorWithAlphaComponent:0.5] set];
    [NSBezierPath strokeRect:r];
#endif // BACKGROUND_VERSION
}

- (void) drawRect:(NSRect) aRect
{
    if (_selectedTabViewItem == nil) {
        return;
    }

    if (self->tabViewType != XATabViewTypeOutline) {
        [self drawBackground];
    }
}

- (void)addTabViewItem:(XATabViewItem *)tabViewItem toGroup:(NSInteger)groupIdentifier {
    if (self == tabViewItem.tabView) return;

    tabViewItem.tabView = self;
    tabViewItem.groupIdentifier = groupIdentifier;

    // In order for selectNext and selectPrevious to work, we need to add this item
    // in the correct order.  We'll also insert the tab button at the same position.
    
    NSUInteger index = 0;
    for (; index < self.tabViewItems.count; index ++) {
        XATabViewItem *tab = [self.tabViewItems objectAtIndex:index];
        if (tab.groupIdentifier == groupIdentifier) {
            index ++;
            break;
        }
    } // strat of matching group now
    for (; index < self.tabViewItems.count; index ++) {
        XATabViewItem *tab = [self.tabViewItems objectAtIndex:index];
        if (tab.groupIdentifier != groupIdentifier) {
            break;
        }
    } // end of matching group now

    [_tabViewItems insertObject:tabViewItem atIndex:index];
    
    XATabViewGroup *group = [self groupForIdentifier:tabViewItem.groupIdentifier];
    [group.tabItems addObject:tabViewItem];

    [tabViewItem makeButton:_tabButtonView order:index];
    
    [self setTabButtonCaps];

    [_tabOutlineView reloadData];

    if (_selectedTabViewItem == nil) {
        [self selectTabViewItem:tabViewItem];
    }
}

#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return [_groups objectAtIndex:index];
    }
        
    if ([item isKindOfClass:[XATabViewGroup class]]) {
        return [[item tabItems] objectAtIndex:index];
    }
        
    // Not possible
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[XATabViewGroup class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return [_groups count];
    }
        
    if ([item isKindOfClass:[XATabViewGroup class]]) {
        return [[item tabItems] count];
    }
        
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[XATabViewGroup class]])
        return [item name];
        
    if ([item isKindOfClass:[XATabViewItem class]])
        return [item label];

    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return [item isKindOfClass:[XATabViewItem class]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if ([item isKindOfClass:[XATabViewItem class]]) {
        [cell setTextColor:[item titleColor]];
        [cell setHasCloseButton:!prefs.xa_hide_tab_close_buttons];
    } else {
        NSColor *color;
        if (prefs.tab_layout == 2 && prefs.style_namelistgad) {
            color = [[[AquaChat sharedAquaChat] palette] getColor:XAColorForeground];
        } else {
            color = [NSColor blackColor];
        }
        [cell setTextColor:color];
        [cell setHasCloseButton:NO];
    }
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification
{
    id item = [_tabOutlineView itemAtRow:[_tabOutlineView selectedRow]];
    if (item && [item isKindOfClass:[XATabViewItem class]]) {
        [self selectTabViewItem:item];
    }
}

#pragma mark - NSSplitView

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (self->tabViewType == XATabViewTypeOutline) {
        prefs.xa_outline_width = _tabOutlineView.frame.size.width;
    }
}

@end
