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
    
    [self setOrientation:SGBoxVertical];
    [self setVJustification:SGVBoxTopVJustification];
    [self setDefaultHJustification:SGVBoxCenterHJustification];
    
    return self;
}

- (void) setVJustification:(short) new_just
{
    [self setMajorJustification:new_just];
}

- (void) setDefaultHJustification:(short) new_just
{
    [self setMinorDefaultJustification:new_just];
}

- (short) hJustification
{
    return [self minorJustification];
}

- (void) setHJustificationFor:(NSView *) view to:(short) new_just
{
    [self setMinorJustificationFor:view to:new_just];
}

- (void) setHMargin:(short) v
{
    [self setMinorMargin:v];
}

- (void) setVInnerMargin:(short) h
{
    [self setMajorInnerMargin:h];
}

- (short) vInnerMargin
{
    return [self majorInnerMargin];
}

- (void) setVOutterMargin:(short) h
{
    [self setMajorOutterMargin:h];
}

- (short) vOutterMargin
{
    return [self majorOutterMargin];
}

- (short) vJustification
{
    return [self majorJustification];
}

@end
