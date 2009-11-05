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

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/xchat-plugin.h"
#include "../common/plugin.h"
#include "../common/util.h"
}

extern GSList *plugin_list;

#import "AquaChat.h"
#import "PluginList.h"

//////////////////////////////////////////////////////////////////////

@interface onePlugin : NSObject
{
  @public
    NSString	*name;
    NSString	*vers;
    NSString	*file;
    NSString	*desc;
}

- (id) initWithPlugin:(xchat_plugin *) plugin;

@end

@implementation onePlugin

- (id) initWithPlugin:(xchat_plugin *) plugin
{
    name = [[NSString stringWithUTF8String:plugin->name] retain];
    vers = [[NSString stringWithUTF8String:plugin->version] retain];
    file = [[NSString stringWithUTF8String:file_part (plugin->filename)] retain];
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

- (id) initWithSelfPtr:(id *) self_ptr
{
    [super initWithSelfPtr:self_ptr];
   
    self->my_items = [[NSMutableArray arrayWithCapacity:0] retain];

    [NSBundle loadNibNamed:@"PluginList" owner:self];

    return self;
}

- (void) dealloc
{
    [self->plugin_list_table setDataSource:NULL];
    [[self->plugin_list_table window] autorelease];
    [my_items release];
    [super dealloc];
}

- (void) do_unload:(id) sender
{
    int row = [self->plugin_list_table selectedRow];
    if (row < 0)
        return;
    
    onePlugin *item = [my_items objectAtIndex:row];

    int len = [item->file length];
    if (len > 3 && strcasecmp ([item->file UTF8String] + len - 3, ".so") == 0)
    {
        if (plugin_kill ((char *) [item->name UTF8String], FALSE) == 2)
            [SGAlert alertWithString:NSLocalizedStringFromTable(@"That plugin is refusing to unload.\n", @"xchat", @"") andWait:false];
    }
    else
    {
        NSString *cmd = [NSString stringWithFormat:@"UNLOAD \"%@\"", item->file];
        handle_command (current_sess, (char *) [cmd UTF8String], FALSE);
    }
}

- (void) do_load:(id) sender
{
    [[AquaChat sharedAquaChat] do_load_plugin:sender];
}

- (void) load_data
{
    [my_items removeAllObjects];

    for (GSList *list = plugin_list; list; list = list->next)
    {
    	xchat_plugin *pl = (xchat_plugin *) list->data;
        if (pl->version && pl->version [0])
            [my_items addObject:[[onePlugin alloc] initWithPlugin:pl]];
    }

    [self->plugin_list_table reloadData];
}

- (void) awakeFromNib
{
    for (int i = 0; i < [self->plugin_list_table numberOfColumns]; i ++)
        [[[self->plugin_list_table tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->plugin_list_table setDataSource:self];
    [[self->plugin_list_table window] setDelegate:self];
    [[self->plugin_list_table window] center];

    [self load_data];
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
    [[self->plugin_list_table window] makeKeyAndOrderFront:self];
}

- (void) update
{
    [self load_data];
}

//////////////
//

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    onePlugin *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->name;
        case 1: return item->vers;
        case 2: return item->file;
        case 3: return item->desc;
    }
    
    return @"";
}

@end
