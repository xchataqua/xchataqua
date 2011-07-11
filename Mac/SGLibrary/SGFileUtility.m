//
// SGFileUtility.m
// aquachat
//
// Created by Steve Green on 11/30/05.
// Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "SGFileUtility.h"

@implementation SGFileUtility (Mac)

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

@end