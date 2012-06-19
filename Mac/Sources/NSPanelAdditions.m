//
//  NSPanel+XChatAqua.m
//  XChatAqua
//
//  Created by youknowone on 12. 6. 20..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "NSPanelAdditions.h"
#import "SystemVersion.h"

@implementation NSSavePanel (XChatAqua)

- (NSInteger)runModalForWindow:(NSWindow *)window {
    NSInteger status;
    
    if ([SystemVersion minor] > 5) { // >= snow leopard
        [self beginSheetModalForWindow:window completionHandler:NULL];
        status = [self runModal];
        [NSApp endSheet:self];
    } else {
        // ignore deprecated warning. this is legacy support runtime code.
        if ([self isKindOfClass:[NSOpenPanel class]]) {
            [(NSOpenPanel *)self beginSheetForDirectory:self.directory file:nil types:nil modalForWindow:window
                           modalDelegate:nil didEndSelector:nil contextInfo:nil];
        } else {
            [self beginSheetForDirectory:nil file:nil modalForWindow:window
                           modalDelegate:nil didEndSelector:nil contextInfo:nil];
        }
        
        status = [NSApp runModalForWindow:self];
        [NSApp endSheet:self];
        [self orderOut:self];
    }
    return status;
}

@end

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
