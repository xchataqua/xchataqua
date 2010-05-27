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

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
}

//////////////////////////////////////////////////////////////////////

@class TabOrWindowViewTabDelegate;

static NSWindow  *tab_window;		// Window for the tab view
//static NSImage *link_delink_image;
static TabOrWindowViewTabDelegate *tab_delegate;
static NSTabViewType tab_type = NSTopTabsBezelBorder;
static float trans = 1;

//////////////////////////////////////////////////////////////////////

static NSWindow *make_window_for_view (Class nswindow, NSView *view, NSPoint *where)
{
    NSRect r = [view frame];

	unsigned int window_attrs = NSTitledWindowMask | 
								NSClosableWindowMask | 
								NSMiniaturizableWindowMask | 
								NSResizableWindowMask;
						
	if (prefs.guimetal)
		window_attrs |= NSTexturedBackgroundWindowMask;
	
    NSWindow *w = [[nswindow alloc] initWithContentRect:r 
                                styleMask:window_attrs
								  backing:NSBackingStoreBuffered
                                    defer:NO];
 	
	if (where)
	{
		[w setFrameOrigin:*where];
	}
	else
	{
		// Center the window over the preferred window size
		NSPoint ws;
		ws.x = prefs.mainwindow_left + (prefs.mainwindow_width - r.size.width) / 2;
		ws.y = prefs.mainwindow_top + (prefs.mainwindow_height - r.size.height) / 2;
		[w setFrameOrigin:ws];
	}
	
    [w setAlphaValue:trans];
    [w setReleasedWhenClosed:NO];
	[w setShowsResizeIndicator:NO];

    static bool first_time = true;
    if (first_time)
    {
        NSRect to = [w frame];
        NSRect from = to;
        from.origin.y += from.size.height - 1;
        from.size.height = 1;
        [w setFrame:from display:NO];
        [w makeKeyAndOrderFront:w];
        [w setFrame:to display:YES animate:YES];
        first_time = false;
    }

    [w setContentView:view];

    return w;
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
    NSArray *items = [(SGTabView *)[tab_window contentView] tabViewItems];
    for (unsigned i = 0; i < [items count]; i ++)
	{
		TabOrWindowView *the_view = (TabOrWindowView *) [[items objectAtIndex:i] view];
		id delegate = [the_view delegate];
		if ([delegate respondsToSelector:@selector (windowDidResize:)])
			[delegate windowDidResize:notification];
	}
}

- (void) windowDidMove:(NSNotification *) notification
{
	NSArray *items = [(SGTabView *)[tab_window contentView] tabViewItems];
	for (unsigned i = 0; i < [items count]; i ++)
	{
		TabOrWindowView *the_view = (TabOrWindowView *) [[items objectAtIndex:i] view];
		id delegate = [the_view delegate];
		if ([delegate respondsToSelector:@selector (windowDidMove:)])
			[delegate windowDidMove:notification];
	}
}

- (void) appleW
{
    SGTabViewItem *item = [(SGTabView *)[tab_window contentView] selectedTabViewItem];
    [self tabWantsToClose:item];
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
    TabOrWindowView *the_view = [[(SGTabView *)[tab_window contentView] selectedTabViewItem] view];
    [[the_view delegate] windowDidBecomeKey:notification];
}

// NOTE: This func closes the tab
- (void) tabWantsToClose:(SGTabViewItem *) item
{
    TabOrWindowView *me = [item view];
	[me close];
}

- (void) link_delink:(SGTabViewItem *) item
{
    TabOrWindowView *me = [item view];
	[me link_delink:item];
}

- (void) windowWillClose:(NSNotification *) notification
{
    while ([[tab_window contentView] numberOfTabViewItems])
    {
        SGTabViewItem *item = [(SGTabView *)[tab_window contentView] tabViewItemAtIndex:0];
        [self tabWantsToClose:item];
    }
}

- (void) tabView:(SGTabView *)tabView didSelectTabViewItem:(SGTabViewItem *)tabViewItem
{
    NSString *title = [[tabViewItem view] title];
    if (title)
        [tab_window setTitle:title];

    current_tab = NULL;		// Set this to NULL.. the next line of code will
							// do the right thing IF it's a chat window!!
    
    // Someone selected a new tab view.  Phony up a 'windowDidBecomeKey'
    // notification.  Let's hope they don't need the NSNotification object.

    [[[tabViewItem view] delegate] windowDidBecomeKey:nil];
}

- (void) tabViewDidResizeOutlne:(int) width
{
	prefs.outline_width = width;
}

@end

//////////////////////////////////////////////////////////////////////

@interface MyTabWindow : NSWindow
{
}
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

- (void) make_view_window:(NSPoint *) where
{
    if (window)
    {
        [window orderOut:self];
        [window autorelease];
    }

	window = make_window_for_view ([NSWindow class], self, where);
	[window setDelegate:self];
	if (ifr)
		[window setInitialFirstResponder:ifr];
	if (title)
		[window setTitle:title];
}

+ (void) make_tab_window:(NSView *) tab_view where:(NSPoint *) where
{
    if (tab_window)
    {
        [tab_window orderOut:self];
        [tab_window autorelease];
    }

	tab_window = make_window_for_view ([MyTabWindow class], tab_view, where);
	[tab_window setDelegate:tab_delegate];
	[tab_window makeKeyAndOrderFront:self];
}

+ (void) prefsChanged
{	
	switch ( prefs._tabs_position ) {
		case 0: tab_type = NSBottomTabsBezelBorder; break;
		case 1: tab_type = NSTopTabsBezelBorder; break;
		case 2: tab_type = NSRightTabsBezelBorder; break;
		case 3: tab_type = NSLeftTabsBezelBorder; break;
		case 4: tab_type = SGOutlineTabs; break;
		default:tab_type = NSTopTabsBezelBorder; break;
	}

    if (tab_window)
	{
        [[tab_window contentView] setTabViewType:tab_type];
        [[tab_window contentView] setHideCloseButtons:prefs.hide_tab_close_buttons];
		[[tab_window contentView] setOutlineWidth:prefs.outline_width];
	}
	
	NSArray *windows = [NSApp windows];
	
	for (unsigned i = 0; i < [windows count]; i ++)
	{
		NSWindow *w = [windows objectAtIndex:i];
		NSView *v = [w contentView];
		NSPoint where = [w frame].origin;
		bool was_metal = [w styleMask] & NSTexturedBackgroundWindowMask;
		
		if ([[v class] isSubclassOfClass:[TabOrWindowView class]])
		{
			TabOrWindowView *towv = (TabOrWindowView *) v;
			if (towv->window)
			{
				if (prefs.guimetal == was_metal)
					return;
				[towv make_view_window:&where];
				[towv->window makeKeyAndOrderFront:self];
			}
		}
		else if (w == tab_window)
		{
			if (prefs.guimetal == was_metal)
				return;
			[TabOrWindowView make_tab_window:v where:&where];
		}
	}
}

+ (void) setTransparency:(NSInteger) new_trans
{
    trans = (float) new_trans / 255;
        
    NSArray *windows = [NSApp windows];

    for (unsigned int i = 0; i < [windows count]; i ++)
    {
        NSWindow *win = (NSWindow *) [windows objectAtIndex:i];
        
        if (win == tab_window || [[win contentView] isKindOfClass:[TabOrWindowView class]])
            [win setAlphaValue:trans];
    }
}

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];

    self->window = nil;
    self->this_item = nil;
    self->delegate = nil;
    self->ifr = nil;
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

+ (bool) selectTab:(unsigned) n
{
    if (!tab_window)
        return false;
   
    NSTabViewItem *item = [[tab_window contentView] tabViewItemAtIndex:n];
    
    if (!item)
        return false;
    
    [[tab_window contentView] selectTabViewItem:item];
     
    return true;
}

+ (void) cycleWindow:(int) direction
{
    NSWindow *win = [NSApp keyWindow];

    if (win == tab_window)
    {
        NSTabView *tv = [tab_window contentView];
        int tab_item = [tv indexOfTabViewItem:[tv selectedTabViewItem]];
        if (direction > 0)
        {
            if (tab_item < [tv numberOfTabViewItems] - 1)
            {
                [tv selectNextTabViewItem:self];
                return;
            }
        }
        else
        {
            if (tab_item > 0)
            {
                [tv selectPreviousTabViewItem:self];
                return;
            }
        }
    }
    
    NSArray *windows = [NSApp windows];
    int win_num = [windows indexOfObject:win];
	int try_count = [windows count];
    
    do
    {
        win_num = (win_num + direction + [windows count]) % [windows count];
        win = [windows objectAtIndex:win_num];
		// all windows minimized
		if(try_count-- == 0)
			return;
    }
    while (![win isVisible]);
    
    [win makeKeyAndOrderFront:self];
    
    if (win == tab_window)
    {
        NSTabView *tv = [tab_window contentView];
        if (direction > 0)
            [tv selectTabViewItemAtIndex:0];
        else
            [tv selectTabViewItemAtIndex:[tv numberOfTabViewItems] - 1];
    }
}

+ (void) link_delink
{
    NSWindow *win = [NSApp keyWindow];

	if (win == tab_window)
	{
		SGTabViewItem *item = [(SGTabView *)[tab_window contentView] selectedTabViewItem];
		TabOrWindowView *view = [item view];
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
	if (tab_window)
	{
        SGTabView *tv = [tab_window contentView];
		NSString *group_name = [NSString stringWithUTF8String:server->servername];
		[tv setName:group_name forGroup:server->gui->tab_group];
	}
}

- (void) setServer:(struct server *) the_server
{
    self->server = the_server;
}

- (void) link_delink:(id) sender
{
    if (this_item)
        [self becomeWindowAndShow:true];
    else
        [self becomeTabAndShow:YES];
}

- (void) setTitle:(NSString *) new_title
{
    if (self->title)
        [self->title release];
    self->title = [new_title retain];

    if (window)
        [window setTitle:title];
    if (tab_window && [(SGTabView *)[tab_window contentView] selectedTabViewItem] == this_item)
        [tab_window setTitle:title];
}

- (void) setTabTitle:(NSString *) new_title
{
    if (self->tab_title)
        [self->tab_title release];
    self->tab_title = [new_title retain];
    
    if (this_item)
        [this_item setLabel:tab_title];
}

- (void) setDelegate:(id) new_delegate
{
    self->delegate = new_delegate;
}

- (void) setTabTitleColor:(NSColor *) c
{
    if (this_item)
    	[this_item setTitleColor:c];
}

- (BOOL)isFrontTab
{
    if (!this_item) return NO;
	else return [this_item isFrontTab];
}

- (id) delegate
{
    return delegate;
}

- (NSString *) title
{
    return title;
}

- (void) setInitialFirstResponder:(NSView *) r
{
    self->ifr = r;
    
    if (this_item)
        [this_item setInitialFirstResponder:r];
    if (window)
        [window setInitialFirstResponder:r];
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
    if (this_item)
    {
        [(SGTabView *)[tab_window contentView] removeTabViewItem:this_item];
        
        this_item = nil;
        
        if ([[[tab_window contentView] tabViewItems] count] == 0)
        {
            [tab_window orderOut:self];
            [tab_window autorelease];
            tab_window = nil;
        }
    }
    
    if (!window)
    {
		[self make_view_window:nil];
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
    else if (tab_window)
    {
        [(SGTabView *)[tab_window contentView] selectTabViewItem:this_item];
        
        // Don't order the tab window front.. just the tab itself.
        //[tab_window makeKeyAndOrderFront:sender];
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
    
    if (!tab_window)
    {
        [self setFrameSize:NSMakeSize (prefs.mainwindow_width, prefs.mainwindow_height)];

        if (!tab_delegate)
            tab_delegate = [[TabOrWindowViewTabDelegate alloc] init];
            
        NSRect frame = [self bounds];
        SGTabView *tab_view = [[[SGTabView alloc] initWithFrame:frame] autorelease];
        [tab_view setDelegate:tab_delegate];
        [tab_view setTabViewType:tab_type];
        [tab_view setHideCloseButtons:prefs.hide_tab_close_buttons];
		[tab_view setOutlineWidth:prefs.outline_width];

		[TabOrWindowView make_tab_window:tab_view where:nil];
    }
    
    if (!this_item)
    {
        this_item = [[[SGTabViewItem alloc] initWithIdentifier:nil] autorelease];
        [this_item setView:self];
        if (ifr)
            [this_item setInitialFirstResponder:ifr];
        if (tab_title)
            [this_item setLabel:tab_title];
		
		SGTabView *tv = (SGTabView *)[tab_window contentView];
		
		int this_group = server ? server->gui->tab_group : 0;

        [tv addTabViewItem:this_item toGroup:this_group];

		if ([tv groupName:this_group] == nil)
		{
			NSString *group_name;
			
			if (server)
			{
				if (server->servername[0])		// Can this ever happen?
					group_name = [NSString stringWithUTF8String:server->servername];
				else
					group_name = @"<Not Connected>";
			}
			else
				group_name = @"Utility Views";
				
			[tv setName:group_name forGroup:this_group];
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
    else if (this_item)
    {
		[self retain];
		[(SGTabView *)[tab_window contentView] removeTabViewItem:this_item];
		this_item = nil;
		if ([[[tab_window contentView] tabViewItems] count] == 0)
		{
			[tab_window orderOut:self];		// TODO - Should this be [tab_window close]?
			[tab_window autorelease];		// Must be autorelase because of 
			tab_window = nil;				// windowWillClose below...
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
