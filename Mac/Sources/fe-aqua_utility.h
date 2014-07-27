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

@class SGFileDescriptor;
@interface InputThing : NSObject
{
    SGFileDescriptor *rf;
    SGFileDescriptor *wf;
    SGFileDescriptor *ef;
    
    void *func;
    void *data;
    
    int tag;
}

@property (nonatomic,readonly) int tag;

+ (id)inputWithSocketFD:(int)socket flags:(int)flags callback:(void *)callback data:(void *)data;

+ (id)inputForTag:(long)tag;
- (void)disable;
- (void)remove;

@end

#pragma mark -

#define USE_GLIKE_TIMER 0
#if USE_GLIKE_TIMER
#    import "GLikeTimer.h"
#else

@interface TimerThing : NSObject
{
    NSTimeInterval _interval;
    void *_callback;
    void *_userdata;
    int _tag;
    
    NSTimer *_timer;
}

@property (nonatomic, readonly) int tag;

+ (id)timerWithInterval:(long)the_interval callback:(void *)the_callback
               userdata:(void *)the_userdata;
+ (id)timerForTag:(long)tag;
- (void)schedule;
- (void)invalidate;
- (void)remove;

@end

#endif


@interface ConfirmObject : NSObject
{
@public
    void (*yesproc)(void *);
    void (*noproc)(void *);
    void *ud;
}
@end

#pragma mark -

@interface OpenURLCommand : NSScriptCommand { }

- (id) performDefaultImplementation;

@end
