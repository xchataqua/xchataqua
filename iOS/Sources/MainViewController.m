//
//  MainViewController.m
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
#import "MainViewController.h"

@interface GroupInfo : NSObject
{
	NSInteger groupId;
	NSString *name;
	NSMutableArray *tabs;
}

@property (nonatomic, readonly) NSInteger groupId;
@property (nonatomic, retain) NSString *name;
@property (nonatomic, readonly) NSMutableArray *tabs;

- (id) initWithGroupId:(int)groupId;

@end

@implementation GroupInfo
@synthesize groupId, name, tabs;

- (id) initWithGroupId:(int)aGroupId {
	if ((self = [super init]) != nil) {
		self->groupId = aGroupId;
		self->tabs = [[NSMutableArray alloc] init];
		self->name = [@"" retain];
	}
	return self;
}

- (void) dealloc {
	[self->tabs release];
	[self->name release];
	[super dealloc];
}

@end


@implementation MainViewController
@synthesize contentView;

- (id) initMainViewController {
	groups = [[NSMutableArray alloc] init];
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	[self initMainViewController];
	return self;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	[self initMainViewController];
	return self;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return NO;
}

- (void) reloadData {
	while ( [[channelSwitcherScrollView subviews] count] > 0 ) {
		[[[channelSwitcherScrollView subviews] objectAtIndex:0] removeFromSuperview];
	}
	CGFloat width = 0;
	for (GroupInfo *group in groups) {
		NSMutableArray *items = [[NSMutableArray alloc] init];
		for (UtilityViewController *utiltiy in [group tabs]) {
			NSString *title = [utiltiy tabTitle];
			if ( title == nil ) title = @"";
			[items addObject:title];
		}
		UISegmentedControl *groupSegmentedControl = [[UISegmentedControl alloc] initWithItems:items];
		[groupSegmentedControl setSegmentedControlStyle:UISegmentedControlStyleBar];
		[groupSegmentedControl addTarget:self action:@selector(channelTabSelected:) forControlEvents:UIControlEventValueChanged];
		[groupSegmentedControl setTag:[group groupId]];
		
		for (NSInteger i = 0; i < [groupSegmentedControl numberOfSegments]; i++ ) {
			NSString *segmentTitle = [groupSegmentedControl titleForSegmentAtIndex:i];
			[groupSegmentedControl setWidth:[segmentTitle sizeWithFont:[UIFont systemFontOfSize:14.0f]].width forSegmentAtIndex:i];
			[groupSegmentedControl setContentOffset:CGSizeMake(0.0f, 0.0f) forSegmentAtIndex:i];
		}
		
		CGRect frame = groupSegmentedControl.frame;
		frame.origin.x = width;
		groupSegmentedControl.frame = frame;
		[channelSwitcherScrollView addSubview:groupSegmentedControl];
		width += groupSegmentedControl.frame.size.width;
		[groupSegmentedControl release];
		[items release];
	}
	channelSwitcherScrollView.contentSize = CGSizeMake(width, 0.0f);
}

- (void)channelTabSelected:(UISegmentedControl *)sender {
	GroupInfo *group = [self groupInfoForGroupId:[sender tag]];
	[self makeKeyView:[[group tabs] objectAtIndex:[sender selectedSegmentIndex]]];
}

- (void) addGroupItemForUtility:(UtilityViewController *)utilityViewController {
	GroupInfo *group = [self groupInfoForGroupId:[utilityViewController groupId]];

	[[group tabs] addObject:utilityViewController];
	
	[self reloadData];
}

- (void) removeGroupItemForUtility:(UtilityViewController *)utilityViewController {
	GroupInfo *group = [self groupInfoForGroupId:[utilityViewController groupId]];
	
	[[group tabs] removeObject:utilityViewController];
	
	[self reloadData];
}

- (GroupInfo *) groupInfoForGroupId:(int)groupId {
	GroupInfo *group = nil;
	for (GroupInfo *aGroup in groups) {
		if ([aGroup groupId] == groupId) {
			group = aGroup;
			break;
		}
	}
	if (group == nil) {
		group = [[GroupInfo alloc] initWithGroupId:groupId];
		[groups addObject:group];
		[group release];
	}
	return group;
}

#pragma mark fe-aqua

- (void) makeKeyView:(UtilityViewController *)utilityViewController {
	while ( [[contentView subviews] count] > 0 )
		[[[contentView subviews] objectAtIndex:0] removeFromSuperview];
	[utilityViewController viewWillAppear:NO];
	utilityViewController.view.frame = contentView.bounds;
	[self.navigationItem setPrompt:utilityViewController.title];
	[contentView addSubview:utilityViewController.view];
	[utilityViewController viewDidAppear:NO];
}
	 
@end
