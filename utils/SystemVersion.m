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

#import "SystemVersion.h"

static SystemVersion * sharedSystemVersion;

@interface SystemVersion ( private )
- (void)_load_system_version;
@end

@implementation SystemVersion ( private )

- (void)_load_system_version {
	NSDictionary * dict = [[NSDictionary alloc] initWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
	
	buildVersion  = [[dict valueForKey:@"ProductBuildVersion"] retain];
	systemVersion = [[dict valueForKey:@"ProductVersion"] retain];
	
	{
		char * orig_buf, * buf = strdup([systemVersion UTF8String]);
		orig_buf = buf;
		major = atoi(buf);
		buf=strchr(buf, '.')+1;
		if(buf) {
			minor = atoi(buf);
			buf=strchr(buf, '.');
			if(buf)
				++buf;
		}
		if(buf)
			micro = atoi(buf);  
		free(orig_buf);
	}
	
	systemBranch = [[NSString alloc] initWithFormat:@"%d.%d", major, minor];
	
	[dict release];
}

@end

@implementation SystemVersion
@synthesize systemVersion, buildVersion, systemBranch;
@synthesize major, minor, micro;

+ (void) initialize {
	sharedSystemVersion = [[SystemVersion alloc] init];	
}

+ (SystemVersion*)sharedInstance {
	return sharedSystemVersion;
}

- (id) init {
	self = [super init];
	if(sharedSystemVersion != 0) {
		[self dealloc];
		self = sharedSystemVersion;
	}else {
		[self _load_system_version];
	}
	return self;
}

- (void) dealloc
{
	if(systemVersion)
		[systemVersion release];
	if(buildVersion)
		[buildVersion release];
	if(systemBranch)
		[systemBranch release];
	[super dealloc];
}

+ (uint8_t)major {
	return [[SystemVersion sharedInstance] major];
}

+ (uint8_t)minor {
	return [[SystemVersion sharedInstance] minor];
}

+ (uint8_t)micro {
	return [[SystemVersion sharedInstance] micro];
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
