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

#import "SGRowColView.h"

//////////////////////////////////////////////////////////////////////

@implementation SGRowColView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    
    self->rows = 0;
    self->cols = 0;
    
    return self;
}

- (void) dealloc
{
    [super dealloc];
}

- (void) do_layout
{
    if (cols == 0)
        return;
        
    NSRect r = [self bounds];

    // If we shrink (or expand) ourselvs in the horiontal, our width is the width of
    // the widest row (using the preferred width of all sub views).
        
    if (shrinkh)
    {
        r.size.width = 0;
        CGFloat thisw = 0;
        
        for (NSUInteger i = 0; i < [metaViews count]; i ++)
        {
            if (i % cols == 0)
                thisw = 0;
            
            id metaView = [metaViews objectAtIndex:i];
            NSRect b = [metaView prefSize];
            
            thisw += b.size.width;
            
            if (thisw > r.size.width)
                r.size.width = thisw;
        }
    }
    
    NSUInteger actualRows = rows;

    if (actualRows == 0)
        actualRows = ([metaViews count] + cols - 1) / cols;
    
    // And now for vertical
    
    if (shrinkv)
    {
        r.size.height = 0.0f;
        CGFloat thish = 0.0f;
        
        for (NSUInteger i = 0; i < [metaViews count]; i ++)
        {
            if (i % actualRows == 0) 
				thish = 0.0f;
            
            NSUInteger ii = (i * cols) % actualRows;
            if (ii >= [metaViews count]) continue;

            id metaView = [metaViews objectAtIndex:ii];
            NSRect b = [metaView prefSize];

            thish += b.size.height;
            
            if (thish > r.size.height)
                r.size.height = thish;
        }
    }

    CGFloat vh = r.size.height / actualRows;
    CGFloat vw = r.size.width / cols;
    
    for (NSUInteger i = 0; i < [metaViews count]; i ++)
    {
        id metaView = [metaViews objectAtIndex:i];
        
        NSRect b;
    
        b.origin.x = r.origin.x + floor ((i % cols) * vw);
        b.origin.y = r.origin.y + floor ((i / cols) * vh);
        b.size.width = floor (vw);
        b.size.height = floor (vh);

        [metaView setFrame:b];
    }
    
    [self setFrameSize:r.size];
}

- (void)setCols:(NSInteger)new_cols rows:(NSInteger)new_rows
{
    self->rows = new_rows;
    self->cols = new_cols;
    [self queue_layout];
}

- (void)setShrinkHoriz:(bool)new_shrinkh vert:(bool)new_shrinkv
{
    self->shrinkh = new_shrinkh;
    self->shrinkv = new_shrinkv;
    [self queue_layout];
}

@end
