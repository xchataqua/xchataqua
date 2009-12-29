//
//  SGTokenizer.h
//  aquachat
//
//  Created by Steve Green on 7/2/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface SGTokenizer : NSObject
{
	NSString		*tmp;
	int				ptr;
}

- (id) initWithString:(NSString *) stringToTokenize;
- (void) setString:(NSString *) stringToTokenize;
- (NSString *) getNextToken:(const char *) delimit;
- (NSString *) remainder;

@end