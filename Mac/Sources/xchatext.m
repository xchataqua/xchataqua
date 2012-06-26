//
//  xchatext.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 18..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "SystemVersion.h"

char *get_xdir_fs(void)
{
    static NSString *applicationSupportDirectory = nil;
    if (applicationSupportDirectory == nil) {
        applicationSupportDirectory = [[SGFileUtility findApplicationSupportFor:@PRODUCT_NAME] retain];
    }
    return (char *)[applicationSupportDirectory UTF8String];
}

char *get_appdir_fs(void)
{
    return (char *)[[[NSBundle mainBundle] bundlePath] UTF8String];
}

char *get_plugin_bundle_path(char *filename) {
    NSString *bundlePath = [NSString stringWithUTF8String:filename];
    NSBundle *bundle = [NSBundle bundleWithPath:bundlePath];
    if (bundle == nil) {
        return NULL;
    }
    
    NSString *version = [[bundle infoDictionary] objectForKey:@"XChatAquaMacOSVersionBranch"];
    if(version != nil && [[SystemVersion systemBranch] compare:version options:NSNumericSearch] != NSOrderedSame) {
        return NULL;
    }
    
    NSString *path = [bundle executablePath];
    return (char *)[path fileSystemRepresentation];
}
