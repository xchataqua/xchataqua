//
//  XATabWindow.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) youknowone.org All rights reserved.
//

#import "XATabWindow.h"
#import "AquaChat.h"
#import "ColorPalette.h"

@implementation XATabWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    contentRect = NSMakeRect(prefs.hex_gui_win_left, prefs.hex_gui_win_top, prefs.hex_gui_win_width, prefs.hex_gui_win_height);
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self != nil) {
        // animation!
        NSRect to = self.frame;
        NSRect from = to;
        from.origin.y += from.size.height - 1;
        from.size.height = 1;
        [self setFrame:from display:NO];
        [self makeKeyAndOrderFront:self];
        [self setFrame:to display:YES animate:YES];
        [self makeKeyAndOrderFront:self];
    }
    return self;
}

- (XATabView *)tabView {
    return (id)self.contentView;
}

- (void) performClose:(id)sender
{
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        [(id<XATabWindowDelegate>)[self delegate] windowCloseTab:self];
    } else {
        [super performClose:sender];
    }
}

- (void)close {
    [NSApp terminate:self]; // this prevent parting!
}

- (void)applyPreferences:(id)sender {
    [self.tabView applyPreferences:sender];
}

@end
