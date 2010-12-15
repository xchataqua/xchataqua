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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/cfgfiles.h"

#import "UserCommandsWindow.h"

@interface UserCommandItem : NSObject
{
	NSString *name;
	NSMutableString	*cmd;
}

@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSMutableString *cmd;

+ (UserCommandItem *)commandWithName:(NSString *)name command:(NSString *)command;

@end

@implementation UserCommandItem
@synthesize name, cmd;

+ (UserCommandItem *)commandWithName:(NSString *)aName command:(NSString *)aCommand
{
	UserCommandItem *command = [[self alloc] init];
	command.name = aName;
	command.cmd = [NSMutableString stringWithString:aCommand];
	return [command autorelease];
}

- (void) dealloc
{
	self.name = nil;
	self.cmd = nil;

	[super dealloc];
}

@end

#pragma mark -

@implementation UserCommandsWindow
	 
- (void) dealloc
{
	[commands release];
	[super dealloc];
}

- (void) loadItems
{
	[commands removeAllObjects];
	
	UserCommandItem *prevCommand = nil;
	for (GSList *list = command_list; list; list = list->next)
	{
		struct popup *pop = (struct popup *) list->data;
		
		if (prevCommand && strcasecmp ([[prevCommand name] UTF8String], pop->name) == 0)
		{
			[[prevCommand cmd] appendString:@"\n"];
			[[prevCommand cmd] appendString:[NSString stringWithUTF8String:pop->cmd]];
		}
		else
		{
			UserCommandItem *item = [UserCommandItem commandWithName:[NSString stringWithUTF8String:pop->name] command:[NSString stringWithUTF8String:pop->cmd]];
			[commands addObject:item];
			prevCommand = item;
		}
	}
}

- (void) awakeFromNib
{
	self->commands = [[NSMutableArray alloc] init];

	// Not sure why IB can't do this!
	[commandTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[commandTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[commandTextView textContainer] setWidthTracksTextView:NO];

	[self center];
	
	[self loadItems];
}

- (void)removeCommand:(id)sender
{
	[commandTableView abortEditing];
	NSInteger row = [commandTableView selectedRow];
	if (row < 0) return;
	[commands removeObjectAtIndex:row];
	[commandTableView reloadData];
	[self tableViewSelectionDidChange:nil];	// TBD: NULL ok?
}

- (void)addCommand:(id)sender
{
	[commands insertObject:[UserCommandItem commandWithName:NSLocalizedStringFromTable(@"*NEW*", @"xchat", @"") command:NSLocalizedStringFromTable(@"EDIT ME", @"xchat", @"")] atIndex:0];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[commandTableView editColumn:0 row:0 withEvent:nil select:true];
	[self tableViewSelectionDidChange:nil];	// TBD: NULL ok?
}

- (void) close {
	// Make sure the current value gets saved
	[self selectionShouldChangeInTableView:commandTableView];
	
	NSString *buf = [NSString stringWithFormat:@"%s/commands.conf", get_xdir_fs ()];
	
	FILE *f = fopen ([buf UTF8String], "w");
	if (!f)
		return;
	
	for (NSUInteger i = 0; i < [commands count]; i ++)
	{
		UserCommandItem *item = [commands objectAtIndex:i];
		
		const char *cmd = [[item cmd] UTF8String];
		while (*cmd)
		{
			const char *cr = strchr (cmd, '\n');
			int len = cr ? cr - cmd : strlen (cmd);
			if (len)
				fprintf (f, "NAME %s\nCMD %.*s\n\n", [[item name] UTF8String], len, cmd);
			cmd += len;
			if (cr) cmd++;
		}
	}
	
	fclose (f);
	
	list_free (&command_list);
	list_loadconf ("commands.conf", &command_list, 0);
	
	[super close];
}

#pragma mark NSTableView delegate

#define DATA_ARRAY commands
#	include "UtilityTableViewDragAndDrop.inc.m"
#undef DATA_ARRAY

- (BOOL) selectionShouldChangeInTableView:(NSTableView *)aTableView
{
	NSInteger commandIndex = [commandTableView selectedRow];
	if (commandIndex >= 0)
	{
		UserCommandItem *item = [commands objectAtIndex:commandIndex];
		[[item cmd] setString:[commandTextView string]];
	}
	return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *)aNotification
{
	NSInteger commandIndex = [commandTableView selectedRow];
	if (commandIndex >= 0)
	{
		UserCommandItem *item = [commands objectAtIndex:commandIndex];
		[commandTextView setString:[item cmd]];
	}
	else
	{
		[commandTextView setString:@""];
	}
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [commands count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	UserCommandItem *item = [commands objectAtIndex:rowIndex];
	return [item name];
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	UserCommandItem *item = [commands objectAtIndex:rowIndex];
	[item setName:anObject];
}

@end
