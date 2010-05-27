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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 */

#import <Cocoa/Cocoa.h>
#import "XAChatText.h"
#import "TabOrWindowView.h"
#import "SG.h"

@class MySplitView;

@interface ChatWindow : NSObject
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTextViewDelegate,NSTextFieldDelegate,NSTableViewDataSource,NSTableViewDelegate,NSSplitViewDelegate>
#endif
{
    TabOrWindowView	*chat_view;
    XAChatText	*chat_text;
    NSTextField	*input_text;
    NSTextField	*nick_text;
    NSTableView	*userlist_table;
    NSScrollView *chat_scroll;

    NSButton	*t_button;
    NSButton	*n_button;
    NSButton	*s_button;
    NSButton	*i_button;
    NSButton	*p_button;
    NSButton	*m_button;
    NSButton	*b_button;
    NSButton	*l_button;
    NSButton	*k_button;
	NSButton	*C_button;
	NSButton	*N_button;
	NSButton	*u_button;
	
    NSTextField	*limit_text;
    NSTextField	*key_text;

    NSImageView	*op_voice_icon;
    NSTextField	*userlist_stats_text;
    NSTextField	*topic_text;
    NSTextField	*chan_text;
    SGHBoxView	*top_box;
    MySplitView	*middle_box;
    SGRowColView *button_box;
    NSProgressIndicator *progress_indicator;
    NSControl *throttle_indicator;
    NSControl *lag_indicator;
    NSPopUpButton	*sess_menu;
    
    NSMutableArray *userlist;
    NSMenuItem * userlist_menu;
    struct User * userlist_menu_curuser;
/* CL */
	CGFloat maxNickWidth;
	CGFloat maxHostWidth;
	CGFloat maxRowHeight;
/* CL end */
    
	int		circular_completion_idx;
	
    struct session *sess;
}

- (id) initWithSession:(struct session *)sess;
- (void) insertText:(NSString *) s;
- (void) prefsChanged;
- (void) save_buffer:(NSString *) fname;
- (void) highlight:(NSString *) string;
- (NSWindow *) window;
- (TabOrWindowView *) view;
- (BOOL) processFileDrop:(id <NSDraggingInfo>) info forUser:(const char *) nick;
- (NSMenu *)menuForEvent:(NSEvent *)theEvent rowIndexes:(NSIndexSet *)rows;
- (session *)session;

// Front end methods
- (void) close_window;
- (void) clear:(int)lines;
- (void) clear_channel;
- (void) print_text:(const char *)text;
- (void) print_text:(const char *)text stamp:(time_t)stamp;
- (void) set_nick;
- (void) set_title;
- (void) set_hilight;
- (void) userlist_insert:(struct User *)user row:(int)row select:(bool)select;
- (bool) userlist_remove:(struct User *)user;
- (void) userlist_move:(struct User *)user row:(int)row;
- (void) userlist_update:(struct User *)user;
- (void) userlist_numbers;
- (void) userlist_clear;
- (void) userlist_rehash:(struct User *) user;
- (void) userlist_select_names:(char **)names clear:(int)clear scroll_to:(int)scroll_to;
- (void) channel_limit;
- (void) mode_buttons:(char)mode sign:(char)sign;
- (void) progressbar_start;
- (void) progressbar_end;
- (void) set_throttle;
- (void) set_channel;
- (void) set_nonchannel:(bool)state;
- (void) set_topic:(const char *)topic;
- (void) setup_userlist_buttons;
- (void) setup_dialog_buttons;
- (void) set_lag:(NSNumber *) percent;
- (void) set_tab_color:(int) col flash:(bool) flash;
- (void) setInputTextPosition:(int) pos delta:(bool) delta;
- (int) getInputTextPosition;
- (void) setInputText:(const char *) xx;
- (const char *) getInputText;
- (void) userlist_set_selected;
- (void) do_userlist_command:(const char *) cmd;
- (void) lastlogIntoWindow:(ChatWindow *)logWin key:(char *)ckey;

@end
