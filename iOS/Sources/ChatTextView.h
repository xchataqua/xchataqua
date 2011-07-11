//
//  ChatTextView.h
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

@interface UIControl (IpharyCocoa)
- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent *)event;
@end

@protocol UIControlTouchEvents
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@interface UIEventTextView : UITextView<UIControlTouchEvents> {
	UIControl *eventHandler;
	BOOL implementedZoomEnabled;
	CGFloat distance, oldscale;
	NSTimeInterval latestTimestamp;
	
	struct {
		unsigned int moved:1;
	} eventTextViewFlags;
}

@property(nonatomic, retain) IBOutlet UIControl *eventHandler;
@property(nonatomic, assign) BOOL implementedZoomEnabled;

@end

@class ChatViewController;
@interface ChatTextView : UIEventTextView {
	ChatViewController *viewController;
	int numberOfLines;
}

- (void)scrollToBottom:(BOOL)force;

- (void) printText:(NSString *)text stamp:(time_t)stamp;
- (void) clearText:(int)lines;

@end
