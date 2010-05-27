/* X-Chat Aqua
 * Copyright (C) 2005-2009 Steve Green
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

#import "SGHBoxViewInspector.h"
#import "SG.h"

@implementation SGHBoxViewInspector

- (NSString *)viewNibName
{
    return @"SGHBoxViewInspector";
}

- (void) awakeFromNib
{
    [[HJustMenu itemWithTitle:@"Left"]   setTag:SGHBoxHJustificationLeft];
    [[HJustMenu itemWithTitle:@"Center"] setTag:SGHBoxHJustificationCenter];
    [[HJustMenu itemWithTitle:@"Right"]  setTag:SGHBoxHJustificationRight];
}

- (void) doHJust:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count], i;

    for (i = 0; i < numObjects; ++i)
    {
        SGHBoxView *view = [objects objectAtIndex:i];
        [view setHJustification:[[sender selectedItem] tag]];
    }
}

- (void) doInner:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count], i;

    for(i = 0; i < numObjects; ++i)
    {
        SGHBoxView *hbox = [objects objectAtIndex:i];
        [hbox setHInnerMargin:[inner_text intValue]];
    }
}

- (void) doOutter:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count], i;

    for(i = 0; i < numObjects; ++i)
    {
        SGHBoxView *hbox = [objects objectAtIndex:i];
        [hbox setHOutterMargin:[outter_text intValue]];
    }
}

- (void) refresh
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count];

    if(numObjects == 1)
    {
        SGHBoxView *hbox = [objects objectAtIndex:0];
        [HJustMenu selectItemWithTag:[hbox hJustification]];
        [inner_text setIntValue:[hbox hInnerMargin]];
        [outter_text setIntValue:[hbox hOutterMargin]];
    }
    [super refresh];
}


@end

