/* X-Chat Aqua
 * Copyright (C) 2005 Steve Green
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

- (id) init
{
    self = [super init];
    [NSBundle loadNibNamed:@"SGVBoxViewInspector" owner:self];
    return self;
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
    SGVBoxView *view = [self object];
    [view setVJustification:[[sender selectedItem] tag]];
    [super ok:sender];
}

- (void) doHJust:(id) sender
{
    SGVBoxView *view = [self object];
    [view setDefaultHJustification:[[sender selectedItem] tag]];
    [super ok:sender];
}

- (void) doInner:(id) sender
{
    SGVBoxView *VBox = [self object];
    [VBox setVInnerMargin:[inner_text intValue]];
    [super ok:sender];
}

- (void) doOutter:(id) sender
{
    SGVBoxView *VBox = [self object];
    [VBox setVOutterMargin:[outter_text intValue]];
    [super ok:sender];
}

- (void) revert:(id) sender
{
    SGVBoxView *VBox = [self object];
    [VJustMenu selectItemWithTag:[VBox vJustification]];
    [HJustMenu selectItemWithTag:[VBox hJustification]];
    [inner_text setIntValue:[VBox vInnerMargin]];
    [outter_text setIntValue:[VBox vOutterMargin]];
    [super revert:sender];
}

@end
