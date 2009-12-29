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

enum
{
    SGBoxHorizontal,
    SGBoxVertical,
};

enum
{
    SGBoxMinorCenterJustification,
    SGBoxMinorFirstJustification,
    SGBoxMinorLastJustification,
    SGBoxMinorFullJustification,
    SGBoxMinorDefaultJustification,		// This is used to undo setMajorJustificationFor
};

enum
{
    SGBoxMajorCenterJustification,		// Overrides stretch view
    SGBoxMajorLastJustification,		// Not implemented yet
    SGBoxMajorFirstJustification,
    SGBoxMajorFullJustification,		// Not implemented yet.  Stretches all views with
};                                      // leftover space.  Overrides stretch view
                                        // This may be too much for this View..??
enum
{
    SGBoxFIFO,
    SGBoxLIFO
};

@interface SGBoxView : SGView
{
    NSView	*stretch;
    short	minorjust;
    short	majorjust;
    short	minormargin;
    short	majorinnermargin;
    short	majorouttermargin;
    char	orient;
    char	order;
    bool    wrap;
}

- (void) setStretchView:(NSView *) view;		// For left or right justification only
- (NSView *) stretchView;
- (void) setMajorJustification:(short) just;
- (short) majorJustification;
- (void) setMinorDefaultJustification:(short) just;
- (short) minorJustification;
- (void) setMinorJustificationFor:(NSView *) view to:(short) just;
- (void) setMinorMargin:(short) v;
- (void) setMajorInnerMargin:(short) h;
- (short) majorInnerMargin;
- (void) setMajorOutterMargin:(short) h;
- (short) majorOutterMargin;
- (void) setOrientation:(int) orientation;
- (int)  orientation;
- (void) setOrder:(int) order;
- (int)  order;

@end
