//
//  XATabWindow.h
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) youknowone.org All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XATabView;

@interface XATabWindow : NSWindow<XAEventChain>

@property(nonatomic, readonly) XATabView *tabView;

@end

@protocol XATabWindowDelegate<NSObject>

- (void)windowCloseTab:(XATabWindow *)window;

@end
