//
//  SGFileUtil.h
//  aquachat
//
//  Created by Steve Green on 11/30/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SGFileUtil : NSObject

+ (NSString *) findApplicationSupportFor:(NSString *) app;
+ (BOOL) exists:(NSString *) fname;
+ (BOOL) isDir:(NSString *) fname;
+ (BOOL) isSymLink:(NSString *) fname;

@end
