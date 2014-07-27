//
//  xchatext.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 18..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "SystemVersion.h"

#include "text.h"
#include "plugin.h"

char *get_xdir_fs(void) {
    static NSString *path = nil;
    if (path == nil) {
        path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0] copy];
    }
    return (char *)[path UTF8String];
}


char *get_appdir_fs(void) {
    return (char *)[[[NSBundle mainBundle] bundlePath] UTF8String];
}

char *get_downloaddir_fs(void) {
    static NSString *path = nil;
    if (path == nil) {
        path = [NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0] copy];
    }
    return (char *)[path UTF8String];
}

char *get_plugin_bundle_path(char *filename) {
    return NULL; // not available
}

void aqua_plugin_auto_load(struct session *ps) {
    
}
