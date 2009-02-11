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
	CLLevelIndicator.m
	Created by Camillo Lugaresi on 13/01/06.
	
	This control displays a non-animating level indicator in a variety of styles.
*/

#import "CLLevelIndicator.h"
#import "CLLevelIndicatorCell.h"


@implementation CLLevelIndicator

+ (Class)cellClass
{
	return [CLLevelIndicatorCell class];
}

- (void) setKind:(UInt16)kind
{
	[[self cell] setKind:kind];
}

- (UInt16) kind
{
	return [(CLLevelIndicatorCell *)[self cell] kind];
}

/* undocumented method used to update the cell when the window is activated/deactivated */
- (void) _windowChangedKeyState
{
	[self updateCell:[self cell]];
}

- (void) sizeToFit
{
	// How can we determine how big the HIToolbox track should be?
	NSSize sz = [self frame].size;
	sz.height = 10;
	[self setFrameSize:sz];
}

@end
