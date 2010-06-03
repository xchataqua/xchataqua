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

#import <Cocoa/Cocoa.h>
#import "TabOrWindowView.h"
#import "ColorPalette.h"
#import <regex.h>

@interface ChannelListWin : NSObject
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTableViewDataSource,NSTableViewDelegate>
#endif
{    
	IBOutlet TabOrWindowView	*channelListView;
	IBOutlet NSButton			*refreshButton;
	IBOutlet NSButton			*applyButton;
	IBOutlet NSButton			*saveButton;
	IBOutlet NSTableView		*itemTableView;
	IBOutlet NSTextField		*captionTextField;
	IBOutlet NSTextField		*regexTextField;
	IBOutlet NSTextField		*minTextField;
	IBOutlet NSTextField		*maxTextField;
	IBOutlet NSButton			*regexChannelButton;
	IBOutlet NSButton			*regexTopicButton;
	
	struct server	*serv;
	NSMutableArray	*allItems;
	NSMutableArray	*items;
	NSTimer			*timer;
	BOOL			added;
	NSInteger		numberOfFoundUsers;
	NSInteger		numberOfShownUsers;
	BOOL			topicChecked;
	BOOL			channelChecked;
	NSInteger		filterMin;
	NSInteger		filterMax;
	regex_t			matchRegex;
	BOOL			regexValid;
	NSImage			*arrow;
	BOOL			sortDir [3];
	ColorPalette	*colorPalette;
}

- (IBAction) doApply:(id)sender;
- (IBAction) doRefresh:(id)sender;
- (IBAction) doSave:(id)sender;
- (IBAction) doJoin:(id)sender;

- (id) initWithServer:(struct server *)server;
- (void) show;
- (void) addChannelList:(NSString *)chan numberOfUsers:(NSString *)users topic:(NSString *)topic;
- (void) chanListEnd;

@end
