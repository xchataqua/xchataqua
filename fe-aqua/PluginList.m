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

#define PLUGIN_C
typedef struct session xchat_context;

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/xchat-plugin.h"
#include "../common/plugin.h"
#include "../common/util.h"

extern GSList *plugin_list;

#import "AquaChat.h"
#import "PluginList.h"

//////////////////////////////////////////////////////////////////////

@interface OnePlugin : NSObject
{
  @public
    NSString	*name;
    NSString	*vers;
    NSString	*file;
    NSString	*desc;
}

- (id) initWithPlugin:(xchat_plugin *) plugin;

@end

@implementation OnePlugin

- (id) initWithPlugin:(xchat_plugin *) plugin
{
    name = [[NSString stringWithUTF8String:plugin->name] retain];
    vers = [[NSString stringWithUTF8String:plugin->version] retain];
    file = [[NSString stringWithUTF8String:file_part(plugin->filename)] retain];
    desc = [[NSString stringWithUTF8String:plugin->desc] retain];
    
    return self;
}

- (void) dealloc
{
    [name release];
    [vers release];
    [file release];
    [desc dealloc];
	[super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation PluginList

- (id) initWithSelfPtr:(id *)self_ptr
{
    self = [super initWithSelfPtr:self_ptr];
   
    self->myItems = [[NSMutableArray arrayWithCapacity:0] retain];

    [NSBundle loadNibNamed:@"PluginList" owner:self];

    return self;
}

- (void) dealloc
{
    [self->pluginListTableView setDataSource:nil];
    [[self->pluginListTableView window] autorelease];
    [myItems release];
    [super dealloc];
}

- (void) doUnload:(id) sender
{
    NSInteger row = [self->pluginListTableView selectedRow];
    if (row < 0)
        return;
    
    OnePlugin *item = [myItems objectAtIndex:row];

    NSUInteger len = [item->file length];
    if (len > 3 && strcasecmp ([item->file UTF8String] + len - 3, ".so") == 0)
    {
        if (plugin_kill ((char *) [item->name UTF8String], false) == 2)
            [SGAlert alertWithString:NSLocalizedStringFromTable(@"That plugin is refusing to unload.\n", @"xchat", @"") andWait:false];
    }
    else
    {
        NSString *cmd = [NSString stringWithFormat:@"UNLOAD \"%@\"", item->file];
        handle_command (current_sess, (char *)[cmd UTF8String], false);
    }
}

- (void) doLoad:(id) sender
{
    [[AquaChat sharedAquaChat] do_load_plugin:sender];
}

- (void) loadData
{
    [myItems removeAllObjects];

    for (GSList *list = plugin_list; list; list = list->next)
    {
    	xchat_plugin *pl = (xchat_plugin *) list->data;
        if (pl->version && pl->version [0])
            [myItems addObject:[[OnePlugin alloc] initWithPlugin:pl]];
    }

    [self->pluginListTableView reloadData];
}

- (void) awakeFromNib
{
    for (NSUInteger i = 0; i < [self->pluginListTableView numberOfColumns]; i ++)
        [[[self->pluginListTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->pluginListTableView setDataSource:self];
    [[self->pluginListTableView window] setDelegate:self];
    [[self->pluginListTableView window] center];

    [self loadData];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self release];
}

- (void) show
{
    [[self->pluginListTableView window] makeKeyAndOrderFront:self];
}

- (void) update
{
    [self loadData];
}

//////////////
//

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [myItems count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    OnePlugin *item = [myItems objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] integerValue])
    {
        case 0: return item->name;
        case 1: return item->vers;
        case 2: return item->file;
        case 3: return item->desc;
    }
    
    return @"";
}

@end
