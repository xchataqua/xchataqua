//
//  ReleaseNotesWindow.m
//  aquachat
//
//  Created by libc on 31.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "ReleaseNotesWindow.h"


@implementation ReleaseNotesWindow

-(id) init
{
	if(self = [super init])
	{
		[NSBundle loadNibNamed:@"ReleaseNotes" owner:self];
	}
	
	return self;
}

-(void) awakeFromNib
{
	NSTextStorage * storage=[release_notes textStorage];
	NSString * relnotes;
	
	relnotes=[NSString stringWithContentsOfFile:
			  [[NSBundle mainBundle] pathForResource:@"Changes" ofType:nil]
			 ];
	
	[storage replaceCharactersInRange:NSMakeRange(0, [storage length])  withString:relnotes];
}

-(void) show
{
	[[self window] makeKeyAndOrderFront:self];
}

@end