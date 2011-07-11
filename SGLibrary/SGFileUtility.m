//
//  SGFileUtility.m
//  aquachat
//
//  Created by Steve Green on 11/30/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#include <sys/stat.h>

#import "SGFileUtility.h"

static mode_t getFileMode (const char *fname)
{
	struct stat sb;
	int sts = lstat (fname, &sb);
	if (sts != 0 && sts != ENOENT)
	{
		perror ("Unable to stat");
		return -1;
	}
	
	return sb.st_mode;
}

@implementation SGFileUtility

+ (BOOL) exists:(NSString *) fname
{
	return getFileMode ([fname UTF8String]) > 0;
}

+ (BOOL) isDirectory:(NSString *) fname
{
	mode_t mode = getFileMode ([fname UTF8String]);
	return mode > 0 ? (mode & S_IFDIR) != 0 : NO;
}

+ (BOOL) isSymLink:(NSString *) fname
{
	mode_t mode = getFileMode ([fname UTF8String]);
	return mode > 0 ? (mode & S_IFLNK) != 0 : NO;
}

@end
