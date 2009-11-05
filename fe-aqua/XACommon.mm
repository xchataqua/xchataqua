/* X-Chat
 * Copyright (C) 2002 Peter Zelezny
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

#include <Foundation/Foundation.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/userlist.h"
#include "../common/server.h"
#include "../common/util.h"
#undef TYPE_BOOL
#include "../common/cfgfiles.h"
}

#include "XACommon.h"

void change_channel_flag (session *sess, char flag, int enabled)
{
    if (sess->server->connected && sess->channel[0])
    {
        if (enabled)
            tcp_sendf (sess->server, "MODE %s +%c\r\n", sess->channel, flag);
        else
            tcp_sendf (sess->server, "MODE %s -%c\r\n", sess->channel, flag);
        tcp_sendf (sess->server, "MODE %s\r\n", sess->channel);
        sess->ignore_mode = TRUE;
        sess->ignore_date = TRUE;
    }
}

void set_l_flag (session *sess, int enabled, int value)
{
    if (sess->server->connected && sess->channel[0])
    {
        if (enabled)
        {
            tcp_sendf (sess->server, "MODE %s +l %d\r\n", sess->channel, value);
            tcp_sendf (sess->server, "MODE %s\r\n", sess->channel);
        } 
        else
            change_channel_flag (sess, 'l', 0);
    }
}

void set_k_flag (session *sess, int enabled, char *value)
{
    if (sess->server->connected && sess->channel[0])
    {
        char d = enabled ? '+' : '-';
        tcp_sendf (sess->server, "MODE %s %ck %s\r\n", sess->channel, d, value);
    }
}


// This is straight copied from fe-gtk
static void
nick_command (session * sess, char *cmd)
{
/*      gtkutil_get_number ("title", "Number to kill:", shit, "hi");*/

        if (*cmd == '!')
                xchat_exec (cmd + 1);
        else
                handle_command (sess, cmd, TRUE);
}


// This is slightly modified from the version in fe-gtk
/* fill in the %a %s %n etc and execute the command */
void
nick_command_parse (session *sess, const char *cmd, const char *nick, const char *allnick)
{
        char *buf;
        const char *host = [NSLocalizedStringFromTable(@"Host unknown", @"xchat", @"") UTF8String];
        struct User *user;
        int len;

        user = userlist_find (sess, (char *)nick);
        if (user && user->hostname)
                host = strchr (user->hostname, '@') + 1;

        /* this can't overflow, since popup->cmd is only 256 */
        len = strlen (cmd) + strlen (nick) + strlen (allnick) + 512;
        buf = (char *) malloc (len);

        auto_insert (buf, len, (unsigned char *) cmd, 0, 0, (char *)allnick, sess->channel, "",
					 server_get_network (sess->server, TRUE), (char*)host,
                     sess->server->nick, (char *)nick);

        nick_command (sess, buf);

        free (buf);
}

NSString * formatNumber (int n)
{
    if (n < 1000)
        return [NSString stringWithFormat:@"%d", n];
    
    if (n < 1000000)
        return [NSString stringWithFormat:@"%.1fk", (float) n / 1000];
    
    return [NSString stringWithFormat:@"%.1fm", (float) n / 1000000];
}
