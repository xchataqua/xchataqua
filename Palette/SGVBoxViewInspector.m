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
    [[VJustMenu itemWithTitle:@"Top"] setTag:SGVBoxVJustificationTop];
    [[VJustMenu itemWithTitle:@"Center"] setTag:SGVBoxVJustificationCenter];
    [[VJustMenu itemWithTitle:@"Bottom"] setTag:SGVBoxVJustificationBottom];

    [[HJustMenu itemWithTitle:@"Left"] setTag:SGVBoxHJustificationLeft];
    [[HJustMenu itemWithTitle:@"Center"] setTag:SGVBoxHJustificationCenter];
    [[HJustMenu itemWithTitle:@"Right"] setTag:SGVBoxHJustificationRight];
    [[HJustMenu itemWithTitle:@"Full"] setTag:SGVBoxHJustificationFull];
}

- (void) doVJust:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSUInteger count = [objects count];

    for(NSUInteger i = 0; i < count; ++i)
    {
        SGVBoxView *view = [objects objectAtIndex:i];
        view.vJustification = [[sender selectedItem] tag];
    }
}

- (void) doHJust:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count];

    for(NSUInteger i = 0; i < count; ++i)
    {
        SGVBoxView *view = [objects objectAtIndex:i];
        [view setDefaultHJustification:[[sender selectedItem] tag]];
    }
}

- (void) doInner:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count];

    for(NSUInteger i = 0; i < count; ++i)
    {
        SGVBoxView * view = [objects objectAtIndex:i];
        view.vInnerMargin = [inner_text intValue];
    }
}

- (void) doOutter:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger count = [objects count];

    for(NSUInteger i = 0; i < count; ++i)
    {
        SGVBoxView * view = [objects objectAtIndex:i];
        view.vOutterMargin= [outter_text intValue];
    }
}

- (void) refresh
{
    NSArray * objects = [self inspectedObjects];

    if([objects count] == 1)
    {
        SGVBoxView *vbox = [objects objectAtIndex:0];
        [VJustMenu selectItemWithTag:vbox.vJustification];
        [HJustMenu selectItemWithTag:vbox.hJustification];
        [inner_text  setIntegerValue:vbox.vInnerMargin];
        [outter_text setIntegerValue:vbox.vOutterMargin];
    }
    [super refresh];
}

@end
