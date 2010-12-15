//
//  SGFileUtility.h
//  aquachat
//
//  Created by Steve Green on 11/30/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

@interface SGFileUtility : NSObject

+ (NSString *) findApplicationSupportFor:(NSString *)app;
+ (BOOL) exists:(NSString *)filename;
+ (BOOL) isDirectory:(NSString *)filename;
+ (BOOL) isSymLink:(NSString *)filename;

@end
