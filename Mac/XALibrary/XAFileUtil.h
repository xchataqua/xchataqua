//
//  XAFileUtil.h
//  XChatAqua
//
//  Created by Terje Bless on 2012-09-03.
//
//

#import <Foundation/Foundation.h>

@interface XAFileUtil : NSObject
+ (BOOL) exists:(NSURL *)url;
+ (BOOL) isDirectory:(NSURL *)url;
+ (BOOL) isSymLink:(NSURL *)url;
+ (NSURL *) findSupportFolderFor:(NSString *)app;
+ (NSURL *) findSupportFolderFor:(NSString *)app named:(NSString *)folder;
+ (BOOL) createSupportFolderFor:(NSString *)app error:(NSError **)err;
+ (BOOL) createSupportFolderFor:(NSString *)app named:(NSString *)folder error:(NSError **)err;
@end
