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

#ifdef __cplusplus
extern "C" {
#endif
#undef TYPE_BOOL
#include "../common/xchat.h"
#include "../common/fe.h"
#undef TYPE_BOOL
#ifdef __cplusplus
}
#endif

#import "fe-aqua_utility.h"
#define CPP_INPUT_THING 0
#define CPP_TIMER_THING 0
#if CPP_INPUT_THING | CPP_TIMER_THING
#include <list>
#endif
#if CPP_INPUT_THING
static std::list<id> input_list;
#else
NSMutableArray *inputArray;
#endif
static NSInteger input_seq = 1;

@implementation InputThing
@synthesize tag;

+ (id) socketFromFD:(int) sok 
              flags:(int) the_flags
               func:(socket_callback) the_func
               data:(void *) the_data
{
    InputThing *thing = [[InputThing alloc] init];
    
    thing->func = the_func;
    thing->data = the_data;
    thing->rf = nil;
    thing->wf = nil;
    thing->ef = nil;
    thing->tag = input_seq ++;
    
    if (the_flags & FIA_READ)
        thing->rf = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDRead
												  target:thing selector:@selector (doit:) withObject:nil];
    if (the_flags & FIA_WRITE)
        thing->wf = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDWrite
												  target:thing selector:@selector (doit:) withObject:nil];
    if (the_flags & FIA_EX)
        thing->ef = [[SGFileDescriptor alloc] initWithFd:sok mode:SGFDExcep
												  target:thing selector:@selector (doit:) withObject:nil];
	#if CPP_INPUT_THING
    input_list.push_back (thing);
	#else
	[inputArray addObject:thing];
	#endif
    
    return [thing autorelease];
}

+ (id)findTagged:(int)atag
{
	for (
		#if CPP_INPUT_THING
		 std::list<id>::iterator iter = input_list.begin(); iter != input_list.end();
		#else
		 InputThing *athing in inputArray
		#endif
		 )
		
    {
		#if CPP_INPUT_THING
        id athing = *iter++;
		#endif
        if ([athing tag] == atag)
            return athing;
    }
    return nil;
}

- (void)dealloc
{
	if(rf) [rf release];
	if(wf) [wf release];
	if(ef) [ef release];
	#if CPP_INPUT_THING
    input_list.remove (self);
	#else
	[inputArray removeObject:self];
	#endif
    [super dealloc];
}

- (void)disable
{
    if (rf) [rf disable];
    if (wf) [wf disable];
    if (ef) [ef disable];
}

- (void)doit:(id)obj
{
    func (NULL, 0, data);
}

#if CPP_INPUT_THING
#else
+ (void) initialize {
	inputArray = [[NSMutableArray alloc] init];	
}
#endif

@end

/////////////////////////////////////////////////////////////////////////////

#if USE_GLIKE_TIMER
#else

#if CPP_TIMER_THING
static std::list<id> timer_list;
#else
NSMutableArray *timerArray;
#endif
static int timer_seq = 1;

@implementation TimerThing
@synthesize tag;

+ (id)timerFromInterval:(int)the_interval callback:(timer_callback)the_callback
			   userdata:(void *)the_userdata
{
    TimerThing *thing = [[TimerThing alloc] init];
	
    thing->interval = (NSTimeInterval) the_interval / 1000;
    thing->callback = the_callback;
    thing->userdata = the_userdata;
    thing->tag = timer_seq ++;
    thing->timer = nil;
	
	#if CPP_TIMER_THING
    timer_list.push_back (thing);
	#else
	[timerArray addObject:thing];
	#endif
    
    [thing schedule];
	
    return [thing autorelease];
}

+ (void)removeTimerWithTag:(int)atag
{
    for (
		#if CPP_TIMER_THING
		 std::list<id>::iterator iter = timer_list.begin(); iter != timer_list.end();
		#else
		 TimerThing *atimer in timerArray
		#endif
		 )
    {
		#if CPP_TIMER_THING
        TimerThing *atimer = *iter++;
		#endif
        if ([atimer tag] == atag)
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
	#if CPP_TIMER_THING
    timer_list.remove (self);
	#else
	[timerArray removeObject:self];
	#endif
    [self invalidate];
    [super dealloc];
}

- (void)invalidate
{
    if (timer)
    {
        [timer invalidate];
        timer = nil;
    }
}

- (void)schedule
{
    timer = [NSTimer scheduledTimerWithTimeInterval:interval
											 target:self
										   selector:@selector(fire:)
										   userInfo:nil
											repeats:NO
										 retainArgs:NO];
}

- (void)fire:(id)userInfo
{
    [timer invalidate];
    timer = nil;
	
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

#if CPP_TIMER_THING
#else
+ (void) initialize {
	timerArray = [[NSMutableArray alloc] init];	
}
#endif


@end

#endif
