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

#import "SGAlert.h"

@interface SGAlertConfirmDelegate : NSObject
{
  @public
	id obj;
	SEL yesSel;
	SEL noSel;
}
@end

@implementation SGAlertConfirmDelegate

- (void) alertDidEnd:(NSAlert *)alert
		  returnCode:(NSInteger)returnCode 
		 contextInfo:(void *)contextInfo
{
	switch (returnCode) {
		case NSAlertFirstButtonReturn: [obj performSelector:noSel]; break;
		case NSAlertSecondButtonReturn:[obj performSelector:yesSel];break;
		default: break;
	}
	[self release];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////

@implementation SGAlert

+ (void) doitWithStyle:(NSAlertStyle) style
			   message:(NSString *)alertText
			   andWait:(BOOL) wait
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel setAlertStyle:style];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"OK", @"libsg", @"button")];
	[panel setMessageText:alertText];

	if (wait)
	{
		[panel runModal];
	}
	else
	{
		// Modal, but not blocking
		[panel beginSheetModalForWindow:nil
						  modalDelegate:nil
						 didEndSelector:nil
							contextInfo:nil];
	}
}

+ (void) alertWithString:(NSString *)alertText andWait:(BOOL)wait
{
	[self doitWithStyle:NSWarningAlertStyle message:alertText andWait:wait];
}

+ (void) noticeWithString:(NSString *)alertText andWait:(BOOL)wait
{
	[self doitWithStyle:NSInformationalAlertStyle message:alertText andWait:wait];
}

+ (void) errorWithString:(NSString *)alertText andWait:(BOOL) wait
{
	[self doitWithStyle:NSCriticalAlertStyle message:alertText andWait:wait];
}

+ (BOOL) confirmWithString:(NSString *)alertText
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"No", @"libsg", @"button")];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"Yes",@"libsg", @"button")];
	[panel setMessageText:alertText];
	[panel setAlertStyle:NSInformationalAlertStyle];

	NSInteger ret = [panel runModal];
	
	return ret == NSAlertSecondButtonReturn;
}

+ (void) confirmWithString:(NSString *)alertText
					inform:(id) obj
					yesSel:(SEL) yesSel
					 noSel:(SEL) noSel
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"No" ,@"libsg", @"button")];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"Yes",@"libsg", @"button")];
	[panel setMessageText:alertText];
	[panel setAlertStyle:NSInformationalAlertStyle];

	SGAlertConfirmDelegate *confirmDelegate = [[SGAlertConfirmDelegate alloc] init];
	confirmDelegate->obj = obj;
	confirmDelegate->yesSel = yesSel;
	confirmDelegate->noSel = noSel;
	
	// Modal, but non-blocking
	[panel beginSheetModalForWindow:nil
					  modalDelegate:confirmDelegate
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
}

@end
