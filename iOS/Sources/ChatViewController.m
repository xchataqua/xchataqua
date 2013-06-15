//
//  ChatViewController.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 17..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
/*
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

#include "outbound.h"

#include "fe-iphone_common.h"

#import "AppDelegate.h"
#import "ColorPalette.h"
#import "ChatViewController.h"
#import "ChatTextView.h"
#import "UserListView.h"

@implementation ChatViewController
@synthesize adViewController;

+ (NSString *) nibName {
	return @"ChatViewController";
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self->session->gui->userListView = userListView;
	[userListView setSession:self->session];
	
	// [ChatWindow -awakeFromNib]
	[self clearText:0];
	if (self->server)
		[self setNickname:@(self->server->nick)];
	[self setTitleBySession];
	//[self setNonchannel];

	if ([self session]->type == SESS_DIALOG) {
		[self setChannel];
	} else {
		[self setTabTitle:XCHATLSTR(@"<none>")];
	}
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[bannerView addSubview:[AppDelegate sharedBannerView]];
	[[AppDelegate sharedAdViewController] setCurrentViewController:self];
}

#pragma mark fe-aqua

- (void) historyUp {
	char *history = history_up(&[self session]->history, (char *)CSTR([inputTextField text]));
	if ( history )
		[self setInputText:@(history)];
}

- (void) historyDown {
	char *history = history_down(&[self session]->history);
	[self setInputText:history ? @(history) : @""];
}

- (void) toggleUserView {
	if ( [inputTextField isEditing] ) {
		[inputTextField endEditing:YES];
		return;
	}
	userListView.hidden = !userListView.hidden;
}

- (void) printText:(NSString *)text stamp:(time_t)stamp {
	[chatTextView printText:text stamp:stamp];
	[chatTextView scrollToBottom:NO];

	if (![self session]->new_data && [self session] != current_tab && ![self session]->nick_said)
	{
		if ([self session]->msg_said)	// Channel message
			[self setTabColor:2 flash:NO];
		else				// Server message?  Not sure..?
			[self setTabColor:1 flash:NO];
	}
}

- (void) clearText:(int)lines {
	[chatTextView clearText:lines];
}

- (void) setTabColor:(int)color flash:(BOOL)flash {
	ColorPalette *p = [ApplicationDelegate colorPalette];
	
	if (prefs._tabs_position == 4 && prefs.style_inputbox) {
		tabTitleColor = [p getColor:AC_FGCOLOR];
	} else {
		tabTitleColor = [UIColor blackColor];
	}
	struct session *sess = [self session];
	
	if (color == 0 || sess != current_tab)
	{
		switch (color)
		{
			case 0: /* no particular color (theme default) */
				sess->new_data = false;
				sess->msg_said = false;
				sess->nick_said = false;
				break;
				
			case 1: /* new data has been displayed (dark red) */
				sess->new_data = true;
				sess->msg_said = false;
				sess->nick_said = false;
				tabTitleColor = [p getColor:AC_NEW_DATA];
				break;
				
			case 2: /* new message arrived in channel (light red) */
				sess->new_data = false;
				sess->msg_said = true;
				sess->nick_said = false;
				tabTitleColor = [p getColor:AC_MSG_SAID];
				break;
				
			case 3: /* your nick has been seen (blue) */
				sess->new_data = false;
				sess->msg_said = false;
				sess->nick_said = true;
				tabTitleColor = [p getColor:AC_NICK_SAID];
				break;
		}
	}
	[[ApplicationDelegate mainViewController] reloadData];
	NSLog(@"set tab color: %d", color);
}

- (void) setNickname:(NSString *)nickname {
	[nicknameLabel setText:nickname];
	[nicknameLabel sizeToFit];
}

- (void) setChannel {
	NSMutableString *channelString = [NSMutableString stringWithUTF8String:[self session]->channel];
	
	if (prefs.truncchans && [channelString length] > prefs.truncchans)
	{
		NSUInteger start = prefs.truncchans - 2;
		NSUInteger len = [channelString length] - start;
		[channelString replaceCharactersInRange:NSMakeRange (start, len) withString:@".."];
	}
	[self setTabTitle:channelString];
	//[chatView setTabTitle:channelString];
	//if (prefs._tabs_position == 4 && prefs.style_inputbox) {
	//	ColorPalette *p = [[AquaChat sharedAquaChat] palette];
	//	[chatView setTabTitleColor:[p getColor:AC_FGCOLOR]];
	//}
}

- (void) setNonchannel {
	/*
	[tButton setEnabled:state];
	[nButton setEnabled:state];
	[sButton setEnabled:state];
	[iButton setEnabled:state];
	[pButton setEnabled:state];
	[mButton setEnabled:state];
	[bButton setEnabled:state];
	[lButton setEnabled:state];
	[kButton setEnabled:state];
	[CButton setEnabled:state];
	[NButton setEnabled:state];
	[uButton setEnabled:state];
	[limitTextField setEnabled:state];
	[keyTextField setEnabled:state];
	[topicTextField setEditable:state];
	*/
}

- (void) setTitleBySession {
	int type = [self session]->type;
	
	NSString *chan = @([self session]->channel);
	
	NSString *title;
	switch (type)
	{
		case SESS_DIALOG:
			title = [NSString stringWithFormat:@"%@ %@",
					 NSLocalizedStringFromTable(@"Dialog with", @"xchat", @""),
					 [NSString stringWithFormat:@"%@ @ %s", chan, [self session]->server->servername]];
			break;
			
		case SESS_CHANNEL:
			if ([self session]->channel[0])
			{
				title = [NSString stringWithFormat:@"%s / %@", [self session]->server->servername, chan];
				break;
			}
			// else fall through
			
		case SESS_SERVER:
		case SESS_NOTICES:
		case SESS_SNOTICES:
			if ([self session]->server->servername [0])
			{
				title = [NSString stringWithFormat:@"%s", [self session]->server->servername];
				break;
			}
			// else fall through
			
		default:
			title = [NSString stringWithFormat:@"X-Chat [%s/%s]", XCHAT_AQUA_VERSION_STRING, PACKAGE_VERSION];
	}

	[self setTitle:title];
}

- (void) setThrottle {	
	float percent = [self session]->server->sendq_len / 1024.0f;
	if (percent > 1.0) percent = 1.0;
	
	[throttleProgressView setProgress:percent];
}

- (void) setLag:(NSNumber *)percent {
	[lagProgressView setProgress:[percent floatValue]];
}

#pragma mark fe-aqua properties

- (NSString *) inputText {
	return [inputTextField text];
}

- (void) setInputText:(NSString *)text {
	if ( text == nil ) return;
	[inputTextField setText:text];
}

- (NSInteger) inputTextPosition {
	// FIXME: there may be no way?
	return [[inputTextField text] length];
}

#pragma mark UITextField delegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
	NSString *message = [textField text];
	if ( [message length] == 0 ) {
		[textField endEditing:YES];
		return NO;
	}
	
	[inputTextField setText:@""];
	
	handle_multiline([self session], (char *)CSTR(message), TRUE, FALSE);

	[textField endEditing:YES];	
	return YES;
}

#define keyboardHeight (220.0f-48.0f)

- (void) textFieldDidBeginEditing:(UITextField *)textField {
	[UIView beginAnimations:@"keyboard" context:NULL];
	[UIView setAnimationDuration:0.3];
	
	CGRect chatTextFrame = chatTextView.frame;
	chatTextFrame.origin.y -= keyboardHeight;
	chatTextView.frame = chatTextFrame;
	/*
	CGRect interactionFrame = interactionView.frame;
	interactionFrame.origin.y -= keyboardHeight;
	interactionView.frame = interactionFrame;
	*/
	historyUpButton.hidden = NO;
	historyDownButton.hidden = NO;
	nicknameLabel.hidden = YES;
	
	[UIView commitAnimations];
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
	[UIView beginAnimations:@"keyboard" context:NULL];
	[UIView setAnimationDuration:0.3];
	CGRect chatTextFrame = chatTextView.frame;
	chatTextFrame.origin.y += keyboardHeight;
	chatTextView.frame = chatTextFrame;
	/*
	CGRect interactionFrame = interactionView.frame;
	interactionFrame.origin.y += keyboardHeight;
	interactionView.frame = interactionFrame;
	*/
	historyUpButton.hidden = YES;
	historyDownButton.hidden = YES;
	nicknameLabel.hidden = NO;
	
	[UIView commitAnimations];
}

#undef keyboardHeight

#pragma mark UIScrollView delegate
/*
- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
	[inputTextField endEditing:YES];
}
*/
@end
