//
//  AppDelegate.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 16..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
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

#include "common/xchat.h"
#include "common/xchatc.h"
#include "common/fe.h"

#include "fe-iphone_common.h"

#import "ColorPalette.h"
#import "MainViewController.h"
#import "ChatViewController.h"
#import "NetworkViewController.h"

#import "AppDelegate.h"

// Admob
//#import "AdViewController.h"

@implementation AppDelegate
@synthesize window, navigationController;
@synthesize mainViewController;
@synthesize colorPalette;

@synthesize bannerView, adViewController;

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {    
    
    // Admob
	//[AdViewController self];

	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	self->colorPalette = [[ColorPalette alloc] init];
	[self->colorPalette load];
	
	// core code disabled
	if (!prefs.slist_skip && !arg_url)
		fe_serverlist_open (NULL);
	
    // Override point for customization after application launch.
    
	[self.window addSubview:navigationController.view];
	[self.window makeKeyAndVisible];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application {
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}

- (void)dealloc {
	[navigationController release];
    [window release];
    [super dealloc];
}

#pragma mark -

+ (void) initialize {
	//ApplicationDelegate = [self sharedAppDelegate];
}

+ (AppDelegate *) sharedAppDelegate {
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

+ (UIView *) sharedBannerView {
	return [(AppDelegate *)[[UIApplication sharedApplication] delegate] bannerView];
}

+ (id) sharedAdViewController {
	return [(AppDelegate *)[[UIApplication sharedApplication] delegate] adViewController];
}

+ (void) performSelector:(SEL)sel forEachSessionOnServer:(struct server *)serv
{
	for (GSList *list = sess_list; list; list = list->next)
	{
		struct session *sess = (struct session *) list->data;
		if (!serv || sess->server == serv)
			[sess->gui->chatViewController performSelector:sel];
	}
}

+ (void) performSelector:(SEL)sel withObject:(id)obj  forEachSessionOnServer:(struct server *)serv 
{
	for (GSList *list = sess_list; list; list = list->next)
	{
		struct session *sess = (struct session *) list->data;
		if (!serv || sess->server == serv)
			[sess->gui->chatViewController performSelector:sel withObject:obj];
	}
}

#pragma mark fe-aqua

- (void) pushNetworkViewControllerForSession:(struct session *)session {
	[navigationController pushViewController:[NetworkViewController viewControllerForSession:session] animated:YES];
}

@end
