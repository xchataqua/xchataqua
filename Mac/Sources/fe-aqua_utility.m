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

#import "fe-aqua_utility.h"

#pragma mark -

NSMutableArray *InputThingItems;
static int InputThingSequence = 1;

@implementation InputThing
@synthesize tag;

+ (void) initialize {
    if (self == [InputThing class]) {
        InputThingItems = [[NSMutableArray alloc] init];
    }
}

+ (id)inputWithSocketFD:(int)socket flags:(int)flags callback:(void *)callback data:(void *)the_data {
    InputThing *thing = [[InputThing alloc] init];
    
    thing->func = callback;
    thing->data = the_data;
    thing->rf = nil;
    thing->wf = nil;
    thing->ef = nil;
    thing->tag = InputThingSequence ++;
    
    if (flags & FIA_READ)
        thing->rf = [[SGFileDescriptor alloc] initWithFd:socket mode:SGFileDescriptorRead
                                                  target:thing selector:@selector (doit:) withObject:nil];
    if (flags & FIA_WRITE)
        thing->wf = [[SGFileDescriptor alloc] initWithFd:socket mode:SGFileDescriptorWrite
                                                  target:thing selector:@selector (doit:) withObject:nil];
    if (flags & FIA_EX)
        thing->ef = [[SGFileDescriptor alloc] initWithFd:socket mode:SGFileDescriptorExcep
                                                  target:thing selector:@selector (doit:) withObject:nil];
    [InputThingItems addObject:thing];
   
    return [thing autorelease];
}

+ (id)inputForTag:(long)atag
{
    for (InputThing *athing in InputThingItems)
    {
        if ([athing tag] == atag)
            return athing;
    }
    return nil;
}

- (void)dealloc
{
    [rf release];
    [wf release];
    [ef release];
    [super dealloc];
}

- (void)remove {
    [InputThingItems removeObject:self];
}

- (void)disable
{
    [rf disable];
    [wf disable];
    [ef disable];
}

typedef gboolean (*input_callback) (GIOChannel *source, GIOCondition condition, void *user_data);
- (void)doit:(id)obj
{
    input_callback func_t = func;
    func_t (NULL, 0, data);
}

@end

#pragma mark -

#if USE_GLIKE_TIMER
#else

NSLock *TimerThingLock;
NSMutableArray *TimerThingItems;
static int TimerThingSequence = 1;

@implementation TimerThing
@synthesize tag=_tag;

+ (void) initialize {
    if (self == [TimerThing class]) {
        TimerThingLock = [NSLock new];
        TimerThingItems = [[NSMutableArray alloc] init];
    }
}

+ (id)timerWithInterval:(long)the_interval callback:(void *)the_callback
               userdata:(void *)the_userdata
{
    dassert(the_callback != NULL);
    TimerThing *thing = [[TimerThing alloc] init];
    
    thing->_interval = (NSTimeInterval) the_interval / 1000;
    thing->_tag = TimerThingSequence ++;
    thing->_callback = the_callback;
    thing->_userdata = the_userdata;

    [TimerThingLock lock];
    [TimerThingItems addObject:thing];
    [TimerThingLock unlock];

    [thing schedule];
    
    return [thing autorelease];
}

+ (id)timerForTag:(long)tag {
    [TimerThingLock lock];
    id timer = nil;
    for (TimerThing *atimer in TimerThingItems)
    {
        if (atimer->_tag == tag) {
            timer = atimer;
            break;
        }
    }
    [TimerThingLock unlock];
    return timer;
}

- (void)remove {
    [self invalidate];
    self->_callback = NULL;     // We'll use this to detect released
    [TimerThingLock lock];
    [[self retain] autorelease];
    [TimerThingItems removeObjectIdenticalTo:self];
    [TimerThingLock unlock];
}

- (void)dealloc
{
    [self invalidate];
    [super dealloc];
}

- (void)invalidate
{
    if (_timer)
    {
        [_timer invalidate];
        _timer = nil;
    }
}

- (void)schedule
{
    self->_timer = [NSTimer scheduledTimerWithTimeInterval:self->_interval
                                                    target:self
                                                  selector:@selector(fire:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)fire:(id)userInfo
{
    [_timer invalidate];
    _timer = nil;

    int (*callback)(void *) = (int (*)(void *))self->_callback;
    
    if (_callback == NULL) {
        // XXX: do not run below if callback is NULL
        // then, so what should i do if it is NULL?
        dlog(TRUE, @"XXX: callback is null the app killer");
    } else if (callback(_userdata) == 0) {
        // Only honour his request to destroy this timer only if
        // he did not already do it in the callback.  We NULL out
        // the callback when he removes a timer to signal us here
        // not to release.
        [self remove];
    } else {
        [self schedule];
    }
}

@end

#endif

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

#pragma mark -

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
