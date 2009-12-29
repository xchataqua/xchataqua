/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/modes.h"
#include "../common/util.h"
}

#import "AquaChat.h"
#import "ChatWindow.h"
#import "AsciiWin.h"

//////////////////////////////////////////////////////////////////////

@implementation AsciiWin

- (id) initWithSelfPtr:(id *) self_ptr
{
    [super initWithSelfPtr:self_ptr];
    
#define AWBWidth 30
#define AWBHeight 30
#define AWLWidth 30
#define AWMargin 20

    NSRect wr = NSMakeRect (0, 0, 16 * AWBWidth + AWMargin + AWMargin + AWLWidth,
                                  16 * AWBHeight + AWMargin + AWMargin);

    NSView *v = [[[NSView alloc] initWithFrame:wr] autorelease];
    
    for (int y = 0; y < 16; y ++)
    {
        NSTextField *l = [[[NSTextField alloc] init] autorelease];
        [l setEditable:false];
        [l setBezeled:false];
        [l setBordered:false];
        [l setDrawsBackground:false];
        [l setAlignment:NSRightTextAlignment];
        [l setTitleWithMnemonic:[NSString stringWithFormat:@"%3.3d", y * 16]];
        [l sizeToFit];
        
        NSRect r = [l frame];
        NSPoint p = NSMakePoint (AWMargin + AWLWidth - r.size.width - 5, 
            wr.size.height - AWMargin - y * AWBHeight - AWBHeight + (AWBHeight - r.size.height) / 2);
        [l setFrameOrigin:p];

        [v addSubview:l];
            
        for (int x = 0; x < 16; x ++)
        {
			unsigned char c = y * 16 + x;
            
            NSButton *b = [[[NSButton alloc] init] autorelease];
            [b setButtonType:NSMomentaryPushButton];
            [b setTitle:[NSString stringWithFormat:@"%c", c]];
            [b setBezelStyle:NSShadowlessSquareBezelStyle];
            [b setAction:@selector (do_button:)];
            [b setTarget:self];
            [b setTag:c];
            [b setImagePosition:NSNoImage];
        
            NSRect r = NSMakeRect (AWMargin + AWLWidth + x * AWBWidth, 
                wr.size.height - AWMargin - y * AWBHeight - AWBHeight, AWBWidth, AWBHeight);
                
            [b setFrame:r];
    
            [v addSubview:b];
            
            if (c == 255)
                break;
        }
    }
    
    window = [[NSWindow alloc] initWithContentRect:[v frame]
                                styleMask: NSTitledWindowMask | 
                                           NSClosableWindowMask | 
                                           NSMiniaturizableWindowMask
                                   backing:NSBackingStoreBuffered
                                     defer:NO];

    [window setReleasedWhenClosed:false];
    [window setContentView:v];
    [window setDelegate:self];
    [window setTitle:NSLocalizedStringFromTable(@"Character Chart", @"xchat", @"")];
    [window center];

    return self;
}

- (void) dealloc
{
    [window autorelease];
    [super dealloc];
}

- (void) do_button:(id) sender
{
    if (current_sess)
        [current_sess->gui->cw insertText:[sender title]];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self release];
}

- (void) show
{
    [window makeKeyAndOrderFront:self];
}

@end
