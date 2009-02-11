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

#import "SGHBoxViewInspector.h"
#import "SG.h"

@implementation SGHBoxViewInspector

- (id) init
{
    self = [super init];
    [NSBundle loadNibNamed:@"SGHBoxViewInspector" owner:self];
    return self;
}

- (void) awakeFromNib
{
    [[HJustMenu itemWithTitle:@"Left"] setTag:SGHBoxLeftHJustification];
    [[HJustMenu itemWithTitle:@"Center"] setTag:SGHBoxCenterHJustification];
    [[HJustMenu itemWithTitle:@"Right"] setTag:SGHBoxRightHJustification];
}

- (void) doHJust:(id) sender
{
    SGHBoxView *view = [self object];
    [view setHJustification:[[sender selectedItem] tag]];
    [super ok:sender];
}

- (void) doInner:(id) sender
{
    SGHBoxView *hbox = [self object];
    [hbox setHInnerMargin:[inner_text intValue]];
    [super ok:sender];
}

- (void) doOutter:(id) sender
{
    SGHBoxView *hbox = [self object];
    [hbox setHOutterMargin:[outter_text intValue]];
    [super ok:sender];
}

- (void) revert:(id) sender
{
    SGHBoxView *hbox = [self object];
    [HJustMenu selectItemWithTag:[hbox hJustification]];
    [inner_text setIntValue:[hbox hInnerMargin]];
    [outter_text setIntValue:[hbox hOutterMargin]];
    [super revert:sender];
}

@end
