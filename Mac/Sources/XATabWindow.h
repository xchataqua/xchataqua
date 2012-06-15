//
//  XATabWindow.h
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) youknowone.org All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SGTabView;

@interface XATabWindow : NSWindow

@property(nonatomic, readonly) SGTabView *tabView;

- (IBAction)performCloseTab:(id)sender;

+ (XATabWindow *)defaultTabWindow;

@end

@protocol XATabWindowDelegate<NSObject>

- (void)closeTab;

@end
