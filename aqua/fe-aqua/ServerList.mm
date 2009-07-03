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
#include "../common/servlist.h"
#include "../common/cfgfiles.h"
	
const char * XALocalizeString(const char *);
}

#import "AquaChat.h"
#import "ServerList.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

static NSString *charsets [] =
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

@interface oneChannel : NSObject
{
  @public
	NSString	*chan;
	NSString	*key;
}

@end

@implementation oneChannel

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

@interface oneServer : NSObject
{
  @public
    ircserver	*svr;
    NSString	*server;
    NSString	*port;
	bool		ssl;
}

- (id) initWithServer:(ircserver *) server;
- (void) setServer:(NSString *) new_name;
- (void) setPort:(NSString *) new_port;
- (bool) setSSL:(NSNumber *) new_ssl;

@end

@implementation oneServer

- (id) initWithServer:(ircserver *) the_svr
{
    svr = the_svr;
	
    const char *the_server = svr->hostname;
    const char *slash = strchr (the_server, '/');
    
    const char *the_port;
    
    if (slash)
    {
        int len = slash - the_server;
		self->server = [[NSString alloc] initWithBytes:the_server
				length:len encoding:NSUTF8StringEncoding];
        the_port = slash + 1;
	}
    else
    {
		self->server = [[NSString stringWithUTF8String:the_server] retain];
		the_port = "";
    }

	if (ssl = (*the_port == '+'))
	{
		the_port ++;
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
    NSString *s = [port length] ? 
        [NSString stringWithFormat:@"%@/%@%@", self->server, ssl ? @"+" : @"", self->port] : self->server;
    svr->hostname = strdup ([s UTF8String]);
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

- (bool) setSSL:(NSNumber *) new_ssl
{
	ssl = [new_ssl boolValue];
	bool willSetPort = ssl && [port length] == 0;
	if (willSetPort)
		[self setPort:@"6667"];
	[self setServerHost];
	return willSetPort;
}

@end

//////////////////////////////////////////////////////////////////////

@interface oneNet : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableArray	*servers;
	NSMutableArray	*channels;
	NSMutableArray	*connect_commands;
    ircnet			*net;
}

- (id) initWithIrcnet:(ircnet *) ircnet;
- (void) addServer:(ircserver *) svr;

@end

@implementation oneNet

- (void) parseAutojoin
{
	const char *autojoin = net->autojoin;
	if (autojoin == NULL || autojoin[0] == 0)
		return;

	// autojoin is in the form of the irc join string
	//
	//		<channel>{,<channel>} [<key>{,<key>}]
	
	SGTokenizer *tok = [[SGTokenizer alloc] initWithString:[NSString stringWithCString:autojoin]];

	NSString *chans = [tok getNextToken:" \t\n"];
	NSString *keys = [tok getNextToken:" \t\n"];

	// Parse out the channel names
	[tok setString:chans];
	for (NSString *s; s = [tok getNextToken:","]; )
	{
		oneChannel *chan = [[oneChannel alloc] initWithChannel:s];
		[channels addObject:chan];
		[chan release];
	}	

	// Then assign any keys..
	[tok setString:keys];
	for (unsigned i = 0; i < [channels count]; i ++)
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
	
	SGTokenizer *tok = [[SGTokenizer alloc] initWithString:[NSString stringWithCString:command]];
	
	for (NSString *s; s = [tok getNextToken:"\n"]; )
		[connect_commands addObject:s];
		
	[tok release];
}

- (id) initWithIrcnet:(ircnet *) ircnet
{
    self->net = ircnet;
    
    name = [[NSMutableString stringWithUTF8String:ircnet->name] retain];
    servers = [[NSMutableArray arrayWithCapacity:0] retain];
	channels = [[NSMutableArray arrayWithCapacity:0] retain];
	connect_commands = [[NSMutableArray arrayWithCapacity:0] retain];

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
	[connect_commands release];
    [super dealloc];
}

- (void) resetCommands
{
	free (net->command);
	
	NSMutableString *cmds = [NSMutableString stringWithCapacity:100];

	for (unsigned i = 0; i < [connect_commands count]; i++)
	{
		if ([cmds length])
			[cmds appendString:@"\n"];
		[cmds appendString:[connect_commands objectAtIndex:i]];
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
	for (unsigned i = 0; i < [channels count]; i++)
	{
		oneChannel *chan = (oneChannel *) [channels objectAtIndex:i];
		
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
	for (unsigned i = 0; i < [channels count]; i++)
	{
		oneChannel *chan = (oneChannel *) [channels objectAtIndex:i];
		
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
    [servers addObject:[[oneServer alloc] initWithServer:svr]];
}

- (NSString *) name
{
	return name;
}

- (void) setName:(NSString *) new_name
{
    [name release];
    name = [new_name retain];
    free (net->name);
    net->name = strdup ([new_name UTF8String]);
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

- (void) show_for_session:(session *) sess
{
    self->servlist_sess = sess;
    
    [[nick1 window] makeKeyAndOrderFront:self];
}

+ (void) show_for_session:(session *) sess
{
	if (!instance)
		instance = [[ServerList alloc] init];
	
	[instance show_for_session:sess];
}

- (id) init
{
    [super init];
        
    [NSBundle loadNibNamed:@"ServerList" owner:self];

    return self;
}

- (void) dealloc
{
    [AquaChat sharedAquaChat]->server_list = NULL;
    
    [[nick1 window] release];
    [my_nets release];
    [all_nets release];
    
    [super dealloc];
}

- (void) savegui
{
    [[nick1 window] makeFirstResponder:nick1];
    
    strcpy (prefs.nick1, [[nick1 stringValue] UTF8String]);
    strcpy (prefs.nick2, [[nick2 stringValue] UTF8String]);
    strcpy (prefs.nick3, [[nick3 stringValue] UTF8String]);
    strcpy (prefs.username, [[username stringValue] UTF8String]);
    strcpy (prefs.realname, [[realname stringValue] UTF8String]);

    servlist_save ();
}

- (void) do_connect:(id) sender
{
    int row = [net_list selectedRow];
    if (row < 0)
        return;

    [self savegui];

    oneNet *net = (oneNet *) [my_nets objectAtIndex:row];

    if (sender == connect_new_button || !is_session (servlist_sess))
        servlist_sess = NULL;

    net->net->selected = [net_server_list selectedRow];	// This kinda stinks. Boo Peter!
                                                        // Why can't it be an arg to
                                                        // servlist_connect!?
    servlist_connect (servlist_sess, net->net, true);

    [[nick1 window] orderOut:sender];
}

- (void) do_set_flag:(id) sender
{
    int row = [net_list selectedRow];
    if (row >= 0)
	{
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];

		bool val = [sender intValue];

		int flag = [sender tag];
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

- (void) do_set_field:(id) sender
{
    int row = [net_list selectedRow];
    if (row >= 0)
	{
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];

		int offset = [sender tag];
		char **f = (char **)(((char *) net->net) + offset);
		free (*f);
		const char *v = [[sender stringValue] UTF8String];
		*f = *v ? strdup (v) : NULL;
	}
}

- (void) do_done_edit:(id) sender
{
	// Grab values from the GUI and replace in struct ircnet.
	// NOTE: struct ircserver is still edited in real time.
    int row = [net_list selectedRow];
    if (row >= 0)
    {
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];

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
	[show_details_button setIntValue:0];
	[self do_drawer:show_details_button];
	
    [self savegui];
}

- (void) do_serverlist_toggle:(id) sender
{
    prefs.slist_skip = ![sender intValue];
}

- (void) do_close:(id) sender
{
	[[nick1 window] close];
}

- (void) use_global_toggled:(id) sender
{
    bool doit = [sender intValue];
    
    [net_nick setEnabled:doit];
    [net_nick2 setEnabled:doit];
    [net_real setEnabled:doit];
    [net_user setEnabled:doit];
	
	[self do_set_flag:net_use_global];
}

- (void) comboBoxSelectionDidChange:(NSNotification *) notification
{
	[charset_combo setObjectValue:[charset_combo objectValueOfSelectedItem]];
}

- (void) populateFlag:(id) check
			  fromNet:(oneNet *) net
{
	int flag = [check tag];
	bool invert = flag < 0;
	if (invert)
		flag = ~flag;

	bool val = (net->net->flags & flag) != 0;
	
	if (invert)
		val = !val;
		
	[check setIntValue:val];
}

- (void) populateField:(id) field
			   fromNet:(oneNet *) net
{
	int offset = [field tag];
	char **f = (char **)(((char *) net->net) + offset);
	char *str = *f;
	
	NSString *val = str ? [NSString stringWithUTF8String:str] : @"";

	[field setStringValue:val];
}

- (void) populate_editor
{
    int row = [self->net_list selectedRow];
    if (row < 0)
		return;

	oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
	
	[net_title_text setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Servers for %s", @"xchat", @""), net->name]];
			
	[self populateField:net_nick fromNet:net];
	[self populateField:net_nick2 fromNet:net];
	[self populateField:net_pass fromNet:net];
	[self populateField:net_real fromNet:net];
	[self populateField:net_user fromNet:net];
	[self populateField:net_nickserv_passwd fromNet:net];
	[self populateField:charset_combo fromNet:net];

	[self populateFlag:net_auto fromNet:net];
	[self populateFlag:net_connect_selected fromNet:net];
	[self populateFlag:net_use_global fromNet:net];
	[self populateFlag:net_use_proxy fromNet:net];
	[self populateFlag:net_use_ssl fromNet:net];
	[self populateFlag:net_accept_invalid fromNet:net];

	[self use_global_toggled:net_use_global];
	
	int selected = net->net->selected;

	[net_join_table reloadData];
	[net_command_table reloadData];
	[net_server_list reloadData];

	if (selected < [self numberOfRowsInTableView:net_server_list])
	{
		[net_server_list selectRow:selected byExtendingSelection:false];
		[net_server_list scrollRowToVisible:selected];
	}
}

- (void) do_drawer:(id) sender
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

- (void) do_new_channel:(id) sender
{
	int nrow = [net_list selectedRow];
    if (nrow < 0)
		return;
        
    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];

	oneChannel *chan = [[oneChannel alloc] initWithChannel:NSLocalizedStringFromTable(@"NEW CHANNEL", @"xchataqua", @"Default channel name: MainMenu->File->Server List... => (Select server)->On Join->channels->'+'")];
	[net->channels addObject:chan];
	
	[net_join_table reloadData];
	
	int last = [net->channels count] - 1;    
    [net_join_table selectRow:last byExtendingSelection:false];
    [net_join_table scrollRowToVisible:last];
	[net_join_table editColumn:0 row:last withEvent:NULL select:YES];
}

- (void) do_remove_channel:(id) sender
{
	[net_join_table abortEditing];

    int nrow = [net_list selectedRow];
    if (nrow < 0)
        return;

    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];

    int crow = [net_join_table selectedRow];
    if (crow < 0)
        return;

	[net->channels removeObjectAtIndex:crow];
	[net_join_table reloadData];
	
	[net resetAutojoin];
}

- (void) do_new_command:(id) sender
{
	int nrow = [net_list selectedRow];
    if (nrow < 0)
        return;
        
    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];

	[net->connect_commands addObject:NSLocalizedStringFromTable(@"NEW COMMAND", @"xchataqua", @"Default command: MainMenu->File->Server List... => (Select server)->On Join->commands->'+'")];
	
	[net_command_table reloadData];
	
	int last = [net->connect_commands count] - 1;    
    [net_command_table selectRow:last byExtendingSelection:false];
    [net_command_table scrollRowToVisible:last];
	[net_command_table editColumn:0 row:last withEvent:NULL select:YES];
}

- (void) do_remove_command:(id) sender
{
	[net_command_table abortEditing];

    int nrow = [net_list selectedRow];
    if (nrow < 0)
        return;

    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];

    int crow = [net_command_table selectedRow];
    if (crow < 0)
        return;

	[net->connect_commands removeObjectAtIndex:crow];
	[net_command_table reloadData];
	
	[net resetCommands];
}

- (void) do_remove_server:(id) sender
{
	[net_server_list abortEditing];

    int nrow = [net_list selectedRow];
    if (nrow < 0)
        return;

    int srow = [net_server_list selectedRow];
    if (srow < 0)
        return;
        
    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];
    
    if (g_slist_length (net->net->servlist) < 2)
        return;
                
    [net->servers removeObjectAtIndex:srow];
    
    ircserver *serv = (ircserver *) g_slist_nth (net->net->servlist, srow)->data;
    servlist_server_remove (net->net, serv);
    
    [net_server_list reloadData];
}

- (void) do_edit_server:(id) sender
{
    int sel = [net_server_list selectedRow];
	if (sel >= 0)
	{
		[net_server_list selectRow:sel byExtendingSelection:false];
		[net_server_list editColumn:0 row:sel withEvent:NULL select:YES];
	}
}

- (void) do_new_server:(id) sender
{
    int nrow = [net_list selectedRow];
    if (nrow < 0)
        return;

    int srow = [net_server_list selectedRow];
    if (srow < 0)
        return;
        
    oneNet *net = (oneNet *) [my_nets objectAtIndex:nrow];
	
    ircserver *svr = servlist_server_add (net->net, "NewServer");
    
    [net addServer:svr];
    [net_server_list reloadData];
    
    int last = [net->servers count] - 1;    
    [net_server_list selectRow:last byExtendingSelection:false];
    [net_server_list scrollRowToVisible:last];
	
	[self do_edit_server:sender];
}

- (void) do_new_network:(id) sender
{
    ircnet *net = servlist_net_add ((char*)XALocalizeString("New Network"), "", false);
    servlist_server_add (net, "NewServer");
    [my_nets addObject:[[oneNet alloc] initWithIrcnet:net]];
    [net_list reloadData];
   
    int last = [self numberOfRowsInTableView:net_list] - 1;
	[net_list selectRow:last byExtendingSelection:false];
    [net_list editColumn:2 row:last withEvent:NULL select:YES];
}

- (void) do_remove_network:(id) sender
{
	[net_list abortEditing];

    int row = [net_list selectedRow];
    if (row < 0)
        return;
    
    oneNet *net = (oneNet *) [my_nets objectAtIndex:row];

    if (![SGAlert confirmWithString:[NSString stringWithFormat:
		NSLocalizedStringFromTable(@"Really remove network \"%@\" and all its servers?", @"xchat", @"Dialog Message from clicking '-' of MainMenu->File->Server List..."), net->name]])
		return;
    
    servlist_net_remove (net->net);
    [my_nets removeObjectAtIndex:row];
    [net_list reloadData];
}

- (void) do_filter:(id) sender
{
	NSString *filter = [[sender stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	const char *cfilter = [filter UTF8String];
	
	[my_nets release];
	
	if (!cfilter || !cfilter[0])
	{
		my_nets = [all_nets retain];
	}
	else
	{
		my_nets = [[NSMutableArray arrayWithCapacity:0] retain];

		for (unsigned i = 0; i < [all_nets count]; i ++)
		{
			oneNet *net = [all_nets objectAtIndex:i];
			
			if (strcasestr (net->net->name, cfilter))
				[my_nets addObject:net];
		}
	}
    
    [net_list reloadData];
	
	// Simulate new selection
	[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"dummy" object:net_list]];
}

- (void) populate_nets
{
	[my_nets release];
	[all_nets release];
	
    all_nets = [[NSMutableArray arrayWithCapacity:0] retain];
	my_nets = [all_nets retain];

    for (GSList *list = network_list; list; list = list->next)
    {
        ircnet *net = (ircnet *) list->data;
		[my_nets addObject:[[oneNet alloc] initWithIrcnet:net]];
    }
    
    [net_list reloadData];
}

- (void) populate
{
    [nick1 setStringValue:[NSString stringWithUTF8String:prefs.nick1]];
    [nick2 setStringValue:[NSString stringWithUTF8String:prefs.nick2]];
    [nick3 setStringValue:[NSString stringWithUTF8String:prefs.nick3]];
    [realname setStringValue:[NSString stringWithUTF8String:prefs.realname]];
    [username setStringValue:[NSString stringWithUTF8String:prefs.username]];

    [skip_serverlist_button setIntValue:!prefs.slist_skip];
	
	[self populate_nets];
}    

- (void) make_charset_menu
{
    for (NSString **c = charsets; *c; c ++)
    {
        [charset_combo addItemWithObjectValue:*c];
    }
}

- (void) awakeFromNib
{
	// 10.3 doesn't support small square buttons.
	// This is the next best thing
	[SGGuiUtil fixSquareButtonsInView:[skip_serverlist_button superview]];
	[SGGuiUtil fixSquareButtonsInView:[net_nick superview]];
	[SGGuiUtil fixSquareButtonsInView:[[[net_join_table superview] superview] superview]];
	
	NSFont *font = [skip_serverlist_button font];
	NSArray *views = [[[net_list window] contentView] subviews];
	for (unsigned i = 0; i < [views count]; i ++)
	{
		NSView *view = [views objectAtIndex:i];
		if ([view isKindOfClass:[NSButton class]])
		{
			[(NSButton *) view setFont:font];
		}
	}
	
    for (int i = 0; i < [net_server_list numberOfColumns]; i ++)
    {
        id col = [[net_server_list tableColumns] objectAtIndex:i];
        [col setIdentifier:[NSNumber numberWithInt:i]];
    }

    for (int i = 0; i < [net_join_table numberOfColumns]; i ++)
    {
        id col = [[net_join_table tableColumns] objectAtIndex:i];
        [col setIdentifier:[NSNumber numberWithInt:i]];
    }

	NSTableColumn *fav_col = [[net_list tableColumns] objectAtIndex:0];
	NSTableHeaderCell *heart_cell = [fav_col headerCell];
	[heart_cell setImage:[NSImage imageNamed:@"heart.tif"]];

	NSTableColumn *conn_col = [[net_list tableColumns] objectAtIndex:1];
	NSTableHeaderCell *conn_cell = [conn_col headerCell];
	[conn_cell setImage:[NSImage imageNamed:@"connect.tif"]];
	
    [[nick1 window] setDelegate:self];
    
    [self->net_server_list setDataSource:self];
    [self->net_server_list setDelegate:self];

    [self->net_join_table setDataSource:self];
    [self->net_join_table setDelegate:self];

    [self->net_command_table setDataSource:self];
    [self->net_command_table setDelegate:self];
    
    [self->net_list setDataSource:self];
    [self->net_list setDelegate:self];
	[self->net_list setAutosaveTableColumns:YES];
    
	[net_auto setTag:FLAG_AUTO_CONNECT];
	[net_use_global setTag:~FLAG_USE_GLOBAL];
	[net_use_proxy setTag:~FLAG_USE_PROXY];
	[net_use_ssl setTag:FLAG_USE_SSL];
	[net_accept_invalid setTag:FLAG_ALLOW_INVALID];
	[net_connect_selected setTag:~FLAG_CYCLE];

	[net_nick setTag:STRUCT_OFFSET_STR(ircnet, nick)];
	[net_nick2 setTag:STRUCT_OFFSET_STR(ircnet, nick2)];
	[net_pass setTag:STRUCT_OFFSET_STR(ircnet, pass)];
	[net_real setTag:STRUCT_OFFSET_STR(ircnet, real)];
	[net_user setTag:STRUCT_OFFSET_STR(ircnet, user)];
	[net_nickserv_passwd setTag:STRUCT_OFFSET_STR(ircnet, nickserv)];
	[charset_combo setTag:STRUCT_OFFSET_STR(ircnet, encoding)];

    // We gotta do a reloadData in order to change the selection, but reload
    // data will call selectionDidChange and thus set prefs.slist_select.  We'll
    // save the value of prefs.slist_select now, and reset the selection after
    // the first reloadData.
    
    int slist_select = prefs.slist_select;
    
    [self make_charset_menu];
    [self populate];

	[my_nets sortUsingDescriptors:[net_list sortDescriptors]];
	[net_list reloadData];

    if (slist_select < [self numberOfRowsInTableView:net_list])
    {
        [net_list selectRow:slist_select byExtendingSelection:false];
        [net_list scrollRowToVisible:slist_select];
    }

    [[nick1 window] center];
}

//
// Table delegates
//

- (void) tableViewSelectionDidChange:(NSNotification *) notification
{
	int row = [self->net_list selectedRow];
	if (row < 0)
		return;
		
    if ([notification object] == net_list)
	{
		// Figure out what was selected from the all_nets
		id selected = [my_nets objectAtIndex:row];
		row = [all_nets indexOfObject:selected];
		prefs.slist_select = row;
		[self populate_editor];
	}
	else if ([notification object] == net_server_list)
	{
	    oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		net->net->selected = [net_server_list selectedRow];
	}
}

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    if (aTableView == net_list)
        return [my_nets count];
    
	if (aTableView == net_server_list)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return 0;
			
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		return [net->servers count];
	}
	
	if (aTableView == net_join_table)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return 0;
			
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		return [net->channels count];
	}
	
	if (aTableView == net_command_table)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return 0;
			
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		return [net->connect_commands count];
	}
	
	return 0;
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
	int col = [[aTableColumn identifier] intValue];
	
    if (aTableView == net_list)
	{
		oneNet *net =[my_nets objectAtIndex:rowIndex];
		
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
	else if (aTableView == net_server_list)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return @"";

		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		oneServer *svr = (oneServer *) [net->servers objectAtIndex:rowIndex];
		
		switch (col)
		{
			case 0: return svr->server;
			case 1: return svr->port;
			case 2: return [NSNumber numberWithBool:svr->ssl];
		}
	}
	else if (aTableView == net_join_table)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return @"";
			
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		oneChannel *chan = (oneChannel *) [net->channels objectAtIndex:rowIndex];
		
		switch (col)
		{
			case 0: return chan->chan;
			case 1: return chan->key;
		}
	}
	else if (aTableView == net_command_table)
	{
		int row = [self->net_list selectedRow];
		if (row < 0)
			return @"";
			
		oneNet *net = (oneNet *) [my_nets objectAtIndex:row];
		return [net->connect_commands objectAtIndex:rowIndex];
	}
    
    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(int)rowIndex
{
	int col = [[aTableColumn identifier] intValue];
	
    if (aTableView == net_list)
    {
		oneNet *net =[my_nets objectAtIndex:rowIndex];

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
    else if (aTableView == net_server_list)
    {
		if ([net_list selectedRow] < 0)
			return;

        oneNet *net = (oneNet *) [my_nets objectAtIndex:[net_list selectedRow]];
        oneServer *svr = (oneServer *) [net->servers objectAtIndex:rowIndex];
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
					[net_server_list reloadData];
                break;
			}
        }
    }
    else if (aTableView == net_join_table)
    {
		if ([net_list selectedRow] < 0)
			return;

        oneNet *net = (oneNet *) [my_nets objectAtIndex:[net_list selectedRow]];
		oneChannel *chan = (oneChannel *) [net->channels objectAtIndex:rowIndex];
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
    else if (aTableView == net_command_table)
    {
		if ([net_list selectedRow] < 0)
			return;

        oneNet *net = (oneNet *) [my_nets objectAtIndex:[net_list selectedRow]];
		[net->connect_commands replaceObjectAtIndex:rowIndex withObject:anObject];
		[net resetCommands];
    }
}

- (void) tableView:(NSTableView *) aTableView
	didClickTableColumn:(NSTableColumn *) aTableColumn
{
    if (aTableView == net_list)
	{
		NSArray *descs = [aTableView sortDescriptors];
		[my_nets sortUsingDescriptors:descs];
		[net_list reloadData];
		[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:net_list]];
	}
}

@end
