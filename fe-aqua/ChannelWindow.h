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

#import <regex.h>
#import "UtilityWindow.h"

@class ColorPalette;
@interface ChannelWindow : UtilityTabOrWindowView
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTableViewDataSource, NSTableViewDelegate>
#endif
{	
	IBOutlet NSTableView *channelTableView;
	IBOutlet NSTextField *captionTextField;
	IBOutlet NSButton *refreshButton;
	IBOutlet NSButton *saveButton;
	NSImage	*arrowImage;
	
	// search interfaces
	IBOutlet NSTextField *regexTextField;
	IBOutlet NSTextField *minTextField;
	IBOutlet NSTextField *maxTextField;
	IBOutlet NSButton *regexChannelButton;
	IBOutlet NSButton *regexTopicButton;
	
	// search temporary value
	NSInteger numberOfFoundUsers;
	NSInteger numberOfShownUsers;
	NSInteger filterMin;
	NSInteger filterMax;	
	BOOL channelChecked;
	BOOL topicChecked;

	NSMutableArray *allChannels, *filteredChannels;
	ColorPalette *colorPalette;
	BOOL added;
	regex_t matchRegex;
	BOOL regexValid;
	BOOL sortDirection[3];
	NSTimer *redrawTimer;
}

- (IBAction)applySearch:(id)sender;
- (IBAction)refreshList:(id)sender;
- (IBAction)saveAs:(id)sender;
- (IBAction)joinChannel:(id)sender;

- (void) addChannelWithName:(NSString *)channel numberOfUsers:(NSString *)users topic:(NSString *)topic;
- (void) refreshFinished;

@end
