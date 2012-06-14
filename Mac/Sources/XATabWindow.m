//
//  XATabWindow.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) youknowone.org All rights reserved.
//

#import "XATabWindow.h"

@implementation XATabWindow

- (void) performCloseTab:(id)sender
{
    [(id<XATabWindowDelegate>)[self delegate] closeTab];
}

@end
