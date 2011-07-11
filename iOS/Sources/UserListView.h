//
//  UserListView.h
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 19..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@interface UserListView : UIView<UITableViewDataSource, UITableViewDelegate> {
	NSMutableArray *users;
	struct session *session;
	
	IBOutlet UITableView *userListTableView;
	IBOutlet UILabel *statusLabel;
	IBOutlet UIImageView *myOpOrVoiceImageView;
}

@property (nonatomic, assign) struct session *session;

- (void) updateStatus;
- (void) rehashUser:(struct User *)user;
- (void) insertUser:(struct User *)user row:(NSInteger)row select:(BOOL)select;
- (BOOL) removeUser:(struct User *)user;
- (void) moveUser:(struct User *)user toRow:(NSInteger)row;
- (void) removeAllUsers;
- (void) userlistSelectNames:(char **)names clear:(int)clear scrollTo:(int)scroll_to;
- (void) updateUser:(struct User *)user;

@end
