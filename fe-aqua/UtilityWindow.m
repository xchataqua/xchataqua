//
//  UtilityWindow.m
//  X-Chat Aqua
//
//  Created by iphary on 10. 11. 14..
//  Copyright 2010 iphary.org. All rights reserved.
//

#import "UtilityWindow.h"

NSMutableDictionary *utilities;
@implementation UtilityWindow
@synthesize windowKey;

+ (void) initialize {
	if ( utilities == nil )
		utilities = [[NSMutableDictionary alloc] init];
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
	[utilities removeObjectForKey:windowKey];
}

- (void) dealloc {
	[self->windowKey release];
	[super dealloc];
}

@end

@implementation UtilityTabOrWindowView
@synthesize windowKey;

+ (void) initialize {
	if ( utilities == nil )
		utilities = [[NSMutableDictionary alloc] init];	
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