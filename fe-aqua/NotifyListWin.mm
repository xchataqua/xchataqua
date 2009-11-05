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
#include "../common/notify.h"
}

#import "SG.h"
#import "NotifyListWin.h"

//////////////////////////////////////////////////////////////////////

@interface oneNotify : NSObject
{
  @public
    NSString	*user;
    NSString	*status;
    NSString	*server;
    NSString	*last;
	NSString    *networks;
}

- (id) initWithUser:(const char *) user_name 
             online:(bool) online
                svr:(notify_per_server *) svr
		   networks:(const char*)networks;

@end

@implementation oneNotify

- (id) initWithUser:(const char *) user_name 
             online:(bool) online
                svr:(notify_per_server *) svr
		  networks:(const char *) ntwk
{
    user = [[NSString stringWithUTF8String:user_name ? user_name : ""] retain];
    status = [online ? NSLocalizedStringFromTable(@"Online", @"xchat", @"") : NSLocalizedStringFromTable(@"Offline", @"xchat", @"") retain];
	self->networks = [[NSString stringWithUTF8String:ntwk ? ntwk : ""] retain];
    if (svr && svr->laston)
    {
        self->server = [[NSString stringWithUTF8String:svr->server->servername] retain];
        last = [[NSString stringWithUTF8String:ctime (&svr->laston)] retain];
    }
    else
    {
        self->server = [[NSString stringWithUTF8String:""] retain];
        last = [NSLocalizedStringFromTable(@"Never", @"xchat", @"") retain];
    }
    
    return self;
}

- (void) dealloc
{
    [user release];
    [status release];
    [self->server release];
    [last release];
	[networks release];

    [super dealloc];
}

@end


/****************************************************************************/

@implementation NotifyListWin

- (id) initWithSelfPtr:(id *) self_ptr;
{
    [super initWithSelfPtr:self_ptr];
    
    my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"NotifyList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [notify_list_view release];
    [my_items release];
	[add_notify_window release];
    [super dealloc];
}

- (void) load_data
{
    // Each "user" could exist on multiple servers.
    // notify_list is a list of "users" and a list of all servers he is on
    // each per_server object has the data for that user on that server.
    // For each user that is online, we add one 1 per online server
    // For each user that is not online on any server, we just add the 'lastseen' line
    
    [my_items removeAllObjects];

    for (GSList *list = notify_list; list; list = list->next)
    {
        notify_per_server *lastsvr = NULL;
        bool online = false;
        oneNotify * n;
		
        struct notify *user = (struct notify *) list->data;
        
        for (GSList *list2 = user->server_list; list2; list2 = list2->next)
        {
            struct notify_per_server *svr = (struct notify_per_server *) list2->data;

            if (!lastsvr || svr->laston > lastsvr->laston)
                lastsvr = svr;
                
            if (svr->ison)
            {
                online = true;
				break;
            }               
        }

		n = [[oneNotify alloc] initWithUser:user->name
									 online:online
										svr:lastsvr
								   networks:user->networks];
		[my_items addObject:n];
		[n release];
    }

    [self->notify_list_table reloadData];
}

- (void) awakeFromNib
{
    [notify_list_view setTitle:NSLocalizedStringFromTable(@"XChat: Friends List", @"xchat", @"")];
    [notify_list_view setTabTitle:NSLocalizedStringFromTable(@"friends", @"xchataqua", @"")];
    
    for (int i = 0; i < [self->notify_list_table numberOfColumns]; i ++)
        [[[self->notify_list_table tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->notify_list_table setDataSource:self];
    [self->notify_list_view setDelegate:self];
    
    [self load_data];
}

- (void) do_add:(id) sender
{
   // NSString *s = [SGRequest requestWithString:@"Add:"];
	[add_notify_window do_it];
}

- (void) do_remove:(id) sender
{
    int row = [self->notify_list_table selectedRow];
    if (row < 0)
    	return;

    oneNotify *notif = (oneNotify *) [my_items objectAtIndex:row];
    notify_deluser ((char *) [notif->user UTF8String]);
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self release];
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [notify_list_view becomeTabAndShow:true];
    else
        [notify_list_view becomeWindowAndShow:true];
}

- (void) update
{
    [self load_data];
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
    oneNotify *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->user;
        case 1: return item->status;
        case 2: return item->server;
		case 3: return item->networks;
        case 4: return item->last;
    }
    
    return @"";
}

@end


@implementation AddNotifyWindow

-(void) do_it
{
	[add_notify_window setDelegate:self];
	
	[add_notify_nick setStringValue:@""];
	[add_notify_network setStringValue:@"ALL"];
	
	[add_notify_window makeKeyAndOrderFront:self];
    NSModalSession session = [NSApp beginModalSessionForWindow:self];
    int ret;
    while ((ret = [NSApp runModalSession:session]) == NSRunContinuesResponse)
		;
    [NSApp endModalSession:session];     
    [self close];
	
    if (ret && [[add_notify_nick stringValue] length])
        notify_adduser ((char *) [[add_notify_nick stringValue] UTF8String], (char*)[[add_notify_network stringValue] UTF8String]); // TODO: Networks arg	
}

-(void) do_ok:(id) sender
{
	[NSApp stopModalWithCode:1];
}

-(void) do_cancel:(id) sender
{
	[NSApp stopModalWithCode:0];
}

@end
