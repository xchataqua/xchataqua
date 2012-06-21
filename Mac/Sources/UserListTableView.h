//
//  UserListTableView.h
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

@interface UserListTableView : NSTableView

@end

@interface UserlistButton : NSButton
{
    struct popup *popup;
}

@property (nonatomic, readonly) struct popup *popup;

- (id) initWithPopup:(struct popup *)popup;
+ (UserlistButton *)buttonWithPopup:(struct popup *)popup;

@end
