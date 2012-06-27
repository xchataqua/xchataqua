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

/* CL: these methods are used in the default key bindings, are implemented by Cocoa classes,
       but Apple forgot to include them in the headers. Declare them so the compiler knows
       what we're calling. */
@interface NSResponder(MissingActionMethods)
- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;
@end

#pragma mark -

@class ColorPalette;
@class ChatViewController;

@interface XAChatTextView : NSTextView <NSLayoutManagerDelegate> {
    ColorPalette *_palette;
    NSMutableParagraphStyle *_style;
    NSFont *normalFont;
    NSFont *boldFont;
    NSRect lineRect;
    NSRange     wordRange;
    int         wordType;
    NSString    *word;
    id          mouseEventRequestId;
    ChatViewController  *dropHandler;
    NSSize      fontSize;
    BOOL        atBottom;
    NSInteger   numberOfLines;
    BOOL        pendingEditing;
}

@property(nonatomic, retain) ColorPalette *palette;
@property(nonatomic, retain ) NSMutableParagraphStyle *style;

- (void) printText:(NSString *)text;
- (void) printText:(NSString *)text stamp:(time_t)stamp;
- (void) clearText;
- (void) setFont:(NSFont *)font boldFont:(NSFont *)boldFont;
- (void) setDropHandler:(id)dropHandler;
- (void) updateAtBottom:(NSNotification *) notif;

@end
