/* X-Chat Aqua
 * Copyright (C) 2006 Steve Green
 * Copyright (C) 2010 Terje Bless
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


#import "AutoAwayController.h"

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/server.h"
}

@implementation AutoAwayController

@synthesize isAway;


- (void) setAway:(BOOL) away
{
    // Get list of current servers from xchat and set the user away (or
    // returned) on all connected server sessions.
  for (GSList *list = serv_list; list; list = list->next)
  {
    struct server *srv = (struct server *) list->data;

    if (!srv->connected)
      continue;

    if (away) {
      handle_command (srv->server_session, "away auto-away", false);
      self.isAway = YES;
    } else {
      handle_command (srv->server_session, "back", false);
      self.isAway = NO;
    }
  }
}

- (void) check_idle_time:(NSTimer *) theTimer
{
    // Uses the Quartz Event Services to find time since the last user action
    // (keyboard, mouse, etc. input). This is a bit hacky in that it's not
    // documented to be for the purpose of determining whether the user is idle,
    // and it requires a polling loop, but it serves the purpose well enough and
    // the system call is documented.
    //
    // Doc: http://developer.apple.com/mac/library/documentation/Carbon/Reference/QuartzEventServicesRef/Reference/reference.html
    //

    // Only poll if the auto-away preference is set.
  if (prefs.auto_away) {
    CFTimeInterval idleTime;
    NSTimeInterval interval;

      // Filters for any input event for the current login session.
    idleTime = CGEventSourceSecondsSinceLastEventType(
                                                      kCGEventSourceStateCombinedSessionState,
                                                      kCGAnyInputEventType
                                                      );

      // Delay pref is in minutes, idleTime in seconds.
    if (idleTime / 60 >= prefs.auto_away_delay) {
      if (!self.isAway) {
        [self setAway:YES];
      }
      interval = 1;
    } else {
      if (self.isAway) {
        [self setAway:NO];
      }
      interval = 10;
    }

      // Trigger another poll of the idle time on a timer.
      //
      // Every 1s when idle/away, every 10s otherwise. It's not important to
      // detect an idle user immediately, but when the user returns we should
      // detect it as soon as possible.
    [NSTimer scheduledTimerWithTimeInterval:interval
                                     target:self
                                   selector:@selector(check_idle_time:)
                                   userInfo:nil
                                    repeats:NO];
  }
}

- (id)init
{
  if ((self = [super init])) {
      // Init isAway to false.
    self.isAway = NO;

      // Start polling for idle time.
    [self check_idle_time:nil];

      // Register for notification of ScreenSaver start and stop events.
      //
      // Note that these events are not documented so Apple might remove them or
      // even change the semantics out from under us with no warning. Since the
      // coupling is loose and all that breaks is /away when screensaver starts,
      // this shouldn't be a problem.
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(screenSaverDidStart)
                                                            name:@"com.apple.screensaver.didstart"
                                                          object:nil];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(screenSaverDidStop)
                                                            name:@"com.apple.screensaver.didstop"
                                                          object:nil];
  }
  return self;
}

/*
 * Called by NSDistributedNotificationCenter when the screen saver starts
 *
 * When the screen saver starts, we set ourself to away.
 */
- (void)screenSaverDidStart
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (!self.isAway && prefs.auto_away) { // Don't set /away if we're allready away.
    [self setAway:YES];
  }
  [pool release];
}

/*
 * Called by NSDistributedNotificationCenter when the screen saver stops
 *
 * When the screen saver stops, we set ourself to back.
 */
- (void)screenSaverDidStop
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  if (self.isAway && prefs.auto_away) { // Don't send /back if we're not /away.
    [self setAway:NO];
  }
  [pool release];
}

@end
