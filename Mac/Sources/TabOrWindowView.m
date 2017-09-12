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

#import "AquaChat.h"
#import "ColorPalette.h"
#import "TabOrWindowView.h"
#import "XATabWindow.h"
#import "XATabView.h"

#pragma mark -

@class TabOrWindowViewTabDelegate;

static float trans = 1;

#pragma mark -

@interface TabOrWindowViewTabDelegate : NSObject<XATabViewDelegate, NSWindowDelegate>

@end

@implementation TabOrWindowViewTabDelegate

- (void)windowDidResize:(NSNotification *)notification {
    XATabWindow *window = notification.object;
    for (XATabViewItem *item in window.tabView.tabViewItems) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidResize:)])
            [delegate windowDidResize:notification];
    }
}

- (void)windowDidMove:(NSNotification *)notification {
    XATabWindow *window = notification.object;
    for (XATabViewItem *item in window.tabView.tabViewItems) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidMove:)])
            [delegate windowDidMove:notification];
    }
}

- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    XATabWindow *window = notification.object;
    for (XATabViewItem *item in window.tabView.tabViewItems) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidEnterFullScreen:)])
            [delegate windowDidEnterFullScreen:notification];
    }
}

- (void)windowDidExitFullScreen:(NSNotification *)notification {
    XATabWindow *window = notification.object;
    for (XATabViewItem *item in window.tabView.tabViewItems) {
        id delegate = ((TabOrWindowView *)item.view).delegate;
        if ([delegate respondsToSelector:@selector (windowDidExitFullScreen:)])
            [delegate windowDidExitFullScreen:notification];
    }
}

- (void)windowCloseTab:(XATabWindow *)window {
    XATabViewItem *item = window.tabView.selectedTabViewItem;
    [item performClose:window];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    XATabWindow *window = notification.object;
    TabOrWindowView *view = (TabOrWindowView *)window.tabView.selectedTabViewItem.view;
    [[view delegate] windowDidBecomeKey:notification];
}

- (void)link_delink:(XATabViewItem *)item {
    TabOrWindowView *me = (TabOrWindowView *)[item view];
    [me link_delink:item];
}

- (void) windowWillClose:(NSNotification *) notification
{
    // NOTE: This raise part-on-quit problem on XChat Aqua
    // Cmd-Q goes AquaChat -applicationWillTerminate: first, so no problem
    // Clicking Red button on Chat windows trigget this directly, so part over all channels
    XATabWindow *window = notification.object;
    while (window.tabView.tabViewItems.count) {
        XATabViewItem *item = [window.tabView tabViewItemAtIndex:0];
        [item performClose:self];
    }
}

- (void)tabView:(XATabView *)tabView didSelectTabViewItem:(XATabViewItem *)tabViewItem {
    NSString *title = [(TabOrWindowView *)[tabViewItem view] title];
    if (title) {
        [tabView.window setTitle:title];
    }

    [(TabOrWindowView *)[tabViewItem view] clearNotifications];
    
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

- (void)viewDidMoveToSuperview {
    SEL action = @selector(viewDidMoveToSuperview:);
    if ([self.delegate respondsToSelector:action]) {
        [self.delegate performSelector:action withObject:self];
    }
}

+ (void)applyPreferences:(id)sender {
    [TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];
}

+ (void) setTransparency:(NSInteger)transparency
{
    trans = transparency / 255.0f;
    
    for (NSWindow *win in [NSApp windows])
    {
        if (win == [[AquaChat sharedAquaChat] mainWindow] || [[win contentView] isKindOfClass:[TabOrWindowView class]])
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

+ (void)cycleWindow:(int)direction {
    NSWindow *mainWindow = [AquaChat sharedAquaChat].mainWindow;
    NSWindow *win = [NSApp keyWindow];
    
    if (win == mainWindow) {
        XATabView *tabView = [win contentView];
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
        win = windows[windowIndex];
        // all windows minimized
        if(try_count-- == 0)
            return;
    }
    while (![win isVisible]);
    
    [win makeKeyAndOrderFront:self];
    
    if (win == mainWindow) {
        XATabView *tabView = [win contentView];
        [tabView selectTabViewItemAtIndex:(direction>0) ? 0 : tabView.tabViewItems.count - 1];
    }
}

+ (void) link_delink
{
    NSWindow *win = [NSApp keyWindow];
    
    if (win == [[AquaChat sharedAquaChat] mainWindow]) {
        XATabViewItem *item = [(XATabView *)[win contentView] selectedTabViewItem];
        TabOrWindowView *view = (TabOrWindowView *)[item view];
        [view link_delink:self];
    } else {
        NSView *view = [win contentView];
        if ([view isKindOfClass:[TabOrWindowView class]]) {
            [(TabOrWindowView *)view link_delink:self];
        }
    }
}

+ (void) updateGroupNameForServer:(struct server *) server
{
    NSWindow *mainWindow = [[AquaChat sharedAquaChat] mainWindow];
    if (mainWindow != nil) {
        XATabView *tabView = mainWindow.contentView;
        NSString *groupName = @(server->servername);
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
    
    if (window) {
        [window setTitle:title];
    }
    
    NSWindow *tabWindow = [AquaChat sharedAquaChat].mainWindow;
    if (tabWindow && [(XATabView *)[tabWindow contentView] selectedTabViewItem] == tabViewItem) {
        [tabWindow setTitle:title];
    }
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
        XATabWindow *tabWindow = [AquaChat sharedAquaChat].mainWindow;
        [tabWindow.tabView removeTabViewItem:tabViewItem];
        
        tabViewItem = nil;
        
        if ([[[tabWindow contentView] tabViewItems] count] == 0)
        {
            [tabWindow orderOut:self];
            tabWindow = nil;
        }
    }
    
    if (!window)
    {
        NSUInteger windowStyleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;

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
    } else {
        XATabWindow *mainWindow = [AquaChat sharedAquaChat].mainWindow;
        [mainWindow.tabView selectTabViewItem:tabViewItem];
        
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
    
    if (!tabViewItem) {
        tabViewItem = [[XATabViewItem alloc] initWithIdentifier:nil];
        [tabViewItem setView:self];
        if (initialFirstResponder != nil) {
            [tabViewItem setInitialFirstResponder:initialFirstResponder];
        }
        if (tabTitle) {
            [tabViewItem setLabel:tabTitle];
        }
        
        XATabView *tabView = [AquaChat sharedAquaChat].mainWindow.tabView;
        
        NSInteger tabGroup = self->server ? self->server->gui->tabGroup : 0;
        
        [tabView addTabViewItem:tabViewItem toGroup:tabGroup];
        [tabViewItem release];
        
        if ([tabView groupForIdentifier:tabGroup].name == nil)
        {
            NSString *groupName;
            
            if (self->server)
            {
                if (self->server->servername[0])        // Can this ever happen?
                    groupName = @(self->server->servername);
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
        
        XATabWindow *tabWindow = [AquaChat sharedAquaChat].mainWindow;
        [tabWindow.tabView removeTabViewItem:tabViewItem];
        tabViewItem = nil;
        if ([[tabWindow.tabView tabViewItems] count] == 0)
        {
            [tabWindow orderOut:self];  // TODO - Should this be [tabWindow close]?
            tabWindow = nil;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowWillCloseNotification object:self];
        if ([delegate respondsToSelector:@selector (windowWillClose:)])
            [delegate windowWillClose:nil];
        [self release];
    }
}

- (void) clearNotifications
{
    if (!server)
        return;

    NSArray *notifications = [NSUserNotificationCenter defaultUserNotificationCenter].deliveredNotifications;

    for (NSUserNotification *notification in notifications)
    {
        NSNumber *servId = notification.userInfo[@"server"];
        NSString *channel = notification.userInfo[@"channel"];
        if (!servId || !channel)
            continue;

        if ([servId intValue] == server->id &&
             [channel isEqualToString:tabViewItem.label])
            [[NSUserNotificationCenter defaultUserNotificationCenter] removeDeliveredNotification:notification];
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

- (void) windowDidEnterFullScreen:(NSNotification *) notification
{
    if ([delegate respondsToSelector:@selector (windowDidEnterFullScreen:)])
        [delegate windowDidEnterFullScreen:notification];
}

- (void) windowDidExitFullScreen:(NSNotification *) notification
{
    if ([delegate respondsToSelector:@selector (windowDidExitFullScreen:)])
        [delegate windowDidExitFullScreen:notification];
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
