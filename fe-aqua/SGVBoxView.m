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

#import "SGVBoxView.h"

//////////////////////////////////////////////////////////////////////

@implementation SGVBoxView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    
    [self setOrientation:SGBoxOrientationVertical];
    self.vJustification = SGVBoxVJustificationTop;
    [self setDefaultHJustification:SGVBoxHJustificationCenter];
    
    return self;
}

- (void) setVJustification:(SGVBoxVJustification) aJustification
{
    [self setMajorJustification:(SGBoxMajorJustification)aJustification];
}

- (void) setDefaultHJustification:(SGVBoxHJustification) aJustification
{
    [self setMinorDefaultJustification:(SGBoxMinorJustification)aJustification];
}

- (SGVBoxHJustification) hJustification
{
    return [self minorJustification];
}

- (void) setHJustificationFor:(NSView *) view to:(SGVBoxHJustification) aJustification
{
    [self setMinorJustificationFor:view to:(SGBoxMinorJustification)aJustification];
}

- (void) setHMargin:(SGBoxMargin) v
{
    [self setMinorMargin:v];
}

- (SGBoxMargin) hMargin {
	return minorMargin;
}

- (void) setVInnerMargin:(SGBoxMargin) h
{
    [self setMajorInnerMargin:h];
}

- (SGBoxMargin) vInnerMargin
{
    return [self majorInnerMargin];
}

- (void) setVOutterMargin:(SGBoxMargin) h
{
    [self setMajorOutterMargin:h];
}

- (SGBoxMargin) vOutterMargin
{
    return [self majorOutterMargin];
}

- (SGVBoxVJustification) vJustification
{
    return [self majorJustification];
}

@end
