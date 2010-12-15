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
#include "fe-aqua_common.h"

#import "ChatWindow.h"
#import "AsciiWindow.h"

@interface AsciiWindow (private)

- (void) inputCharacter:(id)sender;

@end

#pragma mark -

@implementation AsciiWindow

- (id) init {
	#define AWButtonWidth  30.0f
	#define AWButtonHeight 30.0f
	#define AWLabelWidth   30.0f
	#define AWMargin	   20.0f
	#define AWNumberOfColumns 16

	NSRect windowRect = NSMakeRect (0.0f, 0.0f,
								   AWNumberOfColumns * AWButtonWidth + AWMargin + AWMargin + AWLabelWidth,
								   AWNumberOfColumns * AWButtonHeight+ AWMargin + AWMargin);

	self = [super initWithContentRect:windowRect 
							styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
							  backing:NSBackingStoreBuffered
								defer:NO];
	
	if ( self != nil ) {
		NSView *asciiView = [[NSView alloc] initWithFrame:windowRect];
	
		for (NSInteger y = 0; y < AWNumberOfColumns; y ++)
		{
			NSTextField *lineTextField = [[NSTextField alloc] init];
			[lineTextField setEditable:NO];
			[lineTextField setBezeled:NO];
			[lineTextField setBordered:NO];
			[lineTextField setDrawsBackground:NO];
			[lineTextField setAlignment:NSRightTextAlignment];
			[lineTextField setTitleWithMnemonic:[NSString stringWithFormat:@"%03d", y * AWNumberOfColumns]];
			[lineTextField sizeToFit];
			NSRect lineFrame = [lineTextField frame];
			NSPoint lineOrigin = NSMakePoint (AWMargin + AWLabelWidth - lineFrame.size.width - 5.0f, 
											  AWMargin + y * AWButtonHeight + (AWButtonHeight - lineFrame.size.height) / 2);
			[lineTextField setFrameOrigin:lineOrigin];
			[asciiView addSubview:lineTextField];
			[lineTextField release];
			
			for (NSInteger x = 0; x < AWNumberOfColumns; x ++)
			{
				unichar character = y * AWNumberOfColumns + x;
				
				NSRect buttonRect = NSMakeRect (AWMargin + AWLabelWidth + x * AWButtonWidth, AWMargin + y * AWButtonHeight, AWButtonWidth, AWButtonHeight);
				NSButton *characterButton = [[NSButton alloc] initWithFrame:buttonRect];
				[characterButton setBezelStyle:NSShadowlessSquareBezelStyle];
				[characterButton setButtonType:NSMomentaryPushInButton];
				[characterButton setTitle:[NSString stringWithFormat:@"%c", character]];
				[characterButton setAction:@selector(inputCharacter:)];
				[characterButton setTarget:self];
				[characterButton setTag:character];
				[characterButton setImagePosition:NSNoImage];
				[asciiView addSubview:characterButton];
				[characterButton release];
			}
		}
	
		[self setReleasedWhenClosed:NO];
		[self setContentView:asciiView];
		[self setTitle:NSLocalizedStringFromTable(@"Character Chart", @"xchat", @"")];
		[self center];
		[asciiView release];
	}
	return self;
}

@end

#pragma mark -

@implementation AsciiWindow (private)

- (void) inputCharacter:(id)sender
{
	if (current_sess)
		[current_sess->gui->chatWindow insertText:[sender title]];
}

@end