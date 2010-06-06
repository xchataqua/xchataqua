/* MenuMaker
 * Copyright (C) 2006 Camillo Lugaresi
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

/*
	MenuMaker.h
	Created by Camillo Lugaresi on 16/01/06.
	
	This class handles menu generation.
*/

#import <Cocoa/Cocoa.h>

#include "../common/xchat.h"
#include "../common/userlist.h"	/* why don't these headers include their dependencies? */
#include "../common/fe.h"	/* why is there a typedef menu_entry, but no typedef User? */
	
@interface MenuMaker : NSObject {
	CGFloat maxUserInfoLabelWidth;
	CGFloat userInfoTabWidth;
}

+ (MenuMaker *)defaultMenuMaker;

- (NSMenu *)infoMenuForUser:(struct User *)user inSession:(session *)sess;
- (NSMenu *)menuForURL:(NSString *)url inSession:(session *)sess;
- (NSMenu *)menuForNick:(NSString *)nick inSession:(session *)sess;
- (NSMenu *)menuForChannel:(NSString *)chan inSession:(session *)sess;

- (NSMenuItem *)commandItemWithName:(NSString *)name command:(const char *)cmd target:(NSString *)target session:(session *)sess;
- (NSMenuItem *)togglerItemWithName:(NSString *)name option:(const char *)opt;

- (NSString *)stripImageFromTitle:(NSString *)title icon:(NSString **)icon;

- (void) appendItemList:(GSList *)list toMenu:(NSMenu *)menu withTarget:(NSString *)target inSession:(session *)sess;
- (void) menu_add:(menu_entry *) entry;
- (void) menu_del:(menu_entry *) entry;
- (void) menu_update:(menu_entry *) entry;

@end
