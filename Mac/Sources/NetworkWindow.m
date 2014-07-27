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

/* NetworkWindow.m
 * Correspond to fe-gtk: xchat/src/fe-gtk/servlistgui.c
 * Correspond to main menu: File -> Network List...
 */

#include "servlist.h"
#include "cfgfiles.h"

#import "AquaChat.h"
#import "NetworkWindow.h"

static NSString *pages[] =
{
    @IRC_DEFAULT_CHARSET,
    @"IRC (Latin/Unicode Hybrid)",
    @"ISO-8859-15 (Western Europe)",
    @"ISO-8859-2 (Central Europe)",
    @"ISO-8859-7 (Greek)",
    @"ISO-8859-8 (Hebrew)",
    @"ISO-8859-9 (Turkish)",
    @"ISO-2022-JP (Japanese)",
    @"SJIS (Japanese)",
    @"CP949 (Korean)",
    @"KOI8-R (Cyrillic)",
    @"CP1251 (Cyrillic)",
    @"CP1256 (Arabic)",
    @"CP1257 (Baltic)",
    @"GB18030 (Chinese)",
    @"TIS-620 (Thai)",
    NULL
};

static int login_types_conf[] =
{
    LOGIN_DEFAULT,          /* default entry - we don't use this but it makes indexing consistent with login_types[] so it's nice */
    LOGIN_SASL,
#ifdef USE_OPENSSL
    LOGIN_SASLEXTERNAL,
#endif
    LOGIN_PASS,
    LOGIN_MSG_NICKSERV,
    LOGIN_NICKSERV,
#ifdef USE_OPENSSL
    LOGIN_CHALLENGEAUTH,
#endif
    LOGIN_CUSTOM
#if 0
    LOGIN_NS,
    LOGIN_MSG_NS,
    LOGIN_AUTH,
#endif
};

static NSString *login_types[] =
{
    @"Default",
    @"SASL (username + password)",
#ifdef USE_OPENSSL
    @"SASL EXTERNAL (cert)",
#endif
    @"Server Password (/PASS password)",
    @"NickServ (/MSG NickServ + password)",
    @"NickServ (/NICKSERV + password)",
#ifdef USE_OPENSSL
    @"Challenge Auth (username + password)",
#endif
    @"Custom... (connect commands)",
#if 0
    @"NickServ (/NS + password)",
    @"NickServ (/MSG NS + password)",
    @"AUTH (/AUTH nickname password)",
#endif
    NULL
};

#pragma mark -

@interface ServerItem : NSObject
{
@public
    struct ircserver *ircServer;
    NSString *name;
    NSString *port;
    BOOL ssl;
}

+ (ServerItem *)serverWithIrcServer:(struct ircserver *)ircServer;
- (void)setServer:(NSString *)newName;
- (void)setPort:(NSString *)newPort;
- (BOOL)setSSL:(NSNumber *)newSSL;

@end

@implementation ServerItem

+ (ServerItem *) serverWithIrcServer:(struct ircserver *)anIrcServer {
    ServerItem *serverItem = [[self alloc] init];
    serverItem->ircServer = anIrcServer;
    
    const char *serverHostname = serverItem->ircServer->hostname;
    const char *slash = strchr(serverHostname, '/');
    
    const char *cPort;
    
    if (slash)
    {
        NSUInteger length = slash - serverHostname;
        serverItem->name = [[NSString alloc] initWithBytes:serverHostname length:length encoding:NSUTF8StringEncoding];
        cPort = slash + 1;
    }
    else
    {
        serverItem->name = [[NSString alloc] initWithUTF8String:serverHostname];
        cPort = "";
    }
    
    serverItem->ssl = *cPort == '+';
    if (serverItem->ssl)
    {
        cPort++;
    }
    
    serverItem->port = [[NSString alloc] initWithUTF8String:cPort];
    
    return [serverItem autorelease];
}

- (void) dealloc
{
    [self->name release];
    [self->port release];
    [super dealloc];
}

#pragma mark setters

- (void) setIrcServerHostName
{
    free(ircServer->hostname);
    NSString *hostName = self->name;
    if ( [port length] > 0 )
        hostName = [hostName stringByAppendingFormat:@"/%@%@", ssl ? @"+" : @"", self->port];
    ircServer->hostname = strdup([hostName UTF8String]);
}

- (void) setServer:(NSString *)newName
{
    [self->name release];
    self->name = [newName retain];
    [self setIrcServerHostName];
}

- (void) setPort:(NSString *)newPort
{
    [self->port release];
    self->port = [newPort retain];
    [self setIrcServerHostName];
}

- (BOOL) setSSL:(NSNumber *)newSSL
{
    ssl = [newSSL boolValue];
    BOOL willSetPort = ssl && [port length] == 0;
    if (willSetPort)
        [self setPort:@"6667"];
    [self setIrcServerHostName];
    return willSetPort;
}

@end

#pragma mark -

@interface NetworkItem : NSObject
{
@public
    NSString *name;
    NSMutableArray *servers;
    struct ircnet *ircNet;
}

@property BOOL autoconnect, favorite;
@property(nonatomic, retain) NSString *name;

+ (NetworkItem *)networkWithIrcnet:(ircnet *)ircNet;
- (void)addServerWithIrcServer:(struct ircserver *)ircServer;

@end

@implementation NetworkItem
@synthesize name;

+ (NetworkItem *) networkWithIrcnet:(ircnet *)anIrcNet
{
    NetworkItem *network = [[self alloc] init];
    network->ircNet = anIrcNet;
    
    network->name = [[NSString alloc] initWithUTF8String:anIrcNet->name];
    network->servers = [[NSMutableArray alloc] init];
    
    for (GSList *list = network->ircNet->servlist; list; list = list->next) {
        [network addServerWithIrcServer:(ircserver *)list->data];
    }
    
    return [network autorelease];
}

- (void) dealloc
{
    [name release];
    [servers release];
    [super dealloc];
}

- (void) addServerWithIrcServer:(ircserver *)ircServer
{
    [servers addObject:[ServerItem serverWithIrcServer:ircServer]];
}

#pragma mark Property Interfaces

- (void) setAutoconnect:(BOOL)flag
{
    if (flag)
        ircNet->flags |= FLAG_AUTO_CONNECT;
    else
        ircNet->flags &= ~FLAG_AUTO_CONNECT;
}

- (BOOL) autoconnect
{
    return (ircNet->flags & FLAG_AUTO_CONNECT) > 0;
}

- (void) setFavorite:(BOOL)flag
{
    if (flag)
        ircNet->flags |= FLAG_FAVORITE;
    else
        ircNet->flags &= ~FLAG_FAVORITE;
}

- (BOOL) favorite
{
    return (ircNet->flags & FLAG_FAVORITE) > 0;
}

- (void) setName:(NSString *)aName
{
    [name release];
    name = [aName retain];
    free(ircNet->name);
    ircNet->name = strdup([aName UTF8String]);
}

@end

#pragma mark -

@interface NetworkWindow (private)

- (void)savePreferences;
- (void)populateFlag:(id)field fromNetwork:(NetworkItem *)network;
- (void)populateField:(id)field fromNetwork:(NetworkItem *)network;
- (void)loadNetwork;
- (void)loadPreferences;

@end

@implementation NetworkWindow
@synthesize detailDrawer;

- (void) showForSession:(struct session *)aSession
{
    self->sess = aSession;
    [self makeKeyAndOrderFront:self];
}

- (void) dealloc
{    
    [filteredNetworks release];
    [allNetworks release];
    
    [super dealloc];
}

- (void) awakeFromNib
{    
    NSTableHeaderCell *heartCell = [[networkTableView tableColumns][0] headerCell];
    [heartCell setImage:[NSImage imageNamed:@"heart.tif"]];
    
    NSTableHeaderCell *connectionCell = [[networkTableView tableColumns][1] headerCell];
    [connectionCell setImage:[NSImage imageNamed:@"connect.tif"]];
    
    [self->networkTableView setAutosaveTableColumns:YES];
    
    [networkAutoConnectToggleButton setTag:FLAG_AUTO_CONNECT];
    [networkUseCustomInformationToggleButton setTag:FLAG_USE_GLOBAL];
    [networkUseProxyToggleButton setTag:~FLAG_USE_PROXY];
    [networkUseSslToggleButton setTag:FLAG_USE_SSL];
    [networkAcceptInvalidCertificationToggleButton setTag:FLAG_ALLOW_INVALID];
    [networkSelectedOnlyToggleButton setTag:~FLAG_CYCLE];
    
    [networkNicknameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, nick)];
    [networkNickname2TextField setTag:STRUCT_OFFSET_STR(struct ircnet, nick2)];
    [networkRealnameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, real)];
    [networkUsernameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, user)];
    [networkLoginMethodComboBox setTag:STRUCT_OFFSET_INT(struct ircnet, logintype)];
    [networkPasswordTextField setTag:STRUCT_OFFSET_STR(struct ircnet, pass)];
    [charsetComboBox setTag:STRUCT_OFFSET_STR(struct ircnet, encoding)];
    
    // We gotta do a reloadData in order to change the selection, but reload
    // data will call selectionDidChange and thus set prefs.slist_select.  We'll
    // save the value of prefs.slist_select now, and reset the selection after
    // the first reloadData.
    
    NSInteger slist_select = prefs.hex_gui_slist_select;
    
    // make charsets menu
    for (NSString **c = pages; *c; c++) {
        [charsetComboBox addItemWithObjectValue:*c];
    }
    for (NSString **c = login_types; *c; c++) {
        [networkLoginMethodComboBox addItemWithObjectValue:*c];
    }
    [self loadPreferences];
    
    [filteredNetworks sortUsingDescriptors:[networkTableView sortDescriptors]];
    [networkTableView reloadData];
    
    if (slist_select < [self numberOfRowsInTableView:networkTableView])
    {
        [networkTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:slist_select] byExtendingSelection:NO];
        [networkTableView scrollRowToVisible:slist_select];
    }
    
    [self center];
}

#pragma mark notification

- (void) close
{
    // Close the drawer.  If we leave it open and then try to cycle
    // the windows, we'll find it even though it's not really visible!
    [showDetailButton setIntValue:0];
    [self showDetail:showDetailButton];
    [self savePreferences];
    [super close];
}

- (void) comboBoxSelectionDidChange:(NSNotification *) notification
{
    NSComboBox *comboBox = notification.object;
    if (comboBox == charsetComboBox) {
        [comboBox setObjectValue:[comboBox objectValueOfSelectedItem]];
    }
    else if (notification.object == networkLoginMethodComboBox) {
        [comboBox setObjectValue:[comboBox objectValueOfSelectedItem]];
    }
    else {
        NSAssert(NO, @"");
    }
}

#pragma mark IBAction

- (void) showDetail:(id)sender
{
    if ([sender intValue])
    {
        [detailDrawer open];
    }
    else
    {
        [detailDrawer close];
    }
}

- (void) toggleShowWhenStartup:(id)sender
{
    prefs.hex_gui_slist_skip = [sender intValue];
}

- (void) toggleCustomUserInformation:(id)sender
{
    bool doit = ![sender intValue];
    
    [networkNicknameTextField setEnabled:doit];
    [networkNickname2TextField setEnabled:doit];
    [networkRealnameTextField setEnabled:doit];
    [networkUsernameTextField setEnabled:doit];
    
    [self setFlagWithControl:networkUseCustomInformationToggleButton];
}

- (void) connectToSelectdNetwork:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    [self savePreferences];
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    if (sender == connectNewButton || !is_session (sess))
        sess = NULL;
    
    network->ircNet->selected = (int)[networkServerTableView selectedRow];    // This kinda stinks. Boo Peter!
    // Why can't it be an arg to
    // servlist_connect!?
    servlist_connect (sess, network->ircNet, true);
    
    [self orderOut:sender];
}

- (void) setFlagWithControl:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    BOOL val = [sender intValue];
    
    NSInteger flag = [sender tag];
    if (flag < 0)
    {
        flag = ~flag;
        val = !val;
    }
    
    guint32 *flags = &network->ircNet->flags;
    if (val)
        *flags |= flag;
    else
        *flags &= ~flag;
}

- (void) setFieldWithControl:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    NSInteger offset = [sender tag];
    char **f = (char **)(((char *)network->ircNet) + offset);
    free (*f);
    const char *v = [[sender stringValue] UTF8String];
    *f = *v ? strdup (v) : NULL;
}

- (void)setIndexWithControl:(NSComboBox *)sender {
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;

    NetworkItem *network = filteredNetworks[networkIndex];

    NSInteger offset = [sender tag];
    int *f = (int *)(((char *)network->ircNet) + offset);
    *f = (int)[sender indexOfSelectedItem];
}

- (void) addChannel:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0)
        return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    servlist_favchan_add(network->ircNet, NSLocalizedStringFromTable(@"NEW CHANNEL", @"xchataqua", @"Default channel name: MainMenu->File->Server List... => (Select server)->On Join->channels->'+'").UTF8String);
    [networkJoinTableView reloadData];
    
    NSInteger lastIndex = g_slist_length(network->ircNet->favchanlist) - 1;
    [networkJoinTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    [networkJoinTableView scrollRowToVisible:lastIndex];
    [networkJoinTableView editColumn:0 row:lastIndex withEvent:nil select:YES];
}

- (void) removeChannel:(id)sender
{
    [networkJoinTableView abortEditing];
    
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    NSInteger channelIndex = [networkJoinTableView selectedRow];
    if (channelIndex < 0) return;

    favchannel *channel = g_slist_nth_data(network->ircNet->favchanlist, (guint)channelIndex);
    servlist_favchan_remove(network->ircNet, channel);
    [networkJoinTableView reloadData];
}

- (void) addCommand:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];

    commandentry *entry = servlist_command_add(network->ircNet, NSLocalizedStringFromTable(@"NEW COMMAND", @"xchataqua", @"Default command: MainMenu->File->Server List... => (Select server)->On Join->commands->'+'").UTF8String);
    
    [networkCommandTableView reloadData];
    
    NSInteger lastIndex = g_slist_length(network->ircNet->commandlist) - 1;
    [networkCommandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    [networkCommandTableView scrollRowToVisible:lastIndex];
    [networkCommandTableView editColumn:0 row:lastIndex withEvent:nil select:YES];
}

- (void) removeCommand:(id)sender
{
    [networkCommandTableView abortEditing];
    
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    NSInteger commandIndex = [networkCommandTableView selectedRow];
    if (commandIndex < 0) return;

    GSList *list = network->ircNet->commandlist;
    servlist_command_remove(network->ircNet, g_slist_nth_data(list, (guint)commandIndex));
    [networkCommandTableView reloadData];
}

- (void) addServer:(id)sender
{
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    ircserver *ircServer = servlist_server_add (network->ircNet, (char *)[NSLocalizedStringFromTable(@"NewServer", @"xchat", @"") UTF8String]);
    
    [network addServerWithIrcServer:ircServer];
    [networkServerTableView reloadData];
    
    NSInteger lastIndex = [network->servers count] - 1;    
    [networkServerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    [networkServerTableView scrollRowToVisible:lastIndex];
    [networkServerTableView editColumn:0 row:lastIndex withEvent:nil select:YES];
    
}

- (void) removeServer:(id)sender
{
    [networkServerTableView abortEditing];
    
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0)
        return;
    
    NSInteger serverIndex = [networkServerTableView selectedRow];
    if (serverIndex < 0)
        return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    if (g_slist_length (network->ircNet->servlist) < 2)
        return;
    
    [network->servers removeObjectAtIndex:serverIndex];
    
    servlist_server_remove (network->ircNet, (struct ircserver *) g_slist_nth (network->ircNet->servlist, (guint)serverIndex)->data);
    
    [networkServerTableView reloadData];
}

- (void) addNetwork:(id)sender
{
    struct ircnet *ircNet = servlist_net_add ((char*)[NSLocalizedStringFromTable(@"New Network", @"xchat", @"") UTF8String], "", false);
    servlist_server_add (ircNet, (char *)[NSLocalizedStringFromTable(@"NewServer", @"xchat", @"") UTF8String]);
    [filteredNetworks addObject:[NetworkItem networkWithIrcnet:ircNet]]; // add to filtered one?
    [networkTableView reloadData];
    
    NSInteger lastIndex = [self numberOfRowsInTableView:networkTableView] - 1;
    [networkTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
    [networkTableView editColumn:2 row:lastIndex withEvent:nil select:YES];
}

- (void) removeNetwork:(id)sender
{
    [networkTableView abortEditing];
    
    NSInteger networkIndex = [networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    if (![SGAlert confirmWithString:[NSString stringWithFormat:
                                     NSLocalizedStringFromTable(@"Really remove network \"%@\" and all its servers?", @"xchat", @"Dialog Message from clicking '-' of MainMenu->File->Server List..."), network->name]])
        return;
    
    servlist_net_remove (network->ircNet);
    [filteredNetworks removeObjectAtIndex:networkIndex]; // remove from filtered one?
    [networkTableView reloadData];
}

- (void) doFilter:(id)sender
{
    const char *filter = [[[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] UTF8String];
    
    [filteredNetworks release];
    
    if ( filter == NULL || filter[0] == '\0' )
    {
        filteredNetworks = [allNetworks retain];
    }
    else
    {
        filteredNetworks = [[NSMutableArray alloc] init];
        
        for ( NetworkItem *network in allNetworks )
        {
            if (strcasestr (network->ircNet->name, filter))
                [filteredNetworks addObject:network];
        }
    }
    
    [networkTableView reloadData];
    
    // Simulate new selection
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"dummy" object:networkTableView]];
}

#pragma mark NSTableView Protocols

#define DraggingDataType @"TemporaryDataType"

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    if ( tableView == networkTableView ) return NO;
    if ( [self->networkTableView selectedRow] < 0 ) return NO;
    
    [tableView registerForDraggedTypes:@[DraggingDataType]];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:@[DraggingDataType] owner:self];
    [pboard setData:data forType:DraggingDataType];
    return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
    return NSDragOperationMove;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
    NSData *rowData = [[info draggingPasteboard] dataForType:DraggingDataType];
    NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger selectedRow = [rowIndexes firstIndex];
    
    NetworkItem *network = filteredNetworks[[networkTableView selectedRow]];
    if (tableView == networkServerTableView) {
        NSMutableArray *dataArray = network->servers;
        id selectedItem = [dataArray[selectedRow] retain];
        switch (dropOperation) {
            case NSTableViewDropOn:
                dataArray[selectedRow] = dataArray[row];
                dataArray[row] = selectedItem;
                break;
            case NSTableViewDropAbove:
                [dataArray removeObjectAtIndex:selectedRow];
                [dataArray insertObject:selectedItem atIndex:row-(row>=selectedRow)];
                [tableView reloadData];
                break;
            default:
                dassert(NO);
        }
        [selectedItem release];
    } else {
        GSList *dataList = NULL;
        if (tableView == networkJoinTableView) {
            dataList = network->ircNet->favchanlist;
        } else if ( tableView == networkCommandTableView ) {
            dataList = network->ircNet->commandlist;
        } else {
            dassert(NO);
        }

        GSList *selected = g_slist_nth(dataList, (guint)selectedRow);
        switch (dropOperation) {
            case NSTableViewDropOn: { // swap
                GSList *target = g_slist_nth(dataList, (guint)row);
                gpointer data = selected->data;
                selected->data = target->data;
                target->data = data;
            }   break;
            case NSTableViewDropAbove: { // insert
                dataList = g_slist_delete_link(dataList, selected);
                dataList = g_slist_insert(dataList, selected->data, (guint)(row-(row>=selectedRow)));
                [tableView reloadData];
            }   break;
            default:
                dassert(NO);
        }
    }

    [tableView unregisterDraggedTypes];
    
    return YES;
}

#undef DraggingDataType

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger networkIndex = [self->networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    if ([notification object] == networkTableView)
    {
        // Figure out what was selected from the allNetworks
        NetworkItem *network = filteredNetworks[networkIndex];
        prefs.hex_gui_slist_select = (int)[allNetworks indexOfObject:network];
        [self loadNetwork];
    }
    else if ([notification object] == networkServerTableView)
    {
        NetworkItem *network = filteredNetworks[networkIndex];
        network->ircNet->selected = (int)[networkServerTableView selectedRow];
    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (aTableView == networkTableView)
        return [filteredNetworks count];
    
    NSInteger networkIndex = [self->networkTableView selectedRow];
    if (networkIndex < 0) return 0;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    if (aTableView == networkServerTableView)
    {
        return [network->servers count];
    }
    
    if (aTableView == networkJoinTableView)
    {
        return g_slist_length(network->ircNet->favchanlist);
    }
    
    if (aTableView == networkCommandTableView)
    {
        return g_slist_length(network->ircNet->commandlist);
    }
    
    dassert(NO);
    return 0;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) rowIndex
{
    NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
    
    if (aTableView == networkTableView)
    {
        NetworkItem *network =filteredNetworks[rowIndex];
        switch (column)
        {
            case 0: return @((NSInteger)network.favorite);
            case 1: return @((NSInteger)network.autoconnect);
            case 2: return network.name;
        }
    }
    else
    {
        NSInteger networkIndex = [self->networkTableView selectedRow];
        if (networkIndex < 0) return @"";
        
        NetworkItem *network = filteredNetworks[networkIndex];
        
        if (aTableView == networkServerTableView)
        {
            ServerItem *serverItem = network->servers[rowIndex];
            switch (column)
            {
                case 0: return serverItem->name;
                case 1: return serverItem->port;
                case 2: return @(serverItem->ssl);
            }
        }
        else if (aTableView == networkJoinTableView)
        {
            favchannel *channel = g_slist_nth_data(network->ircNet->favchanlist, (guint)rowIndex);
            switch (column) {
                case 0: return @(channel->name);
                case 1: return channel->key ? @(channel->key) : nil;
            }
        }
        else if (aTableView == networkCommandTableView)
        {
            GSList *list = network->ircNet->commandlist;
            commandentry *entry = g_slist_nth_data(list, (guint)rowIndex);
            return @(entry->command);
        }
    }
    dassert(NO);
    return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
    
    if (aTableView == networkTableView)
    {
        NetworkItem *network =filteredNetworks[rowIndex];
        switch (column)
        {
            case 0: [network setFavorite:[anObject boolValue]]; break;
            case 1: [network setAutoconnect:[anObject boolValue]]; break;
            case 2: [network setName:anObject]; break;
        }
    }
    else
    {
        NSInteger networkIndex = [networkTableView selectedRow];
        if ( networkIndex < 0) return;
        
        NetworkItem *network = filteredNetworks[networkIndex];
        
        if (aTableView == networkServerTableView)
        {
            ServerItem *serverItem = network->servers[rowIndex];
            switch (column)
            {
                case 0: [serverItem setServer:anObject]; break;
                case 1: [serverItem setPort:anObject]; break;
                case 2: {
                    BOOL needReload = [serverItem setSSL:anObject];
                    if (needReload)
                        [networkServerTableView reloadData];
                    break;
                }
            }
        }
        else if (aTableView == networkJoinTableView)
        {
            favchannel *channel = g_slist_nth_data(network->ircNet->favchanlist, (guint)rowIndex);
            switch (column)
            {
                case 0: {
                    g_free(channel->name);
                    channel->name = strdup([anObject UTF8String]);
                }   break;
                case 1: {
                    g_free(channel->key);
                    channel->key = strdup([anObject UTF8String]);
                }   break;
            }
        }
        else if (aTableView == networkCommandTableView)
        {
            commandentry *entry = g_slist_nth_data(network->ircNet->commandlist, (guint)rowIndex);
            g_free(entry->command);
            entry->command = strdup([anObject UTF8String]);
        }
    }
}

- (void) tableView:(NSTableView *)aTableView didClickTableColumn:(NSTableColumn *)aTableColumn
{
    if (aTableView == networkTableView)
    {
        [filteredNetworks sortUsingDescriptors:[aTableView sortDescriptors]];
        [networkTableView reloadData];
        [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:networkTableView]];
    }
}

@end

#pragma mark -

@implementation NetworkWindow (private)

- (void) savePreferences
{
    [self makeFirstResponder:nick1TextField]; // any reason?
    
    strcpy (prefs.hex_irc_nick1, [[nick1TextField stringValue] UTF8String]);
    strcpy (prefs.hex_irc_nick2, [[nick2TextField stringValue] UTF8String]);
    strcpy (prefs.hex_irc_nick3, [[nick3TextField stringValue] UTF8String]);
    strcpy (prefs.hex_irc_user_name, [[usernameTextField stringValue] UTF8String]);
    strcpy (prefs.hex_irc_real_name, [[realnameTextField stringValue] UTF8String]);
    
    servlist_save();
}


- (void) populateFlag:(id)field fromNetwork:(NetworkItem *)network
{
    NSInteger flag = [field tag];
    BOOL invert = flag < 0;
    if (invert)
        flag = ~flag;
    
    BOOL val = (network->ircNet->flags & flag) != 0;
    
    if (invert)
        val = !val;
    
    [field setIntValue:val];
}

- (void) populateField:(id)field fromNetwork:(NetworkItem *)network
{
    NSInteger offset = [field tag];
    char **f = (char **)(((char *) network->ircNet) + offset);
    char *str = *f;
    
    NSString *val = str ? @(str) : @"";
    
    [field setStringValue:val];
}

- (void)loadNetwork
{
    NSInteger networkIndex = [self->networkTableView selectedRow];
    if (networkIndex < 0) return;
    
    NetworkItem *network = filteredNetworks[networkIndex];
    
    [networkTitleTextField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Servers for %s", @"xchat", @""), [network->name UTF8String]]];
    
    [self populateField:networkNicknameTextField fromNetwork:network];
    [self populateField:networkNickname2TextField fromNetwork:network];
    [self populateField:networkPasswordTextField fromNetwork:network];
    [self populateField:networkRealnameTextField fromNetwork:network];

    int order;
    int logintype = LOGIN_DEFAULT;
    for (order = 0; order < (sizeof(login_types_conf)/sizeof(login_types_conf[0])); order ++) {
        if (login_types_conf[order] == network->ircNet->logintype) {
            logintype = login_types_conf[order];
            break;
        }
    }
    [self->networkLoginMethodComboBox selectItemAtIndex:order];
    id value = [self->networkLoginMethodComboBox objectValueOfSelectedItem];
    [self->networkLoginMethodComboBox setStringValue:@"wth is happening"];
    [self populateField:networkLoginMethodComboBox fromNetwork:network];
    [self populateField:networkUsernameTextField fromNetwork:network];
    [self populateField:charsetComboBox fromNetwork:network];
    
    [self populateFlag:networkAutoConnectToggleButton fromNetwork:network];
    [self populateFlag:networkSelectedOnlyToggleButton fromNetwork:network];
    [self populateFlag:networkUseCustomInformationToggleButton fromNetwork:network];
    [self populateFlag:networkUseProxyToggleButton fromNetwork:network];
    [self populateFlag:networkUseSslToggleButton fromNetwork:network];
    [self populateFlag:networkAcceptInvalidCertificationToggleButton fromNetwork:network];
    
    [self toggleCustomUserInformation:networkUseCustomInformationToggleButton];
    
    NSInteger selected = network->ircNet->selected;
    
    [networkJoinTableView reloadData];
    [networkCommandTableView reloadData];
    [networkServerTableView reloadData];
    
    if (selected < [self numberOfRowsInTableView:networkServerTableView])
    {
        [networkServerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
        [networkServerTableView scrollRowToVisible:selected];
    }
}

- (void)loadPreferences
{
    [nick1TextField setStringValue:@(prefs.hex_irc_nick1)];
    [nick2TextField setStringValue:@(prefs.hex_irc_nick2)];
    [nick3TextField setStringValue:@(prefs.hex_irc_nick3)];
    [realnameTextField setStringValue:@(prefs.hex_irc_real_name)];
    [usernameTextField setStringValue:@(prefs.hex_irc_user_name)];
    
    [showWhenStartupToggleButton setIntegerValue:prefs.hex_gui_slist_skip];
    
    [filteredNetworks release];
    [allNetworks release];

    allNetworks = [[NSMutableArray alloc] init];
    filteredNetworks = [allNetworks retain];

    for (GSList *list = network_list; list; list = list->next)
    {
        [filteredNetworks addObject:[NetworkItem networkWithIrcnet:(struct ircnet *)list->data]];
    }

    [networkTableView reloadData];
}

@end
