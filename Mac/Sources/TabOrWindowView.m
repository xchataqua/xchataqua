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

#include "fe-aqua_common.h"

#import "ColorPalette.h"
#import "TabOrWindowView.h"
#import "XATabWindow.h"

//////////////////////////////////////////////////////////////////////

@class TabOrWindowViewTabDelegate;

static NSTabViewType tabViewType = NSBottomTabsBezelBorder;
static float trans = 1;

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
    for (SGTabViewItem *item in [[XATabWindow defaultTabWindow].tabView tabViewItems]) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidResize:)])
            [delegate windowDidResize:notification];
    }
}

- (void) windowDidMove:(NSNotification *) notification
{
    for (SGTabViewItem *item in [[XATabWindow defaultTabWindow].tabView tabViewItems]) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidMove:)])
            [delegate windowDidMove:notification];
    }
}

- (void)closeTab
{
    SGTabViewItem *item = [[XATabWindow defaultTabWindow].tabView selectedTabViewItem];
    [self tabWantsToClose:item];
}

- (void) windowDidBecomeKey:(NSNotification *) notification
{
    TabOrWindowView *view = (TabOrWindowView *)[[[XATabWindow defaultTabWindow].tabView selectedTabViewItem] view];
    [[view delegate] windowDidBecomeKey:notification];
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
    // NOTE: This raise part-on-quit problem on XChat Aqua
    // Cmd-Q goes AquaChat -applicationWillTerminate: first, so no problem
    // Clicking Red button on Chat windows trigget this directly, so part over all channels
    
    while ([XATabWindow defaultTabWindow].tabView.tabViewItems.count) {
        SGTabViewItem *item = [[XATabWindow defaultTabWindow].tabView tabViewItemAtIndex:0];
        [self tabWantsToClose:item];
    }
}

- (void) tabView:(SGTabView *)tabView didSelectTabViewItem:(SGTabViewItem *)tabViewItem
{
    NSString *title = [(TabOrWindowView *)[tabViewItem view] title];
    if (title)
        [[XATabWindow defaultTabWindow] setTitle:title];
    
    current_tab = NULL;        // Set this to NULL.. the next line of code will
    // do the right thing IF it's a chat window!!
    
    // Someone selected a new tab view.  Phony up a 'windowDidBecomeKey'
    // notification.  Let's hope they don't need the NSNotification object.
    
    [[(TabOrWindowView *)[tabViewItem view] delegate] windowDidBecomeKey:nil];
}

- (void) tabViewDidResizeOutlne:(int) width
{
    prefs.xa_outline_width = width;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation TabOrWindowView
@synthesize delegate;
@synthesize title, tabTitle;

+ (void) preferencesChanged
{
    [TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];
    
    if ( prefs.tab_layout == 2 ) {
        tabViewType = SGOutlineTabs;
    } else {
        switch ( prefs._tabs_position ) {
            case 0: tabViewType = NSBottomTabsBezelBorder; break;
            case 1: tabViewType = NSTopTabsBezelBorder; break;
            case 2: tabViewType = NSRightTabsBezelBorder; break;
            case 3: tabViewType = NSLeftTabsBezelBorder; break;
            default:tabViewType = NSBottomTabsBezelBorder; break;
        }
    }
    
    if ([XATabWindow defaultTabWindow])
    {
        SGTabView *tabView = [[XATabWindow defaultTabWindow] tabView];
        [tabView setTabViewType:tabViewType];
        [tabView setHideCloseButtons:prefs.xa_hide_tab_close_buttons];
        [tabView setOutlineWidth:prefs.xa_outline_width];
    }
/*    This doesn't work because I can't reference outline in the way I just did,
    if you have a better solution, please share it :)

    ColorPalette *p = [[AquaChat sharedAquaChat] palette];
    [outline setBackgroundColor:[p getColor:XAColorBackground]];
*/
}

+ (void) setTransparency:(NSInteger)transparency
{
    trans = transparency / 255.0f;
    
    for (NSWindow *win in [NSApp windows])
    {
        if (win == [XATabWindow defaultTabWindow] || [[win contentView] isKindOfClass:[TabOrWindowView class]])
            [win setAlphaValue:trans];
    }
}

#if 0
- (id) initWithFrame:(NSRect) frameRect
{
    if ((self=[super initWithFrame:frameRect])!=nil) {
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
    }
    return self;
}
#endif

+ (BOOL) selectTabByIndex:(NSUInteger)index
{
    SGTabView *tabView = [XATabWindow defaultTabWindow].tabView;
    if (!tabView)
        return FALSE;
    
    SGTabViewItem *item = [tabView tabViewItemAtIndex:index];
    
    if (!item)
        return FALSE;
    
    [tabView selectTabViewItem:item];
    
    return TRUE;
}

+ (void) cycleWindow:(int) direction
{
    NSWindow *win = [NSApp keyWindow];
    
    if (win == [XATabWindow defaultTabWindow])
    {
        SGTabView *tabView = [win contentView];
        NSInteger tabItemIndex = [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
        if (direction > 0)
        {
            if (tabItemIndex < tabView.tabViewItems.count - 1)
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
    
    if (win == [XATabWindow defaultTabWindow])
    {
        SGTabView *tabView = [win contentView];
        [tabView selectTabViewItemAtIndex:(direction>0) ? 0 : tabView.tabViewItems.count - 1];
    }
}

+ (void) link_delink
{
    NSWindow *win = [NSApp keyWindow];
    
    if (win == [XATabWindow defaultTabWindow])
    {
        SGTabViewItem *item = [(SGTabView *)[win contentView] selectedTabViewItem];
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
    if ([XATabWindow defaultTabWindow])
    {
        SGTabView *tabView = [XATabWindow defaultTabWindow].tabView;
        NSString *groupName = [NSString stringWithUTF8String:server->servername];
        [tabView setName:groupName forGroup:server->gui->tabGroup];
    }
}

- (void) setServer:(struct server *)aServer
{
    self->server = aServer;
}

- (void) link_delink:(id)sender
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
    NSWindow *tabWindow = [XATabWindow defaultTabWindow];
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

- (void) setTabTitleColorIndex:(NSInteger)color
{
    if (tabViewItem) {
        [tabViewItem setTitleColorIndex:color];
    }
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
        XATabWindow *tabWindow = [XATabWindow defaultTabWindow];
        [tabWindow.tabView removeTabViewItem:tabViewItem];
        
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
        NSUInteger windowStyleMask = NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask;
        
        window = [[NSWindow alloc] initWithContentRect:self.frame
                                             styleMask:windowStyleMask
                                               backing:NSBackingStoreBuffered
                                                 defer:NO];
        NSPoint origin = NSMakePoint(prefs.mainwindow_left + (prefs.mainwindow_width - self.frame.size.width) / 2,
                                     prefs.mainwindow_top  + (prefs.mainwindow_height- self.frame.size.height)/ 2);
        [window setFrameOrigin:origin];

        [window setAlphaValue:trans];
        [window setReleasedWhenClosed:NO];
        [window setShowsResizeIndicator:NO];
        
        [window setContentView:self];
        
        [window setDelegate:self];
        if (initialFirstResponder)
            [window setInitialFirstResponder:initialFirstResponder];
        if (title)
            [window setTitle:title];
    }
    
    if (show)
        [self makeKeyAndOrderFront:self];
}

- (void) makeKeyAndOrderFront:(id)sender
{
    if (window)
    {
        [window makeKeyAndOrderFront:sender];
    } else if ([XATabWindow defaultTabWindow]) {
        [[XATabWindow defaultTabWindow].tabView selectTabViewItem:tabViewItem];
        
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
    
    if (!tabViewItem)
    {
        tabViewItem = [[SGTabViewItem alloc] initWithIdentifier:nil];
        [tabViewItem setView:self];
        if (initialFirstResponder != nil) {
            [tabViewItem setInitialFirstResponder:initialFirstResponder];
        }
        if (tabTitle) {
            [tabViewItem setLabel:tabTitle];
        }
        
        SGTabView *tabView = [XATabWindow defaultTabWindow].tabView;
        
        NSInteger tabGroup = self->server ? self->server->gui->tabGroup : 0;
        
        [tabView addTabViewItem:tabViewItem toGroup:tabGroup];
        [tabViewItem release];
        
        if ([tabView groupName:tabGroup] == nil)
        {
            NSString *groupName;
            
            if (self->server)
            {
                if (self->server->servername[0])        // Can this ever happen?
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
        [window close];        // windowWillClose notification will follow
    }
    else if (tabViewItem)
    {
        [self retain];
        
        XATabWindow *tabWindow = [XATabWindow defaultTabWindow];
        [tabWindow.tabView removeTabViewItem:tabViewItem];
        tabViewItem = nil;
        if ([[tabWindow.tabView tabViewItems] count] == 0)
        {
            [tabWindow orderOut:self];  // TODO - Should this be [tabWindow close]?
            [tabWindow autorelease];    // Must be autorelase because of 
            tabWindow = nil;            // windowWillClose below...
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
    if ([delegate respondsToSelector:@selector(windowDidBecomeKey:)])
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
