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
#import "ChannelListWin.h"
#import "mIRCString.h"

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
}

//////////////////////////////////////////////////////////////////////

static SEL sort_funcs [] = 
{
    @selector (sort_by_chan_reverse:),
    @selector (sort_by_chan:),
    @selector (sort_by_nusers_reverse:),
    @selector (sort_by_nusers:),
    @selector (sort_by_topic_reverse:),
    @selector (sort_by_topic:),
};

//////////////////////////////////////////////////////////////////////

@interface one_entry : NSObject
{
  @public
    NSString	*chan;
    NSString	*nusers;
    mIRCString	*topic;
    int		nusers_val;		// For sorting.. is it really helping?
    NSSize      size;
}

+ (id) entryWithChan:(const char *) the_chan
              nusers:(const char *) the_nusers
               topic:(const char *) the_topic
             palette:(ColorPalette *) palette;

- (NSString *) chan;
- (NSString *) nusers;
- (mIRCString *) topic;
- (int) nusers_val;
- (NSComparisonResult) sort_by_chan:(one_entry *) other;
- (NSComparisonResult) sort_by_nusers:(one_entry *) other;
- (NSComparisonResult) sort_by_topic:(one_entry *) other;
- (NSComparisonResult) sort_by_chan_reverse:(one_entry *) other;
- (NSComparisonResult) sort_by_nusers_reverse:(one_entry *) other;
- (NSComparisonResult) sort_by_topic_reverse:(one_entry *) other;

@end

// For some reason, the Mac does not like UTF8 0xc2 '< 0xa0'
// We'll also strip tabs.. anything else?
static const char *
strip_crap (const char *s)
{
    static char buff [512];
    
    char *eob = buff + sizeof (buff) - 1;
    
    char *d = buff;
    while (*s && d < eob)
    {
        if (*s == (char) 0xc2 && s[1] < (char) 0xa0)
        {
            s += 2;
            continue;
        }
        else if (*s == '\t')
        {
            s ++;
            continue;
        }
           
        *d++ = *s++;
    }
    
    *d = 0;
    
    return buff;
}


@implementation one_entry

+ (id) entryWithChan:(const char *) the_chan
              nusers:(const char *) the_nusers
               topic:(const char *) the_topic
             palette:(ColorPalette *) palette
{
	one_entry *e = [[[one_entry alloc] init] autorelease];
    e->chan = [[NSString stringWithUTF8String:the_chan] retain];
    e->nusers = [[NSString stringWithUTF8String:the_nusers] retain];
    e->size = NSZeroSize;
    
    //e->topic = [[NSString stringWithUTF8String:the_topic] retain];
    const char *t = strip_crap (the_topic);
    
    e->topic = [[mIRCString stringWithUTF8String:t
                                             len:-1
                                         palette:palette
                                            font:NULL
                                        boldFont:NULL] retain];
		
    e->nusers_val = [e->nusers intValue];
    
	// Some of the UTF8
    return e;
}

- (void) dealloc
{
    [chan release];
    [nusers release];
    [topic release];

    [super dealloc];
}

- (NSComparisonResult) sort_by_chan:(one_entry *) other
{
    return [chan compare:other->chan];
}

- (NSComparisonResult) sort_by_nusers:(one_entry *) other
{
    if (nusers_val < other->nusers_val) return NSOrderedAscending;
    if (nusers_val > other->nusers_val) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSComparisonResult) sort_by_topic:(one_entry *) other
{
    return [[topic string] compare:[other->topic string]];
}

- (NSComparisonResult) sort_by_chan_reverse:(one_entry *) other
{
    return [other->chan compare:chan];
}

- (NSComparisonResult) sort_by_nusers_reverse:(one_entry *) other
{
    if (other->nusers_val < nusers_val) return NSOrderedAscending;
    if (other->nusers_val > nusers_val) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSComparisonResult) sort_by_topic_reverse:(one_entry *) other
{
    return [[other->topic string] compare:[topic string]];
}

- (NSString *) chan { return chan; }
- (NSString *) nusers { return nusers; }
- (mIRCString *) topic { return topic; }
- (int) nusers_val { return nusers_val; }

@end

//////////////////////////////////////////////////////////////////////

@implementation ChannelListWin

- (id) initWithServer:(struct server *) server
{
    [super init];

    self->arrow = NULL;
    self->serv = server;
    self->timer = NULL;
    self->added = false;
    self->items = [[NSMutableArray arrayWithCapacity:0] retain];
    self->all_items = [[NSMutableArray arrayWithCapacity:0] retain];
    self->palette = [[[AquaChat sharedAquaChat] getPalette] clone];
    
    [self->palette setColor:AC_FGCOLOR color:[NSColor blackColor]];
    [self->palette setColor:AC_BGCOLOR color:[NSColor whiteColor]];

    sort_dir [0] = false;
    sort_dir [1] = false;
    sort_dir [2] = false;

    [NSBundle loadNibNamed:@"ChanList" owner:self];

    return self;
}

- (void) no_regex
{
    if (regex_valid)
    {
        regfree (&match_regex);
        regex_valid = false;
    }
}

- (void) dealloc
{
    [item_list setDelegate:NULL];
    [channel_list_view setDelegate:NULL];
    [channel_list_view close];
    [channel_list_view autorelease];
    [arrow release];
    [self no_regex];
    [items release];
    [palette release];
    [all_items release];
    
    if (timer)
    {
        [timer invalidate];
        [timer release];
    }
    
    [super dealloc];
}

- (void) update_caption
{
    [caption_text setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Displaying %d/%d users on %d/%d channels.", @"xchat", @""),
        users_shown_count, users_found_count, [items count], [all_items count]]];
}

- (void) reset_counters
{
    users_found_count = 0;
    users_shown_count = 0;
    
    [self update_caption];
}

- (void) awakeFromNib
{
    [channel_list_view setServer:serv];
    
    arrow = [[NSImage imageNamed:@"down.tiff"] retain];
    
    [channel_list_view setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Channel List (%s)", @"xchat", @""), self->serv->servername]];
    [channel_list_view setTabTitle:NSLocalizedStringFromTable(@"chanlist", @"xchataqua", @"")];
    
    for (int i = 0; i < [item_list numberOfColumns]; i ++)
        [[[item_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self reset_counters];
    
    [item_list setDataSource:self];
    [item_list setTarget:self];
    [item_list setDoubleAction:@selector (do_join:)];
    [item_list setDelegate:self];

#if 0    
    [top_box constrain:apply_button
                  edge:SGFormView_EDGE_LEFT
            attachment:SGFormView_ATTACH_CENTER
            relativeTo:NULL
                offset:0];
    
    [top_box bootstrapRelativeTo:apply_button];

    [bottom_box constrain:save_button
                     edge:SGFormView_EDGE_LEFT
               attachment:SGFormView_ATTACH_CENTER
               relativeTo:NULL
                   offset:0];
    
    [bottom_box bootstrapRelativeTo:save_button];
#endif

    [channel_list_view setDelegate:self];
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [channel_list_view becomeTabAndShow:true];
    else
        [channel_list_view becomeWindowAndShow:true];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    serv->gui->clc = NULL;
    [self release];
}

- (void) get_regex
{
    [self no_regex];
    
    NSString *s = [regex_text stringValue];
    
    if ([s length])
    {
        int sts = regcomp (&match_regex, [s UTF8String],
                        REG_ICASE | REG_EXTENDED | REG_NOSUB);
        regex_valid = sts == 0;
    }
}

- (bool) filter:(one_entry *) entry
{
    int num = [entry nusers_val];
    
    users_found_count += num;
    
    if (filter_min && num < filter_min)
        return false;

    if (filter_max && num > filter_max)
        return false;
    
    if (regex_valid)
    {        
		const char *topic = [[[entry topic] string] UTF8String];
		if (!topic) topic = "";
		const char *chan = [[entry chan] UTF8String];
		if (!chan) chan = "";
		
        if (topic_checked && channel_checked && 
            regexec (&match_regex, topic, 0, 0, REG_NOTBOL) != 0 &&
            regexec (&match_regex, chan, 0, 0, REG_NOTBOL) != 0)
        {
            return false;
        }
        else if (topic_checked && !channel_checked &&
            regexec (&match_regex, topic, 0, 0, REG_NOTBOL) != 0)
        {
            return false;
        }
        else if (!topic_checked && channel_checked && 
            regexec (&match_regex, chan, 0, 0, REG_NOTBOL) != 0)
        {
            return false;
        }
    }
    
    users_shown_count += num;
    
    [items addObject:entry];
    
    return true;
}

- (void) sort
{
    NSTableColumn *col = [item_list highlightedTableColumn];
    if (col)
    {
        int colnum = [[col identifier] intValue];
        [items sortUsingSelector:sort_funcs [(colnum << 1) + sort_dir [colnum]]];
    }
}

- (void) do_apply:(id) sender
{
    [items removeAllObjects];

    [self reset_counters];
    [self get_regex];

    filter_min = [min_text intValue];
    filter_max = [max_text intValue];

    topic_checked = [regex_topic intValue];
    channel_checked = [regex_channel intValue];

    for (unsigned int i = 0; i < [all_items count]; i ++)
        [self filter:[all_items objectAtIndex:i]];

    [self update_caption];
    [self sort];
    [item_list reloadData];
}

- (void) do_refresh:(id) sender
{
    if (serv->connected)
    {
        [all_items removeAllObjects];
        [self do_apply:sender];
        
        [refresh_button setEnabled:false];
        
        handle_command (serv->server_session, "list", FALSE);
    }
    else
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"Not connected.", @"xchat", @"") andWait:false];
}

- (void) chan_list_end
{
    [refresh_button setEnabled:true];
}

- (void) redraw:(id) sender
{
    [timer release];
    timer = NULL;
    
    [self update_caption];
    
    if (added)
    {
        [self sort];
        [item_list reloadData];
        added = false;
    }
}

- (void) do_save:(id) sender
{
}

- (void) do_join:(id) sender
{
    int row = [item_list selectedRow];
    
    if (row < 0)
        return;
    
    one_entry *e = [items objectAtIndex:row];

    if (serv->connected && ![[e chan] isEqualToString:@"*"])
    {
        char tbuf [512];
        snprintf (tbuf, sizeof (tbuf), "join %s", [[e chan] UTF8String]);
        handle_command (serv->server_session, tbuf, FALSE);
    }
}

- (void) add_chan_list:(const char *) chan
                 users:(const char *) users 
                 topic:(const char *) topic
{
    one_entry *new_item = [one_entry entryWithChan:chan nusers:users
                                    topic:topic palette:palette];
    
    [all_items addObject:new_item];
        
    added |= [self filter:new_item];
    
    if (!timer)
        timer = [[NSTimer scheduledTimerWithTimeInterval:1
                            target:self
                            selector:@selector(redraw:)
                            userInfo:nil
                            repeats:NO
                            retainArgs:NO] retain];
}

// Table View Data Source Methods

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    one_entry *e = [items objectAtIndex:rowIndex];
    
    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return [e chan];
        case 1: return [e nusers];
        case 2: return [e topic];
    }
    
    return @"";
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    return NO;
}

// Table delegate functions

- (BOOL) tableView:(NSTableView *) aTableView
    shouldSelectTableColumn:(NSTableColumn *) aTableColumn
{
    bool flip = [aTableView highlightedTableColumn] == aTableColumn;
    
    int col = [[aTableColumn identifier] intValue];
    
    if (flip)
    {
        sort_dir [col] = !sort_dir [col];
    }
    else
    {
        [aTableView setIndicatorImage:arrow inTableColumn:aTableColumn];
        [aTableView setIndicatorImage:NULL inTableColumn:[aTableView highlightedTableColumn]];
        [aTableView setHighlightedTableColumn:aTableColumn];
    }

    [arrow setFlipped:sort_dir [col]];
    
    [items sortUsingSelector:sort_funcs [(col << 1) + sort_dir [col]]];

    [item_list reloadData];
    
    return false;
}

- (NSSize) tableView:(NSTableView *) aTableView
    sizeHintForTableColumn:(NSTableColumn *) aTableColumn
        row:(int) rowIndex
{
    // This only supports the last column, for now
    one_entry *e = [items objectAtIndex:rowIndex];
    return e->size;
}

- (void) tableView:(NSTableView *) aTableView
    sizeHintForTableColumn:(NSTableColumn *) aTableColumn
        row:(int) rowIndex
        size:(NSSize) size
{
    // This only supports the last column, for now
    one_entry *e = [items objectAtIndex:rowIndex];
    e->size = size;
}

- (BOOL) shouldDoSizeFixupsForTableView
{
	return YES;
}

@end
