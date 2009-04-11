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
#import "XACommon.h"
#import "DccSendWin.h"

extern int dcc_sendcpssum;

//////////////////////////////////////////////////////////////////////

@interface oneDccSend : DCCFileItem
{
  @public
    //struct DCC 		*dcc;
	//unsigned char prev_dccstat;
    
    //NSMutableString	*status;
    //NSMutableString	*file;
    //NSMutableString	*size;
    //NSMutableString	*position;
    //NSMutableString	*per;
    //NSMutableString	*kbs;
    //NSMutableString	*eta;

    NSMutableString	*ack;
    NSMutableString	*to;
}

- (id) initWithDCC:(struct DCC *) the_dcc;
- (void) update;

@end

@implementation oneDccSend

- (id) initWithDCC:(struct DCC *) the_dcc
{
	[super initWithDCC:the_dcc];

    ack = [[NSMutableString stringWithCapacity:0] retain];
    to = [[NSMutableString stringWithCapacity:0] retain];
    
    [self update];
   
    return self;
}

- (void) dealloc
{
    [ack release];
    [to release];

    [super dealloc];
}

- (void) update
{
    [super update];
    [ack setString:[NSString stringWithFormat:@"%@", formatNumber (dcc->ack)]];
    [to setString:[NSString stringWithUTF8String:dcc->nick]];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation DccSendWin

- (id) init
{
    [super initWithNibNamed:@"DccSend"];
    
    return self;
}

- (DCCItem *)itemWithDCC:(struct DCC *) dcc
{
	if (dcc->type != TYPE_SEND) return nil;
	else return [[[oneDccSend alloc] initWithDCC:dcc] autorelease];
}

- (void) awakeFromNib
{
	cpssum = &dcc_sendcpssum;
	[super awakeFromNib];

    [dcc_list_view setTitle:NSLocalizedStringFromTable(@"XChat: File Send List", @"xchataqua", @"")];
    [dcc_list_view setTabTitle:NSLocalizedStringFromTable(@"dccsend", @"xchataqua", @"")];
}

- (void) do_info:(id) sender
{
    int row = [item_list selectedRow];
    if (row >= 0)
    {
        oneDccSend *item = [my_items objectAtIndex:row];

        struct DCC *dcc = item->dcc;

        NSString *msg = [NSString stringWithFormat:NSLocalizedStringFromTable(@"      File: %s\n        To: %s\n      Size: %"DCC_SIZE_FMT"\n      Port: %d\n IP Number: %s\nStart Time: %s", @"xchataqua", @""),
                                    dcc->file, dcc->nick, dcc->size, dcc->port,
                                    net_ip (dcc->addr), ctime (&dcc->starttime)];

        [SGAlert noticeWithString:msg andWait:false];
    }
}

- (NSString *)activeString
{
	if (activeCount == 0) return NSLocalizedStringFromTable(@"No active upload", @"xchataqua", @"label of DCC Send List: MainMenu->Window->DCC Send List...");
	else if (activeCount == 1) return NSLocalizedStringFromTable(@"1 active upload", @"xchataqua", @"label of DCC Send List: MainMenu->Window->DCC Send List...");
	else return [NSString stringWithFormat:NSLocalizedStringFromTable(@"%d active uploads", @"xchataqua", @"label of DCC Send List: MainMenu->Window->DCC Send List..."), activeCount];
}

- (NSNumber *)globalSpeedLimit
{
	if (prefs.dcc_global_max_send_cps) return [NSNumber numberWithInt:prefs.dcc_global_max_send_cps / 1024];
	else return nil;
}

- (void)setGlobalSpeedLimit:(id)value
{
	if ([value respondsToSelector:@selector(intValue)]) prefs.dcc_global_max_send_cps = [value intValue] * 1024;
	else prefs.dcc_global_max_send_cps = 0;
}

//////////////
//

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    oneDccSend *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->status;
        case 1: return item->file;
        case 2: return item->size;
        case 3: return item->position;
        case 4: return item->ack;
        case 5: return item->per;
        case 6: return item->kbs;
        case 7: return item->eta;
        case 8: return item->to;
    }
    
    return @"";
}

@end
