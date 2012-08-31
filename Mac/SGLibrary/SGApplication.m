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

#import "SGApplication.h"

#import <objc/runtime.h>

@interface ObjSel : NSObject
{
  @public
	SEL sel;
	id object;
}
@end

@implementation ObjSel

- (void) invoke
{
	[object performSelector:sel];
}

@end

#pragma mark -

@interface SGApplicationCustomer : ObjSel
{
	NSEventType type;
	NSWindow *win;
	NSView *view;
}

+ (id) customerWithType:(NSEventType) the_type
			  forWindow:(NSWindow *) the_win
				forView:(NSView *) the_view
			   selector:(SEL) the_sel
				 object:(id) the_object;

@end

@implementation SGApplicationCustomer

+ (id) customerWithType:(NSEventType) the_type
			  forWindow:(NSWindow *) the_win
				forView:(NSView *) the_view
			   selector:(SEL) the_sel
				 object:(id) the_object
{
	SGApplicationCustomer *cust = [[[SGApplicationCustomer alloc] init] autorelease];
	cust->type = the_type;
	cust->win = the_win ? the_win : the_view ? [the_view window] : nil;
	cust->view = the_view;
	cust->sel = the_sel;
	cust->object = the_object;
	
	return cust;
}

- (bool) sendCopy:(NSEvent *) anEvent
{
	if ([anEvent type] == type && (!win || [anEvent window] == win))
	{
		if (!view || [NSApplication event:anEvent inView:view])
		{
			BOOL (*doit)(id, SEL, id) = (BOOL (*)(id, SEL, id)) [object methodForSelector:sel];
			return doit (object, sel, anEvent);
		}
	}
	
	return false;
}

@end

#pragma mark -

NSMutableArray *SGApplicationCustomers = nil;

@implementation NSApplication (SGApplication)

+ (BOOL) event:(NSEvent *)event inView:(NSView *)view
{
	// TBD: Is locationInWindow only good for mouse events?
	NSPoint point = [view convertPoint:[event locationInWindow] fromView:nil];
	return [view mouse:point inRect:[view bounds]];
}

- (void) cancelRequestEvents:(id) req_id
{
	[SGApplicationCustomers removeObject:req_id];
}

- (void)sendOriginalEvent:(NSEvent *)anEvent {
    SGAssert(NO);
}

- (void)sendXAEvent:(NSEvent *)anEvent {
    for (id customer in SGApplicationCustomers) {
        if ([customer sendCopy:anEvent]) {
            return;
        }
    }
    [self sendOriginalEvent:anEvent];
}

- (id) requestEvents:(NSEventType)type
		   forWindow:(NSWindow *)win
			 forView:(NSView *)view
			selector:(SEL)sel
			  object:(id)obj
{
	SGApplicationCustomer *customer = [SGApplicationCustomer customerWithType:type
                                                                    forWindow:win
                                                                      forView:view
                                                                     selector:sel
                                                                       object:obj];
    if (SGApplicationCustomers == nil) {
        SGApplicationCustomers = [[NSMutableArray alloc] init];
        Class class = [NSApplication class];
        Method originalMethod = class_getInstanceMethod(class, @selector(sendEvent:));
        Method overrideMethod = class_getInstanceMethod(class, @selector(sendXAEvent:));
        Method backupMethod = class_getInstanceMethod(class, @selector(sendOriginalEvent:));
        IMP originalImplementation = method_getImplementation(originalMethod);
        IMP overrideImplementation = method_getImplementation(overrideMethod);
        if (originalImplementation != overrideImplementation) {
            method_setImplementation(backupMethod, originalImplementation);
            method_setImplementation(originalMethod, overrideImplementation);
        }
    }
    [SGApplicationCustomers addObject:customer];
    return customer;
}

@end
