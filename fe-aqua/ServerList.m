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
#include "../common/servlist.h"
#include "../common/cfgfiles.h"

#import "AquaChat.h"
#import "ServerList.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

static NSString *charsets[] =
{
	@"UTF-8",
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
    NULL
};

//////////////////////////////////////////////////////////////////////

@interface OneChannel : NSObject
{
  @public
	NSString	*chan;
	NSString	*key;
}

@end

@implementation OneChannel

- (id) initWithChannel:(NSString *) s
{
	self = [super init];
	
	chan = [s retain];
	
	return self;
}

- (void) dealloc
{
	[chan release];
	[key release];
	[super dealloc];
}

- (void) setChannel:(NSString *) c
{
	[chan release];
	chan = [c retain];
}

- (void) setKey:(NSString *) k
{
	[key release];
	key = [k retain];
}

@end

//////////////////////////////////////////////////////////////////////

@interface OneServer : NSObject
{
  @public
    ircserver	*svr;
    NSString	*server;
    NSString	*port;
	BOOL		ssl;
}

- (id) initWithServer:(ircserver *) server;
- (void) setServer:(NSString *) new_name;
- (void) setPort:(NSString *) new_port;
- (BOOL) setSSL:(NSNumber *) new_ssl;

@end

@implementation OneServer

- (id) initWithServer:(ircserver *) the_svr
{
    svr = the_svr;
	
    const char *the_server = svr->hostname;
    const char *slash = strchr(the_server, '/');
    
    const char *the_port;
    
    if (slash)
    {
        int len = slash - the_server;
		self->server = [[NSString alloc] initWithBytes:the_server length:len encoding:NSUTF8StringEncoding];
        the_port = slash + 1;
	}
    else
    {
		self->server = [[NSString stringWithUTF8String:the_server] retain];
		the_port = "";
    }

	if (ssl = (*the_port == '+'))
	{
		the_port++;
	}
    
    self->port = [[NSString stringWithUTF8String:the_port] retain];
    	
    return self;
}

- (void) dealloc
{
    [self->server release];
    [self->port release];
    [super dealloc];
}

- (void) setServerHost
{
	free (svr->hostname);
	NSString *hostName = self->server;
	if ( [port length] > 0 )
		[hostName stringByAppendingFormat:@"/%@%@", ssl ? @"+" : @"", self->port];
    svr->hostname = strdup ([hostName UTF8String]);
}

- (void) setServer:(NSString *) new_name
{
    [self->server release];
    self->server = [new_name retain];
    [self setServerHost];
}

- (void) setPort:(NSString *) new_port
{
    [self->port release];
    self->port = [new_port retain];
    [self setServerHost];
}

- (BOOL) setSSL:(NSNumber *) new_ssl
{
	ssl = [new_ssl boolValue];
	BOOL willSetPort = ssl && [port length] == 0;
	if (willSetPort)
		[self setPort:@"6667"];
	[self setServerHost];
	return willSetPort;
}

@end

//////////////////////////////////////////////////////////////////////

@interface OneNetwork : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableArray	*servers;
	NSMutableArray	*channels;
	NSMutableArray	*connectCommands;
    ircnet			*net;
}

- (id) initWithIrcnet:(ircnet *)ircnet;
- (void) addServer:(ircserver *)svr;

@end

@implementation OneNetwork

- (void) parseAutojoin
{
	const char *autojoin = net->autojoin;
	if (autojoin == NULL || autojoin[0] == 0)
		return;

	// autojoin is in the form of the irc join string
	//
	//		<channel>{,<channel>} [<key>{,<key>}]
	
	SGTokenizer *tok = [[SGTokenizer alloc] initWithString:[NSString stringWithCString:autojoin encoding:NSASCIIStringEncoding]];

	NSString *chans = [tok getNextToken:" \t\n"];
	NSString *keys = [tok getNextToken:" \t\n"];

	// Parse out the channel names
	[tok setString:chans];
	for (NSString *s = [tok getNextToken:","]; s != nil; s = [tok getNextToken:","] )
	{
		OneChannel *chan = [[OneChannel alloc] initWithChannel:s];
		[channels addObject:chan];
		[chan release];
	}	

	// Then assign any keys..
	[tok setString:keys];
	for (NSUInteger i = 0; i < [channels count]; i ++)
	{
		NSString *s = [tok getNextToken:","];
		if (!s)
			break;
		[[channels objectAtIndex:i] setKey:s];
	}
	
	[tok release];
}

- (void) parseCommands
{
	const char *command = net->command;
	if (!command || command[0] == 0)
		return;
	
	SGTokenizer *tok = [[SGTokenizer alloc] initWithString:[NSString stringWithCString:command encoding:NSASCIIStringEncoding]];
	
	for (NSString *s = [tok getNextToken:"\n"]; s != nil; s = [tok getNextToken:"\n"])
		[connectCommands addObject:s];
		
	[tok release];
}

- (id) initWithIrcnet:(ircnet *) ircnet
{
    self->net = ircnet;
    
    name = [[NSMutableString stringWithUTF8String:ircnet->name] retain];
    servers = [[NSMutableArray arrayWithCapacity:0] retain];
	channels = [[NSMutableArray arrayWithCapacity:0] retain];
	connectCommands = [[NSMutableArray arrayWithCapacity:0] retain];

    for (GSList *list = net->servlist; list; list = list->next)
    {
        ircserver *svr = (ircserver *) list->data;
        [self addServer:svr];
    }
    
	[self parseAutojoin];
	[self parseCommands];

    return self;
}

- (void) dealloc
{
    [name release];
    [servers release];
	[channels release];
	[connectCommands release];
    [super dealloc];
}

- (void) resetCommands
{
	free (net->command);
	
	NSMutableString *cmds = [NSMutableString stringWithCapacity:100];

	for (NSUInteger i = 0; i < [connectCommands count]; i++)
	{
		if ([cmds length])
			[cmds appendString:@"\n"];
		[cmds appendString:[connectCommands objectAtIndex:i]];
	}
	
	net->command = strdup([cmds UTF8String]);
}

- (void) resetAutojoin
{
	free (net->autojoin);

	NSMutableString *chans = [NSMutableString stringWithCapacity:100];
	NSMutableString *keys = [NSMutableString stringWithCapacity:100];
	
	// Collect the channels and keys.  Since some channels might not have
	// keys, we need to collec any channels with keys first!  The simplest
	// way to do this is to do it in 2 passes.
	
	// First, the channels with keys
	for (NSUInteger i = 0; i < [channels count]; i++)
	{
		OneChannel *chan = (OneChannel *) [channels objectAtIndex:i];
		
		NSString *key = chan->key;
		if (key && [key length])
		{
			if ([chans length])
			{
				[chans appendString:@","];
				[keys appendString:@","];
			}
			
			[chans appendString:chan->chan];
			[keys appendString:key];
		}
	}

	// and then the channels without keys
	for (NSUInteger i = 0; i < [channels count]; i++)
	{
		OneChannel *chan = (OneChannel *) [channels objectAtIndex:i];
		
		NSString *key = chan->key;
		if (!key || [key length] == 0)
		{
			if ([chans length])
				[chans appendString:@","];
			
			[chans appendString:chan->chan];
		}
	}
	
	if ([keys length] > 0)
	{
		[chans appendString:@" "];
		[chans appendString:keys];
	}
	
	net->autojoin = strdup([chans UTF8String]);
}

- (void) addServer:(ircserver *) svr
{
    [servers addObject:[[OneServer alloc] initWithServer:svr]];
}

- (NSString *) name
{
	return name;
}

- (void) setName:(NSString *)aName
{
    [name release];
    name = [aName retain];
    free(net->name);
    net->name = strdup([aName UTF8String]);
}

- (void) setAutoconnect:(BOOL) new_val
{
	if (new_val)
		net->flags |= FLAG_AUTO_CONNECT;
	else
		net->flags &= ~FLAG_AUTO_CONNECT;
}
 
- (BOOL) autoconnect
{
	return (net->flags & FLAG_AUTO_CONNECT) > 0;
}

- (void) setFavorite:(BOOL) new_val
{
	if (new_val)
		net->flags |= FLAG_FAVORITE;
	else
		net->flags &= ~FLAG_FAVORITE;
}

- (BOOL) favorite
{
	return (net->flags & FLAG_FAVORITE) > 0;
}

@end

//////////////////////////////////////////////////////////////////////

static ServerList *instance;

@implementation ServerList

- (void) showForSession:(session *) sess
{
    self->servlistSession = sess;
    
    [[nick1TextField window] makeKeyAndOrderFront:self];
}

+ (void) showForSession:(session *) sess
{
	if (!instance)
		instance = [[ServerList alloc] init];
	
	[instance showForSession:sess];
}

- (id) init
{
    [super init];
        
    [NSBundle loadNibNamed:@"ServerList" owner:self];

    return self;
}

- (void) dealloc
{
    [AquaChat sharedAquaChat]->server_list = nil;
    
    [[nick1TextField window] release];
    [myNetworks release];
    [allNetworks release];
    
    [super dealloc];
}

- (void) savegui
{
    [[nick1TextField window] makeFirstResponder:nick1TextField];
    
    strcpy (prefs.nick1, [[nick1TextField stringValue] UTF8String]);
    strcpy (prefs.nick2, [[nick2TextField stringValue] UTF8String]);
    strcpy (prefs.nick3, [[nick3TextField stringValue] UTF8String]);
    strcpy (prefs.username, [[usernameTextField stringValue] UTF8String]);
    strcpy (prefs.realname, [[realnameTextField stringValue] UTF8String]);

    servlist_save ();
}

- (void) doConnect:(id) sender
{
    NSInteger row = [networkTableView selectedRow];
    if (row < 0)
        return;

    [self savegui];

    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];

    if (sender == connectNewButton || !is_session (servlistSession))
        servlistSession = NULL;

    net->net->selected = [networkServerTableView selectedRow];	// This kinda stinks. Boo Peter!
                                                        // Why can't it be an arg to
                                                        // servlist_connect!?
    servlist_connect (servlistSession, net->net, true);

    [[nick1TextField window] orderOut:sender];
}

- (void) doSetFlag:(id) sender
{
    NSInteger row = [networkTableView selectedRow];
    if (row >= 0)
	{
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];

		BOOL val = [sender intValue];

		NSInteger flag = [sender tag];
		if (flag < 0)
		{
			flag = ~flag;
			val = !val;
		}

		guint32 *flags = &net->net->flags;
		if (val)
			*flags |= flag;
		else
			*flags &= ~flag;
	}
}

- (void) doSetField:(id) sender
{
    NSInteger row = [networkTableView selectedRow];
    if (row >= 0)
	{
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];

		NSInteger offset = [sender tag];
		char **f = (char **)(((char *) net->net) + offset);
		free (*f);
		const char *v = [[sender stringValue] UTF8String];
		*f = *v ? strdup (v) : NULL;
	}
}

- (void) doDoneEdit:(id) sender
{
	// Grab values from the GUI and replace in struct ircnet.
	// NOTE: struct ircserver is still edited in real time.
    NSInteger row = [networkTableView selectedRow];
    if (row >= 0)
    {
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];

		//set_text_value (net_join, &net->net->autojoin);
		
		if (net->net->autojoin)
		{
			char *s = net->net->autojoin;
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

- (void) windowWillClose:(NSNotification *) xx
{
	// Close the drawer.  If we leave it open and then try to cycle
	// the windows, we'll find it even though it's not really visible!
	[showDetailButton setIntValue:0];
	[self showDetail:showDetailButton];
	
    [self savegui];
}

- (void) toggleShowWhenStartup:(id) sender
{
    prefs.slist_skip = ![sender intValue];
}

- (void) doClose:(id) sender
{
	[[nick1TextField window] close];
}

- (void) toggleCustomUserInformation:(id) sender
{
    bool doit = [sender intValue];
    
    [networkNicknameTextField setEnabled:doit];
    [networkNickname2TextField setEnabled:doit];
    [networkRealnameTextField setEnabled:doit];
    [networkUsernameTextField setEnabled:doit];
	
	[self doSetFlag:networkUseCustomInformationToggleButton];
}

- (void) comboBoxSelectionDidChange:(NSNotification *) notification
{
	[charsetComboBox setObjectValue:[charsetComboBox objectValueOfSelectedItem]];
}

- (void) populateFlag:(id)check fromNetwork:(OneNetwork *) net
{
	NSInteger flag = [check tag];
	BOOL invert = flag < 0;
	if (invert)
		flag = ~flag;

	BOOL	val = (net->net->flags & flag) != 0;
	
	if (invert)
		val = !val;
		
	[check setIntValue:val];
}

- (void) populateField:(id)field fromNetwork:(OneNetwork *) net
{
	NSInteger offset = [field tag];
	char **f = (char **)(((char *) net->net) + offset);
	char *str = *f;
	
	NSString *val = str ? [NSString stringWithUTF8String:str] : @"";

	[field setStringValue:val];
}

- (void) populate_editor
{
    NSInteger row = [self->networkTableView selectedRow];
    if (row < 0)
		return;

	OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
	
	[networkTitleTextField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Servers for %s", @"xchat", @""), net->name]];
			
	[self populateField:networkNicknameTextField fromNetwork:net];
	[self populateField:networkNickname2TextField fromNetwork:net];
	[self populateField:networkPasswordTextField fromNetwork:net];
	[self populateField:networkRealnameTextField fromNetwork:net];
	[self populateField:networkUsernameTextField fromNetwork:net];
	[self populateField:networkNickservPasswordTextField fromNetwork:net];
	[self populateField:charsetComboBox fromNetwork:net];

	[self populateFlag:networkAutoConnectToggleButton fromNetwork:net];
	[self populateFlag:networkSelectedOnlyToggleButton fromNetwork:net];
	[self populateFlag:networkUseCustomInformationToggleButton fromNetwork:net];
	[self populateFlag:networkUseProxyToggleButton fromNetwork:net];
	[self populateFlag:networkUseSslToggleButton fromNetwork:net];
	[self populateFlag:networkAcceptInvalidCertificationToggleButton fromNetwork:net];

	[self toggleCustomUserInformation:networkUseCustomInformationToggleButton];
	
	NSInteger selected = net->net->selected;

	[networkJoinTableView reloadData];
	[networkCommandTableView reloadData];
	[networkServerTableView reloadData];

	if (selected < [self numberOfRowsInTableView:networkServerTableView])
	{
		[networkServerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected] byExtendingSelection:NO];
		[networkServerTableView scrollRowToVisible:selected];
	}
}

- (void) showDetail:(id) sender
{
	if ([sender intValue])
	{
		[drawer open];
	}
	else
	{
		[drawer close];
	}
}

- (void) doNewChannel:(id) sender
{
	NSInteger nrow = [networkTableView selectedRow];
	if (nrow < 0)
		return;
        
	OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];

	OneChannel *chan = [[OneChannel alloc] initWithChannel:NSLocalizedStringFromTable(@"NEW CHANNEL", @"xchataqua", @"Default channel name: MainMenu->File->Server List... => (Select server)->On Join->channels->'+'")];
	[net->channels addObject:chan];
	
	[networkJoinTableView reloadData];
	
	NSInteger last = [net->channels count] - 1;    
	[networkJoinTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:last] byExtendingSelection:NO];
	[networkJoinTableView scrollRowToVisible:last];
	[networkJoinTableView editColumn:0 row:last withEvent:nil select:YES];
}

- (void) doRemoveChannel:(id) sender
{
	[networkJoinTableView abortEditing];

    NSInteger nrow = [networkTableView selectedRow];
    if (nrow < 0)
        return;

    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];

    NSInteger crow = [networkJoinTableView selectedRow];
    if (crow < 0)
        return;

	[net->channels removeObjectAtIndex:crow];
	[networkJoinTableView reloadData];
	
	[net resetAutojoin];
}

- (void) doNewCommand:(id) sender
{
	NSInteger nrow = [networkTableView selectedRow];
	if (nrow < 0) return;
        
	OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];

	[net->connectCommands addObject:NSLocalizedStringFromTable(@"NEW COMMAND", @"xchataqua", @"Default command: MainMenu->File->Server List... => (Select server)->On Join->commands->'+'")];
	
	[networkCommandTableView reloadData];
	
	NSInteger last = [net->connectCommands count] - 1;    
	[networkCommandTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:last] byExtendingSelection:NO];
	[networkCommandTableView scrollRowToVisible:last];
	[networkCommandTableView editColumn:0 row:last withEvent:nil select:YES];
}

- (void) doRemoveCommand:(id) sender
{
	[networkCommandTableView abortEditing];

    NSInteger nrow = [networkTableView selectedRow];
    if (nrow < 0)
        return;

    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];

    NSInteger crow = [networkCommandTableView selectedRow];
    if (crow < 0)
        return;

	[net->connectCommands removeObjectAtIndex:crow];
	[networkCommandTableView reloadData];
	
	[net resetCommands];
}

- (void) doRemoveServer:(id) sender
{
	[networkServerTableView abortEditing];

    NSInteger nrow = [networkTableView selectedRow];
    if (nrow < 0)
        return;

    NSInteger srow = [networkServerTableView selectedRow];
    if (srow < 0)
        return;
        
    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];
    
    if (g_slist_length (net->net->servlist) < 2)
        return;
                
    [net->servers removeObjectAtIndex:srow];
    
    ircserver *serv = (ircserver *) g_slist_nth (net->net->servlist, srow)->data;
    servlist_server_remove (net->net, serv);
    
    [networkServerTableView reloadData];
}

- (void) doEditServer:(id) sender
{
	NSInteger sel = [networkServerTableView selectedRow];
	if (sel >= 0)
	{
		[networkServerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:sel] byExtendingSelection:NO];
		[networkServerTableView editColumn:0 row:sel withEvent:nil select:YES];
	}
}

- (void) doNewServer:(id) sender
{
  NSInteger nrow = [networkTableView selectedRow];
  if (nrow < 0)
    return;

  NSInteger srow = [networkServerTableView selectedRow];
  if (srow < 0)
    return;
        
  OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:nrow];
	
  ircserver *svr = servlist_server_add (net->net, "NewServer");
    
  [net addServer:svr];
  [networkServerTableView reloadData];
    
  NSInteger last = [net->servers count] - 1;    
  [networkServerTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:last] byExtendingSelection:NO];
  [networkServerTableView scrollRowToVisible:last];
	
	[self doEditServer:sender];
}

- (void) doNewNetwork:(id) sender
{
	ircnet *net = servlist_net_add ((char*)[NSLocalizedStringFromTable(@"New Network", @"xchat", @"") UTF8String], "", false);
	servlist_server_add (net, "NewServer");
	[myNetworks addObject:[[OneNetwork alloc] initWithIrcnet:net]];
	[networkTableView reloadData];
	
	NSInteger last = [self numberOfRowsInTableView:networkTableView] - 1;
	[networkTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:last] byExtendingSelection:NO];
	[networkTableView editColumn:2 row:last withEvent:nil select:YES];
}

- (void) doRemoveNetwork:(id) sender
{
	[networkTableView abortEditing];

    NSInteger row = [networkTableView selectedRow];
    if (row < 0)
        return;
    
    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];

    if (![SGAlert confirmWithString:[NSString stringWithFormat:
		NSLocalizedStringFromTable(@"Really remove network \"%@\" and all its servers?", @"xchat", @"Dialog Message from clicking '-' of MainMenu->File->Server List..."), net->name]])
		return;
    
    servlist_net_remove (net->net);
    [myNetworks removeObjectAtIndex:row];
    [networkTableView reloadData];
}

- (void) doFilter:(id) sender
{
	NSString *filter = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	const char *cfilter = [filter UTF8String];
	
	[myNetworks release];
	
	if (!cfilter || !cfilter[0])
	{
		myNetworks = [allNetworks retain];
	}
	else
	{
		myNetworks = [[NSMutableArray arrayWithCapacity:0] retain];

		for (NSUInteger i = 0; i < [allNetworks count]; i ++)
		{
			OneNetwork *net = [allNetworks objectAtIndex:i];
			
			if (strcasestr (net->net->name, cfilter))
				[myNetworks addObject:net];
		}
	}
    
    [networkTableView reloadData];
	
	// Simulate new selection
	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"dummy" object:networkTableView]];
}

- (void) populate_nets
{
	[myNetworks release];
	[allNetworks release];
	
    allNetworks = [[NSMutableArray arrayWithCapacity:0] retain];
	myNetworks = [allNetworks retain];

    for (GSList *list = network_list; list; list = list->next)
    {
        ircnet *net = (ircnet *) list->data;
		[myNetworks addObject:[[OneNetwork alloc] initWithIrcnet:net]];
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

    [showWhenStartupToggleButton setIntValue:!prefs.slist_skip];
	
	[self populate_nets];
}    

- (void) make_charset_menu
{
    for (NSString **c = charsets; *c; c ++)
    {
        [charsetComboBox addItemWithObjectValue:*c];
    }
}

- (void) awakeFromNib
{
	// 10.3 doesn't support small square buttons.
	// This is the next best thing
	[SGGuiUtil fixSquareButtonsInView:[showWhenStartupToggleButton superview]];
	[SGGuiUtil fixSquareButtonsInView:[networkNicknameTextField superview]];
	[SGGuiUtil fixSquareButtonsInView:[[[networkJoinTableView superview] superview] superview]];
	
	NSFont *font = [showWhenStartupToggleButton font];
	for (NSView *view in [[[networkTableView window] contentView] subviews])
	{
		if ([view isKindOfClass:[NSButton class]])
		{
			[(NSButton *) view setFont:font];
		}
	}
	
	for (NSUInteger i = 0; i < [networkServerTableView numberOfColumns]; i ++)
	{
		id col = [[networkServerTableView tableColumns] objectAtIndex:i];
		[col setIdentifier:[NSNumber numberWithInt:i]];
	}

	for (NSUInteger i = 0; i < [networkJoinTableView numberOfColumns]; i ++)
	{
		id col = [[networkJoinTableView tableColumns] objectAtIndex:i];
		[col setIdentifier:[NSNumber numberWithInt:i]];
	}
	
	NSTableColumn *fav_col = [[networkTableView tableColumns] objectAtIndex:0];
	NSTableHeaderCell *heart_cell = [fav_col headerCell];
	[heart_cell setImage:[NSImage imageNamed:@"heart.tif"]];
	
	NSTableColumn *conn_col = [[networkTableView tableColumns] objectAtIndex:1];
	NSTableHeaderCell *conn_cell = [conn_col headerCell];
	[conn_cell setImage:[NSImage imageNamed:@"connect.tif"]];
	
	[[nick1TextField window] setDelegate:self];
	
	[self->networkServerTableView setDataSource:self];
	[self->networkServerTableView setDelegate:self];
	
	[self->networkJoinTableView setDataSource:self];
	[self->networkJoinTableView setDelegate:self];
	
	[self->networkCommandTableView setDataSource:self];
	[self->networkCommandTableView setDelegate:self];
	
	[self->networkTableView setDataSource:self];
	[self->networkTableView setDelegate:self];
	[self->networkTableView setAutosaveTableColumns:YES];
    
	[networkAutoConnectToggleButton setTag:FLAG_AUTO_CONNECT];
	[networkUseCustomInformationToggleButton setTag:~FLAG_USE_GLOBAL];
	[networkUseProxyToggleButton setTag:~FLAG_USE_PROXY];
	[networkUseSslToggleButton setTag:FLAG_USE_SSL];
	[networkAcceptInvalidCertificationToggleButton setTag:FLAG_ALLOW_INVALID];
	[networkSelectedOnlyToggleButton setTag:~FLAG_CYCLE];

	[networkNicknameTextField setTag:STRUCT_OFFSET_STR(ircnet, nick)];
	[networkNickname2TextField setTag:STRUCT_OFFSET_STR(ircnet, nick2)];
	[networkPasswordTextField setTag:STRUCT_OFFSET_STR(ircnet, pass)];
	[networkRealnameTextField setTag:STRUCT_OFFSET_STR(ircnet, real)];
	[networkUsernameTextField setTag:STRUCT_OFFSET_STR(ircnet, user)];
	[networkNickservPasswordTextField setTag:STRUCT_OFFSET_STR(ircnet, nickserv)];
	[charsetComboBox setTag:STRUCT_OFFSET_STR(ircnet, encoding)];

    // We gotta do a reloadData in order to change the selection, but reload
    // data will call selectionDidChange and thus set prefs.slist_select.  We'll
    // save the value of prefs.slist_select now, and reset the selection after
    // the first reloadData.
    
	NSInteger slist_select = prefs.slist_select;
    
	[self make_charset_menu];
	[self populate];

	[myNetworks sortUsingDescriptors:[networkTableView sortDescriptors]];
	[networkTableView reloadData];

	if (slist_select < [self numberOfRowsInTableView:networkTableView])
	{
		[networkTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:slist_select] byExtendingSelection:NO];
		[networkTableView scrollRowToVisible:slist_select];
	}

	[[nick1TextField window] center];
}

//
// Table delegates
//

- (void) tableViewSelectionDidChange:(NSNotification *) notification
{
	NSInteger row = [self->networkTableView selectedRow];
	if (row < 0)
		return;
		
    if ([notification object] == networkTableView)
	{
		// Figure out what was selected from the allNetworks
		id selected = [myNetworks objectAtIndex:row];
		row = [allNetworks indexOfObject:selected];
		prefs.slist_select = row;
		[self populate_editor];
	}
	else if ([notification object] == networkServerTableView)
	{
	    OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		net->net->selected = [networkServerTableView selectedRow];
	}
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    if (aTableView == networkTableView)
        return [myNetworks count];
    
	if (aTableView == networkServerTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return 0;
			
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		return [net->servers count];
	}
	
	if (aTableView == networkJoinTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return 0;
			
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		return [net->channels count];
	}
	
	if (aTableView == networkCommandTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return 0;
			
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		return [net->connectCommands count];
	}
	
	return 0;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger) rowIndex
{
	NSInteger col = [[aTableColumn identifier] integerValue];
	
    if (aTableView == networkTableView)
	{
		OneNetwork *net =[myNetworks objectAtIndex:rowIndex];
		
		switch (col)
		{
			case 0:
				return [NSNumber numberWithInt:[net favorite]];
			case 1:
				return [NSNumber numberWithInt:[net autoconnect]];
			case 2:
				return [net name];
		}
	}
	else if (aTableView == networkServerTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return @"";

		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		OneServer *svr = (OneServer *) [net->servers objectAtIndex:rowIndex];
		
		switch (col)
		{
			case 0: return svr->server;
			case 1: return svr->port;
			case 2: return [NSNumber numberWithBool:svr->ssl];
		}
	}
	else if (aTableView == networkJoinTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return @"";
			
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		OneChannel *chan = (OneChannel *) [net->channels objectAtIndex:rowIndex];
		
		switch (col)
		{
			case 0: return chan->chan;
			case 1: return chan->key;
		}
	}
	else if (aTableView == networkCommandTableView)
	{
		NSInteger row = [self->networkTableView selectedRow];
		if (row < 0)
			return @"";
			
		OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:row];
		return [net->connectCommands objectAtIndex:rowIndex];
	}
    
    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(NSInteger)rowIndex
{
	NSInteger col = [[aTableColumn identifier] integerValue];
	
    if (aTableView == networkTableView)
    {
		OneNetwork *net =[myNetworks objectAtIndex:rowIndex];

		switch (col)
		{
			case 0:
				[net setFavorite:[anObject boolValue]];
				break;
			case 1:
				[net setAutoconnect:[anObject boolValue]];
				break;
			case 2:
				[net setName:anObject];
		}
    }
    else if (aTableView == networkServerTableView)
    {
		if ([networkTableView selectedRow] < 0)
			return;

        OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:[networkTableView selectedRow]];
        OneServer *svr = (OneServer *) [net->servers objectAtIndex:rowIndex];
        switch (col)
        {
            case 0: 
                [svr setServer:anObject];
                break;
            case 1:
                [svr setPort:anObject];
                break;
            case 2:
			{
                bool needReload = [svr setSSL:anObject];
				if (needReload)
					[networkServerTableView reloadData];
                break;
			}
        }
    }
    else if (aTableView == networkJoinTableView)
    {
		if ([networkTableView selectedRow] < 0)
			return;

        OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:[networkTableView selectedRow]];
		OneChannel *chan = (OneChannel *) [net->channels objectAtIndex:rowIndex];
        switch (col)
        {
            case 0: 
                [chan setChannel:anObject];
                break;
            case 1:
                [chan setKey:anObject];
                break;
        }
		[net resetAutojoin];
    }
    else if (aTableView == networkCommandTableView)
    {
		if ([networkTableView selectedRow] < 0)
			return;

        OneNetwork *net = (OneNetwork *) [myNetworks objectAtIndex:[networkTableView selectedRow]];
		[net->connectCommands replaceObjectAtIndex:rowIndex withObject:anObject];
		[net resetCommands];
    }
}

- (void) tableView:(NSTableView *) aTableView
	didClickTableColumn:(NSTableColumn *) aTableColumn
{
    if (aTableView == networkTableView)
	{
		NSArray *descs = [aTableView sortDescriptors];
		[myNetworks sortUsingDescriptors:descs];
		[networkTableView reloadData];
		[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:networkTableView]];
	}
}

@end
