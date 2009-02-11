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

static pthread_mutex_t sgfd_mtx = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t  sgfd_dispatch_complete = PTHREAD_COND_INITIALIZER;
static bool	       sgfd_inited;
static NSMutableArray  *sgfd_list;
static CFRunLoopRef    sgfd_run_loop;
static CFRunLoopSourceRef sgfd_rls;
static int	       sgfd_pipes [2];
static SGFileDescriptorPrivate *sgfd_dispatch_list;

//////////////////////////////////////////////////////////////////////

@interface SGFileDescriptorPrivate : SGFileDescriptor
{
    int fd;
    int mode;
    id  target;
    SEL selector;
    id  obj;

    bool enable;

  @public
    SGFileDescriptorPrivate *next;	// For dispatch list
}

- (int)getFd;
- (int)getMode;
- (void)dispatch;

@end

//////////////////////////////////////////////////////////////////////

static void sgfd_dispatch (void *)
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

static void *sgfd_main_loop (void *)
{
    pthread_mutex_lock (&sgfd_mtx);

    for (;;)
    {
        fd_set rfds, wfds, efds;

	FD_ZERO (&rfds);
	FD_ZERO (&wfds);
	FD_ZERO (&efds);

	FD_SET (sgfd_pipes [0], &rfds);

	int max = sgfd_pipes [0];

	for (unsigned i = 0; i < [sgfd_list count]; i++)
	{
	    id sgfd = [sgfd_list objectAtIndex:i];
            
            fd_set *the_set = NULL;
            
            switch ([sgfd getMode])
            {
                case SGFDRead: the_set = &rfds; break;
                case SGFDWrite: the_set = &wfds; break;
                case SGFDExcep: the_set = &efds; break;
            }
            
            if (the_set)
                FD_SET ([sgfd getFd], the_set);

	    if ([sgfd getFd] > max)
	        max = [sgfd getFd];
	}

	pthread_mutex_unlock (&sgfd_mtx);

	int n = select (max + 1, &rfds, &wfds, &efds, NULL);

        //if (n < 0)
            //perror ("select");
            
	pthread_mutex_lock (&sgfd_mtx);

	if (n > 0)
	{
	    for (unsigned i = 0; i < [sgfd_list count]; i++)
	    {
		SGFileDescriptorPrivate *sgfd = [sgfd_list objectAtIndex:i];

	        bool fire = false;
            
                switch ([sgfd getMode])
                {
                    case SGFDRead: fire = FD_ISSET ([sgfd getFd], &rfds); break;
                    case SGFDWrite: fire = FD_ISSET ([sgfd getFd], &wfds); break;
                    case SGFDExcep: fire = FD_ISSET ([sgfd getFd], &efds); break;
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
	        CFRunLoopSourceSignal (sgfd_rls);
		CFRunLoopWakeUp (sgfd_run_loop);

		pthread_cond_wait (&sgfd_dispatch_complete, &sgfd_mtx);
	    }
	}
    }

    pthread_mutex_unlock (&sgfd_mtx);

    return NULL;
}

static void sgfd_init ()
{
    sgfd_run_loop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    sgfd_list = [[NSMutableArray arrayWithCapacity:0] retain];

    pipe (sgfd_pipes);

    CFRunLoopSourceContext context =
	{ 0, 0, 0, 0, 0, 0, 0, 0, 0, sgfd_dispatch };

    sgfd_rls = CFRunLoopSourceCreate (NULL, 0, &context);

    CFRunLoopAddSource (sgfd_run_loop, sgfd_rls, kCFRunLoopCommonModes);

    sgfd_inited = true;

    pthread_t thrd;
    pthread_create (&thrd, NULL, sgfd_main_loop, NULL);
}

static void sgfd_add (SGFileDescriptor *sgfd)
{
    pthread_mutex_lock (&sgfd_mtx);

    if (!sgfd_inited)
        sgfd_init ();

    [sgfd_list addObject:sgfd];

    char ch = 0;
    write (sgfd_pipes [1], &ch, 1);

    pthread_mutex_unlock (&sgfd_mtx);
}


static void sgfd_remove (SGFileDescriptor *sgfd)
{
    pthread_mutex_lock (&sgfd_mtx);

    [sgfd_list removeObjectIdenticalTo:sgfd];

    pthread_mutex_unlock (&sgfd_mtx);
}

//////////////////////////////////////////////////////////////////////

@implementation SGFileDescriptorPrivate

- (SGFileDescriptor *)initWithFd:(int)the_fd mode:(int)the_mode target:(id)the_target 
                        selector:(SEL)the_selector withObject:(id)the_obj
{
    self->fd = the_fd;
    self->mode = the_mode;
    self->target = the_target;
    self->selector = the_selector;
    self->obj = the_obj;

    self->enable = true;

    sgfd_add (self);
    
    return self;
}

- (int)getFd
{
    return fd;
}

- (int)getMode
{
    return mode;
}

- (void)dispatch
{
    if (enable)
        [target performSelector:selector withObject:obj];
}

- (void)disable
{
    enable = false;
    sgfd_remove (self);
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

- (SGFileDescriptor *)initWithFd:(int)fd mode:(int)the_mode target:(id)the_target 
                        selector:(SEL)s withObject:(id)obj;
{
    return NULL;
}

- (void)disable
{
}

@end
