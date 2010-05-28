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

#import "SGView.h"

//////////////////////////////////////////////////////////////////////

typedef enum
{
    SGBoxOrientationHorizontal,
    SGBoxOrientationVertical,
}	SGBoxOrientation;

typedef enum {
    SGBoxMinorJustificationCenter,
    SGBoxMinorJustificationFirst,
    SGBoxMinorJustificationLast,
    SGBoxMinorJustificationFull,
    SGBoxMinorJustificationDefault,		// This is used to undo setMajorJustificationFor
}	SGBoxMinorJustification;

typedef enum {
    SGBoxMajorJustificationCenter,		// Overrides stretch view
    SGBoxMajorJustificationLast,		// Not implemented yet
    SGBoxMajorJustificationFirst,
    SGBoxMajorJustificationFull,		// Not implemented yet.  Stretches all views with
}	SGBoxMajorJustification;			// leftover space.  Overrides stretch view
										// This may be too much for this View..??
typedef enum
{
    SGBoxOrderFIFO,
    SGBoxOrderLIFO,
}	SGBoxOrder;

typedef short SGBoxMargin;

@interface SGBoxView : SGView
{
    NSView					*stretchView;
    SGBoxMinorJustification	minorJustification;
    SGBoxMajorJustification	majorJustification;
    SGBoxMargin				minorMargin;
    SGBoxMargin				majorInnerMargin;
    SGBoxMargin				majorOutterMargin;
    SGBoxOrientation		orientation;
    SGBoxOrder				order;
    BOOL					wrap;
}

@property (nonatomic,assign,setter=setStretchView:)			NSView *stretchView;
@property (nonatomic,readonly)								SGBoxMinorJustification	minorJustification;
@property (nonatomic,assign,setter=setMajorJustification:)	SGBoxMajorJustification	majorJustification;
@property (nonatomic,assign,setter=setMinorMargin:)			SGBoxMargin				minorMargin;
@property (nonatomic,assign,setter=setMajorInnerMargin:)	SGBoxMargin				majorInnerMargin;
@property (nonatomic,assign,setter=setMajorOutterMargin:)	SGBoxMargin				majorOutterMargin;
@property (nonatomic,assign,setter=setOrientation:)			SGBoxOrientation		orientation;
@property (nonatomic,assign,setter=setOrder:)				SGBoxOrder				order;

- (void) setMinorDefaultJustification:(SGBoxMinorJustification) just;
- (void) setMinorJustificationFor:(NSView *) view to:(SGBoxMinorJustification) just;

@end
