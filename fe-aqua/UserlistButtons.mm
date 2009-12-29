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

#import "AquaChat.h"
#import "UserlistButtons.h"

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
}

@implementation UserlistButtons

- (id) init
{
    [super initWithList:&button_list fileName:@"buttons.conf" title:NSLocalizedStringFromTable(@"XChat: Userlist buttons", @"xchat", "Title of Window: MainMenu->X-Chat Aqua->References Lists->Userlist Buttons...")];
    return self;
}

- (void) do_save:(id) sender
{
    [super do_save:sender];
    [AquaChat forEachSessionOnServer:NULL
		     performSelector:@selector (setup_userlist_buttons)];
}

@end
