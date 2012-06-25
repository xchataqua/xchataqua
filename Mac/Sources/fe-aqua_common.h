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

@protocol XAEventChain

- (void)applyPreferences:(id)sender;

@end

@class ChatViewController;
struct session_gui
{
    ChatViewController *controller;
};

struct server_gui
{
    NSInteger tabGroup;    // assume sizeof(NSInteger) > sizeof(struct server *)
};

struct XATextEventItem {
    NSInteger growl;
    NSInteger show;
    NSInteger bounce;
};

void nick_command_parse (struct session *sess, const char *cmd, const char *nick, const char *allnick);
void change_channel_flag (struct session *sess, char flag, int enabled);
void set_l_flag (struct session *sess, int enabled, int value);
void set_k_flag (struct session *sess, int enabled, char *value);

NSString * formatNumber (int n);
