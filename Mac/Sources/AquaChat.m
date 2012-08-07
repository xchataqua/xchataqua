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

#include "outbound.h"
#include "server.h"
#include "cfgfiles.h"
#include "util.h"
#include "text.h"

#import <ShortcutRecorder/ShortcutRecorder.h>

#import "AquaChat.h"
#import "AutoAwayController.h"
#import "MenuMaker.h"
#import "XATabWindow.h"
#import "SGTabView.h"

// Utility Window
#import "AsciiWindow.h"
#import "BanWindow.h"
#import "ChannelWindow.h"
#import "ColorPalette.h"
#import "ChatViewController.h"
#import "DCCFileSendController.h"
#import "DCCFileRecieveController.h"
#import "DCCChatController.h"
#import "EditListWindow.h"
#import "FriendWindow.h"
#import "IgnoreWindow.h"
#import "PluginWindow.h"
#import "NetworkWindow.h"
#import "UrlGrabberWindow.h"

extern struct text_event te[];

extern void identd_start ();
extern void identd_stop ();

struct XAMenuPreferenceItem
{
    NSMenuItem *menuItem;
    unsigned int *preference;
    int reverse;
};

static struct XAMenuPreferenceItem menuPreferenceItems[6];

struct XATextEventItem XATextEvents[NUM_XP];

#pragma mark -

@interface AquaChat (private)

- (void) loadEventInfo;
- (void) saveEventInfo;
- (void) loadMenuPreferences;
- (void) toggleMenuItem:(id)sender;
- (void) updateUsermenu;
- (void) growl:(NSString *)text title:(NSString *)title;
- (void) setFont:(const char *) fontName;
- (NSUInteger) numberOfActiveDccFileTransfer;

@end

AquaChat *AquaChatShared;

@implementation AquaChat
@synthesize font, boldFont;
@synthesize palette=_palette;
@synthesize mainWindow=_mainWindow;

- (void) post_init
{    
    // Can't do this in awakeFromNib.. lists are not yet loaded..
    [self updateUsermenu];
    
    [AutoAwayController self]; // initialize
}

- (void) awakeFromNib
{   
    AquaChatShared = self;
    
    [GrowlApplicationBridge setGrowlDelegate:self];
    
    [self loadEventInfo];
    
    self->soundCache = [[NSMutableDictionary alloc] init];
    
    self->_palette = [[ColorPalette alloc] init];
    [self->_palette loadFromConfiguration];
    
    [self loadMenuPreferences];
    
    NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"ChatWindow"];
    self->_mainWindow = (id)controller.window;
    
    [self applyPreferences:nil];
    
    [NSApp requestEvents:NSKeyDown forWindow:nil forView:nil selector:@selector (myKeyDown:) object:self];
}

- (NSInteger)badgeCount {
    return _badgeCount;
}

- (void)setBadgeCount:(NSInteger)value {
    if (_badgeCount == value) return;

    NSDockTile *tile = [NSApp dockTile];
    if (value == 0) {
        tile.badgeLabel = nil;
    } else {
        tile.badgeLabel = [NSString stringWithFormat:@"%ld", value];
    }
    _badgeCount = value;
}

- (void)applyPreferences:(id)sender {
    [self setFont:prefs.font_normal];
    
    [self.mainWindow applyPreferences:sender];
    [TabOrWindowView applyPreferences:sender];
    
    if (prefs.autodccsend == 1 && !strcasecmp ((char *)g_get_home_dir (), prefs.dccdir))
    {
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"*WARNING*\nAuto accepting DCC to your home directory\ncan be dangerous and is exploitable. Eg:\nSomeone could send you a .bash_profile", @"xchat", @"") andWait:false];
    }
    
    // Fix existing windows
    
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *)list->data;
        [sess->gui->controller applyPreferences:sender];
    }
    
    // Toggle menu has no effect anymore
    if ([sender isKindOfClass:[NSMenuItem class]]) return;
    
    NSString* keyCodeString;
    keyCodeString = SRStringForKeyCode(prefs.tab_left_key);
    if ( keyCodeString != nil ) {
        [previousWindowMenuItem setKeyEquivalent:keyCodeString];
        [previousWindowMenuItem setKeyEquivalentModifierMask:prefs.tab_left_modifiers];
    }
    
    keyCodeString = SRStringForKeyCode(prefs.tab_right_key);
    if ( keyCodeString != nil ) {
        [nextWindowMenuItem setKeyEquivalent:keyCodeString];
        [nextWindowMenuItem setKeyEquivalentModifierMask:prefs.tab_right_modifiers];
    }
    
    if (prefs.identd)
        identd_start ();
    else
        identd_stop ();
}

- (BOOL) myKeyDown:(NSEvent *) theEvent
{
    if (([theEvent modifierFlags] & NSCommandKeyMask) == 0)
        return NO;
    
    NSString *key = [theEvent characters];
    if (!key || [key length] != 1)
        return NO;
    
    const char *text = [key UTF8String]; 
    
    if (text[0] < '1' || text[0] > '9')
        return NO;
    
    NSUInteger num = text[0] - '1';
    if (num >= self.mainWindow.tabView.tabViewItems.count) {
        return NO;
    }
    
    [self.mainWindow.tabView selectTabViewItemAtIndex:num];
    return YES;
    
}

//TODO sparkle here
- (void) new_version_alert
{
    bool ok = [SGAlert confirmWithString:NSLocalizedStringFromTable(@"There is a new version of X-Chat aqua available for download.  Press OK to visit the download site.", @"xchataqua", "")];
    if (ok)
        [self openDownload:self];
}

/* let's do it in the standard Cocoa way */
/*
 - (void) do_quit_menu:(id)sender
 {
 [[NSUserDefaults standardUserDefaults] synchronize];
 xchat_exit ();
 }
 */

- (void) event:(int) event args:(char **) args session:(session *) sess
{
    struct XATextEventItem *info = XATextEvents + event;
    BOOL bg = ![NSApp isActive];
    
    // Pref can be
    //    0 - Don't do it
    // -1 - Do it always
    //  1 - Do it if we're background
    //
    // Boiled down:
    //    Perform the action if our pref is -1 or we are in the background.
    
    if (info->growl && (info->growl == -1 || bg))
    {
        char o[4096];
        format_event (sess, event, args, o, sizeof (o), 1);
        if (o[0])
        {
            NSString *title = [NSString stringWithUTF8String:te[event].name];
            char *x = strip_color (o, -1, STRIP_ALL);
            NSString *description = [NSString stringWithUTF8String:x];
            [self growl:description title:title];
            free (x);
        }
    }
    
    if (info->bounce && (info->bounce == -1 || bg))
    {
        [NSApp requestUserAttention:prefs.xa_bounce_continuously ? NSCriticalRequest : NSInformationalRequest];
    }
    
    if (info->show && (info->show == -1 || bg))
    {
        self.badgeCount += 1;
    }
}

#pragma mark 

+ (void) forEachSessionOnServer:(struct server *)serv performSelector:(SEL)sel
{
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
        if (!serv || sess->server == serv)
            [sess->gui->controller performSelector:sel];
    }
}

+ (void) forEachSessionOnServer:(struct server *)serv performSelector:(SEL)sel withObject:(id) obj
{
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
        if (!serv || sess->server == serv)
            [sess->gui->controller performSelector:sel withObject:obj];
    }
}

+ (AquaChat *) sharedAquaChat
{
    return AquaChatShared;
}

#pragma mark NSApplication delegate

- (void) applicationDidFinishLaunching:(NSNotification *) notification
{ 
    NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    [center addObserver:self
               selector:@selector(workspaceWillSleep:)
                   name:NSWorkspaceWillSleepNotification
                 object:nil];
    
    [center addObserver:self
               selector:@selector(workspaceDidWake:)
                   name:NSWorkspaceDidWakeNotification
                 object:nil];
}

- (void) applicationDidBecomeActive:(NSNotification *) aNotification
{
    self.badgeCount = 0;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application
{
    NSApplicationTerminateReply reply = NSTerminateNow;
    NSUInteger active = [self numberOfActiveDccFileTransfer];
    if (active > 0) {
        if (NSRunAlertPanel(NSLocalizedStringFromTable(@"Some file transfers are still active.", @"xchat", @""),
                            NSLocalizedStringFromTable(@"Are you sure you want to quit?", @"xchat", @""),
                            NSLocalizedStringFromTable(@"Quit", @"xchataqua", @""), NSLocalizedStringFromTable(@"Cancel", @"xchataqua", @""), nil) != NSAlertDefaultReturn) reply = NSTerminateCancel;
    }
    return reply;
}

- (void) applicationWillTerminate:(NSNotification *) aNotification
{
    // To avoid having the closed windows end up sending /part, tell xchat we're quitting
    xchat_is_quitting = true;
    
    // ensure window delegates get windowWillClose: messages
    // shouldn't this happen automatically? it doesn't :(
    NSArray *windows = [[NSApplication sharedApplication] windows];
    NSUInteger count = [windows count];
    
    while (count--) {
        [[windows objectAtIndex:count] close];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    xchat_exit ();
}

#pragma mark NSWorkspace notification

- (void) workspaceWillSleep: (NSNotification *) notification
{
    if (!prefs.xa_partonsleep)
        return;
    
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
        
        if (sess->type == SESS_CHANNEL && sess->channel[0])
        {
            strcpy (sess->waitchannel, sess->channel);
            strcpy (sess->willjoinchannel, sess->channel);
        }
    }
    
    for (GSList *slist = serv_list; slist; slist = slist->next)
    {
        struct server *serv = (struct server *) slist->data;
        if (serv->server_session)
        {
            serv->p_quit (serv, prefs.xa_sleepmessage);
            serv->disconnect (serv->server_session, false, -1);
        }
    }
}

- (void) workspaceDidWake: (NSNotification *) notification
{
    for (GSList *slist = serv_list; slist; slist = slist->next)
    {
        struct server *serv = (struct server *) slist->data;
        serv->recondelay_tag = 0;
        if (!serv->connected && !serv->connecting && serv->server_session)
            serv->connect (serv, serv->hostname, serv->port, FALSE);
    }
}

#pragma mark fe-aqua

- (void) cleanup
{
    [self.palette save];
    [self saveEventInfo];
}

- (void) updatePluginWindow
{
    [(PluginWindow *)[UtilityWindow utilityIfExistsByKey:PluginWindowKey] update];
}

- (void) updateIgnoreWindowForLevel:(int)level
{
    [(IgnoreWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:IgnoreWindowKey] update:level];
}

- (void) growl:(NSString *)text title:(NSString *)title
{
    if ( title == nil ) title = @PRODUCT_NAME;
    [GrowlApplicationBridge notifyWithTitle:title
                                description:text
                           notificationName:@"X-Chat"
                                   iconData:nil
                                   priority:0
                                   isSticky:NO
                               clickContext:nil];
    
}

- (void) updateDcc:(struct DCC *) dcc
{
    switch (dcc->type)
    {
        case TYPE_SEND:
            if (dcc_send_window)
                [dcc_send_window update:dcc];
            break;
            
        case TYPE_RECV:
            if (dcc_recv_window)
                [dcc_recv_window update:dcc];
            break;
            
        case TYPE_CHATSEND:
        case TYPE_CHATRECV:
            if (dcc_chat_window)
                [dcc_chat_window update:dcc];
    }
}

- (void) addDcc:(struct DCC *) dcc
{
    switch (dcc->type)
    {
        case TYPE_SEND:
            if (dcc_send_window)
                [dcc_send_window add:dcc];
            break;
            
        case TYPE_RECV:
            if (dcc_recv_window)
                [dcc_recv_window add:dcc];
            break;
            
        case TYPE_CHATSEND:
        case TYPE_CHATRECV:
            if (dcc_chat_window)
                [dcc_chat_window add:dcc];
    }
}

- (void) removeDcc:(struct DCC *) dcc
{
    switch (dcc->type)
    {
        case TYPE_SEND:
            if (dcc_send_window)
                [dcc_send_window remove:dcc];
            break;
            
        case TYPE_RECV:
            if (dcc_recv_window)
                [dcc_recv_window remove:dcc];
            break;
            
        case TYPE_CHATSEND:
        case TYPE_CHATRECV:
            if (dcc_chat_window)
                [dcc_chat_window remove:dcc];
    }
}

- (BOOL)openDCCSendWindowAndShow:(BOOL)show {
    BOOL is_new = dcc_send_window != nil;
    
    if (!dcc_send_window) {
        dcc_send_window = [[DCCFileSendController alloc] init];
    }
    
    [dcc_send_window show:show];
    
    return is_new;
}

- (BOOL)openDCCRecieveWindowAndShow:(BOOL)show {
    BOOL is_new = dcc_recv_window != nil;
    
    if (!dcc_recv_window) {
        dcc_recv_window = [[DCCFileRecieveController alloc] init];
    }
    
    [dcc_recv_window show:show];
    
    return is_new;
}

- (BOOL)openDCCChatWindowAndShow:(BOOL)show {
    BOOL is_new = dcc_chat_window != nil;
    
    if (!dcc_chat_window) {
        dcc_chat_window = [[DCCChatController alloc] init];
    }
    
    [dcc_chat_window show:show];
    
    return is_new;
}

- (void) updateFriendWindow
{
    [(FriendWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:FriendWindowKey] update];
}

- (void) playWaveNamed:(const char *)filename
{
    NSString *key = [NSString stringWithUTF8String:filename];
    NSSound *sound = [soundCache objectForKey:key];
    
    if (sound == nil)
    {
        NSString *path = key;
        
        if ([key characterAtIndex:0] != '/')
        {
            NSString *bundle = [[NSBundle mainBundle] bundlePath];
            path = [NSString stringWithFormat:@"%@/../Sounds/%@", bundle, key];
        }
        
        sound = [[NSSound alloc] initWithContentsOfFile:path byReference:NO];
        if (sound == nil)
            return;
        [soundCache setObject:sound forKey:key];
        [sound setName:path];
        [sound release];
    }
    
    if (![sound isPlaying])
        [sound play];
}

- (void) openNetworkWindowForSession:(struct session *)sess
{
    NetworkWindow *window = [UtilityWindow utilityByKey:NetworkWindowKey windowNibName:@"NetworkWindow"];
    [window showForSession:sess];
}

- (void) addUrl:(const char *) url
{
    [(UrlGrabberWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UrlGrabberWindowKey] addUrl:[NSString stringWithUTF8String:url]];
}

- (void) ctrl_gui:(session *) sess action:(int) action arg:(int) arg
{
    switch (action)
    {
        case 0:
            [[sess->gui->controller window] orderOut:self]; break;
        case 1:
            [[sess->gui->controller window] orderFront:self]; break;
        case 2:
            [[sess->gui->controller window] orderFront:self]; break;
        case 3:
            /*[[sess->gui->controller set_tab_color (sess, -1, TRUE);*/ break; /* flash */
        case 4:
            [sess->gui->controller setTabColor:arg flash:NO]; break;
        case 5:
            [[sess->gui->controller window] miniaturize:self]; break;
    }
}

- (void) server_event:(server *)server event_type:(int)type arg:(int)arg
{
    switch (type)
    {
        case FE_SE_CONNECT:
            [TabOrWindowView updateGroupNameForServer:server];
    }
}

#pragma mark IBAction

- (void) showPreferencesWindow:(id)sender
{
    [[UtilityWindow utilityByKey:PreferencesWindowKey windowNibName:@"PreferencesWindow"] makeKeyAndOrderFront:self];
}

- (void) loadPlugin:(id)sender
{
    NSString *f = [SGFileSelection selectWithWindow:nil inDirectory:@"Plugins"].path;
    if (f)
    {
        NSString *cmd = [NSString stringWithFormat:@"LOAD \"%@\"", f];
        handle_command (current_sess, (char *) [cmd UTF8String], FALSE);
    }
}

- (void) showSearchPanel:(id)sender
{
    [searchString autorelease];
    searchString = [[SGRequest stringByRequestWithTitle:NSLocalizedStringFromTable(@"XChat: Search", @"xchat", @"") defaultValue:searchString] retain];
    [self findNext:sender];
}

- (void) findNext:(id)sender
{
    if ( searchString != nil )
        [current_sess->gui->controller find:searchString caseSensitive:NO backward:NO];
}

- (void) findPrevious:(id)sender
{
    if ( searchString != nil )
        [current_sess->gui->controller find:searchString caseSensitive:NO backward:YES];
}

- (void) useSelectionForFind:(id)sender
{
    [current_sess->gui->controller useSelectionForFind];
}

- (void) jumpToSelection:(id)sender
{
    [current_sess->gui->controller jumpToSelection];
}

- (void)insertMIRCFormat:(id)sender {
    [current_sess->gui->controller doMircColor:sender];
}

- (void) toggleAway:(id)sender
{
    handle_command (current_sess, "away", FALSE);
}

- (void) showChannelWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:UtilityWindowKey(ChannelWindowKey, current_sess->server) viewNibName:@"ChannelWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showDccRecieveWindow:(id)sender
{
    [self openDCCRecieveWindowAndShow:YES];
}

- (void) showDccChatWindow:(id)sender
{
    [self openDCCChatWindowAndShow:YES];
}

- (void) showDccSendWindow:(id)sender
{
    [self openDCCSendWindowAndShow:YES];
}

- (void) showRawLogWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:UtilityWindowKey(RawLogWindowKey, current_sess->server) viewNibName:@"RawLogWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showUrlGrabberWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:UrlGrabberWindowKey viewNibName:@"UrlGrabberWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showFriendWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:FriendWindowKey viewNibName:@"FriendWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showIgnoreWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:IgnoreWindowKey viewNibName:@"IgnoreWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showBanWindow:(id)sender
{
    if (current_sess->type != SESS_CHANNEL) {
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"You can only open the Ban List window while in a channel tab.", @"xchat", @"") andWait:YES];
        return;
    }
    [[UtilityTabOrWindowView utilityByKey:UtilityWindowKey(BanWindowKey, current_sess) viewNibName:@"BanWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) showAsciiWindow:(id)sender
{
    [[AsciiWindow utilityByKey:AsciiWindowKey] makeKeyAndOrderFront:self];
}

- (void) openNewServer:(id)sender
{
    int old = prefs.tabchannels;
    prefs.tabchannels = sender == newServerTabMenuItem;
    new_ircwindow (NULL, NULL, SESS_SERVER, true);
    prefs.tabchannels = old;
}

- (void) openNewChannel:(id)sender
{
    int old = prefs.tabchannels;
    prefs.tabchannels = sender == newChannelTabMenuItem;
    new_ircwindow (current_sess->server, NULL, SESS_CHANNEL, true);
    prefs.tabchannels = old;
}

- (void) toggleMenuItemAndReloadPreferences:(id)sender {
    [self toggleMenuItem:sender];
    [self applyPreferences:sender];
}

- (void) toggleInvisible:(id)sender
{
    [self toggleMenuItem:sender];
    
    if (current_sess->server->connected)
    {
        if (prefs.invisible)
            tcp_sendf (current_sess->server, "MODE %s +i\r\n", current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -i\r\n", current_sess->server->nick);
    }
}

- (void) toggleReceiveServerNotices:(id)sender
{
    [self toggleMenuItem:sender];
    
    if (current_sess->server->connected)
    {
        if (prefs.servernotice)
            tcp_sendf (current_sess->server, "MODE %s +s\r\n", current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -s\r\n", current_sess->server->nick);
    }
}

- (void) toggleReceiveWallops:(id)sender
{
    [self toggleMenuItem:sender];
    
    if (current_sess->server->connected)
    {
        if (prefs.wallops)
            tcp_sendf (current_sess->server, "MODE %s +w\r\n", current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -w\r\n", current_sess->server->nick);
    }
}

- (void) showPluginWindow:(id)sender
{
    [[UtilityWindow utilityByKey:PluginWindowKey windowNibName:@"PluginWindow"] makeKeyAndOrderFront:self];
}

- (void) clearWindow:(id)sender
{
    if (current_sess)
        [current_sess->gui->controller clear];
}

- (void) selectNextTab:(id)sender
{
    [TabOrWindowView cycleWindow:1];
}

- (void) selectPreviousTab:(id)sender
{
    [TabOrWindowView cycleWindow:-1];
}

- (void) toggleTabAttachment:(id)sender
{
    [TabOrWindowView link_delink];
}

- (void) closeTab:(id)sender
{
    [[NSApp keyWindow] performClose:sender];
}

- (void) toggleAwayToValue:(bool) is_away
{
    [awayMenuItem setState:is_away ? NSOnState : NSOffState];
}

- (void) showNetworkWindow:(id)sender
{
    [self openNetworkWindowForSession:current_sess];
}

- (void) showUserCommandsWindow:(id)sender
{
    [[UtilityWindow utilityByKey:UserCommandsWindowKey windowNibName:@"UserCommandsWindow"] makeKeyAndOrderFront:self];
}

#define ctcp_help _("CTCP Replies - Special codes:\n\n"\
                    "%d  =  data (the whole ctcp)\n"\
                    "%e  =  current network name\n"\
                    "%m  =  machine info\n"\
                    "%s  =  nick who sent the ctcp\n"\
                    "%t  =  time/date\n"\
                    "%2  =  word 2\n"\
                    "%3  =  word 3\n"\
                    "&2  =  word 2 to the end of line\n"\
                    "&3  =  word 3 to the end of line\n\n")

- (void) showCtcpRepliesWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:CTCPRepliesWindowKey windowNibName:@"EditListWindow"];
    [window setTitle:NSLocalizedStringFromTable(@"XChat: CTCP Replies", @"xchat", @"Title of Window: MainMenu->X-Chat Aqua->Preference Lists->CTCP Replies...")];
    [window loadDataFromList:&ctcp_list filename:@"ctcpreply.conf"];                              
    [window setHelp:ctcp_help];
    [window makeKeyAndOrderFront:self];
}

#define ulbutton_help _("Userlist Buttons - Special codes:\n\n"\
                        "%a  =  all selected nicks\n"\
                        "%c  =  current channel\n"\
                        "%e  =  current network name\n"\
                        "%h  =  selected nick's hostname\n"\
                        "%m  =  machine info\n"\
                        "%n  =  your nick\n"\
                        "%s  =  selected nick\n"\
                        "%t  =  time/date\n")

- (void) showUserlistButtonsWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:UserlistButtonsWindowKey windowNibName:@"EditListWindow"];    
    [window setTitle:NSLocalizedStringFromTable(@"XChat: Userlist buttons", @"xchat", "Title of Window: MainMenu->X-Chat Aqua->References Lists->Userlist Buttons...")];
    [window loadDataFromList:&button_list filename:@"buttons.conf"];
    [window setHelp:ulbutton_help];
    [window makeKeyAndOrderFront:self];
    [window setTarget:[window class] didCloseSelector:@selector(setupUserlistButtons)];
}

- (void) showUserlistPopupWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:UserlistPopupWindowKey windowNibName:@"EditListWindow"];
    [window setTitle:NSLocalizedStringFromTable(@"XChat: Userlist Popup menu", @"xchat", @"Title of Window: MainMenu->X-Chat Aqua->References Lists->Userlist Popup...")];
    [window loadDataFromList:&popup_list filename:@"popup.conf"];
    [window setHelp:ulbutton_help];
    [window makeKeyAndOrderFront:self];
}

#define dlgbutton_help  _("Dialog Buttons - Special codes:\n\n"\
                          "%a  =  all selected nicks\n"\
                          "%c  =  current channel\n"\
                          "%e  =  current network name\n"\
                          "%h  =  selected nick's hostname\n"\
                          "%m  =  machine info\n"\
                          "%n  =  your nick\n"\
                          "%s  =  selected nick\n"\
                          "%t  =  time/date\n")


- (void) showDialogButtonsWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:DialogButtonsWindowKey windowNibName:@"EditListWindow"];
    [window setTitle:NSLocalizedStringFromTable(@"XChat: Dialog buttons", @"xchat", @"")];
    [window loadDataFromList:&dlgbutton_list filename:@"dlgbuttons.conf"];
    [window setHelp:dlgbutton_help];
    [window makeKeyAndOrderFront:self];
    [window setTarget:[window class] didCloseSelector:@selector(setupUserlistButtons)];
}

- (void) showReplacePopupWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:ReplacePopupWindowKey windowNibName:@"EditListWindow"];
    [window setTitle:NSLocalizedStringFromTable(@"XChat: Replace", @"xchat", @"")];
    [window loadDataFromList:&replace_list filename:@"replace.conf"];
    [window makeKeyAndOrderFront:self];
}

#define url_help  _("URL Handlers - Special codes:\n\n"\
                    "%s  =  the URL string\n\n"\
                    "Putting a ! infront of the command\n"\
                    "indicates it should be sent to a\n"\
                    "shell instead of XChat")

- (void) showUrlHandlersWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:URLHandlersWindowKey windowNibName:@"EditListWindow"];
    [window setTitle:NSLocalizedStringFromTable(@"XChat: URL Handlers", @"xchat", "Title of Window: MainMenu->X-Chat Aqua->References Lists->URL Handler...")];
    [window loadDataFromList:&urlhandler_list filename:@"urlhandlers.conf"];
    [window setHelp:url_help];
    [window makeKeyAndOrderFront:self];    
}

- (void) showUserMenusWindow:(id)sender
{
    EditListWindow *window = [UtilityWindow utilityByKey:UserMenusWindowKey windowNibName:@"EditListWindow"];

    [window setTitle:NSLocalizedStringFromTable(@"XChat: User menu", @"xchat", @"Title of Window: MainMenu->User Menu->Edit This Menu...")];
    [window loadDataFromList:&usermenu_list filename:@"usermenu.conf"];
    [window makeKeyAndOrderFront:self];    
    [window setTarget:[AquaChat sharedAquaChat] didCloseSelector:@selector(updateUsermenu)];
}

- (void) showTextEventsWindow:(id)sender
{
    [[UtilityWindow utilityByKey:TextEventsWindowKey windowNibName:@"TextEventsWindow"] makeKeyAndOrderFront:self];
}

- (void) showLogViewWindow:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:LogViewWindowKey viewNibName:@"LogViewWindow"] becomeTabOrWindowAndShow:YES];
}

/*
 * These four methods are hooked up to menu entries in the Help menu and are
 * used to open various relevant URLs (docs, homepage, etc.) in the default
 * web browser.
 *
 */

// Open developer page
- (void) openHomepage:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://xchataqua.github.com/"]];
}

// Open the X-Chat Aqua download page (same as homepage for now).
- (void) openDownload:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://github.com/xchataqua/xchataqua/downloads"]];
}

// Open the X-Chat Aqua Release Notes.
- (void) showReleaseNotes:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://github.com/xchataqua/xchataqua/tags"]];
}

// Open issue tracker
- (void) openIssues:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://github.com/xchataqua/xchataqua/issues"]];
}

#pragma mark GrowlApplicationBridgeDelegate

- (NSDictionary *) registrationDictionaryForGrowl
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [NSArray arrayWithObjects:@"X-Chat", nil], GROWL_NOTIFICATIONS_ALL,
            [NSArray arrayWithObjects:@"X-Chat", nil], GROWL_NOTIFICATIONS_DEFAULT,
            nil];
}

- (BOOL)hasNetworkClientEntitlement {
    return YES;
}

@end

#pragma mark -

@implementation AquaChat (Private)

- (void) loadEventInfo
{
    NSString *fn = [NSString stringWithFormat:@"%s/xcaevents.conf", get_xdir_fs ()];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fn];
    if (dict == nil) {
        return;
    }
    
    for (NSInteger i = 0; i < NUM_XP; i++) {
        struct XATextEventItem *event = &XATextEvents[i];
        char *name = te[i].name;
        
        event->growl = [[dict objectForKey:[NSString stringWithFormat:@"%s_growl", name]] integerValue];
        event->show = [[dict objectForKey:[NSString stringWithFormat:@"%s_show", name]] integerValue];
        event->bounce = [[dict objectForKey:[NSString stringWithFormat:@"%s_bounce", name]] integerValue];
    }
}

- (void) saveEventInfo
{    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:NUM_XP];
    for (int i = 0; i < NUM_XP; i++)
    {
        struct XATextEventItem *event = &XATextEvents[i];
        char *name = te[i].name;
        
        if (event->growl)
        {
            [dict setObject:[NSNumber numberWithInteger:event->growl] forKey:[NSString stringWithFormat:@"%s_growl", name]];
        }
        if (event->show)
        {
            [dict setObject:[NSNumber numberWithInteger:event->show] forKey:[NSString stringWithFormat:@"%s_show", name]];
        }
        if (event->bounce)
        {
            [dict setObject:[NSNumber numberWithInteger:event->bounce] forKey:[NSString stringWithFormat:@"%s_bounce", name]];
        }
        
    }
    NSString *filename = [NSString stringWithFormat:@"%s/xcaevents.conf", get_xdir_fs ()];
    [dict writeToFile:filename atomically:YES];
}

- (void) toggleMenuItem:(id)sender
{
    struct XAMenuPreferenceItem *pref = &menuPreferenceItems[[sender tag]];
    *pref->preference = !*pref->preference;
    NSCellStateValue shownValue = *pref->preference ? NSOnState : NSOffState;
    if (pref->reverse) shownValue = !shownValue;
    [sender setState:shownValue];
}

- (void) saveBuffer:(id)sender
{
    NSString *filename = [SGFileSelection saveWithWindow:[current_sess->gui->controller window]].path;
    if ( filename != nil )
        [current_sess->gui->controller saveBuffer:filename];
}

- (void) updateUsermenu
{
    while ([userMenu numberOfItems] > 2)
        [userMenu removeItemAtIndex:2];
    
    [[MenuMaker defaultMenuMaker] appendItemList:usermenu_list toMenu:userMenu withTarget:nil inSession:NULL];
}

- (void) loadMenuPreferences
{
    struct XAMenuPreferenceItem tempPreferences [] =
    {
        // IRC menu
        { invisibleMenuItem, &prefs.invisible, NO },
        { receiveNoticesMenuItem, &prefs.servernotice, NO },
        { receiveWallopsMenuItem, &prefs.wallops, NO },
        // View menu
        { userListMenuItem,  &prefs.hideuserlist, YES },
        { userlistButtonsMenuItem, &prefs.userlistbuttons, NO },
        { modeButtonsMenuItem, &prefs.chanmodebuttons, NO },
    };
    
    for (NSUInteger i = 0; i < sizeof(menuPreferenceItems) / sizeof(menuPreferenceItems[0]); i ++)
    {
        menuPreferenceItems [i] = tempPreferences [i];
        struct XAMenuPreferenceItem *pref = &menuPreferenceItems [i];
        NSCellStateValue shownValue = *pref->preference ? NSOnState : NSOffState;
        if (pref->reverse) shownValue = !shownValue;
        [pref->menuItem setState:shownValue];
        [pref->menuItem setTag:i];
    }
}

- (void) setFont:(const char *) fontName
{
    NSFont *f = nil;
    
    // "Font Name <space> Font Size"
    const char *space = strrchr (fontName, ' ');
    if (space)
    {
        CGFloat sz = atof (space + 1);
        if (sz)
        {
            NSString *nm = [[NSString alloc] initWithBytes:prefs.font_normal
                                                    length:space - fontName
                                                  encoding:NSUTF8StringEncoding];
            f = [NSFont fontWithName:nm size:sz];
            [nm release];
        }
    }
    
    if (!f)
        f = [NSFont fontWithName:@"Courier" size:12];
    
    if (!f)
        f = [NSFont systemFontOfSize:12];
    
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    
    [self->font release];
    [self->boldFont release];
    
    self->font = [[fontManager convertFont:f toHaveTrait:NSUnboldFontMask] retain];
    self->boldFont = [[fontManager convertFont:f toHaveTrait:NSBoldFontMask] retain];
    
    if (!self->font)
        self->font = [f retain];
    if (!self->boldFont)
        self->boldFont = [f retain];
    
    sprintf (prefs.font_normal, "%s %.1f", [[font fontName] UTF8String], [font pointSize]);
}

- (NSUInteger) numberOfActiveDccFileTransfer
{
    GSList *list = dcc_list;
    NSUInteger count = 0;
    
    while (list)
    {
        struct DCC *dcc = (struct DCC *)list->data;
        if ((dcc->type == TYPE_SEND || dcc->type == TYPE_RECV) &&
            dcc->dccstat == STAT_ACTIVE)
            count++;
        list = list->next;
    }
    
    return count;
}

@end

