//
//  UtilityViewController.h
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 16..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@interface UtilityViewController : UIViewController {
	struct session *session;
	struct server *server;
	NSString *utilityKey;
	NSString *tabTitle;
}

@property (nonatomic, readonly) struct session *session;
@property (nonatomic, assign) struct server *server;
@property (nonatomic, readonly) NSInteger groupId;
@property (nonatomic, retain) NSString *tabTitle;

+ (UtilityViewController *)viewControllerWithNibName:(NSString *)nibName key:(NSString *)key forSession:(struct session *)session;
+ (UtilityViewController *)viewControllerByKey:(NSString *)key forSession:(struct session *)session; // if not exists, nil
// override +nibName
+ (NSString *)nibName;
+ (NSString *)mainKey;
+ (id)viewControllerForSession:(struct session *)session;
+ (id)viewControllerIfExistsForSession:(struct session *)session;

@end
