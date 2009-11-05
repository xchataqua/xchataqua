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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include <ctype.h>
#include <unistd.h>
#include <list>

extern "C" {
#undef TYPE_BOOL
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/util.h"
#include "../common/plugin.h"
#include "../common/xchat-plugin.h"
#include "../common/cfgfiles.h"
#include "../common/fe.h"
#include "../common/text.h"
#include "../common/servlist.h"
#include "../common/server.h"
#include "outbound.h"
#undef TYPE_BOOL
}

#import "aquachat.h"
#import "ChatWindow.h"
#import "ChannelListWin.h"
#import "BanListWin.h"
#import "RawLogWin.h"
#import "SG.h"
#import "MenuMaker.h"

#include "plugins/bundle_loader/bundle_loader_plugin.h"

static NSAutoreleasePool *initPool;

extern struct text_event te[];

/////////////////////////////////////////////////////////////////////////////

typedef int (*socket_callback) (void *source, int condition, void *user_data);

static std::list<id> input_list;
static int input_seq = 1;

@interface InputThing : NSObject
{
    SGFileDescriptor *rf;
    SGFileDescriptor *wf;
    SGFileDescriptor *ef;
    
    socket_callback  func;
    void	     *data;
    
    int		     tag;
}

+ (id) socketFromFD:(int) sok 
              flags:(int) the_flags 
               func:(socket_callback) the_func
               data:(void *) the_data;

+ (id)findTagged:(int)atag;

- (void)disable;
- (int)getTag;

@end

@implementation InputThing

+ (id) socketFromFD:(int) sok 
              flags:(int) the_flags
               func:(socket_callback) the_func
               data:(void *) the_data
{
    InputThing *thing = [[InputThing alloc] init];
    
    thing->func = the_func;
    thing->data = the_data;
    thing->rf = NULL;
    thing->wf = NULL;
    thing->ef = NULL;
    thing->tag = input_seq ++;
    
    if (the_flags & FIA_READ)
        thing->rf = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDRead
                        target:thing selector:@selector (doit:) withObject:NULL];
    if (the_flags & FIA_WRITE)
        thing->wf = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDWrite
                        target:thing selector:@selector (doit:) withObject:NULL];
    if (the_flags & FIA_EX)
        thing->ef = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDExcep
                        target:thing selector:@selector (doit:) withObject:NULL];
    
    input_list.push_back (thing);
    
    return [thing autorelease];
}

+ (id)findTagged:(int)atag
{
    for (std::list<id>::iterator iter = input_list.begin(); iter != input_list.end(); )
    {
        id athing = *iter++;
        if ([athing getTag] == atag)
            return athing;
    }
    return NULL;
}

- (void)dealloc
{
	if(rf)
		[rf release];
	if(wf)
		[wf release];
	if(ef)
		[ef release];
    input_list.remove (self);
    [super dealloc];
}

- (void)disable
{
    if (rf) [rf disable];
    if (wf) [wf disable];
    if (ef) [ef disable];
}

- (int)getTag
{
    return tag;
}

- (void)doit:(id)obj
{
    func (NULL, 0, data);
}

@end

/////////////////////////////////////////////////////////////////////////////

#define USE_GLIKE_TIMER 1
#if USE_GLIKE_TIMER
#import "GLikeTimer.h"
#else

typedef int (*timer_callback) (void *user_data);

static std::list<id> timer_list;
static int timer_seq = 1;

@interface TimerThing : NSObject
{
    NSTimeInterval interval;
    timer_callback callback;
    void *userdata;
    int tag;
    
    NSTimer *timer;
}

+ (id)timerFromInterval:(int)the_interval callback:(timer_callback)the_callback
            userdata:(void *)the_userdata;
+ (void)removeTimerWithTag:(int)atag;
- (int)getTag;
- (void)schedule;
- (void)invalidate;

@end

@implementation TimerThing

+ (id)timerFromInterval:(int)the_interval callback:(timer_callback)the_callback
            userdata:(void *)the_userdata
{
    TimerThing *thing = [[TimerThing alloc] init];

    thing->interval = (NSTimeInterval) the_interval / 1000;
    thing->callback = the_callback;
    thing->userdata = the_userdata;
    thing->tag = timer_seq ++;
    thing->timer = NULL;

    timer_list.push_back (thing);
    
    [thing schedule];

    return [thing autorelease];
}

+ (void)removeTimerWithTag:(int)atag
{
    for (std::list<id>::iterator iter = timer_list.begin(); iter != timer_list.end(); )
    {
        id atimer = *iter++;
        if ([atimer getTag] == atag)
        {
            TimerThing *timer = (TimerThing *) atimer;
            [timer invalidate];
            timer->callback = NULL;     // We'll use this to detect released
            [timer release];            // timers in [TimerThing fire]
            return;
        }
    }
}

- (void)dealloc
{    
    timer_list.remove (self);
    [self invalidate];
    [super dealloc];
    
    //printf ("TimerThing dealloc\n");
}

- (void)invalidate
{
    if (timer)
    {
        [timer invalidate];
        [timer release];
        timer = NULL;
    }
}

- (int)getTag
{
    return tag;
}

- (void)schedule
{
    timer = [[NSTimer scheduledTimerWithTimeInterval:(double) interval
                            target:self
                            selector:@selector(fire:)
                            userInfo:nil
                            repeats:NO
                            retainArgs:NO] retain];
}

- (void)fire:(id)userInfo
{
    [timer invalidate];
    [timer release];
    timer = NULL;
   
    [self retain];	// Retain ourselvs just in case he decides
    				// to release us in the callback.

    if (callback (userdata) == 0)
    {
    	// Only honour his request to destroy this timer only if
        // he did not already do it in the callback.  We NULL out
        // the callback when he removes a timer to signal us here
        // not to release.

        if (callback != NULL)
            [self release];
    }
    else
    {
        [self schedule];
    }

    [self release];
}

@end

#endif

/////////////////////////////////////////////////////////////////////////////

#define APPLESCRIPT_HELP "Usage: APPLESCRIPT [-o] <script>"
#define BROWSER_HELP "Usage: BROWSER [browser] <url>"

static xchat_plugin *my_plugin_handle;

static int
applescript_cb (char *word[], char *word_eol[], void *userdata)
{
    char *command = NULL;
    bool to_channel = false;
    
    if (!word [2][0])
    {
        PrintText (current_sess, APPLESCRIPT_HELP);
        return XCHAT_EAT_ALL;
    }
    
    if (strcmp (word [2], "-o") == 0)
    {
        if (!word [3][0])
        {
            PrintText (current_sess, APPLESCRIPT_HELP);
            return XCHAT_EAT_ALL;
        }
        
        command = word_eol [3];
        to_channel = true;
    }
    else
        command = word_eol [2];
    
    NSMutableString *script = [NSMutableString stringWithUTF8String:command];
    [script replaceOccurrencesOfString:@"\\n" withString:@"\n" 
        options:0 range:NSMakeRange(0, [script length])];
    NSAppleScript *s = [[[NSAppleScript alloc] initWithSource:script] autorelease];
    
    NSDictionary *errors = NULL;
    NSAppleEventDescriptor *d = [s executeAndReturnError:&errors];

    if (d)
    {
        const char *return_val = [[d stringValue] UTF8String];

        if (return_val)
        {
            if (to_channel)
                handle_multiline (current_sess, (char *) return_val, FALSE, TRUE);
            else
                PrintText (current_sess, (char *) return_val);
        }
    }
    else
        PrintText (current_sess, "Applescript Error\n");
    
    return XCHAT_EAT_ALL;
}

static NSString *fix_url (const char *url)
{
	NSString *ret = [NSString stringWithUTF8String:url];
	
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
browser_cb (char *word[], char *word_eol[], void *userdata)
{
    if (!word [2][0])
    {
        PrintText (current_sess, BROWSER_HELP);
        return XCHAT_EAT_ALL;
    }
    
	const char *browser = NULL;
	const char *url = NULL;
	
	if (word [3][0])
	{
		browser = word[2];
		url = word_eol[3];
	}
	else
	{
		url = word_eol[2];
	}

	NSString *new_url = fix_url (url);
    
	if (browser)
	{
		NSString *command =
			[NSString stringWithFormat:
				@"tell application \"%s\" to «event WWW!OURL» (\"%@\")", browser, new_url];
		NSAppleScript *s = [[[NSAppleScript alloc] initWithSource:command] autorelease];
		NSDictionary *errors = NULL;
		[s executeAndReturnError:&errors];
	}
	else
	{
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:new_url]];
	}
	
	return XCHAT_EAT_ALL;
}

static int
event_cb (char *word[], void *cbd)
{
	int event = (int) (size_t)cbd;
	session *sess = (session *) xchat_get_context(my_plugin_handle);
    [[AquaChat sharedAquaChat] event:event args:word session:sess];
	return XCHAT_EAT_NONE;
}

static int
my_plugin_init (xchat_plugin *plugin_handle, char **plugin_name,
                             char **plugin_desc, char **plugin_version, char *arg)
{
	/* we need to save this for use with any xchat_* functions */
	my_plugin_handle = plugin_handle;

	*plugin_name = "X-Chat Aqua Internal Plugin";
	*plugin_desc = "Does stuff";
	*plugin_version = "";

	xchat_hook_command (plugin_handle, "APPLESCRIPT", XCHAT_PRI_NORM, 
		applescript_cb, APPLESCRIPT_HELP, plugin_handle);

	xchat_hook_command (plugin_handle, "BROWSER", XCHAT_PRI_NORM, 
		browser_cb, BROWSER_HELP, plugin_handle);

	for (int i = 0; i < NUM_XP; i ++)
		xchat_hook_print (plugin_handle, te[i].name, XCHAT_PRI_NORM, event_cb, (void *) i);

	return 1;       /* return 1 for success */
}

/////////////////////////////////////////////////////////////////////////////

@interface confirm_obj : NSObject
{
  @public
    void (*yesproc)(void *);
    void (*noproc)(void *);
    void *ud;
}
@end

@implementation confirm_obj

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
    confirm_obj *o = [[confirm_obj alloc] init];
    o->yesproc = yesproc;
    o->noproc = noproc;
    o->ud = ud;
    [SGAlert confirmWithString:[NSString stringWithUTF8String:message]
                    inform:o
                   yes_sel:@selector (do_yes)
                    no_sel:@selector (do_no)];
}

/////////////////////////////////////////////////////////////////////////////

static void
one_time_work_phase2()
{
    static bool done;
    if (done)
		return;

	plugin_add (current_sess, NULL, NULL, (void *) my_plugin_init, NULL, NULL, FALSE);
    plugin_add (current_sess, NULL, NULL, (void *) bundle_loader_init, NULL, NULL, FALSE);

	// TODO: Disable the version check here if the user has set that preference.
	/*
	if (prefs.checkvers)
	{
	}
	*/

	done = true;
}

void
fe_new_window (struct session *sess, int focus)
{
    sess->gui = (session_gui *) malloc (sizeof (session_gui));
    sess->gui->cw = [[ChatWindow alloc] initWithSession:sess];
    sess->gui->ban_list = NULL;

	if (!current_sess)
		current_sess = sess;
		
	if (focus)
		[[sess->gui->cw view] makeKeyAndOrderFront:NULL];

    // XChat waits until a session is created before installing plugins.. we
    // do the same thing..

	one_time_work_phase2 ();
}

void
fe_print_text (struct session *sess, char *text, time_t stamp)
{
    [sess->gui->cw print_text:text stamp:stamp];
}

void
fe_timeout_remove (int tag)
{
#if USE_GLIKE_TIMER
	[GLikeTimer removeTimerWithTag:tag];
#else
    [TimerThing removeTimerWithTag:tag];
#endif
}

int
fe_timeout_add (int interval, void *callback, void *userdata)
{
#if USE_GLIKE_TIMER
	return [GLikeTimer addTaggedTimerWithMSInterval:interval callback:(GSourceFunc)callback userData:userdata];
#else
    TimerThing *timer = [[TimerThing timerFromInterval:interval 
        callback:(timer_callback)callback userdata:userdata] retain];

    [timer schedule];

    return [timer getTag];
#endif
}

void
fe_idle_add (void *func, void *data)
{
    fe_timeout_add (0, func, data);
}

void
fe_input_remove (int tag)
{
    InputThing *thing = [InputThing findTagged:tag];
    [thing disable];
    [thing release];
}

int
fe_input_add (int sok, int flags, void *func, void *data)
{
    InputThing *thing = [[InputThing socketFromFD:sok 
                                            flags:flags 
                                             func:(socket_callback)func 
                                             data:data] retain];
    return [thing getTag];
}

//					|  AS Dir Exists	|	!AS Dir Exists	  |
// ------------------------------------------------------------
// XC Dir Exists	|  (1) Error		|  (2) Move, Link	  |
// ------------------------------------------------------------
// !XC Dir Exists	|  (3)  Link		| (4) Mkdir AS, Link  |
// ------------------------------------------------------------
// XC Link Exists	|  (5)  Done		|  (6)    Mkdir		  |
// ------------------------------------------------------------
//
#include <sys/types.h>
#include <sys/stat.h>

/*
	Note about fileSystemRepresentation: use that method when passing pathnames to
	POSIX system calls. However, use UTF8String when passing pathnames to XChat
	functions, even those that take pathnames, because XChat does the conversion
	to fs encoding itself using glib calls.
*/

static void setupAppSupport ()
{
	NSString *asdir = [SGFileUtil findApplicationSupportFor:@"X-Chat Aqua"];
	NSString *xcdir = [NSString stringWithUTF8String:get_xdir_utf8()];
	
	bool xclink_exists = [SGFileUtil isSymLink:xcdir];	
	bool xcdir_exists = [SGFileUtil isDir:xcdir];
	bool asdir_exists = [SGFileUtil isDir:asdir];

	// State 1
	if (xcdir_exists && asdir_exists)
	{
		printf ("~/.xchat2 and ApplicationSupport/X-Chat Aqua!?");
		return;
	}

	// State 2
	if (xcdir_exists && !asdir_exists)
	{
		rename (get_xdir_utf8 (), [asdir fileSystemRepresentation]);
		symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
		return;
	}
		
	// State 3
	if (!xclink_exists && !xcdir_exists && asdir_exists)
	{
		symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
		return;
	}

	// State 4
	if (!xclink_exists && !xcdir_exists && !asdir_exists)
	{
		mkdir ([asdir fileSystemRepresentation], 0755);
		symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
		return;
	}
	
	// State 6
	if (xclink_exists && !asdir_exists)
	{
		mkdir ([asdir fileSystemRepresentation], 0755);
	}
}

int
fe_args (int argc, char *argv[])
{
	char buff [128];
	
    setlocale (LC_ALL, "");
#ifdef ENABLE_NLS
	sprintf(buff, "%s/locale", [[[NSBundle mainBundle] resourcePath] UTF8String]);
	bindtextdomain (GETTEXT_PACKAGE, buff);
	bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);
#endif
	// Find the default charset pref.. 
	// This is really gross but we need it really early!
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

    initPool = [[NSAutoreleasePool alloc] init];

	setupAppSupport();

    return -1;
}

static bool ends_with (const char *string, const char *ext)
{
    int s_len = strlen (string);
	int e_len = strlen (ext);
	if (e_len > s_len)
		return false;
    return strcasecmp (string + s_len - e_len, ext) == 0;
}

static void fix_log_files_and_pref ()
{
	// Check for the change.. maybe some smart user did this already..
	if (ends_with (prefs.logmask, ".txt"))
		return;

	// If logging is off, fix the pref and log files.
	// It's a little sneaky but is probably right for the vast majority ??
	// Else we probably should ask first.
	if (prefs.logging && ! [SGAlert confirmWithString:
		NSLocalizedStringFromTable(@"This version of X-Chat Aqua has spotlight searchable"
		@" log support but I have to change your log filename mask preference and rename your existing logs."
		@"  Do you want me to do that?", @"xchataqua", @"")])
	{
		return;
	}
	
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
    
    for (NSString *fname; fname = [enumerator nextObject]; )
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
    [SGApplication sharedApplication];
    [NSBundle loadNibNamed:@"MainMenu" owner:NSApp];

	// This is not just for debug.
#if !CLX_BUILD
    if (GetCurrentKeyModifiers () & (optionKey | rightOptionKey))
#endif
        arg_dont_autoconnect = true;
		        
    NSString *bundle = [[NSBundle mainBundle] bundlePath];
    chdir ([[NSString stringWithFormat:@"%@/..", bundle] fileSystemRepresentation]);
}

#import <Foundation/NSDebug.h>
#import <ExceptionHandling/NSExceptionHandler.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/resource.h>

#if AQUACHAT_DEBUG
static void bar (NSException *e)
{
    printf ("BAR!\n");
}
#endif

static bool fix_field (char *&field)
{
	if (field && field[0] == 0)
	{
		field = NULL;
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
		found_any |= fix_field (net->command);
		found_any |= fix_field (net->autojoin);
		found_any |= fix_field (net->nick);
		found_any |= fix_field (net->pass);
		found_any |= fix_field (net->real);
		found_any |= fix_field (net->user);
    }

	if (found_any)
		servlist_save();
}

void
fe_main (void)
{
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
//    NSHangOnMallocError = true;
    NSHangOnUncaughtException = true;
	
	/* CL: many concrete instances of Foundation objects are actually CF objects, and are
	   not covered by NSZombieEnabled. To get them, set the CFZombieLevel environment
	   variable, and load libraries with the debug suffix (see executable settings). */
	putenv("CFZombieLevel=3");
	
#endif

    [[AquaChat sharedAquaChat] post_init];
	
    [initPool release];
    [NSApp run];
}

void
fe_exit (void)
{
    exit (0);
}

void
fe_new_server (struct server *serv)
{
    static int server_num;
    
	//server_set_encoding (serv, prefs.default_charset);
	
    serv->gui = (server_gui *) malloc (sizeof (server_gui));
    memset (serv->gui, 0, sizeof (*serv->gui));
    serv->gui->tab_group = ++server_num;
}

void
fe_message (char *msg, int flags)
{
	// TODO Deal with FE_MSG_HASTITLE

	BOOL wait = (flags & FE_MSG_WAIT) != 0;
	
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
	}
}

void
fe_get_int (char *msg, int def, void *callback, void *userdata)
{
    NSString *s = [SGRequest requestWithString:[NSString stringWithUTF8String:msg]
                        defaultValue:[NSString stringWithFormat:@"%d", def]];
    
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
    NSString *s = [SGRequest requestWithString:[NSString stringWithUTF8String:msg]
                        defaultValue:[NSString stringWithUTF8String:def]];
    
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
    [sess->gui->cw close_window];
}

void
fe_beep (void)
{
    NSBeep ();
}

void
fe_add_rawlog (struct server *serv, char *text, int len, int outbound)
{
    if (serv->gui->rawlog)
        [serv->gui->rawlog log:text len:len outbound:outbound];
}

void
fe_set_topic (struct session *sess, char *topic, char *stripped_topic)
{
    [sess->gui->cw set_topic:topic];
}

void
fe_cleanup (void)
{
    [[AquaChat sharedAquaChat] cleanup];
}

void
fe_set_hilight (struct session *sess)
{
    [sess->gui->cw set_hilight];
}

void
fe_update_mode_buttons (struct session *sess, char mode, char sign)
{
    [sess->gui->cw mode_buttons:mode sign:sign];
}

void
fe_update_channel_key (struct session *sess)
{
    printf ("update channel key\n");
}

void
fe_update_channel_limit (struct session *sess)
{
    [sess->gui->cw channel_limit];
}

int
fe_is_chanwindow (struct server *serv)
{
    return serv->gui->clc != NULL;
}

void
fe_add_chan_list (struct server *serv, char *chan, char *users, char *topic)
{
    if (serv->gui->clc)
        [serv->gui->clc add_chan_list:chan users:users topic:topic];
}

void
fe_chan_list_end (struct server *serv)
{
    if (serv->gui->clc)
        [serv->gui->clc chan_list_end];
}

int
fe_is_banwindow (struct session *sess)
{
    return sess->gui->ban_list ? true : false;
}

void
fe_add_ban_list (struct session *sess, char *mask, char *who, char *when, int is_exemption)
{
    if (sess->gui->ban_list)
        [sess->gui->ban_list add_ban_list:mask who:who when:when is_exemption:is_exemption];
}     
          
void
fe_ban_list_end (struct session *sess, int is_exemption)
{
    if (sess->gui->ban_list)
        [sess->gui->ban_list ban_list_end];
}

void
fe_notify_update (char *name)
{
    // fe_notify_update is used in 2 different ways.
    // 1.  With a user arg.  Presumably to {de}hilight in the userlist but fe-gtk has
    //     this code commented out.  Ask Peter about this some day.  Either way, we
    //     should probably do the same thing some day too.
    // 2.  With a NULL args.  Just update the notify list.
 
    if (!name)
        [[AquaChat sharedAquaChat] notify_list_update];
}

void fe_notify_ask (char *name, char *networks)
{
    NSLog(@"Unimplemented function “fe_notify_ask”(%s, %s)", name, networks);
}

void
fe_text_clear (struct session *sess, int lines)
{
    [sess->gui->cw clear:lines];
}

void
fe_progressbar_start (struct session *sess)
{
    [sess->gui->cw progressbar_start];
}

void
fe_progressbar_end (struct server *serv)
{
    [AquaChat forEachSessionOnServer:serv
		     performSelector:@selector (progressbar_end)];
}

void
fe_userlist_insert (struct session *sess, struct User *newuser, int row, int selected)
{
    [sess->gui->cw userlist_insert:newuser row:row select:selected];
}

void fe_userlist_update (struct session *sess, struct User *user)
{
    [sess->gui->cw userlist_update:user];
}

int
fe_userlist_remove (struct session *sess, struct User *user)
{
    return [sess->gui->cw userlist_remove:user];
}

void
fe_userlist_move (struct session *sess, struct User *user, int new_row)
{
    [sess->gui->cw userlist_move:user row:new_row];
}

void
fe_userlist_numbers (struct session *sess)
{
    [sess->gui->cw userlist_numbers];
}

void
fe_userlist_clear (struct session *sess)
{
    [sess->gui->cw userlist_clear];
}

void
fe_dcc_add (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] dcc_add:dcc];
}

void
fe_dcc_update (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] dcc_update:dcc];
}

void
fe_dcc_remove (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] dcc_remove:dcc];
}

void
fe_clear_channel (struct session *sess)
{
    [sess->gui->cw clear_channel];
}

void
fe_session_callback (struct session *sess)
{
    [sess->gui->cw release];
    free (sess->gui);
    sess->gui = NULL;
}

void
fe_server_callback (struct server *serv)
{
    [serv->gui->clc release];
    [serv->gui->rawlog release];
    free (serv->gui);
    serv->gui = NULL;
}

void fe_url_add (const char *url)
{
    [[AquaChat sharedAquaChat] add_url:url];
}

void
fe_pluginlist_update (void)
{
    [[AquaChat sharedAquaChat] pluginlist_update];
}

void
fe_buttons_update (struct session *sess)
{
    [sess->gui->cw setup_userlist_buttons];
}

void
fe_dlgbuttons_update (struct session *sess)
{
    [sess->gui->cw setup_dialog_buttons];
}

void
fe_set_channel (struct session *sess)
{
    [sess->gui->cw set_channel];
}

void
fe_set_title (struct session *sess)
{
    [sess->gui->cw set_title];
}

void
fe_set_nonchannel (struct session *sess, int state)
{
    [sess->gui->cw set_nonchannel:state];
}

void
fe_set_nick (struct server *serv, char *newnick)
{
    [AquaChat forEachSessionOnServer:serv
		     performSelector:@selector (set_nick)];
}

void
fe_change_nick (struct server *serv, char *nick, char *newnick)
{
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
    [[AquaChat sharedAquaChat] ignore_update:level];
}

int
fe_dcc_open_recv_win (int passive)
{
    return [[AquaChat sharedAquaChat] dcc_open_recv_win:passive];
}

int
fe_dcc_open_send_win (int passive)
{
    return [[AquaChat sharedAquaChat] dcc_open_send_win:passive];
}

int
fe_dcc_open_chat_win (int passive)
{
    return [[AquaChat sharedAquaChat] dcc_open_chat_win:passive];
}

void
fe_lastlog (session * sess, session * lastlog_sess, char *sstr, gboolean regexp)
{
	[sess->gui->cw lastlogIntoWindow:lastlog_sess->gui->cw key:sstr];
}

void
fe_set_lag (server * serv, int lag)
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

    [AquaChat forEachSessionOnServer:serv
		     performSelector:@selector (set_lag:)
		     withObject:[NSNumber numberWithFloat:per]];
}

void
fe_set_throttle (server *serv)
{
    [AquaChat forEachSessionOnServer:serv
		     performSelector:@selector (set_throttle)];
}

void
fe_set_away (server *serv)
{
    if (serv == current_sess->server)
        [[AquaChat sharedAquaChat] set_away:serv->is_away];
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

    [[AquaChat sharedAquaChat] open_serverlist_for:sess];
}

extern "C" void
fe_play_wave (const char *fname)
{
    [[AquaChat sharedAquaChat] play_wave:fname];
}

void
fe_ctrl_gui (session *sess, fe_gui_action action, int arg)
{
    [[AquaChat sharedAquaChat] ctrl_gui:sess action:action arg:arg];
}

void
fe_userlist_rehash (struct session *sess, struct User *user)
{
    [sess->gui->cw userlist_rehash:user];
}

void
fe_dcc_send_filereq (struct session *sess, char *nick, int maxcps, int passive)
{
    NSString *s = [SGFileSelection selectWithWindow:[current_sess->gui->cw window]];
    if (s)
        dcc_send (sess, nick, (char *) [s UTF8String], maxcps, passive);
}

void fe_confirm (const char *message, void (*yesproc)(void *), void (*noproc)(void *), void *ud)
{
    confirm_wrapper (message, yesproc, noproc, ud);
}

int
fe_gui_info (session *sess, int info_type)
{
    switch (info_type)
    {
        case 0: // window status
            if (![[sess->gui->cw window] isVisible])
                return 2;       // hidden (iconified or systray)

            if ([[sess->gui->cw window] isKeyWindow])
                return 1;       // active/focused

            return 0;           // normal (no keyboard focus or behind a window)
    }

    return -1;
}

char * fe_get_inputbox_contents (struct session *sess)
{
	return (char *) [sess->gui->cw getInputText];
}

void fe_set_inputbox_contents (struct session *sess, char *text)
{
	[sess->gui->cw setInputText:text];
}

int fe_get_inputbox_cursor (struct session *sess)
{
	return [sess->gui->cw getInputTextPosition];
}

void fe_set_inputbox_cursor (struct session *sess, int delta, int pos)
{
	[sess->gui->cw setInputTextPosition:pos delta:delta];
}

void fe_open_url (const char *url)
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:[NSString stringWithUTF8String:url]]];
}

void fe_menu_del (menu_entry *me)
{
	[[MenuMaker defaultMenuMaker] menu_del:me];
}

char * fe_menu_add (menu_entry *me)
{
	[[MenuMaker defaultMenuMaker] menu_add:me];
	
	return me->label;
}

void fe_menu_update (menu_entry *me)
{
	[[MenuMaker defaultMenuMaker] menu_update:me];
}

void fe_uselect (session *sess, char *word[], int do_clear, int scroll_to)
{
    [sess->gui->cw userlist_select_names:word clear:do_clear scroll_to:scroll_to];
}

void fe_server_event (server *serv, int type, int arg)
{
	[[AquaChat sharedAquaChat] server_event:serv event_type:type arg:arg];
}

void *fe_gui_info_ptr (session *sess, int info_type)
{
	switch (info_type)
	{
		case 0:	/* native window pointer (for plugins) */
			return [sess->gui->cw window];	// return the NSWindow *... it seems the closest thing to what GTK does, although I shudder to think what a plugin might want to do with it
	}
	return NULL;
}

void
fe_userlist_set_selected (struct session *sess)
{
	[sess->gui->cw userlist_set_selected];
}

// This should be called fe_joind()!  Sending mail to peter.
// This function is supposed to bring up a join channels dialog box.
extern "C" void joind (int action, server *serv)
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
	[[NSApplication sharedApplication] requestUserAttention:NSInformationalRequest];
}
void fe_get_file (const char *title, char *initial,
				  void (*callback) (void *userdata, char *file), void *userdata,
				  int flags)
{
	[SGFileSelection getFile:title initial:initial callback:callback userdata:userdata flags:flags];
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
	[[AquaChat sharedAquaChat] growl:text];
}
void fe_tray_set_balloon (const char *title, const char *text)
{
	[[AquaChat sharedAquaChat] growl:text title:title];
}
