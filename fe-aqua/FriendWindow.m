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
#include "../common/notify.h"

#import "FriendWindow.h"
#import "TabOrWindowView.h"

@interface FriendItem : NSObject
{
@public
    struct notify_per_server *serverNotify;
    NSString *user, *status, *networks;
}

@property (nonatomic, readonly) NSString *server, *last;

+ (FriendItem *)friendWithUser:(NSString *)aUser online:(BOOL)online notify:(struct notify_per_server *)notify networks:(NSString *)aNetwork;

@end

@implementation FriendItem

+ (FriendItem *) friendWithUser:(NSString *)aUser online:(BOOL)online notify:(struct notify_per_server *)aNotify networks:(NSString *)aNetwork
{
    FriendItem *friend = [[self alloc] init];
    if ( friend != nil ) {
        friend->serverNotify = aNotify;
        friend->user = [aUser retain];
        friend->status = [(online ? NSLocalizedStringFromTable(@"Online", @"xchat", @"") : NSLocalizedStringFromTable(@"Offline", @"xchat", @"")) retain];
        friend->networks = [aNetwork retain];
    }
    return [friend autorelease];
}

- (void) dealloc
{
    [user release];
    [status release];
    [networks release];
    [super dealloc];
}

#pragma mark property interface

- (NSString *) server {
    return (serverNotify && serverNotify->laston) ? [NSString stringWithUTF8String:serverNotify->server->servername] : @"";
}

- (NSString *) last {
    return (serverNotify && serverNotify->laston) ? [NSString stringWithUTF8String:ctime(&serverNotify->laston)] : NSLocalizedStringFromTable(@"Never", @"xchat", @"");
}

@end

#pragma mark -

@implementation FriendWindow
@synthesize friendAdditionPanel;

- (id) initAsFriendWindow {
    friends = [[NSMutableArray alloc] init];
    return self;
}

- (id) initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    return [self initAsFriendWindow];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    return [self initAsFriendWindow];
}

- (void) dealloc
{
    [friends release];
    [friendAdditionPanel release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self setTitle:NSLocalizedStringFromTable(@"XChat: Friends List", @"xchat", @"")];
    [self setTabTitle:NSLocalizedStringFromTable(@"friends", @"xchataqua", @"")];
    
    [self update];
}

- (void) update
{
    // Each "user" could exist on multiple servers.
    // notify_list is a list of "users" and a list of all servers he is on
    // each per_server object has the data for that user on that server.
    // For each user that is online, we add one 1 per online server
    // For each user that is not online on any server, we just add the 'lastseen' line
    
    [friends removeAllObjects];
    
    for (GSList *list = notify_list; list; list = list->next)
    {
        struct notify_per_server *lastNotify = NULL;
        BOOL online = NO;
        
        struct notify *user = (struct notify *) list->data;
        
        for (GSList *list2 = user->server_list; list2; list2 = list2->next)
        {
            struct notify_per_server *svr = (struct notify_per_server *) list2->data;
            
            if (!lastNotify || svr->laston > lastNotify->laston)
                lastNotify = svr;
            
            if (svr->ison)
            {
                online = YES;
                break;
            }               
        }
        
        FriendItem *friendItem = [FriendItem friendWithUser:[NSString stringWithUTF8String:user->name]
                                                     online:online
                                                     notify:lastNotify
                                                   networks:user->networks ? [NSString stringWithUTF8String:user->networks] : @""];
        [friends addObject:friendItem];
    }
    
    [friendTableView reloadData];
}

#pragma mark IBAction

- (void) addFriend:(id)sender
{
    [friendAdditionPanel showAdditionWindow];
}

- (void) removeFriend:(id)sender
{
    NSInteger friendIndex = [self->friendTableView selectedRow];
    if (friendIndex < 0)
        return;
    
    FriendItem *friend = [self->friends objectAtIndex:friendIndex];
    notify_deluser ((char *)[friend->user UTF8String]);
}

- (void) openDialog:(id)sender
{
    NSInteger friendIndex = [self->friendTableView selectedRow];
    if (friendIndex < 0)
        return;
    
    FriendItem *friend = [self->friends objectAtIndex:friendIndex];
    if ( friend->serverNotify )
        open_query(friend->serverNotify->server, friend->serverNotify->notify->name, true);
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self->friends count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) row
{
    FriendItem *item = [self->friends objectAtIndex:row];
    
    switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
    {
        case 0: return item->user;
        case 1: return item->status;
        case 2: return [item server];
        case 3: return item->networks;
        case 4: return [item last];
    }
    SGAssert(NO);
    return @"";
}

@end

#pragma mark -

@implementation FriendAdditionPanel

-(void) showAdditionWindow
{    
    [friendAdditionNickTextField setStringValue:@""];
    [friendAdditionNetworkTextField setStringValue:@"ALL"];
    
    NSModalSession modalSession = [NSApp beginModalSessionForWindow:self];
    NSInteger ret;
    while ((ret = [NSApp runModalSession:modalSession]) == NSRunContinuesResponse)
        ;
    [NSApp endModalSession:modalSession];
    [self close];
    
    if (ret && [[friendAdditionNickTextField stringValue] length]>0) {
        NSString *network = [friendAdditionNetworkTextField stringValue];
        if ( [network length] == 0 || [network isEqualTo:@"ALL"] ) {
            network = @"";
        }
        notify_adduser ((char *) [[friendAdditionNickTextField stringValue] UTF8String], [network isEqualTo:@""] ? NULL : (char*)[network UTF8String]); // TODO: Networks arg
    }
}

-(void) doOk:(id)sender
{
    [NSApp stopModalWithCode:1];
}

-(void) doCancel:(id)sender
{
    [NSApp stopModalWithCode:0];
}

@end
