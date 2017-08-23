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

#define FE_TRACKING 0

#import <unistd.h>

#undef TYPE_BOOL
#include "fe.h"
#include "cfgfiles.h"
#include "xchatc.h"
#include "util.h"
#include "plugin.h"
#include "xchat-plugin.h"
#include "text.h"
#include "servlist.h"
#include "outbound.h"

#import "fe-iphone_common.h"
#import "fe-iphone_utility.h"

#import "AppDelegate.h"
#import "MainViewController.h"
#import "ChatViewController.h"
#import "UserListView.h"
#import "RawLogViewController.h"

#include "iOS/Plugins/internal/bundle_loader_plugin.h"

static NSAutoreleasePool *initPool;
static int argc;
static char **argv;

extern struct text_event te[];

/////////////////////////////////////////////////////////////////////////////

#define APPLESCRIPT_HELP "Usage: APPLESCRIPT [-o] <script>"
#define BROWSER_HELP "Usage: BROWSER [browser] <url>"

static xchat_plugin *my_plugin_handle;

static NSString *fix_url (const char *url)
{
	NSString *ret = @(url);
	
	SGRegex *regex = [SGRegex
		regexWithString:@"(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
		nSubExpr:2];
	
	if (![regex doitWithUTF8String:url])
		return ret;
	
	NSString *scheme = [regex getNthMatch:1];
	
	// Any URL with a protocol is considered good
	if ([scheme length])
		return ret;

	// If we have an '@', then it's probably an email address
	// URLs with ftp in their name are probably ftp://
	// Else, just assume http://
	if (strchr (url, '@'))
		scheme = @"mailto:";
	else if (strncasecmp (url, "ftp.", 4) == 0)
		scheme = @"ftp://";
	else
		scheme = @"http://";
		
	return [NSString stringWithFormat:@"%@%@", scheme, ret];
}

static int
event_cb (char *word[], void *cbd)
{
	int event = (int) (size_t)cbd;
	struct session *sess = (struct session *) xchat_get_context(my_plugin_handle);
	NSLog(@"event?");
	//[[AquaChat sharedAquaChat] event:event args:word session:sess];
	return XCHAT_EAT_NONE;
}

/////////////////////////////////////////////////////////////////////////////

@interface ConfirmObject : NSObject
{
  @public
	void (*yesproc)(void *);
	void (*noproc)(void *);
	void *ud;
}
@end

@implementation ConfirmObject

- (void) do_yes
{
	yesproc (ud);
	[self release];
}

- (void) do_no
{
	noproc (ud);
	[self release];
}

@end

void
confirm_wrapper (const char *message, void (*yesproc)(void *), void (*noproc)(void *), void *ud)
{
	ConfirmObject *o = [[ConfirmObject alloc] init];
	o->yesproc = yesproc;
	o->noproc = noproc;
	o->ud = ud;
	/*
	[SGAlert confirmWithString:[NSString stringWithUTF8String:message]
						inform:o
						yesSel:@selector (do_yes)
						 noSel:@selector (do_no)];
	 */
}

/////////////////////////////////////////////////////////////////////////////

static void
one_time_work_phase2()
{
	static bool done;
	if (done)
		return;

	plugin_add (current_sess, NULL, NULL, (void *) bundle_loader_init, NULL, NULL, FALSE);

	// TODO: Disable the version check here if the user has set that preference.
	/*
	if (prefs.xa_checkvers)
	{
	}
	*/

	done = true;
}

void
fe_new_window (struct session *sess, int focus)
{
	dlog(FE_TRACKING, @"fe_new_window session: %p focus: %d", sess, focus);
	
	sess->gui = (struct session_gui *) malloc (sizeof (struct session_gui));
	sess->gui->chatViewController = [ChatViewController viewControllerForSession:sess];
	[[ApplicationDelegate mainViewController] addGroupItemForUtility:sess->gui->chatViewController];

	if (!current_sess)
		current_sess = sess;
		
	if (focus) {
		[[ApplicationDelegate mainViewController] makeKeyView:sess->gui->chatViewController];
	}

	// XChat waits until a session is created before installing plugins.. we
	// do the same thing..

	one_time_work_phase2 ();
}

void
fe_print_text (struct session *sess, const char *text, time_t stamp)
{
	dlog(FE_TRACKING, @"fe_print_text session: %p timestamp: %d text: %s", sess, stamp, text);
	[sess->gui->chatViewController printText:@(text) stamp:stamp];
}

void
fe_timeout_remove (long tag)
{
	dlog(FE_TRACKING, @"fe_timeout_remove tag: %d", tag);
#if USE_GLIKE_TIMER
	[GLikeTimer removeTimerWithTag:tag];
#else
	[TimerThing removeTimerWithTag:tag];
#endif
}

long
fe_timeout_add (long interval, void *callback, void *userdata)
{
	int tag;	
#if USE_GLIKE_TIMER
	tag = [GLikeTimer addTaggedTimerWithMSInterval:interval callback:(GSourceFunc)callback userData:userdata];
#else
	TimerThing *timer = [[TimerThing timerFromInterval:interval 
		callback:(void *)callback userdata:userdata] retain];

	[timer schedule];

	tag = [timer tag];
#endif
	dlog(FE_TRACKING, @"fe_timeout_add return tag: %d interval: %d ...", tag, interval);
	return tag;
}

void
fe_idle_add (void *func, void *data)
{
	dlog(FE_TRACKING, @"fe_idle_add ...");
	fe_timeout_add (0, func, data);
}

void
fe_input_remove (long tag)
{
	dlog(FE_TRACKING, @"fe_input_remove tag: %d", tag);
	InputThing *thing = [InputThing findTagged:tag];
	[thing disable];
	[thing release];
}

int
fe_input_add (int sok, int flags, input_callback func, void *data)
{
	dlog(FE_TRACKING, @"fe_input_add sok: %x flags: %x ...", sok, flags);
	InputThing *thing = [[InputThing socketFromFD:sok 
											flags:flags 
											 func:(socket_callback)func 
											 data:data] retain];
	return [thing tag];
}


#include <sys/types.h>
#include <sys/stat.h>

/*
	Note about fileSystemRepresentation: use that method when passing pathnames to
	POSIX system calls. However, use UTF8String when passing pathnames to XChat
	functions, even those that take pathnames, because XChat does the conversion
	to fs encoding itself using glib calls.
*/

int
fe_args (int pargc, char *pargv[])
{
	dlog(FE_TRACKING, @"fe_args argc: %d", pargc);
	#if FE_TRACKING
	for ( int i = 1; i < pargc; i++ ) {
		dlog(FE_TRACKING, @"\targ%d: %s", i, pargv[i]);
	}
	#endif
	
	argc = pargc;
	argv = pargv;
	
	initPool = [[NSAutoreleasePool alloc] init];	

	xdir_fs = g_strdup_printf("%s/.xchat2", CSTR([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]));
	
	setlocale (LC_ALL, "");
#if ENABLE_NLS
    NSString *localePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/locale"];
    bindtextdomain (GETTEXT_PACKAGE, [localePath UTF8String]);
    bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    textdomain (GETTEXT_PACKAGE);
#endif
	
	// Find the default charset pref.. 
	// This is really gross but we need it really early!
	char buff [1024];
	sprintf (buff, "%s/xchat.conf", get_xdir_fs());
	FILE *f = fopen (buff, "r");
	if (f)
	{
		while (fgets (buff, sizeof (buff), f))
		{
			const char *k = strtok (buff, " =\n");
			const char *v = strtok (NULL, " =\n");
			if (strcmp (k, "default_charset") == 0)
			{
				if (v && v[0])  /* v can be NULL */
					setenv ("CHARSET", v, 1);
				break;
			}
		}
		fclose (f);
	}

	return -1;
}

static void fix_log_files_and_pref ()
{
	// Check for the change.. maybe some smart user did this already..
	if ([@(prefs.logmask) hasSuffix:@".txt"])
		return;

	// If logging is off, fix the pref and log files.
	// It's a little sneaky but is probably right for the vast majority ??
	// Else we probably should ask first.
	/* UIAlertView
	if (prefs.logging && ! [SGAlert confirmWithString:
		NSLocalizedStringFromTable(@"This version of X-Chat Aqua has spotlight searchable"
		@" log support but I have to change your log filename mask preference and rename your existing logs."
		@"  Do you want me to do that?", @"xchataqua", @"")])
	{
		return;
	}
	*/
	// Fix the logmask pref.  Chop off the extension.. no matter what it is.
	char *last_dot = strrchr (prefs.logmask, '.');
	if (last_dot)
		*last_dot = 0;
	// Append .txt.. spotlight will automatically index these files.
	strcat (prefs.logmask, ".txt");
	
	// Rename the existing log files
	NSString *dir = [NSString stringWithFormat:@"%s/xchatlogs", get_xdir_utf8 ()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
	
	for (NSString *fname = [enumerator nextObject]; fname != nil; fname = [enumerator nextObject] )
	{
		if ([fname hasPrefix:@"."] || [fname hasSuffix:@".txt"])
			continue;
		
		char buff [512];
		strncpy (buff, [fname UTF8String], sizeof(buff) - 1);
		buff [sizeof(buff) - 1] = 0;
		
		char *last_dot = strrchr (buff, '.');
		if (last_dot)
			*last_dot = 0;
		strcat (buff, ".txt");
		
		NSString *old_name = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_utf8(), fname];
		NSString *new_name = [NSString stringWithFormat:@"%s/xchatlogs/%s", get_xdir_utf8(), buff];
		
		rename ([old_name fileSystemRepresentation], [new_name fileSystemRepresentation]);
	}
}

void
fe_init (void)
{
	dlog(FE_TRACKING, @"fe_init");
#if USE_GLIKE_TIMER
	[GLikeTimer self];
#endif

	//arg_dont_autoconnect = true;
				
	NSString *bundle = [[NSBundle mainBundle] bundlePath];
	chdir ([[NSString stringWithFormat:@"%@/..", bundle] fileSystemRepresentation]);
}

#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>

static bool fix_field (char **field)
{
	if (*field && (*field)[0] == 0)
	{
		*field = NULL;
		return true;
	}
	return false;
}

static void USER_not_enough_parameters_bug ()
{
	// Remove empty fields in the server list.
	// This code correct a problem that X-Chat Aqua introduced into the server list file.
	// NOTE: Let the memory leak just in case the serverlist is open now
	
	bool found_any = false;
	
	for (GSList *list = network_list; list; list = list->next)
	{
		ircnet *net = (ircnet *) list->data;
		found_any |= fix_field (&net->command);
		found_any |= fix_field (&net->autojoin);
		found_any |= fix_field (&net->nick);
		found_any |= fix_field (&net->pass);
		found_any |= fix_field (&net->real);
		found_any |= fix_field (&net->user);
	}

	if (found_any)
		servlist_save();
}

void
fe_main (void)
{
	dlog(FE_TRACKING, @"fe_main start");
	
	USER_not_enough_parameters_bug ();
	
#if 0
	struct rlimit rlp;
	rlp.rlim_cur = RLIM_INFINITY;
	rlp.rlim_max = RLIM_INFINITY;
	setrlimit (RLIMIT_CORE, &rlp);
#endif

#if AQUACHAT_DEBUG
	NSSetUncaughtExceptionHandler (bar);
	[[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask: 127];
	//[[NSExceptionHandler defaultExceptionHandler] setExceptionHangingMask: NSHangOnEveryExceptionMask];
	
	NSZombieEnabled = true;
	NSDebugEnabled = true;
//	NSHangOnMallocError = true;
	NSHangOnUncaughtException = true;
	
	/* CL: many concrete instances of Foundation objects are actually CF objects, and are
	   not covered by NSZombieEnabled. To get them, set the CFZombieLevel environment
	   variable, and load libraries with the debug suffix (see executable settings). */
	putenv("CFZombieLevel=3");
	
#endif
	UIApplicationMain(argc, argv, nil, nil);
	//[[AquaChat sharedAquaChat] post_init];
	
	[initPool release];
	
	dlog(FE_TRACKING, @"fe_main end");
}

void
fe_exit (void)
{
	dlog(FE_TRACKING, @"fe_exit");
	exit (0);
}

void
fe_new_server (struct server *serv)
{
	dlog(FE_TRACKING, @"fe_new_server");
	
	static int server_num;
	
	//server_set_encoding (serv, prefs.xa_default_charset);
	
	serv->gui = (struct server_gui *) malloc (sizeof (struct server_gui));
	memset (serv->gui, 0, sizeof (*serv->gui));
	serv->gui->tabGroup = ++server_num;
}

void
fe_message (char *msg, int flags)
{
	dlog(FE_TRACKING, @"fe_message flags: %x msg:%s", flags, msg);
	// TODO Deal with FE_MSG_HASTITLE

	BOOL wait = (flags & FE_MSG_WAIT) != 0;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"XChat"
														message:@(msg)
													   delegate:nil
											  cancelButtonTitle:XCHATLSTR(@"OK")
											  otherButtonTitles:nil];
	[alertView show];
	[alertView release];
	/*
	if (flags & FE_MSG_INFO)
	{
		[SGAlert noticeWithString:[NSString stringWithUTF8String:msg] andWait:wait];
	}
	else if (flags & FE_MSG_WARN)
	{
		[SGAlert alertWithString:[NSString stringWithUTF8String:msg] andWait:wait];
	}
	else if (flags & FE_MSG_ERROR)
	{
		[SGAlert errorWithString:[NSString stringWithUTF8String:msg] andWait:wait];
	}*/
}

void
fe_get_int (char *msg, int def, void *callback, void *userdata)
{
	dlog(TRUE, @"fe_get_int def: %d msg: %s", def, msg);
	//NSString *s = [SGRequest requestWithString:[NSString stringWithUTF8String:msg]
	//					defaultValue:[NSString stringWithFormat:@"%d", def]];
	NSString *s = @"0"; // FIXME:
	int value = 0;
	int cancel = 1;
	
	if (s)
	{
		value = [s intValue];
		cancel = 0;
	}

	void (*cb) (int cancel, int value, void *user_data);
	cb = (void (*) (int cancel, int value, void *user_data)) callback;
	
	cb (cancel, value, userdata);
}

void
fe_get_str (char *msg, char *def, void *callback, void *userdata)
{
	dlog(TRUE, @"fe_get_int def: %s msg: %s", def, msg);
	//NSString *s = [SGRequest requestWithString:[NSString stringWithUTF8String:msg]
	//					defaultValue:[NSString stringWithUTF8String:def]];
	NSString *s = @"";
	char *value = NULL;
	int cancel = 1;
	
	if (s)
	{
		value = (char *) [s UTF8String];
		cancel = 0;
	}

	void (*cb) (int cancel, char *value, void *user_data);
	cb = (void (*) (int cancel, char *value, void *user_data)) callback;
	
	cb (cancel, value, userdata);
}

void
fe_close_window (struct session *sess)
{
	dlog(1, @"fe_close_window session: %p", sess);
	[[ApplicationDelegate mainViewController] removeGroupItemForUtility:sess->gui->chatViewController];
}

void
fe_beep (void)
{
	dlog(TRUE, @"fe_beep");
	//NSBeep ();
}

void
fe_add_rawlog (struct server *serv, const char *text, const ssize_t len, int outbound)
{
	dlog(FE_TRACKING, @"fe_add_rawlog serv: %p ...", serv);
	RawLogViewController *viewController = [RawLogViewController viewControllerIfExistsForSession:(struct session *)serv]; // fake pointer
	[viewController setServer:serv];
	[viewController printLog:text length:len outbound:outbound];
}

void
fe_set_topic (struct session *sess, char *topic, char *stripped_topic)
{
	dlog(1, @"fe_set_topic");
	//[sess->gui->chatWindow setTopic:topic];
}

void
fe_cleanup (void)
{
	dlog(1, @"fe_clean_up");
	//[[AquaChat sharedAquaChat] cleanup];
}

void
fe_set_hilight (struct session *sess)
{
	dlog(1, @"fe_set_hilight sess: %p", sess);
	//[sess->gui->chatWindow setHilight];
}

void
fe_update_mode_buttons (struct session *sess, char mode, char sign)
{
	dlog(1, @"set_update_mode_button sess: %p mode: %c sign: %c", sess, mode, sign);
	//[sess->gui->chatWindow modeButtons:mode sign:sign];
}

void
fe_update_channel_key (struct session *sess)
{
	dlog(1, @"fe_update_channel_key sess: %p", sess);
}

void
fe_update_channel_limit (struct session *sess)
{
	dlog(1, @"fe_update_channel_limit sess: %p", sess);
	//[sess->gui->chatWindow channelLimit];
}

int
fe_is_chanwindow (struct server *serv)
{
	dlog(1, @"fe_is_chanwindow serv: %p", serv);
	return 0; // FIXME:
	//return [UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] != nil;
}

void
fe_add_chan_list (struct server *serv, char *chan, char *users, char *topic)
{
	dlog(1, @"fe_add_chan_list serv: %p chan: %s users: %s topic: %s", serv, chan, users, topic);
	//[(ChannelWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] addChannelWithName:[NSString stringWithUTF8String:chan] numberOfUsers:[NSString stringWithUTF8String:users] topic:[NSString stringWithUTF8String:topic]];
}

void
fe_chan_list_end (struct server *serv)
{
	dlog(1, @"fe_chan_list_end serv: %p", serv);
	//	[(ChannelWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] refreshFinished];
}

int
fe_is_banwindow (struct session *sess)
{
	dlog(1, @"fe_is_banwindow session: %p");
	return 0;
	//return [UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] ? true : false;
}

void
fe_add_ban_list (struct session *sess, char *mask, char *who, char *when, int is_exemption)
{
	dlog(1, @"fe_add_ban_list session: %p mask: %s who: %s when: %s is_exemption: %d", sess, mask, who, when, is_exemption);
	//[(BanWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] addBanWithMask:[NSString stringWithUTF8String:mask] who:[NSString stringWithUTF8String:who] when:[NSString stringWithUTF8String:when] isExemption:is_exemption];
}	 
		  
void
fe_ban_list_end (struct session *sess, int is_exemption)
{
	dlog(1, @"fe_ban_list_end session: %p is_exemption: %d", sess, is_exemption);
	//[(BanWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] refreshFinished];
}

void
fe_notify_update (char *name)
{
	// fe_notify_update is used in 2 different ways.
	// 1.  With a user arg.  Presumably to {de}hilight in the userlist but fe-gtk has
	//	 this code commented out.  Ask Peter about this some day.  Either way, we
	//	 should probably do the same thing some day too.
	// 2.  With a NULL args.  Just update the notify list.

	dlog(1, @"fe_notify_update name: %s", name);
	//if (!name)
	//	[[AquaChat sharedAquaChat] updateFriendWindow];
}

void fe_notify_ask (char *name, char *networks)
{
	dlog(1, @"fe_notify_ask name: %s networks: %s", name, networks);
}

void
fe_text_clear (struct session *sess, int lines)
{
	dlog(FE_TRACKING, @"fe_text_clear session: %p lines: %d", sess, lines);
	[sess->gui->chatViewController clearText:lines];
}

void
fe_progressbar_start (struct session *sess)
{
	dlog(1, @"fe_progressbar_start session: %p", sess);
	//[sess->gui->chatWindow progressbarStart];
}

void
fe_progressbar_end (struct server *serv)
{
	dlog(1, @"fe_progressbar_end serv: %p", serv);
	//[AquaChat forEachSessionOnServer:serv performSelector:@selector (progressbarEnd)];
}

void
fe_userlist_insert (struct session *sess, struct User *newuser, long row, int selected)
{
	dlog(FE_TRACKING, @"fe_userlist_insert session: %p", sess);
	[sess->gui->userListView insertUser:newuser row:(NSInteger)row select:selected];
}

void fe_userlist_update (struct session *sess, struct User *user)
{
	dlog(1, @"fe_userlist_update session: %p user: %p", sess, user);
	[sess->gui->userListView updateUser:user];
}

int
fe_userlist_remove (struct session *sess, struct User *user)
{
	dlog(FE_TRACKING, @"fe_userlist_remove session: %p", sess);
	return (int)[sess->gui->userListView removeUser:user];
}

void
fe_userlist_move (struct session *sess, struct User *user, long new_row)
{
	dlog(FE_TRACKING, @"fe_userlist_move session: %p", sess);
	[sess->gui->userListView moveUser:user toRow:(NSInteger)new_row];
}

void
fe_userlist_numbers (struct session *sess)
{
	dlog(FE_TRACKING, @"fe_userlist_numbers session: %p", sess);
	[sess->gui->userListView updateStatus];
}

void
fe_userlist_clear (struct session *sess)
{
	dlog(FE_TRACKING, @"fe_userlist_clear session: %p", sess);
	[sess->gui->userListView removeAllUsers];
}

void
fe_dcc_add (struct DCC *dcc)
{
	NSLog(@"dcc add");
	//[[AquaChat sharedAquaChat] addDcc:dcc];
}

void
fe_dcc_update (struct DCC *dcc)
{
	NSLog(@"update dcc");
	//[[AquaChat sharedAquaChat] updateDcc:dcc];
}

void
fe_dcc_remove (struct DCC *dcc)
{
	NSLog(@"remove dcc");
	//[[AquaChat sharedAquaChat] removeDcc:dcc];
}

void
fe_clear_channel (struct session *sess)
{
	NSLog(@"clear channel");
	//[sess->gui->chatWindow clearChannel];
}

void
fe_session_callback (struct session *sess)
{
	NSLog(@"session callback");
	//[sess->gui->chatWindow release];
	//free (sess->gui);
	//sess->gui = NULL;
}

void
fe_server_callback (struct server *serv)
{
	NSLog(@"server callback");
	free (serv->gui);
	serv->gui = NULL;
}

void fe_url_add (const char *url)
{
	NSLog(@"add url");
	//[[AquaChat sharedAquaChat] addUrl:url];
}

void
fe_pluginlist_update (void)
{
	NSLog(@"plugin update");
	//[[AquaChat sharedAquaChat] updatePluginWindow];
}

void
fe_buttons_update (struct session *sess)
{
	NSLog(@"userlist buttons update");
	//[sess->gui->chatWindow setupUserlistButtons];
}

void
fe_dlgbuttons_update (struct session *sess)
{
	NSLog(@"dlg buttons update");
	//[sess->gui->chatWindow setupDialogButtons];
}

void
fe_set_channel (struct session *sess)
{
	dlog(1, @"fe_set_channel session: %p", sess);
	[sess->gui->chatViewController setChannel];
}

void
fe_set_title (struct session *sess)
{
	dlog(FE_TRACKING, @"fe_set_title session: %p", sess);
	[sess->gui->chatViewController setTitleBySession];
}

void
fe_set_nonchannel (struct session *sess, int state)
{
	dlog(1, @"fe_set_nonchannel session: %p", sess);
	[sess->gui->chatViewController setNonchannel];
}

void
fe_set_nick (struct server *serv, char *newnick)
{
	dlog(FE_TRACKING, @"fe_set_nick serv: %p newnick: %s", serv, newnick);
	[AppDelegate performSelector:@selector(setNickname:) withObject:@(newnick) forEachSessionOnServer:serv];
}

void
fe_change_nick (struct server *serv, char *nick, char *newnick)
{
	dlog(1, @"fe_change_nick serv: %p nick: %s newnick: %s", serv, nick, newnick);
	session *sess = find_dialog (serv, nick);
	if (sess)
	{
		safe_strcpy (sess->channel, newnick, NICKLEN);	// fe-gtk does this, but I don't
		fe_set_title (sess);				// think it's needed
	}
}

void
fe_ignore_update (int level)
{
	NSLog(@"ignore update");
	//[[AquaChat sharedAquaChat] updateIgnoreWindowForLevel:level];
}

int
fe_dcc_open_recv_win (int passive)
{
	NSLog(@"dcc recv");
	return 1;
	//return [[AquaChat sharedAquaChat] openDccReceiveWindowAndShow:!passive];
}

int
fe_dcc_open_send_win (int passive)
{
	NSLog(@"dcc send");
	return 1;
	//return [[AquaChat sharedAquaChat] openDccSendWindowAndShow:!passive];
}

int
fe_dcc_open_chat_win (int passive)
{
	NSLog(@"dcc chat");
	return 1;
	//return [[AquaChat sharedAquaChat] openDccChatWindowAndShow:!passive];
}

void
fe_lastlog (session * sess, session * lastlog_sess, char *sstr, gboolean regexp)
{
	NSLog(@"last log");
	//[sess->gui->chatWindow lastlogIntoWindow:lastlog_sess->gui->chatWindow key:sstr];
}

void
fe_set_lag (server * serv, long lag)
{
	// lag seems to be measured as tenths of seconds since the ping was sent.
	// -1 indicates that we sent a PING but we are stil waiting for the PING reply.

	if (lag == -1)
	{
		if (!serv->lag_sent)
			return;
		unsigned long nowtim = make_ping_time ();
		lag = (nowtim - serv->lag_sent) / 100000;
	}

	// Peter computes the lagmeter as a percentage of 4 seconds.
	
	float per = (float) lag / 40;
	if (per > 1.0)
		per = 1.0;

	[AppDelegate performSelector:@selector(setLag:) withObject:@(per) forEachSessionOnServer:serv];
}

void
fe_set_throttle (server *serv)
{
	[AppDelegate performSelector:@selector(setThrottle) forEachSessionOnServer:serv];
}

void
fe_set_away (server *serv)
{
	NSLog(@"set away");
	//if (serv == current_sess->server)
	//	[[AquaChat sharedAquaChat] toggleAwayToValue:serv->is_away];
}

void
fe_serverlist_open (session *sess)
{
	// We never allow the last session window to close, and thus we need to
	// always have a session window.  If the session list is empty at this
	// point, this must be at startup of XChat.  Open a session window now
	// so it appears under the server list.
	// We could create the window at fe_main, but then it would cover the 
	// serverlist which was created just before fe_main
	
	if (!sess_list)
		sess = new_ircwindow (NULL, NULL, SESS_SERVER, true);

	[ApplicationDelegate pushNetworkViewControllerForSession:sess];
}

extern void
fe_play_wave (const char *fname)
{
	NSLog(@"play wave");
	//[[AquaChat sharedAquaChat] playWaveNamed:fname];
}

void
fe_ctrl_gui (session *sess, fe_gui_action action, int arg)
{
	NSLog(@"ctrl gui");
	//[[AquaChat sharedAquaChat] ctrl_gui:sess action:action arg:arg];
}

void
fe_userlist_rehash (struct session *sess, struct User *user)
{
	dlog(FE_TRACKING, @"fe_userlist_rehash session: %p user: %p", sess, user);
	[sess->gui->userListView rehashUser:user];
}

void
fe_dcc_send_filereq (struct session *sess, char *nick, int maxcps, int passive)
{
	NSLog(@"dcc send");
	//NSString *s = [SGFileSelection selectWithWindow:[current_sess->gui->chatWindow window]];
	//if (s)
	//	dcc_send (sess, nick, (char *) [s UTF8String], maxcps, passive);
}

void fe_confirm (const char *message, void (*yesproc)(void *), void (*noproc)(void *), void *ud)
{
	dlog(FE_TRACKING, @"fe_confirm msg: %s", message);
	confirm_wrapper (message, yesproc, noproc, ud);
}

int
fe_gui_info (session *sess, int info_type)
{
	dlog(FE_TRACKING, @"fe_gui_info session: %p infotype: %d", sess, info_type);
	switch (info_type)
	{
		case 0: // window status
			//if (![[sess->gui->chatWindow window] isVisible])
			//return 2;	   // hidden (iconified or systray)

			if ([[sess->gui->chatViewController view] isEqual:[[[[ApplicationDelegate mainViewController] contentView] subviews] lastObject]] )
				return 1;	   // active/focused

			return 0;		   // normal (no keyboard focus or behind a window)
	}

	return -1;
}

char * fe_get_inputbox_contents (struct session *sess)
{
	dlog(FE_TRACKING, @"fe_get_inputbox_contents session: %p", sess);
	return (char *)CSTR([sess->gui->chatViewController inputText]);
}

void fe_set_inputbox_contents (struct session *sess, char *text)
{
	dlog(FE_TRACKING, @"fe_set_inputbox_contents session: %p text: %s", sess, text);
	[sess->gui->chatViewController setInputText:@(text)];
}

int fe_get_inputbox_cursor (struct session *sess)
{
	return [sess->gui->chatViewController inputTextPosition];
}

void fe_set_inputbox_cursor (struct session *sess, int delta, int pos)
{
	dlog(1, @"fe_set_inputbox_cursor session: %p delta: %d pos: %d", sess, delta, pos);
	//[sess->gui->chatViewController setInputTextPosition:pos delta:delta];
}

void fe_open_url (const char *url)
{
	dlog(FE_TRACKING, @"fe_open_url url: %s", url);
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@(url)]];
}

void fe_menu_del (menu_entry *me)
{
	dlog(1, @"fe_menu_del");
//	[[MenuMaker defaultMenuMaker] menu_del:me];
}

char * fe_menu_add (menu_entry *me)
{
	dlog(1, @"fe_menu_add");
	//[[MenuMaker defaultMenuMaker] menu_add:me];
	return me->label;
}

void fe_menu_update (menu_entry *me)
{
	dlog(1, @"fe_menu_update");
	//[[MenuMaker defaultMenuMaker] menu_update:me];
}

void fe_uselect (session *sess, char *word[], int do_clear, int scroll_to)
{
	dlog(1, @"fe_uselect session: %p ...", sess);
	[sess->gui->userListView userlistSelectNames:word clear:do_clear scrollTo:scroll_to];
}

void fe_server_event (server *serv, int type, int arg)
{
	dlog(1, @"fe_server_event serv: %p type: %d arg: %d", serv, type, arg);
	//[[AquaChat sharedAquaChat] server_event:serv event_type:type arg:arg];
}

void *fe_gui_info_ptr (session *sess, int info_type)
{
	dlog(1, @"fe_gui_info_ptr session: %p infotype: %d", sess, info_type);
	switch (info_type)
	{
		case 0:	/* native window pointer (for plugins) */ //?????
			return sess->gui->chatViewController;	// return the NSWindow *... it seems the closest thing to what GTK does, although I shudder to think what a plugin might want to do with it
	}
	return NULL;
}

void
fe_userlist_set_selected (struct session *sess)
{
	dlog(1, @"fe_userlist_set_selected session: %p", sess);
	//[sess->gui->chatWindow userlistSetSelected];
}

// This should be called fe_joind()!  Sending mail to peter.
// This function is supposed to bring up a join channels dialog box.
extern void
joind (int action, server *serv)
{
}

/* Xchat 2.8 */
#define NOT_IMPLEMENTED_FUNCTION(func) NSLog(@"%s not implemented", func)
void fe_set_color_paste (session *sess, int status)
{
	NOT_IMPLEMENTED_FUNCTION("fe_set_color_paste");
}

void fe_flash_window (struct session *sess)
{
	NOT_IMPLEMENTED_FUNCTION("fe_flash_window");
	//[[UIApplication sharedApplication] requestUserAttention:NSInformationalRequest];
}
void fe_get_file (const char *title, char *initial,
				  void (*callback) (void *userdata, char *file), void *userdata,
				  int flags)
{
	dlog(1, @"fe_get_file");
	//[SGFileSelection getFile:[NSString stringWithUTF8String:title]
	//				 initial:[NSString stringWithUTF8String:initial]
	//				callback:callback userdata:userdata flags:flags];
}

void fe_tray_set_flash (const char *filename1, const char *filename2, int timeout)
{
	NOT_IMPLEMENTED_FUNCTION("fe_tray_set_flash");
}
void fe_tray_set_file (const char *filename)
{
	NOT_IMPLEMENTED_FUNCTION("fe_tray_set_file");
}
void fe_tray_set_icon (feicon icon)
{
	NOT_IMPLEMENTED_FUNCTION("fe_tray_set_icon");
}
void fe_tray_set_tooltip (const char *text)
{
	NOT_IMPLEMENTED_FUNCTION("fe_tray_set_tooltip");
}
void fe_tray_set_balloon (const char *title, const char *text)
{
	NOT_IMPLEMENTED_FUNCTION("fe_tray_set_balloon");
}
