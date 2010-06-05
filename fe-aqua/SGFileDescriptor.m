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

//////////////////////////////////////////////////////////////////////

#include <sys/select.h>
#include <sys/types.h>
#include <sys/time.h>
#include <unistd.h>
#import <pthread.h>
#import "SGFileDescriptor.h"

//////////////////////////////////////////////////////////////////////

@class SGFileDescriptorPrivate;

static pthread_mutex_t	sgfd_mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t	sgfd_dispatch_complete = PTHREAD_COND_INITIALIZER;
static NSMutableArray  *sgfdArray;
static CFRunLoopRef		sgfdRunLoop;
static CFRunLoopSourceRef sgfdRunLoopSource;
static int				sgfd_pipes [2];
static SGFileDescriptorPrivate *sgfd_dispatch_list;

//////////////////////////////////////////////////////////////////////

@interface SGFileDescriptorPrivate : SGFileDescriptor
{
    int fd;
    NSInteger mode;
    id  target;
    SEL selector;
    id  obj;

    BOOL enable;

  @public
    SGFileDescriptorPrivate *next;	// For dispatch list
}

@property (nonatomic, readonly) int fd;
@property (nonatomic, readonly) NSInteger mode;

- (void)dispatch;

@end

//////////////////////////////////////////////////////////////////////
@implementation SGFileDescriptorPrivate
@synthesize fd,mode;

static void sgfd_dispatch (void *args)
{
    // NOTE:  We are in "run_loop"s thread.
    //
    // The mutex is NOT locked but this list IS safe because we know
    // that sgfd_main_loop () is blocked waiting for us to complete.
    // We could lock the mutex but then we would either have to make
    // the mutex recursive or create a separate mutex just for this
    // list.  Either way, it's not really needed.

    while (sgfd_dispatch_list)
    {
		[sgfd_dispatch_list dispatch];

		SGFileDescriptorPrivate *prev = sgfd_dispatch_list;
		sgfd_dispatch_list = sgfd_dispatch_list->next;

		[prev release];
    }

    // sgfd_main_loop is waiting for us to finish.. cut him loose..

    pthread_mutex_lock (&sgfd_mtx);
    pthread_cond_signal (&sgfd_dispatch_complete);
    pthread_mutex_unlock (&sgfd_mtx);
}

static void *sgfd_main_loop (void *args)
{
	pthread_mutex_lock (&sgfd_mtx);
	
	for (;;)
	{
		fd_set rfds, wfds, efds;

		FD_ZERO (&rfds);
		FD_ZERO (&wfds);
		FD_ZERO (&efds);

		FD_SET (sgfd_pipes[0], &rfds);

		int max = sgfd_pipes [0];

		for (NSUInteger i = 0; i < [sgfdArray count]; i++)
		{
			SGFileDescriptorPrivate *sgfd = [sgfdArray objectAtIndex:i];
            
            fd_set *the_set = NULL;
            switch ([sgfd mode])
			{
				case SGFDRead:  the_set = &rfds; break;
				case SGFDWrite: the_set = &wfds; break;
				case SGFDExcep: the_set = &efds; break;
			}
            
			if (the_set)
				FD_SET ([sgfd fd], the_set);

			if ([sgfd fd] > max)
				max = [sgfd fd];
		}

		pthread_mutex_unlock (&sgfd_mtx);
		
		int n = select (max + 1, &rfds, &wfds, &efds, NULL);
		
		//if (n < 0)
			//perror ("select");

		pthread_mutex_lock (&sgfd_mtx);
		
		if (n > 0)
		{
			for (NSUInteger i = 0; i < [sgfdArray count]; i++)
			{
				SGFileDescriptorPrivate *sgfd = [sgfdArray objectAtIndex:i];

				bool fire = false;
            
                switch ([sgfd mode])
                {
                    case SGFDRead: fire = FD_ISSET ([sgfd fd], &rfds); break;
                    case SGFDWrite: fire = FD_ISSET ([sgfd fd], &wfds); break;
                    case SGFDExcep: fire = FD_ISSET ([sgfd fd], &efds); break;
                }

                if (fire)
				{
					sgfd->next = sgfd_dispatch_list;
					sgfd_dispatch_list = sgfd;

					// Retain this guy just in case he gets removed
					// from the list during some other descriptor callback. 

					[sgfd retain];
				}
			}

			if (FD_ISSET (sgfd_pipes [0], &rfds))
			{
				char ch;
				read (sgfd_pipes [0], &ch, 1);
			}

			if (sgfd_dispatch_list)
			{
				CFRunLoopSourceSignal (sgfdRunLoopSource);
				CFRunLoopWakeUp (sgfdRunLoop);

				pthread_cond_wait (&sgfd_dispatch_complete, &sgfd_mtx);
			}
		}
	}

    pthread_mutex_unlock (&sgfd_mtx);

    return NULL;
}

+ (void) initialize {
    sgfdRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    sgfdArray = [[NSMutableArray arrayWithCapacity:0] retain];
	
    pipe (sgfd_pipes);
	
    CFRunLoopSourceContext context = { 0, 0, 0, 0, 0, 0, 0, 0, 0, sgfd_dispatch };
	
    sgfdRunLoopSource = CFRunLoopSourceCreate (NULL, 0, &context);
	
    CFRunLoopAddSource (sgfdRunLoop, sgfdRunLoopSource, kCFRunLoopCommonModes);
	
    pthread_t thrd;
    pthread_create (&thrd, NULL, sgfd_main_loop, NULL);
}

+ (void) sgfd_add:(SGFileDescriptor *)sgfd
{
    pthread_mutex_lock (&sgfd_mtx);
	
    [sgfdArray addObject:sgfd];
	
    char ch = 0;
    write (sgfd_pipes [1], &ch, 1);
	
    pthread_mutex_unlock (&sgfd_mtx);
}

- (SGFileDescriptor *)initWithFd:(int)the_fd mode:(NSInteger)the_mode target:(id)the_target 
                        selector:(SEL)the_selector withObject:(id)the_obj
{
    self->fd = the_fd;
    self->mode = the_mode;
    self->target = the_target;
    self->selector = the_selector;
    self->obj = the_obj;

    self->enable = true;

    [[self class] sgfd_add:self];
    
    return self;
}

- (void)dispatch
{
    if (enable)
        [target performSelector:selector withObject:obj];
}

- (void)disable
{
    enable = false;
	
	pthread_mutex_lock (&sgfd_mtx);
		
	[sgfdArray removeObjectIdenticalTo:self];
		
	pthread_mutex_unlock (&sgfd_mtx);
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGFileDescriptor

+ (id)alloc
{
    if ([self isEqual:[SGFileDescriptor class]])
		return [SGFileDescriptorPrivate alloc];
    else
		return [super alloc];
}

- (SGFileDescriptor *)initWithFd:(int)fd mode:(NSInteger)the_mode target:(id)the_target 
                        selector:(SEL)s withObject:(id)obj;
{
    return nil;
}

- (void)disable
{
}

@end
