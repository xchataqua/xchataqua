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
	int				n_sub_expr;
	regmatch_t		*pmatch;
	NSMutableArray	*list;
	bool			ok;
}

+ (SGRegex *) regexWithString:(NSString *) regex nSubExpr:(int) nSubExpr;

- (bool) doitWithString:(NSString *) input;
- (bool) doitWithUTF8String:(const char *) input;
- (bool) doitWithCString:(const char *) input encoding:(NSStringEncoding) enc;
- (NSString *) getNthMatch:(int) n;

@end
