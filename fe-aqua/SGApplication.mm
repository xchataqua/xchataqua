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

//////////////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////

@interface oneCustomer : ObjSel
{
    NSEventType type;
    NSWindow *win;
    NSView *view;
}

+ (id) customerWithType:(NSEventType) the_type
              forWindow:(NSWindow *) the_win
                forView:(NSView *) the_view
                    sel:(SEL) the_sel
                    obj:(id) the_object;

@end

@implementation oneCustomer

+ (id) customerWithType:(NSEventType) the_type
              forWindow:(NSWindow *) the_win
                forView:(NSView *) the_view
                    sel:(SEL) the_sel
                    obj:(id) the_object
{
    oneCustomer *cust = [[[oneCustomer alloc] init] autorelease];
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
        if (!view || [SGApplication event:anEvent inView:view])
        {
            BOOL (*doit)(id, SEL, id) = 
                (BOOL (*)(id, SEL, id)) [object methodForSelector:sel];
            return doit (object, sel, anEvent);
        }
    }
    
    return false;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation SGApplication

+ (bool) event:(NSEvent *) e
        inView:(NSView *) v
{
    // TBD: Is locationInWindow only good for mouse events?
    NSPoint p = [v convertPoint:[e locationInWindow] fromView:nil];
    return [v mouse:p inRect:[v bounds]];
}

- (id) init
{
    [super init];
    customers = [[NSMutableArray arrayWithCapacity:0] retain];
    after_events = [[NSMutableArray arrayWithCapacity:0] retain];
    return self;
}

- (id) requestEvents:(NSEventType) type
	   forWindow:(NSWindow *) win
             forView:(NSView *) view
            selector:(SEL) sel
              object:(id) obj
{
    oneCustomer *cust = [oneCustomer customerWithType:type
					    forWindow:win
					      forView:view
					          sel:sel
					          obj:obj];
    [customers addObject:cust];
    return cust;
}

- (void) cancelRequestEvents:(id) req_id
{
    [customers removeObject:req_id];
}

- (void) sendEvent:(NSEvent *) anEvent
{
    for (unsigned int i = 0; i < [customers count]; i ++)
        if ([[customers objectAtIndex:i] sendCopy:anEvent])
            return;
    
    [super sendEvent:anEvent];
}

@end
