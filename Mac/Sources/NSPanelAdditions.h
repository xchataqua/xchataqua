//
//  NSPanel+XChatAqua.h
//  XChatAqua
//
//  Created by youknowone on 12. 6. 20..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSSavePanel (XChatAqua)

- (NSInteger)runModalForWindow:(NSWindow *)window;

@end

@interface NSOpenPanel (XChatAqua)

- (id)initCommonPanel;
+ (id)commonOpenPanel;

@end
