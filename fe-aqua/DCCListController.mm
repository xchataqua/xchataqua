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
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/dcc.h"
}

#import "SG.h"
#import "AquaChat.h"
#import "ColorPalette.h"
#import "DCCListController.h"
#import "XACommon.h"

//////////////////////////////////////////////////////////////////////

@implementation DCCItem

- (id) initWithDCC:(struct DCC *) the_dcc
{
    dcc = the_dcc;
	prev_dccstat = dcc->dccstat;
    
    status = [[NSMutableString stringWithCapacity:0] retain];
   
    return self;
}

- (void) dealloc
{
    [status release];

    [super dealloc];
}

- (void) update
{
    [status setString:[NSString stringWithUTF8String:dccstat[(int) dcc->dccstat].name]];
	prev_dccstat = dcc->dccstat;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation DCCListController

- (id) initWithNibNamed:(NSString *)nibName
{
    [super init];

    my_items = [[NSMutableArray arrayWithCapacity:0] retain];	// this must be done before loading the nib
	
	hasSelection = NO;
	lastDCCStatus = 0xFF;
    
    [NSBundle loadNibNamed:nibName owner:self];
    
    return self;
}

- (void) dealloc
{
    [dcc_list_view dealloc];
    [my_items release];
    [super dealloc];
}

- (DCCItem *)itemWithDCC:(struct DCC *) dcc
{
	// subclasses must implement this; return nil if the item is of the wrong type and should not be added to this list
	return nil;
}

- (void)setActiveCount:(unsigned)count
{
	activeCount = count;
}

- (void) load_data
{
    [my_items removeAllObjects];

	[self setActiveCount:0];
    for (GSList *list = dcc_list; list; list = list->next)
    {
        struct DCC *dcc = (struct DCC *) list->data;
        
		[self add:dcc];	/* itemWithDCC will determine if the item is the right type */
    }

    [item_list reloadData];
}

- (void) awakeFromNib
{
    for (int i = 0; i < [item_list numberOfColumns]; i ++)
        [[[item_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [item_list setDataSource:self];
    [item_list setDelegate:self];
	[self setNextResponder: [item_list nextResponder]];
    [item_list setNextResponder:self];
	
	[dcc_list_view setDelegate:self];

    [self load_data];
}

- (void) show:(bool) and_bring_to_front
{
    if (prefs.windows_as_tabs)
        [dcc_list_view becomeTabAndShow:and_bring_to_front];
    else
        [dcc_list_view becomeWindowAndShow:and_bring_to_front];
}

- (void) update:(struct DCC *) dcc
{
    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        DCCItem *item = [my_items objectAtIndex:i];
        if (item->dcc == dcc)
        {
			if (item->prev_dccstat != dcc->dccstat) {
				if (item->prev_dccstat == STAT_ACTIVE) [self setActiveCount:activeCount - 1];
				else if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount + 1];
			}
            [item update];
            break;
        }
    }
    
    [item_list reloadData];
	[self setTabColorWithStatus:dcc->dccstat];
}

- (void) add:(struct DCC *) dcc
{
    DCCItem *item = [self itemWithDCC:dcc];
	if (item == nil) return;
    [my_items addObject:item];
	if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount + 1];
    [item_list reloadData];
}

- (void) remove:(struct DCC *) dcc
{
    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        DCCItem *item = [my_items objectAtIndex:i];
        if (item->dcc == dcc)
        {
			if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount - 1];
            [my_items removeObjectAtIndex:i];
            break;
        }
    }

    [item_list reloadData];
}

- (void) do_abort:(id) sender
{
    int row = [item_list selectedRow];
    if (row >= 0)
    {
        DCCItem *item = [my_items objectAtIndex:row];
        struct DCC *dcc = item->dcc;
        dcc_abort (dcc->serv->front_session, dcc);
    }
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
	// subclasses must implement this
    return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    DCCItem *item = [my_items objectAtIndex:rowIndex];
	NSColor *color = [[[AquaChat sharedAquaChat] getPalette] getColor:dccstat[item->dcc->dccstat].color];
	[aCell setTextColor:color];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self setHasSelection:([item_list numberOfSelectedRows] > 0)];
}

- (void)setHasSelection:(BOOL)value	// this accessor method triggers KVO notifications
{
	hasSelection = value;
}

- (void)setTabColorWithStatus:(unsigned char)dcc_status
{
	if (lastDCCStatus == dcc_status) return;
	lastDCCStatus = dcc_status;
	if ([dcc_list_view isFrontTab]) return;
	
	int dcc_status_color = dccstat[dcc_status].color;
	if (dcc_status_color == 1) dcc_status_color = 8; /* we still want to show that something new happened */
	NSColor *color = [[[AquaChat sharedAquaChat] getPalette] getColor:dcc_status_color];
    [dcc_list_view setTabTitleColor:color];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[dcc_list_view setTabTitleColor:[NSColor blackColor]];
}

@end
