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

#import "EditList.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

@interface one_item : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*cmd;
}
@end

@implementation one_item

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

- (NSComparisonResult) sort:(one_item *) other
{
    return [name compare:other->name];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditList

- (id) initWithList:(GSList **) the_slist 
		   fileName:(NSString *) the_fname
              title:(NSString *) the_title
{
    [super init];
     
    self->slist = the_slist;
    self->fname = [the_fname copyWithZone:nil];
    self->title = [the_title copyWithZone:nil];
    self->my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"EditList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [[cmd_list window] release];
    [fname release];
    [title release];
    [my_items release];
	[super dealloc];
}

- (void) awakeFromNib
{
    for (int i = 0; i < [cmd_list numberOfColumns]; i ++)
        [[[cmd_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [cmd_list setDelegate:self];
    [cmd_list setDataSource:self];
    [[cmd_list window] setTitle:title];
    [[cmd_list window] center];
}

- (void) load_items
{
    [my_items removeAllObjects];

    for (GSList *list = *slist; list; list = list->next)
    {
		struct popup *pop = (struct popup *) list->data;
		one_item *item = [[[one_item alloc] 
								initWithName:pop->name cmd:pop->cmd] autorelease];
		[my_items addObject:item];
    }

    [cmd_list reloadData];
}

- (void) show
{
    [self load_items];
    [[cmd_list window] makeKeyAndOrderFront:self];
}

- (void) do_delete:(id) sender
{
	[cmd_list abortEditing];
    int row = [cmd_list selectedRow];
    if (row < 0) return;
    [my_items removeObjectAtIndex:row];
    [cmd_list reloadData];
}

- (void) do_down:(id) sender
{
    unsigned int row = [cmd_list selectedRow];
    if (row < 0 || row >= [my_items count] - 1)
		return;
    [my_items exchangeObjectAtIndex:row withObjectAtIndex:row + 1];
    [cmd_list reloadData];
    [cmd_list selectRow:row + 1 byExtendingSelection:false];
}

- (void) do_help:(id) sender
{
    [SGAlert alertWithString:@"Not implemented (yet)" andWait:false];
}

- (void) do_new:(id) sender
{
  one_item *item = [[one_item alloc] initWithName:"*NEW*" cmd:"EDIT ME"];
  [my_items insertObject:item atIndex:0];
  [cmd_list reloadData];
  [cmd_list
   selectRowIndexes:[NSIndexSet indexSetWithIndex:0]
   byExtendingSelection:NO];
  [cmd_list editColumn:0 row:0 withEvent:nil select:true];
}

- (void) do_save:(id) sender
{
    [[sender window] makeFirstResponder:sender];

    NSString *buf = [NSString stringWithFormat:@"%s/%s", get_xdir_fs (), [fname UTF8String]];
    
    FILE *f = fopen ([buf UTF8String], "w");
    if (!f)
        return;

    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        one_item *item = [my_items objectAtIndex:i];
        fprintf (f, "NAME %s\nCMD %s\n\n", [item->name UTF8String], [item->cmd UTF8String]);
    }
    
    fclose (f);

    list_free (slist);
    list_loadconf ((char *) [fname UTF8String], slist, 0);
    
    [[sender window] orderOut:sender];
}

- (void) do_sort:(id) sender
{
    [my_items sortUsingSelector:@selector (sort:)];
    [cmd_list reloadData];
}

- (void) do_up:(id) sender
{
    int row = [cmd_list selectedRow];
    if (row < 1)
		return;
    [my_items exchangeObjectAtIndex:row withObjectAtIndex:row - 1];
    [cmd_list reloadData];
    [cmd_list selectRow:row - 1 byExtendingSelection:false];
}

////////////

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    one_item *item = [my_items objectAtIndex:rowIndex];
    
    switch ([[aTableColumn identifier] intValue])
    {
		case 0: return item->name;
		case 1: return item->cmd;
    }

    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(NSInteger)rowIndex
{
    one_item *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
		case 0: [item->name setString:anObject]; break;
		case 1: [item->cmd setString:anObject]; break;
    }
}

@end
