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
        float thisw = 0;
        
        for (unsigned int i = 0; i < [meta_views count]; i ++)
        {
            if (i % cols == 0)
                thisw = 0;
            
            id meta_view = [meta_views objectAtIndex:i];
            NSRect b = [meta_view prefSize];
            
            thisw += b.size.width;
            
            if (thisw > r.size.width)
                r.size.width = thisw;
        }
    }
    
    int actual_rows = rows;

    if (actual_rows == 0)
        actual_rows = ([meta_views count] + cols - 1) / cols;
    
    // And now for vertical
    
    if (shrinkv)
    {
        r.size.height = 0;
        float thish = 0;
        
        for (unsigned int i = 0; i < [meta_views count]; i ++)
        {
            if (i % actual_rows == 0)
                thish = 0;
            
            unsigned int ii = (i * cols) % actual_rows;
            if (ii >= [meta_views count])
                continue;

            id meta_view = [meta_views objectAtIndex:ii];
            NSRect b = [meta_view prefSize];

            thish += b.size.height;
            
            if (thish > r.size.height)
                r.size.height = thish;
        }
    }

    float vh = r.size.height / actual_rows;
    float vw = r.size.width / cols;
    
    for (unsigned int i = 0; i < [meta_views count]; i ++)
    {
        id meta_view = [meta_views objectAtIndex:i];
        
        NSRect b;
    
        b.origin.x = r.origin.x + floor ((i % cols) * vw);
        b.origin.y = r.origin.y + floor ((i / cols) * vh);
        b.size.width = floor (vw);
        b.size.height = floor (vh);

        [meta_view setFrame:b];
    }
    
    [self setFrameSize:r.size];
}

- (void)setCols:(int)new_cols rows:(int)new_rows
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
