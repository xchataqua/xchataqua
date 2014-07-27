//
//  PluginManager.m
//  XChatAqua
//
//  Created by agnes on 12. 8. 22..
//
//

#define PLUGIN_C
typedef struct session hexchat_context;

#include "cfgfiles.h"
#include "hexchat-plugin.h"
#include "plugin.h"
#include "util.h"

#import "XAFileUtil.h"
#import "PluginManager.h"

extern GSList *plugin_list;

@interface PluginItem ()

- (id)initWithConfiguration:(NSDictionary *)configuration;
- (id)initWithBundleInfo:(NSDictionary *)infoDictionary filename:(NSString *)filename;
+ (id)pluginWithBundleInfo:(NSDictionary *)infoDictionary filename:(NSString *)filename;
- (id)initWithFilename:(NSString *)filename;
+ (id)pluginWithFilename:(NSString *)filename;
- (id)initWithXChatPlugin:(hexchat_plugin *)plugin;
+ (id)pluginWithXChatPlugin:(hexchat_plugin *)plugin;

@end

@implementation PluginItem
@synthesize name=_name, version=_version, filename=_filename, description=_description;

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[PluginItem class]]) {
        return [self.filename isEqualToString:[object filename]];
    }
    return [super isEqual:object];
}

- (id)initWithPath:(NSString *)path {
    if ([path hasSuffix:@".bundle"]) {
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        self = [self initWithBundleInfo:bundle.infoDictionary filename:path];
    } else {
        self = [self initWithFilename:path];
    }
    return self;
}

+ (id)pluginWithPath:(NSString *)path {
    return [[[self alloc] initWithPath:path] autorelease];
}

- (id)initWithConfiguration:(NSDictionary *)configuration {
    self = [super init];
    if (self != nil) {
        
    }
    return self;
}

- (id)initWithBundleInfo:(NSDictionary *)infoDictionary filename:(NSString *)filename {
    self = [super init];
    if (self != nil) {
        NSString *bundleIdentifier = infoDictionary[@"CFBundleIdentifier"];
        self->_name = [[[bundleIdentifier componentsSeparatedByString:@"."] lastObject] copy];
        self->_version = [infoDictionary[@"XChatAquaMacOSVersionBranch"] copy];
        self->_filename = [filename copy];
        self->_description = [@"" copy];
    }
    return self;
}

+ (id)pluginWithBundleInfo:(NSDictionary *)infoDictionary filename:(NSString *)filename {
    return [[[self alloc] initWithBundleInfo:infoDictionary filename:filename] autorelease];
}

- (id)initWithFilename:(NSString *)filename {
    self = [super init];
    if (self != nil) {
        self->_name = [[filename lastPathComponent] copy];
        self->_version = [@"" copy];
        self->_filename = [filename copy];
        self->_description = [@"" copy];
    }
    return self;
}

+ (id)pluginWithFilename:(NSString *)filename {
    return [[[self alloc] initWithFilename:filename] autorelease];
}

- (id)initWithXChatPlugin:(hexchat_plugin *)plugin {
    self = [super init];
    if (self != nil) {
        self->_name = [[NSString alloc] initWithUTF8String:plugin->name];
        self->_version = [[NSString alloc] initWithUTF8String:plugin->version];
        self->_filename = [[NSString alloc] initWithUTF8String:file_part(plugin->filename)];
        self->_description = [[NSString alloc] initWithUTF8String:plugin->desc];
    }
    return self;
}

+ (id)pluginWithXChatPlugin:(hexchat_plugin *)plugin {
    return [[[self alloc] initWithXChatPlugin:plugin] autorelease];
}

- (void)dealloc {
    [self->_name release];
    [self->_version release];
    [self->_filename release];
    [self->_description release];
    [super dealloc];
}

@end

@implementation PluginManager
@synthesize items=_items;

- (id)init {
    self = [super init];
    if (self != nil) {
        self->_items = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)load {  } // abstract
+ (id)sharedPluginManager { return nil; }

@end

@implementation LoadedPluginManager

LoadedPluginManager *LoadedPluginManagerSharedObject;

+ (void)initialize {
    if (self == [LoadedPluginManager class]) {
        LoadedPluginManagerSharedObject = [[self alloc] init];
    }
}

- (void)load {
    [self->_items removeAllObjects];
    
    for (GSList *list = plugin_list; list; list = list->next) {
        hexchat_plugin *pl = (hexchat_plugin *) list->data;
        if (pl->version && pl->version [0]) {
            [self->_items addObject:[PluginItem pluginWithXChatPlugin:pl]];
        }
    }
}

+ (id)sharedPluginManager {
    return LoadedPluginManagerSharedObject;
}

@end

@interface PluginFileManager ()

- (void)loadItems;
- (void)saveItems;

- (void)loadAutoItems;
- (void)saveAutoItems;

- (void)addPluginForFilename:(NSString *)filename;

@end

@implementation PluginFileManager
@synthesize autoItems=_autoItems;

+ (id)sharedPluginManager {
    return nil;
}

+ (NSString *)autoItemConfigurationFilename {
    return nil;
}

- (id)init {
    self = [super init];
    if (self != nil) {
        [self load];
    }
    return self;
}

- (void)dealloc {
    [self->_items release];
    [super dealloc];
}

- (void)load {
    [self loadItems];
    [self loadAutoItems];
}

- (void)loadItems {
    
}

- (void)loadAutoItems {
    [self->_autoItems release];
    self->_autoItems = [[NSMutableArray alloc] initWithContentsOfFile:[[self class] autoItemConfigurationFilename]];
    if (self->_autoItems == nil) {
        self->_autoItems = [[NSMutableArray alloc] init];
    }
}

- (void)addAutoloadItem:(PluginItem *)item {
    [self->_autoItems addObject:item.filename];
}

- (void)removeAutoloadItem:(PluginItem *)item {
    [self->_autoItems removeObject:item.filename];
}

- (bool)hasAutoloadItem:(PluginItem *)item {
    return [self->_autoItems indexOfObject:item.filename] != NSNotFound;
}

- (void)save {
    [self saveItems];
    [self saveAutoItems];
}

- (void)saveItems {
    
}

- (void)saveAutoItems {
    NSString *filename = [[self class] autoItemConfigurationFilename];
    [self->_autoItems writeToFile:filename atomically:YES];
}

- (void)addPluginForFilename:(NSString *)filename {
    PluginItem *item = [PluginItem pluginWithPath:filename];
    [self->_items addObject:item];
}

@end

EmbeddedPluginManager *EmbeddedPluginManagerLoadCallbackReceiver;
void EmbeddedPluginManagerLoadCallback(char *filename) {
    [EmbeddedPluginManagerLoadCallbackReceiver addPluginForFilename:@(filename)];
}

@implementation EmbeddedPluginManager

NSString *EmbeddedPluginConfigurationFilename;
EmbeddedPluginManager *EmbeddedPluginManagerSharedObject;

+ (void)initialize {
    if (self != [EmbeddedPluginManager class]) return;
    
    EmbeddedPluginConfigurationFilename = [[[[XAFileUtil findSupportFolderFor:@PRODUCT_NAME] path] stringByAppendingPathComponent:@"embedpluginsauto.plist"] retain];
    EmbeddedPluginManagerSharedObject = [[self alloc] init];
}

+ (NSString *)autoItemConfigurationFilename {
    return EmbeddedPluginConfigurationFilename;
}

+ (id)sharedPluginManager {
    return EmbeddedPluginManagerSharedObject;
}

- (void)dealloc {
    [self->_autoItems release];
    [super dealloc];
}

- (void)loadItems {
    [self->_items removeAllObjects];
    NSString *path = [[NSBundle mainBundle] builtInPlugInsPath];
    const char *cpath = path.UTF8String;
    EmbeddedPluginManagerLoadCallbackReceiver = self;
    for_files ((char *)cpath, "*.bundle", EmbeddedPluginManagerLoadCallback);
    for_files ((char *)cpath, "*.??", EmbeddedPluginManagerLoadCallback);
}

- (void)addAutoloadItem:(PluginItem *)item {
    [self.autoItems addObject:item.name];
}

- (void)removeAutoloadItem:(PluginItem *)item {
    [self.autoItems removeObject:item.name];
}

- (bool)hasAutoloadItem:(PluginItem *)item {
    return [self.autoItems indexOfObject:item.name] != NSNotFound;
}

@end

NSString *UserPluginConfigurationFilename;
UserPluginManager *UserPluginManagerSharedObject;
UserPluginManager *UserPluginManagerLoadCallbackReceiver;
void UserPluginManagerLoadCallback(char *filename) {
    [EmbeddedPluginManagerLoadCallbackReceiver addPluginForFilename:@(filename)];
}

@implementation UserPluginManager

+ (void)initialize {
    if (self != [UserPluginManager class]) return;

    UserPluginConfigurationFilename = [[[[XAFileUtil findSupportFolderFor:@PRODUCT_NAME] path] stringByAppendingPathComponent:@"pluginsauto.plist"] copy];
    UserPluginManagerSharedObject = [[self alloc] init];
}

+ (NSString *)autoItemConfigurationFilename {
    return UserPluginConfigurationFilename;
}

+ (id)sharedPluginManager {
    return UserPluginManagerSharedObject;
}

- (void)loadItems {
    [self->_items removeAllObjects];
    NSString *path = [[[XAFileUtil findSupportFolderFor:@PRODUCT_NAME] path] stringByAppendingPathComponent:@"plugins"];
    const char *cpath = path.UTF8String;
    UserPluginManagerLoadCallbackReceiver = self;
    for_files ((char *)cpath, "*.bundle", UserPluginManagerLoadCallback);
    for_files ((char *)cpath, "*.??", UserPluginManagerLoadCallback);
}

- (void)addItemWithFilename:(NSString *)filename {
    NSString *name = [filename lastPathComponent];
    NSString *pluginDirectory = [[[XAFileUtil findSupportFolderFor:@PRODUCT_NAME] path] stringByAppendingPathComponent:@"plugins"];
    NSString *pluginFilename = [pluginDirectory stringByAppendingPathComponent:name];
    NSString *cmd = [@"rm -rf '%@'" format:pluginFilename];
    system(cmd.UTF8String); // if directory...
    cmd = [@"cp -R '%@' '%@'" format:filename, [pluginDirectory stringByAppendingString:@"/"]];
    system(cmd.UTF8String); // install
    [self.items addObject:[PluginItem pluginWithFilename:pluginFilename]];
}

@end
