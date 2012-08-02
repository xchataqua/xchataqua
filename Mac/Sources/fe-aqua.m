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


#import <Carbon/Carbon.h>

#undef TYPE_BOOL
#include "cfgfiles.h"
#include "util.h"
#include "plugin.h"

#include "servlist.h"

#import "fe-aqua_utility.h"
#import "AquaChat.h"
#import "ChatViewController.h"
#import "ChannelWindow.h"
#import "BanWindow.h"
#import "RawLogWindow.h"
#import "MenuMaker.h"

#import "UtilityWindow.h"

#import "AquaPlugins.h"

static NSAutoreleasePool *initPool;

/////////////////////////////////////////////////////////////////////////////

static void init_plugins_once()
{
    static bool done;
    if (done)
        return;
    
    // if this is first runtime, install builtin plugins.
    NSString *supportDirectory = [SGFileUtility findApplicationSupportFor:@PRODUCT_NAME];
    const char *currentVersion = [[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"] UTF8String];
    #ifdef CONFIG_Azure
    if (strcmp(prefs.xa_builtin_plugins_version, "1.11") < 0 && currentVersion[0] == '1') {
        int result = system([[NSString stringWithFormat:@"/bin/rm -r '%@/plugins'", supportDirectory] UTF8String]);
        if (result == 0) {
            NSLog(@PRODUCT_NAME" removed auto-installed old libraries");
        }
    }
    #endif
    if (strcmp(prefs.xa_builtin_plugins_version, currentVersion) != 0) {
        system([[NSString stringWithFormat:@"mkdir '%@/plugins'", supportDirectory] UTF8String]);
        // install builtin plugins
        NSString *pack = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"plugins.tar"];
        int result = 0;
        if ([[NSFileManager defaultManager] fileExistsAtPath:pack]) {
            // install when embedded archive exists
            result = system([[NSString stringWithFormat:@"/usr/bin/tar xf '%@' -C '%@'", pack, supportDirectory] UTF8String]);
        }
        if (0 == result) {
            // save current version
            strcpy(prefs.xa_builtin_plugins_version, currentVersion);
        }
    }
    
    plugin_add (current_sess, NULL, NULL, (void *) XAInitInternalPlugin, NULL, NULL, FALSE);
    
    done = true;
}

void
fe_new_window (struct session *sess, int focus)
{
    sess->gui = (struct session_gui *) malloc (sizeof (struct session_gui));
    sess->gui->controller = [[ChatViewController alloc] initWithSession:sess];
    [sess->gui->controller view]; // force load views
    
    if (!current_sess)
        current_sess = sess;
    
    if (focus)
        [sess->gui->controller.chatView makeKeyAndOrderFront:nil];
    
    // XChat waits until a session is created before installing plugins.. we
    // do the same thing..
    
    init_plugins_once();
}

void
fe_print_text (struct session *sess, char *text, time_t stamp)
{
    NSString *string = [NSString stringWithUTF8String:text];
    if ( string == nil ) return;
    [sess->gui->controller printText:string stamp:stamp];
}

void
fe_timeout_remove (int tag)
{
#if USE_GLIKE_TIMER
    [GLikeTimer removeTimerWithTag:tag];
#else
    [[TimerThing timerForTag:tag] remove];
#endif
}

int
fe_timeout_add (int interval, void *callback, void *userdata)
{
#if USE_GLIKE_TIMER
    return [GLikeTimer addTaggedTimerWithMSInterval:interval callback:(GSourceFunc)callback userData:userdata];
#else
    TimerThing *timer = [TimerThing timerWithInterval:interval
                                             callback:(timer_callback)callback userdata:userdata];
    
    [timer schedule];
    
    return [timer tag];
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
    InputThing *thing = [InputThing inputForTag:tag];
    [thing disable];
    [thing remove];
}

int
fe_input_add (int sok, int flags, void *func, void *data)
{
    InputThing *thing = [InputThing inputWithSocketFD:sok flags:flags callback:(socket_callback)func data:data]; 
    return [thing tag];
}

//                  |   AS Dir Exists   |   !AS Dir Exists      |
// --------------------------------------------------------------
// XC Dir Exists    |   (1) Error       |   (2) Move, Link      |
// --------------------------------------------------------------
// !XC Dir Exists   |   (3) Link        |   (4) Mkdir AS, Link  |
// --------------------------------------------------------------
// XC Link Exists   |   (5) Done        |   (6) Mkdir           |
// --------------------------------------------------------------
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
    NSString *asdir = [SGFileUtility findApplicationSupportFor:@PRODUCT_NAME];
    NSString *xcdir = [NSString stringWithUTF8String:get_xdir_utf8()];
    
    bool xclink_exists = [SGFileUtility isSymLink:xcdir];    
    bool xcdir_exists = [SGFileUtility isDirectory:xcdir];
    bool asdir_exists = [SGFileUtility isDirectory:asdir];
    
    // State 1
    if (xcdir_exists && asdir_exists)
    {
        NSLog(@"~/.xchat2 and ApplicationSupport/XChat Azure!?");
        return;
    }
    
    // State 2
    if (xcdir_exists && !asdir_exists)
    {
        rename (get_xdir_utf8 (), [asdir fileSystemRepresentation]);
        #ifdef CONFIG_Aqua
        symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
        #endif
        return;
    }
    
    // State 3
    if (!xclink_exists && !xcdir_exists && asdir_exists)
    {
        #ifdef CONFIG_Aqua
        symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
        #endif
        return;
    }
    
    // State 4
    if (!xclink_exists && !xcdir_exists && !asdir_exists)
    {
        mkdir ([asdir fileSystemRepresentation], 0755);
        #ifdef CONFIG_Aqua
        symlink ([asdir fileSystemRepresentation], get_xdir_utf8 ());
        #endif
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
    initPool = [[NSAutoreleasePool alloc] init];    
    
    setlocale (LC_ALL, "");
#if ENABLE_NLS
    NSString *localePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/locale"];
    bindtextdomain (GETTEXT_PACKAGE, [localePath UTF8String]);
    bind_textdomain_codeset(GETTEXT_PACKAGE, "UTF-8");
    textdomain (GETTEXT_PACKAGE);
#endif
    
    // Find the default charset pref.. 
    // This is really gross but we need it really early!
    char buff[128];
    sprintf (buff, "%s/xchat.conf", get_xdir_fs());
    FILE *f = fopen (buff, "r");
    if (f)
    {
        while (fgets (buff, sizeof(buff), f))
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
    
    setupAppSupport();
    
    return -1;
}

static void fix_log_files_and_pref ()
{
    // Check for the change.. maybe some smart user did this already..
    if ([[NSString stringWithUTF8String:prefs.logmask] hasSuffix:@".txt"])
        return;
    
    // If logging is off, fix the pref and log files.
    // It's a little sneaky but is probably right for the vast majority ??
    // Else we probably should ask first.
    if (prefs.logging && ! [SGAlert confirmWithString:
                            NSLocalizedStringFromTable(@"This version of XChat Azure has spotlight searchable"
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
#if USE_GLIKE_TIMER
    [GLikeTimer self];
#endif
    [SGApplication sharedApplication];
    NSString *mainNibFile = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSMainNibFile"];
    [NSBundle loadNibNamed:mainNibFile owner:NSApp];
    
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

#if DEBUG
static void bar (NSException *e)
{
    printf ("BAR!\n");
}
#endif

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
    USER_not_enough_parameters_bug ();
    
#if 0
    struct rlimit rlp;
    rlp.rlim_cur = RLIM_INFINITY;
    rlp.rlim_max = RLIM_INFINITY;
    setrlimit (RLIMIT_CORE, &rlp);
#endif
    
#if DEBUG
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
    
    //server_set_encoding (serv, prefs.xa_default_charset);
    
    serv->gui = (struct server_gui *) malloc (sizeof (struct server_gui));
    memset (serv->gui, 0, sizeof (*serv->gui));
    serv->gui->tabGroup = ++server_num;
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
    NSString *s = [SGRequest stringByRequestWithTitle:[NSString stringWithUTF8String:msg]
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
    NSString *s = [SGRequest stringByRequestWithTitle:[NSString stringWithUTF8String:msg]
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
    [sess->gui->controller closeWindow];
}

void
fe_beep (void)
{
    NSBeep ();
}

void
fe_add_rawlog (struct server *serv, char *text, int len, int outbound)
{
    RawLogWindow *window = [UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(RawLogWindowKey, serv)];
    [window log:text length:len outbound:outbound];
}

void
fe_set_topic (struct session *sess, char *topic, char *stripped_topic)
{
    [sess->gui->controller setTopic:topic];
}

void
fe_cleanup (void)
{
    [[AquaChat sharedAquaChat] cleanup];
}

void
fe_set_hilight (struct session *sess)
{
    [sess->gui->controller setHilight];
}

void
fe_update_mode_buttons (struct session *sess, char mode, char sign)
{
    [sess->gui->controller modeButtons:mode sign:sign];
}

void
fe_update_channel_key (struct session *sess)
{
    printf ("update channel key\n");
}

void
fe_update_channel_limit (struct session *sess)
{
    [sess->gui->controller channelLimit];
}

int
fe_is_chanwindow (struct server *serv)
{
    return [UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] != nil;
}

void
fe_add_chan_list (struct server *serv, char *chan, char *users, char *topic)
{
    [(ChannelWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] addChannelWithName:[NSString stringWithUTF8String:chan] numberOfUsers:[NSString stringWithUTF8String:users] topic:[NSString stringWithUTF8String:topic]];
}

void
fe_chan_list_end (struct server *serv)
{
    [(ChannelWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(ChannelWindowKey, serv)] refreshFinished];
}

int
fe_is_banwindow (struct session *sess)
{
    return [UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] ? true : false;
}

void
fe_add_ban_list (struct session *sess, char *mask, char *who, char *when, int is_exemption)
{
    [(BanWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] addBanWithMask:[NSString stringWithUTF8String:mask] who:[NSString stringWithUTF8String:who] when:[NSString stringWithUTF8String:when] isExemption:is_exemption];
}     

void
fe_ban_list_end (struct session *sess, int is_exemption)
{
    [(BanWindow *)[UtilityTabOrWindowView utilityIfExistsByKey:UtilityWindowKey(BanWindowKey, sess)] refreshFinished];
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
        [[AquaChat sharedAquaChat] updateFriendWindow];
}

void fe_notify_ask (char *name, char *networks)
{
    NSLog(@"Unimplemented function “fe_notify_ask”(%s, %s)", name, networks);
}

void
fe_text_clear (struct session *sess, int lines)
{
    [sess->gui->controller clear];
}

void
fe_progressbar_start (struct session *sess)
{
    [sess->gui->controller progressbarStart];
}

void
fe_progressbar_end (struct server *serv)
{
    [AquaChat forEachSessionOnServer:serv performSelector:@selector (progressbarEnd)];
}

void
fe_userlist_insert (struct session *sess, struct User *newuser, int row, int selected)
{
    [sess->gui->controller userlistInsert:newuser row:(NSInteger)row select:selected];
}

void fe_userlist_update (struct session *sess, struct User *user)
{
    [sess->gui->controller userlistUpdate:user];
}

int
fe_userlist_remove (struct session *sess, struct User *user)
{
    return (int)[sess->gui->controller userlistRemove:user];
}

void
fe_userlist_move (struct session *sess, struct User *user, int new_row)
{
    [sess->gui->controller userlistMove:user row:(NSInteger)new_row];
}

void
fe_userlist_numbers (struct session *sess)
{
    [sess->gui->controller userlistNumbers];
}

void
fe_userlist_clear (struct session *sess)
{
    [sess->gui->controller userlistClear];
}

void
fe_dcc_add (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] addDcc:dcc];
}

void
fe_dcc_update (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] updateDcc:dcc];
}

void
fe_dcc_remove (struct DCC *dcc)
{
    [[AquaChat sharedAquaChat] removeDcc:dcc];
}

void
fe_clear_channel (struct session *sess)
{
    [sess->gui->controller clearChannel];
}

void
fe_session_callback (struct session *sess)
{
    [sess->gui->controller release];
    free (sess->gui);
    sess->gui = NULL;
}

void
fe_server_callback (struct server *serv)
{
    free (serv->gui);
    serv->gui = NULL;
}

void fe_url_add (const char *url)
{
    [[AquaChat sharedAquaChat] addUrl:url];
}

void
fe_pluginlist_update (void)
{
    [[AquaChat sharedAquaChat] updatePluginWindow];
}

void
fe_buttons_update (struct session *sess)
{
    [sess->gui->controller setupUserlistButtons];
}

void
fe_dlgbuttons_update (struct session *sess)
{
    [sess->gui->controller setupDialogButtons];
}

void
fe_set_channel (struct session *sess)
{
    [sess->gui->controller setChannel];
}

void
fe_set_title (struct session *sess)
{
    [sess->gui->controller setTitle];
}

void
fe_set_nonchannel (struct session *sess, int state)
{
    [sess->gui->controller setNonchannel:state];
}

void
fe_set_nick (struct server *serv, char *newnick)
{
    [AquaChat forEachSessionOnServer:serv
                     performSelector:@selector (setNick)];
}

void
fe_change_nick (struct server *serv, char *nick, char *newnick)
{
    session *sess = find_dialog (serv, nick);
    if (sess)
    {
        safe_strcpy (sess->channel, newnick, NICKLEN);    // fe-gtk does this, but I don't
        fe_set_title (sess);                // think it's needed
    }
}

void
fe_ignore_update (int level)
{
    [[AquaChat sharedAquaChat] updateIgnoreWindowForLevel:level];
}

int
fe_dcc_open_recv_win (int passive)
{
    return [[AquaChat sharedAquaChat] openDCCRecieveWindowAndShow:!passive];
}

int
fe_dcc_open_send_win (int passive)
{
    return [[AquaChat sharedAquaChat] openDCCSendWindowAndShow:!passive];
}

int
fe_dcc_open_chat_win (int passive)
{
    return [[AquaChat sharedAquaChat] openDCCChatWindowAndShow:!passive];
}

void
fe_lastlog (session * sess, session * lastlog_sess, char *sstr, gboolean regexp)
{
    [sess->gui->controller lastlogIntoWindow:lastlog_sess->gui->controller key:sstr];
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
                     performSelector:@selector (setLag:)
                          withObject:[NSNumber numberWithFloat:per]];
}

void
fe_set_throttle (server *serv)
{
    [AquaChat forEachSessionOnServer:serv performSelector:@selector (setThrottle)];
}

void
fe_set_away (server *serv)
{
    if (serv == current_sess->server)
        [[AquaChat sharedAquaChat] toggleAwayToValue:serv->is_away];
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
    
    [[AquaChat sharedAquaChat] openNetworkWindowForSession:sess];
}

extern void
fe_play_wave (const char *fname)
{
    [[AquaChat sharedAquaChat] playWaveNamed:fname];
}

void
fe_ctrl_gui (session *sess, fe_gui_action action, int arg)
{
    [[AquaChat sharedAquaChat] ctrl_gui:sess action:action arg:arg];
}

void
fe_userlist_rehash (struct session *sess, struct User *user)
{
    [sess->gui->controller userlistRehash:user];
}

void
fe_dcc_send_filereq (struct session *sess, char *nick, int maxcps, int passive)
{
    NSString *s = [SGFileSelection selectWithWindow:[current_sess->gui->controller window]].path;
    if (s)
        dcc_send (sess, nick, (char *) [s UTF8String], maxcps, passive);
}

void fe_confirm (const char *message, void (*yesproc)(void *), void (*noproc)(void *), void *ud)
{
    ConfirmObject *o = [[ConfirmObject alloc] init];
    o->yesproc = yesproc;
    o->noproc = noproc;
    o->ud = ud;
    [SGAlert confirmWithString:[NSString stringWithUTF8String:message]
                        inform:o
                        yesSel:@selector (do_yes)
                         noSel:@selector (do_no)];
    [o release];
}

int
fe_gui_info (session *sess, int info_type)
{
    switch (info_type)
    {
        case 0: // window status
            if (![[sess->gui->controller window] isVisible])
                return 2;       // hidden (iconified or systray)
            
            if ([[sess->gui->controller window] isKeyWindow])
                return 1;       // active/focused
            
            return 0;           // normal (no keyboard focus or behind a window)
    }
    
    return -1;
}

char * fe_get_inputbox_contents (struct session *sess)
{
    return (char *) [[sess->gui->controller inputText] UTF8String];
}

void fe_set_inputbox_contents (struct session *sess, char *text)
{
    [sess->gui->controller setInputText:[NSString stringWithUTF8String:text]];
}

int fe_get_inputbox_cursor (struct session *sess)
{
    return (int)[sess->gui->controller inputTextPosition];
}

void fe_set_inputbox_cursor (struct session *sess, int delta, int pos)
{
    [sess->gui->controller setInputTextPosition:pos delta:delta];
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
    [sess->gui->controller userlistSelectNames:word clear:do_clear scrollTo:scroll_to];
}

void fe_server_event (server *serv, int type, int arg)
{
    [[AquaChat sharedAquaChat] server_event:serv event_type:type arg:arg];
}

void *fe_gui_info_ptr (session *sess, int info_type)
{
    switch (info_type)
    {
        case 0:    /* native window pointer (for plugins) */
            return [sess->gui->controller window];    // return the NSWindow *... it seems the closest thing to what GTK does, although I shudder to think what a plugin might want to do with it
    }
    return NULL;
}

void
fe_userlist_set_selected (struct session *sess)
{
    [sess->gui->controller userlistSetSelected];
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
    [[NSApplication sharedApplication] requestUserAttention:NSCriticalRequest];
}
void fe_get_file (const char *title, char *initial,
                  void (*callback) (void *userdata, char *file), void *userdata,
                  int flags)
{
    [SGFileSelection getFile:[NSString stringWithUTF8String:title]
                     initial:[NSString stringWithUTF8String:initial]
                    callback:callback userdata:userdata flags:flags];
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
    [[AquaChat sharedAquaChat] growl:[NSString stringWithUTF8String:text] title:nil];
}
void fe_tray_set_balloon (const char *title, const char *text)
{
    [[AquaChat sharedAquaChat] growl:[NSString stringWithUTF8String:text] title:[NSString stringWithUTF8String:title]];
}
