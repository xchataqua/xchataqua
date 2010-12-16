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
#include "../common/servlist.h"
#include "../common/cfgfiles.h"

#import "AquaChat.h"
#import "NetworkWindow.h"

static NSString *charsets[] =
{
	@"UTF-8",
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

#pragma mark -

@interface OneChannel : NSObject
{
  @public
	NSString *name;
	NSString *key;
}
@property(nonatomic,retain) NSString *name, *key;

+ (OneChannel *)channelWithName:(NSString *)name;

@end

@implementation OneChannel
@synthesize name, key;

- (void) dealloc
{
	self.name = nil;
	self.key = nil;
	[super dealloc];
}

+ (OneChannel *) channelWithName:(NSString *)aName {
	OneChannel *channel = [[self alloc] init];
	channel.name = aName;
	return [channel autorelease];
}

@end

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
	
	if (serverItem->ssl = (*cPort == '+'))
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
	NSMutableArray *channels;
	NSMutableArray *connectCommands;
	struct ircnet *ircNet;
}

@property BOOL autoconnect, favorite;
@property(retain) NSString *name;

+ (NetworkItem *)networkWithIrcnet:(ircnet *)ircNet;
- (void)addServerWithIrcServer:(struct ircserver *)ircServer;
- (void)resetCommands;
- (void)resetAutojoin;

@end

@interface NetworkItem (private)

- (void)parseAutojoin;
- (void)parseCommands;

@end

@implementation NetworkItem
@synthesize name;

+ (NetworkItem *) networkWithIrcnet:(ircnet *)anIrcNet
{
	NetworkItem *network = [[self alloc] init];
	network->ircNet = anIrcNet;
	
	network->name = [[NSString alloc] initWithUTF8String:anIrcNet->name];
	network->servers = [[NSMutableArray alloc] init];
	network->channels = [[NSMutableArray alloc] init];
	network->connectCommands = [[NSMutableArray alloc] init];
	
	for (GSList *list = network->ircNet->servlist; list; list = list->next)
	{
		[network addServerWithIrcServer:(ircserver *)list->data];
	}
	
	[network parseAutojoin];
	[network parseCommands];
	
	return [network autorelease];
}

- (void) dealloc
{
	[name release];
	[servers release];
	[channels release];
	[connectCommands release];
	[super dealloc];
}

- (void) addServerWithIrcServer:(ircserver *)ircServer
{
	[servers addObject:[ServerItem serverWithIrcServer:ircServer]];
}

- (void) resetCommands
{
	free(ircNet->command);
	ircNet->command = strdup([[connectCommands componentsJoinedByString:@"\n"] UTF8String]);
}

- (void) resetAutojoin
{
	free(ircNet->autojoin);
	
	// TODO: should be replaced to autojoin_merge and autojoin_split
	
	NSMutableString *ircNetChannels = [NSMutableString string];
	NSMutableString *ircNetKeys = [NSMutableString string];
	
	// Collect the channels and keys.  Since some channels might not have
	// keys, we need to collec any channels with keys first!  The simplest
	// way to do this is to do it in 2 passes.
	
	// First, the channels with keys
	for ( OneChannel *channel in channels )
	{
		NSString *key = channel->key;
		if (key && [key length])
		{
			if ([ircNetChannels length])
			{
				[ircNetChannels appendString:@","];
				[ircNetKeys appendString:@","];
			}
			
			[ircNetChannels appendString:channel->name];
			[ircNetKeys appendString:key];
		}
	}
	
	// and then the channels without keys
	for ( OneChannel *channel in channels )
	{
		NSString *key = channel->key;
		if ( !key || [key length] == 0)
		{
			if ([ircNetChannels length])
				[ircNetChannels appendString:@","];
			
			[ircNetChannels appendString:channel->name];
		}
	}
	
	if ([ircNetKeys length] > 0)
	{
		[ircNetChannels appendString:@" "];
		[ircNetChannels appendString:ircNetKeys];
	}
	
	ircNet->autojoin = strdup([ircNetChannels UTF8String]);
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

@implementation NetworkItem (private)

- (void) parseAutojoin {
	const char *autojoin = ircNet->autojoin;
	if (autojoin == NULL || autojoin[0] == 0)
		return;
	
	// TODO: should be replaced to autojoin_merge and autojoin_split
	
	// autojoin is in the form of the irc join string
	//
	//		<channel>{,<channel>} [<key>{,<key>}]
	NSString *autojoins = [NSString stringWithUTF8String:autojoin];
	NSArray *autojoinParts = [autojoins componentsSeparatedByString:@" \t\n"];

	NSString *channelsString = [autojoinParts objectAtIndex:0];
	NSString *keysString = [autojoinParts count]>1 ? [autojoinParts objectAtIndex:1] : @"";
	
	for ( NSString *channelName in [channelsString componentsSeparatedByString:@","] ) {
		[channels addObject:[OneChannel channelWithName:channelName]];
	}
	
	// Then assign any keys..
	NSArray *keys = [keysString componentsSeparatedByString:@","];
	
	for ( NSUInteger i = 0; i < [keys count]; i++ ) {
		[[channels objectAtIndex:i] setKey:[keys objectAtIndex:i]];
	}
}

- (void) parseCommands
{
	const char *commandsCString = ircNet->command;
	if ( commandsCString == NULL || commandsCString[0] == 0)
		return;

	for ( NSString *command in [[NSString stringWithUTF8String:commandsCString] componentsSeparatedByString:@"\n"] ) {
		[connectCommands addObject:command];
	}
}

@end

#pragma mark -

@interface NetworkWindow (private)

- (void)savePreferences;
- (void)populateFlag:(id)field fromNetwork:(NetworkItem *)network;
- (void)populateField:(id)field fromNetwork:(NetworkItem *)network;
- (void)populateEditor;
- (void)populateNetworks;
- (void)populate;

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
	NSTableHeaderCell *heartCell = [[[networkTableView tableColumns] objectAtIndex:0] headerCell];
	[heartCell setImage:[NSImage imageNamed:@"heart.tif"]];
	
	NSTableHeaderCell *connectionCell = [[[networkTableView tableColumns] objectAtIndex:1] headerCell];
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
	[networkPasswordTextField setTag:STRUCT_OFFSET_STR(struct ircnet, pass)];
	[networkRealnameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, real)];
	[networkUsernameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, user)];
	[networkNickservPasswordTextField setTag:STRUCT_OFFSET_STR(struct ircnet, nickserv)];
	[charsetComboBox setTag:STRUCT_OFFSET_STR(struct ircnet, encoding)];
	
	// We gotta do a reloadData in order to change the selection, but reload
	// data will call selectionDidChange and thus set prefs.slist_select.  We'll
	// save the value of prefs.slist_select now, and reset the selection after
	// the first reloadData.
	
	NSInteger slist_select = prefs.slist_select;
	
	// make charsets menu
	for (NSString **c = charsets; *c; c++)
	{
		[charsetComboBox addItemWithObjectValue:*c];
	}
	[self populate];
	
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
	[charsetComboBox setObjectValue:[charsetComboBox objectValueOfSelectedItem]];
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
	prefs.slist_skip = [sender intValue];
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
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	if (sender == connectNewButton || !is_session (sess))
		sess = NULL;
	
	network->ircNet->selected = [networkServerTableView selectedRow];	// This kinda stinks. Boo Peter!
																		// Why can't it be an arg to
																		// servlist_connect!?
	servlist_connect (sess, network->ircNet, true);
	
	[self orderOut:sender];
}

- (void) setFlagWithControl:(id)sender
{
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0) return;

	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		
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

	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		
	NSInteger offset = [sender tag];
	char **f = (char **)(((char *)network->ircNet) + offset);
	free (*f);
	const char *v = [[sender stringValue] UTF8String];
	*f = *v ? strdup (v) : NULL;
}

// not used
- (void) doDoneEdit:(id)sender
{
	// Grab values from the GUI and replace in struct ircnet.
	// NOTE: struct ircserver is still edited in real time.
	NSInteger row = [networkTableView selectedRow];
	if (row >= 0)
	{
		NetworkItem *network = [filteredNetworks objectAtIndex:row];
		
		//set_text_value (net_join, &net->net->autojoin);
		
		if (network->ircNet->autojoin)
		{
			char *s = network->ircNet->autojoin;
			char *d = s;
			while (*s)
			{
				if (*s == '\n')
					*s = ',';
				if (*s != ' ')
					*d++ = *s;
				s++;
			}
			*d = 0;
		}
		
		
	}
}

- (void) addChannel:(id)sender
{
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0)
		return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	[network->channels addObject:[OneChannel channelWithName:NSLocalizedStringFromTable(@"NEW CHANNEL", @"xchataqua", @"Default channel name: MainMenu->File->Server List... => (Select server)->On Join->channels->'+'")]];
	
	[networkJoinTableView reloadData];
	
	NSInteger lastIndex = [network->channels count] - 1;	
	[networkJoinTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
	[networkJoinTableView scrollRowToVisible:lastIndex];
	[networkJoinTableView editColumn:0 row:lastIndex withEvent:nil select:YES];
}

- (void) removeChannel:(id)sender
{
	[networkJoinTableView abortEditing];
	
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0) return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	NSInteger channelIndex = [networkJoinTableView selectedRow];
	if (channelIndex < 0) return;
	
	[network->channels removeObjectAtIndex:channelIndex];
	[networkJoinTableView reloadData];
	
	[network resetAutojoin];
}

- (void) addCommand:(id)sender
{
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0) return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	[network->connectCommands addObject:NSLocalizedStringFromTable(@"NEW COMMAND", @"xchataqua", @"Default command: MainMenu->File->Server List... => (Select server)->On Join->commands->'+'")];
	
	[networkCommandTableView reloadData];
	
	NSInteger lastIndex = [network->connectCommands count] - 1;	
	[networkCommandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:lastIndex] byExtendingSelection:NO];
	[networkCommandTableView scrollRowToVisible:lastIndex];
	[networkCommandTableView editColumn:0 row:lastIndex withEvent:nil select:YES];
}

- (void) removeCommand:(id)sender
{
	[networkCommandTableView abortEditing];
	
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0) return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	NSInteger commandIndex = [networkCommandTableView selectedRow];
	if (commandIndex < 0) return;
	
	[network->connectCommands removeObjectAtIndex:commandIndex];
	[networkCommandTableView reloadData];
	
	[network resetCommands];
}

- (void) addServer:(id)sender
{
	NSInteger networkIndex = [networkTableView selectedRow];
	if (networkIndex < 0) return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
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
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	if (g_slist_length (network->ircNet->servlist) < 2)
		return;
	
	[network->servers removeObjectAtIndex:serverIndex];
	
	servlist_server_remove (network->ircNet, (struct ircserver *) g_slist_nth (network->ircNet->servlist, serverIndex)->data);
	
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
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
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
	
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:DraggingDataType]];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:DraggingDataType] owner:self];
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
	
	NetworkItem *network = [filteredNetworks objectAtIndex:[networkTableView selectedRow]];
	
	NSMutableArray *dataArray = nil;
	if ( tableView == networkServerTableView ) {
		dataArray = network->servers;
	}
	else if ( tableView == networkJoinTableView ) {
		dataArray = network->channels;
	}
	else if ( tableView == networkCommandTableView ) {
		dataArray = network->connectCommands;
	} 
	else {
		SGAssert(NO);
	}
	
	id selectedItem = [[dataArray objectAtIndex:selectedRow] retain];
	switch (dropOperation) {
		case NSTableViewDropOn:
			[dataArray replaceObjectAtIndex:selectedRow withObject:[dataArray objectAtIndex:row]];
			[dataArray replaceObjectAtIndex:row withObject:selectedItem];
			break;
		case NSTableViewDropAbove:
			[dataArray removeObjectAtIndex:selectedRow];
			[dataArray insertObject:selectedItem atIndex:row-(row>=selectedRow)];
			[tableView reloadData];
			break;
		default:
			SGAssert(NO);
	}
	[selectedItem release];
	[tableView unregisterDraggedTypes];
	
	if ( tableView == networkJoinTableView ) {
		NetworkItem *network = [filteredNetworks objectAtIndex:[networkTableView selectedRow]];
		[network resetAutojoin];
	}
	else if ( tableView == networkCommandTableView ) {
		NetworkItem *network = [filteredNetworks objectAtIndex:[networkTableView selectedRow]];
		[network resetCommands];
	}
	
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
		NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		prefs.slist_select = [allNetworks indexOfObject:network];
		[self populateEditor];
	}
	else if ([notification object] == networkServerTableView)
	{
		NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		network->ircNet->selected = [networkServerTableView selectedRow];
	}
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == networkTableView)
		return [filteredNetworks count];
	
	NSInteger networkIndex = [self->networkTableView selectedRow];
	if (networkIndex < 0) return 0;

	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	if (aTableView == networkServerTableView)
	{
		return [network->servers count];
	}

	if (aTableView == networkJoinTableView)
	{
		return [network->channels count];
	}

	if (aTableView == networkCommandTableView)
	{
		return [network->connectCommands count];
	}
	
	SGAssert(NO);
	return 0;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) rowIndex
{
	NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
	
	if (aTableView == networkTableView)
	{
		NetworkItem *network =[filteredNetworks objectAtIndex:rowIndex];
		switch (column)
		{
			case 0: return [NSNumber numberWithInteger:[network favorite]];
			case 1: return [NSNumber numberWithInteger:[network autoconnect]];
			case 2: return [network name];
		}
	}
	else
	{
		NSInteger networkIndex = [self->networkTableView selectedRow];
		if (networkIndex < 0) return @"";
		
		NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		
		if (aTableView == networkServerTableView)
		{
			ServerItem *serverItem = [network->servers objectAtIndex:rowIndex];
			switch (column)
			{
				case 0: return serverItem->name;
				case 1: return serverItem->port;
				case 2: return [NSNumber numberWithBool:serverItem->ssl];
			}
		}
		else if (aTableView == networkJoinTableView)
		{
			OneChannel *channel = [network->channels objectAtIndex:rowIndex];
			switch (column)
			{
				case 0: return channel->name;
				case 1: return channel->key;
			}
		}
		else if (aTableView == networkCommandTableView)
		{
			return [network->connectCommands objectAtIndex:rowIndex];
		}
	}
	SGAssert(NO);
	return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
	
	if (aTableView == networkTableView)
	{
		NetworkItem *network =[filteredNetworks objectAtIndex:rowIndex];
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
		
		NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
		
		if (aTableView == networkServerTableView)
		{
			ServerItem *serverItem = [network->servers objectAtIndex:rowIndex];
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
			OneChannel *channel = [network->channels objectAtIndex:rowIndex];
			switch (column)
			{
				case 0: [channel setName:anObject]; break;
				case 1: [channel setKey:anObject]; break;
			}
			[network resetAutojoin];
		}
		else if (aTableView == networkCommandTableView)
		{
			[network->connectCommands replaceObjectAtIndex:rowIndex withObject:anObject];
			[network resetCommands];
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
	
	strcpy (prefs.nick1, [[nick1TextField stringValue] UTF8String]);
	strcpy (prefs.nick2, [[nick2TextField stringValue] UTF8String]);
	strcpy (prefs.nick3, [[nick3TextField stringValue] UTF8String]);
	strcpy (prefs.username, [[usernameTextField stringValue] UTF8String]);
	strcpy (prefs.realname, [[realnameTextField stringValue] UTF8String]);
	
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
	
	NSString *val = str ? [NSString stringWithUTF8String:str] : @"";
	
	[field setStringValue:val];
}

- (void) populateEditor
{
	NSInteger networkIndex = [self->networkTableView selectedRow];
	if (networkIndex < 0) return;
	
	NetworkItem *network = [filteredNetworks objectAtIndex:networkIndex];
	
	[networkTitleTextField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Servers for %s", @"xchat", @""), [network->name UTF8String]]];
	
	[self populateField:networkNicknameTextField fromNetwork:network];
	[self populateField:networkNickname2TextField fromNetwork:network];
	[self populateField:networkPasswordTextField fromNetwork:network];
	[self populateField:networkRealnameTextField fromNetwork:network];
	[self populateField:networkUsernameTextField fromNetwork:network];
	[self populateField:networkNickservPasswordTextField fromNetwork:network];
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

- (void) populateNetworks
{
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

- (void) populate
{
	[nick1TextField setStringValue:[NSString stringWithUTF8String:prefs.nick1]];
	[nick2TextField setStringValue:[NSString stringWithUTF8String:prefs.nick2]];
	[nick3TextField setStringValue:[NSString stringWithUTF8String:prefs.nick3]];
	[realnameTextField setStringValue:[NSString stringWithUTF8String:prefs.realname]];
	[usernameTextField setStringValue:[NSString stringWithUTF8String:prefs.username]];
	
	[showWhenStartupToggleButton setIntegerValue:prefs.slist_skip];
	
	[self populateNetworks];
}

@end