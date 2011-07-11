//
//  ChatViewController.h
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

#import "UtilityViewController.h"

@class ChatTextView;
@class UserListView;
@interface ChatViewController : UtilityViewController<UITextFieldDelegate, UIScrollViewDelegate> {
	UIColor *tabTitleColor;
	
	IBOutlet ChatTextView *chatTextView;
	IBOutlet UserListView *userListView;
	
	IBOutlet UIView *interactionView;
	IBOutlet UILabel *nicknameLabel;
	IBOutlet UITextField *inputTextField;
	IBOutlet UIProgressView *throttleProgressView, *lagProgressView;
	IBOutlet UIButton *historyUpButton, *historyDownButton;

	IBOutlet id adViewController;
	IBOutlet UIView *bannerView;
}

@property (nonatomic, retain) id adViewController;
@property (nonatomic, retain) NSString *inputText;
@property (nonatomic, readonly) NSInteger inputTextPosition;

- (IBAction) historyUp;
- (IBAction) historyDown;
- (IBAction) toggleUserView;

- (void) setNickname:(NSString *)nickname;
- (void) printText:(NSString *)text stamp:(time_t)stamp;
- (void) clearText:(int)lines;
- (void) setTabColor:(int)color flash:(BOOL)flash;

- (void) setChannel;
- (void) setNonchannel;
- (void) setTitleBySession;
- (void) setThrottle;
- (void) setLag:(NSNumber *)percent;

@end
