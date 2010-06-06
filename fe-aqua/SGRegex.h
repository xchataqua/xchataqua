//
//  SGRegex.h
//  aquachat
//
//  Created by Steve Green on 3/29/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/types.h>
#include <regex.h>

@interface SGRegex : NSObject
{
	regex_t			preg;
	size_t			n_sub_expr;
	regmatch_t		*pmatch;
	NSMutableArray	*list;
	BOOL			ok;
}

+ (SGRegex *) regexWithString:(NSString *) regex nSubExpr:(int) nSubExpr;

- (BOOL) doitWithString:(NSString *) input;
- (BOOL) doitWithUTF8String:(const char *) input;
- (BOOL) doitWithCString:(const char *) input encoding:(NSStringEncoding) enc;
- (NSString *) getNthMatch:(NSInteger) n;

@end
