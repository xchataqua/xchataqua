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

#import "SGHBoxView.h"

//////////////////////////////////////////////////////////////////////

@implementation SGHBoxView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    
    [self setOrientation:SGBoxOrientationHorizontal];
    [self setHJustification:SGHBoxHJustificationLeft];
    [self setDefaultVJustification:SGHBoxVJustificationCenter];
    
    return self;
}

- (void) setHJustification:(SGHBoxHJustification) new_just
{
    [self setMajorJustification:(SGBoxMajorJustification)new_just];
}

- (short) hJustification
{
    return [self majorJustification];
}

- (void) setDefaultVJustification:(SGHBoxVJustification) new_just
{
    [self setMinorDefaultJustification:(SGBoxMinorJustification)new_just];
}

- (void) setVJustificationFor:(NSView *) view to:(SGHBoxVJustification) new_just
{
    [self setMinorJustificationFor:view to:(SGBoxMinorJustification)new_just];
}

- (void) setVMargin:(short) v
{
    [self setMinorMargin:v];
}

- (void) setHInnerMargin:(short) h
{
    [self setMajorInnerMargin:h];
}

- (short) hInnerMargin
{
    return [self majorInnerMargin];
}

- (void) setHOutterMargin:(short) h
{
    [self setMajorOutterMargin:h];
}

- (short) hOutterMargin
{
    return [self majorOutterMargin];
}

#if 0
- (void) drawRect:(NSRect) aRect
{
    [super drawRect:aRect];

    [[NSColor redColor] set];
    [[NSGraphicsContext currentContext] setShouldAntialias:false];
    NSBezierPath *p = [NSBezierPath bezierPathWithRect:[self bounds]];
    [p setLineWidth:5];
    [p stroke];
}
#endif

@end
