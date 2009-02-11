//
//  SGLeopardPalette.m
//  aquachat
//
//  Created by libc on 30.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "SGLeopardPalette.h"


@implementation SGLeopardPalette
- (NSArray *)libraryNibNames {
    return [NSArray arrayWithObject:@"SGPaletteLeopard"];
}

-(NSString *)label {
	return @"SGPalette";
}
@end
