//
//  NSPanel+XChatAqua.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 20..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "NSPanelAdditions.h"

@implementation NSOpenPanel (XChatAqua)

- (id)initCommonPanel {
    self = [self init];
    if (self != nil ) {
        [self setCanChooseFiles:YES];
        [self setResolvesAliases:NO];
        [self setCanChooseDirectories:NO];
        [self setAllowsMultipleSelection:NO];
    }
    return self;
}

+ (id)commonOpenPanel {
    return [[[self alloc] initCommonPanel] autorelease];
}

@end
