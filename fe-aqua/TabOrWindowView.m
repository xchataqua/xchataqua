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

//
// TBD:  Too much repeated code in here!!!!!
//

///////////////////////////////////////////////////////////////////////

#import "SG.h"
#import "TabOrWindowView.h"
#import "AquaChat.h"

#include "../common/xchat.h"
#include "../common/xchatc.h"

//////////////////////////////////////////////////////////////////////

@class TabOrWindowViewTabDelegate;

static NSWindow  *tabWindow;		// Window for the tab view
//static NSImage *link_delink_image;
static TabOrWindowViewTabDelegate *tabDelegate;
static NSTabViewType tabViewType = NSTopTabsBezelBorder;
static float trans = 1;

//////////////////////////////////////////////////////////////////////

static NSWindow *makeWindowForView (Class nswindow, NSView *view, NSPoint *where)
{
	NSRect viewFrame = view.frame;
	
	NSUInteger windowAttributes = NSTitledWindowMask | 
	NSClosableWindowMask | 
	NSMiniaturizableWindowMask | 
	NSResizableWindowMask;
	
	if (prefs.guimetal)
		windowAttributes |= NSTexturedBackgroundWindowMask;
	
	NSWindow *window = [[nswindow alloc] initWithContentRect:viewFrame
												   styleMask:windowAttributes
													 backing:NSBackingStoreBuffered
													   defer:NO];
 	
	if (where)
	{
		[window setFrameOrigin:*where];
	}
	else
	{
		// Center the window over the preferred window size
		NSPoint windowOrigin;
		windowOrigin.x = prefs.mainwindow_left + (prefs.mainwindow_width - viewFrame.size.width) / 2;
		windowOrigin.y = prefs.mainwindow_top + (prefs.mainwindow_height - viewFrame.size.height)/ 2;
		[window setFrameOrigin:windowOrigin];
	}
	
	[window setAlphaValue:trans];
	[window setReleasedWhenClosed:NO];
	[window setShowsResizeIndicator:NO];
	
	static BOOL firstTime = YES;
	if (firstTime)
	{
		NSRect to = window.frame;
		NSRect from = to;
		from.origin.y += from.size.height - 1;
		from.size.height = 1;
		[window setFrame:from display:NO];
		[window makeKeyAndOrderFront:window];
		[window setFrame:to display:YES animate:YES];
		firstTime = NO;
	}
	
	[window setContentView:view];
	
	return window;
}

//////////////////////////////////////////////////////////////////////

@interface TabOrWindowViewTabDelegate : NSObject<SGTabViewDelegate
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
,NSWindowDelegate
#endif
>
@end

@implementation TabOrWindowViewTabDelegate

- (void) windowDidResize:(NSNotification *) notification
{
	for ( SGTabViewItem *item in [(SGTabView *)tabWindow.contentView tabViewItems] ) {
		id delegate = ((TabOrWindowView *)item.view).delegate;
		if ([delegate respondsToSelector:@selector (windowDidResize:)])
			[delegate windowDidResize:notification];
	}
}

- (void) windowDidMove:(NSNotification *) notification
{
	for ( SGTabViewItem *item in [(SGTabView *)tabWindow.contentView tabViewItems] ) {
		id delegate = ((TabOrWindowView *)item.view).delegate;
		if ([delegate respondsToSelector:@selector (windowDidMove:)])
			[delegate windowDidMove:notification];
	}
}

- (void) appleW
{
	SGTabViewItem *item = [(SGTabView *)[tabWindow contentView] selectedTabViewItem];
	[self tabWantsToClose:item];
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
	TabOrWindowView *the_view = (TabOrWindowView *)[[(SGTabView *)[tabWindow contentView] selectedTabViewItem] view];
	[[the_view delegate] windowDidBecomeKey:notification];
}

// NOTE: This func closes the tab
- (void) tabWantsToClose:(SGTabViewItem *) item
{
	TabOrWindowView *me = (TabOrWindowView *)[item view];
	[me close];
}

- (void) link_delink:(SGTabViewItem *) item
{
	TabOrWindowView *me = (TabOrWindowView *)[item view];
	[me link_delink:item];
}

- (void) windowWillClose:(NSNotification *) notification
{
	while ([[tabWindow contentView] numberOfTabViewItems])
	{
		SGTabViewItem *item = [(SGTabView *)[tabWindow contentView] tabViewItemAtIndex:0];
		[self tabWantsToClose:item];
	}
}

- (void) tabView:(SGTabView *)tabView didSelectTabViewItem:(SGTabViewItem *)tabViewItem
{
	NSString *title = [(TabOrWindowView *)[tabViewItem view] title];
	if (title)
		[tabWindow setTitle:title];
	
	current_tab = NULL;		// Set this to NULL.. the next line of code will
	// do the right thing IF it's a chat window!!
	
	// Someone selected a new tab view.  Phony up a 'windowDidBecomeKey'
	// notification.  Let's hope they don't need the NSNotification object.
	
	[[(TabOrWindowView *)[tabViewItem view] delegate] windowDidBecomeKey:nil];
}

- (void) tabViewDidResizeOutlne:(int) width
{
	prefs.outline_width = width;
}

@end

//////////////////////////////////////////////////////////////////////

@interface MyTabWindow : NSWindow

@end

@implementation MyTabWindow

- (void) performClose:(id) sender
{
	if ([sender isKindOfClass:[NSMenuItem class]])	// Apple-W?
		[[self delegate] appleW];
	else
		[super performClose:sender];				// Window close button
}

@end

//////////////////////////////////////////////////////////////////////

@implementation TabOrWindowView
@synthesize delegate;
@synthesize title, tabTitle;

- (void) makeViewWindow:(NSPoint *) where
{
	if (window)
	{
		[window orderOut:self];
		[window autorelease];
	}
	
	window = makeWindowForView ([NSWindow class], self, where);
	[window setDelegate:self];
	if (initialFirstResponder)
		[window setInitialFirstResponder:initialFirstResponder];
	if (title)
		[window setTitle:title];
}

+ (void) makeTabWindow:(NSView *) tabView where:(NSPoint *) where
{
	if (tabWindow)
	{
		[tabWindow orderOut:self];
		[tabWindow autorelease];
	}
	
	tabWindow = makeWindowForView ([MyTabWindow class], tabView, where);
	[tabWindow setDelegate:tabDelegate];
	[tabWindow makeKeyAndOrderFront:self];
}

+ (void) preferencesChanged
{	
	switch ( prefs._tabs_position ) {
		case 0: tabViewType = NSBottomTabsBezelBorder; break;
		case 1: tabViewType = NSTopTabsBezelBorder; break;
		case 2: tabViewType = NSRightTabsBezelBorder; break;
		case 3: tabViewType = NSLeftTabsBezelBorder; break;
		case 4: tabViewType = SGOutlineTabs; break;
		default:tabViewType = NSTopTabsBezelBorder; break;
	}
	
	if (tabWindow)
	{
		[[tabWindow contentView] setTabViewType:tabViewType];
		[[tabWindow contentView] setHideCloseButtons:prefs.hide_tab_close_buttons];
		[[tabWindow contentView] setOutlineWidth:prefs.outline_width];
	}
	
	for ( NSWindow *win in [NSApp windows] )
	{
		NSPoint where = win.frame.origin;
		bool windowWasMetal = win.styleMask & NSTexturedBackgroundWindowMask;
		
		if ([[win.contentView class] isSubclassOfClass:[TabOrWindowView class]])
		{
			TabOrWindowView *view = (TabOrWindowView *)win.contentView;
			if (view->window)
			{
				if (prefs.guimetal == windowWasMetal)
					return;
				[view makeViewWindow:&where];
				[view->window makeKeyAndOrderFront:self];
			}
		}
		else if (win == tabWindow)
		{
			if (prefs.guimetal == windowWasMetal)
				return;
			[TabOrWindowView makeTabWindow:win.contentView where:&where];
		}
	}
}

+ (void) setTransparency:(NSInteger)transparency
{
	trans = (float) transparency / 255;
	
	for ( NSWindow *win in [NSApp windows] )
	{
		if (win == tabWindow || [[win contentView] isKindOfClass:[TabOrWindowView class]])
			[win setAlphaValue:trans];
	}
}

- (id) initWithFrame:(NSRect) frameRect
{
	[super initWithFrame:frameRect];
	
	self->window = nil;
	self->tabViewItem = nil;
	self->delegate = nil;
	self->initialFirstResponder = nil;
	self->server = nil;
	
#if 0
	if (!link_delink_image)
		link_delink_image = [[NSImage imageNamed:@"link.tiff"] retain];
	
	NSButton *b = [[[NSButton alloc] init] autorelease];
	[b setButtonType:NSMomentaryPushButton];
	[b setTitle:@""];
	[b setBezelStyle:NSShadowlessSquareBezelStyle];
	[b setImage:link_delink_image];
	[b sizeToFit];
	if (![self isFlipped])
		[b setFrameOrigin:NSMakePoint (2, [self bounds].size.height - [b bounds].size.height - 2)];
	[b setAutoresizingMask:NSViewMaxXMargin | NSViewMinYMargin];
	[b setAction:@selector (link_delink:)];
	[b setTarget:self];
	
	[self addSubview:b];
#endif
	
	return self;
}

- (void) dealloc
{
	[super dealloc];
}

+ (BOOL) selectTabByIndex:(NSUInteger)index
{
	if (!tabWindow)
		return FALSE;
	
	NSTabViewItem *item = [[tabWindow contentView] tabViewItemAtIndex:index];
	
	if (!item)
		return FALSE;
	
	[[tabWindow contentView] selectTabViewItem:item];
	
	return TRUE;
}

+ (void) cycleWindow:(int) direction
{
	NSWindow *win = [NSApp keyWindow];
	
	if (win == tabWindow)
	{
		NSTabView *tabView = [tabWindow contentView];
		NSInteger tabItemIndex = [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
		if (direction > 0)
		{
			if (tabItemIndex < [tabView numberOfTabViewItems] - 1)
			{
				[tabView selectNextTabViewItem:self];
				return;
			}
		}
		else
		{
			if (tabItemIndex > 0)
			{
				[tabView selectPreviousTabViewItem:self];
				return;
			}
		}
	}
	
	NSArray *windows = [NSApp windows];
	NSUInteger windowIndex = [windows indexOfObject:win];
	
	NSUInteger try_count = [windows count];
	do
	{
		windowIndex = (windowIndex + direction + [windows count]) % [windows count];
		win = [windows objectAtIndex:windowIndex];
		// all windows minimized
		if(try_count-- == 0)
			return;
	}
	while (![win isVisible]);
	
	[win makeKeyAndOrderFront:self];
	
	if (win == tabWindow)
	{
		NSTabView *tabView = [tabWindow contentView];
		[tabView selectTabViewItemAtIndex:(direction>0) ? 0 : [tabView numberOfTabViewItems]-1];
	}
}

+ (void) link_delink
{
	NSWindow *win = [NSApp keyWindow];
	
	if (win == tabWindow)
	{
		SGTabViewItem *item = [(SGTabView *)[tabWindow contentView] selectedTabViewItem];
		TabOrWindowView *view = (TabOrWindowView *)[item view];
		[view link_delink:self];
	}
	else
	{
		NSView *view = [win contentView];
		if ([view isKindOfClass:[TabOrWindowView class]])
		{
			[(TabOrWindowView *)view link_delink:self];
		}
	}
}

+ (void) updateGroupNameForServer:(struct server *) server
{
	if (tabWindow)
	{
		SGTabView *tabView = [tabWindow contentView];
		NSString *groupName = [NSString stringWithUTF8String:server->servername];
		[tabView setName:groupName forGroup:server->gui->tab_group];
	}
}

- (void) setServer:(struct server *)aServer
{
	self->server = aServer;
}

- (void) link_delink:(id) sender
{
	if (tabViewItem)
		[self becomeWindowAndShow:true];
	else
		[self becomeTabAndShow:YES];
}

- (void) setTitle:(NSString *) aTitle
{
	[self->title release];
	self->title = [aTitle retain];
	
	if (window)
		[window setTitle:title];
	if (tabWindow && [(SGTabView *)[tabWindow contentView] selectedTabViewItem] == tabViewItem)
		[tabWindow setTitle:title];
}

- (void) setTabTitle:(NSString *) aTitle
{
	[self->tabTitle release];
	self->tabTitle = [aTitle retain];
	
	if (tabViewItem)
		[tabViewItem setLabel:tabTitle];
}

- (void) setTabTitleColor:(NSColor *) color
{
	if (tabViewItem)
		[tabViewItem setTitleColor:color];
}

- (BOOL)isFrontTab
{
	if (!tabViewItem) return NO;
	else return [tabViewItem isFrontTab];
}

- (void) setInitialFirstResponder:(NSView *) responder
{
	self->initialFirstResponder = responder;
	
	if (tabViewItem)
		[tabViewItem setInitialFirstResponder:responder];
	if (window)
		[window setInitialFirstResponder:responder];
}

- (void) becomeTab:(BOOL) tab andShow:(BOOL) show
{
	if (tab)
		[self becomeTabAndShow:show];
	else
		[self becomeWindowAndShow:show];
}

- (void) becomeWindowAndShow:(BOOL) show
{
	if (tabViewItem)
	{
		[(SGTabView *)[tabWindow contentView] removeTabViewItem:tabViewItem];
		
		tabViewItem = nil;
		
		if ([[[tabWindow contentView] tabViewItems] count] == 0)
		{
			[tabWindow orderOut:self];
			[tabWindow autorelease];
			tabWindow = nil;
		}
	}
	
	if (!window)
	{
		[self makeViewWindow:nil];
	}
	
	if (show)
		[self makeKeyAndOrderFront:self];
}

- (void) makeKeyAndOrderFront:(id) sender
{
	if (window)
	{
		[window makeKeyAndOrderFront:sender];
	}
	else if (tabWindow)
	{
		[(SGTabView *)[tabWindow contentView] selectTabViewItem:tabViewItem];
		
		// Don't order the tab window front.. just the tab itself.
		//[tabWindow makeKeyAndOrderFront:sender];
	}
}

- (void) becomeTabAndShow:(BOOL) show
{
	if (window)
	{
		[window orderOut:self];
		[window autorelease];
		window = nil;
	}
	
	if (!tabWindow)
	{
		[self setFrameSize:NSMakeSize (prefs.mainwindow_width, prefs.mainwindow_height)];
		
		if (!tabDelegate)
			tabDelegate = [[TabOrWindowViewTabDelegate alloc] init];
		
		NSRect frame = [self bounds];
		SGTabView *tabView = [[[SGTabView alloc] initWithFrame:frame] autorelease];
		[tabView setDelegate:tabDelegate];
		[tabView setTabViewType:tabViewType];
		[tabView setHideCloseButtons:prefs.hide_tab_close_buttons];
		[tabView setOutlineWidth:prefs.outline_width];
		
		[TabOrWindowView makeTabWindow:tabView where:nil];
	}
	
	if (!tabViewItem)
	{
		tabViewItem = [[[SGTabViewItem alloc] initWithIdentifier:nil] autorelease];
		[tabViewItem setView:self];
		if (initialFirstResponder)
			[tabViewItem setInitialFirstResponder:initialFirstResponder];
		if (tabTitle)
			[tabViewItem setLabel:tabTitle];
		
		SGTabView *tabView = (SGTabView *)[tabWindow contentView];
		
		int tabGroup = self->server ? self->server->gui->tab_group : 0;
		
		[tabView addTabViewItem:tabViewItem toGroup:tabGroup];
		
		if ([tabView groupName:tabGroup] == nil)
		{
			NSString *groupName;
			
			if (self->server)
			{
				if (self->server->servername[0])		// Can this ever happen?
					groupName = [NSString stringWithUTF8String:self->server->servername];
				else
					groupName = NSLocalizedStringFromTable(@"<Not Connected>", @"xchataqua", @"tab group label when not connected yet");
			}
			else
				groupName = NSLocalizedStringFromTable(@"Utility Views", @"xchataqua", @"tab group label for utility windows");
			
			[tabView setName:groupName forGroup:tabGroup];
		}
	}
	
	if (show)
		[self makeKeyAndOrderFront:self];
}

- (void) close
{
	if (window)
	{
		[window close];		// windowWillClose notification will follow
	}
	else if (tabViewItem)
	{
		[self retain];
		[(SGTabView *)[tabWindow contentView] removeTabViewItem:tabViewItem];
		tabViewItem = nil;
		if ([[[tabWindow contentView] tabViewItems] count] == 0)
		{
			[tabWindow orderOut:self];		// TODO - Should this be [tabWindow close]?
			[tabWindow autorelease];		// Must be autorelase because of 
			tabWindow = nil;				// windowWillClose below...
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
		if ([delegate respondsToSelector:@selector (windowWillClose:)])
			[delegate windowWillClose:nil];
		[self release];
	}
}

- (void) windowDidResize:(NSNotification *) notification
{
	if ([delegate respondsToSelector:@selector (windowDidResize:)])
		[delegate windowDidResize:notification];
}

- (void) windowDidMove:(NSNotification *) notification
{
	if ([delegate respondsToSelector:@selector (windowDidMove:)])
		[delegate windowDidMove:notification];
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
	[delegate windowDidBecomeKey:notification];
}

// We are in window mode, and the window is closing.
- (void) windowWillClose:(NSNotification *) notification
{
	// Before giving the delegate the bad news, we need to take ourselvs out of the
	// window so the delegate can release us.
	
	[self retain];
	[window setContentView:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
	if ([delegate respondsToSelector:@selector (windowWillClose:)])
		[delegate windowWillClose:notification];
	[window autorelease];
	window = nil;
	[self release];
}

@end
