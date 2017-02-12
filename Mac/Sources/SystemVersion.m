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

#import <Foundation/Foundation.h>
#import "SystemVersion.h"

static SystemVersion *SystemVersionSharedSystemVersion;

@implementation SystemVersion
@synthesize systemVersion, buildVersion, systemBranch;
@synthesize major, minor, bugfix;

+ (void) initialize {
    if (self == [SystemVersion class]) {
        SystemVersionSharedSystemVersion = [[SystemVersion alloc] init];
    }
}

+ (SystemVersion*)sharedInstance {
    return SystemVersionSharedSystemVersion;
}

- (id) init {
    self = [super init];
    if (self != nil) {
        NSDictionary * dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
        
        buildVersion  = [[dict valueForKey:@"ProductBuildVersion"] retain];
        systemVersion = [[dict valueForKey:@"ProductVersion"] retain];

        NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
        self->major = version.majorVersion;
        self->minor = version.minorVersion;
        self->bugfix = version.patchVersion;

        systemBranch = [[NSString alloc] initWithFormat:@"%d.%d", major, minor];
    }
    return self;
}

- (void) dealloc
{
    [systemVersion release];
    [buildVersion release];
    [systemBranch release];
    [super dealloc];
}

+ (NSInteger)major {
    return [[SystemVersion sharedInstance] major];
}

+ (NSInteger)minor {
    return [[SystemVersion sharedInstance] minor];
}

+ (NSInteger)bugfix {
    return [[SystemVersion sharedInstance] bugfix];
}

+ (NSString *)systemVersion {
    return [[SystemVersion sharedInstance] systemVersion];
}

+ (NSString *)buildVersion {
    return [[SystemVersion sharedInstance] buildVersion];
}

+ (NSString *)systemBranch {
    return [[SystemVersion sharedInstance] systemBranch];
}

@end
