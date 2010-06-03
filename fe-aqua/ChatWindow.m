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
#import "ChatWindow.h"
#import "mIRCString.h"
#import "MenuMaker.h"

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/server.h"
#include "../common/util.h"
#include "../common/fe.h"
#include "XACommon.h"

//////////////////////////////////////////////////////////////////////

static void size_prefs (NSWindow *w)
{
    NSRect r = [w frame];
    prefs.mainwindow_width = (int) r.size.width;
    prefs.mainwindow_height = (int) r.size.height;
}

static void location_prefs (NSWindow *w)
{
    NSRect r = [w frame];
    prefs.mainwindow_left = (int) r.origin.x;
    prefs.mainwindow_top = (int) r.origin.y;		// It's really the bottom?
}

//////////////////////////////////////////////////////////////////////

@interface OneCompletion : NSObject
{
	NSString *value;
}

+ (id) completionWithValue:(const char *) val;
- (id) initWithValue:(const char *) val;

@end

@implementation OneCompletion

+ (id) completionWithValue:(const char *) val
{
	return [[[OneCompletion alloc] initWithValue:val] autorelease];
}

- (id) initWithValue:(const char *) val
{
	self = [super init];
	self->value = [[NSString stringWithUTF8String:val] retain];
	return self;
}

- (void) dealloc
{
	[value release];
	[super dealloc];
}

- (NSString *) stringValue
{
	return value;
}

- (NSString *) description
{
	return value;
}

- (NSComparisonResult) compare:(id) aCompletion
{
	OneCompletion *other = (OneCompletion *) aCompletion;
	
	//TODO rfc compare
	// for me it's not important (bug is around [ { and others symbols which in RFC interprented as one)
	// i think it's slow convert to utf8 compare with xchat's one and revert to ucs2
	return [self->value compare:other->value options:NSCaseInsensitiveSearch];
}

@end

//////////////////////////////////////////////////////////////////////

@interface OneNickCompletion : OneCompletion
{
	time_t lasttalk;
}

+ (id) nickWithNick:(const char *) nick lasttalk:(time_t)lt;
- (id) initWithNick:(const char *) nick lasttalk:(time_t)lt;

@end

@implementation OneNickCompletion

+ (id) nickWithNick:(const char *) the_nick lasttalk:(time_t)lt
{
	return [[[OneNickCompletion alloc] initWithNick:the_nick lasttalk:lt] autorelease];
}

- (id) initWithNick:(const char *) the_nick lasttalk:(time_t) lt
{
	self = [super initWithValue:the_nick];
	self->lasttalk=lt;
	return self;
}

- (NSComparisonResult) compare:(id) aNick
{
	OneNickCompletion *other = (OneNickCompletion *) aNick;
	
	switch (prefs.completion_sort)
	{
		case 1:
		{
			if (other->lasttalk == self->lasttalk)
				return NSOrderedSame;
				
			if (other->lasttalk < self->lasttalk)
				return NSOrderedAscending;
				
			return NSOrderedDescending;
		}
		
		case 0:
		default:
			return [super compare:aNick];
	}
}

@end

//////////////////////////////////////////////////////////////////////

@interface MySplitView : NSSplitView
{
}
@end

@implementation MySplitView

- (int) get_split_pos
{
	NSView *second = [[self subviews] objectAtIndex:1];
	NSRect second_rect = [second frame];
	return (int) second_rect.size.width;
}

- (void) set_split_pos:(int) position
{
	NSView *first = [[self subviews] objectAtIndex:0];
	NSView *second = [[self subviews] objectAtIndex:1];

	[first setPostsFrameChangedNotifications:NO];
	[second setPostsFrameChangedNotifications:NO];

	NSView *ulist = [[self subviews] objectAtIndex:1];
	NSRect ulist_rect = [ulist frame];
	ulist_rect.size.width = position;
	[ulist setFrame:ulist_rect];
	
	[self adjustSubviews];
	
	[self setNeedsDisplay:YES];
}

- (NSRect) dividerRect
{
	NSView *first = [[self subviews] objectAtIndex:0];

	NSRect first_rect = [first frame];
	first_rect.origin.x += first_rect.size.width;
	first_rect.size.width = [self dividerThickness];
	
	return first_rect;
}

- (void) mouseDown:(NSEvent *) theEvent
{
	NSPoint where = [theEvent locationInWindow];
	where = [self convertPoint:where fromView:nil];
	if (! NSPointInRect(where, [self dividerRect]))
	{		
		[super mouseDown:theEvent];
		return;
	}
	
	if ([theEvent clickCount] == 2)
	{
		if ([self get_split_pos] > 0)
			[self set_split_pos:0];
		else
			[self set_split_pos:prefs.paned_pos];
	}
	else
	{
		int old_pos = [self get_split_pos];
		[super mouseDown:theEvent];
		int new_pos = [self get_split_pos];

		// Only set the pref if we moved.  Double click might have moved the pane
		// but not changed the prefs.  Lets not muck the pref when we double click again.
		
		if (old_pos != new_pos)
		{
			if (new_pos < 10 && new_pos > 0)
			{
				new_pos = 0;
				[self set_split_pos:0];
				if (old_pos == 0)		// It didn't really move, so put it back
					return;				// and don't change prefs.
			}
			
			prefs.paned_pos = new_pos;
			prefs.hideuserlist = prefs.paned_pos == 0;
		}
	}
}

- (void) adjustSubviews 
{
	NSView *first = [[self subviews] objectAtIndex:0];
	NSView *second = [[self subviews] objectAtIndex:1];

	[first setPostsFrameChangedNotifications:NO];
	[second setPostsFrameChangedNotifications:NO];
	
	NSRect total_rect = [self bounds];
	NSRect first_rect = [first frame];
	NSRect second_rect = [second frame];
	
	second_rect.origin.x = total_rect.size.width - second_rect.size.width;
	second_rect.origin.y = 0;
	second_rect.size.height = total_rect.size.height;
	first_rect.origin.x = 0;
	first_rect.origin.y = 0;
	first_rect.size.width = second_rect.origin.x - [self dividerThickness];
	first_rect.size.height = total_rect.size.height;
	
	[first setFrame:first_rect];
	[second setFrame:second_rect];

	[first setPostsFrameChangedNotifications:YES];
	[second setPostsFrameChangedNotifications:YES];
}

@end

//////////////////////////////////////////////////////////////////////

@interface UserlistButton : NSButton
{
    struct popup *p;
}

- (id) initWithPopup:(struct popup *) p;
- (struct popup *) getPopup;

@end

@implementation UserlistButton

- (id) initWithPopup:(struct popup *) pop
{
    [super init];

    self->p = pop;

    [self setButtonType:NSMomentaryPushButton];
    [self setTitle:[NSString stringWithUTF8String:p->name]];
    [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [[self cell] setControlSize:NSSmallControlSize];
    [self setImagePosition:NSNoImage];
	if (prefs.guimetal)
		[self setBezelStyle:NSTexturedSquareBezelStyle];
	else
		[self setBezelStyle:NSShadowlessSquareBezelStyle];
    [self sizeToFit];

    return self;
}

- (struct popup *) getPopup
{
    return p;
}

@end

//////////////////////////////////////////////////////////////////////

/* CL */
@interface MyUserList : NSTableView
/* CL end */
{
}
@end

@implementation MyUserList

- (void)rightMouseDown:(NSEvent *)theEvent
{
	NSInteger clickedRow = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
	if (![self isRowSelected:clickedRow])
		[self selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
	[super rightMouseDown:theEvent];
}

/* CL: let the delegate handle this */
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
	NSIndexSet *selectedRows = [self selectedRowIndexes];
	if ([selectedRows count] == 0) return [super menuForEvent:theEvent];
	id delegate = [self delegate];
	if (delegate && [delegate respondsToSelector:@selector(menuForEvent:rowIndexes:)])
		return [(ChatWindow *)delegate menuForEvent:theEvent rowIndexes:selectedRows];
	else return [super menuForEvent:theEvent];
}

@end

//////////////////////////////////////////////////////////////////////

@interface OneUser : NSObject
{
  @public
    id		nick;		// NSString or NSAttributedString
    NSString	*host;
    struct User	*user;
/* CL */
	NSSize nickSize;
	NSSize hostSize;
/* CL end */
}

- (id) initWithUser:(struct User *) u;
- (void) rehash;
- (struct User *) getUser;
/* CL */
- (void) cacheSizesForTable: (NSTableView *) table;
/* CL end */

@end

@implementation OneUser

- (id) initWithUser:(struct User *) u
{
    self->user = u;
    nick = nil;
    host = nil;
/* CL */
	nickSize = NSZeroSize;
	hostSize = NSZeroSize;
/* CL end */
    
    [self rehash];

    return self;
}

- (NSString *)nick
{
	return [NSString stringWithUTF8String:user->nick];
}

- (void) rehash
{
    [nick release];
    [host release];

    NSString *s = [NSString stringWithUTF8String:user->nick];

    if (user->away)
    {
        ColorPalette *p = [[AquaChat sharedAquaChat] palette];
        NSDictionary *attr = [NSDictionary 
            dictionaryWithObject:[p getColor:AC_AWAY_USER]
            forKey:NSForegroundColorAttributeName];
        nick = [[NSAttributedString alloc] initWithString:s attributes:attr];
    }
    else
    {
        nick = [[NSAttributedString alloc] initWithString:s];
    }
    
    host = [[NSString stringWithUTF8String:user->hostname ? user->hostname : ""] retain];
}

- (void) dealloc
{
    [nick release];
    [host release];
    [super dealloc];
}

- (struct User *) getUser
{
    return user;
}

/* CL */
- (void) cacheSizesForTable: (NSTableView *) table
{
	NSArray *columns = [table tableColumns];
	/* nickname column */
	id dataCell = [[columns objectAtIndex:1] dataCell];
	[dataCell setAttributedStringValue: nick];
	nickSize = [dataCell cellSize];
	
//	NSLayoutManager * layoutManager = [[[NSLayoutManager alloc] init] autorelease];
//	NSTextContainer * textContainer = [[[NSTextContainer alloc] init] autorelease];
//	NSTextStorage   * textStorage   = [[[NSTextStorage alloc] initWithAttributedString:nick] autorelease];
//	
//	[layoutManager addTextContainer:textContainer];
//	[textStorage addLayoutManager:layoutManager];
//
//	(void) [layoutManager glyphRangeForTextContainer:textContainer];
//	
//	nickSize=[layoutManager usedRectForTextContainer:textContainer].size;
	
	/* host column */
    if (prefs.showhostname_in_userlist) {
		dataCell = [[columns objectAtIndex:2] dataCell];
		[dataCell setObjectValue: host];
		hostSize = [dataCell cellSize];
	}
}
/* CL end */

@end

//////////////////////////////////////////////////////////////////////

static NSImage *red_image;
static NSImage *purple_image;
static NSImage *green_image;
static NSImage *blue_image;
static NSImage *yellow_image;
static NSImage *empty_image;

//////////////////////////////////////////////////////////////////////

@implementation ChatWindow

- (id) initWithSession:(struct session *) the_sess
{
    [super init];
    
    self->sess = the_sess;
    self->userlist = [[NSMutableArray arrayWithCapacity:0] retain];
    
    if (!green_image)
    {
		red_image = [[NSImage imageNamed:@"red.tiff"] retain];
		purple_image = [[NSImage imageNamed:@"purple.tiff"] retain];
		green_image = [[NSImage imageNamed:@"green.tiff"] retain];
		blue_image = [[NSImage imageNamed:@"blue.tiff"] retain];
		yellow_image = [[NSImage imageNamed:@"yellow.tiff"] retain];
		empty_image = [[NSImage alloc] initWithSize:NSMakeSize (1,1)];
    }
    
    [NSBundle loadNibNamed:@"ChatWindow" owner:self];

    return self;
}

- (void) dealloc
{
    [chat_view release];		// TBD: Anything else need to get released here?
    [userlist release];
    [super dealloc];
}

- (void) save_buffer:(NSString *) fname
{
    [[[chat_text textStorage] string] writeToFile:fname atomically:true encoding:NSUTF8StringEncoding error:NULL];
}

- (void) highlight:(NSString *) string
{
    NSRange from = [chat_text selectedRange];

    if (from.location == NSNotFound)
        from.location = 0;
    else
        from.location += from.length;
        
    from.length = [[chat_text textStorage] length] - from.location;
    
    NSStringCompareOptions mask = NSCaseInsensitiveSearch;
    
    NSRange where = [[[chat_text textStorage] string] rangeOfString:string options:mask range:from];
    
    if (where.location == NSNotFound)
    {
        if (from.location == 0)
            return;
        from.length = from.location;
        from.location = 0;
        where = [[[chat_text textStorage] string] rangeOfString:string options:mask range:from];

        if (where.location == NSNotFound)
            return;
    }
    
    [chat_text setSelectedRange:where];
    [chat_text scrollRangeToVisible:where];
	//[chat_text updateAtBottom];
}

- (NSWindow *) window
{
    return [chat_view window];
}

- (TabOrWindowView *) view
{
	return chat_view;
}

- (session *)session
{
	return sess;
}

- (void) clean_top_box
{
    // The dialog and channel mode buttons share the top box with the
    // topic text.  Remove everything but the topic text and the spacer.

    CGFloat x = [topic_text frame].origin.x;
    
    for (unsigned int i = 0; i < [[top_box subviews] count]; )
    {
        NSView *view = [[top_box subviews] objectAtIndex:i];
        if (view == topic_text || [view frame].origin.x < x)
            i ++;
        else
            [view removeFromSuperviewWithoutNeedingDisplay];
    }

	// This is just to be safe
	t_button = nil;
	n_button = nil;
	s_button = nil;
	i_button = nil;
	p_button = nil;
	m_button = nil;
	b_button = nil;
	l_button = nil;
	k_button = nil;
	C_button = nil;
	N_button = nil;
	u_button = nil;
	limit_text = nil;
	key_text = nil;
}

- (void) do_dialog_button:(id) sender
{
    /* the longest cmd is 12, and the longest nickname is 64 */
    char buf[128];

    struct popup *p = [(UserlistButton *) sender getPopup];
    auto_insert (buf, sizeof (buf), (unsigned char *)p->cmd, 0, 0, "", "", "", "", "", "", sess->channel);
    handle_command (sess, buf, TRUE);
}

- (void) setup_dialog_buttons
{
    [self clean_top_box];

    for (GSList *list = dlgbutton_list; list; list = list->next)
    {
        struct popup *p = (struct popup *) list->data;
        
        UserlistButton *b =
			[[[UserlistButton alloc] initWithPopup:p] autorelease];

        [b setAction:@selector (do_dialog_button:)];
        [b setTarget:self];

        [top_box addSubview:b];
    }
}

- (NSButton *) make_mode_button:(char) flag
		       selector:(SEL) selector
{
    NSButton *b = [[NSButton alloc] init];

    [b setButtonType:NSPushOnPushOffButton];
    [b setTitle:[NSString stringWithFormat:@"%c", toupper (flag)]];
    [[b cell] setControlSize:NSSmallControlSize];
    [b setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [b setImagePosition:NSNoImage];
	if (prefs.guimetal)
		[b setBezelStyle:NSTexturedSquareBezelStyle];
	else
		[b setBezelStyle:NSShadowlessSquareBezelStyle];
    [b sizeToFit];
    [b setTag:flag];
    [b setAction:selector];
    [b setTarget:self];
    
    NSSize sz = [b frame].size;
    sz.height = [topic_text frame].size.height;
    [b setFrameSize:sz];

    [top_box addSubview:b];

    return b;
}

- (NSTextField *) make_mode_text:(SEL) selector
{
    NSTextField *b = [[NSTextField alloc] init];

    [[b cell] setControlSize:NSSmallControlSize];
    [b setStringValue:@"999"];	
    [b setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [b sizeToFit];
    [b setStringValue:@""];
    [b setAction:selector];
    [b setTarget:self];
    [b setNextKeyView:input_text];

    [top_box addSubview:b];
    
    return b;
}

- (void) setup_channel_mode_buttons
{
    [self clean_top_box]; // Is this really needed?  Does it hurt?

    t_button = [self make_mode_button:'t' selector:@selector (do_flag_button:)];
    n_button = [self make_mode_button:'n' selector:@selector (do_flag_button:)];
    s_button = [self make_mode_button:'s' selector:@selector (do_flag_button:)];
    i_button = [self make_mode_button:'i' selector:@selector (do_flag_button:)];
    p_button = [self make_mode_button:'p' selector:@selector (do_flag_button:)];
    m_button = [self make_mode_button:'m' selector:@selector (do_flag_button:)];
	C_button = [self make_mode_button:'C' selector:@selector (do_flag_button:)];
	N_button = [self make_mode_button:'N' selector:@selector (do_flag_button:)];
	u_button = [self make_mode_button:'u' selector:@selector (do_flag_button:)];
    b_button = [self make_mode_button:'b' selector:@selector (do_b_button:)];
    l_button = [self make_mode_button:'l' selector:@selector (do_l_button:)];
    limit_text = [self make_mode_text:@selector (do_limit_text:)];
    k_button = [self make_mode_button:'k' selector:@selector (do_k_button:)];
	key_text = [self make_mode_text:@selector (do_key_text:)];
	
	[top_box sizeToFit];
}

- (void) prefsChanged
{
    [chat_text setFont:[[AquaChat sharedAquaChat] font] boldFont:[[AquaChat sharedAquaChat] bold_font]];
              
    if (prefs.style_inputbox)
    {
        [input_text setFont:[[AquaChat sharedAquaChat] font]];
        [input_text sizeToFit];
    }

    [chat_text setPalette:[[AquaChat sharedAquaChat] palette]];

    [button_box setHidden:!prefs.userlistbuttons];
	[self setup_userlist_buttons];
    
    if (prefs.chanmodebuttons)
    {
        if (sess->type == SESS_DIALOG)
            [self setup_dialog_buttons];
        else
            [self setup_channel_mode_buttons];
    }
    else
        [self clean_top_box];
}

- (void) do_conf_mode:(id) sender
{
    sess->text_hidejoinpart = !sess->text_hidejoinpart;
    [sender setState:sess->text_hidejoinpart ? NSOnState : NSOffState];
}

- (void) do_mirc_color:(id) sender
{
    NSInteger val = [sender tag];
    
    // The value will contain the ascii code to send.  If it's <=0, the value
    // represents a color value.
    
    char buff [4];
    
    if (val <= 0)
    {
        val = -val;
        buff [0] = 3;
        buff [1] = '0' + val / 10;
        buff [2] = '0' + val % 10;
        buff [3] = 0;
    }
    else
    {
        buff [0] = val;
        buff [1] = 0;
    }

    [self insertText:[NSString stringWithUTF8String:buff]];
}

- (void) setup_sess_menu
{
    NSMenu *m = [sess_menu menu];

    // First item is the conference mode button

    [[m itemAtIndex:0] setState:sess->text_hidejoinpart ? NSOnState : NSOffState];
    
    NSRect rect = NSMakeRect (0,0,100,14);
    ColorPalette *p = [[AquaChat sharedAquaChat] palette];
    for (NSInteger i = 0; i < 16; i ++)
    {
        NSImage *im = [[NSImage alloc] initWithSize:rect.size];
        [im lockFocus];
        NSColor *c = [p getColor:i];
        [c set];
        [NSBezierPath fillRect:rect];
        [im unlockFocus];
        
        NSMenuItem *mi = [[NSMenuItem alloc] init];
        [mi setTitle:@""];
        [mi setTarget:self];
        [mi setAction:@selector (do_mirc_color:)];
        [mi setImage:im];
        [mi setTag:-i];		// See do_mirc_color
        
        [m addItem:[mi autorelease]];
    }
}

- (void) awakeFromNib
{
	[chat_view setFrameSize:NSMakeSize (prefs.mainwindow_width, prefs.mainwindow_height)];
	[chat_text setFrame:[chat_scroll documentVisibleRect]];

    [top_box layoutNow];
    
    [self prefsChanged];

    [chat_view setServer:sess->server];
    [chat_view setInitialFirstResponder:input_text];

    [chat_text setDropHandler:self];
    [chat_text setNextKeyView:input_text];
    [chat_text setDelegate:self];
    
#if 0
    NSScroller *right_scroll_bar = [chat_scroll verticalScroller];
    scroll_target = [right_scroll_bar target];
    scroll_sel = [right_scroll_bar action];
    [right_scroll_bar setTarget:self];
    [right_scroll_bar setAction:@selector (user_scrolled:)];
#endif

	//[input_text setAllowsEditingTextAttributes:true];
    [input_text setTarget:self];
    [input_text setDelegate:self];
    [input_text setAction:@selector (do_command:)];
    if (prefs.style_inputbox)
        [input_text setFont:[[AquaChat sharedAquaChat] font]];
 
    [userlist_table setDoubleAction:@selector (do_doubleclick:)];
    [userlist_table setTarget:self];
    [userlist_table setDataSource:self];
    [userlist_table setDelegate:self];
    [userlist_table registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];

    //[input_text registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
	
    if (prefs.showhostname_in_userlist)
    {
        NSTableColumn *c = [[NSTableColumn alloc] initWithIdentifier:nil];
        [c setEditable:false];
        //[c setMaxWidth:250];
        //[c setMinWidth:250];
        //[c setWidth:250];
        [userlist_table addTableColumn:c];
        [c release];
    }
    
    for (NSInteger i = 0; i < [userlist_table numberOfColumns]; i ++)
    {
        NSTableColumn *col = [[userlist_table tableColumns] objectAtIndex:i];
        [col setIdentifier:[NSNumber numberWithInt:i]];
    }

    NSArray *cols = [userlist_table tableColumns];
    NSTableColumn *col_zero = [cols objectAtIndex:0];
    [col_zero setDataCell:[[[NSImageCell alloc] init] autorelease]];
    NSTableColumn *col_one  = [cols objectAtIndex:1];
    [col_one setDataCell:[[[NSTextFieldCell alloc] init] autorelease]];
    [[col_one dataCell] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	if (prefs.showhostname_in_userlist)
	{
		NSTableColumn *col_two = [cols objectAtIndex:2];
		[col_two setDataCell:[[[NSTextFieldCell alloc] init] autorelease]];
		[[col_two dataCell] setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
	}
	
	[lag_indicator sizeToFit];
	[throttle_indicator sizeToFit];
    
    [progress_indicator setHidden:true];
    [op_voice_icon setHidden:true];

    [top_box setStretchView:topic_text];
    [top_box layoutNow];	// This allows topic_text to keep it's place
    [topic_text setAction:@selector (do_topic_text:)];
    [topic_text setTarget:self];
    
    [button_box setCols:2 rows:0];
    [button_box setShrinkHoriz:false vert:true];
    [self setup_userlist_buttons];

    [chat_view setDelegate:self];

    [self setup_sess_menu];
    [self clear:0];
    [self set_nick];
    [self set_title];
    [self set_nonchannel:false];

    if (sess->type == SESS_DIALOG)
        [self set_channel];
    else
        [chat_view setTabTitle:NSLocalizedStringFromTable(@"<none>", @"xchat", @"")];
    
    if (sess->type == SESS_DIALOG || prefs.hideuserlist)
        [middle_box set_split_pos:0];
    else if (prefs.paned_pos > 0)
        [middle_box set_split_pos:prefs.paned_pos];
    else
        [middle_box set_split_pos:150];

    if (sess->type == SESS_DIALOG)
    {
        if (prefs.privmsgtab)
            [chat_view becomeTabAndShow:prefs.newtabstofront];
        else
            [chat_view becomeWindowAndShow:true];
    }
    else
    {
        if (prefs.tabchannels)
            [chat_view becomeTabAndShow:prefs.newtabstofront];
        else
            [chat_view becomeWindowAndShow:true];
    }
    
	[middle_box setDelegate:self];
    //[[input_text window] makeFirstResponder:input_text];
}

- (void) insertText:(NSString *) s
{
    NSMutableString *news = [NSMutableString stringWithString:[input_text stringValue]];
    [news appendString:s];
    [input_text setStringValue:news];
    NSWindow *win = [input_text window];
	NSResponder *res = [win firstResponder];
	if ([res isKindOfClass:[NSTextView class]])
	{
		NSTextView *tview = (NSTextView *) res;
		if ((NSTextField *)[tview delegate] == input_text)
			[tview moveToEndOfParagraph:self];
	}
}

- (void) set_lag:(NSNumber *) percent
{
    [lag_indicator setDoubleValue:[percent floatValue]];
}

/* CL: this is used for both buttons and menus, like userlist_button_cb in fe-gtk */
- (void) do_userlist_command:(const char *) cmd
{
	if (sess->type == SESS_DIALOG)
	{
		nick_command_parse (sess, cmd, sess->channel, "");
		return;
	}

    if ([userlist_table numberOfSelectedRows] < 1)
    {
        nick_command_parse (sess, cmd, "", "");
        return;
    }
    
    NSMutableString *allnicks = [NSMutableString stringWithCapacity:0];
    char *first_nick = NULL;
    bool using_allnicks = strstr (cmd, "%a");
    
    NSIndexSet *rowIndexSet = [userlist_table selectedRowIndexes];
    for (NSUInteger rowIndex = [rowIndexSet firstIndex]; rowIndex != NSNotFound; rowIndex = [rowIndexSet indexGreaterThanIndex:rowIndex] )
    {
        OneUser *u = (OneUser *) [userlist objectAtIndex:rowIndex];
		struct User *user = u->user;

        if (using_allnicks)
        {
            if ([allnicks length])
                [allnicks appendString:@" "];
                    
            [allnicks appendString:[NSString stringWithUTF8String:user->nick]];
        }
        
        if (!first_nick)
            first_nick = user->nick;
        
        if (!using_allnicks)
            nick_command_parse (sess, cmd, user->nick, "");
    }

    if (using_allnicks)
        nick_command_parse (sess, cmd, first_nick ? first_nick : (char *)"", (char *) [allnicks UTF8String]);
}

- (void) do_userlist_button:(id) sender
{
    struct popup *p = [(UserlistButton *) sender getPopup];
	[self do_userlist_command:p->cmd];
}

- (void) setup_userlist_buttons
{
    while ([[button_box subviews] count])
        [[[button_box subviews] objectAtIndex:0] removeFromSuperviewWithoutNeedingDisplay];
    
    for (GSList *list = button_list; list; list = list->next)
    {
        struct popup *p = (struct popup *) list->data;
        
        UserlistButton *b =
	    [[[UserlistButton alloc] initWithPopup:p] autorelease];

        [b setAction:@selector (do_userlist_button:)];
        [b setTarget:self];

        [button_box addSubview:b];
    }
}

- (void) do_doubleclick:(id) sender
{
    if (prefs.doubleclickuser [0])
    {
        int row = [sender selectedRow];
        if (row >= 0)
        {
            OneUser *u = (OneUser *) [userlist objectAtIndex:row];
            struct User *user = u->user;
            nick_command_parse (sess, prefs.doubleclickuser, user->nick, user->nick);
        }
    }
}

- (void) clear_channel
{
    NSString *s;
    
    if (sess->waitchannel[0])
    {
        NSMutableString *s2 = [NSMutableString stringWithUTF8String:sess->waitchannel];
        if (prefs.truncchans && [s2 length] > prefs.truncchans)
        {
            unsigned int start = prefs.truncchans - 4;
            unsigned int len = [s2 length] - start;
            [s2 replaceCharactersInRange:NSMakeRange (start, len)
                            withString:@".."];
			s = s2;
        }
        s = [NSString stringWithFormat:@"(%@)", s2];
    }
    else
        s = NSLocalizedStringFromTable(@"<none>", @"xchat", @"");
        
    [chat_view setTabTitle:s];
    [op_voice_icon setHidden:true];
    [limit_text setStringValue:@""];

    [self set_topic:""];
}

- (void) clear:(int)lines
{
    //TODO: implement this
    [chat_text clear_text];
}

- (void) close_window
{
    [chat_view close];
}

- (void) windowDidResize:(NSNotification *) notification
{
    size_prefs ([notification object]);
}

- (void) windowDidMove:(NSNotification *) notification
{
    location_prefs ([notification object]);
}

- (void) windowWillClose:(NSNotification *) xx
{
    session_free (sess);
    
    // common will find new front_session for each server, but it wont
    // find a new current_sess.  We had assumed that by closing this session,
    // a new session would appear on top, and thus generating a windowDidBecomeKey
    // for a different window, and thus setting current_sess.  The problem is
    // that the new top window may not be a chat window and thus current_sess
    // points to a zombie.  We need to find any session for current_sess.
    
	if (current_sess == sess)
		current_sess = sess_list ? (session *) sess_list->data : NULL;
	
	//printf ("current session is 0x%x\n", current_sess);
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
    //printf ("Focus change\n");
	//printf ("current session is 0x%x (0x%x)\n", current_sess, sess);

    // This is the global current tab pointer.
    current_tab = sess;
    // This is the global current session pointer.
    current_sess = sess;
    
    // Each server keeps track of it's front session too
    sess->server->front_session = sess;

    // If our server has a server session, but it's not of type SESS_SERVER, then
    // we become the server session to server messages appear in front.
    if (sess->server->server_session != NULL)
    {
        if (sess->server->server_session->type != SESS_SERVER)
            sess->server->server_session = sess;
    } 
    else
    {
        sess->server->server_session = sess;
    }

    if (sess->new_data || sess->nick_said || sess->msg_said)
    {
        [self set_tab_color:0 flash:false];
    }

    fe_set_away (sess->server);
}

- (void) set_tab_color:(int) col flash:(bool) flash
{
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];

    if (col == 0 || sess != current_tab)
    {
        switch (col)
        {
            case 0: /* no particular color (theme default) */
                sess->new_data = false;
                sess->msg_said = false;
                sess->nick_said = false;
                [chat_view setTabTitleColor:[NSColor blackColor]];
                break;
                
            case 1: /* new data has been displayed (dark red) */
                sess->new_data = true;
                sess->msg_said = false;
                sess->nick_said = false;
                [chat_view setTabTitleColor:[palette getColor:AC_NEW_DATA]];
                break;
                
            case 2: /* new message arrived in channel (light red) */
                sess->new_data = false;
                sess->msg_said = true;
                sess->nick_said = false;
                [chat_view setTabTitleColor:[palette getColor:AC_MSG_SAID]];
                break;
                
            case 3: /* your nick has been seen (blue) */
                sess->new_data = false;
                sess->msg_said = false;
                sess->nick_said = true;
                [chat_view setTabTitleColor:[palette getColor:AC_NICK_SAID]];
                break;
        }
    }
}

- (void) do_topic_text:(id) sender
{
    if (sess->channel[0] && sess->server->connected)
    {
        const char *topic = [[topic_text stringValue] UTF8String];
        sess->server->p_topic (sess->server, sess->channel, (char *) topic);
    }
    
    [[input_text window] makeFirstResponder:input_text];
}

- (void) do_l_button:(id) sender
{
    set_l_flag (sess, [sender state] == NSOnState, [limit_text intValue]);
}

- (void) do_k_button:(id) sender
{
    set_k_flag (sess, [sender state] == NSOnState, (char *) [[key_text stringValue] UTF8String]);
}



- (void) do_b_button:(id) sender
{
    // TBD
    printf ("Open banlist\n");
}

- (void) do_flag_button:(id) sender
{
    change_channel_flag (sess, [sender tag], [sender state] == NSOnState);
}

- (void) do_key_text:(id) sender
{
    if (sess->server->connected && sess->channel[0])
    {
        [k_button setState:NSOnState];
        [self do_k_button:k_button];
    }
}

- (void) do_limit_text:(id) sender
{
    if (sess->server->connected && sess->channel[0])
    {
        [l_button setState:NSOnState];
        [self do_l_button:l_button];
    }
}

- (void) mode_buttons:(char) mode sign:(char) sign
{
	NSButton *button = nil;
	
	switch (mode)
	{
		case 't': button = t_button; break;
		case 'n': button = n_button; break;
		case 's': button = s_button; break;
		case 'i': button = i_button; break;
		case 'p': button = p_button; break;
		case 'm': button = m_button; break;
		case 'b': button = b_button; break;
		case 'l': button = l_button; break;
		case 'k': button = k_button; break;
		case 'C': button = C_button; break;
		case 'N': button = N_button; break;
		case 'u': button = u_button; break;
        default: return;
	}
   
    if ( nil != button )
		[button setState:sign == '+' ? NSOnState : NSOffState];
	
	// Can't do this..  We really need to know if our user mode allows
	// us to edit the topic.. can we know that for sure given the various
	// operator levels that exist?
	//if (mode == 't')
	//	[topic_text setEditable:sign == '-'];
}

- (void) set_topic:(const char *) topic
{
	ColorPalette *palette = [[[[AquaChat sharedAquaChat] palette] clone] autorelease];

	[palette setColor:AC_FGCOLOR color:[NSColor blackColor]];
	[palette setColor:AC_BGCOLOR color:[NSColor whiteColor]];

	[topic_text setStringValue:[mIRCString stringWithUTF8String:topic
															len:-1
														palette:palette
															font:nil
														boldFont:nil]];
}

- (void) set_channel
{
	NSMutableString *channelString = [NSMutableString stringWithUTF8String:sess->channel];

	if (prefs.truncchans && [channelString length] > prefs.truncchans)
	{
		NSUInteger start = prefs.truncchans - 2;
		NSUInteger len = [channelString length] - start;
		[channelString replaceCharactersInRange:NSMakeRange (start, len) withString:@".."];
	}
	[chat_view setTabTitle:channelString];

	// FIXME: rough solution to solve initialization with scrollToDocumentEnd 2/3
	[chat_text scrollToEndOfDocument:chat_view];
}

- (void) set_nonchannel:(bool) state
{
    [t_button setEnabled:state];
    [n_button setEnabled:state];
    [s_button setEnabled:state];
    [i_button setEnabled:state];
    [p_button setEnabled:state];
    [m_button setEnabled:state];
    [b_button setEnabled:state];
    [l_button setEnabled:state];
    [k_button setEnabled:state];
	[C_button setEnabled:state];
	[N_button setEnabled:state];
	[u_button setEnabled:state];
    [limit_text setEnabled:state];
    [key_text setEnabled:state];
    [topic_text setEditable:state];
    
    // FIXME: rough solution to solve initialization with scrollToDocumentEnd 3/3
    [chat_text scrollToEndOfDocument:chat_view];
}

- (void) set_nick
{
    [nick_text setStringValue:[NSString stringWithUTF8String:sess->server->nick]];
    [nick_text sizeToFit];
}

- (int) find_user:(struct User *) user
{
    for (NSUInteger i = 0; i < [userlist count]; i ++)
        if ([[userlist objectAtIndex:i] getUser] == user)
            return i;
    return -1;
}

/* CL */
- (int) findUser:(struct User *) user returnObject:(OneUser **) userObject
{
	for (NSUInteger i = 0, n = [userlist count]; i < n; i++) {
		OneUser *u = (OneUser *) [userlist objectAtIndex:i];
		if ([u getUser] == user) {
			*userObject = u;
			return i;
		}
	}
	*userObject = nil;
	return -1;
}
/* CL end */

- (NSImage *) get_user_image:(struct User *) user
{
	switch (user->prefix [0])
	{
		case '@': return green_image;
		case '%': return blue_image;
		case '+': return yellow_image;
	}

	/* find out how many levels above Op this user is */
	char *pre = strchr (sess->server->nick_prefixes, '@');
	if (pre && pre != sess->server->nick_prefixes)
	{
		pre--;
		NSInteger level = 0;
		while (1)
		{
			if (pre[0] == user->prefix[0])
			{
				switch (level)
				{
					case 0: return red_image;		/* 1 level above op */
					case 1: return purple_image;	/* 2 levels above op */
				}
				break;								/* 3+, no icons */
			}
			level++;
			if (pre == sess->server->nick_prefixes)
				break;
			pre--;
		}
	}
	return empty_image;
}

/* CL */
- (void) recalculateUserTableLayout
{
	maxNickWidth = 0.0;
	maxHostWidth = 0.0;
	maxRowHeight = 16.0;

	NSEnumerator *enumerator = [userlist objectEnumerator];
	for ( OneUser * u = [enumerator nextObject]; u != nil; u = [enumerator nextObject]) {
		if (u->nickSize.width > maxNickWidth) maxNickWidth = u->nickSize.width;
		if ((prefs.showhostname_in_userlist) && (u->hostSize.width > maxHostWidth)) maxHostWidth = u->hostSize.width;
		if (u->nickSize.height > maxRowHeight) maxRowHeight = u->nickSize.height;
	}
	
	NSTableColumn *column = [[userlist_table tableColumns] objectAtIndex:1];
	[column sizeToFit];
	if (maxNickWidth != [column width]) [column setWidth: maxNickWidth];
	if (prefs.showhostname_in_userlist) {
		column = [[userlist_table tableColumns] objectAtIndex:2];
		if (maxHostWidth != [column width]) [column setWidth: maxHostWidth];
	}
	if (maxRowHeight != [userlist_table rowHeight]) [userlist_table setRowHeight: maxRowHeight];
}

- (void) updateUserTableLayoutForInsert:(OneUser *) user
{
	NSArray *columns = [userlist_table tableColumns];
	/* nickname column */
	NSTableColumn *column = [columns objectAtIndex:1];
	CGFloat width = user->nickSize.width;
	if (width > maxNickWidth) {
		maxNickWidth = width+0.5; // Leopard fix :) Where this 0.25 come from?
		[column setWidth: maxNickWidth];
	}
	/* host column */
    if (prefs.showhostname_in_userlist) {
		column = [columns objectAtIndex:2];
		CGFloat width = user->hostSize.width;
		if (width > maxHostWidth) {
			maxHostWidth = width;
			[column setWidth: width];
		}
	}
	/* row height */
	CGFloat height = (user->nickSize.height > user->hostSize.height ? user->nickSize.height: user->hostSize.height);
	if (height > maxRowHeight) {
		maxRowHeight = height;
		[userlist_table setRowHeight: height];
	}
}

- (void) updateUserTableLayoutForRemove:(OneUser *) user
{
	/* nickname column */
	if (user->nickSize.width == maxNickWidth) [self recalculateUserTableLayout];
	/* host column */
	else if ((prefs.showhostname_in_userlist) && (user->hostSize.width == maxHostWidth)) [self recalculateUserTableLayout];
	/* row height */
	else {
		CGFloat height = (user->nickSize.height > user->hostSize.height ? user->nickSize.height: user->hostSize.height);
		if ((height == maxRowHeight) && (height > 16.0)) [self recalculateUserTableLayout];	/* in this case, a stricter condition should be added, as (oldHeight == [userlist_table rowHeight]) will be true for most users */
	}
}

- (void) updateUserTableLayoutForRehash:(OneUser *)user
							oldNickSize:(NSSize)oldNickSize oldHostSize:(NSSize)oldHostSize
{
	NSArray *columns = [userlist_table tableColumns];
	/* nickname column */
	NSTableColumn *column = [columns objectAtIndex:1];
	CGFloat width = user->nickSize.width;
	if ((width < oldNickSize.width) && (oldNickSize.width == maxNickWidth)) {
		[self recalculateUserTableLayout];
		return;
	}
	else if (width > maxNickWidth) {
		maxNickWidth = width;
		[column setWidth: width];
	}
	/* host column */
    if (prefs.showhostname_in_userlist) {
		column = [columns objectAtIndex:2];
		CGFloat width = user->hostSize.width;
		if ((width < oldHostSize.width) && (oldHostSize.width == maxHostWidth)) {
			[self recalculateUserTableLayout];
			return;
		}
		else if (width > maxHostWidth) {
			maxHostWidth = width;
			[column setWidth: width];
		}
	}
	/* row height */
	CGFloat height = (user->nickSize.height > user->hostSize.height ? user->nickSize.height: user->hostSize.height);
	CGFloat oldHeight = (oldNickSize.height > oldHostSize.height ? oldNickSize.height: oldHostSize.height);
	if ((height < oldHeight) && (oldHeight == maxRowHeight) && (oldHeight > 16.0)) {	/* in this case, a stricter condition should be added, as (oldHeight == [userlist_table rowHeight]) will be true for most users */
		[self recalculateUserTableLayout];
		return;
	}
	else if (height > maxRowHeight) {
		maxRowHeight = height;
		[userlist_table setRowHeight: height];
	}
}

- (void) rehashUserAndUpdateLayout:(OneUser *)user
{
	NSSize oldNickSize = user->nickSize;
	NSSize oldHostSize = user->hostSize;
    [user rehash];
	[user cacheSizesForTable: userlist_table];
	[self updateUserTableLayoutForRehash:user oldNickSize:oldNickSize oldHostSize:oldHostSize];
    [userlist_table reloadData];
}

- (void) userlist_select_names:(char **)names clear:(int)clear scroll_to:(int)scroll_to
{
	if (clear) [userlist_table deselectAll:self];
	
	if (*names[0]) {
		for (NSUInteger i = 0, n = [userlist count]; i < n; i++) {
			struct User *user = [[userlist objectAtIndex:i] getUser];
			NSUInteger j = 0;
			do {
				if (sess->server->p_cmp (user->nick, names[j]) == 0) {
					[userlist_table
           selectRowIndexes:[NSIndexSet indexSetWithIndex:i]
           byExtendingSelection:YES];
					if (scroll_to) [userlist_table scrollRowToVisible:i];
				}
			} while (*names[++j]);
		}
	}
}
/* CL end */

- (void) userlist_rehash:(struct User *) user
{
/* CL */
	OneUser *u;
	NSInteger idx = [self findUser:user returnObject:&u];
    if (idx < 0)
        return;
	[self rehashUserAndUpdateLayout:u];
/* CL end */
}

- (void) userlist_insert:(struct User *)user row:(int)row select:(bool) select
{
	OneUser *u = [(OneUser *) [OneUser alloc] initWithUser:user];
	/* CL */
	[u cacheSizesForTable: userlist_table];
	[self updateUserTableLayoutForInsert: u];
	/* CL end */

	if (row < 0) {
		[userlist addObject:u];
	} else
	{
		NSInteger srow = [userlist_table selectedRow];
		[userlist insertObject:u atIndex:row];
		if (srow >= 0 && row <= srow)
			[userlist_table selectRowIndexes:[NSIndexSet indexSetWithIndex:srow+1] byExtendingSelection:NO];
	}

	if (select)
		[userlist_table selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];

    [userlist_table reloadData];

	if (user->me)
	{
		NSImage *img = [self get_user_image:user];
		if (img == empty_image) {
			[op_voice_icon setHidden:true];
		}
		else
		{
			[op_voice_icon setImage:img];
			[op_voice_icon setHidden:false];
		}
	}
	[u release];
}

- (bool) userlist_remove:(struct User *) user
{
/* CL */
	OneUser *u;
	NSInteger idx = [self findUser:user returnObject:&u];
	if (idx < 0)
		return false;

	NSInteger srow = [userlist_table selectedRow];
	[u retain];
	[userlist removeObjectAtIndex:idx];
	[self updateUserTableLayoutForRemove: u];
	[u release];
/* CL end */
	if (idx < srow)
		[userlist_table selectRowIndexes:[NSIndexSet indexSetWithIndex:srow-1] byExtendingSelection:NO];
    else if (idx == srow)
		[userlist_table deselectAll:self];
	[userlist_table reloadData]; 

	return srow == idx;
}

- (void) userlist_move:(struct User *)user row:(int) row
{
/* CL */
	OneUser *u;
	NSInteger i = [self findUser:user returnObject:&u];
	if (i < 0) return;

	if (i != row) {
		[u retain];		//<--
		[userlist removeObjectAtIndex:i];
		[userlist insertObject:u atIndex:row];
		[u release];	//<--

		NSInteger srow = [userlist_table selectedRow];
		if (i == srow) srow = row;
		else {
			if (i < srow) srow--;
			if (row <= srow) srow++;
		}
		[userlist_table selectRowIndexes:[NSIndexSet indexSetWithIndex:srow] byExtendingSelection:NO];
	}
	
	[self rehashUserAndUpdateLayout: u];
	
	if (user->me)
	{
		NSImage *img = [self get_user_image:user];
		if (img == empty_image)
			[op_voice_icon setHidden:true];
		else
		{
			[op_voice_icon setImage:img];
			[op_voice_icon setHidden:false];
		}
	}
/* CL end */
}

// Used only for updating menus
- (void) userlist_update:(struct User *)user
{
    if(userlist_menu_curuser && !strcmp(userlist_menu_curuser->nick, user->nick))
        [userlist_menu setSubmenu:[[MenuMaker defaultMenuMaker] infoMenuForUser:user inSession:sess]];
}

- (void) userlist_numbers
{
    [userlist_stats_text setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d ops, %d total", @"xchat", nil),
            sess->ops, sess->total]];
}

- (void) progressbar_start
{
    [progress_indicator startAnimation:self];
    [progress_indicator setHidden:false];
}

- (void) progressbar_end
{
    [progress_indicator setHidden:true];
    [progress_indicator stopAnimation:self];
}

- (void) userlist_clear
{
    [userlist removeAllObjects];
/* CL */
	[self recalculateUserTableLayout];
/* CL end */
    [userlist_table reloadData]; 
}

- (void) channel_limit
{
    [limit_text setIntValue:sess->limit];
    [self set_title];
}

- (void) set_throttle
{
    double per = (double) sess->server->sendq_len / 1024.0;
    if (per > 1.0) per = 1.0;

    [throttle_indicator setDoubleValue:per];
}

- (void) set_hilight
{
    [self set_tab_color:3 flash:true];
}

- (void) set_title
{
	NSString *title;

	int type = sess->type;

	NSString *chan = [NSString stringWithUTF8String:sess->channel];
    
	switch (type)
	{
		case SESS_DIALOG:
			title = [NSString stringWithFormat:@"%@ %@",
					 NSLocalizedStringFromTable(@"Dialog with", @"xchat", @""),
					 [NSString stringWithFormat:@"%@ @ %s", chan, sess->server->servername]];
            break;

		case SESS_CHANNEL:
			if (sess->channel[0])
			{
				title = [NSString stringWithFormat:@"%s / %@", sess->server->servername, chan];
				break;
			}
			// else fall through

		case SESS_SERVER:
		case SESS_NOTICES:
		case SESS_SNOTICES:
			if (sess->server->servername [0])
			{
				title = [NSString stringWithFormat:@"%s", sess->server->servername];
				break;
			}
			// else fall through

		default:
			title = [NSString stringWithFormat:@"X-Chat [%s/%s]", MYVERSION, PACKAGE_VERSION];
	}
	[chat_view setTitle:title];
}

- (void) do_command:(id) sender
{
    [[input_text window] makeFirstResponder:input_text];

    NSString* message = [[[input_text stringValue] retain] autorelease];
    
    if ([message length] < 1)
        return;

    [input_text setStringValue:@""];

    handle_multiline (sess, (char *) [message UTF8String], TRUE, FALSE);
    
    // Don't do anything there.. previous command might have killed us.
}

- (void) lastlogIntoWindow:(ChatWindow *)logWin key:(char *)ckey
{

	if ([[chat_text textStorage] length] == 0) {
		[logWin print_text:[NSLocalizedStringFromTable(@"Search buffer is empty.\n", @"xchat", @"") UTF8String]];
		return;
	}
	NSTextStorage *sourceStorage = [chat_text textStorage];
	NSTextStorage *destStorage = [logWin->chat_text textStorage];
	NSString *text = [sourceStorage string];
	NSString *key = [NSString stringWithUTF8String:ckey];
	NSUInteger length = [text length];
	NSUInteger start = 0;
	while (true) {
		NSRange keyRange = [text rangeOfString:key options:NSCaseInsensitiveSearch range:NSMakeRange(start, length - start)];
		if (keyRange.location == NSNotFound) break;

		NSRange lineRange = [text lineRangeForRange:keyRange];
		NSMutableAttributedString *result = [[sourceStorage attributedSubstringFromRange:lineRange] mutableCopy];
		
		keyRange.location -= lineRange.location;	/* make range relative to result */
		[result applyFontTraits:NSFontBoldTrait range:keyRange];
		
		[destStorage appendAttributedString:result];
		[result release];
		start = NSMaxRange(lineRange);
	}

}

- (void) print_text:(const char *) text
{
	[self print_text:text stamp:time(NULL)];
}

- (void) print_text:(const char *) text stamp:(time_t)stamp
{
	[chat_text print_text:text stamp:stamp];

	if (!sess->new_data && sess != current_tab && !sess->nick_said)
	{
		if (sess->msg_said)	// Channel message
			[self set_tab_color:2 flash:false];
		else				// Server message?  Not sure..?
			[self set_tab_color:1 flash:false];
	}
}

- (BOOL) processFileDrop:(id <NSDraggingInfo>) info forUser:(const char *) nick
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if (![[pboard types] containsObject:NSFilenamesPboardType]) 
        return NO;

    if (!nick)
    {
        if (sess->type == SESS_DIALOG)
            nick = sess->channel;
        else
        {
            int row = [userlist_table selectedRow];
            if (row < 0)
                return NO;
            nick = [[[userlist_table dataSource] tableView:userlist_table
                      objectValueForTableColumn:[[userlist_table tableColumns] objectAtIndex:1]
                                            row:row] UTF8String];
        }
    }
    
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    for (NSUInteger i = 0; i < [files count]; i ++)
    {
        dcc_send (sess, (char *)nick, (char *)[[files objectAtIndex:i] UTF8String], prefs.dcc_max_send_cps, 0);
    }
	return YES;
}

- (const char *) getInputText
{
	return [[input_text stringValue] UTF8String];
}

- (void) setInputText:(const char *)text
{
    if (!text) return;
        
    [input_text setStringValue:[NSString stringWithUTF8String:text]];
    [[[input_text window] firstResponder] moveToEndOfParagraph:self];
}

- (int) getInputTextPosition
{
    NSWindow *win = [input_text window];
	NSTextView *view = (NSTextView*)[win firstResponder];
    if ([view isKindOfClass:[NSTextView class]] && (NSTextField *)[view delegate] == input_text)
	{
	    NSUInteger loc = [view selectedRange].location;
		return loc;
	}
	return 0;
}

- (void) setInputTextPosition:(int) pos delta:(bool) delta
{
    NSWindow *win = [input_text window];
	NSTextView *view = (NSTextView*)[win firstResponder];
    if ([view isKindOfClass:[NSTextView class]] && (NSTextField *)[view delegate] == input_text)
	{
		if (delta)
		{
			pos += [self getInputTextPosition];
		}
	    NSRange range;
		range.location = pos;
		range.length = 0;
		[view setSelectedRange:range];
	}
}

- (void) userlist_set_selected
{
    for (NSUInteger row = 0; row < [userlist count]; row++)
    {
        OneUser *u = [userlist objectAtIndex:row];
		u->user->selected = [userlist_table isRowSelected:row];
    }
}

/////
// User table data source methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [userlist count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    OneUser *u = [userlist objectAtIndex:row];
    switch ([[tableColumn identifier] intValue])
    {
        case 0: return [self get_user_image:u->user];
        case 1: return u->nick;
        case 2: return u->host;
    }
    return @"";
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    if (row < 0 || dropOperation == NSTableViewDropAbove /* || [tv isHiddenOrHasHiddenAncestor] */)
        return NSDragOperationNone;
	
    return NSDragOperationCopy;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSAttributedString *nick = [[tableView dataSource] tableView:tableView objectValueForTableColumn:[[tableView tableColumns] objectAtIndex:1] row:row];
    return [self processFileDrop:info forUser:[[nick string] UTF8String]];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent rowIndexes:(NSIndexSet *)rows
{
	NSUInteger count = [rows count];
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	NSString *nick = nil;
	
	[menu setAutoenablesItems:false];
    if(userlist_menu)
        [userlist_menu release];
	
	if (count > 1) {
		[[menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d users selected", @"xchataqua", @"Popup menu message when you right-clicked userlist."), count] action:nil keyEquivalent:@""] setEnabled:NO];
        userlist_menu_curuser = NULL;
	} else {
		OneUser *userObject = (OneUser *) [userlist objectAtIndex:[rows firstIndex]];
		struct User *user = [userObject getUser];

		nick = [userObject nick];
		NSMenuItem *userItem = [menu addItemWithTitle:nick action:nil keyEquivalent:@""];

        userlist_menu_curuser = user;
        userlist_menu         = [userItem retain];
        
		[userItem setSubmenu:[[MenuMaker defaultMenuMaker] infoMenuForUser:user inSession:sess]];

	}
	[menu addItem:[NSMenuItem separatorItem]];

	[[MenuMaker defaultMenuMaker] appendItemList:popup_list toMenu:menu withTarget:nick inSession:sess];

    return menu;
}

//////////////////////////////////////////////////////////////////////
// 
// Tab completion
//

static int ncommon (const char *a, const char *b)
{
	int n;
    for (n = 0; *a && *b && rfc_tolower (*a++) == rfc_tolower (*b++); n ++) ;
    return n;
}

static int find_common (NSArray *list)
{
    if ([list count] < 1) return 0;

    NSString *xx = (NSString *) [[list objectAtIndex:0] stringValue];
    NSInteger n = [xx length];

    for (NSUInteger i = 1; i < [list count]; i ++)
    {
    	NSInteger this_n = ncommon ([xx UTF8String], [[[list objectAtIndex:i] stringValue] UTF8String]);
		if (this_n < n)
			n = this_n;
    }

    return n;
}

- (NSArray *) command_complete:(NSTextView *) view start:(NSString *) start
{
	const char *utf = [start UTF8String];
	int len = strlen (utf);
	
	// Use a set because stupid user commands appear multiple times!
    NSMutableSet *matchArray = [NSMutableSet setWithCapacity:0];

    for (GSList *list = command_list; list; list = list->next)
    {
        struct popup *pop = (struct popup *) list->data;
		int this_len = strlen (pop->name);
		if (len <= this_len && strncasecmp (utf, pop->name, len) == 0)
			[matchArray addObject:[OneCompletion completionWithValue:pop->name]];
    }

    for (int i = 0; xc_cmds[i].name; i ++)
    {
        char *cmd = xc_cmds[i].name;
		int this_len = strlen (cmd);
		if (len <= this_len && strncasecmp (utf, cmd, len) == 0)
			[matchArray addObject:[OneCompletion completionWithValue:cmd]];
    }
    
	return [matchArray allObjects];
}

- (NSArray *) nick_complete:(NSTextView *) view
		       start:(NSString *) start
{
	const char *utf = [start UTF8String];
	int len = strlen (utf);

    NSMutableArray *matchArray = [NSMutableArray arrayWithCapacity:0];

	if (sess->type == SESS_DIALOG)
	{
		int this_len = strlen (sess->channel);
		if (len > this_len || rfc_ncasecmp ((char *) utf, sess->channel, len) != 0)
			return nil;
		[matchArray addObject:[OneCompletion completionWithValue:sess->channel]];
	}
	else
	{
		for (unsigned i = 0; i < [userlist count]; i ++)
		{
			OneUser *u = (OneUser *) [userlist objectAtIndex:i];
			struct User *user = u->user;
			int this_len = strlen (user->nick);
			if (len <= this_len && rfc_ncasecmp ((char *) utf, user->nick, len) == 0)
				[matchArray addObject:[OneNickCompletion nickWithNick:user->nick lasttalk:user->lasttalk]];
		}
	}

	return matchArray;
}

- (NSArray *) channel_complete:(NSTextView *) view
                          start:(NSString *) start
{
	const char *utf = [start UTF8String];
	int len = strlen (utf);

    NSMutableArray *matchArray = [NSMutableArray arrayWithCapacity:0];

    for (GSList *list = sess_list; list; list = list->next)
    {
        session *tmp_sess = (session *) list->data;

        if (tmp_sess->type == SESS_CHANNEL)
        {
            int this_len = strlen (tmp_sess->channel);
            if (len <= this_len && strncasecmp (utf, tmp_sess->channel, len) == 0)
                [matchArray addObject:[OneCompletion completionWithValue:tmp_sess->channel]];
        }
    }

	return matchArray;
}

- (void) tab_complete:(NSTextView *) view
{
    // Strategy:
    //  Find the word to the left (or under) the insertion point and
    //  tab complete it.
    //  If it starts in column zero:
    //	  If it starts with '/', do command completion
    //    else do nick completion but add the nick completion suffix (:)
    //  else if the word starts with '#', do channel completion
    //  else just do nick completion
		
	NSUInteger insertionPoint;
	if ([view hasMarkedText])
	{
		// If we have a marked range, remove it now and let
		// the reset of this code work as if it's the first time.
		// This was necessary, as it appears there is a bug when
		// marking/replacing text that's already marked.
		// Just adding unmarkText didn't seem to help by itself.
		NSRange range = [view markedRange];
		[view unmarkText];
		[view replaceCharactersInRange:range withString:@""];
		insertionPoint = range.location;
	}
	else
	{
		circular_completion_idx = 0;
		NSRange range = [view selectedRange];
		insertionPoint = range.location;
	}
	
	// Anything less than 1 char to the left of the insertion point is useless
    if (insertionPoint == 0) return;

	//////////
	//
	// Find the text to lookup.
	// So now we have
	//		abc|
 	// Location is the number of chars to our left.  Subtract 1 so we're
	// pointing to the 'c' and not the tailing NULL.
	
	NSTextStorage *stg = [view textStorage];
	NSString *str = [stg string];
	
	NSRange range = NSMakeRange(insertionPoint - 1, 1);
	
    if ([str characterAtIndex:range.location] == ' ') return;

    while (range.location > 0 && [str characterAtIndex:range.location - 1] != ' ')
    {
		range.location --;
		range.length ++;
	}

	//////////
	
	NSArray *matchArray;
	bool add_suffix = false;
	
    if (range.location == 0)
    {
        if ([str characterAtIndex:0] == prefs.cmdchar[0])
        {
            range.location ++;
            range.length --;
			matchArray = [self command_complete:view start:[str substringWithRange:range]];
        }
		else
		{
			matchArray = [self nick_complete:view start:[str substringWithRange:range]];
			add_suffix = true;
		}
    }
    else
    {
        if ([str characterAtIndex:range.location] == '#')
            matchArray = [self channel_complete:view start:[str substringWithRange:range]];
        else
            matchArray = [self nick_complete:view start:[str substringWithRange:range]];
    }

    if (!matchArray || [matchArray count] < 1) return;
	
	matchArray = [matchArray sortedArrayUsingSelector:@selector(compare:)];

    NSUInteger n = find_common (matchArray);

	// If there's only 1 possible match, then we're done.
	// If were doing the old style (bash style), and the common chars
	// exceed what we typed, we'll complete up to the ambiguity.
    if ([matchArray count] == 1 || (!prefs.scrolling_completion && n > range.length))
    {
    	NSString *first = [[matchArray objectAtIndex:0] stringValue];
		NSMutableString *r = [NSMutableString stringWithString:[first substringToIndex:n]];
		if ([matchArray count] == 1)
		{
			if (add_suffix && prefs.nick_suffix[0])
                [r appendString:[NSString stringWithUTF8String:prefs.nick_suffix]];
            [r appendString:@" "];
		}
		[stg replaceCharactersInRange:range withString:r];
		return;
    }
	
	if (prefs.scrolling_completion)
	{
		NSString *item = [[matchArray objectAtIndex:circular_completion_idx] stringValue];

		// Replace the part he typed, just so the case will match
		NSString *left = [item substringToIndex:range.length];
		[view replaceCharactersInRange:range withString:left];

		// Now add the completion part as a "marked" area.
		NSString *right = [item substringFromIndex:range.length];
		NSMutableString *r = [NSMutableString stringWithString:right];
		if (add_suffix && prefs.nick_suffix[0])
			[r appendString:[NSString stringWithUTF8String:prefs.nick_suffix]];
		[r appendString:@" "];
		[view setMarkedText:r selectedRange:NSMakeRange(0, [r length])];
		[view setSelectedRange:NSMakeRange(range.location + range.length + [r length], 0)];
		circular_completion_idx = (circular_completion_idx + 1) % [matchArray count];
	}
	else
	{
		[self print_text:[[matchArray componentsJoinedByString:@" "] UTF8String]];
	}
}

//////////
// input_text delegate and helper funcs

- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    if (prefs.spell_check)
        [(NSTextView *)fieldEditor setContinuousSpellCheckingEnabled:YES];
		
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    prefs.spell_check = [(NSTextView *)fieldEditor isContinuousSpellCheckingEnabled];
    [(NSTextView *)fieldEditor setContinuousSpellCheckingEnabled:NO];
    return YES;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    //NSArray *xx = [input_text registeredDraggedTypes];
    //if (xx)
    //{
    //    for (unsigned i = 0; i < [xx count]; i ++)
    //        printf ("%d %s\n", i, [[xx objectAtIndex:i] UTF8String]);
    //}

    //printf ("->%s\n", [NSStringFromSelector (command) UTF8String]);

	if (commandSelector == @selector (insertNewline:))
	{
		NSEvent *theEvent = [NSApp currentEvent];
		if ([theEvent type] == NSKeyDown && ([theEvent modifierFlags] & NSShiftKeyMask))
		{
			[textView insertNewlineIgnoringFieldEditor:control];
		}
		else return false;
	}
	else if (commandSelector == @selector (moveUp:))
    {
        const char *xx = history_up (&sess->history, (char *) [[input_text stringValue] UTF8String]);
        [self setInputText:xx];
    }
    else if (commandSelector == @selector (moveDown:))
    {
        const char *xx = history_down (&sess->history);
        [self setInputText:xx];
    }
    else if (commandSelector == @selector (scrollPageDown:))
    {
        [chat_text scrollPageDown:textView];
    }
    else if (commandSelector == @selector (scrollPageUp:))
    {
        [chat_text scrollPageUp:textView];
    }
    else if (commandSelector == @selector (scrollToBeginningOfDocument:))
    {
        [chat_text scrollToBeginningOfDocument:textView];
    }
    else if (commandSelector == @selector (scrollToEndOfDocument:))
    {
        [chat_text scrollToEndOfDocument:textView];
    }
    else if (commandSelector == @selector (insertTab:))
    {
        if (prefs.tab_completion)
            [self tab_complete:textView];
        else
            [textView insertTab:textView];
    }
	else {
		return false;
	}

    return true;
}

@end
