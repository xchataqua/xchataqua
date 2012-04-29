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

#include <unistd.h>
#include <pthread.h>
#import "SGFileDescriptor.h"

@class SGFileDescriptorPrivate;

static pthread_mutex_t SGFileDescriptorMutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t SGFileDescriptorDispatchComplete = PTHREAD_COND_INITIALIZER;

static CFRunLoopRef SGFileDescriptorRunLoop;
static CFRunLoopSourceRef SGFileDescriptorRunLoopSource;

static NSMutableArray *SGFileDescriptors;
static NSMutableArray *SGFileDescriptorStack;
static int SGFileDescriptorPipes [2];

@interface SGFileDescriptorPrivate : SGFileDescriptor
{
@public
    int fd;
    NSInteger mode;
@protected
    id  target;
    SEL selector;
    id  obj;

    BOOL enabled;
}

- (void)dispatch;

@end

#pragma mark -

static void SGFileDescriptorDispatch (void *args)
{
    // NOTE:  We are in "run_loop"s thread.
    //
    // The mutex is NOT locked but this list IS safe because we know
    // that SGFileDescriptorMainLoop () is blocked waiting for us to complete.
    // We could lock the mutex but then we would either have to make
    // the mutex recursive or create a separate mutex just for this
    // list.  Either way, it's not really needed.
    
    while (SGFileDescriptorStack.count > 0)
    {
        SGFileDescriptorPrivate *descriptor = [SGFileDescriptorStack lastObject];
        [descriptor dispatch];
        [SGFileDescriptorStack removeLastObject];
    }
    
    // SGFileDescriptorMainLoop is waiting for us to finish.. cut him loose..
    
    pthread_mutex_lock (&SGFileDescriptorMutex);
    pthread_cond_signal (&SGFileDescriptorDispatchComplete);
    pthread_mutex_unlock (&SGFileDescriptorMutex);
}

static void *SGFileDescriptorMainLoop (void *args)
{
    pthread_mutex_lock (&SGFileDescriptorMutex);
    
    for (;;)
    {
        fd_set rfds, wfds, efds;
        
        FD_ZERO (&rfds);
        FD_ZERO (&wfds);
        FD_ZERO (&efds);
        
        FD_SET (SGFileDescriptorPipes[0], &rfds);
        
        int max = SGFileDescriptorPipes [0];
        
        for (SGFileDescriptorPrivate *descriptor in SGFileDescriptors)
        {
            fd_set *set = NULL;
            switch (descriptor->mode)
            {
                case SGFileDescriptorRead:  set = &rfds; break;
                case SGFileDescriptorWrite: set = &wfds; break;
                case SGFileDescriptorExcep: set = &efds; break;
            }
            
            if (set) {
                FD_SET (descriptor->fd, set);
            }
            
            if (descriptor->fd > max) {
                max = descriptor->fd;
            }
        }
        
        pthread_mutex_unlock (&SGFileDescriptorMutex);
        
        int n = select (max + 1, &rfds, &wfds, &efds, NULL);
        
        //if (n < 0)
        //perror ("select");
        
        pthread_mutex_lock (&SGFileDescriptorMutex);
        
        if (n > 0)
        {
            for (SGFileDescriptorPrivate *descriptor in SGFileDescriptors)
            {
                bool fire = false;
                
                switch (descriptor->mode)
                {
                    case SGFileDescriptorRead: fire = FD_ISSET (descriptor->fd, &rfds); break;
                    case SGFileDescriptorWrite: fire = FD_ISSET (descriptor->fd, &wfds); break;
                    case SGFileDescriptorExcep: fire = FD_ISSET (descriptor->fd, &efds); break;
                }
                
                if (fire)
                {
                    [SGFileDescriptorStack addObject:descriptor];
                }
            }
            
            if (FD_ISSET (SGFileDescriptorPipes [0], &rfds))
            {
                char ch;
                read (SGFileDescriptorPipes [0], &ch, 1);
            }
            
            if (SGFileDescriptorStack.count > 0)
            {
                CFRunLoopSourceSignal (SGFileDescriptorRunLoopSource);
                CFRunLoopWakeUp (SGFileDescriptorRunLoop);
                
                pthread_cond_wait (&SGFileDescriptorDispatchComplete, &SGFileDescriptorMutex);
            }
        }
    }
    
    pthread_mutex_unlock (&SGFileDescriptorMutex);
    
    return NULL;
}

@implementation SGFileDescriptorPrivate

+ (void) initialize {
    SGFileDescriptorRunLoop = [[NSRunLoop currentRunLoop] getCFRunLoop];
    SGFileDescriptors = [[NSMutableArray alloc] init];
    SGFileDescriptorStack = [[NSMutableArray alloc] init];
    
    pipe (SGFileDescriptorPipes);
    
    CFRunLoopSourceContext context = { 0, 0, 0, 0, 0, 0, 0, 0, 0, SGFileDescriptorDispatch };
    
    SGFileDescriptorRunLoopSource = CFRunLoopSourceCreate (NULL, 0, &context);
    
    CFRunLoopAddSource (SGFileDescriptorRunLoop, SGFileDescriptorRunLoopSource, kCFRunLoopCommonModes);
    
    pthread_t thread;
    pthread_create (&thread, NULL, SGFileDescriptorMainLoop, NULL);
}

- (void) enable
{
    self->enabled = true;
    
    pthread_mutex_lock (&SGFileDescriptorMutex);
    
    [SGFileDescriptors addObject:self];
    
    char ch = 0;
    write (SGFileDescriptorPipes [1], &ch, 1);
    
    pthread_mutex_unlock (&SGFileDescriptorMutex);
}

- (SGFileDescriptor *)initWithFd:(int)aFd mode:(NSInteger)aMode target:(id)aTarget
						selector:(SEL)aSelector withObject:(id)anObject;
{
    self->fd = aFd;
    self->mode = aMode;
    self->target = aTarget;
    self->selector = aSelector;
    self->obj = anObject;

    [self enable];
    
    return self;
}

- (void)dispatch
{
    if (enabled) {
        [target performSelector:selector withObject:obj];
    }
}

- (void)disable
{
    enabled = false;
    
    pthread_mutex_lock (&SGFileDescriptorMutex);
    
    [SGFileDescriptors removeObjectIdenticalTo:self];
        
    pthread_mutex_unlock (&SGFileDescriptorMutex);
}

@end

#pragma mark -

@implementation SGFileDescriptor

+ (id)alloc
{
    if ([self isEqual:[SGFileDescriptor class]])
        return [SGFileDescriptorPrivate alloc];
    else
        return [super alloc];
}

- (SGFileDescriptor *)initWithFd:(int)fd mode:(NSInteger)mode target:(id)target
						selector:(SEL)selector withObject:(id)object;
{
    return nil;
}

- (void)disable
{
}

@end
