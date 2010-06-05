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

#import "UserCommands.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

@interface OneUserCommand : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*cmd;
}
@end

@implementation OneUserCommand

- (id) initWithName:(const char *)the_name cmd:(const char *) the_cmd
{
    name = [[NSMutableString stringWithUTF8String:the_name] retain];
    cmd = [[NSMutableString stringWithUTF8String:the_cmd] retain];
    
    return self;
}

- (void) dealloc
{
    [name release];
    [cmd release];

    [super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation UserCommands

- (id) init
{
    [super init];
     
    self->myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"UserCommands" owner:self];
    [[commandTableView window] setTitle:NSLocalizedStringFromTable(@"XChat: User Defined Commands", @"xchat", @"")];
    return self;
}

- (void) dealloc
{
    [commandTableView setDelegate:nil];
    [[commandTableView window] close];
    [[commandTableView window] release];
    [myItems release];
    [super dealloc];
}

- (void) loadItems
{
    [myItems removeAllObjects];

    OneUserCommand *prev = nil;
    for (GSList *list = command_list; list; list = list->next)
    {
		struct popup *pop = (struct popup *) list->data;
        
        if (prev && strcasecmp ([prev->name UTF8String], pop->name) == 0)
        {
            [prev->cmd appendString:@"\n"];
            [prev->cmd appendString:[NSString stringWithUTF8String:pop->cmd]];
        }
        else
        {
            OneUserCommand *item = [[[OneUserCommand alloc] initWithName:pop->name cmd:pop->cmd] autorelease];
            [myItems addObject:item];
            prev = item;
        }
    }

    [commandTableView reloadData];
}

- (void) awakeFromNib
{
	// 10.3 doesn't support small square buttons.
	// This is the next best thing
	NSFont *font = [[[[commandTableView tableColumns] objectAtIndex:0] dataCell] font];
	for (NSView *view in [[[commandTableView window] contentView] subviews])
	{
		if ([view isKindOfClass:[NSButton class]])
		{
			NSButton *button = (NSButton *) view;
			if ([[button cell] bezelStyle] == NSShadowlessSquareBezelStyle)
				[button setFont:font];
		}
	}

	// Not sure why IB can't do this!
	[[commandTextView enclosingScrollView] setHasHorizontalScroller:YES];
	[commandTextView setHorizontallyResizable:YES];
	[commandTextView setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[commandTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[commandTextView textContainer] setWidthTracksTextView:NO];

    [[commandTableView window] center];
}

- (void) show
{
	[self loadItems];
	[self tableViewSelectionDidChange:nil];	// TBD: NULL ok?
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[[commandTableView window] makeKeyAndOrderFront:self];
}

- (void) doDelete:(id) sender
{
	[commandTableView abortEditing];
	NSInteger row = [commandTableView selectedRow];
	if (row < 0) return;
	[myItems removeObjectAtIndex:row];
	[commandTableView reloadData];
	[self tableViewSelectionDidChange:nil];	// TBD: NULL ok?
}

- (void) doAdd:(id) sender
{
	OneUserCommand *item = [[OneUserCommand alloc] initWithName:"*NEW*" cmd:"EDIT ME"];
	[myItems insertObject:item atIndex:0];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[commandTableView editColumn:0 row:0 withEvent:nil select:true];
	[self tableViewSelectionDidChange:nil];	// TBD: NULL ok?
}

- (void) doOk:(id) sender
{
    // Make sure the current value gets saved
    [self selectionShouldChangeInTableView:commandTableView];
    
    NSString *buf = [NSString stringWithFormat:@"%s/commands.conf", get_xdir_fs ()];
    
    FILE *f = fopen ([buf UTF8String], "w");
    if (!f)
        return;

    for (NSUInteger i = 0; i < [myItems count]; i ++)
    {
        OneUserCommand *item = [myItems objectAtIndex:i];

        const char *cmd = [item->cmd UTF8String];
        while (*cmd)
        {
            const char *cr = strchr (cmd, '\n');
            int len = cr ? cr - cmd : strlen (cmd);
            if (len)
                fprintf (f, "NAME %s\nCMD %.*s\n\n", [item->name UTF8String], len, cmd);
            cmd += len;
            if (cr) cmd++;
        }
    }
    
    fclose (f);

    list_free (&command_list);
    list_loadconf ("commands.conf", &command_list, 0);
    
    [[sender window] orderOut:sender];
}

- (void) doCancel:(id) sender
{
    [[sender window] orderOut:sender];
}

- (BOOL) selectionShouldChangeInTableView:(NSTableView *) aTableView
{
    NSInteger row = [commandTableView selectedRow];
    if (row >= 0)
    {
        OneUserCommand *item = [myItems objectAtIndex:row];
        [item->cmd setString:[commandTextView string]];
    }
    return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    NSInteger row = [commandTableView selectedRow];
    if (row >= 0)
    {
        OneUserCommand *item = [myItems objectAtIndex:row];
        [commandTextView setString:item->cmd];
    }
    else
        [commandTextView setString:@""];
}

////////////

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [myItems count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    OneUserCommand *item = [myItems objectAtIndex:rowIndex];
    return item->name;
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(NSInteger)rowIndex
{
    OneUserCommand *item = [myItems objectAtIndex:rowIndex];
    [item->name setString:anObject];
}

@end
