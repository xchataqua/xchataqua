//
//  AppDelegate.h
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

#define ApplicationDelegate [AppDelegate sharedAppDelegate]

@class MainViewController;
@class ColorPalette;
@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	UINavigationController *navigationController;
	MainViewController *mainViewController;
	ColorPalette *colorPalette;
	
	UIView *bannerView;
	id adViewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet MainViewController *mainViewController;
@property (nonatomic, retain) ColorPalette *colorPalette;

@property (nonatomic, retain) IBOutlet UIView *bannerView;
@property (nonatomic, retain) IBOutlet id adViewController;

+ (AppDelegate *)sharedAppDelegate;
+ (UIView *)sharedBannerView;
+ (id)sharedAdViewController;

+ (void) performSelector:(SEL)sel forEachSessionOnServer:(struct server *)server;
+ (void) performSelector:(SEL)sel withObject:(id)obj forEachSessionOnServer:(struct server *)server;

- (void)pushNetworkViewControllerForSession:(struct session *)session;

@end
