/* X-Chat Aqua
 * Copyright (C) 2005 Steve Green
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

#import "SGView.h"

@interface SGView (SGPaletteSGViewAdditions)
@end

@implementation SGView (SGPaletteSGViewAdditions)

- (void) drawRect:(NSRect) aRect
{
	if ([[self subviews] count] > 0 || [NSApp isTestingInterface])
	{
		[super drawRect:aRect];
		return;
	}
	
	NSRect bounds = [self bounds];
	
	NSRectEdge mySides [] =
	{
		NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge, 
		NSMinYEdge, NSMaxXEdge, NSMaxYEdge, NSMinXEdge
	};

	float myGrays [] = 
	{
		NSLightGray, NSLightGray, NSLightGray, NSLightGray,
		NSWhite, NSWhite, NSWhite, NSWhite 
	};

	NSRect anotherRect = NSDrawTiledRects (bounds, aRect, mySides, myGrays, 8);
	[[NSColor colorWithDeviceRed:.55 green:.65 blue:.75 alpha:.5] set];
	[NSBezierPath fillRect:anotherRect];
	
	NSDictionary *attributes = [[NSDictionary alloc]
		initWithObjectsAndKeys:[NSColor whiteColor], NSForegroundColorAttributeName,
							   [NSFont boldSystemFontOfSize:12.0], NSFontAttributeName, 
							   nil];

	NSAttributedString *label = [[[NSAttributedString alloc] 
				initWithString:[[self class] className] attributes:attributes] autorelease];
	NSSize labelSize = [label size];
	bounds.origin.y += floorf((bounds.size.height - labelSize.height)/2.0);
	bounds.origin.x += floorf((bounds.size.width - labelSize.width)/2.0);
	bounds.size = labelSize;
	[label drawInRect:bounds];
}

@end