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
#include "../common/xchat-plugin.h"
#include "../common/plugin.h"
#include "../common/util.h"

extern GSList *plugin_list;

#import "AquaChat.h"
#import "PluginWindow.h"

@interface PluginItem : NSObject
{
  @public
	NSString *name, *vers, *file, *desc;
}

- (id) initWithPlugin:(xchat_plugin *)plugin;

@end

@implementation PluginItem

- (id) initWithPlugin:(xchat_plugin *) plugin
{
	if ((self=[super init]) != nil) {
		name = [[NSString alloc] initWithUTF8String:plugin->name];
		vers = [[NSString alloc] initWithUTF8String:plugin->version];
		file = [[NSString alloc] initWithUTF8String:file_part(plugin->filename)];
		desc = [[NSString alloc] initWithUTF8String:plugin->desc];
	}
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

#pragma mark -

@implementation PluginWindow

- (id) initWithCoder:(NSCoder *)aDecoder {
	if ((self = [super initWithCoder:aDecoder]) != nil) {
		self->plugins = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc
{
	[self->pluginTableView setDataSource:nil];
	[plugins release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self center];
	[self update];
}

- (void) update
{
	[plugins removeAllObjects];
	
	for (GSList *list = plugin_list; list; list = list->next)
	{
		xchat_plugin *pl = (xchat_plugin *) list->data;
		if (pl->version && pl->version [0])
			[plugins addObject:[[PluginItem alloc] initWithPlugin:pl]];
	}
	
	[self->pluginTableView reloadData];
}

#pragma mark -
#pragma mark IBAction

- (void) loadPlugin:(id)sender {
	[[AquaChat sharedAquaChat] loadPlugin:sender];
}

- (void) unloadPlugin:(id)sender {
	NSInteger row = [self->pluginTableView selectedRow];
	if (row < 0)
		return;
	
	PluginItem *item = [plugins objectAtIndex:row];
	
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

#pragma mark -
#pragma mark NSTableView DataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [plugins count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	PluginItem *item = [plugins objectAtIndex:rowIndex];

	switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
	{
		case 0: return item->name;
		case 1: return item->vers;
		case 2: return item->file;
		case 3: return item->desc;
	}
	SGAssert(NO);
	return @"";
}

@end
