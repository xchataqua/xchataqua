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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/modes.h"
#include "../common/util.h"

#import "AquaChat.h"
#import "ChatWindow.h"
#import "AsciiWin.h"

//////////////////////////////////////////////////////////////////////

@implementation AsciiWin

- (id) initWithSelfPtr:(id *) self_ptr
{
    [super initWithSelfPtr:self_ptr];
    
	#define AWBWidth  30.0f
	#define AWBHeight 30.0f
	#define AWLWidth  30.0f
	#define AWMargin  20.0f
	#define AWColCount 16

    NSRect wr = NSMakeRect (0.0f, 0.0f,
							AWColCount * AWBWidth + AWMargin + AWMargin + AWLWidth,
							AWColCount * AWBHeight + AWMargin + AWMargin);

    NSView *asciiView = [[[NSView alloc] initWithFrame:wr] autorelease];
    
    for (NSInteger y = 0; y < AWColCount; y ++)
    {
        NSTextField *lineTextField = [[[NSTextField alloc] init] autorelease];
        [lineTextField setEditable:NO];
        [lineTextField setBezeled:NO];
        [lineTextField setBordered:NO];
        [lineTextField setDrawsBackground:NO];
        [lineTextField setAlignment:NSRightTextAlignment];
        [lineTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%3.3d", y * AWColCount]];
        [lineTextField sizeToFit];
        
        NSRect lineRect = [lineTextField frame];
        [lineTextField setFrameOrigin:NSMakePoint (AWMargin + AWLWidth - lineRect.size.width - 5.0f, 
												   wr.size.height - AWMargin - y * AWBHeight - AWBHeight + (AWBHeight - lineRect.size.height) / 2)];

        [asciiView addSubview:lineTextField];
            
        for (NSInteger x = 0; x < AWColCount; x ++)
        {
			unsigned char character = y * AWColCount + x;
            
            NSButton *characterButton = [[[NSButton alloc] init] autorelease];
            [characterButton setButtonType:NSMomentaryPushButton];
            [characterButton setTitle:[NSString stringWithFormat:@"%c", character]];
            [characterButton setBezelStyle:NSShadowlessSquareBezelStyle];
            [characterButton setAction:@selector(onInput:)];
            [characterButton setTarget:self];
            [characterButton setTag:character];
            [characterButton setImagePosition:NSNoImage];
        
            NSRect characterRect = NSMakeRect (AWMargin + AWLWidth + x * AWBWidth, 
											   wr.size.height - AWMargin - y * AWBHeight - AWBHeight, AWBWidth, AWBHeight);
                
            [characterButton setFrame:characterRect];
    
            [asciiView addSubview:characterButton];
            
            if (character == 255)
                break;
        }
    }
    
    window = [[NSWindow alloc] initWithContentRect:[asciiView frame]
                                styleMask: NSTitledWindowMask | 
                                           NSClosableWindowMask | 
                                           NSMiniaturizableWindowMask
                                   backing:NSBackingStoreBuffered
                                     defer:NO];

    [window setReleasedWhenClosed:NO];
    [window setContentView:asciiView];
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

- (void) onInput:(id) sender
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
