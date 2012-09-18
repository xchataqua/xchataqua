//
//  xchatext.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 18..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "SystemVersion.h"

#import "PluginManager.h"

#include "text.h"
#include "plugin.h"

char *get_xdir_fs(void) {
    static NSString *applicationSupportDirectory = nil;
    if (applicationSupportDirectory == nil) {
        applicationSupportDirectory = [[SGFileUtility findApplicationSupportFor:@PRODUCT_NAME] retain];
    }
    return (char *)[applicationSupportDirectory UTF8String];
}

char *get_appdir_fs(void) {
    return (char *)[[[NSBundle mainBundle] bundlePath] UTF8String];
}

char *get_downloaddir_fs(void) {
    FSRef ref;
    if (FSFindFolder(kUserDomain, kDownloadsFolderType, false, &ref) != noErr)
        return NULL;
    UInt8 *path = malloc(sizeof(UInt8) * PATH_MAX);
    if (FSRefMakePath(&ref, path, sizeof(UInt8) * PATH_MAX) != noErr) {
        free(path);
        return NULL;
    }
    
    return (char *)path;
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

void aqua_plugin_auto_load_item(struct session *ps, const char *filename) {
    char *pMsg = plugin_load (ps, (char *)filename, NULL);
	if (pMsg)
	{
		PrintTextf (ps, "AutoLoad failed for: %s\n", filename);
		PrintText (ps, pMsg);
	}
}

void aqua_plugin_auto_load(struct session *ps) {
    PluginFileManager *manager = [EmbeddedPluginManager sharedPluginManager];
    for (PluginItem *item in manager.items) {
        if ([manager hasAutoloadItem:item]) {
            aqua_plugin_auto_load_item(ps, item.filename.UTF8String);
        }
    }
    manager = [UserPluginManager sharedPluginManager];
    for (PluginItem *item in manager.items) {
        if ([manager hasAutoloadItem:item]) {
            aqua_plugin_auto_load_item(ps, item.filename.UTF8String);
        }
    }
}
