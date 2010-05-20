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
#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1050
#import <ShortcutRecorder/ShortcutRecorder.h>
#endif

enum
{
    MYPREF_STRING,
    MYPREF_INT,
    MYPREF_MENU
};

struct my_pref
{
    id	       item;
    void      *pref;
    int        type;
};

@interface PrefsController : NSObject
{
    NSTabView	*tab_view;
#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1050
	SRRecorderCell *tab_left_sr;
	SRRecorderCell *tab_right_sr;
#endif
    NSWindow *prefs_window;
    NSColorWell *colors [41];
	NSMutableArray *sounds;
	NSMutableArray *sound_events;
	id  perform_always_check;
	id  sounds_table;
    id	category_list;
    id	content_box;

    id	announce_away_check;
    id	auto_open_dcc_chat_list_check;
    id	auto_open_dcc_receive_list_check;
    id	auto_open_dcc_send_list_check;
    id	auto_reconnect_delay_text;
    id	auto_unmark_away_check;
    id	tab_complete_check;
    id	away_message_text;
    id	beep_on_channel_messages_check;
    id	beep_on_private_check;
    id	bind_address_text;
    id	channel_command_text;
    id	colored_nicks_check;
    id	convert_spaces_check;
    id	dcc_address_text;
    id	doubleclick_command_text;
    id	down_dir_text;
    id	enable_logging_check;
    id	extra_highlight_words_text;
    id	first_dcc_send_port_text;
    id	font_text;
    id	get_my_ip_check;
    id	indent_nicks_check;
    id	interpret_nnn_check;
    id	insert_timestamps_check;
    id	last_dcc_send_port_text;
    id	log_filename_mask_text;
    id	log_timestamp_format_text;
    id	nick_command_text;
    id	nick_completion_text;
    id	notices_tab_check;
    id	open_channels_in_menu;
    id	open_dialogs_in_menu;
    id	open_utilities_in_menu;
    id	part_message_text;
	id  part_on_sleep_check;
    id	pop_new_tabs_check;
    id	proxy_port_text;
    id	proxy_server_text;
    id	proxy_type_menu;
    id	quit_message_text;
    id	raw_modes_check;
    id	save_nicknames_check;
    id	server_tab_check;
    id	show_away_once_check;
    id	show_channel_mode_buttons_check;
    id	show_hostnames_check;
    id	show_tab_at_menu;
    id  spell_check_check;
    id	strip_mirc_color_check;
    id  suffix_completion_check;
    id	time_stamp_format_text;
    id	time_stamp_text_check;
    id	hide_tab_close_check;
    id	show_separator_check;
    id	url_command_text;
    id	use_text_box_font_check;
    id	userlist_buttons_enabled_check;
    id	userlist_sort_menu;
    id  trans_check;
    id  trans_slider;
    id  bounce_check;
	id  bounce_other_check;
    id  badge_private_check;
	id  badge_other_check;
    id	whois_on_notify_check;
    id  hide_join_part_check;
    id  identd_check;
    id  interpret_percent_color;
    id  dcc_send_menu;
    id  dcc_chat_menu;
    id  auto_rejoin_check;
    id  auto_reconnect_check;
    id  never_give_up_check;
    id  auto_dialog_check;
    id  hide_userlist_check;
    id  checkvers_check;
	id  sleep_message_text;
	id  gui_metal_check;
    id  scrolling_completion_check;
	id  charset_text;
	id  completed_downloads_text;
	id  max_lines_text;
	id  auto_away_check;
	id  auto_away_text;
	id  nick_complete_sort_menu;
	
    my_pref     my_prefs [86];
}

- (void) show;

@end
