/* X-Chat Aqua
 * Copyright (C) 2006 Steve Green
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
#include <mach-o/dyld.h>

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/server.h"
}

@implementation AutoAwayController

- (void) setAway:(BOOL) away
{
	for (GSList *list = serv_list; list; list = list->next)
    {
        struct server *svr = (struct server *) list->data;
		
		if (!svr->connected)
			continue;
			
		if (away)
			handle_command (svr->server_session, "away auto-away", false);
		else
			handle_command (svr->server_session, "away", false);
    }
}

- (void) check_idle_time:(NSTimer *) theTimer
{
	// This code uses an undocumented function for determining the idle time.
	// Thanks to Evan Schoenberg for pioneering this.
	//
	// I don't like using extern to find the function.  If apple decides to remove
	// that function, I don't want XCA to suddenly stop working.  Dynamically find the
	// function instead.
	
	typedef CFTimeInterval (*CGSSecondsSinceLastInputEventProcPtr)(unsigned long);
	static CGSSecondsSinceLastInputEventProcPtr proc;
    
    if (proc == NULL && NSIsSymbolNameDefined ("_CGSSecondsSinceLastInputEvent"))
    {
        proc = (CGSSecondsSinceLastInputEventProcPtr) 
            NSAddressOfSymbol (NSLookupAndBindSymbol ("_CGSSecondsSinceLastInputEvent"));
			
		if (proc == NULL)
		{
			printf ("Unable to find CGSSecondsSinceLastInputEvent().  Auto-away disabled\n");
			[theTimer invalidate];
		}
    } 

	CFTimeInterval idleTime = proc(-1);
	if (idleTime >= 18446744000.0)
		idleTime = 0.0;
	
	NSTimeInterval interval;
		
	if (prefs.auto_away && (idleTime / 60 >= prefs.auto_away_delay))
	{
		if (!wasIdle)
		{
			[self setAway:YES];
			wasIdle = YES;
		}
		
		interval = 1;
	}
	else
	{
		if (wasIdle)
		{
			[self setAway:NO];
			wasIdle = NO;
		}
		
		interval = 60;
	}
	
	[NSTimer scheduledTimerWithTimeInterval:interval
								     target:self
								   selector:@selector (check_idle_time:)
								   userInfo:nil
								    repeats:NO];
}

+ (void) start
{
	id x = [[AutoAwayController alloc] init];
	[x check_idle_time:nil];
}

@end
