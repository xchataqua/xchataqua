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
#import "DccChatWin.h"

//////////////////////////////////////////////////////////////////////

@interface oneDccChat : DCCItem
{
  @public
    //struct DCC 		*dcc;
    
    //NSMutableString	*status;
    NSMutableString	*to_from;
    NSMutableString	*recv;
    NSMutableString	*sent;
    NSMutableString	*start_time;
}

- (id) initWithDCC:(struct DCC *) the_dcc;
- (void) update;

@end

@implementation oneDccChat

- (id) initWithDCC:(struct DCC *) the_dcc
{
	[super initWithDCC:the_dcc];

    to_from = [[NSMutableString stringWithCapacity:0] retain];
    recv = [[NSMutableString stringWithCapacity:0] retain];
    sent = [[NSMutableString stringWithCapacity:0] retain];
    start_time = [[NSMutableString stringWithCapacity:0] retain];
    
    [self update];
   
    return self;
}

- (void) dealloc
{
    [to_from release];
    [recv release];
    [sent release];
    [start_time release];

    [super dealloc];
}

- (void) update
{
    [super update];
    [to_from setString:[NSString stringWithUTF8String:dcc->nick]];
    [recv setString:[NSString stringWithFormat:@"%"DCC_SIZE_FMT, dcc->pos]];
    [sent setString:[NSString stringWithFormat:@"%"DCC_SIZE_FMT, dcc->size]];
    [start_time setString:[NSString stringWithUTF8String:ctime(&dcc->starttime)]];
    //int end = [start_time length] - 1;
    //[start_time deleteCharactersInRange:NSMakeRange (end, end)];
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
	else return [[[oneDccChat alloc] initWithDCC:dcc] autorelease];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

    [dcc_list_view setTitle:NSLocalizedStringFromTable(@"XChat: DCC Chat List", @"xchat", @"")];
    [dcc_list_view setTabTitle:NSLocalizedStringFromTable(@"dccchat", @"xchataqua", @"Title of Tab: MainMenu->Window->DCC Chat...")];
}

- (void) do_accept:(id) sender
{
    int row = [item_list selectedRow];
    if (row >= 0)
    {
        oneDccChat *item = [my_items objectAtIndex:row];
        struct DCC *dcc = item->dcc;
        dcc_get (dcc);
    }
}

- (void) add:(struct DCC *) dcc
{
    oneDccChat *item = [[[oneDccChat alloc] initWithDCC:dcc] autorelease];
    [my_items addObject:item];
    [item_list reloadData];
}

//////////////
//

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    oneDccChat *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->status;
        case 1: return item->to_from;
        case 2: return item->recv;
        case 3: return item->sent;
        case 4: return item->start_time;
    }
    
    return @"";
}

@end
