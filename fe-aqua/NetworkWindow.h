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

#import "UtilityWindow.h"

@interface NetworkWindow : UtilityWindow
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTableViewDataSource,NSTableViewDelegate>
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
	
	IBOutlet NSDrawer		*detailDrawer;
	
	NSMutableArray *allNetworks, *filteredNetworks;
	struct session *servlistSession;
}

@property (nonatomic, retain) NSDrawer *detailDrawer;

- (void)showForSession:(struct session *) sess;

- (IBAction)showDetail:(id)sender;
- (IBAction)toggleShowWhenStartup:(id)sender;
- (IBAction)toggleCustomUserInformation:(id)sender;
- (IBAction)connectToSelectdNetwork:(id)sender;
- (IBAction)setFlagWithControl:(id)sender;
- (IBAction)setFieldWithControl:(id)sender;
- (IBAction)addChannel:(id)sender;
- (IBAction)removeChannel:(id)sender;
- (IBAction)addCommand:(id)sender;
- (IBAction)removeCommand:(id)sender;
- (IBAction)addServer:(id)sender;
- (IBAction)removeServer:(id)sender;
- (IBAction)addNetwork:(id)sender;
- (IBAction)removeNetwork:(id)sender;
- (IBAction)doFilter:(id)sender;

// not used
//- (IBAction)doDoneEdit:(id)sender;

@end
