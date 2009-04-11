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

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/cfgfiles.h"
}

#import "UserCommands.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

@interface oneUserCommand : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*cmd;
}
@end

@implementation oneUserCommand

- (id) initWithName:(const char *) the_name
		cmd:(const char *) the_cmd
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
     
    self->my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"UserCommands" owner:self];
    [[cmd_list window] setTitle:NSLocalizedStringFromTable(@"XChat: User Defined Commands", @"xchat", @"")];
    return self;
}

- (void) dealloc
{
    [cmd_list setDelegate:NULL];
    [[cmd_list window] close];
    [[cmd_list window] release];
    [my_items release];
    [super dealloc];
}

- (void) load_items
{
    [my_items removeAllObjects];

    oneUserCommand *prev = NULL;
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
            oneUserCommand *item = [[[oneUserCommand alloc] 
                            initWithName:pop->name cmd:pop->cmd] autorelease];
            [my_items addObject:item];
            prev = item;
        }
    }

    [cmd_list reloadData];
}

- (void) awakeFromNib
{
	// 10.3 doesn't support small square buttons.
	// This is the next best thing
	NSFont *font = [[[[cmd_list tableColumns] objectAtIndex:0] dataCell] font];
	NSArray *views = [[[cmd_list window] contentView] subviews];
	for (unsigned i = 0; i < [views count]; i ++)
	{
		NSView *view = [views objectAtIndex:i];
		if ([view isKindOfClass:[NSButton class]])
		{
			NSButton *b = (NSButton *) view;
			if ([[b cell] bezelStyle] == NSShadowlessSquareBezelStyle)
				[b setFont:font];
		}
	}

	// Not sure why IB can't do this!
	[[cmd_text enclosingScrollView] setHasHorizontalScroller:YES];
	[cmd_text setHorizontallyResizable:YES];
	[cmd_text setMaxSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[cmd_text textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
	[[cmd_text textContainer] setWidthTracksTextView:NO];

    [[cmd_list window] center];
}

- (void) show
{
	[self load_items];
    [self tableViewSelectionDidChange:NULL];	// TBD: NULL ok?
    [cmd_list selectRow:0 byExtendingSelection:false];
    [[cmd_list window] makeKeyAndOrderFront:self];
}

- (void) do_delete:(id) sender
{
	[cmd_list abortEditing];
    int row = [cmd_list selectedRow];
    if (row < 0) return;
    [my_items removeObjectAtIndex:row];
    [cmd_list reloadData];
    [self tableViewSelectionDidChange:NULL];	// TBD: NULL ok?
}

- (void) do_add:(id) sender
{
    oneUserCommand *item = [[oneUserCommand alloc] initWithName:"*NEW*"
					        cmd:"EDIT ME"];
    [my_items insertObject:item atIndex:0];
    [cmd_list reloadData];
    [cmd_list selectRow:0 byExtendingSelection:false];
    [cmd_list editColumn:0 row:0 withEvent:NULL select:true];
    [self tableViewSelectionDidChange:NULL];	// TBD: NULL ok?
}

- (void) do_ok:(id) sender
{
    // Make sure the current value gets saved
    [self selectionShouldChangeInTableView:cmd_list];
    
    NSString *buf = [NSString stringWithFormat:@"%s/commands.conf", get_xdir_fs ()];
    
    FILE *f = fopen ([buf UTF8String], "w");
    if (!f)
        return;

    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        oneUserCommand *item = [my_items objectAtIndex:i];

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

- (void) do_cancel:(id) sender
{
    [[sender window] orderOut:sender];
}

- (BOOL) selectionShouldChangeInTableView:(NSTableView *) aTableView
{
    int row = [cmd_list selectedRow];
    if (row >= 0)
    {
        oneUserCommand *item = [my_items objectAtIndex:row];
        [item->cmd setString:[cmd_text string]];
    }
    return YES;
}

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    int row = [cmd_list selectedRow];
    if (row >= 0)
    {
        oneUserCommand *item = [my_items objectAtIndex:row];
        [cmd_text setString:item->cmd];
    }
    else
        [cmd_text setString:@""];
}

////////////

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    oneUserCommand *item = [my_items objectAtIndex:rowIndex];
    return item->name;
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(int)rowIndex
{
    oneUserCommand *item = [my_items objectAtIndex:rowIndex];
    [item->name setString:anObject];
}

@end
