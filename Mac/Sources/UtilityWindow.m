/*
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

//
//  UtilityWindow.m
//  X-Chat Aqua
//
//  Created by iphary on 10. 11. 14..
//  Copyright 2010 iphary.org. All rights reserved.
//
//  This is interface which provides common GUI handler for utility windows
//

#import "UtilityWindow.h"

NSMutableDictionary *utilities;
@implementation UtilityWindow
@synthesize windowKey;

+ (void) initialize {
    if (self == [UtilityWindow class]) {
        if (utilities == nil) {
            utilities = [[NSMutableDictionary alloc] init];
        }
    }
}

+ (UtilityWindow *) utilityIfExistsByKey:(id)aKey {
    return [utilities objectForKey:aKey];
}

+ (UtilityWindow *) utilityByKey:(id)aKey {
    UtilityWindow *utility = [utilities objectForKey:aKey];
    if ( utility == nil ) {
        utility = [[self alloc] init];
        utility->windowKey = [aKey retain];        
        [utilities setObject:utility forKey:aKey];
        [utility release];
    }
    return utility;
}

+ (UtilityWindow *) utilityByKey:(id)aKey windowNibName:(NSString *)nibName {
    UtilityWindow *utility = [utilities objectForKey:aKey];
    if ( utility == nil ) {
        NSWindowController *windowController = [[NSWindowController alloc] initWithWindowNibName:nibName];
        utility = (UtilityWindow *)[windowController window];
        utility->windowKey = [aKey retain];
        [utilities setObject:utility forKey:aKey];
        [windowController release];
    }
    return utility;
}

- (void) close {    
    [super close];
    if (self.isReleasedWhenClosed) {
        [utilities removeObjectForKey:windowKey];
    }
}

- (void) dealloc {
    [self->windowKey release];
    if ([utilities objectForKey:windowKey]) {
        [utilities removeObjectForKey:windowKey];
    }
    [super dealloc];
}

@end

@implementation UtilityTabOrWindowView
@synthesize windowKey;

+ (void) initialize {
    if (self == [UtilityTabOrWindowView class]) {
        if (utilities == nil) {
            utilities = [[NSMutableDictionary alloc] init];
        }
    }
}

+ (UtilityTabOrWindowView *) utilityIfExistsByKey:(id)aKey {
    return [utilities objectForKey:aKey];
}

+ (UtilityTabOrWindowView *) utilityByKey:(id)aKey viewNibName:(NSString *)nibName {
    UtilityTabOrWindowView *utility = [utilities objectForKey:aKey];
    if ( utility == nil ) {
        NSViewController *viewController = [[NSViewController alloc] initWithNibName:nibName bundle:nil];
        utility = (UtilityTabOrWindowView *)viewController.view;
        utility->windowKey = [aKey retain];
        [utilities setObject:utility forKey:aKey];
        [viewController release];
    }
    return utility;
}

- (void) windowWillClose:(NSNotification *)notification {
    [super windowWillClose:notification];
    [utilities removeObjectForKey:windowKey];
}

- (void) becomeTabOrWindowAndShow:(BOOL)flag
{
    if (prefs.windows_as_tabs)
        [self becomeTabAndShow:flag];
    else
        [self becomeWindowAndShow:flag];
}

- (void) dealloc {
    [self->windowKey release];
    [super dealloc];
}

@end
