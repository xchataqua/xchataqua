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

@interface SGConfirmDelegate : NSObject
{
  @public
	id obj;
	SEL yes_sel;
	SEL no_sel;
}
@end

@implementation SGConfirmDelegate

- (void) alertDidEnd:(NSAlert *) alert
		  returnCode:(int) returnCode 
		 contextInfo:(void *) contextInfo
{
	if (returnCode == NSAlertFirstButtonReturn)
	{
		[obj performSelector:no_sel];
	}
	else if (returnCode == NSAlertSecondButtonReturn)
	{
		[obj performSelector:yes_sel];
	}
	
	[self release];
}

@end

/////////////////////////////////////////////////////////////////////////////////////////

@implementation SGAlert

+ (void) doitWithStyle:(NSAlertStyle) style
			   message:(NSString *) alert_text
			   andWait:(bool) wait
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel setAlertStyle:style];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"OK", @"libsg", @"button")];
	[panel setMessageText:alert_text];

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

+ (void) alertWithString:(NSString *) alert_text andWait:(bool) wait
{
	[self doitWithStyle:NSWarningAlertStyle
		        message:alert_text
		        andWait:wait];
}

+ (void) noticeWithString:(NSString *) alert_text andWait:(bool) wait
{
	[self doitWithStyle:NSInformationalAlertStyle
		        message:alert_text
		        andWait:wait];
}

+ (void) errorWithString:(NSString *) alert_text andWait:(bool) wait
{
	[self doitWithStyle:NSCriticalAlertStyle
				message:alert_text
		        andWait:wait];
}

+ (bool) confirmWithString:(NSString *) alert_text
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"No", @"libsg", @"button")];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"Yes",@"libsg", @"button")];
	[panel setMessageText:alert_text];
	[panel setAlertStyle:NSInformationalAlertStyle];

	int ret = [panel runModal];
	
	return ret == NSAlertSecondButtonReturn;
}

+ (void) confirmWithString:(NSString *) alert_text
                    inform:(id) obj
                   yes_sel:(SEL) yes_sel
                    no_sel:(SEL) no_sel
{
	NSAlert *panel = [[[NSAlert alloc] init] autorelease];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"No" ,@"libsg", @"button")];
	[panel addButtonWithTitle:NSLocalizedStringFromTable(@"Yes",@"libsg", @"button")];
	[panel setMessageText:alert_text];
	[panel setAlertStyle:NSInformationalAlertStyle];

	SGConfirmDelegate *confirmDelegate = [[SGConfirmDelegate alloc] init];
	confirmDelegate->obj = obj;
	confirmDelegate->yes_sel = yes_sel;
	confirmDelegate->no_sel = no_sel;
	
	// Modal, but non-blocking
	[panel beginSheetModalForWindow:nil
			modalDelegate:confirmDelegate
			didEndSelector:@selector (alertDidEnd:returnCode:contextInfo:)
			contextInfo:nil];
}

@end
