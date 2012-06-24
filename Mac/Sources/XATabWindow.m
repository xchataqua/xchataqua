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

XATabWindow *XATabWindowDefaultWindow;

@implementation XATabWindow

+ (void)initialize {
    if (self == [XATabWindow class]) {
        NSWindowController *controller = [[NSWindowController alloc] initWithWindowNibName:@"ChatWindow"];
        XATabWindowDefaultWindow = (id)controller.window;
    }
}

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    contentRect = NSMakeRect(prefs.mainwindow_left, prefs.mainwindow_top, prefs.mainwindow_width, prefs.mainwindow_height);
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

- (SGTabView *)tabView {
    return (id)self->_contentView;
}

- (void) performClose:(id)sender
{
    if ([sender class] == [NSMenuItem class]) {
        [(id<XATabWindowDelegate>)[self delegate] closeTab];
    } else {
        [super performClose:sender];
    }
}

+ (XATabWindow *)defaultTabWindow {
    return XATabWindowDefaultWindow;
}

- (void)preferencesChanged {
    if (prefs.style_inputbox) {
        if (prefs.tab_layout == 2) {
            self.backgroundColor = [[[AquaChat sharedAquaChat] palette] getColor:XAColorBackground];
        } else {
            self.backgroundColor = nil;
        }
    } else {
        self.backgroundColor = nil;
    }
    
    [self.tabView preferencesChanged];
}

@end
