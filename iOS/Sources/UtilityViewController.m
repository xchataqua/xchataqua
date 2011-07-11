//
//  UtilityViewController.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 16..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include "common/xchat.h"
#import "fe-iphone_common.h"
#import "AppDelegate.h"
#import "UtilityViewController.h"

NSMutableDictionary *utilityViewControllers;

NSString *fullKey(NSString *key, struct session *sess) {
	if ( sess != NULL )
		key = [key stringByAppendingFormat:@"_%x", sess];
	return key;
}

@implementation UtilityViewController
@synthesize session, server;
@synthesize tabTitle;

- (void) setTabTitle:(NSString *)aTabTitle {
	[tabTitle release];
	tabTitle = [aTabTitle retain];
	[[ApplicationDelegate mainViewController] reloadData];
}

- (NSInteger) groupId {
	return self->server ? self->server->gui->tabGroup : 0;
}

+ (void) initialize {
	utilityViewControllers = [[NSMutableDictionary alloc] init];
}

+ (UtilityViewController *)viewControllerByKey:(NSString *)key forSession:(struct session *)session {
	return [utilityViewControllers objectForKey:fullKey(key, session)];
}

+ (UtilityViewController *) viewControllerWithNibName:(NSString *)nibName key:(NSString *)key forSession:(struct session *)session {
	UtilityViewController *viewController = [self viewControllerByKey:key forSession:session];
	if ( viewController == nil ) {
		viewController = [[self alloc] initWithNibName:nibName bundle:nil];
		viewController->utilityKey = [key retain];
		viewController->session = session;
		[utilityViewControllers setObject:viewController forKey:fullKey(key, session)];
		[viewController release];
	}
	return viewController;
}

+ (NSString *) nibName { /*SGAssert(NO);*/ return @""; }
+ (NSString *) mainKey { return [self nibName]; }

+ (id) viewControllerForSession:(struct session *)session {
	return [self viewControllerWithNibName:[self nibName] key:[self mainKey] forSession:session];
}

+ (id)viewControllerIfExistsForSession:(struct session *)session {
	return [self viewControllerByKey:[self mainKey] forSession:session];
}

@end
