/* X-Chat Aqua
 * Copyright (C) 2008 Eugene Pimenov
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

@interface SystemVersion : NSObject {
	NSString *systemVersion;
	NSString *buildVersion;
	NSString *systemBranch;
    SInt32 version;
	SInt32 major;
	SInt32 minor;
	SInt32 bugfix;
}

+ (SystemVersion*)sharedInstance;

@property (nonatomic, readonly) NSString *systemVersion, *buildVersion, *systemBranch;
@property (nonatomic, readonly) SInt32 version, major, minor, bugfix;

+ (SInt32)version;
+ (SInt32)major;
+ (SInt32)minor;
+ (SInt32)bugfix;
+ (NSString *)systemVersion;
+ (NSString *)buildVersion;
+ (NSString *)systemBranch;

@end
