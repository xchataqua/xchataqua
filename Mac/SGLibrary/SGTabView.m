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
#import "SGTabView.h"
#import "CLTabViewButtonCell.h"

static NSMutableDictionary *labelDictionary;

//////////////////////////////////////////////////////////////////////

typedef OSStatus 
    (*ThemeDrawSegmentProc)(
      const HIRect *                  inBounds,
      const HIThemeSegmentDrawInfo *  inDrawInfo,
      CGContextRef                    inContext,
      HIThemeOrientation              inOrientation);

static ThemeDrawSegmentProc MyThemeDrawSegment;

static ThemeDrawState MySegmentHilightFlag;
static ThemeDrawState MySegmentFGSelectedFlag;
static ThemeDrawState MySegmentNormalFlag;
static ThemeDrawState MySegmentBGSelectedFlag;

static CGFloat MySegmentHeight;

//////////////////////////////////////////////////////////////////////

static NSImage *getCloseImage()
{
    static NSImage *close_image;
    if (!close_image)
        close_image = [NSImage imageNamed:@"close.tiff"];
    return close_image;
}

@interface NSButtonCell (SGTabViewCloseCell)

+ (NSButtonCell *)tabViewCloseCell;

@end

@implementation NSButtonCell (SGTabViewCloseCell)

+ (NSButtonCell *)tabViewCloseCell {
    NSButtonCell *closeCell = [[self alloc] initImageCell:getCloseImage()];
    [closeCell setButtonType:NSMomentaryLightButton];
    [closeCell setImagePosition:NSImageOnly];
    [closeCell setBordered:NO];
    [closeCell setHighlightsBy:NSContentsCellMask];
    return [closeCell autorelease];    
}

@end

#pragma mark -

@interface SGTabViewOutlineCell : NSTextFieldCell
{
    BOOL hasClose;
    NSButtonCell *closeCell;
}

@property (nonatomic, assign) BOOL hasClose;

@end

@implementation SGTabViewOutlineCell
@synthesize hasClose;

- (id) initTextCell:(NSString *) aString
{
    if ((self = [super initTextCell:aString]) != nil) {
        closeCell = [[NSButtonCell tabViewCloseCell] retain];
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
    SGTabViewOutlineCell *copy = [super copyWithZone:zone];
    copy->closeCell = [closeCell copyWithZone:zone];
    return copy;
}

- (void) doClose:(id)sender
{
    [[closeCell target] performSelector:[closeCell action]];
}

- (NSRect) calculateCloseRectWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    NSRect r;
    
    r.size = [getCloseImage() size];
    r.origin.x = cellFrame.origin.x;
    r.origin.y = cellFrame.origin.y + floor ((cellFrame.size.height - r.size.height) / 2);
    
    return r;
}

- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
    NSRect closeRect = NSMakeRect(0, 0, 0, 0);

    if (hasClose)
    {
        closeRect = [self calculateCloseRectWithFrame:cellFrame inView:controlView];
        cellFrame.origin.x += closeRect.size.width + 5.0f;
    }

    [super drawInteriorWithFrame:cellFrame inView:controlView];

    // Gotta draw the icon last because highlighted cells have a
    // blue background which will cover the image otherwise.                  
    if (hasClose) {
        [closeCell drawInteriorWithFrame:closeRect inView:controlView];
    }
}

- (BOOL) mouseDown:(NSEvent *) theEvent
         cellFrame:(NSRect) cellFrame
       controlView:(NSView *) controlView
       closeAction:(SEL) closeAction
       closeTarget:(id) closeTarget
{
    if (!hasClose)
        return NO;

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

@interface SGTabViewOutlineView : NSOutlineView
@end

@implementation SGTabViewOutlineView

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

        if ([item isKindOfClass:[SGTabViewItem class]])
        {
            NSTableColumn *tableColumn = [[self tableColumns] objectAtIndex:col];
            SGTabViewOutlineCell *cell = [tableColumn dataCell];
            
            if ([cell isKindOfClass:[SGTabViewOutlineCell class]])
            {
                [[self delegate] outlineView:self willDisplayCell:cell forTableColumn:tableColumn item:item];
                if ([cell mouseDown:theEvent 
                          cellFrame:[self frameOfCellAtColumn:col row:row]
                        controlView:self
                        closeAction:@selector (doClose:)
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

        if ([item isKindOfClass:[SGTabViewItem class]])
        {
            return ((SGTabViewItem *)item)->ctxMenu;
        }
    }
    
    return [super menuForEvent:theEvent];
}

@end

#pragma mark -

@interface SGTabViewGroupInfo : NSObject
{
  @public
    NSInteger    group;
    NSString    *name;
    NSMutableArray *tabs;
}

@property (nonatomic, retain) NSString *name;

@end

@implementation SGTabViewGroupInfo
@synthesize name;

- (id) init
{
    if ((self = [super init]) != nil) {
        group = 0;
        name = nil;
        tabs = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    [name release];
    [tabs release];
    [super dealloc];
}

- (NSUInteger) numberOfTabs
{
    return [tabs count];
}

- (SGTabViewItem *) tabAtIndex:(int) index
{
    return [tabs objectAtIndex:index];
}

- (void) addTabViewItem:(SGTabViewItem *) item
{
    [tabs addObject:item];
}

- (void) removeTabViewItem:(SGTabViewItem *) item
{
    [tabs removeObject:item];
}

@end

#pragma mark -

HIThemeSegmentPosition positionTable[2][2] = 
{
    //                            No right cap                    right cap
    /* No left cap */    { kHIThemeSegmentPositionMiddle, kHIThemeSegmentPositionLast },
    /* Left cap       */   { kHIThemeSegmentPositionFirst,  kHIThemeSegmentPositionOnly },
};

@interface SGTabViewButtonCell : NSButtonCell
{
    NSColor *titleColor;
    BOOL     hideClose;
    BOOL     left_cap;
    BOOL     right_cap;
    NSRect   close_rect;
    NSPoint  textPoint;
    NSButtonCell *closeCell;
    NSSize    cellSize;
    HIThemeSegmentDrawInfo drawInfo;
}

@property (nonatomic, retain) NSColor *titleColor;
@property (nonatomic, readonly) NSSize cellSize;

@end

#pragma mark -

@implementation SGTabViewButtonCell
@synthesize cellSize, titleColor;

+ (void) initialize
{
    labelDictionary = [[NSMutableDictionary alloc] init];
    [labelDictionary setObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]] forKey:NSFontAttributeName];

    // Setup stuff for drawing the segments.
    //
    // NOTE to Camillo.. if you're still alive and wondering why I didn't use your patch,
    // let me tell you (and anyone else that wonders WTF is going on here).
    //
    // I like the idea of drawing segments rather than tabs (even thought they look the same)
    // for a few reasons.
    //    1.  The same code works on 10.3 and 10.4.
    //    2.  It's much simpler in implementation.
    //    3.  If 10.5 changes tabs in any drastic way, we'd be broken.  In other words, my
    //      tab view is pretty much dependant on the way tabs work on 10.4.  i.e. with segments.
    //
    // Now I know what you're thinking.. we're using private APIs and that's bogus!  You're right
    // but the odds of Apple changing 10.3 or even 10.4 at this time isn't very likely.  If they
    // do change things, then we're screwed but hopefully they also fix the bugs for 10.4 at the
    // same time.  I thought about this problem for quite some time and I feel this is the lesser
    // of the evils.  Please feel free to awake from the dead and tell me what you think.
        
    SInt32 version = 0;
    Gestalt(gestaltSystemVersion, &version);
    
    #if 0
    if (version < 0x1040)
    {
        // 10.3 has this API, but it's a private API.
        // We know from GDB that that the public API on 10.4 just 
        // calls the private function without any parameter
        // differences so we feel pretty good about using the private API.
        //
        // (gdb) disass HIThemeDrawSegment
        // Dump of assembler code for function HIThemeDrawSegment:
        // 0x92f57234 <HIThemeDrawSegment+0>:      push   %ebp
        // 0x92f57235 <HIThemeDrawSegment+1>:      mov    %esp,%ebp
        // 0x92f57237 <HIThemeDrawSegment+3>:      pop    %ebp
        // 0x92f57238 <HIThemeDrawSegment+4>:      jmp    0x92e4d6e4 <_HIThemeDrawSegment>
        
        MyThemeDrawSegment = (ThemeDrawSegmentProc) dlsym (RTLD_DEFAULT, "_HIThemeDrawSegment");
    }
    else
    #endif
    {
        // So yea.. this is technically the same as the 10.3 case but it may not
        // be the same on 10.5..
        MyThemeDrawSegment = (ThemeDrawSegmentProc) dlsym (RTLD_DEFAULT, "HIThemeDrawSegment");
    }

    // As for this, the public (and private) APIs have bugs.  The documented
    // flags don't work.  These were discovered by CL.  If Apple ever fixes
    // the bugs, then we can change these flags in the proper gestalt block.
    
    MySegmentHilightFlag = 0xc0000000;
    MySegmentFGSelectedFlag = 0x80000000;
    MySegmentNormalFlag = 0;
    MySegmentBGSelectedFlag = 0x80000001;
    
    // The theme APIs for getting the segment height is broken too.
    // Just get a cell and ask it...
    NSSegmentedCell *cell = [[NSSegmentedCell alloc] initTextCell:@""];
    MySegmentHeight = [cell cellSize].height;
    [cell release];
}

- (id) initTextCell:(NSString *) aString
{
    if ((self = [super initTextCell:aString]) != nil) {
        closeCell = [[NSButtonCell tabViewCloseCell] retain];
        self->hideClose = false;
    }
    return self;
}

- (void) dealloc
{
    [titleColor release];
    [super dealloc];
}

// Undocumented method used to update the cell when the window is activated/deactivated
- (BOOL) _needRedrawOnWindowChangedKeyState
{
    return YES;
}

- (void) setHideCloseButton:(BOOL) hideit
{
    self->hideClose = hideit;
    [self calcDrawInfo:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
}

- (void) setHasLeftCap:(BOOL) b
{
    if (left_cap == b) return;
    
    left_cap = b;
    [self calcDrawInfo:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
}

- (void) setHasRightCap:(BOOL) b
{
    if (right_cap == b) return;

    right_cap = b;
    [self calcDrawInfo:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
}

- (void) setCloseAction:(SEL) act
{
    [closeCell setAction:act];
}

- (void) setCloseTarget:(id) targ
{
    [closeCell setTarget:targ];
}

- (void) doClose:(id)sender
{
    [[closeCell target] performSelector:[closeCell action]];
}

- (void) calcDrawInfo:(NSRect) aRect
{
    // [super init] calls us before we are ready
    if (!closeCell)
        return;

    cellSize.height = MySegmentHeight;
    
    NSSize sz = [[self title] sizeWithAttributes:labelDictionary];

    if (hideClose)
    {
        close_rect = NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f);
        textPoint.x = 7.0f + 2.0f;
        textPoint.y = (cellSize.height - sz.height) / 2;
    }
    else
    {
        NSSize closeSize = [closeCell cellSize];

        close_rect.size = closeSize;
        close_rect.origin.x = 7.0f;
        close_rect.origin.y = (cellSize.height - close_rect.size.height) / 2;

        textPoint.x = close_rect.origin.x + closeSize.width + 3;
        textPoint.y = (cellSize.height - sz.height) / 2;
    }

    cellSize.width = floor (sz.width + textPoint.x + 7 + 2);
    
    drawInfo.version = 1;
    drawInfo.value = kThemeButtonOn;
    drawInfo.size = kHIThemeSegmentSizeNormal;
    drawInfo.kind = kHIThemeSegmentKindNormal;
    drawInfo.position = positionTable[left_cap][right_cap];

    drawInfo.adornment = (left_cap ? kHIThemeSegmentAdornmentNone : kHIThemeSegmentAdornmentLeadingSeparator) |
                         (right_cap ? kHIThemeSegmentAdornmentNone : kHIThemeSegmentAdornmentTrailingSeparator);
}

- (void) setTitle:(NSString *) aString
{
    [super setTitle:aString];
    [self calcDrawInfo:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
}

- (void) drawCellBodyWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    BOOL selected = [self state] == NSOnState;
    BOOL hilight = [self isHighlighted];
    
    if ([[controlView window] isMainWindow])
    {
        drawInfo.state = hilight ? MySegmentHilightFlag : 
            selected ? MySegmentFGSelectedFlag : MySegmentNormalFlag;
    }
    else
    {
        drawInfo.state = selected ? MySegmentBGSelectedFlag : MySegmentNormalFlag;
    }

    HIRect cellRect;
    cellRect.origin.x = cellFrame.origin.x;
    cellRect.origin.y = cellFrame.origin.y;
    cellRect.size.width = cellFrame.size.width;
    cellRect.size.height = cellFrame.size.height;

    HIThemeOrientation orientation = [controlView isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted;

    NSGraphicsContext *ctx = [NSGraphicsContext currentContext];
    MyThemeDrawSegment(&cellRect, &drawInfo, (CGContextRef)[ctx graphicsPort], orientation);
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    [self drawCellBodyWithFrame:cellFrame inView:controlView];
    
    if (!hideClose)
        [closeCell drawWithFrame:close_rect inView:controlView];

    // I'm not sure if this actually even does anything
    if (prefs.tab_layout == 2 && prefs.style_namelistgad) {
        ColorPalette *p = [[AquaChat sharedAquaChat] palette];
        [labelDictionary setObject:(titleColor?titleColor:[p getColor:AC_FGCOLOR]) forKey:NSForegroundColorAttributeName];
    } else {
        [labelDictionary setObject:(titleColor?titleColor:[NSColor blackColor]) forKey:NSForegroundColorAttributeName];
    }

    [[self title] drawAtPoint:textPoint withAttributes:labelDictionary];
}

- (void) mouseDown:(NSEvent *)event controlView:(NSView *) controlView
{
    NSButtonCell *track_cell;
    NSRect track_rect;
    
    NSPoint p = [controlView convertPoint:[event locationInWindow] fromView:nil];
    BOOL mouseIn = NSMouseInRect (p, close_rect, [controlView isFlipped]);
    
    if (!hideClose && mouseIn)
    {
        track_cell = closeCell;
        track_rect = close_rect;
    }
    else
    {
        track_cell = self;
        track_rect = [controlView bounds];
    }

    [SGGuiUtility trackButtonCell:track_cell withEvent:event inRect:track_rect controlView:controlView];
}

@end

#pragma mark -

@interface SGTabViewButton: NSButton

- (void) setCloseAction:(SEL) act;
- (void) setCloseTarget:(id) targ;
- (void) setHideCloseButton:(BOOL) hideit;

@end

@implementation SGTabViewButton

/* CL: undocumented method used to update the cell when the window is activated/deactivated */
- (void) _windowChangedKeyState 
{
    [self updateCell:[self cell]];
}

- (id) init
{
    if ((self = [super init]) != nil) {
        [self setCell:[[[CLTabViewButtonCell alloc] init] autorelease]];
        [self setButtonType:NSOnOffButton];
        [[self cell] setControlSize:NSSmallControlSize];
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

- (void) setCloseAction:(SEL) act
{
    [[self cell] setCloseAction:act];
}

- (void) setCloseTarget:(id) targ
{
    [[self cell] setCloseTarget:targ];
}

- (void) setHasLeftCap:(BOOL) b
{
    [[self cell] setHasLeftCap:b];
}

- (void) setHasRightCap:(BOOL) b
{
    [[self cell] setHasRightCap:b];
}

- (void) setTitleColor:(NSColor *) c
{
    [[self cell] setTitleColor:c];
    [self setNeedsDisplay:true];
}

- (void) mouseDown:(NSEvent *) e
{
    [[self cell] mouseDown:e controlView:self];
}

- (BOOL) isFlipped
{
    return NO;
}

@end

#pragma mark -

NSNib *SGTabViewItemTabMenuNib;

@implementation SGTabViewItem
@synthesize label;
@synthesize titleColor=_titleColor;
@synthesize view=_view;
@synthesize initialFirstResponder=_initialFirstResponder;

+ (void)initialize {
    if (self == [SGTabViewItem class]) {
        SGTabViewItemTabMenuNib = [[NSNib alloc] initWithNibNamed:@"TabMenu" bundle:nil];
    }
}

- (id) initWithIdentifier:(id) identifier
{
    self = [super init];
    if (self != nil) {    
        [SGTabViewItemTabMenuNib instantiateNibWithOwner:self topLevelObjects:nil];
    }
    return self;
}

- (void) dealloc
{
    self.label = nil;
    self.titleColor = nil;
    self.view = nil;
    [button release];
    [ctxMenu release];
    [super dealloc];
}

- (void) makeButton:(SGWrapView *) box
              where:(NSUInteger) where
          withClose:(BOOL) with_close
{
    button = [[SGTabViewButton alloc] init]; // ???: not released here?
    [button setAction:@selector (doit:)];
    [button setTarget:self];
    [button setCloseAction:@selector (doClose:)];
    [button setCloseTarget:self];
    [button setHideCloseButton:!with_close];
    [[button cell] setMenu:ctxMenu];
    
    [box addSubview:button];
    [box setOrder:where forView:button];

    [self setLabel:label];
}

- (void)removeButton
{
    if (button)
    {
        [button removeFromSuperview];
        [button release];
        button = nil;
    }
}

- (SGTabView *) tabView
{
    return parent;
}

- (BOOL)isFrontTab
{
    return [parent selectedTabViewItem] == self;
}

- (void) setHideCloseButton:(BOOL) hidem
{
    [button setHideCloseButton:hidem];
}

- (void) setTitleColor:(NSColor *) color
{
    [_titleColor autorelease];
    _titleColor = [color retain];
    if (button) {
        [button setTitleColor:color];
    }
    [parent.tabOutlineView reloadData];
}

- (void) doClose:(id)sender
{
    // TODO
    // This method shoud probably close the tab
    // and behave much like clicking the red close
    // button on a window.
    if (parent)
        [[parent delegate] tabWantsToClose:self];
}

- (void) link_delink:(id)sender
{
    if (parent)
        [[parent delegate] link_delink:self];
}

- (void) doit:(id)sender
{
    if (parent)
    {
        [button setIntValue:1];
        [parent selectTabViewItem:self];
    }
}

- (void) setLabel:(NSString *) new_label
{
    if (new_label != label)
    {
        [label release];
        label = [new_label retain];
    }
    
    if (button)
    {    
        [button setTitle:label];
        [button sizeToFit];
    }
    else
    {
        [parent.tabOutlineView reloadData];
    }
}

- (void) setSelected:(BOOL) selected
{
    if (button) {
        [button setIntegerValue:!!selected];
    }
}

- (void) setView:(NSView *)view
{
    [_view removeFromSuperview];
    [_view release];

    _view = [view retain];

    if (self == parent.selectedTabViewItem)
    {
        parent.chatView = view;
    }
}

@end

#pragma mark -

@implementation SGTabView
@synthesize delegate=_delegate;
@synthesize tabOutlineView=_tabOutlineView;
@synthesize selectedTabViewItem=_selectedTabViewItem;

- (void)SGTabViewInit {
    self->_tabViewItems = [[NSMutableArray alloc] init];
    self->groups = [[NSMutableArray alloc] init];
    [_chatViewContainer	 setMinorDefaultJustification:SGBoxMinorJustificationFull];
}

- (id) initWithFrame:(NSRect) frameRect
{
    self = [super initWithFrame:frameRect];
    [self SGTabViewInit];
    [self makeOutline];
    [self makeTabs];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self SGTabViewInit];
    return self;
}

- (void)awakeFromNib {
    [self makeOutline];
    [self makeTabs];
}

- (void) dealloc
{
    [_tabViewItems release];
    [groups release];
    [super dealloc];
}

- (void) setOutlineWidth:(CGFloat) width
{
    prefs.xa_outline_width = width;
    if (width < 50.0f) {            // Just because
        width = 50.0f;
    }
    if (self->tabViewType != SGOutlineTabs) return;
    
    NSScrollView *outlineScroll = [_tabOutlineView enclosingScrollView];
    [outlineScroll setFrameSize:NSMakeSize(width, [outlineScroll frame].size.height)];
}

- (id)chatView {
    if (_chatViewContainer.subviews.count == 0) return nil;
    return [_chatViewContainer.subviews objectAtIndex:0];
}

- (void)setChatView:(id)chatView {
    while (_chatViewContainer.subviews.count > 0) {
        [[_chatViewContainer.subviews objectAtIndex:0] removeFromSuperview];
    }
    [chatView setFrame:_chatViewContainer.bounds];
    [_chatViewContainer addSubview:chatView];
    [_chatViewContainer setStretchView:chatView];
    
    if (self->tabViewType != SGOutlineTabs) {
        [_chatViewContainer addSubview:_tabButtonView];
    }
}

- (SGTabViewGroupInfo *)getGroupInfo:(NSInteger) group
{
    SGTabViewGroupInfo *info = nil;
    for (SGTabViewGroupInfo *this_info in groups) {
        if (this_info->group == group)
        {
            info = this_info;
            break;
        }
    }
    
    if (info == nil)
    {
        info = [[SGTabViewGroupInfo alloc] init];
        info->group = group;
        [groups addObject:info];
        [_tabOutlineView reloadData];
        [_tabOutlineView expandItem:info];
        [info release];
    }
    
    return info;
}

- (void) setName:(NSString *)name forGroup:(NSInteger)group
{
    [[self getGroupInfo:group] setName:name];
    [_tabOutlineView reloadData];
}

- (NSString *) groupName:(NSInteger) group
{
    return [[self getGroupInfo:group] name];
}

- (void) setHideCloseButtons:(BOOL) hidem
{
    self->hideClose = hidem;
    
    for (SGTabViewItem *tab in self.tabViewItems)
    {
        [tab setHideCloseButton:hideClose];
    }
}

- (NSArray *) tabViewItems
{
    return _tabViewItems;
}

- (void) setCaps
{        
    SGTabViewItem *lastTab = nil;
    for (SGTabViewItem *tab in self.tabViewItems)
    {
        [tab->button setHasLeftCap:!lastTab || (tab->group != lastTab->group)];
        if (lastTab)
            [lastTab->button setHasRightCap:tab->group != lastTab->group];
        lastTab = tab;
    }
    if (lastTab)
        [lastTab->button setHasRightCap:YES];
}

- (void) makeTabs
{
    _tabButtonView = [[SGWrapView alloc] initWithFrame:NSMakeRect(0.0f, 0.0f, 1.0f, 1.0f)];
    _tabButtonView.autoresizingMask = NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewMinYMargin|NSViewHeightSizable|NSViewMaxYMargin;
    [_chatViewContainer addSubview:_tabButtonView];
    
    NSArray *tabViewItems = self.tabViewItems;
    for (NSUInteger i = 0; i < tabViewItems.count; i ++)
    {
        SGTabViewItem *tab = [tabViewItems objectAtIndex:i];
        [tab makeButton:_tabButtonView where:i withClose:!hideClose];
    }
    
    [self setCaps];
    
    [_selectedTabViewItem setSelected:YES];
}

- (void) makeOutline
{    
    ColorPalette *p = [[AquaChat sharedAquaChat] palette];

    [_tabOutlineView enclosingScrollView].frame = NSMakeRect(.0, .0, prefs.xa_outline_width, self.frame.size.height);    
    
    CGFloat fontSize = [NSFont smallSystemFontSize];
    if (prefs.tab_small) {
        fontSize *= 0.86;
    }
    NSFont *font = [NSFont systemFontOfSize:fontSize];
    SGTabViewOutlineCell *dataCell = [[_tabOutlineView.tableColumns objectAtIndex:0] dataCell];
    dataCell.font = font;

    NSLayoutManager *layoutManager=[[NSLayoutManager new] autorelease];

    [_tabOutlineView setOutlineTableColumn:[_tabOutlineView.tableColumns objectAtIndex:0]];
    [_tabOutlineView setRowHeight:[layoutManager defaultLineHeightForFont:font] + 1];

    [_tabOutlineView reloadData];
        
    for (SGTabViewGroupInfo *info in groups)
        [_tabOutlineView expandItem:info];

    NSInteger row = [_tabOutlineView rowForItem:self.selectedTabViewItem];
    [_tabOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    if (prefs.style_namelistgad) {
        dataCell.textColor = [p getColor:AC_FGCOLOR];
        _tabOutlineView.backgroundColor = [p getColor:AC_BGCOLOR];
    }
}

- (void) setTabViewType:(NSTabViewType) new_tabViewType
{
    self->tabViewType = new_tabViewType;
    
    SGBoxOrientation newOrientation;
    SGBoxOrder newOrder;
    float rotation;

    switch (tabViewType)
    {
        case SGOutlineTabs:
            break;
            
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

    if (tabViewType == SGOutlineTabs) {
        [self setOutlineWidth:prefs.xa_outline_width];
    } else {
        NSScrollView *outlineScrollView = [_tabOutlineView enclosingScrollView];
        [outlineScrollView setFrameSize:NSMakeSize(1.0, outlineScrollView.frame.size.height)];
        
        [_tabButtonView setBoundsRotation:rotation];
        NSSize size = _tabButtonView.frame.size;
        if ((rotation == 0.0) ^ (size.height < size.width)) {
            // restart is better than this...
            [_tabButtonView setFrameSize:NSMakeSize(size.height, size.width)];
        }
        [_tabButtonView queue_layout];
    }
    self.chatView = self.chatView;
}

- (SGTabViewItem *) tabViewItemAtIndex:(NSInteger) index
{
    return (NSUInteger) index < self.tabViewItems.count ? [self.tabViewItems objectAtIndex:index] : nil;
}

- (NSInteger) indexOfTabViewItem:(SGTabViewItem *) tabViewItem
{
    return [self.tabViewItems indexOfObject:tabViewItem];
}

- (void) addTabViewItem:(SGTabViewItem *) tabViewItem
{
    [self addTabViewItem:tabViewItem toGroup:0];
}

- (void) removeTabViewItem:(SGTabViewItem *) tabViewItem
{
    if ([tabViewItem tabView] != self)
        return;
    
    [tabViewItem.view removeFromSuperview];
    [tabViewItem removeButton];
    tabViewItem->parent = nil;

    if (_selectedTabViewItem == tabViewItem)
    {
        _selectedTabViewItem = nil;

        if (self.tabViewItems.count > 1)
        {
            // If there is another tab on the right of the tab being closed, and it's in the same group, choose it;
            // Else, if there is another tab on the left of the tab being closed, and it's in the same group, choose it;
            // Else, choose the tab on the right unless it's the last tab;
            // Else, choose the tab on the left.
            NSUInteger tabIndex = [self.tabViewItems indexOfObject:tabViewItem];
            NSUInteger lastTabIndex = self.tabViewItems.count - 1;
            NSUInteger selectedIndex;
            if (tabIndex < lastTabIndex && ((SGTabViewItem *)[self.tabViewItems objectAtIndex:tabIndex + 1])->group == tabViewItem->group) {
                selectedIndex = tabIndex + 1;
            } else if (tabIndex > 0 && ((SGTabViewItem *)[self.tabViewItems objectAtIndex:tabIndex - 1])->group == tabViewItem->group) {
                selectedIndex = tabIndex - 1;
            } else {
                selectedIndex = tabIndex == lastTabIndex ? tabIndex - 1 : tabIndex + 1;
            }
            [self selectTabViewItemAtIndex:selectedIndex];
        }
    }
    
    [_tabViewItems removeObject:tabViewItem];
    
    SGTabViewGroupInfo *info = [self getGroupInfo:tabViewItem->group];
    [info removeTabViewItem:tabViewItem];
    if ([info->tabs count] == 0) {
        [groups removeObject:[self getGroupInfo:tabViewItem->group]];
    }

    [_tabOutlineView reloadData];
        // Removing items above the current item muck up the selected item in the outline
    NSInteger row = [_tabOutlineView rowForItem:_selectedTabViewItem];
    [_tabOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
    [self setCaps];
}

- (void) selectNextTabViewItem:(id)sender
{
    NSInteger n = [self indexOfTabViewItem:self.selectedTabViewItem] +1;
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

- (void) selectTabViewItem:(SGTabViewItem *) tabViewItem
{
    if (_selectedTabViewItem)
    {
        if (tabViewItem == _selectedTabViewItem) {
            return;
        }
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
        if ([_selectedTabViewItem initialFirstResponder])
            [[self window] makeFirstResponder:[_selectedTabViewItem initialFirstResponder]];
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

#define kBackgroundStyleGroup   0
#define kBackgroundStyleGL      1
#define kBackgroundStyleTheme   2
enum {
    kTabBorderInset = 9 /* the exact value which matches the NSBox look is 11; however, since we have very little space between the box and the window border, using 9 gives a better visual balance */
};
#define BACKGROUND_VERSION  kBackgroundStyleGL

- (void) drawBackground
{
    if (self->tabViewType == SGOutlineTabs)
        return;
        
    NSRect r = _selectedTabViewItem.view.frame;
    //NSRect br = [hbox frame];
#if BACKGROUND_VERSION == kBackgroundStyleGroud
    //  const float dy = 12;    // floor (br.size.height / [hbox rowCount] / 2)
    //  const float dx = 12;    // floor (br.size.width / [hbox rowCount] / 2)
    const float dr = 12;
#elif BACKGROUND_VERSION == kBackgroundStyleTheme
    const float d2 = -3;
    const float dr = kTabBorderInset - d2 - 1;
    r = NSInsetRect(r, d2, d2);
#else
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
    if (err != noErr) [NSException raise:NSGenericException format:@"SGTabView: HIThemeDrawTabPane returned %d", err];
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
    if (_selectedTabViewItem == nil)
        return;

    if (self->tabViewType != SGOutlineTabs) {
        [self drawBackground];
    }
}

- (void) addTabViewItem:(SGTabViewItem *) tabViewItem toGroup:(NSInteger) group
{
    if (tabViewItem->parent)
        return;

    tabViewItem->parent = self;
    tabViewItem->group = group;

    // In order for selectNext and selectPrevious to work, we need to add this item
    // in the correct order.  We'll also insert the tab button at the same position.
    
    NSUInteger where = 0;
    for (; where < self.tabViewItems.count; where ++)
    {
        SGTabViewItem *tab = [self.tabViewItems objectAtIndex:where];
        if (tab->group == group)
        {
            where ++;
            break;
        }
    }
    for (; where < self.tabViewItems.count; where ++)
    {
        SGTabViewItem *tab = [self.tabViewItems objectAtIndex:where];
        if (tab->group != group)
            break;
    }

    [_tabViewItems insertObject:tabViewItem atIndex:where];
    
    SGTabViewGroupInfo *info = [self getGroupInfo:tabViewItem->group];
    [info addTabViewItem:tabViewItem];

    [tabViewItem makeButton:_tabButtonView where:where withClose:!hideClose];
    
    [self setCaps];

    [_tabOutlineView reloadData];

    if (_selectedTabViewItem == nil) {
        [self selectTabViewItem:tabViewItem];
    }
}

#pragma mark NSOutlineViewDataSource

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil)
        return [groups objectAtIndex:index];
        
    if ([item isKindOfClass:[SGTabViewGroupInfo class]])
        return [item tabAtIndex:index];
        
    // Not possible
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [item isKindOfClass:[SGTabViewGroupInfo class]];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil)
        return [groups count];
        
    if ([item isKindOfClass:[SGTabViewGroupInfo class]])
        return [item numberOfTabs];
        
    return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[SGTabViewGroupInfo class]])
        return [item name];
        
    if ([item isKindOfClass:[SGTabViewItem class]])
        return [item label];

    return @"";
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    return [item isKindOfClass:[SGTabViewItem class]];
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSColor *color;
    if (prefs.tab_layout == 2 && prefs.style_namelistgad) {
        ColorPalette *p = [[AquaChat sharedAquaChat] palette];
        color = [p getColor:AC_FGCOLOR];
    } else {
        color = [NSColor blackColor];
    }

    if ([item isKindOfClass:[SGTabViewItem class]]) {
        NSColor *c = [item titleColor];
        if (c)
            color = c;
        [cell setHasClose:!hideClose];
    } else {
        [cell setHasClose:NO];
    }

    [cell setTextColor:color];
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification
{
    id item = [_tabOutlineView itemAtRow:[_tabOutlineView selectedRow]];
    if (item && [item isKindOfClass:[SGTabViewItem class]])
        [self selectTabViewItem:item];
}

#pragma mark - NSSplitView

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    if (self->tabViewType == SGOutlineTabs) {
        prefs.xa_outline_width = _tabOutlineView.frame.size.width;
    }
}

@end
