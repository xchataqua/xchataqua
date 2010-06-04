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
#import "XAChatTextView.h"
#import "ChatWindow.h"
#import "mIRCString.h"
#import "SG.h"
#import "MenuMaker.h"

// TBD: This is for urlhander_list Should we pass this in?
//extern "C" {
#import "XACommon.h"
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/text.h"
#include "../common/url.h"
//}

#if 0
#define DPrint printf
#else
static void DPrint (const char * x, ...) { };
#endif

//////////////////////////////////////////////////////////////////////

static NSAttributedString *newline;
static NSAttributedString *tab;
static bool jaguar;
static NSCursor *lr_cursor;

//////////////////////////////////////////////////////////////////////

@implementation XAChatTextView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];

    if (!newline)
    {
        newline = [[NSAttributedString alloc] initWithString:@"\n"];
        tab = [[NSAttributedString alloc] initWithString:@"\t"];
        
        // Pre-10.2 MacOS does not support right tabs.  The only way I could
        // figure out if I have Jaguar or better is to check for a method that
        // I know appeared with 10.2.
        
        jaguar = [self respondsToSelector:@selector 
                    (performSelectorOnMainThread:withObject:waitUntilDone:)];
        
        lr_cursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"lr_cursor.tiff"]
                                hotSpot:NSMakePoint (8,8)];
    }
    
    palette = nil;
    normalFont = nil;
    boldFont = nil;
	wordRange = NSMakeRange(NSNotFound, 0);
    wordType = 0;
    word = nil;
    mouseEventRequestId = nil;
    fontWidth = 10;
        
    style = [[NSMutableParagraphStyle alloc] init];
    
    [self setRichText:true];
    [self setEditable:false];

    [self registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    [[self layoutManager] setDelegate:self];

    return self;
}

- (void) awakeFromNib
{
	// Scrolling is achieved by moving the origin of the NSClipView's bounds rectangle. 
	// So you can receive notification of changes to the scroll position by adding yourself
	// as an observer of NSViewBoundsDidChangeNotification for the NSScrollView's NSClipView
	// ([theScrollView contentView]).

	[[NSNotificationCenter defaultCenter] addObserver:self
										    selector:@selector(updateAtBottom:)
											    name:@"NSViewBoundsDidChangeNotification"
											  object:[self superview]];
}

- (void) dealloc
{
    [palette release];
    [normalFont release];
    [boldFont release];
    [style release];
    [word release];
    
    if (mouseEventRequestId)
        [NSApp cancelRequestEvents:mouseEventRequestId];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}

- (void) copy:(id) sender
{
	// Perform the "copy" operation.

	// Setup the pasteboard
	NSPasteboard *pb = [NSPasteboard generalPasteboard];

	NSArray *types = [NSArray arrayWithObjects:
		NSStringPboardType, NSRTFPboardType, nil];
	[pb declareTypes:types owner:self];

	NSRange selection = [self selectedRange];
	NSTextStorage *stg = [self textStorage];
	
	// Get the selected text
	NSAttributedString *attr_string = [stg attributedSubstringFromRange:selection];

	// Plain text version.  Convert tabs to spaces.
	NSString *plain = [attr_string string];
	NSMutableString *pstripped = [plain mutableCopyWithZone:nil];
	[pstripped replaceOccurrencesOfString:@"\t" 
							   withString:@" "
								  options:NSLiteralSearch
								    range:NSMakeRange(0, [pstripped length])];
	
	[pb setString:pstripped forType:NSStringPboardType];
 
	// RTF version.  Remove the hidden text completely.
	NSMutableAttributedString *rstripped = [attr_string mutableCopyWithZone:nil];
	NSRange range = NSMakeRange(0, [rstripped length]);
	while (range.length > 0)
	{
		NSRange ret;
		
		id font = [rstripped attribute:NSFontAttributeName
							   atIndex:range.location 
				 longestEffectiveRange:&ret
							   inRange:range];

		if (font == [mIRCString hiddenFont])
		{
			[rstripped deleteCharactersInRange:ret];
			range.length -= ret.length;
		}
		else
		{
			range.location += ret.length;
			range.length -= ret.length;
		}
	}
	
	NSData *rtfData = [rstripped
						RTFFromRange:(NSMakeRange(0, [rstripped length]))
						documentAttributes:nil];
	[pb setData:rtfData forType:NSRTFPboardType];
}

- (void) setDropHandler:(id) handler
{
    self->dropHandler = handler;
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>) sender
{
    return [self draggingUpdated:sender];
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>) sender
{
    if (!dropHandler /* || [self isHiddenOrHasHiddenAncestor] */)
        return NSDragOperationNone;
        
    NSPasteboard *pboard = [sender draggingPasteboard];

    if (![[pboard types] containsObject:NSFilenamesPboardType])
        return NSDragOperationNone;
        
    return NSDragOperationCopy;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>) info
{
	return [dropHandler processFileDrop:info forUser:nil];
}

- (void) setPalette:(ColorPalette *) new_palette
{
    if (palette)
    	[palette release];
    palette = [new_palette retain];
    
    [self setBackgroundColor:[palette getColor:AC_BGCOLOR]];
}

- (void) setup_margin
{
    CGFloat x = prefs.text_manual_indent_chars * fontWidth;
    NSMutableAttributedString *s = [self textStorage];
	NSRange whole = NSMakeRange (0, [s length]);
    
    [style release];
    style = [[NSMutableParagraphStyle alloc] init];
    [style setTabStops:[[[NSArray alloc] init] autorelease]];

    if (jaguar)
        [style addTabStop:[[[NSTextTab alloc] 
            initWithType:NSRightTabStopType location:x] autorelease]];

    x += fontWidth;

    lineRect.origin.x = floor (x + fontWidth * 2 / 3) - 1;

    x += fontWidth;

    [style setHeadIndent:x];
    for (NSInteger i = 0; i < 30; i ++)
    {
        [style addTabStop:[[[NSTextTab alloc] 
            initWithType:NSLeftTabStopType location:x] autorelease]];
        x += fontWidth;
    }
    
	[s beginEditing];
    [s removeAttribute:NSParagraphStyleAttributeName
        range:whole];
    [s addAttribute:NSParagraphStyleAttributeName
        value:style range:whole];
	[s endEditing];

    [[self window] invalidateCursorRectsForView:self];
    [self setNeedsDisplay:true];
}

- (void) setFont:(NSFont *) new_font boldFont:(NSFont *) new_boldFont
{
    NSFont *old_font = normalFont;
    NSFont *old_boldFont = boldFont;
    
    normalFont = [new_font retain];
    boldFont = [new_boldFont retain];

    NSDictionary *tmp = 
        [NSDictionary dictionaryWithObject:normalFont forKey:NSFontAttributeName];
    NSSize sz = [@"-" sizeWithAttributes:tmp];
    
    fontWidth = sz.width;
    
	if (![new_font isEqual:old_font])	// CL: setup_margin is VERY expensive, don't do it unless necessary
		[self setup_margin];

    // Apply changes
#if 0
// This is too damn slow!!
    NSMutableAttributedString *s = [self textStorage];
    for (NSUInteger i = 0; i < [s length]; )
    {
        NSRange r;
        NSRange limit = NSMakeRange (i, [s length] - i);
        NSDictionary *attr = 
            [s attributesAtIndex:i longestEffectiveRange:&r inRange:limit];
        
        NSFont *of = [attr objectForKey:NSFontAttributeName];
        NSFont *nf = of == old_boldFont ? boldFont : normalFont;
        
        NSMutableDictionary *nattr = [attr mutableCopyWithZone:nil];
        [nattr setObject:nf forKey:NSFontAttributeName];
 
        //if ([attr objectForKey:NSParagraphStyleAttributeName])
            //[nattr setObject:style forKey:NSParagraphStyleAttributeName];

        [s setAttributes:nattr range:r];
        
        i += r.length;
    }
#endif
    [old_font release];
    [old_boldFont release];
}

- (void) clear_lines_really
{		
	NSTextStorage *stg = [self textStorage];

	[stg beginEditing];

	while (numberOfLines > prefs.max_lines)
	{
		NSString *s = [stg mutableString];
		NSRange firstLine = [s lineRangeForRange:NSMakeRange(0, 0)];
		if (NSEqualRanges(firstLine, NSMakeRange(0, [s length])))
			break;
		[stg deleteCharactersInRange:firstLine];
		numberOfLines--;
	}
	
	[stg endEditing];
}

- (void) clear_lines
{
	if (prefs.max_lines == 0)
		return;

	int threshhold = prefs.max_lines + prefs.max_lines * 0.1;
	if (numberOfLines < threshhold)
		return;
	
	// Clearing lines while adding lines seesm to cause strange artifacting.
	// We'll give layout a chance before clearing.. 
	[self performSelector:@selector(clear_lines_really) withObject:nil afterDelay:0.5];
}

- (void) print_line:(char *) text
                len:(int) len
			  stamp:(time_t) stamp
{
    NSMutableAttributedString *stg = [self textStorage];    

	[stg beginEditing];
	
    char buff [128];  // 128 = large enough for timestamp
    char *prepend = buff;

    if (prefs.timestamp)
    {
        prepend += strftime (buff, sizeof (buff), prefs.stamp_format, localtime (&stamp));
    }

    char *tmp = text;
    char *end = tmp + len;

    if (prefs.indent_nicks)
    {
        if (jaguar)
            *prepend++ = '\t';

        tmp = strchr (text, '\t');
        if (tmp)
            tmp ++;
        else
            *prepend++ = '\t';
    }    

    *prepend = 0;
    
    while (tmp && *tmp && tmp < end)	// Blast remaining tabs
    {
        if (*tmp == '\t')
            *tmp = ' ';
        tmp ++;
    }

    mIRCString *pre_str = [mIRCString stringWithUTF8String:buff
                                                         len:prepend - buff
                                                     palette:palette
                                                        font:normalFont
                                                    boldFont:boldFont];

    mIRCString *msgString = [mIRCString stringWithUTF8String:text
                                                         len:len
                                                     palette:palette
                                                        font:normalFont
                                                    boldFont:boldFont];
    
    [pre_str appendAttributedString:msgString];
    [pre_str appendAttributedString:newline];

    [pre_str addAttribute:NSParagraphStyleAttributeName
                value:style range:NSMakeRange (0, [pre_str length])];

    [stg appendAttributedString:pre_str];
	
	numberOfLines ++;
	
	[self clear_lines];

	[stg endEditing];
}

- (void) print_line:(char *) text
                len:(int) len
{
	[self print_line:text len:len stamp:time(NULL)];
}

- (void) printText:(NSString *)const_text
{
	[self printText:const_text stamp:time(NULL)];
}

- (void) printText:(NSString *)aText stamp:(time_t)stamp
{
    NSMutableAttributedString *stg = [self textStorage];    
    // TBD: Yuck!! Cast away const.  fe-gtk does this so it must be ok..
	const char *const_text = [aText UTF8String];
    char *text = (char *)const_text;

    char *last_text = text;
    int len = 0;

	[stg beginEditing];

    // split the text into separate lines
    while  (*text)
    {
        switch (*text)
        {
            case '\n':
                [self print_line:last_text len:len];
                text++;
                last_text = text;
                len = 0;
                break;
            case '\007':                        
                *text = ' ';
                if (!prefs.filterbeep) 
                    NSBeep ();
            default:
                text++;
                len++;
        } 
    }

    if (len)
        [self print_line:last_text len:len];

	[stg endEditing];
}

- (void) clearText
{
	// FIXME: rough solution to solve initialization with scrollToDocumentEnd 1/3
	numberOfLines = 50;
    [self setString:@"\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"];
}

- (void) layoutManager:(NSLayoutManager *) aLayoutManager 
    didCompleteLayoutForTextContainer:(NSTextContainer *) aTextContainer
    atEnd:(BOOL) flag
{
	DPrint("didCompleteLayoutForTextContainer %d\n", atBottom);
    if (atBottom)
	{
#if 1
        [self scrollPoint:NSMakePoint(0, NSMaxY([self bounds]))];
#else
		NSClipView *clipView = [self superview];
		if (![clipView isKindOfClass:[NSClipView class]]) return;
		[clipView scrollToPoint:[clipView constrainScrollPoint:NSMakePoint(0,[self frame].size.height)]];
		[[clipView superview] reflectScrolledClipView:clipView];
#endif
	}
}

- (void) updateAtBottom:(NSNotification *) notif
{
	NSClipView *clipView = (NSClipView *)[self superview];
	NSRect documentRect = [clipView documentRect];
	NSRect clipRect = [clipView documentVisibleRect];
	
	CGFloat dmax = NSMaxY(documentRect);
	CGFloat cmax = NSMaxY(clipRect);

	atBottom = dmax == cmax;

	DPrint("Update at bottom %d\n", atBottom);
}

- (void) viewDidMoveToWindow
{
    if (mouseEventRequestId)
        [NSApp cancelRequestEvents:mouseEventRequestId];

    [[self window] setAcceptsMouseMovedEvents:true];

    mouseEventRequestId = [NSApp requestEvents:NSMouseMoved
			      forWindow:[self window]
                                forView:nil
                               selector:@selector (myMouseMoved:)
                                 object:self];

    // Docs say that characterIndexForPoint will return -1 for a point that is out of range.
    // Practice says otherwise.  
	// 24 Jan 06 - SBG
	// This crashes when joining channels with 1300+ users... it's useless anyway.
    //illegal_index = [self characterIndexForPoint:NSMakePoint (-100,-100)];
}

- (void) clear_hot_word
{
    if (word)
    {
		NSTextStorage *stg = [self textStorage];
		if (NSMaxRange(wordRange) <= [stg length])
			[stg removeAttribute:NSUnderlineStyleAttributeName 
				   range:wordRange];
		[word release];
		word = nil;
		wordRange = NSMakeRange(NSNotFound, 0);
    }
}

- (void) resetCursorRects
{
    NSRect b = [self visibleRect];
    
    lineRect.origin.y = b.origin.y;
    lineRect.size.width = 3;
    lineRect.size.height = b.size.height;

    [self addCursorRect:lineRect cursor:lr_cursor];
}

/* CL: use our real session if possible, otherwise fall back on current_sess */
- (session *)currentSession
{
	ChatWindow *chatWindow = (ChatWindow *)[self delegate];
	if (![chatWindow isKindOfClass:[ChatWindow class]]) chatWindow = nil;
	return (chatWindow ? [chatWindow session] : current_sess);
}

- (void) do_link
{
    const char *cmd = NULL;
    
    switch (wordType)
    {
        case WORD_HOST:
        case WORD_EMAIL:
        case WORD_URL:
            cmd = prefs.urlcommand;
            break;
            
        case WORD_NICK:
            cmd = prefs.nickcommand;
            break;

        case WORD_CHANNEL:
            cmd = prefs.channelcommand;
            break;
        
        default:
            return;
    }

    nick_command_parse ([self currentSession], (char *) cmd, (char *) [word UTF8String], (char *) [word UTF8String]);
    
    [self clear_hot_word];
}

- (void) mouseDown:(NSEvent *) theEvent
{
    NSPoint point = [theEvent locationInWindow];
    NSPoint where = [self convertPoint:point fromView:nil];

    if (!NSPointInRect (where, lineRect))
    {
        [super mouseDown:theEvent];	// Superclass will block until mouseUp
        if (word && [self selectedRange].length == 0 && [self currentSession])
            [self do_link];
        return;
    }

    int margin = prefs.text_manual_indent_chars;
    
    for (;;)
    {
        NSEvent *theEvent = [[self window] nextEventMatchingMask:NSLeftMouseUpMask |
                                                                 NSLeftMouseDraggedMask];

        if ([theEvent type] == NSLeftMouseUp)
            break;
        
        NSPoint mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        int new_margin = (int)(mouseLoc.x / fontWidth) - 1;
        
        if (new_margin > 2 && new_margin < 50 && new_margin != margin)
        {
            margin = new_margin;
            prefs.text_manual_indent_chars = margin;
            [self setup_margin];
        }
    }
}

- (NSMenu *) menuForEvent:(NSEvent *) theEvent
{    
	session *sess = [self currentSession];
	
    NSRange sel = [self selectedRange];
    if (sel.location != NSNotFound && sel.length > 0)
    {
        NSMenu *m = [[super menuForEvent:theEvent] copyWithZone:nil];

        NSString *text = [[[self textStorage] string] substringWithRange:sel];

        NSMenu *url_menu = [[MenuMaker defaultMenuMaker] menuForURL:text inSession:sess];
        NSMenuItem *i = [[NSMenuItem alloc] initWithTitle:@"URL Actions" action:nil keyEquivalent:@""];
        [i setSubmenu:url_menu];
        [m addItem:i];

        NSMenu *nick_menu = [[MenuMaker defaultMenuMaker] menuForNick:text inSession:sess];
        i = [[NSMenuItem alloc] initWithTitle:@"Nick Actions" action:nil keyEquivalent:@""];
        [i setSubmenu:nick_menu];
        [m addItem:i];

        return m;
    }
        
    if (word)
    {
        [[NSRunLoop currentRunLoop] performSelector:@selector (clear_hot_word)
											 target:self argument:nil order:1
											  modes:[NSArray arrayWithObject:NSDefaultRunLoopMode]];

        switch (wordType)
        {
            case WORD_HOST:
            case WORD_URL:
                return [[MenuMaker defaultMenuMaker] menuForURL:word inSession:sess];
                
            case WORD_NICK:
                return [[MenuMaker defaultMenuMaker] menuForNick:word inSession:sess];
				
            case WORD_CHANNEL:
                return [[MenuMaker defaultMenuMaker] menuForChannel:word inSession:sess];
                
            case WORD_EMAIL:
                return [[MenuMaker defaultMenuMaker] menuForURL:[NSString stringWithFormat:@"mailto:%@", word] inSession:sess];
        }
    }
    
    // TBD:
    // if (sess->type == dialog)
    //   return [[AquaChat sharedAquaChat] nickMenuForServer:current_sess->server
    //                            nick:[NSString stringWithUTF8String:sess->channel]];

    return [super menuForEvent:theEvent];
}

- (int)checkHotwordInRange:(NSRangePointer)range
{
	session *sess = [self currentSession];
	NSString *text = [[self textStorage] string];

	for (;;)
	{
		char *cword = (char *)[[text substringWithRange:*range] UTF8String];
		int len = strlen(cword);// range->length;

		// Let common have first crack at it.
		int ret = url_check_word (cword, len);	/* common/url.c */
		
		// If we get something from common, double check a few things..
		if (ret)
		{
			// Check for @#channel, and chop off the @ (or any nick prefix)
			if (ret == WORD_CHANNEL && strchr (sess->server->nick_prefixes, cword[0]))
			{
				range->location++;
				range->length--;
			}
			
			return ret;
		}
		
		//
		// Else, check for stuff that common doesn't.
		//
		
		// @nick
		if (strchr (sess->server->nick_prefixes, cword[0]) && userlist_find (sess, cword+1))
		{
			range->location++;
			range->length--;
			return WORD_NICK;
		}
		
		// Just plain nick
		if (userlist_find (sess, cword))
			return WORD_NICK;

		// What does this do?
		//if (sess->type == SESS_DIALOG)
		//	return WORD_DIALOG;
		
		// Check for words surrounded in brackets.
		// Narrow the range and try again.
		if ((*cword == '(' && cword[len - 1] == ')') ||
			(*cword == '[' && cword[len - 1] == ']') ||
			(*cword == '{' && cword[len - 1] == '}') ||
			(*cword == '<' && cword[len - 1] == '>') ||
			(!isalpha(*cword) && *cword == cword[len - 1]))
		{
			if (range->length < 3) break;	/* check this before subtracting; length is unsigned */
			range->location++;
			range->length -= 2;
			continue;
		}
		
		return 0;
	}
	
	// Make compiler happy
	return 0;
}

- (BOOL) myMouseMoved:(NSEvent *) theEvent
{
    // TBD: The use of 'superview' below assumes we live in a scroll view
    //      which is not always true.
    if (![self window] || ![SGApplication event:theEvent inView:[self superview]])
    {
    	[self clear_hot_word];
		return NO;
    }

    NSPoint point = [theEvent locationInWindow];
    NSPoint where = [[theEvent window] convertBaseToScreen:point];
    NSUInteger idx = [self characterIndexForPoint:where];

    NSTextStorage *stg = [self textStorage];

    if (word)
    {
		if (NSLocationInRange(idx, wordRange))
            return NO;
    	[self clear_hot_word];
    }

    NSString *s = [stg string];
    NSUInteger slen = [s length];

    if (slen == 0)
        return NO;
		
	if (slen == idx)
		return NO;

    if (isspace ([s characterAtIndex:idx]))
        return NO;
    
    // From this point, we know we have a selection...
    
    unsigned int word_start = idx;
    unsigned int word_stop = idx;
    
    while (word_start > 0 && !isspace ([s characterAtIndex:word_start-1]))	/* CL: maybe this should be iswspace, or a test using whitespaceAndNewlineCharacterSet? */
        word_start --;
    
    while (word_stop < slen && !isspace ([s characterAtIndex:word_stop+1]))
        word_stop ++;

    wordRange = NSMakeRange (word_start, word_stop - word_start + 1);

	wordType = [self checkHotwordInRange:&wordRange];
/*    wordType = my_text_word_check (s, &word_start, &word_stop);	*/

    if (wordType <= 0)
        return NO;

    word = [[s substringWithRange:wordRange] retain];
    
    [stg addAttribute:NSUnderlineStyleAttributeName 
                value:[NSNumber numberWithInt:NSSingleUnderlineStyle]
                range:wordRange];
                
    return NO;
}

- (void) keyDown:(NSEvent *) theEvent
{
    // We got a key event, and but we don't want it.
    // Set the first responder, and forward the event..
    // .. just make sure we don't recurse.
    [[self window] selectNextKeyView:self];
    if ([[self window] firstResponder] != self)
        [[[self window] firstResponder] keyDown:theEvent];
}

#if 1
- (void) drawRect:(NSRect) aRect
{
    if (!prefs.show_separator || !prefs.indent_nicks)
    {
        [super drawRect:aRect];
        return;
    }
    
    [super drawRect:aRect];
    [[palette getColor:AC_FGCOLOR] set];
    [[NSGraphicsContext currentContext] setShouldAntialias:false];
    NSBezierPath *p = [NSBezierPath bezierPath];
    [p setLineWidth:1];
    [p moveToPoint:NSMakePoint (lineRect.origin.x + 1, aRect.origin.y)];
    [p lineToPoint:NSMakePoint (lineRect.origin.x + 1, aRect.origin.y + aRect.size.height)];
    [p stroke];
}
#endif

@end
