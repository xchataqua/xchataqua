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

#import "NSTimerAdditions.h"

@interface MyInvocation : NSInvocation
{
}
@end

@implementation MyInvocation
- (void) retainArguments
{
}
@end

@implementation NSTimer (SGTimerAdditions)

+ (NSTimer *) scheduledTimerWithTimeInterval:(NSTimeInterval)seconds 
                                      target:(id)target
                                    selector:(SEL)aSelector
                                    userInfo:(id)userInfo
                                     repeats:(BOOL)repeats
                                  retainArgs:(BOOL)retainArgs
{
    NSMethodSignature *sig = [target methodSignatureForSelector:aSelector];
    NSInvocation *inv = [MyInvocation invocationWithMethodSignature:sig];
    [inv setSelector:aSelector];
    [inv setTarget:target];
    [inv setArgument:&userInfo atIndex:2];
    if (retainArgs)
        [inv retainArguments];
    return [NSTimer scheduledTimerWithTimeInterval:seconds
                                        invocation:inv
                                           repeats:repeats];
}

@end
