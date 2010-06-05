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
	IBOutlet NSComboBox		*charsetComboBox;
	IBOutlet NSButton		*connectNewButton;
	IBOutlet NSButton		*networkSelectedOnlyToggleButton;
	IBOutlet NSTableView 	*networkCommandTableView;
	IBOutlet NSTableView 	*networkJoinTableView;
	IBOutlet NSTableView 	*networkTableView;
	IBOutlet NSTextField 	*networkNicknameTextField;
	IBOutlet NSTextField 	*networkNickname2TextField;
	IBOutlet NSTextField	*networkNickservPasswordTextField;
	IBOutlet NSTextField 	*networkPasswordTextField;
	IBOutlet NSTextField 	*networkRealnameTextField;
	IBOutlet NSTableView 	*networkServerTableView;
	IBOutlet NSTextField	*networkTitleTextField;
	IBOutlet NSButton 		*networkUseCustomInformationToggleButton;
	IBOutlet NSButton 		*networkAutoConnectToggleButton;
	IBOutlet NSButton		*networkUseProxyToggleButton;
	IBOutlet NSButton 		*networkUseSslToggleButton;
	IBOutlet NSButton 		*networkAcceptInvalidCertificationToggleButton;
	IBOutlet NSTextField 	*networkUsernameTextField;
	IBOutlet NSTextField 	*nick1TextField;
	IBOutlet NSTextField 	*nick2TextField;
	IBOutlet NSTextField 	*nick3TextField;
	IBOutlet NSTextField 	*realnameTextField;
	IBOutlet NSButton		*showWhenStartupToggleButton;
	IBOutlet NSTextField 	*usernameTextField;
	IBOutlet NSButton		*showDetailButton;
	
	IBOutlet NSDrawer		*drawer;
	
    NSMutableArray	*allNetworks;
    NSMutableArray	*myNetworks;
    struct session	*servlistSession;
}

+ (void) showForSession:(session *) sess;

- (IBAction) doConnect:(id) sender;
- (IBAction) doSetFlag:(id) sender;
- (IBAction) doSetField:(id) sender;
- (IBAction) doDoneEdit:(id) sender;
- (IBAction) toggleShowWhenStartup:(id) sender;
- (IBAction) doClose:(id) sender;
- (IBAction) showDetail:(id) sender;
- (IBAction) doNewChannel:(id) sender;
- (IBAction) doRemoveChannel:(id) sender;
- (IBAction) doNewCommand:(id) sender;
- (IBAction) doRemoveCommand:(id) sender;
- (IBAction) doRemoveServer:(id) sender;
- (IBAction) doEditServer:(id) sender;
- (IBAction) doNewServer:(id) sender;
- (IBAction) doNewNetwork:(id) sender;
- (IBAction) doRemoveNetwork:(id) sender;
- (IBAction) doFilter:(id) sender;
- (IBAction) toggleCustomUserInformation:(id) sender;

@end
