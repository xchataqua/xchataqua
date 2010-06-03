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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"

//////////////////////////////////////////////////////////////////////

SEL *sort_funcs; // defined in +initialize

//////////////////////////////////////////////////////////////////////

@interface OneEntry : NSObject
{
  @public
    NSString	*channel;
    NSString	*numberOfUsersString;
    mIRCString	*topic;
    NSInteger	numberOfUsers;		// For sorting.. is it really helping?
    NSSize      size;
}

@property (nonatomic, readonly) NSString *channel, *numberOfUsersString;
@property (nonatomic, readonly) mIRCString *topic;
@property (nonatomic, readonly) NSInteger numberOfUsers;

+ (id) entryWithChannel:(NSString *)channel numberOfUsers:(NSString *)user topic:(NSString *)topic colorPalette:(ColorPalette *)palette;

- (NSComparisonResult) sortByChannel:(OneEntry *)other;
- (NSComparisonResult) sortByNumberOfUsers:(OneEntry *)other;
- (NSComparisonResult) sortByTopic:(OneEntry *)other;
- (NSComparisonResult) sortByChannelReverse:(OneEntry *)other;
- (NSComparisonResult) sortByNumberOfUsersReverse:(OneEntry *)other;
- (NSComparisonResult) sortByTopicReverse:(OneEntry *)other;

@end

// For some reason, the Mac does not like UTF8 0xc2 '< 0xa0'
// We'll also strip tabs.. anything else?
static const char * strip_crap (const char *s)
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


@implementation OneEntry
@synthesize channel, numberOfUsersString, topic, numberOfUsers;

+ (id) entryWithChannel:(NSString *)channel numberOfUsers:(NSString *)user topic:(NSString *)aTopic colorPalette:(ColorPalette *)palette
{
	OneEntry *entry = [[[OneEntry alloc] init] autorelease];
    entry->channel = [channel retain];
    entry->numberOfUsersString = [user retain];
    entry->size = NSZeroSize;
    
    entry->topic = [[mIRCString stringWithUTF8String:strip_crap([aTopic UTF8String]) len:-1 palette:palette font:nil boldFont:nil] retain];
    		
    entry->numberOfUsers = [entry->numberOfUsersString integerValue];
    
    return entry;
}

- (void) dealloc
{
    [channel release];
    [numberOfUsersString release];
    [topic release];

    [super dealloc];
}

- (NSComparisonResult) sortByChannel:(OneEntry *)other
{
    return [channel compare:other->channel];
}

- (NSComparisonResult) sortByNumberOfUsers:(OneEntry *)other
{
    if (numberOfUsers < other->numberOfUsers) return NSOrderedAscending;
    if (numberOfUsers > other->numberOfUsers) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSComparisonResult) sortByTopic:(OneEntry *)other
{
    return [[topic string] compare:[other->topic string]];
}

- (NSComparisonResult) sortByChannelReverse:(OneEntry *)other
{
    return [other->channel compare:channel];
}

- (NSComparisonResult) sortByNumberOfUsersReverse:(OneEntry *)other
{
    if (other->numberOfUsers < numberOfUsers) return NSOrderedAscending;
    if (other->numberOfUsers > numberOfUsers) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSComparisonResult) sortByTopicReverse:(OneEntry *)other;
{
    return [[other->topic string] compare:[topic string]];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation ChannelListWin

- (id) initWithServer:(struct server *)aServer
{
    [super init];

    self->arrow = nil;
    self->serv = aServer;
    self->timer = nil;
    self->added = NO;
    self->items = [[NSMutableArray arrayWithCapacity:0] retain];
    self->allItems = [[NSMutableArray arrayWithCapacity:0] retain];
    self->colorPalette = [[[AquaChat sharedAquaChat] palette] clone];
    
    [self->colorPalette setColor:AC_FGCOLOR color:[NSColor blackColor]];
    [self->colorPalette setColor:AC_BGCOLOR color:[NSColor whiteColor]];

    sortDir[0] = NO;
    sortDir[1] = NO;
    sortDir[2] = NO;

    [NSBundle loadNibNamed:@"ChanList" owner:self];

    return self;
}

- (void) no_regex
{
    if (regexValid)
    {
        regfree (&matchRegex);
        regexValid = NO;
    }
}

- (void) dealloc
{
    [itemTableView setDelegate:nil];
    [channelListView setDelegate:nil];
    [channelListView close];
    [channelListView autorelease];
    [arrow release];
    [self no_regex];
    [items release];
    [colorPalette release];
    [allItems release];
    
    if (timer)
    {
        [timer invalidate];
        [timer release];
    }
    
    [super dealloc];
}

- (void) updateCaption
{
    [captionTextField setStringValue:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Displaying %d/%d users on %d/%d channels.", @"xchat", @""),
        numberOfShownUsers, numberOfFoundUsers, [items count], [allItems count]]];
}

- (void) resetCounters
{
    numberOfFoundUsers = 0;
    numberOfShownUsers = 0;
    
    [self updateCaption];
}

- (void) awakeFromNib
{
    [channelListView setServer:serv];
    
    arrow = [[NSImage imageNamed:@"down.tiff"] retain];
    
    [channelListView setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Channel List (%s)", @"xchat", @""), self->serv->servername]];
    [channelListView setTabTitle:NSLocalizedStringFromTable(@"chanlist", @"xchataqua", @"")];
    
    for (NSInteger i = 0; i < [itemTableView numberOfColumns]; i++ )
        [[[itemTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self resetCounters];
    
    [itemTableView setDataSource:self];
    [itemTableView setTarget:self];
    [itemTableView setDoubleAction:@selector(onJoin:)];
    [itemTableView setDelegate:self];

    [channelListView setDelegate:self];
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [channelListView becomeTabAndShow:YES];
    else
        [channelListView becomeWindowAndShow:YES];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    serv->gui->clc = nil;
    [self release];
}

- (void) getRegex
{
    [self no_regex];
    
    NSString *s = [regexTextField stringValue];
    
    if ([s length] > 0)
    {
        int sts = regcomp (&matchRegex, [s UTF8String], REG_ICASE | REG_EXTENDED | REG_NOSUB);
        regexValid = sts == 0;
    }
}

- (BOOL) filter:(OneEntry *) entry
{
    NSInteger num = [entry numberOfUsers];
    
    numberOfFoundUsers += num;
    
    if (filterMin && num < filterMin)
        return NO;

    if (filterMax && num > filterMax)
        return NO;
    
    if (regexValid)
    {        
		const char *topic = [[[entry topic] string] UTF8String];
		if (!topic) topic = "";
		const char *chan = [[entry channel] UTF8String];
		if (!chan) chan = "";
		
        if (topicChecked && channelChecked && 
            regexec (&matchRegex, topic, 0, 0, REG_NOTBOL) != 0 &&
            regexec (&matchRegex, chan, 0, 0, REG_NOTBOL) != 0)
        {
            return NO;
        }
        else if (topicChecked && !channelChecked &&
            regexec (&matchRegex, topic, 0, 0, REG_NOTBOL) != 0)
        {
            return NO;
        }
        else if (!topicChecked && channelChecked && 
            regexec (&matchRegex, chan, 0, 0, REG_NOTBOL) != 0)
        {
            return NO;
        }
    }
    
    numberOfShownUsers += num;
    
    [items addObject:entry];
    
    return YES;
}

- (void) sort
{
    NSTableColumn *col = [itemTableView highlightedTableColumn];
    if ( col != nil )
    {
        NSInteger colnum = [[col identifier] integerValue];
        [items sortUsingSelector:sort_funcs [(colnum << 1) + sortDir[colnum]]];
    }
}

- (void) doApply:(id) sender
{
    [items removeAllObjects];

    [self resetCounters];
    [self getRegex];

    filterMin = [minTextField integerValue];
    filterMax = [maxTextField integerValue];

    topicChecked = [regexTopicButton integerValue];
    channelChecked = [regexChannelButton integerValue];

    for (NSUInteger i = 0; i < [allItems count]; i ++)
        [self filter:[allItems objectAtIndex:i]];

    [self updateCaption];
    [self sort];
    [itemTableView reloadData];
}

- (void) doRefresh:(id) sender
{
    if (serv->connected)
    {
        [allItems removeAllObjects];
        [self doApply:sender];
        
        [refreshButton setEnabled:NO];
        
        handle_command(serv->server_session, "list", false);
    }
    else
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"Not connected.", @"xchat", @"") andWait:NO];
}

- (void) chanListEnd
{
    [refreshButton setEnabled:YES];
}

- (void) redraw:(id) sender
{
    [timer release];
    timer = nil;
    
    [self updateCaption];
    
    if (added)
    {
        [self sort];
        [itemTableView reloadData];
        added = NO;
    }
}

- (void) doSave:(id) sender
{
}

- (void) doJoin:(id) sender
{
    NSInteger row = [itemTableView selectedRow];
    
    if (row < 0) return;
    
    OneEntry *entry = [items objectAtIndex:row];

    if (serv->connected && ![[entry channel] isEqualToString:@"*"])
    {
        char tbuf [512];
        snprintf (tbuf, sizeof (tbuf), "join %s", [[entry channel] UTF8String]);
        handle_command(serv->server_session, tbuf, false);
    }
}

- (void) addChannelList:(NSString *)channel numberOfUsers:(NSString *)users topic:(NSString *)topic
{
    OneEntry *newItem = [OneEntry entryWithChannel:channel numberOfUsers:users topic:topic colorPalette:colorPalette];
    
    [allItems addObject:newItem];
        
    added |= [self filter:newItem];
    
    if (!timer)
        timer = [[NSTimer scheduledTimerWithTimeInterval:1.0
												  target:self
												selector:@selector(redraw:)
												userInfo:nil
												 repeats:NO
											  retainArgs:NO] retain];
}

// Table View Data Source Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [items count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    OneEntry *entry = [items objectAtIndex:rowIndex];
    
    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return [entry channel];
        case 1: return [entry numberOfUsersString];
        case 2: return [entry topic];
    }
    
    return @"";
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}

// Table delegate functions

- (BOOL) tableView:(NSTableView *) aTableView shouldSelectTableColumn:(NSTableColumn *) aTableColumn
{
    BOOL flip = [aTableView highlightedTableColumn] == aTableColumn;
    
    NSInteger col = [[aTableColumn identifier] integerValue];
    
    if (flip)
    {
        sortDir [col] = !sortDir [col];
    }
    else
    {
        [aTableView setIndicatorImage:arrow inTableColumn:aTableColumn];
        [aTableView setIndicatorImage:nil inTableColumn:[aTableView highlightedTableColumn]];
        [aTableView setHighlightedTableColumn:aTableColumn];
    }

    [arrow setFlipped:sortDir [col]];
    
    [items sortUsingSelector:sort_funcs [(col << 1) + sortDir [col]]];

    [itemTableView reloadData];
    
    return NO;
}

- (NSSize) tableView:(NSTableView *) aTableView
    sizeHintForTableColumn:(NSTableColumn *) aTableColumn
        row:(NSInteger) rowIndex
{
    // This only supports the last column, for now
	OneEntry *entry = [items objectAtIndex:rowIndex];
    return entry->size;
}

- (void) tableView:(NSTableView *) aTableView
    sizeHintForTableColumn:(NSTableColumn *) aTableColumn
        row:(NSInteger) rowIndex
        size:(NSSize) size
{
    // This only supports the last column, for now
	OneEntry *entry = [items objectAtIndex:rowIndex];
    entry->size = size;
}

- (BOOL) shouldDoSizeFixupsForTableView
{
	return YES;
}

+ (void) initialize {
	sort_funcs = (SEL*)malloc(7*sizeof(SEL));
	sort_funcs = (SEL[]) {
		@selector (sortByChannelReverse:),
		@selector (sortByChannel:),
		@selector (sortByNumberOfUsersReverse:),
		@selector (sortByNumberOfUsers:),
		@selector (sortByTopicReverse:),
		@selector (sortByTopic:),
		NULL
	};
}

@end
