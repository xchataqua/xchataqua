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

#include <unistd.h>

#ifdef __cplusplus
extern "C" {
#endif
	
#include <stdio.h>
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/server.h"
#include "../common/userlist.h"
#include "../common/cfgfiles.h"
#include "../common/util.h"
#include "../common/text.h"
#include "../common/dcc.h"
#ifdef __cplusplus
}
#endif

#include "XACommon.h"

#import <Cocoa/Cocoa.h>


#import "AquaChat.h"
#import "PrefsController.h"
#import "ReleaseNotesWindow.h"
#import "ChatWindow.h"
#import "SGAlert.h"
#import "UserCommands.h"
#import "CtcpReplies.h"
#import "UserlistButtons.h"
#import "UserlistPopup.h"
#import "DialogButtons.h"
#import "ReplacePopup.h"
#import "UrlHandlers.h"
#import "UserMenus.h"
#import "EditEvents.h"
#import "UrlGrabberWin.h"
#import "DccSendWin.h"
#import "DccRecvWin.h"
#import "DccChatWin.h"
#import "ChannelListWin.h"
#import "RawLogWin.h"
#import "NotifyListWin.h"
#import "IgnoreListWin.h"
#import "BanListWin.h"
#import "AsciiWin.h"
#import "LogViewer.h"
#import "PluginList.h"
#import "MenuMaker.h"
#import "ServerList.h"
#import "SRCommon.h"
#import "AutoAwayController.h"

extern struct text_event te[];

extern void identd_start ();
extern void identd_stop ();

//////////////////////////////////////////////////////////////////////

struct menu_pref
{
    id			 menu;
    unsigned int *pref;
};

//////////////////////////////////////////////////////////////////////

static menu_pref menu_prefs [3];
static AquaChat *aquachat;
static NSImage  *my_image;
static NSImage  *alert_image;

EventInfo text_event_info[NUM_XP];

//////////////////////////////////////////////////////////////////////

@implementation AquaChat

+ (void) forEachSessionOnServer:(struct server *) serv
		performSelector:(SEL) sel
{
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
        if (!serv || sess->server == serv)
            [sess->gui->cw performSelector:sel];
    }
}

+ (void) forEachSessionOnServer:(struct server *) serv
		performSelector:(SEL) sel
		     withObject:(id) obj
{
    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
        if (!serv || sess->server == serv)
            [sess->gui->cw performSelector:sel withObject:obj];
    }
}

- (void) setup_menu_prefs
{
    menu_pref tmp_prefs [] = 
    {
        { invisible_menu, &prefs.invisible },
        { receive_notices_menu, &prefs.servernotice },
        { receive_wallops_menu, &prefs.wallops },
    };
    
    for (unsigned int i = 0; i < sizeof (menu_prefs) / sizeof (menu_prefs [0]); i ++)
    {
		menu_prefs [i] = tmp_prefs [i];
        menu_pref *pref = &menu_prefs [i];
        [pref->menu setState:*pref->pref ? NSOnState : NSOffState];
        [pref->menu setTag:i];
    }
}

- (NSDictionary *) registrationDictionaryForGrowl
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSArray arrayWithObjects:@"X-Chat", NULL], GROWL_NOTIFICATIONS_ALL,
		[NSArray arrayWithObjects:@"X-Chat", NULL], GROWL_NOTIFICATIONS_DEFAULT,
		NULL];
}

- (void) load_event_info
{
    NSString *fn = [NSString stringWithFormat:@"%s/xcaevents.conf", get_xdir_fs ()];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fn];

    if (!dict)
    	return;
	
    for (int i = 0; i < NUM_XP; i++)
    {
        EventInfo *event = &text_event_info[i];
		char *name = te[i].name;

		id gval = [dict objectForKey:[NSString stringWithFormat:@"%s_growl", name]];
		id sval = [dict objectForKey:[NSString stringWithFormat:@"%s_show", name]];
		id bval = [dict objectForKey:[NSString stringWithFormat:@"%s_bounce", name]];
		
		if (gval)
			event->growl = [gval intValue];
		if (sval)
			event->show = [sval intValue];
		if (bval)
			event->bounce = [bval intValue];
	}
}

- (void) save_event_info
{	
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:NUM_XP];
    for (int i = 0; i < NUM_XP; i++)
    {
        EventInfo *event = &text_event_info[i];
		char *name = te[i].name;
		
		if (event->growl)
		{
			[dict setObject:[NSNumber numberWithInt:event->growl]
			 forKey:[NSString stringWithFormat:@"%s_growl", name]];
		}
		if (event->show)
		{
			[dict setObject:[NSNumber numberWithInt:event->show]
			 forKey:[NSString stringWithFormat:@"%s_show", name]];
		}
		if (event->bounce)
		{
			[dict setObject:[NSNumber numberWithInt:event->bounce]
			 forKey:[NSString stringWithFormat:@"%s_bounce", name]];
		}
		
    }
    NSString *fn = [NSString stringWithFormat:@"%s/xcaevents.conf", get_xdir_fs ()];
    [dict writeToFile:fn atomically:true];
}

- (void) awakeFromNib
{
    aquachat = self;
    
	[GrowlApplicationBridge setGrowlDelegate:self];
	
	[self load_event_info];
	
    my_image = [[NSApp applicationIconImage] copyWithZone:NULL];
    NSImage *msg_badge = [NSImage imageNamed:@"warning.tiff"];
    alert_image = [my_image copyWithZone:NULL];
    NSSize sz = [alert_image size];
    NSSize sz2 = [msg_badge size];
    [alert_image lockFocus];
    [msg_badge compositeToPoint:NSMakePoint (sz.width - sz2.width,
                                             sz.height - sz2.height) 
                      operation:NSCompositeSourceOver 
                       fraction:1];
    [alert_image unlockFocus];

    self->sound_cache = [[NSMutableDictionary dictionaryWithCapacity:0] retain];
    
    self->server_list = NULL;

    self->user_commands = NULL;
    self->ctcp_replies = NULL;
    self->userlist_buttons = NULL;
    self->userlist_popup = NULL;
    self->dialog_buttons = NULL;
    self->replace_popup = NULL;
    self->url_handlers = NULL;
    self->user_menus = NULL;
    self->edit_events = NULL;

    self->dcc_send_window = NULL;
    self->dcc_recv_window = NULL;
    self->dcc_chat_window = NULL;
    self->url_grabber = NULL;
    self->notify_list = NULL;
    self->ignore_window = NULL;
    self->ascii_window = NULL;
    self->plugin_list_win = NULL;

    self->search_string = NULL;
    
    self->font = NULL;
    self->bold_font = NULL;
    
    self->palette = [[ColorPalette alloc] init];
    [self->palette load];

    [self setup_menu_prefs];
    
    // See comment in prefsChanged
    [TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];
    
    [self prefsChanged];
    
    [NSApp requestEvents:NSKeyDown forWindow:NULL forView:NULL
        selector:@selector (myKeyDown:) object:self];
}

+ (AquaChat *) sharedAquaChat
{
    return aquachat;
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
        
    unsigned num = text [0] - '1';
    
    return [TabOrWindowView selectTab:num];
}

- (void) do_prefs:(id) sender
{
	if (!prefs_controller)
		prefs_controller = [[PrefsController alloc] init];
	[prefs_controller show];
}

- (void) do_release_notes:(id) sender
{
	if(!release_notes_window)
		release_notes_window=[[ReleaseNotesWindow alloc] init];
	[release_notes_window show];
}

- (void) do_goto_download:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://sourceforge.net/project/showfiles.php?group_id=62257"]];
}

//TODO sparkle here
- (void) new_version_alert
{
    bool ok = [SGAlert confirmWithString:NSLocalizedStringFromTable(@"There is a new version of X-Chat aqua available for download.  Press OK to visit the download site.", @"xchataqua", "")];
    if (ok)
        [self do_goto_download:self];
}

- (void) post_init
{
    [NSApp setDelegate:self];
    
    // Can't do this in awakeFromNib.. lists are not yet loaded..
    [self usermenu_update];
	
	[AutoAwayController start];
}
    
- (void) cleanup
{
    [palette save];
	[self save_event_info];
}

- (void) set_font:(const char *) font_name
{
    NSFont *f = NULL;
    
    // "Font Name <space> Font Size"
    const char *space = strrchr (font_name, ' ');
    if (space)
    {
        float sz = atof (space + 1);
        if (sz)
        {
            NSString *nm = [[NSString alloc] initWithBytes:prefs.font_normal
													length:space - font_name
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
    [self->bold_font release];
    
    self->font = [[fontManager convertFont:f toHaveTrait:NSUnboldFontMask] retain];
    self->bold_font = [[fontManager convertFont:f toHaveTrait:NSBoldFontMask] retain];

    if (!self->font)
        self->font = [f retain];
    if (!self->bold_font)
        self->bold_font = [f retain];
    
    sprintf (prefs.font_normal, "%s %.1f", [[font fontName] UTF8String], [font pointSize]);
}

- (NSFont *) getFont
{
    return font;
}

- (NSFont *) getBoldFont
{
    return bold_font;
}

- (ColorPalette *) getPalette
{
    return palette;
}

- (void) setPalette:(ColorPalette *) new_palette
{
    [palette release];
    palette = [new_palette retain];
}

- (void) prefsChanged
{
    [self set_font:prefs.font_normal];

    [TabOrWindowView prefsChanged];

    // This is a real-time pref.. it's already set when we get here.. we just need to make
    // sure it get's set at startup too.
    //[TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];

    if (prefs.autodccsend == 1 && !strcasecmp ((char *)g_get_home_dir (), prefs.dccdir))
    {
         [SGAlert alertWithString:NSLocalizedStringFromTable(@"*WARNING*\nAuto accepting DCC to your home directory\ncan be dangerous and is exploitable. Eg:\nSomeone could send you a .bash_profile", @"xchat", @"") andWait:false];
    }

    // Fix existing windows

    for (GSList *list = sess_list; list; list = list->next)
    {
        struct session *sess = (struct session *) list->data;
		[sess->gui->cw prefsChanged];
    }
    
	// Tab key shortcuts
	[prev_window_menu setKeyEquivalent:SRStringForKeyCode(prefs.tab_left_key)];
	[prev_window_menu setKeyEquivalentModifierMask:prefs.tab_left_modifiers];

	[next_window_menu setKeyEquivalent:SRStringForKeyCode(prefs.tab_right_key)];
	[next_window_menu setKeyEquivalentModifierMask:prefs.tab_right_modifiers];
	
    if (prefs.identd)
        identd_start ();
    else
        identd_stop ();
}

- (void) do_online_docs:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://xchataqua.sourceforge.net/docs/"]];
}

- (void) do_homepage:(id) sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://xchataqua.sourceforge.net/"]];
}

- (void) do_load_plugin:(id) sender
{
    NSString *f = [SGFileSelection selectWithWindow:NULL inDir:@"Plugins"];
    if (f)
    {
        NSString *cmd = [NSString stringWithFormat:@"LOAD \"%@\"", f];
        handle_command (current_sess, (char *) [cmd UTF8String], FALSE);
    }
}

- (void) pluginlist_update
{
    if (plugin_list_win)
        [plugin_list_win update];
}

- (void) do_pluginlist:(id) sender
{
    if (!plugin_list_win)
        [[PluginList alloc] initWithSelfPtr:&plugin_list_win];
    [plugin_list_win show];
}

- (void) do_flush_buffer:(id) sender
{
    if (current_sess)
        [current_sess->gui->cw clear:0];
}

- (void) do_next_window:(id) sender
{
    [TabOrWindowView cycleWindow:1];
}

- (void) do_prev_window:(id) sender
{
    [TabOrWindowView cycleWindow:-1];
}

- (void) do_link_delink:(id) sender
{
    [TabOrWindowView link_delink];
}

- (void) do_close_menu:(id) sender
{
    [[NSApp keyWindow] performClose:sender];
}

- (void) usermenu_update
{
    while ([user_menu numberOfItems] > 2)
        [user_menu removeItemAtIndex:2];

	[[MenuMaker defaultMenuMaker] appendItemList:usermenu_list toMenu:user_menu withTarget:nil inSession:NULL];
}

- (void) set_away:(bool) is_away
{
    [away_menu_item setState:is_away ? NSOnState : NSOffState];
}

- (void) do_search_again:(id) sender
{
    if (search_string)
        [current_sess->gui->cw highlight:search_string];
}

- (void) do_search_buffer:(id) sender
{
    NSString *old_string = search_string;
    search_string =
        [[SGRequest requestWithString:NSLocalizedStringFromTable(@"XChat: Search", @"xchat", @"") defaultValue:search_string] retain];
    [old_string release];
    [self do_search_again:sender];
}

- (void) do_save_buffer:(id) sender
{
    NSString *fname = [SGFileSelection saveWithWindow:[current_sess->gui->cw window]];
    if (fname)
        [current_sess->gui->cw save_buffer:fname];
}

- (void) do_serverlist:(id) sender
{
    [self open_serverlist_for:current_sess];
}

- (void) open_serverlist_for:(session *) sess
{
	[ServerList show_for_session:sess];
}

- (void) add_url:(const char *) url
{
    if (url_grabber)
        [url_grabber add_url:url];
}

- (void) dcc_update:(struct DCC *) dcc
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

- (void) dcc_add:(struct DCC *) dcc
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

- (void) dcc_remove:(struct DCC *) dcc
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

- (unsigned) dcc_active_file_transfer_count
{
	GSList *list = dcc_list;
	int count = 0;

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

- (int) dcc_open_send_win:(bool) passive
{
    bool is_new = dcc_send_window != NULL;
    
    if (!dcc_send_window)
        dcc_send_window = [[DccSendWin alloc] init];
        
    [dcc_send_window show:!passive];
    
    return is_new;
}

- (int) dcc_open_recv_win:(bool) passive
{
    bool is_new = dcc_recv_window != NULL;

    if (!dcc_recv_window)
        dcc_recv_window = [[DccRecvWin alloc] init];
        
    [dcc_recv_window show:!passive];

    return is_new;
}

- (int) dcc_open_chat_win:(bool) passive
{
    bool is_new = dcc_chat_window != NULL;

    if (!dcc_chat_window)
        dcc_chat_window = [[DccChatWin alloc] init];
        
    [dcc_chat_window show:!passive];

    return is_new;
}

- (void) notify_list_update
{
    if (notify_list)
        [notify_list update];
}

- (void) ignore_update:(int) level
{
    if (ignore_window)
        [ignore_window update:level];
}

/* let's do it in the standard Cocoa way */
/*
- (void) do_quit_menu:(id) sender
{
	[[NSUserDefaults standardUserDefaults] synchronize];
    xchat_exit ();
}
*/

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)application
{
	NSApplicationTerminateReply reply = NSTerminateNow;
	unsigned active = [self dcc_active_file_transfer_count];
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
    unsigned count = [windows count];
	
    while (count--) {
        [[windows objectAtIndex:count] close];
    }
	
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	xchat_exit ();
}

- (void) do_away_button:(id) sender
{
    handle_command (current_sess, "away", FALSE);
}

- (void) do_channellist_window:(id) sender
{
    if (!current_sess->server->gui->clc)
        current_sess->server->gui->clc = 
            [[ChannelListWin alloc] initWithServer:current_sess->server];

    [current_sess->server->gui->clc show];
}

- (void) do_dcc_recv_window:(id) sender
{
    [self dcc_open_recv_win:false];
}

- (void) do_dcc_chat_window:(id) sender
{
    [self dcc_open_chat_win:false];
}

- (void) do_dcc_send_window:(id) sender
{
    [self dcc_open_send_win:false];
}

- (void) do_raw_log_window:(id) sender
{
    if (!current_sess->server->gui->rawlog)
        current_sess->server->gui->rawlog = [[RawLogWin alloc] 
                                                initWithServer:current_sess->server];
    [current_sess->server->gui->rawlog show];
}

- (void) do_url_grabber_window:(id) sender
{
    if (!url_grabber)
        [[UrlGrabberWin alloc] initWithObjPtr:&url_grabber];
    [url_grabber show];
}

- (void) do_notify_list_window:(id) sender
{
    if (!notify_list)
        [[NotifyListWin alloc] initWithSelfPtr:&notify_list];
    [notify_list show];
}

- (void) do_ignore_window:(id) sender
{
    if (!ignore_window)
        [[IgnoreListWin alloc] initWithSelfPtr:&ignore_window];
    [ignore_window show];
}

- (void) do_ban_list_window:(id) sender
{
	if (current_sess->type != SESS_CHANNEL)
		return;
    if (!current_sess->gui->ban_list)
        [[BanListWin alloc] initWithSelfPtr:&current_sess->gui->ban_list session:current_sess];
    [current_sess->gui->ban_list show];
}

- (void) do_ascii_window:(id) sender
{
    if (!ascii_window)
        [[AsciiWin alloc] initWithSelfPtr:&ascii_window];
    [ascii_window show];
}

- (void) do_new_server:(id) sender
{
    int old = prefs.tabchannels;
    prefs.tabchannels = sender == new_server_tab_menu;
    new_ircwindow (NULL, NULL, SESS_SERVER, true);
    prefs.tabchannels = old;
}

- (void) do_new_channel:(id) sender
{
    int old = prefs.tabchannels;
    prefs.tabchannels = sender == new_channel_tab_menu;
    new_ircwindow (current_sess->server, NULL, SESS_CHANNEL, true);
    prefs.tabchannels = old;
}

- (void) do_menu_toggle:(id) sender
{
    menu_pref *pref = &menu_prefs[[sender tag]];
    *pref->pref = !*pref->pref;
    [sender setState:*pref->pref ? NSOnState : NSOffState];
}

- (void) do_invisible_menu:(id) sender
{
    [self do_menu_toggle:sender];
    
    if (current_sess->server->connected)
    {
        if (prefs.invisible)
            tcp_sendf (current_sess->server, "MODE %s +i\r\n",
                                            current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -i\r\n",
                                            current_sess->server->nick);
    }
}

- (void) do_receive_server_notices_menu:(id) sender
{
    [self do_menu_toggle:sender];
    
    if (current_sess->server->connected)
    {
        if (prefs.servernotice)
            tcp_sendf (current_sess->server, "MODE %s +s\r\n",
                                            current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -s\r\n",
                                            current_sess->server->nick);
    }
}

- (void) do_receive_wallops_menu:(id) sender
{
    [self do_menu_toggle:sender];
   
    if (current_sess->server->connected)
    {
        if (prefs.wallops)
            tcp_sendf (current_sess->server, "MODE %s +w\r\n",
                                            current_sess->server->nick);
        else
            tcp_sendf (current_sess->server, "MODE %s -w\r\n",
                                            current_sess->server->nick);
    }
}

- (void) do_user_commands:(id) sender
{
    if (!user_commands)
        user_commands = [[UserCommands alloc] init];
    [user_commands show];
}

- (void) do_ctcp_replies:(id) sender
{
    if (!ctcp_replies)
        ctcp_replies = [[CtcpReplies alloc] init];
    [ctcp_replies show];
}

- (void) do_userlist_buttons:(id) sender
{
    if (!userlist_buttons)
        userlist_buttons = [[UserlistButtons alloc] init];
    [userlist_buttons show];
}

- (void) do_userlist_popup:(id) sender
{
    if (!userlist_popup)
        userlist_popup = [[UserlistPopup alloc] init];
    [userlist_popup show];
}

- (void) do_dialog_buttons:(id) sender
{
    if (!dialog_buttons)
        dialog_buttons = [[DialogButtons alloc] init];
    [dialog_buttons show];
}

- (void) do_replace_popup:(id) sender
{
    if (!replace_popup)
        replace_popup = [[ReplacePopup alloc] init];
    [replace_popup show];
}

- (void) do_url_handlers:(id) sender
{
    if (!url_handlers)
        url_handlers = [[UrlHandlers alloc] init];
    [url_handlers show];
}

- (void) do_edit_user_menu:(id) sender
{
    if (!user_menus)
        user_menus = [[UserMenus alloc] init];
    [user_menus show];
}

- (void) do_edit_events_menu:(id) sender
{
    if (!edit_events)
        edit_events = [[EditEvents alloc] init];
    [edit_events show];
}

- (void) do_log_viewer:(id) sender
{
    if (!log_viewer)
        log_viewer = [[LogViewer alloc] init];
    [log_viewer show];
}

- (void) play_wave:(const char *) fname
{
    NSString *key = [NSString stringWithUTF8String:fname];
    NSSound *s = [sound_cache objectForKey:key];
    
    if (!s)
    {
        NSString *path;
        
        if ([key characterAtIndex:0] != '/')
        {
            NSString *bundle = [[NSBundle mainBundle] bundlePath];
            path = [NSString stringWithFormat:@"%@/../Sounds/%@", bundle, key];
        }
        else
            path = key;
        s = [[[NSSound alloc] initWithContentsOfFile:path byReference:false] autorelease];
        if (!s)
            return;
        [sound_cache setObject:s forKey:key];
        [s setName:path];
    }

    if (![s isPlaying])
        [s play];
}

- (void) applicationDidBecomeActive:(NSNotification *) aNotification
{
    [NSApp setApplicationIconImage:my_image];
}

- (void) event:(int) event
	      args:(char **) args
	   session:(session *) sess
{
	EventInfo *info = text_event_info + event;
	bool bg = ![NSApp isActive];
	
	// Pref can be
	//	0 - Don't do it
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
			char *x = strip_color (o, -1, STRIP_ALL);
			[GrowlApplicationBridge
			   notifyWithTitle:[NSString stringWithUTF8String:te[event].name]
				description:[NSString stringWithUTF8String:x]
				notificationName:@"X-Chat"
				iconData:nil
				priority:0
				isSticky:NO
				clickContext:nil];
			free (x);
		}
	}
	
	if (info->bounce && (info->bounce == -1 || bg))
	{
		[NSApp requestUserAttention:NSInformationalRequest];
	}
	
	if (info->show && (info->show == -1 || bg))
	{
		[NSApp setApplicationIconImage:alert_image];
	}
}

- (void) growl:(const char *)text
{
	[self growl:text title:0];
}

- (void) growl:(const char * )text title:(const char*)title
{
	[GrowlApplicationBridge
	 notifyWithTitle:[NSString stringWithUTF8String:(title!=0 ? title : "X-Chat Aqua")]
	 description:[NSString stringWithUTF8String:text]
	 notificationName:@"X-Chat"
	 iconData:nil
	 priority:0
	 isSticky:NO
	 clickContext:nil];
	
}

- (void) ctrl_gui:(session *) sess action:(int) action arg:(int) arg
{
    switch (action)
    {
        case 0:
            [[sess->gui->cw window] orderOut:self]; break;
        case 1:
            [[sess->gui->cw window] orderFront:self]; break;
        case 2:
            [[sess->gui->cw window] orderFront:self]; break;
        case 3:
            /*[[sess->gui->cw set_tab_color (sess, -1, TRUE);*/ break; /* flash */
        case 4:
            [sess->gui->cw set_tab_color:arg flash:false]; break;
        case 5:
            [[sess->gui->cw window] miniaturize:self]; break;
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

- (void) applicationDidFinishLaunching:(NSNotification *) notification
{ 
	//if (self = [super init]) 
	{ 
		NSNotificationCenter *center = [[NSWorkspace sharedWorkspace] notificationCenter];
 
		[center addObserver: self
				selector: @selector(workspaceWillSleep:)
				name: NSWorkspaceWillSleepNotification
				object: nil];
 
		[center addObserver: self
				selector: @selector(workspaceDidWake:)
				name: NSWorkspaceDidWakeNotification
				object: nil];
	}
}

- (void) workspaceWillSleep: (NSNotification *) notification
{
	if (!prefs.partonsleep)
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
			serv->p_quit (serv, prefs.sleepmessage);
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

@end

//////// Scripting crap

@interface OpenURLCommand : NSScriptCommand { }

- (id) performDefaultImplementation;

@end

@implementation OpenURLCommand

- (id) performDefaultImplementation 
{
	const char *newstr = "new";
	
	// If we don't have any windows, we need to create 1 now, else the
	// handle_command() is a no-op.  In that case, we don't need /newserver
    if (!sess_list)
	{
        new_ircwindow (NULL, NULL, SESS_SERVER, true);
		newstr = "";
	}

    NSString *urlString = [self directParameter];
    if (!urlString)
        return nil;
    char buff [128];
    snprintf (buff, sizeof (buff), "%sserver %s", newstr, [urlString UTF8String]);
    handle_command (current_sess, buff, 0);
    return nil;
}

@end
