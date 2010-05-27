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

#import "ColorPalette.h"

//////////////////////////////////////////////////////////////////////

/* CL: these methods are used in the default key bindings, are implemented by Cocoa classes,
       but Apple forgot to include them in the headers. Declare them so the compiler knows
	   what we're calling. */
@interface NSResponder(MissingActionMethods)
- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;
@end

//////////////////////////////////////////////////////////////////////

@class ChatWindow;

@interface XAChatText : NSTextView
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSLayoutManagerDelegate>
#endif
{
    ColorPalette			*palette;
    NSFont					*normal_font;
    NSFont					*bold_font;
    NSMutableParagraphStyle	*style;
    NSRect					line_rect;
    NSRange					word_range;
    int						word_type;
    NSString				*word;
    id						m_event_req_id;
    ChatWindow				*drop_handler;
    bool					shows_sep;
    CGFloat					font_width;
    bool					at_bottom;
	int						num_lines;
}

- (void) print_text:(const char *) text;
- (void) print_text:(const char *) text stamp:(time_t)stamp;
- (void) clear_text;
- (void) setPalette:(ColorPalette *) palette;
- (void) setFont:(NSFont *) font boldFont:(NSFont *) bold_font;
- (void) setDropHandler:(id) drop_handler;

@end
