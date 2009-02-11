/* CLLevelIndicator
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
	CLLevelIndicatorCell.m
	Created by Camillo Lugaresi on 13/01/06.
	
	This cell can draw a non-animating level indicator in a variety of styles.
*/

#import "CLLevelIndicatorCell.h"
#include <Carbon/Carbon.h>

static inline CGRect CGRectFromNSRect(NSRect nsRect)
{
    return *(CGRect*)&nsRect;
}

@implementation CLLevelIndicatorCell

- (id)init
{
	self = [super init];
	[self setType:NSTextCellType];	/* NSCell only manages values for text cells, so advertise ourselves as such */
	drawInfo.version = 0;
	drawInfo.kind = kThemeProgressBarMedium;
	drawInfo.min = 0;
	drawInfo.max = 1000000;
	drawInfo.reserved = 0;
	drawInfo.filler1 = 0;
	drawInfo.trackInfo.progress.phase = 0;
	return self;
}

- (void) setKind:(UInt16)kind
{
	drawInfo.kind = kind;
}

- (UInt16) kind
{
	return drawInfo.kind;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	if (drawInfo.kind == CLLevelIndicatorFlat) {
		NSRect bar, rest;

		[[NSColor grayColor] set];
		[NSBezierPath setDefaultLineWidth:1];
		[NSBezierPath strokeRect:cellFrame];
		
		NSDivideRect(NSInsetRect(cellFrame, 1, 1), &bar, &rest, cellFrame.size.width * [self floatValue], NSMinXEdge);
		[NSBezierPath fillRect:bar];
		
		[[NSColor colorWithDeviceWhite:0.9 alpha:1.0] set];
		[NSBezierPath fillRect:rest];
	} else {
		drawInfo.bounds = CGRectFromNSRect(cellFrame);
		drawInfo.value = drawInfo.max * [self floatValue];
		drawInfo.attributes = kThemeTrackHorizontal;
		drawInfo.enableState = [[controlView window] isMainWindow] ? kThemeTrackActive : kThemeTrackInactive;

		OSStatus err = HIThemeDrawTrack(&drawInfo, NULL, (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort], [controlView isFlipped] ? kHIThemeOrientationNormal : kHIThemeOrientationInverted);
		if (err != noErr) [NSException raise:NSGenericException format:@"CLLevelIndicatorCell: HIThemeDrawTrack returned %d", err];
	}
}

@end
