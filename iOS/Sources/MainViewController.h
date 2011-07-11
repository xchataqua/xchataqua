//
//  MainViewController.h
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

@class GroupInfo;
@class UtilityViewController;
@interface MainViewController : UIViewController {
	NSMutableArray *groups;
	
	IBOutlet UIScrollView *channelSwitcherScrollView;
	IBOutlet UIView *contentView;
}

@property (nonatomic, retain) UIView *contentView;

- (void)reloadData;
- (void)channelTabSelected:(UISegmentedControl *)sender;
- (void)addGroupItemForUtility:(UtilityViewController *)utilityViewController;
- (void)removeGroupItemForUtility:(UtilityViewController *)utilityViewController;
- (GroupInfo *)groupInfoForGroupId:(int)groupId;
- (void)makeKeyView:(UtilityViewController *)utilityViewController;

@end
