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

#import "DccChatWin.h"

//////////////////////////////////////////////////////////////////////

@interface DccChatItem : DCCItem
{
	NSString	*toFrom;
	NSString	*recv;
	NSString	*sent;
	NSString	*startTime;
}

@property (nonatomic, retain) NSString *toFrom, *recv, *sent, *startTime;

- (id) initWithDCC:(struct DCC *)dcc;
- (void) update;

@end

@implementation DccChatItem
@synthesize toFrom, recv, sent, startTime;

- (id) initWithDCC:(struct DCC *)aDcc
{
	[super initWithDCC:aDcc];
	
	[self update];
   
	return self;
}

- (void) dealloc
{
	self.toFrom   = nil;
	self.recv     = nil;
	self.sent     = nil;
	self.startTime= nil;

	[super dealloc];
}

- (void) update
{
	[super update];
	self.toFrom   = [NSString stringWithUTF8String:dcc->nick];
	self.recv     = [NSString stringWithFormat:@"%"DCC_SIZE_FMT, dcc->pos];
	self.sent     = [NSString stringWithFormat:@"%"DCC_SIZE_FMT, dcc->size];
	self.startTime= [NSString stringWithUTF8String:ctime(&dcc->starttime)];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation DccChatWin

- (id) init
{
	[super initWithNibNamed:@"DccChat"];
	
	return self;
}

- (DCCItem *)itemWithDCC:(struct DCC *) dcc
{
	if (dcc->type != TYPE_CHATSEND && dcc->type != TYPE_CHATRECV) return nil;
	else return [[[DccChatItem alloc] initWithDCC:dcc] autorelease];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[dccListView setTitle:NSLocalizedStringFromTable(@"XChat: DCC Chat List", @"xchat", @"")];
	[dccListView setTabTitle:NSLocalizedStringFromTable(@"dccchat", @"xchataqua", @"Title of Tab: MainMenu->Window->DCC Chat...")];
}

- (void) doAccept:(id) sender
{
	NSInteger row = [itemTableView selectedRow];
	if (row >= 0)
	{
		DccChatItem *item = [dccItems objectAtIndex:row];
		struct DCC *dcc = item->dcc;
		dcc_get(dcc);
	}
}

- (void) add:(struct DCC *) dcc
{
	DccChatItem *item = [[[DccChatItem alloc] initWithDCC:dcc] autorelease];
	[dccItems addObject:item];
	[itemTableView reloadData];
}

//////////////
//

- (id) tableView:(NSTableView *) aTableView
	objectValueForTableColumn:(NSTableColumn *) aTableColumn
	row:(NSInteger) rowIndex
{
	DccChatItem *item = [dccItems objectAtIndex:rowIndex];

	switch ([[aTableColumn identifier] integerValue])
	{
		case 0: return [item status];
		case 1: return [item toFrom];
		case 2: return [item recv];
		case 3: return [item sent];
		case 4: return [item startTime];
	}
	
	return @"";
}

@end
