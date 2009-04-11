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

#import "UserlistPopup.h"

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
}

@implementation UserlistPopup

- (id) init
{
    [super initWithList:&popup_list fileName:@"popup.conf" title:NSLocalizedStringFromTable(@"XChat: Userlist Popup menu", @"xchat", @"Title of Window: MainMenu->X-Chat Aqua->References Lists->Userlist Popup...")];
    return self;
}

@end
