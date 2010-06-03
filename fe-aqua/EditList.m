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

#import "EditList.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

@interface OneItem : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*command;
}
@end

@implementation OneItem

- (id) initWithName:(const char *)aName command:(const char *)aCommand
{
    name = [[NSMutableString stringWithUTF8String:aName] retain];
    command = [[NSMutableString stringWithUTF8String:aCommand] retain];
    
    return self;
}

- (void) dealloc
{
    [name release];
    [command release];

    [super dealloc];
}

- (NSComparisonResult) sort:(OneItem *) other
{
    return [name compare:other->name];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditList

- (id) initWithList:(GSList **)aSlist filename:(NSString *)aFilename title:(NSString *)aTitle
{
    self = [super init];
     
    self->slist = aSlist;
    self->filename = [aFilename copyWithZone:nil];
    self->title = [aTitle copyWithZone:nil];
    self->myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"EditList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [[commandTableView window] release];
    [filename release];
    [title release];
    [myItems release];
	[super dealloc];
}

- (void) awakeFromNib
{
    for (NSUInteger i = 0; i < [commandTableView numberOfColumns]; i ++)
        [[[commandTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [commandTableView setDelegate:self];
    [commandTableView setDataSource:self];
    [[commandTableView window] setTitle:title];
    [[commandTableView window] center];
}

- (void) loadItems
{
    [myItems removeAllObjects];

    for (GSList *list = *slist; list; list = list->next)
    {
		struct popup *pop = (struct popup *) list->data;
		OneItem *item = [[[OneItem alloc] initWithName:pop->name command:pop->cmd] autorelease];
		[myItems addObject:item];
    }

    [commandTableView reloadData];
}

- (void) show
{
    [self loadItems];
    [[commandTableView window] makeKeyAndOrderFront:self];
}

- (void) doDelete:(id)sender
{
	[commandTableView abortEditing];
    NSInteger row = [commandTableView selectedRow];
    if (row < 0) return;
    [myItems removeObjectAtIndex:row];
    [commandTableView reloadData];
}

- (void) doDown:(id) sender
{
	NSInteger row = [commandTableView selectedRow];
	if (row < 0 || row >= (NSInteger)[myItems count] - 1) return;

	[myItems exchangeObjectAtIndex:row withObjectAtIndex:row + 1];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row + 1] byExtendingSelection:NO];
}

- (void) doHelp:(id) sender
{
    [SGAlert alertWithString:NSLocalizedStringFromTable(@"Not implemented (yet)",@"xchataqua",@"Alert message when a feature not implemented yet is tried") andWait:false];
}

- (void) doNew:(id) sender
{
	OneItem *item = [[OneItem alloc] initWithName:"*NEW*" command:"EDIT ME"];
	[myItems insertObject:item atIndex:0];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	[commandTableView editColumn:0 row:0 withEvent:nil select:YES];
}

- (void) doSave:(id) sender
{
    [[sender window] makeFirstResponder:sender];

    NSString *buf = [NSString stringWithFormat:@"%s/%s", get_xdir_fs(), [filename UTF8String]];
    
    FILE *f = fopen ([buf UTF8String], "w");
    if (f == NULL) return;

    for (NSUInteger i = 0; i < [myItems count]; i ++)
    {
        OneItem *item = [myItems objectAtIndex:i];
        fprintf (f, "NAME %s\ncommand %s\n\n", [item->name UTF8String], [item->command UTF8String]);
    }
    fclose (f);

    list_free(slist);
    list_loadconf((char *)[filename UTF8String], slist, 0);
    
    [[sender window] orderOut:sender];
}

- (void) doSort:(id) sender
{
    [myItems sortUsingSelector:@selector(sort:)];
    [commandTableView reloadData];
}

- (void) doUp:(id) sender
{
	NSInteger row = [commandTableView selectedRow];
	if (row < 1)
		return;
	[myItems exchangeObjectAtIndex:row withObjectAtIndex:row - 1];
	[commandTableView reloadData];
	[commandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row-1] byExtendingSelection:NO];
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
    OneItem *item = [myItems objectAtIndex:rowIndex];
    
    switch ([[aTableColumn identifier] intValue])
    {
		case 0: return item->name;
		case 1: return item->command;
    }

    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(NSInteger)rowIndex
{
    OneItem *item = [myItems objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
		case 0: [item->name setString:anObject]; break;
		case 1: [item->command setString:anObject]; break;
    }
}

@end
