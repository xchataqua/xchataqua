//
//  RawLogViewController.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 19..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RawLogViewController.h"

@implementation RawLogViewController

- (void) printLog:(const char *)text length:(NSInteger)length outbound:(BOOL)outbound {
	if(text[length-1]=='\n')
		length -= 1;
	
	NSString *s = [[NSString alloc] initWithBytes:text length:length encoding:NSUTF8StringEncoding];
	rawLogTextView.text = [rawLogTextView.text stringByAppendingFormat:@"%c %@\n", outbound ? '>' : '<', s];
	[s release];
	
	CGFloat scrollPoint = rawLogTextView.contentSize.height - rawLogTextView.frame.size.height;
	if ( scrollPoint > 0.0f ) {
		[rawLogTextView setContentOffset:CGPointMake(0.0f, scrollPoint)];
	}
}

@end
