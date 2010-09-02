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
#include "../common/dcc.h"

#import "AquaChat.h"
#import "ColorPalette.h"
#import "DCCListController.h"

//////////////////////////////////////////////////////////////////////

@implementation DCCItem
@synthesize status;

- (id) initWithDCC:(struct DCC *) the_dcc
{
	dcc = the_dcc;
	prevDccStat = dcc->dccstat;
   
	return self;
}

- (void) dealloc
{
	self.status = nil;

	[super dealloc];
}

- (void) update
{
	self.status = [NSString stringWithUTF8String:dccstat[dcc->dccstat].name];
	prevDccStat = dcc->dccstat;
}

@end

//////////////////////////////////////////////////////////////////////

@implementation DCCListController
@synthesize hasSelection;

- (id) initWithNibNamed:(NSString *)nibName
{
	[super init];

	dccItems = [[NSMutableArray alloc] init]; // this must be done before loading the nib
	
	hasSelection = NO;
	lastDCCStatus = 0xFF;
	
	[NSBundle loadNibNamed:nibName owner:self];
	
	return self;
}

- (void) dealloc
{
	[dccListView dealloc];
	[dccItems release];
	
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

- (void) loadData
{
	[dccItems removeAllObjects];

	[self setActiveCount:0];
	for (GSList *list = dcc_list; list; list = list->next)
	{
		struct DCC *dcc = (struct DCC *) list->data;
		
		[self add:dcc];	/* itemWithDCC will determine if the item is the right type */
	}

	[itemTableView reloadData];
}

- (void) awakeFromNib
{
	for (NSInteger i = 0; i < [itemTableView numberOfColumns]; i ++)
		[[[itemTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

	[itemTableView setDataSource:self];
	[itemTableView setDelegate:self];
	[self setNextResponder: [itemTableView nextResponder]];
	[itemTableView setNextResponder:self];
	
	[dccListView setDelegate:self];

	[self loadData];
}

- (void) show:(BOOL) and_bring_to_front
{
	if (prefs.windows_as_tabs)
		[dccListView becomeTabAndShow:and_bring_to_front];
	else
		[dccListView becomeWindowAndShow:and_bring_to_front];
}

- (void) update:(struct DCC *) dcc
{
	for (NSUInteger i = 0; i < [dccItems count]; i ++)
	{
		DCCItem *item = [dccItems objectAtIndex:i];
		if (item->dcc == dcc)
		{
			if (item->prevDccStat != dcc->dccstat) {
				if (item->prevDccStat == STAT_ACTIVE) [self setActiveCount:activeCount - 1];
				else if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount + 1];
			}
			[item update];
			break;
		}
	}
	
	[itemTableView reloadData];
	[self setTabColorWithStatus:dcc->dccstat];
}

- (void) add:(struct DCC *) dcc
{
	DCCItem *item = [self itemWithDCC:dcc];
	if (item == nil) return;
	[dccItems addObject:item];
	if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount + 1];
	[itemTableView reloadData];
}

- (void) remove:(struct DCC *) dcc
{
	for (NSInteger i = 0; i < [dccItems count]; i ++)
	{
		DCCItem *item = [dccItems objectAtIndex:i];
		if (item->dcc == dcc)
		{
			if (dcc->dccstat == STAT_ACTIVE) [self setActiveCount:activeCount - 1];
			[dccItems removeObjectAtIndex:i];
			break;
		}
	}

	[itemTableView reloadData];
}

- (void) doAbort:(id) sender
{
	NSInteger row = [itemTableView selectedRow];
	if (row >= 0)
	{
		DCCItem *item = [dccItems objectAtIndex:row];
		struct DCC *dcc = item->dcc;
		dcc_abort (dcc->serv->front_session, dcc);
	}
}

//////////////
//

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [dccItems count];
}

- (id) tableView:(NSTableView *) aTableView
	objectValueForTableColumn:(NSTableColumn *) aTableColumn
	row:(NSInteger) rowIndex
{
	// subclasses must implement this
	return @"";
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	DCCItem *item = [dccItems objectAtIndex:rowIndex];
	NSColor *color = [[[AquaChat sharedAquaChat] palette] getColor:dccstat[item->dcc->dccstat].color];
	[aCell setTextColor:color];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	[self setHasSelection:([itemTableView numberOfSelectedRows] > 0)];
}

- (void)setTabColorWithStatus:(unsigned char)status
{
	if (lastDCCStatus == status) return;
	lastDCCStatus = status;
	if ([dccListView isFrontTab]) return;
	
	int dcc_status_color = dccstat[status].color;
	if (dcc_status_color == 1) dcc_status_color = 8; /* we still want to show that something new happened */
	NSColor *color = [[[AquaChat sharedAquaChat] palette] getColor:dcc_status_color];
	[dccListView setTabTitleColor:color];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
	[dccListView setTabTitleColor:[NSColor blackColor]];
}

@end
