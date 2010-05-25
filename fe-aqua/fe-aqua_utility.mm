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

extern "C" {
#undef TYPE_BOOL
#include "../common/xchat.h"
#include "../common/fe.h"
#undef TYPE_BOOL
}

#import "fe-aqua_utility.h"

static std::list<id> input_list;
static int input_seq = 1;

@implementation InputThing

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
    return nil;
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

#if USE_GLIKE_TIMER
#else

static std::list<id> timer_list;
static int timer_seq = 1;

@implementation TimerThing

+ (id)timerFromInterval:(int)the_interval callback:(timer_callback)the_callback
			   userdata:(void *)the_userdata
{
    TimerThing *thing = [[TimerThing alloc] init];
	
    thing->interval = (NSTimeInterval) the_interval / 1000;
    thing->callback = the_callback;
    thing->userdata = the_userdata;
    thing->tag = timer_seq ++;
    thing->timer = nil;
	
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
        timer = nil;
    }
}

- (int)getTag
{
    return tag;
}

- (void)schedule
{
    timer = [NSTimer scheduledTimerWithTimeInterval:(double) interval
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

@end

#endif
