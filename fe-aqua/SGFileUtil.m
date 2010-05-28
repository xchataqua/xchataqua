//
//  SGFileUtil.mm
//  aquachat
//
//  Created by Steve Green on 11/30/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SGFileUtil.h"

#include <sys/types.h>
#include <sys/stat.h>

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

@implementation SGFileUtil

+ (NSString *) findApplicationSupportFor:(NSString *) app
{
	FSRef ref;
	if (FSFindFolder(kUserDomain, kApplicationSupportFolderType, false, &ref) != noErr)
		return nil;
		
	UInt8 path[PATH_MAX];    
	if (FSRefMakePath(&ref, path, sizeof(path)) != noErr)
		return nil;
		
	NSMutableString *dir = [NSMutableString stringWithUTF8String:(const char *)path];
	[dir appendString:@"/"];
	[dir appendString:app];
	
	return dir;
}

+ (BOOL) exists:(NSString *) fname
{
	return getFileMode ([fname UTF8String]) > 0;
}

+ (BOOL) isDir:(NSString *) fname
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
