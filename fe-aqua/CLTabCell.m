/* CLTabCell
 * Copyright (C) 2006 Camillo Lugaresi
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

/*
 CLTabCell.m
 Created by Camillo Lugaresi on 17/01/06.
 
 This cell draws a theme-compliant tab. Subclass to add customized content.
 */

#import "CLTabCell.h"

@interface NSView(CLTabCellAdditions)

- (void)displayRectWithoutSubviews:(NSRect)aRect;

@end

@implementation NSView(CLTabCellAdditions)

- (void)displayRectWithoutSubviews:(NSRect)aRect
{
	if (![self isOpaque]) {
		NSView *superview = [self superview];
		[superview displayRectWithoutSubviews:[self convertRect:aRect toView:superview]];
	}
	if ([self lockFocusIfCanDraw]) {
		[[NSBezierPath bezierPathWithRect:aRect] setClip];
		[self drawRect:aRect];
		[self unlockFocus];
	}
}

@end


@implementation CLTabCell

/*  Note: HIThemeDrawTab is available on Panther, but only supported the Jaguar tab
 appearance until 10.4. We check for HIThemeDrawSegment instead, since that call
 is only available on the 10.4 version of HIToolbox. */
+ (BOOL)available
{
	return (HIThemeDrawSegment != NULL);
}

- (id)init
{
	self = [super init];
	drawInfo.version = 1;
	drawInfo.direction = kThemeTabNorth;
	drawInfo.size = kHIThemeTabSizeNormal;
	drawInfo.adornment = kHIThemeTabAdornmentNone;
	drawInfo.kind = kHIThemeTabKindNormal;
	drawInfo.position = kHIThemeTabPositionOnly;
	return self;
}

- (HIThemeTabPosition)position
{
	return drawInfo.position;
}

- (void)setPosition:(HIThemeTabPosition)position
{
	drawInfo.position = position;
	switch (position) {
		case kHIThemeTabPositionOnly:
			drawInfo.adornment = kHIThemeTabAdornmentNone;
			break;
		case kHIThemeTabPositionFirst:
			drawInfo.adornment = kHIThemeTabAdornmentTrailingSeparator;
			break;
		case kHIThemeTabPositionMiddle:
			drawInfo.adornment = kHIThemeTabAdornmentTrailingSeparator;
			break;
		case kHIThemeTabPositionLast:
			break;
	}
}

- (NSSize)contentSize
{
	NSSize titleSize = [[self attributedTitle] size];
	return titleSize;
}

- (NSSize)cellSize
{
	NSSize mySize, contentSize;
	SInt32 metric;
	
	contentSize = [self contentSize];
	verify_noerr( GetThemeMetric(kThemeMetricLargeTabHeight, &metric) );
	mySize.height = metric;
	verify_noerr( GetThemeMetric(kThemeMetricTabFrameOverlap, &metric) );
	mySize.height += metric;
	verify_noerr( GetThemeMetric(kThemeMetricLargeTabCapsWidth, &metric) );
	mySize.width = floor(contentSize.width) + metric * 2;
	
	return mySize;
}

- (BOOL)isOpaque
{
	return NO;
}

- (void)drawContentInRect:(NSRect)contentFrame inView:(NSView *)controlView
{
	NSAttributedString *attributedTitle = [self attributedTitle];
	NSSize titleSize = [attributedTitle size];
	NSPoint pt;
    
	pt.x = contentFrame.origin.x + (contentFrame.size.width - floor(titleSize.width)) / 2;
	pt.y = contentFrame.origin.y + (contentFrame.size.height - floor(titleSize.height)) / 2;
    [attributedTitle drawAtPoint:pt];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	BOOL front = ([self state] == NSOnState);
	BOOL pressed = [self isHighlighted];
	BOOL inactive = ![[controlView window] isMainWindow];
	BOOL disabled = [self cellAttribute:NSCellDisabled];
	HIThemeOrientation orientation = [controlView isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted;
	HIRect cellRect = NSRectToCGRect(cellFrame);
	HIRect labelRect;
	OSStatus err;
	
	if (front) {
		if (disabled) drawInfo.style = kThemeTabFrontUnavailable;
		else if (inactive) drawInfo.style = kThemeTabFrontInactive;
		else drawInfo.style = kThemeTabFront;
	} else {
		if (disabled) drawInfo.style = kThemeTabNonFrontUnavailable;
		else if (pressed) drawInfo.style = kThemeTabNonFrontPressed;
		else if (inactive) drawInfo.style = kThemeTabNonFrontInactive;
		else drawInfo.style = kThemeTabNonFront;
	}
	
    /*	This piece of code shows how to draw the proper separator for pressed and front tabs;
     however, it causes unwanted shadow multiplication. To get the proper look, one would
     have to: (1) ensure that the preceding tab does not draw the trailing separator;
     (2) cause the background to be redrawn before drawing the tab. These things are only
     practical to do when a single control manages an entire tab group. For now, let's
     just not draw the highlighted leading separator; it's a rather subtle difference.	*/
    /*	Addendum: actually, we can get it right if we punch a hole in the previous tab using
     displayRectWithoutSubviews: on the superview. The tab control should still tell the
     previous tab to hide its trailing separator, because the display order of sibling
     views is not guaranteed! However, this code would still be necessary for the highlight
     case: move the cursor in and out of the tracking tab, and the shadows will multiply
     unless you tell the parent to redraw itself.	*/
#if 1
	if ((drawInfo.position == kHIThemeTabPositionLast || drawInfo.position == kHIThemeTabPositionMiddle)
		&& (pressed || front)) {
		drawInfo.adornment |= kHIThemeTabAdornmentLeadingSeparator;
		NSRect separatorRect = cellFrame;
		separatorRect.origin.x--;
		separatorRect.size.width = 1;
		NSView *superview = [controlView superview];
		[superview displayRectWithoutSubviews:[controlView convertRect:separatorRect toView:superview]];
		[[NSBezierPath bezierPathWithRect:NSUnionRect(cellFrame, separatorRect)] setClip];
	}
#endif
    
	err = HIThemeDrawTab(&cellRect, &drawInfo, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort],
                         orientation, &labelRect);
	if (err != noErr) [NSException raise:NSGenericException format:@"CLTabCell: HIThemeDrawTab returned %d", err];
    
	if (orientation == kHIThemeOrientationInverted)
		labelRect.origin.y = cellRect.size.height - (labelRect.size.height + labelRect.origin.y);
	
	[self drawContentInRect:NSRectFromCGRect(labelRect) inView:controlView];
}

@end
