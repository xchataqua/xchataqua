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

#import <Cocoa/Cocoa.h>
#import "TabOrWindowView.h"
#import "ColorPalette.h"
#import <regex.h>

@interface ChannelListWin : NSObject
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTableViewDataSource,NSTableViewDelegate>
#endif
{    
    TabOrWindowView	*channel_list_view;
    NSButton		*refresh_button;
    NSButton		*apply_button;
    NSButton		*save_button;
    NSTableView		*item_list;
    NSTextField		*caption_text;
    NSTextField		*regex_text;
    NSTextField		*min_text;
    NSTextField		*max_text;
    NSButton		*regex_channel;
    NSButton		*regex_topic;
    
    struct server	*serv;
    NSMutableArray	*all_items;
    NSMutableArray	*items;
    NSTimer			*timer;
    bool			added;
    int			users_found_count;
    int			users_shown_count;
    bool			topic_checked;
    bool                channel_checked;
    int                 filter_min;
    int                 filter_max;
    regex_t		match_regex;
    bool		regex_valid;
    NSImage		*arrow;
    bool		sort_dir [3];
    ColorPalette	*palette;
}

- (id) initWithServer:(struct server *) server;
- (void) show;
- (void) add_chan_list:(const char *) chan
                 users:(const char *) users 
                 topic:(const char *) topic;
- (void) chan_list_end;

@end
