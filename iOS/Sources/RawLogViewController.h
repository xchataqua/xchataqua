//
//  RawLogViewController.h
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 19..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import "UtilityViewController.h"

@interface RawLogViewController : UtilityViewController {
	IBOutlet UITextView *rawLogTextView;
}

- (void) printLog:(const char *)text length:(NSInteger)length outbound:(BOOL)outbound;

@end
