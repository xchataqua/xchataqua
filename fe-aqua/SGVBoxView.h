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

#import "SGBoxView.h"

//////////////////////////////////////////////////////////////////////

typedef enum
{
    SGVBoxHJustificationCenter	= SGBoxMinorJustificationCenter,
    SGVBoxHJustificationLeft	= SGBoxMinorJustificationFirst,
    SGVBoxHJustificationRight	= SGBoxMinorJustificationLast,
    SGVBoxHJustificationFull	= SGBoxMinorJustificationFull,
    SGVBoxHJustificationDefault	= SGBoxMinorJustificationDefault,
}	SGVBoxHJustification;

typedef enum
{
    SGVBoxVJustificationCenter	= SGBoxMajorJustificationCenter,
    SGVBoxVJustificationBottom	= SGBoxMajorJustificationLast,
    SGVBoxVJustificationTop		= SGBoxMajorJustificationFirst,
    SGVBoxVJustificationFull	= SGBoxMajorJustificationFull,
}	SGVBoxVJustification;

@interface SGVBoxView : SGBoxView

@property (nonatomic, assign, getter=majorJustification, setter=setMajorJustification:) SGVBoxVJustification vJustification;
@property (nonatomic, readonly, getter=minorJustification)                              SGVBoxHJustification hJustification;
@property (nonatomic, assign, getter=minorMargin, setter=setMinorMargin:)               SGBoxMargin hMargin;
@property (nonatomic, assign, getter=majorInnerMargin,   setter=setMajorInnerMargin:)   SGBoxMargin vInnerMargin;
@property (nonatomic, assign, getter=majorOutterMargin,  setter=setMajorOutterMargin:)  SGBoxMargin vOutterMargin;

- (void) setDefaultHJustification:(SGVBoxHJustification) justification;
- (void) setHJustificationFor:(NSView *) view to:(SGVBoxHJustification) justification;

@end
