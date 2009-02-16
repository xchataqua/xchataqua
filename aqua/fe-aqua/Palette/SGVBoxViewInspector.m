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

#import "SGVBoxViewInspector.h"
#import "SG.h"

@implementation SGVBoxViewInspector

- (NSString *)viewNibName
{
    return @"SGVBoxViewInspector";
}

- (void) awakeFromNib
{
    [[VJustMenu itemWithTitle:@"Top"] setTag:SGVBoxTopVJustification];
    [[VJustMenu itemWithTitle:@"Center"] setTag:SGVBoxCenterVJustification];
    [[VJustMenu itemWithTitle:@"Bottom"] setTag:SGVBoxBottomVJustification];

    [[HJustMenu itemWithTitle:@"Left"] setTag:SGVBoxLeftHJustification];
    [[HJustMenu itemWithTitle:@"Center"] setTag:SGVBoxCenterHJustification];
    [[HJustMenu itemWithTitle:@"Right"] setTag:SGVBoxRightHJustification];
    [[HJustMenu itemWithTitle:@"Full"] setTag:SGVBoxFullHJustification];
}

- (void) doVJust:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count], i;

    for(i = 0; i < count; ++i)
    {
        SGVBoxView *view = [objects objectAtIndex:i];
        [view setVJustification:[[sender selectedItem] tag]];
    }
}

- (void) doHJust:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count], i;

    for(i = 0; i < count; ++i)
    {
        SGVBoxView *view = [objects objectAtIndex:i];
        [view setDefaultHJustification:[[sender selectedItem] tag]];
    }
}

- (void) doInner:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count], i;

    for(i = 0; i < count; ++i)
    {
        SGVBoxView * view = [objects objectAtIndex:i];
        [view setVInnerMargin:[inner_text intValue]];
    }
}

- (void) doOutter:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count], i;

    for(i = 0; i < count; ++i)
    {
        SGVBoxView * view = [objects objectAtIndex:i];
        [view setVOutterMargin:[outter_text intValue]];
    }
}

- (void) refresh
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count];

    if(count == 1)
    {
        SGVBoxView *vbox = [objects objectAtIndex:0];
        [VJustMenu selectItemWithTag:[vbox vJustification]];
        [HJustMenu selectItemWithTag:[vbox hJustification]];
        [inner_text setIntValue:[vbox vInnerMargin]];
        [outter_text setIntValue:[vbox vOutterMargin]];
    }
    [super refresh];
}

@end
