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
	CLLevelIndicatorCell.h
	Created by Camillo Lugaresi on 13/01/06.
	
	This cell can draw a non-animating level indicator in a variety of styles.
*/

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

#define CLLevelIndicatorFlat	0xFFFF

@interface CLLevelIndicatorCell : NSCell {
	HIThemeTrackDrawInfo drawInfo;
}

- (void) setKind:(UInt16)kind;
- (UInt16) kind;

@end
