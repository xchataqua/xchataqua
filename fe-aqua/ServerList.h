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

@interface ServerList : NSObject
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSWindowDelegate,NSTableViewDataSource,NSTableViewDelegate>
#endif
{
    NSComboBox		*charset_combo;
    NSButton		*connect_new_button;
    NSButton 		*net_accept_invalid;
    NSButton 		*net_auto;
    NSTableView 	*net_command_table;
	NSButton		*net_connect_selected;
    NSTableView 	*net_join_table;
    NSTableView 	*net_list;
    NSTextField 	*net_nick;
    NSTextField 	*net_nick2;
	NSTextField		*net_nickserv_passwd;
    NSTextField 	*net_pass;
    NSTextField 	*net_real;
    NSTableView 	*net_server_list;
	NSTextField		*net_title_text;
    NSButton 		*net_use_global;
    NSButton		*net_use_proxy;
    NSButton 		*net_use_ssl;
    NSTextField 	*net_user;
    NSTextField 	*nick1;
    NSTextField 	*nick2;
    NSTextField 	*nick3;
    NSTextField 	*realname;
    NSButton		*skip_serverlist_button;
    NSTextField 	*username;
	NSButton		*my_servers_check;
	NSButton		*show_details_button;
	
	NSDrawer		*drawer;
	
    NSMutableArray	*all_nets;
    NSMutableArray	*my_nets;
    struct session	*servlist_sess;
}

+ (void) show_for_session:(session *) sess;

//
- (void) do_drawer:(id) sender;

@end
