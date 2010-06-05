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
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/notify.h"

#import "FriendListWin.h"

//////////////////////////////////////////////////////////////////////

@interface OneNotify : NSObject
{
  @public
    NSString	*user;
    NSString	*status;
    NSString	*server;
    NSString	*last;
	NSString    *networks;
}

- (id) initWithUser:(NSString *)user 
             online:(BOOL) online
			 server:(struct notify_per_server *)server
		   networks:(NSString *)networks;

@end

@implementation OneNotify

- (id) initWithUser:(NSString *)user_name
             online:(BOOL) online
			 server:(struct notify_per_server *)svr
		   networks:(NSString *)ntwk;
{
    user = [user_name retain];
    status = [online ? NSLocalizedStringFromTable(@"Online", @"xchat", @"") : NSLocalizedStringFromTable(@"Offline", @"xchat", @"") retain];
	self->networks = [ntwk retain];
    if (svr && svr->laston)
    {
        self->server = [[NSString stringWithUTF8String:svr->server->servername] retain];
        last = [[NSString stringWithUTF8String:ctime (&svr->laston)] retain];
    }
    else
    {
        self->server = [@"" retain];
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

@implementation FriendListWin

- (id) initWithSelfPtr:(id *)selfPtr;
{
    [super initWithSelfPtr:selfPtr];
    
    myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"FriendList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [friendListTableView release];
    [myItems release];
	[friendAddWindow release];
    [super dealloc];
}

- (void) loadData
{
    // Each "user" could exist on multiple servers.
    // notify_list is a list of "users" and a list of all servers he is on
    // each per_server object has the data for that user on that server.
    // For each user that is online, we add one 1 per online server
    // For each user that is not online on any server, we just add the 'lastseen' line
    
    [myItems removeAllObjects];

    for (GSList *list = notify_list; list; list = list->next)
    {
        struct notify_per_server *lastsvr = NULL;
        BOOL online = NO;
		
        struct notify *user = (struct notify *) list->data;
        
        for (GSList *list2 = user->server_list; list2; list2 = list2->next)
        {
            struct notify_per_server *svr = (struct notify_per_server *) list2->data;

            if (!lastsvr || svr->laston > lastsvr->laston)
                lastsvr = svr;
                
            if (svr->ison)
            {
                online = YES;
				break;
            }               
        }

		OneNotify *oneNotify = [[OneNotify alloc] initWithUser:[NSString stringWithUTF8String:user->name]
									 online:online
									 server:lastsvr
								   networks:user->networks ? [NSString stringWithUTF8String:user->networks] : @""];
		[myItems addObject:oneNotify];
		[oneNotify release];
    }

    [self->friendListTableView reloadData];
}

- (void) awakeFromNib
{
    [friendListView setTitle:NSLocalizedStringFromTable(@"XChat: Friends List", @"xchat", @"")];
    [friendListView setTabTitle:NSLocalizedStringFromTable(@"friends", @"xchataqua", @"")];
    
    for (NSUInteger i = 0; i < [self->friendListTableView numberOfColumns]; i ++)
        [[[self->friendListTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->friendListTableView setDataSource:self];
    [self->friendListView setDelegate:self];
    
    [self loadData];
}

- (void) doAdd:(id) sender
{
	[friendAddWindow doAdd];
}

- (void) doRemove:(id) sender
{
    NSInteger row = [self->friendListTableView selectedRow];
    if (row < 0)
    	return;

    OneNotify *notif = (OneNotify *) [myItems objectAtIndex:row];
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
        [friendListView becomeTabAndShow:YES];
    else
        [friendListView becomeWindowAndShow:YES];
}

- (void) update
{
    [self loadData];
}

//////////////
//

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [myItems count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) row
{
    OneNotify *item = [myItems objectAtIndex:row];

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


@implementation FriendAddWindow

-(void) doAdd
{
	[friendAddPanel setDelegate:self];
	
	[friendAddNickTextField setStringValue:@""];
	[friendAddNetworkTextField setStringValue:@"ALL"];
	
	[friendAddPanel makeKeyAndOrderFront:self];
    NSModalSession session = [NSApp beginModalSessionForWindow:self];
    NSInteger ret;
    while ((ret = [NSApp runModalSession:session]) == NSRunContinuesResponse)
		;
    [NSApp endModalSession:session];     
    [self close];
	
    if (ret && [[friendAddNickTextField stringValue] length])
        notify_adduser ((char *) [[friendAddNickTextField stringValue] UTF8String], (char*)[[friendAddNickTextField stringValue] UTF8String]); // TODO: Networks arg	
}

-(void) doOk:(id) sender
{
	[NSApp stopModalWithCode:1];
}

-(void) doCancel:(id) sender
{
	[NSApp stopModalWithCode:0];
}

@end
