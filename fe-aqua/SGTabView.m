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
#include <Carbon/Carbon.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import "SG.h"
#import "SGTabView.h"

//////////////////////////////////////////////////////////////////////

static NSMutableDictionary *label_dict;
static NSNib *tab_menu_nib;
static NSCursor *lr_cursor;
static NSImage *dimple;

//////////////////////////////////////////////////////////////////////

typedef OSStatus 
	(*ThemeDrawSegmentProc)(
	  const HIRect *                  inBounds,
	  const HIThemeSegmentDrawInfo *  inDrawInfo,
	  CGContextRef                    inContext,
	  HIThemeOrientation              inOrientation);

static ThemeDrawSegmentProc MyThemeDrawSegment;

static int MySegmentHilightFlag;
static int MySegmentFGSelectedFlag;
static int MySegmentNormalFlag;
static int MySegmentBGSelectedFlag;

static int MySegmentHeight;

//////////////////////////////////////////////////////////////////////

static NSImage *getCloseImage()
{
	static NSImage *close_image;
	if (!close_image)
	    close_image = [NSImage imageNamed:@"close.tiff"];
	return close_image;
}

static NSNib *getTabMenuNib ()
{
	if (!tab_menu_nib)
		tab_menu_nib = [[NSNib alloc] initWithNibNamed:@"TabMenu" bundle:nil];
	return tab_menu_nib;
}

static NSButtonCell *makeCloseCell ()
{
    NSButtonCell *closeCell = [[NSButtonCell alloc] initImageCell:getCloseImage()];
    [closeCell setButtonType:NSMomentaryLightButton];
    [closeCell setImagePosition:NSImageOnly];
    [closeCell setBordered:false];
    [closeCell setHighlightsBy:NSContentsCellMask];
	return closeCell;
}

//////////////////////////////////////////////////////////////////////

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
	self = [super initTextCell:aString];
	closeCell = makeCloseCell();
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

- (void) doClose:(id) sender
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
	NSRect closeRect;

	if (hasClose)
	{
		closeRect = [self calculateCloseRectWithFrame:cellFrame inView:controlView];
		cellFrame.origin.x += closeRect.size.width + 5;
	}

	[super drawInteriorWithFrame:cellFrame inView:controlView];

	// Gotta draw the icon last because highlighted cells have a
	// blue background which will cover the image otherwise.                  
	if (hasClose)
		[closeCell drawInteriorWithFrame:closeRect inView:controlView];
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
		[SGGuiUtil trackButtonCell:closeCell withEvent:theEvent inRect:closeRect controlView:controlView];
		return YES;
	}
	
	return NO;
}

@end

//////////////////////////////////////////////////////////////////////

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
	int row = [self rowAtPoint:where];
	int col = [self columnAtPoint:where];
	
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

//////////////////////////////////////////////////////////////////////

@interface SGTabViewGroupInfo : NSObject
{
	@public
		int			group;
		NSString	*name;
		NSMutableArray *tabs;
}
@end

@implementation SGTabViewGroupInfo

- (id) init
{
	self = [super init];
			
	group = 0;
	name = nil;
	tabs = [[NSMutableArray arrayWithCapacity:0] retain];

	return self;
}

- (void) dealloc
{
	[name release];
	[tabs release];
	[super dealloc];
}

- (int) numTabs
{
	return [tabs count];
}

- (NSString *) name
{
	return name;
}

- (SGTabViewItem *) tabAtIndex:(int) index
{
	return [tabs objectAtIndex:index];
}

- (void) setName:(NSString *) new_name
{
	[name release];
	name = [new_name retain];
}

- (void) addTab:(SGTabViewItem *) item
{
	[tabs addObject:item];
}

- (void) removeTabViewItem:(SGTabViewItem *) item
{
	[tabs removeObject:item];
}

@end

//////////////////////////////////////////////////////////////////////

HIThemeSegmentPosition positionTable[2][2] = 
{
	//							No right cap					right cap
	/* No left cap */	{ kHIThemeSegmentPositionMiddle, kHIThemeSegmentPositionLast },
	/* Left cap	   */   { kHIThemeSegmentPositionFirst,  kHIThemeSegmentPositionOnly },
};

@interface SGTabViewButtonCell : NSButtonCell
{
    NSColor *color;
    bool     hideClose;
    bool     left_cap;
    bool     right_cap;
    NSRect   close_rect;
    NSPoint  textPoint;
    NSButtonCell *closeCell;
	NSSize	size;
	HIThemeSegmentDrawInfo drawInfo;
}
@end

@implementation SGTabViewButtonCell

+ (void) initialize
{
    label_dict = [[NSMutableDictionary
                dictionaryWithObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
                forKey:NSFontAttributeName] retain];

	// Setup stuff for drawing the segments.
	//
	// NOTE to Camillo.. if you're still alive and wondering why I didn't use your patch,
	// let me tell you (and anyone else that wonders WTF is going on here).
	//
	// I like the idea of drawing segments rather than tabs (even thought they look the same)
	// for a few reasons.
	//	1.  The same code works on 10.3 and 10.4.
	//	2.  It's much simpler in implementation.
	//	3.  If 10.5 changes tabs in any drastic way, we'd be broken.  In other words, my
	//      tab view is pretty much dependant on the way tabs work on 10.4.  i.e. with segments.
	//
	// Now I know what you're thinking.. we're using private APIs and that's bogus!  You're right
	// but the odds of Apple changing 10.3 or even 10.4 at this time isn't very likely.  If they
	// do change things, then we're screwed but hopefully they also fix the bugs for 10.4 at the
	// same time.  I thought about this problem for quite some time and I feel this is the lesser
	// of the evils.  Please feel free to awake from the dead and tell me what you think.
		
	SInt32 version = 0;
	Gestalt(gestaltSystemVersion, &version);
	
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
}

- (id) initTextCell:(NSString *) aString
{
    self = [super initTextCell:aString];
    closeCell = makeCloseCell();
    self->hideClose = false;
    return self;
}

- (void) dealloc
{
    [color release];
    [closeCell release];
    [super dealloc];
}

// Undocumented method used to update the cell when the window is activated/deactivated
- (BOOL) _needRedrawOnWindowChangedKeyState
{
	return YES;
}

- (void) setHideCloseButton:(bool) hideit
{
    self->hideClose = hideit;
    [self calcDrawInfo:NSMakeRect(0, 0, 1, 1)];
}

- (void) setHasLeftCap:(BOOL) b
{
    if (left_cap != b)
    {
        left_cap = b;
        [self calcDrawInfo:NSMakeRect(0, 0, 1, 1)];
    }
}

- (void) setHasRightCap:(BOOL) b
{
    if (right_cap != b)
    {
        right_cap = b;
        [self calcDrawInfo:NSMakeRect(0, 0, 1, 1)];
    }
}

- (void) setCloseAction:(SEL) act
{
    [closeCell setAction:act];
}

- (void) setCloseTarget:(id) targ
{
    [closeCell setTarget:targ];
}

- (void) doClose:(id) sender
{
	[[closeCell target] performSelector:[closeCell action]];
}

- (NSSize) cellSize
{
    return size;
}

- (void) setTitleColor:(NSColor *) c
{
    [color release];
    color = [c retain];
}

- (void) calcDrawInfo:(NSRect) aRect
{
	// [super init] calls us before we are ready
	if (!closeCell)
		return;

	size.height = MySegmentHeight;
	
    NSSize sz = [[self title] sizeWithAttributes:label_dict];

    if (hideClose)
    {
        close_rect = NSMakeRect(0,0,1,1);
        textPoint.x = 7 + 2;
        textPoint.y = floor (size.height - sz.height) / 2;
    }
    else
    {
		NSSize close_size = [closeCell cellSize];

        close_rect.size = close_size;
        close_rect.origin.x = 7;
        close_rect.origin.y = floor (size.height - close_rect.size.height) / 2;

        textPoint.x = close_rect.origin.x + close_size.width + 3;
        textPoint.y = floor (size.height - sz.height) / 2;
    }

    size.width = floor (sz.width + textPoint.x + 7 + 2);
	
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
    [self calcDrawInfo:NSMakeRect(0, 0, 1, 1)];
}

- (void) drawCellBodyWithFrame:(NSRect) cellFrame
                inView:(NSView *) controlView
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

- (void) drawWithFrame:(NSRect) cellFrame
                inView:(NSView *) controlView
{
	[self drawCellBodyWithFrame:cellFrame inView:controlView];
	
    if (!hideClose)
        [closeCell drawWithFrame:close_rect inView:controlView];
    
    [label_dict setObject:color ? color : [NSColor blackColor]
		 forKey:NSForegroundColorAttributeName];

    [[self title] drawAtPoint:textPoint withAttributes:label_dict];
}

- (void) mouseDown:(NSEvent *) e
       controlView:(NSView *) controlView
{
    NSButtonCell *track_cell;
    NSRect track_rect;
    
    NSPoint p = [controlView convertPoint:[e locationInWindow] fromView:nil];
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

	[SGGuiUtil trackButtonCell:track_cell withEvent:e inRect:track_rect controlView:controlView];
}

@end

//////////////////////////////////////////////////////////////////////

@interface SGTabViewButton : NSButton
{
}

- (void) setCloseAction:(SEL) act;
- (void) setCloseTarget:(id) targ;
- (void) setHideCloseButton:(bool) hideit;

@end

@implementation SGTabViewButton

- (id) init
{
    [super init];
    
    [self setCell:[[[SGTabViewButtonCell alloc] initTextCell:@""] autorelease]];
    [self setButtonType:NSOnOffButton];
    [[self cell] setControlSize:NSSmallControlSize];
    [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [self setImagePosition:NSNoImage];
    [self setBezelStyle:NSShadowlessSquareBezelStyle];
    [super setTitle:@""];

    [self sizeToFit];

    return self;
}

- (void) setHideCloseButton:(bool) hideit
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

//////////////////////////////////////////////////////////////////////

@implementation SGTabViewItem
@synthesize titleColor;

- (id) initWithIdentifier:(id) identifier
{
	parent = nil;
	view = nil;
	button = nil;
	label = nil;

	if (!lr_cursor)
		lr_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lr_cursor.tiff"]
                                hotSpot:NSMakePoint (8,8)];
	if (!dimple)
		dimple = [NSImage imageNamed:@"dimple.tiff"];
	
	[getTabMenuNib() instantiateNibWithOwner:self topLevelObjects:nil];

	return self;
}

- (void) dealloc
{
	[label release];
    [button release];
    [titleColor release];
    [view release];
	[ctxMenu release];
    [super dealloc];
}

- (void) makeButton:(SGWrapView *) box
			  where:(int) where
		  withClose:(BOOL) with_close
{
    button = [[SGTabViewButton alloc] init];
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

- (void) noButton
{
	if (button)
	{
		[button removeFromSuperview];
		[button release];
		button = nil;
	}
}

- (id) view
{
    return view;
}

- (SGTabView *) tabView
{
	return parent;
}

- (BOOL)isFrontTab
{
	return ([parent selectedTabViewItem] == self ? YES : NO);
}

- (void) setHideCloseButton:(bool) hidem
{
	[button setHideCloseButton:hidem];
}

- (void) setTitleColor:(NSColor *) color
{
	[titleColor release];
	titleColor = [color retain];
	if (button)
	    [button setTitleColor:color];
	if (parent && parent->outline)
		[parent->outline reloadData];
}

- (void) doClose:(id) sender
{
	// TODO
	// This method shoud probably close the tab
	// and behave much like clicking the red close
	// button on a window.
    if (parent)
        [[parent delegate] tabWantsToClose:self];
}

- (void) link_delink:(id) sender
{
    if (parent)
        [[parent delegate] link_delink:self];
}

- (void) doit:(id) sender
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
	else if (parent && parent->outline)
	{
		[parent->outline reloadData];
	}
}

- (NSString *) label
{
	return label;
}

- (void) setSelected:(BOOL) selected
{
	if (button)
		[button setIntValue:selected ? 1 : 0];
}

- (void) setView:(NSView *) new_view
{
    if (view)
    {
		[view removeFromSuperview];
		[view release];
    }

    view = [new_view retain];

    if (parent)
    {
		// 27-aug-04
		//[parent addSubview:view];
		//if (self == parent->selected_tab)
		//	[parent setStretchView:view];
		//else
		//	[view setHidden:true];
		if (self == parent->selected_tab) // 27-aug-04
		{
			[parent addSubview:view];     // 27-aug-04
			[parent setStretchView:view]; // 27-aug-04
		}
    }
}

- (id) initialFirstResponder
{
    return initial_first_responder;
}

- (void) setInitialFirstResponder:(NSView *) the_view
{
    initial_first_responder = the_view;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGTabView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];

    self->selected_tab = nil;
    self->tabs = [[NSMutableArray arrayWithCapacity:0] retain];
    self->delegate = nil;
    self->tabViewType = NSTopTabsBezelBorder;
    self->hideClose = false;
	self->hbox = nil;
	self->outline = nil;
	self->outline_width = 150;
	self->groups = [[NSMutableArray arrayWithCapacity:5] retain];
	
    [self setOrientation:SGBoxOrientationVertical];
    [self setMinorDefaultJustification:SGBoxMinorJustificationFull];
    [self setMajorInnerMargin:0];
    [self setMajorOutterMargin:0];
    [self setMinorMargin:0];
    
	[self setTabViewType:NSTopTabsBezelBorder];
	
    return self;
}

- (void) dealloc
{
    //[hbox release];	We don't explicitly retain this.
    //[outline release];	We don't explicitly retain this.
    [tabs release];
	[groups release];
    [super dealloc];
}

- (void) setOutlineWidth:(int) width
{
	self->outline_width = width;
	if (outline)
	{
		if (width < 50)			// Just because
			width = 50;
		else if (width > 300)	// Just because
			width = 300;
		NSScrollView *outlineScroll = [outline enclosingScrollView];
		NSRect outline_frame = [outlineScroll frame];
		NSSize new_size = NSMakeSize(width, outline_frame.size.height);
		[outlineScroll setFrameSize:new_size];
	}
}

- (SGTabViewGroupInfo *) getGroupInfo:(int) group
{
	SGTabViewGroupInfo *info = nil;
	for (unsigned i = 0; i < [groups count]; i ++)
	{
		SGTabViewGroupInfo *this_info = [groups objectAtIndex:i];
		if (this_info->group == group)
		{
			info = this_info;
			break;
		}
	}
	
	if (!info)
	{
		info = [[SGTabViewGroupInfo alloc] init];
		info->group = group;
		[groups addObject:info];
		[outline reloadData];
		[outline expandItem:info];
		[info release];
	}
	
	return info;
}

- (void) setName:(NSString *) name
	    forGroup:(int) group
{
	[[self getGroupInfo:group] setName:name];
	[outline reloadData];
}

- (NSString *) groupName:(int) group
{
	return [[self getGroupInfo:group] name];
}

- (void) setHideCloseButtons:(bool) hidem
{
    self->hideClose = hidem;
    
    for (unsigned int i = 0; i < [tabs count]; i ++)
    {
        SGTabViewItem *tab = [tabs objectAtIndex:i];
		[tab setHideCloseButton:hideClose];
    }
}

- (NSArray *) tabViewItems
{
    return tabs;
}

- (id) delegate
{
    return delegate;
}

- (void) setDelegate:(id) anObject
{
    delegate = anObject;
}

- (void) setCaps
{
	if (!hbox)
		return;
		
    SGTabViewItem *last_tab = nil;
    for (unsigned i = 0; i < [tabs count]; i ++)
    {
        SGTabViewItem *this_tab = [tabs objectAtIndex:i];
    
        [this_tab->button setHasLeftCap:!last_tab || (this_tab->group != last_tab->group)];
        if (last_tab)
            [last_tab->button setHasRightCap:this_tab->group != last_tab->group];
        last_tab = this_tab;
    }
    if (last_tab)
        [last_tab->button setHasRightCap:true];
}

- (void) makeTabs
{
	if (outline)
	{
		[[outline enclosingScrollView] removeFromSuperview];
		outline = nil;
	}
	
	if (!hbox)
	{
		hbox = [[[SGWrapView alloc] initWithFrame:NSMakeRect (0,0,1,1)] autorelease];
		[self addSubview:hbox];
		
		[self setOrder:0 forView:hbox];

		for (unsigned i = 0; i < [tabs count]; i ++)
		{
			SGTabViewItem *this_tab = [tabs objectAtIndex:i];
			[this_tab makeButton:hbox where:i withClose:!hideClose];
		}
		
		[self setCaps];
		
		[selected_tab setSelected:true];
	}
}

- (void) makeOutline
{
	if (hbox)
	{
	    for (unsigned i = 0; i < [tabs count]; i ++)
		{
			SGTabViewItem *this_tab = [tabs objectAtIndex:i];
			[this_tab noButton];
		}

		[hbox removeFromSuperview];
		hbox = nil;
	}
	
	if (!outline)
	{
		NSScrollView *outlineScroll = [[[NSScrollView alloc] initWithFrame:NSMakeRect (0,0,outline_width,1)] autorelease];
		[self addSubview:outlineScroll];
		
		[self setOrder:0 forView:outlineScroll];
		
		NSFont *font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
		NSLayoutManager * layout_manager=[[NSLayoutManager new] autorelease];
		
		SGTabViewOutlineCell *data_cell = [[SGTabViewOutlineCell alloc] initTextCell:@""];
		
		NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@""];
		[col setWidth:outline_width];
		[col setDataCell:data_cell];
		[data_cell setFont:font];
		[[col headerCell] setStringValue:@"Tabs"];
		
		[data_cell release];
		
		outline = [[[SGTabViewOutlineView alloc] initWithFrame:NSMakeRect (0,0,1,1)] autorelease];
		[outline setIndentationPerLevel:10];
		//[outline setIndentationMarkerFollowsCell:NO];
		[outline addTableColumn:col];
		[outline setOutlineTableColumn:col];
		[outlineScroll setDocumentView:outline];
		[outline setFrame:[outlineScroll documentVisibleRect]];
		[outline setAutoresizingMask:NSViewWidthSizable];
		[outline setRowHeight:[layout_manager defaultLineHeightForFont:font] + 1];
		[outline setAllowsEmptySelection:NO];

		[outline setDelegate:self];
		[outline setDataSource:self];
		[outline reloadData];
		
		for (unsigned i = 0; i < [groups count]; i ++)
			[outline expandItem:[groups objectAtIndex:i]];

		NSInteger row = [outline rowForItem:selected_tab];
		[outline
     selectRowIndexes:[NSIndexSet indexSetWithIndex:row]
     byExtendingSelection:NO];
	}
}

- (void) setTabViewType:(NSTabViewType) new_tabViewType
{
    self->tabViewType = new_tabViewType;
    
    SGBoxOrientation newOrientation;
    SGBoxOrder newOrder;
    SGBoxOrder boxOrder;
	//short margin = 0;
	SGBoxMargin imargin = 0;
    float rotation;

    switch (tabViewType)
    {
		case SGOutlineTabs:
            newOrientation = SGBoxOrientationVertical;
            newOrder = SGBoxOrderFIFO;
            boxOrder = SGBoxOrderLIFO;
            rotation = 0;
			imargin = 10;
			break;
			
        case NSBottomTabsBezelBorder:
            newOrientation = SGBoxOrientationHorizontal;
            newOrder = SGBoxOrderFIFO;
            boxOrder = SGBoxOrderFIFO;
            rotation = 0;
            break;
            
        case NSRightTabsBezelBorder:
            newOrientation = SGBoxOrientationVertical;
            newOrder = SGBoxOrderLIFO;
            boxOrder = SGBoxOrderLIFO;
            rotation = 90;
            break;
            
        case NSLeftTabsBezelBorder:
            newOrientation = SGBoxOrientationVertical;
            newOrder = SGBoxOrderFIFO;
            boxOrder = SGBoxOrderLIFO;
            rotation = -90;
            break;

        case NSTopTabsBezelBorder:
        default:
            newOrientation = SGBoxOrientationHorizontal;
            newOrder = SGBoxOrderLIFO;
            boxOrder = SGBoxOrderFIFO;
            rotation = 0;
            break;
    }
    
    [self setOrientation:SGBoxOrientationVertical==newOrientation?SGBoxOrientationHorizontal:SGBoxOrientationVertical];
    [self setOrder:newOrder];
    [self setMajorInnerMargin:imargin];
	//[self setMinorMargin:margin];

	if (tabViewType == SGOutlineTabs)
		[self makeOutline];
	else
	{
		[self makeTabs];
		[hbox setBoundsRotation:rotation];
		[hbox queue_layout];
	}
}

- (SGTabViewItem *) tabViewItemAtIndex:(NSInteger) index
{
    return (NSUInteger) index < [tabs count] ? [tabs objectAtIndex:index] : nil;
}

- (NSInteger) numberOfTabViewItems
{
    return [tabs count];
}

- (NSInteger) indexOfTabViewItem:(SGTabViewItem *) tabViewItem
{
    return [tabs indexOfObject:tabViewItem];
}

- (void) addTabViewItem:(SGTabViewItem *) tabViewItem
{
    [self addTabViewItem:tabViewItem toGroup:0];
}

- (void) removeTabViewItem:(SGTabViewItem *) tabViewItem
{
    if ([tabViewItem tabView] != self)
    	return;
    
    [tabViewItem->view removeFromSuperview];
    [tabViewItem noButton];
    tabViewItem->parent = nil;

    if (selected_tab == tabViewItem)
    {
		selected_tab = nil;

		if ([tabs count] > 1)
		{
			// If there is another tab on the right of the tab being closed, and it's in the same group, choose it;
			// Else, if there is another tab on the left of the tab being closed, and it's in the same group, choose it;
			// Else, choose the tab on the right unless it's the last tab;
			// Else, choose the tab on the left.
			NSUInteger tab_num = [tabs indexOfObject:tabViewItem];
			NSUInteger last_tab = [tabs count] - 1;
			NSUInteger tab_to_select;
			if (tab_num < last_tab && ((SGTabViewItem *)[tabs objectAtIndex:tab_num + 1])->group == tabViewItem->group)
				tab_to_select = tab_num + 1;
			else if (tab_num > 0 && ((SGTabViewItem *)[tabs objectAtIndex:tab_num - 1])->group == tabViewItem->group)
				tab_to_select = tab_num - 1;
			else
				tab_to_select = tab_num == last_tab ? tab_num - 1 : tab_num + 1;
			[self selectTabViewItemAtIndex:tab_to_select];
		}
    }
    
    [tabs removeObject:tabViewItem];
	
	SGTabViewGroupInfo *info = [self getGroupInfo:tabViewItem->group];
	[info removeTabViewItem:tabViewItem];
	if ([info->tabs count] == 0)
		[groups removeObject:[self getGroupInfo:tabViewItem->group]];

	if (outline)
	{
		[outline reloadData];
		// Removing items above the current item muck up the selected item in the outline
		NSInteger row = [outline rowForItem:selected_tab];
		[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}

    [self setCaps];
}

- (SGTabViewItem *) selectedTabViewItem
{
    return selected_tab;
}

- (void) selectNextTabViewItem:(id) sender
{
    NSInteger n = [self indexOfTabViewItem:[self selectedTabViewItem]] +1;
    if (n < [self numberOfTabViewItems])
        [self selectTabViewItemAtIndex:n];
}

- (void) selectPreviousTabViewItem:(id) sender
{
    NSInteger n = [self indexOfTabViewItem:[self selectedTabViewItem]] - 1;
    if (n >= 0)
        [self selectTabViewItemAtIndex:n];
}

- (void) selectTabViewItemAtIndex:(NSInteger) index
{
    [self selectTabViewItem:[self tabViewItemAtIndex:index]];
}

- (void) selectTabViewItem:(SGTabViewItem *) tabViewItem
{
    if (selected_tab)
    {
		if (tabViewItem == selected_tab)
			return;
		[selected_tab->view removeFromSuperview];
		[selected_tab setSelected:false];
    }

    [self setStretchView:tabViewItem->view];
	[self addSubview:tabViewItem->view];

    selected_tab = tabViewItem;
	
    [selected_tab setSelected:true];
	
	if (outline)
	{
		NSInteger row = [outline rowForItem:tabViewItem];
		[outline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
	}
    
    if (selected_tab->view)
    {
        if ([selected_tab initialFirstResponder])
            [[self window] makeFirstResponder:[selected_tab initialFirstResponder]];
    }
        
    if ([delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
        [delegate performSelector:@selector(tabView:didSelectTabViewItem:)
                       withObject:self
                       withObject:selected_tab];

    // We need to force the newly added item to have the correct size since hidden
    // items are not layed out (or layed out wrong).
    [self layout_maybe];
}

- (BOOL) mouseDownCanMoveWindow
{
	return NO;
}

- (NSRect) dragAreaRect
{
	if (!outline || !selected_tab) return NSZeroRect;
		
	NSScrollView *outlineScroll = [outline enclosingScrollView];
	NSRect outline_frame = [outlineScroll frame];
	NSRect view_frame = [selected_tab->view frame];
	CGFloat margin = view_frame.origin.x - outline_frame.origin.x - outline_frame.size.width + 1;
	NSRect line_rect = NSMakeRect(outline_frame.origin.x + outline_frame.size.width,
		outline_frame.origin.y, margin, outline_frame.size.height);

	return line_rect;
}

- (void) resetCursorRects
{
	if (outline)
		[self addCursorRect:[self dragAreaRect] cursor:lr_cursor];
}

// SplitView-like functionality for outline view
- (void) mouseDown:(NSEvent *) theEvent
{
	if (!outline)
	{
		[super mouseDown:theEvent];
		return;
	}
	
    NSPoint point = [theEvent locationInWindow];
    NSPoint where = [self convertPoint:point fromView:nil];
	NSRect line_rect = [self dragAreaRect];
	
    if (!NSPointInRect (where, line_rect))
    {
        [super mouseDown:theEvent];
		return;
    }

	NSScrollView *outlineScroll = [outline enclosingScrollView];
	NSRect outline_frame = [outlineScroll frame];
    
    for (;;)
    {
        NSEvent *theEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask |
                                                                 NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		CGFloat width = mouseLoc.x - where.x + outline_frame.size.width;
		[self setOutlineWidth:width];

		[[self delegate] tabViewDidResizeOutlne:outline_width];
		
		[[self window] invalidateCursorRectsForView:self];
    }
}

- (void) drawBackground
{
	if (!hbox)
		return;
		
	NSRect r = [selected_tab->view frame];
    //NSRect br = [hbox frame];
	const float dy = 12;		// floor (br.size.height / [hbox rowCount] / 2)
	const float dx = 12;		// floor (br.size.width / [hbox rowCount] / 2)

    switch (tabViewType)
    {
        case NSBottomTabsBezelBorder:
            r.origin.y -= dy;
            r.size.height += dy;
            break;
            
        case NSRightTabsBezelBorder:
            r.size.width += dx;
            break;
            
        case NSLeftTabsBezelBorder:
            r.origin.x -= dx;
            r.size.width += dx;
            break;

        case NSTopTabsBezelBorder:
        default:
            r.size.height += dy;
            break;
    }

	HIRect paneRect;
	paneRect.origin.x = r.origin.x;
	paneRect.origin.y = r.origin.y;
	paneRect.size.width = r.size.width;
	paneRect.size.height = r.size.height;
	
#if 0
	// Doesn't look right on 10.3
	HIThemeTabPaneDrawInfo drawInfo;
	drawInfo.version = 1;
	drawInfo.state = [[self window] isMainWindow] ? kThemeStateActive : kThemeStateInactive;
	drawInfo.direction = kThemeTabNorth;
	drawInfo.size = kHIThemeTabSizeNormal;
	drawInfo.kind = kHIThemeTabKindNormal;
	drawInfo.adornment = kHIThemeTabPaneAdornmentNormal;
	
	OSStatus err = HIThemeDrawTabPane(&paneRect, &drawInfo, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
		[self isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted);
	if (err != noErr)
		[NSException raise:NSGenericException format:@"SGTabView: HIThemeDrawTabPane returned %d", err];
#else

	HIThemeGroupBoxDrawInfo drawInfo;
	drawInfo.version = 1;
	drawInfo.state = [[self window] isMainWindow] ? kThemeStateActive : kThemeStateInactive;
	drawInfo.kind = kHIThemeGroupBoxKindPrimary;
	
	HIThemeDrawGroupBox(&paneRect, &drawInfo, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
		[self isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted);
	
#endif
}

- (void) drawDivider
{
	NSRect line_rect = [self dragAreaRect];
	NSPoint point;
	point.x = line_rect.origin.x + ((line_rect.size.width  - [dimple size].width ) / 2);
	point.y = line_rect.origin.y + ((line_rect.size.height - [dimple size].height) / 2);
	[dimple compositeToPoint:point operation:NSCompositeSourceOver];
}

- (void) drawRect:(NSRect) aRect
{
    if (!selected_tab)
        return;

	if (outline)
		[self drawDivider];
	else
		[self drawBackground];
}

- (void) setupItem:(SGTabViewItem *) item where:(int) where
{
	if (hbox)
	{
		[item makeButton:hbox where:where withClose:!hideClose];
	}
}

- (void) addTabViewItem:(SGTabViewItem *) tabViewItem toGroup:(int) group
{
    if (tabViewItem->parent)
    	return;

    tabViewItem->parent = self;
    tabViewItem->group = group;

    // In order for selectNext and selectPrevious to work, we need to add this item
    // in the correct order.  We'll also insert the tab button at the same position.
    
    NSUInteger where = 0;
    for (; where < [tabs count]; where ++)
    {
        SGTabViewItem *this_tab = [tabs objectAtIndex:where];
        if (this_tab->group == group)
        {
            where ++;
            break;
        }
    }
    for (; where < [tabs count]; where ++)
    {
        SGTabViewItem *this_tab = [tabs objectAtIndex:where];
        if (this_tab->group != group)
            break;
    }

    [tabs insertObject:tabViewItem atIndex:where];
	
	SGTabViewGroupInfo *info = [self getGroupInfo:tabViewItem->group];
	[info addTab:tabViewItem];

	[self setupItem:tabViewItem where:where];
	
    [self setCaps];

	if (outline)
		[outline reloadData];

    if (!selected_tab)
    	[self selectTabViewItem:tabViewItem];
}

//////////////////////////////////////////////////////

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
	BOOL is = [item isKindOfClass:[SGTabViewGroupInfo class]];
	return is;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item == nil)
		return [groups count];
		
	if ([item isKindOfClass:[SGTabViewGroupInfo class]])
		return [item numTabs];
		
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
	NSColor *color = [NSColor blackColor];
	
	if ([item isKindOfClass:[SGTabViewItem class]])
	{
		NSColor *c = [item titleColor];
		if (c)
			color = c;
		[cell setHasClose:!hideClose];
	}
	else
		[cell setHasClose:NO];

	[cell setTextColor:color];
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification
{
	id item = [outline itemAtRow:[outline selectedRow]];
	if (item && [item isKindOfClass:[SGTabViewItem class]])
		[self selectTabViewItem:item];
}

@end
