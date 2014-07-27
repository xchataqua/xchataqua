/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
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

/* PluginWindow.h
 * Correspond to fe-gtk: xchat/src/fe-gtk/plugingui.*
 * Correspond to main menu: Window -> Plugins and Scripts...
 */

typedef struct session xchat_context;

#include "outbound.h"
#include "hexchat-plugin.h"
#include "plugin.h"
#include "util.h"

extern GSList *plugin_list;

#import "AquaChat.h"
#import "XAFileUtil.h"
#import "PluginWindow.h"

#import "PluginManager.h"

#import "NSPanelAdditions.h"

#pragma mark -

@interface PluginWindow ()

- (void)unloadPluginWithName:(NSString *)name;

@end

@implementation PluginWindow
@synthesize tableViewDataSource;

- (void) awakeFromNib
{
    [self center];
    [self update];
}

- (void) update
{
    [self->embeddedPluginTableView reloadData];
    [self->userPluginTableView reloadData];
    PluginManager *manager = [LoadedPluginManager sharedPluginManager];
    [manager load];
    [self->loadedPluginTableView reloadData];
}

- (void)unloadPluginWithName:(NSString *)name {
    NSUInteger len = name.length;
    char *cString = (char *)name.UTF8String;
    if (len > 3 && strcasecmp (cString + len - 3, ".so") == 0)
    {
        if (plugin_kill (cString, false) == 2)
            [SGAlert alertWithString:NSLocalizedStringFromTable(@"That plugin is refusing to unload.\n", @"xchat", @"") andWait:false];
    }
    else
    {
        NSString *cmd = [NSString stringWithFormat:@"UNLOAD \"%@\"", name];
        handle_command (current_sess, (char *)[cmd UTF8String], false);
    }
}

#pragma mark IBAction

- (void)addUserPlugin:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel commonOpenPanel];
    [panel beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            UserPluginManager *manager = [UserPluginManager sharedPluginManager];
            [manager addItemWithFilename:panel.URL.path];
            [manager save];
        }
    }];
}

- (void)removeUserPlugin:(id)sender {
    NSInteger row = [self->userPluginTableView selectedRow];
    if (row < 0)
        return;
    PluginFileManager *manager = [UserPluginManager sharedPluginManager];
    PluginItem *item = (manager.items)[row];

    [manager.items removeObject:item];
    [manager save];
}

- (void) loadPlugin:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel commonOpenPanel];
    [panel beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        NSString *cmd = [NSString stringWithFormat:@"LOAD \"%@\"", panel.URL.path];
        handle_command (current_sess, (char *) [cmd UTF8String], FALSE);
    }];
}

- (void) unloadPlugin:(id)sender {
    NSInteger row = [self->loadedPluginTableView selectedRow];
    if (row < 0)
        return;
    
    PluginManager *manager = [UserPluginManager sharedPluginManager];
    PluginItem *item = (manager.items)[row];
    [self unloadPluginWithName:item.filename];
}

- (void)showStartupItemsInFinder:(id)sender {
    NSString *path = [[[XAFileUtil findSupportFolderFor:@PRODUCT_NAME] path] stringByAppendingPathComponent:@"plugins"];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path isDirectory:YES]];
}

- (void)showBundledItemsInFinder:(id)sender {
    NSString *path;
    path = [[NSBundle mainBundle] builtInPlugInsPath];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:path isDirectory:YES]];
}

#pragma mark NSTableView DataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView {
    PluginManager *manager = [LoadedPluginManager sharedPluginManager];
    return manager.items.count;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    PluginManager *manager = [LoadedPluginManager sharedPluginManager];

    PluginItem *item = (manager.items)[rowIndex];
    
    switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
    {
        case 0: return item.name;
        case 1: return item.version;
        case 2: return item.filename;
        case 3: return item.description;
    }
    dassert(NO);
    return @"";
}

@end

@interface PluginWindow (TableView)

@property(nonatomic, readonly) NSTableView *embeddedPluginTableView, *userPluginTableView, *loadedPluginTableView;

@end

@implementation PluginWindow (TableView)

- (NSTableView *)embeddedPluginTableView { return self->embeddedPluginTableView; }
- (NSTableView *)userPluginTableView { return self->userPluginTableView; }
- (NSTableView *)loadedPluginTableView { return self->loadedPluginTableView; }

@end

@implementation PluginFileTableViewDataSource

- (PluginFileManager *)managerForTableView:(NSTableView *)aTableView {
    PluginFileManager *manager = nil;
    if (aTableView == self->window.embeddedPluginTableView) {
        manager = [EmbeddedPluginManager sharedPluginManager];
    } else if (aTableView == self->window.userPluginTableView) {
        manager = [UserPluginManager sharedPluginManager];
    }
    return manager;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self managerForTableView:tableView].items.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    PluginFileManager *manager = [self managerForTableView:tableView];
    
    PluginItem *item = (manager.items)[row];
    
    switch ([[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn])
    {
        case 0: return @([manager hasAutoloadItem:item]);
        case 1: return item.name;
        case 2: return item.version;
        case 3: return [item.filename lastPathComponent];
    }
    dassert(NO);
    return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    PluginFileManager *manager = [self managerForTableView:aTableView];
    PluginItem *item = (manager.items)[rowIndex];
    
    NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
    switch (column) {
        case 0: {
            if ([anObject boolValue]) {
                [manager addAutoloadItem:item];
                NSString *cmd = [NSString stringWithFormat:@"LOAD \"%@\"", item.filename];
                handle_command (current_sess, (char *)cmd.UTF8String, FALSE);
            } else {
                [manager removeAutoloadItem:item];
                NSString *cmd = [NSString stringWithFormat:@"UNLOAD \"%@\"", item.name];
                handle_command (current_sess, (char *)cmd.UTF8String, FALSE);
            }
            [self->window update];
        }   break;
        default:
            return;
    }
    [manager save];
}

@end
