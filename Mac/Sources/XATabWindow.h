//
//  XATabWindow.h
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) youknowone.org All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XATabWindow : NSWindow

- (IBAction)performCloseTab:(id)sender;

@end

@protocol XATabWindowDelegate<NSObject>

- (void)closeTab;

@end
