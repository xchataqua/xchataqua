//
//  PluginManager.h
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 8. 22..
/*
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

@interface PluginItem : NSObject {
    NSString *_name;
    NSString *_version;
    NSString *_filename;
    NSString *_description;
}

@property(nonatomic, readonly) NSString *name, *version, *filename, *description;

- (id)initWithPath:(NSString *)path;
+ (id)pluginWithPath:(NSString *)path;

@end

@interface PluginManager : NSObject {
    NSMutableArray *_items;
}

@property(nonatomic, readonly) NSMutableArray *items;

- (void)load;
+ (id)sharedPluginManager;

@end

@interface LoadedPluginManager : PluginManager

@end

// abstract
@interface PluginFileManager : PluginManager {
    NSMutableArray *_autoItems;
}

@property(nonatomic, readonly) NSMutableArray *autoItems;

+ (NSString *)autoItemConfigurationFilename;

- (void)save;
- (void)addAutoloadItem:(PluginItem *)item;
- (void)removeAutoloadItem:(PluginItem *)item;
- (bool)hasAutoloadItem:(PluginItem *)item;

@end

@interface EmbeddedPluginManager : PluginFileManager

@end

@interface UserPluginManager : PluginFileManager

- (void)addItemWithFilename:(NSString *)filename;

@end
