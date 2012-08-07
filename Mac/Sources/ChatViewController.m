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
#import "ChatViewController.h"
#import "ColorPalette.h"
#import "MIRCString.h"
#import "MenuMaker.h"
#import "UtilityWindow.h"
#import "UserListTableView.h"

#include "outbound.h"
#include "util.h"

#pragma mark Objects for tab auto-complete

@interface TabCompletionItem : NSObject {
    NSString *_stringValue;
}

@property (nonatomic, retain) NSString* stringValue;

+ (id)completionWithValue:(NSString *)value;
- (id)initWithValue:(NSString *)value;

@end

/*
 * Superclass for a single auto-completion object.
 *
 * Used for commands and channels; nicks have a specific subclass.
 *
 */
@implementation TabCompletionItem
@synthesize stringValue=_stringValue; // NSString where we stash the actual text value.

/*
 * Designated initializer for TabCompletionItem objects.
 *
 * Takes a const char* from C land and stashes it in self.value as NSString.
 * ???: Is const char* really directly interchangeable with NSString?
 *
 */
+ (id) completionWithValue:(NSString *) val
{
    return [[[TabCompletionItem alloc] initWithValue:val] autorelease];
}

/*
 * Actual initializer for TabCompletionItem objects.
 *
 * Takes the const char*, calls super's init, and stashes the NSString in .value.
 *
 */
- (id)initWithValue:(NSString *)value {
    self = [super init];
    if (self != nil) {
        self.stringValue = value;
    }
    return self;
}

- (void)dealloc {
    self.stringValue = nil;
    [super dealloc];
}


/*
 * Selector called by NSarray when sorting TabCompletionItem objects.
 *
 * Essentially just compares NSString objects alphabetically (case insensitive).
 *
 * Needs to specify its argument as id because NickCompletionItem's compare:
 * calls super's (our) compare: with a NickCompletionItem argument in some cases;
 * which in turn means we have to cast to TabCompletionItem.
 *
 */
- (NSComparisonResult) compare:(id) aCompletion
{
    TabCompletionItem *other = (TabCompletionItem *) aCompletion;
    
    // TODO: rfc compare
    // For me it's not important (bug is around [ { and others symbols which in
    // RFC interprented as one). I think it's slow convert to utf8 compare with
    // xchat's one and revert to ucs2.
    // TODO: Could use NSCharacterSet?
    return [self.stringValue compare:other.stringValue options:NSCaseInsensitiveSearch];
}

/*
 * Serialize ourself as text.
 *
 * -description: is what gets called when you ask Cocoa to treat an object as a
 * string to serialize itself as text. For TabCompletionItem objects, that's just
 * the nicks that match so we dump out the completion's stringValue.
 */
- (NSString *) description
{
    return self.stringValue;
}

@end

#pragma mark -

@interface NickCompletionItem : TabCompletionItem
{
    time_t lasttalk;
}

+ (id)nickWithNick:(NSString *)nick lasttalk:(time_t)timestamp;
- (id)initWithNick:(NSString *)nick lasttalk:(time_t)timestamp;

@property (nonatomic, assign) time_t lasttalk;

@end

/*
 * Subclass of TabCompletionItem specifically for nicks.
 *
 */
@implementation NickCompletionItem

@synthesize lasttalk;

+ (id)nickWithNick:(NSString *)nick lasttalk:(time_t)lt
{
    return [[[self alloc] initWithNick:nick lasttalk:lt] autorelease];
}

- (id)initWithNick:(NSString *)nick lasttalk:(time_t)lt
{
    if ((self = [super initWithValue:nick]) != nil) {
        self.lasttalk = lt;
    }
    return self;
}

- (NSComparisonResult) compare:(id) aNick
{
    NickCompletionItem *other = (NickCompletionItem *) aNick;
    
    if (prefs.completion_sort == 1) {
        if (other.lasttalk == self.lasttalk) {
            return NSOrderedSame;
        } else if (other.lasttalk < self.lasttalk) {
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    } else {
        return [super compare:aNick];
    }
}

@end

#pragma mark -
#pragma mark Various utility objects

@interface ChatSplitView : NSSplitView

@property (nonatomic, assign) NSInteger splitPosition;

@end

@implementation ChatSplitView

- (void)viewDidResize:(id)sender {
    NSSplitViewDividerStyle dividerStyle;
    if (self.splitPosition < 10) {
        prefs.xa_paned_pos = 30;
        prefs.hideuserlist = 1;
        self.splitPosition = 0;
        dividerStyle = NSSplitViewDividerStyleThick;
    } else {
        prefs.xa_paned_pos = (int)self.splitPosition;
        prefs.hideuserlist = 0;
        dividerStyle = NSSplitViewDividerStyleThin;
    }
    self.dividerStyle = dividerStyle;
}

- (NSRect) dividerRect
{
    NSView *first = [[self subviews] objectAtIndex:0];
    
    NSRect firstRect = [first frame];
    firstRect.origin.x = firstRect.size.width - 1;
    firstRect.size.width = [self dividerThickness] + 1;
    
    return firstRect;
}

- (void) mouseDown:(NSEvent *) theEvent
{
    [super mouseDown:theEvent];
    NSPoint where = [theEvent locationInWindow];
    where = [self convertPoint:where fromView:nil];
    NSRect divider = [self dividerRect];
    
    if (!NSPointInRect(where, divider))
    {        
        return;
    }
    
    if ([theEvent clickCount] == 2)
    {
        if (prefs.hideuserlist) {
            [self setSplitPosition:prefs.xa_paned_pos];
            [self viewDidResize:self];
        } else {
            [self setSplitPosition:1];
            [self viewDidResize:self];
        }
    }
}

- (void) adjustSubviews 
{
    NSView *firstView = [[self subviews] objectAtIndex:0];
    NSView *secondView = [[self subviews] objectAtIndex:1];
    
    [firstView setPostsFrameChangedNotifications:NO];
    [secondView setPostsFrameChangedNotifications:NO];
    
    NSRect totalRect = [self bounds];
    NSRect firstRect = [firstView frame];
    NSRect secondRect = [secondView frame];
    
    secondRect.origin.x = totalRect.size.width - secondRect.size.width;
    secondRect.origin.y = 0.0f;
    secondRect.size.height = totalRect.size.height;
    firstRect.origin.x = 0.0f;
    firstRect.origin.y = 0.0f;
    firstRect.size.width = secondRect.origin.x - [self dividerThickness];
    firstRect.size.height = totalRect.size.height;
    
    [firstView setFrame:firstRect];
    [secondView setFrame:secondRect];
    
    [firstView setPostsFrameChangedNotifications:YES];
    [secondView setPostsFrameChangedNotifications:YES];
}

#pragma mark Propertyies

- (NSInteger)splitPosition
{
    NSView *second = [[self subviews] objectAtIndex:1];
    NSRect secondFrame = [second frame];
    return (int)secondFrame.size.width;
}

- (void)setSplitPosition:(NSInteger)position
{
    NSView *first = [[self subviews] objectAtIndex:0];
    NSView *second = [[self subviews] objectAtIndex:1];
    
    [first setPostsFrameChangedNotifications:NO];
    [second setPostsFrameChangedNotifications:NO];
    
    NSView *ulist = [[self subviews] objectAtIndex:1];
    NSRect ulistFrame = [ulist frame];
    ulistFrame.size.width = position;
    [ulist setFrame:ulistFrame];
    
    [self adjustSubviews];
    
    [self setNeedsDisplay:YES];
}

@end

#pragma mark -

@interface ChannelUser : NSObject
{
@public
    id nick, host; // NSString or NSAttributedString
    struct User    *user;
    /* CL */
    NSSize nickSize;
    NSSize hostSize;
    /* CL end */
}

@property (nonatomic, readonly) struct User *user;
@property (nonatomic, readonly) NSString *nick;

- (id) initWithUser:(struct User *)user;
- (void) rehash;
/* CL */
- (void) cacheSizesForTable: (NSTableView *) table;
/* CL end */

@end

@implementation ChannelUser
@synthesize user;

- (id) initWithUser:(struct User *) u
{
    if ((self = [super init]) != nil) {
        self->user = u;
        /* CL */
        nickSize = NSZeroSize;
        hostSize = NSZeroSize;
        /* CL end */
        
        [self rehash];
    }
    return self;
}

- (void) rehash
{
    //    I'm not sure how to or if I should call rehash on applyPreferences: it seems a bit irrelevant as eventually this will catch up and flip nick/host colors for us
    [nick release];
    [host release];
    
    NSString *nickString = [NSString stringWithUTF8String:user->nick];
    NSString *hostString = user->hostname ? [NSString stringWithUTF8String:user->hostname] : @"";
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
    
    NSColor *color;
    if (user->away) {
        color = [palette getColor:XAColorAwayUser];
    } else {
        if (prefs.style_namelistgad) {
            color = [palette getColor:XAColorForeground];
        } else {
            color = [NSColor blackColor];
        }
    }
    NSDictionary *attr = [NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName];
    
    nick = [[NSAttributedString alloc] initWithString:nickString attributes:attr];
    host = [[NSAttributedString alloc] initWithString:hostString attributes:attr];
}

- (void) dealloc
{
    [nick release];
    [host release];
    [super dealloc];
}

/* CL */
- (void) cacheSizesForTable: (NSTableView *) table
{
    NSArray *columns = [table tableColumns];
    /* nickname column */
    id dataCell = [[columns objectAtIndex:1] dataCell];
    [dataCell setAttributedStringValue: nick];
    nickSize = [dataCell cellSize];
    
    //    NSLayoutManager * layoutManager = [[[NSLayoutManager alloc] init] autorelease];
    //    NSTextContainer * textContainer = [[[NSTextContainer alloc] init] autorelease];
    //    NSTextStorage   * textStorage   = [[[NSTextStorage alloc] initWithAttributedString:nick] autorelease];
    //    
    //    [layoutManager addTextContainer:textContainer];
    //    [textStorage addLayoutManager:layoutManager];
    //
    //    (void) [layoutManager glyphRangeForTextContainer:textContainer];
    //    
    //    nickSize=[layoutManager usedRectForTextContainer:textContainer].size;
    
    /* host column */
    if (prefs.showhostname_in_userlist) {
        dataCell = [[columns objectAtIndex:2] dataCell];
        [dataCell setObjectValue: host];
        hostSize = [dataCell cellSize];
    }
}
/* CL end */

#pragma mark Property Interface

- (NSString *)nick
{
    return [NSString stringWithUTF8String:user->nick];
}

@end

#pragma mark -

static NSImage *redBulletImage;
static NSImage *purpleBulletImage;
static NSImage *greenBulletImage;
static NSImage *blueBulletImage;
static NSImage *yellowBulletImage;
static NSImage *emptyBulletImage;

#pragma mark Main class definition for the ChatViewController

@implementation ChatViewController
@synthesize tButton, nButton, sButton, iButton, pButton, mButton, bButton, lButton, kButton, CButton, NButton, uButton;
@synthesize limitTextField, keyTextField;

+ (void)initialize {
    if (self == [ChatViewController class]) {
        redBulletImage = [[NSImage imageNamed:@"red.tiff"] retain];
        purpleBulletImage = [[NSImage imageNamed:@"purple.tiff"] retain];
        greenBulletImage = [[NSImage imageNamed:@"green.tiff"] retain];
        blueBulletImage = [[NSImage imageNamed:@"blue.tiff"] retain];
        yellowBulletImage = [[NSImage imageNamed:@"yellow.tiff"] retain];
        emptyBulletImage = [[NSImage alloc] initWithSize:NSMakeSize(1.0f,1.0f)];
    }
}

- (id) initWithSession:(struct session *)aSession
{
    self = [super initWithNibName:@"ChatView" bundle:nil];
    if (self != nil) {
        self->sess = aSession;
        self->users = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) dealloc
{
    self.tButton = nil;
    self.nButton = nil;
    self.sButton = nil;
    self.iButton = nil;
    self.pButton = nil;
    self.mButton = nil;
    self.bButton = nil;
    self.lButton = nil;
    self.kButton = nil;
    self.CButton = nil;
    self.NButton = nil;
    self.uButton = nil;
    self.limitTextField = nil;
    self.keyTextField = nil;
    [users release];
    [super dealloc];
}

- (void) saveBuffer:(NSString *) filename
{
    [[[chatTextView textStorage] string] writeToFile:filename atomically:YES encoding:NSUTF8StringEncoding error:NULL];
}

- (void) find:(NSString *)string caseSensitive:(BOOL)caseSensitive backward:(BOOL)backward;
{
    NSRange from = [chatTextView selectedRange];

    // set initial bound
    if (!backward) {
        if (from.location == NSNotFound) {
            from.location = 0;
        } else {
            from.location += from.length;
        }
        from.length = [[chatTextView textStorage] length] - from.location;
    } else {
        if (from.location == NSNotFound) {
            from.length = [[chatTextView textStorage] length];
        } else {
            from.length = from.location;
        }
        from.location = 0;
    }
    
    NSStringCompareOptions mask = 0;
    if (!caseSensitive) {
        mask |= NSCaseInsensitiveSearch;
    }
    if (backward) {
        mask |= NSBackwardsSearch;
    }
    
    // find string
    NSRange where = [[[chatTextView textStorage] string] rangeOfString:string options:mask range:from];
    
    if (where.location == NSNotFound)
    {
        // try again about whole text
        from.length = [[chatTextView textStorage] length];
        from.location = 0;
        where = [[[chatTextView textStorage] string] rangeOfString:string options:mask range:from];
        
        if (where.location == NSNotFound)
            return;
    }
    
    [chatTextView setSelectedRange:where];
    [chatTextView scrollRangeToVisible:where];
}

- (void) useSelectionForFind {
    NSRange selectedRange = [[self.view.window fieldEditor:NO forObject:inputTextField] selectedRange];    
    NSString *searchString = [[inputTextField stringValue] substringWithRange:selectedRange];
    if ([searchString length] == 0) {
        searchString = [[[chatTextView textStorage] string] substringWithRange:[chatTextView selectedRange]];
    }
    [self find:searchString caseSensitive:NO backward:NO];
}

- (void) jumpToSelection {
    [chatTextView scrollRangeToVisible:[chatTextView selectedRange]];
}

- (void) cleanHeaderBoxView
{
    // The dialog and channel mode buttons share the top box with the
    // topic text.  Remove everything but the topic text and the spacer.
    
    CGFloat topicOriginX = [topicTextField frame].origin.x;
    
    for (NSUInteger i = 0; i < [[headerBoxView subviews] count]; )
    {
        NSView *view = [[headerBoxView subviews] objectAtIndex:i];
        if (view == topicTextField || [view frame].origin.x < topicOriginX)
            i ++;
        else
            [view removeFromSuperviewWithoutNeedingDisplay];
    }
    
    // This is just to be safe
    self.tButton = nil;
    self.nButton = nil;
    self.sButton = nil;
    self.iButton = nil;
    self.pButton = nil;
    self.mButton = nil;
    self.bButton = nil;
    self.lButton = nil;
    self.kButton = nil;
    self.CButton = nil;
    self.NButton = nil;
    self.uButton = nil;
    self.limitTextField = nil;
    self.keyTextField = nil;
}

- (void) doDialogButton:(id)sender
{
    /* the longest cmd is 12, and the longest nickname is 64 */
    char buf[128];
    
    struct popup *p = [(UserlistButton *)sender popup];
    auto_insert (buf, sizeof (buf), (unsigned char *)p->cmd, 0, 0, "", "", "", "", "", "", sess->channel);
    handle_command (sess, buf, TRUE);
}

- (void) setupDialogButtons
{
    [self cleanHeaderBoxView];
    
    for (GSList *list = dlgbutton_list; list; list = list->next)
    {
        struct popup *p = (struct popup *) list->data;
        
        UserlistButton *button = [UserlistButton buttonWithPopup:p];
        
        [button setAction:@selector(setupChannelModeButtons:)];
        [button setTarget:self];
        
        [headerBoxView addSubview:button];
    }
}

- (NSButton *)modeButtonForFlag:(char)flag selector:(SEL) selector
{
    NSButton *b = [[NSButton alloc] init];
    
    [b setButtonType:NSPushOnPushOffButton];
    [b setTitle:[NSString stringWithFormat:@"%c", toupper (flag)]];
    [[b cell] setControlSize:NSSmallControlSize];
    [b setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [b setImagePosition:NSNoImage];
    [b setBezelStyle:NSTexturedSquareBezelStyle];
    [b sizeToFit];
    [b setTag:flag];
    [b setAction:selector];
    [b setTarget:self];
    
    NSSize sz = [b frame].size;
    sz.height = [topicTextField frame].size.height;
    [b setFrameSize:sz];
    
    [headerBoxView addSubview:b];
    
    return [b autorelease];
}

- (NSTextField *)modeTextFieldForSelector:(SEL) selector
{
    NSTextField *b = [[NSTextField alloc] init];
    
    [[b cell] setControlSize:NSSmallControlSize];
    [b setStringValue:@"999"];    
    [b setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
    [b sizeToFit];
    [b setStringValue:@""];
    [b setAction:selector];
    [b setTarget:self];
    [b setNextKeyView:inputTextField];
    
    [headerBoxView addSubview:b];
    
    return [b autorelease];
}

- (void) setupChannelModeButtons
{
    [self cleanHeaderBoxView]; // Is this really needed?  Does it hurt?
    
    self.tButton = [self modeButtonForFlag:'t' selector:@selector (doFlagButton:)];
    self.nButton = [self modeButtonForFlag:'n' selector:@selector (doFlagButton:)];
    self.sButton = [self modeButtonForFlag:'s' selector:@selector (doFlagButton:)];
    self.iButton = [self modeButtonForFlag:'i' selector:@selector (doFlagButton:)];
    self.pButton = [self modeButtonForFlag:'p' selector:@selector (doFlagButton:)];
    self.mButton = [self modeButtonForFlag:'m' selector:@selector (doFlagButton:)];
    self.CButton = [self modeButtonForFlag:'C' selector:@selector (doFlagButton:)];
    self.NButton = [self modeButtonForFlag:'N' selector:@selector (doFlagButton:)];
    self.uButton = [self modeButtonForFlag:'u' selector:@selector (doFlagButton:)];
    self.bButton = [self modeButtonForFlag:'b' selector:@selector (doBButton:)];
    self.lButton = [self modeButtonForFlag:'l' selector:@selector (doLButton:)];
    self.limitTextField = [self modeTextFieldForSelector:@selector (doLimitTextField:)];
    self.kButton = [self modeButtonForFlag:'k' selector:@selector (doKButton:)];
    self.keyTextField = [self modeTextFieldForSelector:@selector (doKeyTextField:)];
    
    [headerBoxView sizeToFit];
}

- (void)adjustSplitBar {
    if (sess->type != SESS_CHANNEL || prefs.hideuserlist) {
        [userlistSplitView setSplitPosition:1];
    } else if (prefs.xa_paned_pos > 0) {
        [userlistSplitView setSplitPosition:prefs.xa_paned_pos];
    } else {
        [userlistSplitView setSplitPosition:150];
    }
}

- (void)applyPreferences:(id)sender {
    // init ColorPalette
    ColorPalette *p = [[AquaChat sharedAquaChat] palette];
    [chatTextView setFont:[[AquaChat sharedAquaChat] font] boldFont:[[AquaChat sharedAquaChat] boldFont]];
    chatTextView.enclosingScrollView.backgroundColor = [p getColor:XAColorBackground];

    NSColor *foregroundColor = [p getColor:XAColorForeground];
    NSColor *backgroundColor = [p getColor:XAColorBackground];
    if (prefs.style_inputbox)
    {
        inputTextField.font = [[AquaChat sharedAquaChat] font];
        [inputTextField sizeToFit];
        nickTextField.font = [[AquaChat sharedAquaChat] font];
        if (prefs.tab_layout == 2) {
            [inputContainerView setWantsLayer:YES];
            [inputContainerView.layer setBackgroundColor:CGColorCreateGenericRGB(backgroundColor.redComponent, backgroundColor.greenComponent, backgroundColor.blueComponent, backgroundColor.alphaComponent)];
            nickTextField.textColor = foregroundColor;
            nickTextField.backgroundColor = backgroundColor;
        } else {
            [inputContainerView setWantsLayer:NO];
            [inputContainerView.layer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 0, 0 )];
            nickTextField.textColor = [NSColor textColor];
            nickTextField.backgroundColor = [NSColor textBackgroundColor];
        }

        // fg, bg
        inputTextField.textColor = foregroundColor;
        inputTextField.backgroundColor = backgroundColor;
        topicTextField.textColor = foregroundColor;
        topicTextField.backgroundColor = backgroundColor;
    } else {
        [inputContainerView setWantsLayer:NO];
        [inputContainerView.layer setBackgroundColor:CGColorCreateGenericRGB(0, 0, 0, 0 )];
        inputTextField.font = [NSFont controlContentFontOfSize:0];
        [inputTextField sizeToFit];
        nickTextField.font = [NSFont controlContentFontOfSize:0];
        
        // fg, bg
        inputTextField.textColor = [NSColor textColor];
        inputTextField.backgroundColor = [NSColor textBackgroundColor];
        topicTextField.textColor = [NSColor textColor];
        topicTextField.backgroundColor = [NSColor textBackgroundColor];
        nickTextField.textColor = [NSColor textColor];
        nickTextField.backgroundColor = [NSColor textBackgroundColor];
    }

    if (prefs.style_namelistgad) {
        // bg only
        [userlistTableView setBackgroundColor:backgroundColor];

        // fg, bg and bezel
        [userlistStatusTextField setTextColor:[NSColor windowFrameTextColor]];
        [userlistStatusTextField setBackgroundColor:[NSColor windowBackgroundColor]];
        [userlistStatusTextField setBezeled:NO];

        for (ChannelUser *user in self->users) {
            [self rehashUserAndUpdateLayout:user];
        }
    } else {
        // bg only
        [userlistTableView setBackgroundColor:[NSColor textBackgroundColor]];
        
        // fg, bg and bezel
        [userlistStatusTextField setTextColor:[NSColor windowFrameTextColor]];
        [userlistStatusTextField setBackgroundColor:[NSColor windowBackgroundColor]];
        [userlistStatusTextField setBezeled:NO];
        
        for (ChannelUser *user in self->users) {
            [self rehashUserAndUpdateLayout:user];
        }
    }
    
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
    if (prefs.background && strlen(prefs.background) > 0) {
        palette = [[palette copy] autorelease];
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:[NSString stringWithUTF8String:prefs.background]];
        [palette setColor:XAColorBackground color:[NSColor colorWithPatternImage:image]];
        [image release];
    }
    [chatTextView setPalette:palette];
    
    [buttonBoxView setHidden:!prefs.userlistbuttons];
    [self setupUserlistButtons];
    
    SEL setupModeButtons = @selector(cleanHeaderBoxView);
    if (prefs.chanmodebuttons)
    {
        switch (sess->type) {
            case SESS_CHANNEL: setupModeButtons = @selector(setupChannelModeButtons); break;
            case SESS_DIALOG:  setupModeButtons = @selector(setupDialogButtons); break;
            default: break;
        }
    }
    [self performSelector:setupModeButtons];
    
    [self adjustSplitBar];
}

- (void)toggleConferenceMode:(id)sender
{
    sess->text_hidejoinpart = !sess->text_hidejoinpart;
    [sender setState:sess->text_hidejoinpart ? NSOnState : NSOffState];
}

- (void) doMircColor:(id)sender
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

- (void) setupSessMenuButton
{
    NSMenu *m = [sessMenuButton menu];
    
    // First item is the conference mode button
    
    [[m itemAtIndex:0] setState:sess->text_hidejoinpart ? NSOnState : NSOffState];
    
    NSRect rect = NSMakeRect (0.0f, 0.0f, 100.0f, 14.0f); // XXX: constant size used
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
        [mi setAction:@selector (doMircColor:)];
        [mi setImage:im];
        [mi setTag:-i];        // See do_mirc_color
        
        [m addItem:mi];
        [mi release];
        [im release];
    }
}

- (void) awakeFromNib
{
    [self.chatView setFrameSize:NSMakeSize (prefs.mainwindow_width, prefs.mainwindow_height)];
    [chatTextView setFrame:[chatScrollView documentVisibleRect]];
    
    [headerBoxView layoutNow];
    self->inputContainerView.layer = [CALayer layer];
    
    [self applyPreferences:nil];
    
    [self.chatView setServer:sess->server];
    [self.chatView setInitialFirstResponder:inputTextField];
    
    [chatTextView setDropHandler:self];
    [chatTextView setNextKeyView:inputTextField];
    
#if 0
    NSScroller *right_scroll_bar = [chatScrollView verticalScroller];
    scroll_target = [right_scroll_bar target];
    scroll_sel = [right_scroll_bar action];
    [right_scroll_bar setTarget:self];
    [right_scroll_bar setAction:@selector (user_scrolled:)];
#endif
    
    //[inputTextField setAllowsEditingTextAttributes:true];
    [inputTextField setTarget:self];
    [inputTextField setAction:@selector (doCommand:)];
    
    [userlistTableView setDoubleAction:@selector (doDoubleclick:)];
    [userlistTableView setTarget:self];
    [userlistTableView setDataSource:self];
    [userlistTableView setDelegate:self];
    [userlistTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
    
    //[inputTextField registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
    
    if (prefs.showhostname_in_userlist)
    {
        NSTableColumn *c = [[NSTableColumn alloc] initWithIdentifier:nil];
        [c setEditable:false];
        //[c setMaxWidth:250];
        //[c setMinWidth:250];
        //[c setWidth:250];
        [userlistTableView addTableColumn:c];
        [c release];
    }
    
    NSArray *cols = [userlistTableView tableColumns];
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
    
    [lagIndicator sizeToFit];
    [throttleIndicator sizeToFit];
    
    [progressIndicator setHidden:YES];
    [myOpOrVoiceIconImageView setHidden:YES];
    
    [headerBoxView setStretchView:topicTextField];
    [headerBoxView layoutNow];    // This allows topicTextField to keep it's place
    [topicTextField setAction:@selector(doTopicTextField:)];
    [topicTextField setTarget:self];
    
    [buttonBoxView setColumns:2 rows:0];
    [buttonBoxView setShrinkHoriz:NO vert:YES];
    [self setupUserlistButtons];
    
    [self setupSessMenuButton];
    [self clear];
    [self setNick];
    [self setTitle];
    [self setNonchannel:NO];
    
    if (sess->type == SESS_DIALOG)
        [self setChannel];
    else
        [self.chatView setTabTitle:NSLocalizedStringFromTable(@"<none>", @"xchat", @"")];
    
    
    if (sess->type == SESS_DIALOG)
    {
        if (prefs.privmsgtab)
            [self.chatView becomeTabAndShow:prefs.newtabstofront];
        else
            [self.chatView becomeWindowAndShow:true];
    }
    else
    {
        if (prefs.tabchannels)
            [self.chatView becomeTabAndShow:prefs.newtabstofront];
        else
            [self.chatView becomeWindowAndShow:true];
    }
    
    //[[inputTextField window] makeFirstResponder:inputTextField];
}

- (void) insertText:(NSString *) s
{
    NSMutableString *news = [NSMutableString stringWithString:[inputTextField stringValue]];
    [news appendString:s];
    [inputTextField setStringValue:news];
    NSWindow *win = [inputTextField window];
    NSResponder *res = [win firstResponder];
    if ([res isKindOfClass:[NSTextView class]])
    {
        NSTextView *tview = (NSTextView *) res;
        if ([tview delegate] == (id)inputTextField)
            [tview moveToEndOfParagraph:self];
    }
}

- (void) setLag:(NSNumber *) percent
{
    [lagIndicator setDoubleValue:[percent floatValue]];
}

/* CL: this is used for both buttons and menus, like userlistButton_cb in fe-gtk */
- (void) doUserlistCommand:(const char *) cmd
{
    if (sess->type == SESS_DIALOG)
    {
        nick_command_parse (sess, cmd, sess->channel, "");
        return;
    }
    
    if ([userlistTableView numberOfSelectedRows] < 1)
    {
        nick_command_parse (sess, cmd, "", "");
        return;
    }
    
    NSMutableString *allnicks = [[NSMutableString alloc] init];
    
    char *first_nick = NULL;
    bool using_allnicks = strstr (cmd, "%a");
    
    NSIndexSet *rowIndexSet = [userlistTableView selectedRowIndexes];
    for (NSUInteger rowIndex = [rowIndexSet firstIndex]; rowIndex != NSNotFound; rowIndex = [rowIndexSet indexGreaterThanIndex:rowIndex] )
    {
        ChannelUser *u = [users objectAtIndex:rowIndex];
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
    
    [allnicks release];
}

- (void) doUserlistButton:(id)sender
{
    struct popup *p = [(UserlistButton *)sender popup];
    [self doUserlistCommand:p->cmd];
}

- (void) setupUserlistButtons
{
    while ([[buttonBoxView subviews] count])
        [[[buttonBoxView subviews] objectAtIndex:0] removeFromSuperviewWithoutNeedingDisplay];
    
    for (GSList *list = button_list; list; list = list->next)
    {
        struct popup *p = (struct popup *) list->data;
        
        UserlistButton *button = [[UserlistButton alloc] initWithPopup:p];
        
        [button setAction:@selector (doUserlistButton:)];
        [button setTarget:self];
        
        [buttonBoxView addSubview:button];
        [button release];
    }
}

- (void) doDoubleclick:(id)sender
{
    if (prefs.doubleclickuser [0])
    {
        NSInteger row = [sender selectedRow];
        if (row >= 0)
        {
            ChannelUser *u = (ChannelUser *) [users objectAtIndex:row];
            struct User *user = u->user;
            nick_command_parse (sess, prefs.doubleclickuser, user->nick, user->nick);
        }
    }
}

- (void) clearChannel
{
    NSString *s;
    
    if (sess->waitchannel[0]) {
        NSMutableString *s2 = [NSMutableString stringWithUTF8String:sess->waitchannel];
        if (prefs.truncchans > 2 && [s2 length] > prefs.truncchans)
        {
            NSUInteger start = prefs.truncchans - 4;
            NSUInteger len = [s2 length] - start;
            [s2 replaceCharactersInRange:NSMakeRange(start, len) withString:@".."];
        }
        s = [NSString stringWithFormat:@"(%@)", s2];
    } else {
        s = NSLocalizedStringFromTable(@"<none>", @"xchat", @"");
    }
    
    [self.chatView setTabTitle:s];
    [self.chatView setTabTitleColorIndex:XAColorForeground];

    [myOpOrVoiceIconImageView setHidden:YES];
    [limitTextField setStringValue:@""];
    
    [self setTopic:""];
}

- (void) clear
{
    [chatTextView clearText];
}

- (void) closeWindow
{
    [self.chatView close];
}

#pragma mark Property interface

- (NSWindow *) window
{
    return self.view.window;
}

- (struct session *)session
{
    return sess;
}

#pragma mark NSWindow delegate

/*
 * Update xchat preferences with new sizes for the main window.
 * TODO: Use Cocoa user defaults and live auto-save
 */
- (void) windowDidResize:(NSNotification *) resizeNotification
{
    NSWindow *window = resizeNotification.object;
    NSRect windowRectangle = window.frame;
    
    prefs.mainwindow_width  = windowRectangle.size.width;
    prefs.mainwindow_height = windowRectangle.size.height;
}

/*
 * Update xchat preferences with new positions for the main window.
 * TODO: Use Cocoa user defaults and live auto-save
 */
- (void) windowDidMove:(NSNotification *) moveNotification
{
    NSWindow *window = moveNotification.object;
    NSRect windowRectangle = window.frame;
    
    prefs.mainwindow_top  = windowRectangle.origin.y;
    prefs.mainwindow_left = windowRectangle.origin.x;
}

- (void) windowWillClose:(NSNotification *) notification
{
    session_free (sess);
    
    // common will find new front_session for each server, but it wont
    // find a new current_sess.  We had assumed that by closing this session,
    // a new session would appear on top, and thus generating a windowDidBecomeKey
    // for a different window, and thus setting current_sess.  The problem is
    // that the new top window may not be a chat window and thus current_sess
    // points to a zombie.  We need to find any session for current_sess.
    
    if (current_sess == sess)
        current_sess = sess_list ? (struct session *) sess_list->data : NULL;
    
    //printf ("current session is 0x%x\n", current_sess);
}

- (void) windowDidBecomeKey:(NSNotification *) notification
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
        [self setTabColor:0 flash:false];
    }
    
    fe_set_away (sess->server);
}

- (void) setTabColor:(int)col flash:(BOOL)flash
{
    if (col == 0 || sess != current_tab)
    {
        switch (col)
        {
            case 0: /* no particular color (theme default) */
                sess->new_data = false;
                sess->msg_said = false;
                sess->nick_said = false;
                [self.chatView setTabTitleColorIndex:XAColorForeground];
                break;
                
            case 1: /* new data has been displayed (dark red) */
                sess->new_data = true;
                sess->msg_said = false;
                sess->nick_said = false;
                [self.chatView setTabTitleColorIndex:XAColorNewData];
                break;
                
            case 2: /* new message arrived in channel (light red) */
                sess->new_data = false;
                sess->msg_said = true;
                sess->nick_said = false;
                [self.chatView setTabTitleColorIndex:XAColorNewMessage];
                break;
                
            case 3: /* your nick has been seen (blue) */
                sess->new_data = false;
                sess->msg_said = false;
                sess->nick_said = true;
                [self.chatView setTabTitleColorIndex:XAColorNickMentioned];
                break;
        }
    }
}

- (void) doTopicTextField:(id)sender
{
    if (sess->channel[0] && sess->server->connected)
    {
        const char *topic = [[topicTextField stringValue] UTF8String];
        sess->server->p_topic (sess->server, sess->channel, (char *) topic);
    }
    
    [[inputTextField window] makeFirstResponder:inputTextField];
}

- (void) doLButton:(id)sender
{
    set_l_flag (sess, [sender state] == NSOnState, [limitTextField intValue]);
}

- (void) doKButton:(id)sender
{
    set_k_flag (sess, [sender state] == NSOnState, (char *) [[keyTextField stringValue] UTF8String]);
}

- (void) doBButton:(id)sender
{
    [[UtilityTabOrWindowView utilityByKey:UtilityWindowKey(BanWindowKey, sess) viewNibName:@"BanWindow"] becomeTabOrWindowAndShow:YES];
}

- (void) doFlagButton:(id)sender
{
    change_channel_flag (sess, [sender tag], [sender state] == NSOnState);
}

- (void) doKeyTextField:(id)sender
{
    if (sess->server->connected && sess->channel[0])
    {
        [kButton setState:NSOnState];
        [self doKButton:kButton];
    }
}

- (void) doLimitTextField:(id)sender
{
    if (sess->server->connected && sess->channel[0])
    {
        [lButton setState:NSOnState];
        [self doLButton:lButton];
    }
}

- (void) modeButtons:(char) mode sign:(char) sign
{
    NSButton *button = nil;
    
    switch (mode)
    {
        case 't': button = tButton; break;
        case 'n': button = nButton; break;
        case 's': button = sButton; break;
        case 'i': button = iButton; break;
        case 'p': button = pButton; break;
        case 'm': button = mButton; break;
        case 'b': button = bButton; break;
        case 'l': button = lButton; break;
        case 'k': button = kButton; break;
        case 'C': button = CButton; break;
        case 'N': button = NButton; break;
        case 'u': button = uButton; break;
        default: return;
    }
    
    [button setState:sign == '+' ? NSOnState : NSOffState];
    
    // Can't do this..  We really need to know if our user mode allows
    // us to edit the topic.. can we know that for sure given the various
    // operator levels that exist?
    //if (mode == 't')
    //    [topicTextField setEditable:sign == '-'];
}

- (void) setTopic:(const char *) topic
{
    ColorPalette *palette = [[[AquaChat sharedAquaChat] palette] copy];
    
    [palette setColor:XAColorForeground color:[NSColor blackColor]];
    [palette setColor:XAColorBackground color:[NSColor whiteColor]];
    
    [topicTextField setStringValue:[MIRCString stringWithUTF8String:topic
                                                            palette:palette
                                                               font:nil
                                                           boldFont:nil]];
    [palette release];
}

- (void)setChannel
{
    NSMutableString *channelString = [NSMutableString stringWithUTF8String:sess->channel];
    
    if (prefs.truncchans && [channelString length] > prefs.truncchans)
    {
        NSUInteger start = prefs.truncchans - 2;
        NSUInteger len = [channelString length] - start;
        [channelString replaceCharactersInRange:NSMakeRange (start, len) withString:@".."];
    }
    [self.chatView setTabTitle:channelString];
    [self.chatView setTabTitleColorIndex:XAColorForeground];
}

- (void) setNonchannel:(bool) state
{
    [tButton setEnabled:state];
    [nButton setEnabled:state];
    [sButton setEnabled:state];
    [iButton setEnabled:state];
    [pButton setEnabled:state];
    [mButton setEnabled:state];
    [bButton setEnabled:state];
    [lButton setEnabled:state];
    [kButton setEnabled:state];
    [CButton setEnabled:state];
    [NButton setEnabled:state];
    [uButton setEnabled:state];
    [limitTextField setEnabled:state];
    [keyTextField setEnabled:state];
    [topicTextField setEditable:state];
}

- (void) setNick
{
    [nickTextField setStringValue:[NSString stringWithUTF8String:sess->server->nick]];
    [nickTextField sizeToFit];
}

- (NSInteger) findUser:(struct User *) user
{
    for (NSUInteger i = 0; i < [users count]; i ++)
        if ([(ChannelUser *)[users objectAtIndex:i] user] == user)
            return i;
    return NSNotFound;
}

/* CL */
- (NSInteger) findUser:(struct User *) user returnObject:(ChannelUser **) userObject
{
    for (NSUInteger i = 0, n = [users count]; i < n; i++) {
        ChannelUser *u = (ChannelUser *) [users objectAtIndex:i];
        if ([u user] == user) {
            *userObject = u;
            return i;
        }
    }
    *userObject = nil;
    return NSNotFound;
}
/* CL end */

- (NSImage *) imageForUser:(struct User *) user
{
    switch (user->prefix [0])
    {
        case '@': return greenBulletImage;
        case '%': return blueBulletImage;
        case '+': return yellowBulletImage;
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
                    case 0: return redBulletImage;        /* 1 level above op */
                    case 1: return purpleBulletImage;    /* 2 levels above op */
                }
                break;                                /* 3+, no icons */
            }
            level++;
            if (pre == sess->server->nick_prefixes)
                break;
            pre--;
        }
    }
    return emptyBulletImage;
}

/* CL */
- (void) recalculateUserTableLayout
{
    maxNickWidth = 0.0f;
    maxHostWidth = 0.0f;
    maxRowHeight = 16.0f;
    
    for ( ChannelUser *user in users ) {
        if (user->nickSize.width > maxNickWidth) maxNickWidth = user->nickSize.width;
        if ((prefs.showhostname_in_userlist) && (user->hostSize.width > maxHostWidth)) maxHostWidth = user->hostSize.width;
        if (user->nickSize.height > maxRowHeight) maxRowHeight = user->nickSize.height;
    }
    
    NSTableColumn *column = [[userlistTableView tableColumns] objectAtIndex:1];
    [column sizeToFit];
    if (maxNickWidth != [column width]) [column setWidth: maxNickWidth];
    if (prefs.showhostname_in_userlist) {
        column = [[userlistTableView tableColumns] objectAtIndex:2];
        if (maxHostWidth != [column width]) [column setWidth: maxHostWidth];
    }
    if (maxRowHeight != [userlistTableView rowHeight]) [userlistTableView setRowHeight: maxRowHeight];
}

- (void) updateUserTableLayoutForInsert:(ChannelUser *) user
{
    NSArray *columns = [userlistTableView tableColumns];
    /* nickname column */
    NSTableColumn *column = [columns objectAtIndex:1];
    CGFloat width = user->nickSize.width;
    if (width > maxNickWidth) {
        maxNickWidth = width+0.5f; // Leopard fix :) Where this 0.25 come from?// WEIRDNESS
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
        [userlistTableView setRowHeight: height];
    }
}

- (void) updateUserTableLayoutForRemove:(ChannelUser *) user
{
    /* nickname column */
    if (user->nickSize.width == maxNickWidth) [self recalculateUserTableLayout];
    /* host column */
    else if ((prefs.showhostname_in_userlist) && (user->hostSize.width == maxHostWidth)) [self recalculateUserTableLayout];
    /* row height */
    else {
        CGFloat height = (user->nickSize.height > user->hostSize.height ? user->nickSize.height: user->hostSize.height);
        if ((height == maxRowHeight) && (height > 16.0f)) [self recalculateUserTableLayout];    /* in this case, a stricter condition should be added, as (oldHeight == [userlistTableView rowHeight]) will be true for most users */
    }
}

- (void) updateUserTableLayoutForRehash:(ChannelUser *)user oldNickSize:(NSSize)oldNickSize oldHostSize:(NSSize)oldHostSize
{
    NSArray *columns = [userlistTableView tableColumns];
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
    if ((height < oldHeight) && (oldHeight == maxRowHeight) && (oldHeight > 16.0f)) {    /* in this case, a stricter condition should be added, as (oldHeight == [userlistTableView rowHeight]) will be true for most users */
        [self recalculateUserTableLayout];
        return;
    }
    else if (height > maxRowHeight) {
        maxRowHeight = height;
        [userlistTableView setRowHeight: height];
    }
}

- (void) rehashUserAndUpdateLayout:(ChannelUser *)user
{
    NSSize oldNickSize = user->nickSize;
    NSSize oldHostSize = user->hostSize;
    [user rehash];
    [user cacheSizesForTable: userlistTableView];
    [self updateUserTableLayoutForRehash:user oldNickSize:oldNickSize oldHostSize:oldHostSize];
    [userlistTableView reloadData];
}

- (void) userlistSelectNames:(char **)names clear:(int)clear scrollTo:(int)scroll_to
{
    if (clear) [userlistTableView deselectAll:self];
    
    if (*names[0]) {
        for (NSUInteger i = 0, n = [users count]; i < n; i++) {
            struct User *user = [(ChannelUser *)[users objectAtIndex:i] user];
            NSUInteger j = 0;
            do {
                if (sess->server->p_cmp (user->nick, names[j]) == 0) {
                    [userlistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:i]
                                   byExtendingSelection:YES];
                    if (scroll_to) [userlistTableView scrollRowToVisible:i];
                }
            } while (*names[++j]);
        }
    }
}
/* CL end */

- (void) userlistRehash:(struct User *) user
{
    /* CL */
    ChannelUser *u;
    NSInteger idx = [self findUser:user returnObject:&u];
    if (idx == NSNotFound) return;
    [self rehashUserAndUpdateLayout:u];
    /* CL end */
}

- (void) userlistInsert:(struct User *)user row:(NSInteger)row select:(BOOL)select
{
    ChannelUser *u = [[ChannelUser alloc] initWithUser:user];
    /* CL */
    [u cacheSizesForTable: userlistTableView];
    [self updateUserTableLayoutForInsert: u];
    /* CL end */
    
    if (row < 0) {
        [users addObject:u];
    } else {
        NSInteger selectedRow = [userlistTableView selectedRow];
        [users insertObject:u atIndex:row];
        if (selectedRow >= 0 && row <= selectedRow)
            [userlistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow+1] byExtendingSelection:NO];
    }
    
    if (select) {
        [userlistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    
    [userlistTableView reloadData];
    
    if (user->me) {
        NSImage *img = [self imageForUser:user];
        if (img == emptyBulletImage) {
            [myOpOrVoiceIconImageView setHidden:YES];
        } else {
            [myOpOrVoiceIconImageView setImage:img];
            [myOpOrVoiceIconImageView setHidden:NO];
        }
    }
    [u release];
}

- (BOOL) userlistRemove:(struct User *) user
{
    /* CL */
    ChannelUser *u;
    NSInteger idx = [self findUser:user returnObject:&u];
    if (idx == NSNotFound) return NO;
    
    NSInteger srow = [userlistTableView selectedRow];
    [u retain];
    [users removeObjectAtIndex:idx];
    [self updateUserTableLayoutForRemove: u];
    [u release];
    /* CL end */
    if (idx < srow)
        [userlistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:srow-1] byExtendingSelection:NO];
    else if (idx == srow)
        [userlistTableView deselectAll:self];
    [userlistTableView reloadData]; 
    
    return srow == idx;
}

- (void) userlistMove:(struct User *)user row:(NSInteger) row
{
    /* CL */
    ChannelUser *u;
    NSInteger i = [self findUser:user returnObject:&u];
    if (i == NSNotFound) return;
    
    if (i != row) {
        [u retain];        //<--
        [users removeObjectAtIndex:i];
        [users insertObject:u atIndex:row];
        [u release];    //<--
        
        NSInteger srow = [userlistTableView selectedRow];
        if (i == srow) srow = row;
        else {
            if (i < srow) srow--;
            if (row <= srow) srow++;
        }
        [userlistTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:srow] byExtendingSelection:NO];
    }
    
    [self rehashUserAndUpdateLayout: u];
    
    if (user->me)
    {
        NSImage *img = [self imageForUser:user];
        if (img == emptyBulletImage)
            [myOpOrVoiceIconImageView setHidden:YES];
        else
        {
            [myOpOrVoiceIconImageView setImage:img];
            [myOpOrVoiceIconImageView setHidden:NO];
        }
    }
    /* CL end */
}

- (TabOrWindowView *)chatView {
    return (id)self.view;
}

- (void) progressbarStart
{
    [progressIndicator startAnimation:self];
    [progressIndicator setHidden:NO];
}

- (void) progressbarEnd
{
    [progressIndicator setHidden:YES];
    [progressIndicator stopAnimation:self];
}

// Used only for updating menus
- (void) userlistUpdate:(struct User *)user
{
    if(userlistMenuItemCurrentUser && !strcmp(userlistMenuItemCurrentUser->nick, user->nick))
        [userlistMenuItem setSubmenu:[[MenuMaker defaultMenuMaker] infoMenuForUser:user inSession:sess]];
}

- (void) userlistNumbers
{
    [userlistStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d ops, %d total", @"xchat", @""), sess->ops, sess->total]];
}

- (void) userlistClear
{
    [users removeAllObjects];
    /* CL */
    [self recalculateUserTableLayout];
    /* CL end */
    [userlistTableView reloadData]; 
}

- (void) channelLimit
{
    [limitTextField setIntValue:sess->limit];
    [self setTitle];
}

- (void) setThrottle
{
    double per = (double) sess->server->sendq_len / 1024.0;
    if (per > 1.0) per = 1.0;
    
    [throttleIndicator setDoubleValue:per];
}

- (void) setHilight
{
    [self setTabColor:3 flash:YES];
}

- (void) setTitle
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
            title = [NSString stringWithFormat:@"X-Chat [%s/%s]", XCHAT_AQUA_VERSION_STRING, PACKAGE_VERSION];
    }
    [self.chatView setTitle:title];
}

- (void) doCommand:(id)sender
{
    [[inputTextField window] makeFirstResponder:inputTextField];
    
    NSString* message = [inputTextField stringValue];
    
    if ([message length] < 1)
        return;
    
    [inputTextField setStringValue:@""];
    
    char *msg = strdup([message UTF8String]);
    handle_multiline (sess, msg, TRUE, FALSE);
    free(msg);
    // Don't do anything there.. previous command might have killed us.
}

- (void) lastlogIntoWindow:(ChatViewController *)logWin key:(char *)ckey
{
    
    if ([[chatTextView textStorage] length] == 0) {
        [logWin printText:NSLocalizedStringFromTable(@"Search buffer is empty.\n", @"xchat", @"")];
        return;
    }
    NSTextStorage *sourceStorage = [chatTextView textStorage];
    NSTextStorage *destStorage = [logWin->chatTextView textStorage];
    NSString *text = [sourceStorage string];
    NSString *key = [NSString stringWithUTF8String:ckey];
    NSUInteger length = [text length];
    NSUInteger start = 0;
    while (true) {
        NSRange keyRange = [text rangeOfString:key options:NSCaseInsensitiveSearch range:NSMakeRange(start, length - start)];
        if (keyRange.location == NSNotFound) break;
        
        NSRange lineRange = [text lineRangeForRange:keyRange];
        NSMutableAttributedString *result = [[sourceStorage attributedSubstringFromRange:lineRange] mutableCopy];
        
        keyRange.location -= lineRange.location;    /* make range relative to result */
        [result applyFontTraits:NSFontBoldTrait range:keyRange];
        
        [destStorage appendAttributedString:result];
        [result release];
        start = NSMaxRange(lineRange);
    }
    
}

- (void) printText:(NSString *)text
{
    [self printText:text stamp:time(NULL)];
}

- (void) printText:(NSString *)text stamp:(time_t)stamp
{
    [chatTextView printText:text stamp:stamp];
    
    if (!sess->new_data && sess != current_tab && !sess->nick_said)
    {
        if (sess->msg_said)    // Channel message
            [self setTabColor:2 flash:NO];
        else                // Server message?  Not sure..?
            [self setTabColor:1 flash:NO];
    }
}

- (BOOL) processFileDrop:(id<NSDraggingInfo>)info forUser:(NSString *)nick
{
    NSPasteboard *pboard = [info draggingPasteboard];
    
    if (![[pboard types] containsObject:NSFilenamesPboardType]) 
        return NO;
    
    if (!nick)
    {
        if (sess->type == SESS_DIALOG)
            nick = [NSString stringWithUTF8String:sess->channel];
        else
        {
            NSInteger row = [userlistTableView selectedRow];
            if (row < 0)
                return NO;
            nick = [[userlistTableView dataSource] tableView:userlistTableView
                                   objectValueForTableColumn:[[userlistTableView tableColumns] objectAtIndex:1]
                                                         row:row];
        }
    }
    
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    for ( id file in files ) {
        dcc_send (sess, (char *)[nick UTF8String], (char *)[file UTF8String], prefs.dcc_max_send_cps, 0);
    }
    return YES;
}

- (void) userlistSetSelected
{
    for (NSUInteger row = 0; row < [users count]; row++)
    {
        ChannelUser *u = [users objectAtIndex:row];
        u->user->selected = [userlistTableView isRowSelected:row];
    }
}

#pragma mark Property interface

- (NSString *) inputText
{
    return [inputTextField stringValue];
}

- (void) setInputText:(NSString *)text
{
    if (!text) return;
    
    [inputTextField setStringValue:text];
    [[[inputTextField window] firstResponder] moveToEndOfParagraph:self];
}

- (NSUInteger) inputTextPosition
{
    NSWindow *win = [inputTextField window];
    NSTextView *view = (NSTextView*)[win firstResponder];
    if ([view isKindOfClass:[NSTextView class]] && (NSTextField *)[view delegate] == inputTextField)
    {
        NSUInteger loc = [view selectedRange].location;
        return loc;
    }
    return 0;
}

- (void) setInputTextPosition:(int) pos delta:(bool) delta
{
    NSWindow *win = [inputTextField window];
    NSTextView *view = (NSTextView*)[win firstResponder];
    if ([view isKindOfClass:[NSTextView class]] && (NSTextField *)[view delegate] == inputTextField)
    {
        if (delta)
        {
            pos += [self inputTextPosition];
        }
        NSRange range;
        range.location = pos;
        range.length = 0;
        [view setSelectedRange:range];
    }
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [users count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
    ChannelUser *u = [users objectAtIndex:row];
    switch ([[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn])
    {
        case 0: return [self imageForUser:u->user];
        case 1: return u->nick;
        case 2: return u->host;
    }
    SGAssert(NO);
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
    return [self processFileDrop:info forUser:[nick string]];
}

- (NSMenu *)menuForEvent:(NSEvent *)theEvent rowIndexes:(NSIndexSet *)rows
{
    NSUInteger count = [rows count];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSString *nick = nil;
    
    [menu setAutoenablesItems:false];
    if(userlistMenuItem)
        [userlistMenuItem release];
    
    if (count > 1) {
        [[menu addItemWithTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"%d users selected", @"xchataqua", @"Popup menu message when you right-clicked userlist."), count] action:nil keyEquivalent:@""] setEnabled:NO];
        userlistMenuItemCurrentUser = NULL;
    } else {
        ChannelUser *userObject = (ChannelUser *) [users objectAtIndex:[rows firstIndex]];
        struct User *user = [userObject user];
        
        nick = [userObject nick];
        NSMenuItem *userItem = [menu addItemWithTitle:nick action:nil keyEquivalent:@""];
        
        userlistMenuItemCurrentUser = user;
        userlistMenuItem         = [userItem retain];
        
        [userItem setSubmenu:[[MenuMaker defaultMenuMaker] infoMenuForUser:user inSession:sess]];
        
    }
    [menu addItem:[NSMenuItem separatorItem]];
    
    [[MenuMaker defaultMenuMaker] appendItemList:popup_list toMenu:menu withTarget:nick inSession:sess];
    
    return menu;
}


/*
 * MARK: -
 * MARK: Tab completion
 */

// Accessor for the completionIndex instance variable.
@synthesize completionIndex;

// Takes an NSArray of NSString and returns the shortest common prefix length.
- (NSInteger) shortestCommonPrefixLength:(NSArray *)matches
{
    if ([matches count] < 1) return 0;
    
    NSString *shortestPrefix = [[matches objectAtIndex:0] stringValue];
    
    for (TabCompletionItem *thisItem in matches) {
        NSString *commonPrefix = [thisItem.stringValue commonPrefixWithString:shortestPrefix options:NSCaseInsensitiveSearch];
        if ([commonPrefix length] < [shortestPrefix length]) {
            shortestPrefix = commonPrefix;
        }
    }
    return [shortestPrefix length];
}

- (NSArray *) command_complete:(NSTextView *) view start:(NSString *) start
{
    const char *utf = [start UTF8String];
    size_t len = strlen (utf);
    
    // Use a set because stupid user commands appear multiple times!
    NSMutableSet *matchArray = [NSMutableSet set];
    
    for (GSList *list = command_list; list; list = list->next)
    {
        struct popup *pop = (struct popup *) list->data;
        size_t this_len = strlen (pop->name);
        if (len <= this_len && strncasecmp (utf, pop->name, len) == 0)
            [matchArray addObject:[TabCompletionItem completionWithValue:[NSString stringWithUTF8String:pop->name]]];
    }
    
    for (int i = 0; xc_cmds[i].name; i ++)
    {
        char *cmd = xc_cmds[i].name;
        size_t this_len = strlen (cmd);
        if (len <= this_len && strncasecmp (utf, cmd, len) == 0)
            [matchArray addObject:[TabCompletionItem completionWithValue:[NSString stringWithUTF8String:cmd]]];
    }
    
    return [matchArray allObjects];
}

- (NSArray *) nick_complete:(NSTextView *) view start:(NSString *) start
{
    const char *utf = [start UTF8String];
    size_t len = strlen (utf);
    
    NSMutableArray *matchArray = [[NSMutableArray alloc] init];
    
    if (sess->type == SESS_DIALOG)
    {
        size_t this_len = strlen (sess->channel);
        if (len > this_len || rfc_ncasecmp ((char *) utf, sess->channel, len) != 0) {
            [matchArray release];
            return nil;
        }
        [matchArray addObject:[TabCompletionItem completionWithValue:[NSString stringWithUTF8String:sess->channel]]];
    }
    else
    {
        for (ChannelUser *u in users) {
            struct User *user = u->user;
            size_t this_len = strlen (user->nick);
            if (len <= this_len && rfc_ncasecmp ((char *) utf, user->nick, len) == 0)
                [matchArray addObject:[NickCompletionItem nickWithNick:[NSString stringWithUTF8String:user->nick] lasttalk:user->lasttalk]];
        }
    }
    
    return [matchArray autorelease];
}

- (NSArray *) channel_complete:(NSTextView *)view start:(NSString *) start
{
    const char *utf = [start UTF8String];
    size_t len = strlen (utf);
    
    NSMutableArray *matchArray = [[NSMutableArray alloc] init];
    
    for (GSList *list = sess_list; list; list = list->next)
    {
        session *tmp_sess = (session *) list->data;
        
        if (tmp_sess->type == SESS_CHANNEL)
        {
            size_t this_len = strlen (tmp_sess->channel);
            if (len <= this_len && strncasecmp (utf, tmp_sess->channel, len) == 0)
                [matchArray addObject:[TabCompletionItem completionWithValue:[NSString stringWithUTF8String:tmp_sess->channel]]];
        }
    }
    
    return [matchArray autorelease];
}

/*
 * Autocomplete Nicks, Commands, and Channels when TAB key is pressed.
 *
 */
- (void) tabComplete:(NSTextView *) view
{
    // Get the NSTextField's underlying NSTextStorage and its string value.
    NSTextStorage *textFieldStorage = [view textStorage];
    
    // NSRange to hold the actual text we'll be completing against, within the
    // whole string, and excluding any words before a space character etc.
    // We init with the whole string.
    NSRange completionTextRange = NSMakeRange(0, 0);
    
    // Get the selected range and the position of the insertion point.
    NSRange selectedRange = [view selectedRange];
    
    // There's no selection at all so something is wrong: bail out!
    if (selectedRange.location == NSNotFound)
        return;
    
    // If selected length is 0 there's no selection, just an insertion point.
    if (selectedRange.length == 0) {
        self.completionIndex = 0;
        completionTextRange.location = selectedRange.location;
        completionTextRange.length = 0;
    } else {
        // Nuke selected text; it's what we completed on last tab.
        [textFieldStorage replaceCharactersInRange:selectedRange withString:@""];
        selectedRange = [view selectedRange]; // Get updated selectionRange.
    }
    NSString *textFieldString = [textFieldStorage string];
    
    // Return if there's nothing to the left of the insertion point because
    // then we have nothing to complete.
    if (selectedRange.location == 0)
        return;
    
    // Return if the character before the insertion point is a space because
    // then we have nothing to complete.
    if ([textFieldString characterAtIndex:(selectedRange.location - 1)] == ' ')
        return;
    
    // Find the location of the last space character in the string, and then
    // grab its following characters as the completion string.
    NSCharacterSet *spaceCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" "];
    NSRange spaceRange = [textFieldString
                          rangeOfCharacterFromSet:spaceCharacterSet
                          options:NSBackwardsSearch
                          range:NSMakeRange(0, selectedRange.location)];
    
    
    if (spaceRange.location == NSNotFound) {
        // No space characters in the string. Complete on whole string up to selection.
        completionTextRange.location = 0;
        completionTextRange.length = selectedRange.location;
    } else {
        // Found a space character, and spaceRange has the NSRange for it.
        //
        // Our prefix to complete will be at the location given by spaceRange
        // plus one, because we don't want to include the actual space character.
        // Its length will be given by the total length of the string, minus the
        // position of the spaceRange; and minus one because we're excluding the
        // actual space character.
        completionTextRange.location = spaceRange.location + 1;
        completionTextRange.length = (textFieldString.length - spaceRange.location) - 1;
    }
    
    NSArray *matchArray;
    BOOL shouldAddSuffix = NO;
    
    // If we're in column 0 we're completing either a nick or a command.
    if (completionTextRange.location == 0)
    {
        // If the first char is the command char (/), it's a command.
        if ([textFieldString characterAtIndex:0] == prefs.cmdchar[0])
        {
            // Don't include the command char (/) in the prefix to complete.
            completionTextRange.location++;
            completionTextRange.length--;
            matchArray = [self command_complete:view start:[textFieldString substringWithRange:completionTextRange]];
        }
        // Otherwise it's a nick.
        else
        {
            matchArray = [self nick_complete:view start:[textFieldString substringWithRange:completionTextRange]];
            shouldAddSuffix = YES; // When we're in column 0, nicks get a ": " at the end.
        }
    }
    // If we're not in column 0 we're completing either a nick or a channel.
    else
    {
        // If the first char is a '#', it's a channel.
        if ([textFieldString characterAtIndex:(completionTextRange.location - 1)] == '#') {
            matchArray = [self channel_complete:view start:[textFieldString substringWithRange:completionTextRange]];
        } else {
            matchArray = [self nick_complete:view start:[textFieldString substringWithRange:completionTextRange]];
        }
    }
    
    // If there are no completions we bail out.
    if (!matchArray || [matchArray count] < 1) return;
    
    matchArray = [matchArray sortedArrayUsingSelector:@selector(compare:)];
    
    
    // Get the position and length of the common prefix.
    NSInteger shortestPrefix = [self shortestCommonPrefixLength:matchArray];
    
    // If there's only 1 possible match, then we're done.
    // If were doing the old style (bash style), and the common chars
    // exceed what we typed, we'll complete up to the ambiguity.
    if ([matchArray count] == 1 || (!prefs.xa_scrolling_completion && shortestPrefix > completionTextRange.length))
    {
        NSString *first = [[matchArray objectAtIndex:0] stringValue];
        NSMutableString *rightMutableString = [NSMutableString stringWithString:[first substringToIndex:shortestPrefix]];
        if ([matchArray count] == 1)
        {
            if (shouldAddSuffix && prefs.nick_suffix[0]) {
                [rightMutableString appendString:[NSString stringWithUTF8String:prefs.nick_suffix]]; 
            }
            [rightMutableString appendString:@" "];
        }
        [textFieldStorage replaceCharactersInRange:completionTextRange withString:rightMutableString];
        return;
    }
    
    if (prefs.xa_scrolling_completion)
    {
        NSString *completionItem = [[matchArray objectAtIndex:self.completionIndex] stringValue];
        
        // Final string to insert.
        NSMutableString *replacementString = [NSMutableString stringWithString:@""];
        
        // Replace the part he typed, just so the case will match
        NSString *leftString = [completionItem substringToIndex:completionTextRange.length];
        //        [view replaceCharactersInRange:completionTextRange withString:leftString];
        [replacementString appendString:leftString];
        
        // Now add the completion part as a "marked" area.
        NSString *rightString = [completionItem substringFromIndex:completionTextRange.length];
        NSMutableString *rightMutableString = [NSMutableString stringWithString:rightString];
        
        // Tack on the nick suffix if set.
        if (shouldAddSuffix && prefs.nick_suffix[0]) {
            [rightMutableString appendString:[NSString stringWithUTF8String:prefs.nick_suffix]]; 
        }
        [rightMutableString appendString:@" "];
        
        [replacementString appendString:rightMutableString];
        
        [textFieldStorage replaceCharactersInRange:completionTextRange withString:replacementString];
        NSUInteger insertAt = (completionTextRange.location + leftString.length);
        NSUInteger insertTo = [rightMutableString length];
        [view setSelectedRange:NSMakeRange(insertAt, insertTo)];
        self.completionIndex = (self.completionIndex + 1) % [matchArray count];
    }
    else
    {
        [self printText:[matchArray componentsJoinedByString:@" "]];
    }
}

/*
 * MARK: -
 * MARK: Handle command keys
 *
 * inputTextField delegate and helper functions.
 */
- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor
{
    if (prefs.gui_input_spell)
        [(NSTextView *)fieldEditor setContinuousSpellCheckingEnabled:YES];
    
    return YES;
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    prefs.gui_input_spell = [(NSTextView *)fieldEditor isContinuousSpellCheckingEnabled];
    [(NSTextView *)fieldEditor setContinuousSpellCheckingEnabled:NO];
    return YES;
}

/*
 * Called by the NSControlTextEditingDelegate Protocol when a “command” key is
 * pressed (tab, return, escape, etc.) and passed a selector. Returns a BOOL
 * indicating whether we handled the selector or not.
 *
 * - See also the «NSControlTextEditingDelegate Protocol Reference»:
 * http://developer.apple.com/mac/library/documentation/cocoa/reference/NSControlTextEditingDelegate_Protocol/Reference/Reference.html
 *
 * - See also the «Cocoa Event Architecture»:
 * http://developer.apple.com/mac/library/documentation/cocoa/conceptual/EventOverview/EventArchitecture/EventArchitecture.html
 *
 * - See also the «Class Hierarchy of the Cocoa Text System»:
 * http://developer.apple.com/mac/library/documentation/cocoa/Conceptual/TextArchitecture/Concepts/TextSysClassHier.html
 *
 */
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    // By default we do not handle the selector.
    BOOL didHandleSelector = NO;
    
    /*
     * Check the passed in selector against the ones we have handlers for.
     */
    
    // Shift+Return inserts a literal newline.
    if (commandSelector == @selector(insertNewline:))
    {
        NSEvent *theEvent = [NSApp currentEvent];
        if ([theEvent type] == NSKeyDown && ([theEvent modifierFlags] & NSShiftKeyMask))
        {
            [textView insertNewlineIgnoringFieldEditor:control];
            didHandleSelector = YES;
        }
    }
    
    // Up/down-arrow scroll through your input history.
    else if (commandSelector == @selector(moveUp:))
    {
        const char *prevInput = history_up(&sess->history, (char *) [[inputTextField stringValue] UTF8String]);
        if (prevInput != NULL) {
            [self setInputText:[NSString stringWithUTF8String:prevInput]];
        }
        didHandleSelector = YES;
    }
    else if (commandSelector == @selector(moveDown:))
    {
        const char *nextInput = history_down(&sess->history);
        [self setInputText:nextInput == NULL ? @"" : [NSString stringWithUTF8String:nextInput]];
        didHandleSelector = YES;
    }
    
    // Handle Page-Up / Page-Down / Home / End
    // (scroll channel window the appropriate direction).
    else if (commandSelector == @selector(scrollPageDown:))
    {
        [chatTextView scrollPageDown:textView];
        didHandleSelector = YES;
    }
    else if (commandSelector == @selector(scrollPageUp:))
    {
        [chatTextView scrollPageUp:textView];
        didHandleSelector = YES;
    }
    else if (commandSelector == @selector(scrollToBeginningOfDocument:))
    {
        [chatTextView scrollToBeginningOfDocument:textView];
        didHandleSelector = YES;
    }
    else if (commandSelector == @selector(scrollToEndOfDocument:))
    {
        [chatTextView scrollToEndOfDocument:textView];
        didHandleSelector = YES;
    }
    
    // Tab key auto-completes nicks, channels, and commands (if enabled in prefs).
    else if (commandSelector == @selector(insertTab:))
    {
        if (prefs.xa_tab_completion) {
            [self tabComplete:textView];
            didHandleSelector = YES;
        }
        else
        {
            /*
             * FIXME: This shouldn't be needed.
             *
             * If we return NO, NSResponder will handle the original insertTab: selector.
             */
            [textView insertTab:textView];
            didHandleSelector = YES;
        }
    }
    
    return didHandleSelector;
}

- (void)viewDidMoveToSuperview:(NSView *)view {
    if (sess->type != SESS_CHANNEL) return;
    if (view.superview == nil) {
        userlistSplitView.delegate = nil;
    } else {
        [self adjustSplitBar];
        userlistSplitView.delegate = self;
    }
}

#pragma mark -

- (void)splitViewDidResizeSubviews:(NSNotification *)notification {
    [notification.object viewDidResize:self];
}

@end
