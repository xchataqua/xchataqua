//
//  ChatTextView.m
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

#import "mIRCString.h"
#import "AppDelegate.h"
#import "ChatTextView.h"

#define ICLog(...)

@implementation UIControl (IpharyCocoa)

- (void)sendActionsForControlEvents:(UIControlEvents)controlEvents withEvent:(UIEvent *)event {
	NSArray *targets = [[self allTargets] allObjects];
	for ( NSUInteger i=0; i < [targets count]; i++ ) {
		NSArray *actions = [self actionsForTarget:[targets objectAtIndex:i] forControlEvent:controlEvents];
		for ( NSUInteger j=0; j < [actions count]; j++ ) {
			[self sendAction:NSSelectorFromString([actions objectAtIndex:j]) to:[targets objectAtIndex:i] forEvent:event];
		}
	}
}

@end


@implementation UIEventTextView
@synthesize eventHandler, implementedZoomEnabled;

- (void)dealloc {
	self.eventHandler = nil;
	[super dealloc];
}

#pragma mark -
#pragma mark control interface

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ( implementedZoomEnabled )
		if ( [[event allTouches] count] == 2 ) {
			NSArray *allTouches = [[event allTouches] allObjects];
			UITouch *t1 = [allTouches objectAtIndex:0];
			UITouch *t2 = [allTouches objectAtIndex:1];
			distance = (CGFloat)sqrt(pow([t1 locationInView:self].x, 2.0) + pow([t2 locationInView:self].y, 2.0));
			oldscale = self.zoomScale;
		}
	
	ICLog(ICSCROLL_DEBUG, @"touches begin");
	eventTextViewFlags.moved = NO;
	[eventHandler sendActionsForControlEvents:UIControlEventTouchDown withEvent:event];
	[super touchesEnded: touches withEvent: event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ( implementedZoomEnabled && [[event allTouches] count] == 2 ) {
		if ( distance == 0.0f ) {
			[self touchesBegan:touches withEvent:event];
			return;
		}
		NSArray *allTouches = [[event allTouches] allObjects];
		UITouch *t1 = [allTouches objectAtIndex:0];
		UITouch *t2 = [allTouches objectAtIndex:1];
		CGFloat newdistance = (CGFloat)sqrt(pow([t1 locationInView:self].x, 2.0) + pow([t2 locationInView:self].y, 2.0));
		float newScale = oldscale*(newdistance/distance);
		ICLog(ICSCROLL_DEBUG, @"oldscale, newscale, dist, newdist, newscale: %f, %f, %f, %f, %f", oldscale, newScale, distance, newdistance, newScale);
		[self setZoomScale:newScale animated:NO];
	}	
	ICLog(ICSCROLL_DEBUG, @"touches move");
	eventTextViewFlags.moved = YES;
	[eventHandler sendActionsForControlEvents:UIControlEventTouchDragEnter withEvent:event];
	[super touchesEnded: touches withEvent: event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	distance = 0.0f;
	ICLog(ICSCROLL_DEBUG, @"touches end");
	if ( eventTextViewFlags.moved ) {
		[eventHandler sendActionsForControlEvents:UIControlEventTouchDragExit withEvent:event];
		[eventHandler sendActionsForControlEvents:UIControlEventTouchDragInside withEvent:event];
	}
	else {
		[eventHandler sendActionsForControlEvents:UIControlEventTouchUpInside withEvent:event];
	}
	if (event.timestamp - latestTimestamp < 0.4) {
		[eventHandler sendActionsForControlEvents:UIControlEventTouchDownRepeat withEvent:event];
	}
	latestTimestamp = event.timestamp;
	[super touchesEnded: touches withEvent: event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	ICLog(ICSCROLL_DEBUG, @"touches cancel");
	if ( eventTextViewFlags.moved ) {
		[eventHandler sendActionsForControlEvents:UIControlEventTouchDragExit];
	}
	[eventHandler sendActionsForControlEvents:UIControlEventTouchCancel withEvent:event];
	[super touchesEnded: touches withEvent: event];
}

@end

@implementation ChatTextView

- (void) scrollToBottom:(BOOL)force {
	// TODO: force check
	
	CGFloat scrollPosition = self.contentSize.height-self.frame.size.height;
	if ( scrollPosition > 0 ) {
		[self setContentOffset:CGPointMake(0.0f, scrollPosition) animated:YES];
	}	
}

- (void) printText:(NSString *)text stamp:(time_t)stamp {
	mIRCString *mstring = [mIRCString stringWithUTF8String:CSTR(text) length:[text lengthOfBytesUsingEncoding:NSUTF8StringEncoding] palette:[ApplicationDelegate colorPalette] font:[UIFont systemFontOfSize:10.0f] boldFont:[UIFont systemFontOfSize:10.0f]];
	NSString *stripedText = [mstring string];
	if ( stripedText == nil ) {
		// legacy support
		stripedText = text;
	}
	self.text = [self.text stringByAppendingString:stripedText];
	numberOfLines = [[self.text componentsSeparatedByString:@"\n"] count];
}

- (void) clearText:(int)lines {
	self.text = @"";
	numberOfLines = 0;
}

@end
