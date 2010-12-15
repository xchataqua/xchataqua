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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"

#import "AquaChat.h"
#import "ColorPalette.h"
#import "mIRCString.h"
#import "ChannelWindow.h"

//////////////////////////////////////////////////////////////////////

SEL *sortSelectors;
const char* sortSelectorNames[] = {
	"sortByChannelDescending:",
	"sortByChannelAscending:",
	"sortByNumberOfUsersDescending:",
	"sortByNumberOfUsersAscending:",
	"sortByTopicDescending:",
	"sortByTopicAscending:",
};

//////////////////////////////////////////////////////////////////////

@interface ChannelEntry : NSObject
{
  @public
	NSString *channel;
	NSString *numberOfUsersString;
	mIRCString *topic;
	NSInteger numberOfUsers;	// For sorting.. is it really helping?
	NSSize size;
}

@property (nonatomic, readonly) NSString *channel, *numberOfUsersString;
@property (nonatomic, readonly) mIRCString *topic;
@property (nonatomic, readonly) NSInteger numberOfUsers;

+ (id) entryWithChannel:(NSString *)channel numberOfUsers:(NSString *)numberOfUsersString topic:(NSString *)topic colorPalette:(ColorPalette *)palette;

- (NSComparisonResult)sortByChannelAscending:(ChannelEntry *)other;
- (NSComparisonResult)sortByChannelDescending:(ChannelEntry *)other;
- (NSComparisonResult)sortByNumberOfUsersAscending:(ChannelEntry *)other;
- (NSComparisonResult)sortByNumberOfUsersDescending:(ChannelEntry *)other;
- (NSComparisonResult)sortByTopicAscending:(ChannelEntry *)other;
- (NSComparisonResult)sortByTopicDescending:(ChannelEntry *)other;

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

@implementation ChannelEntry
@synthesize channel, numberOfUsersString, topic, numberOfUsers;

+ (id) entryWithChannel:(NSString *)channel numberOfUsers:(NSString *)numberOfUsersString topic:(NSString *)aTopic colorPalette:(ColorPalette *)palette
{
	ChannelEntry *entry =  [[ChannelEntry alloc] init];
	if (entry != nil) {
		entry->channel = [channel retain];
		entry->numberOfUsersString = [numberOfUsersString retain];
		entry->size = NSZeroSize;
	
		entry->topic = [[mIRCString stringWithUTF8String:strip_crap([aTopic UTF8String]) length:-1 palette:palette font:nil boldFont:nil] retain];
			
		entry->numberOfUsers = [entry->numberOfUsersString integerValue];
	}
	return [entry autorelease];
}

- (void) dealloc
{
	[channel release];
	[numberOfUsersString release];
	[topic release];

	[super dealloc];
}

#pragma mark sort selectors

- (NSComparisonResult) sortByChannelAscending:(ChannelEntry *)other
{
	return [self->channel compare:other->channel];
}

- (NSComparisonResult) sortByChannelDescending:(ChannelEntry *)other
{
	return [other->channel compare:self->channel];
}

- (NSComparisonResult) sortByNumberOfUsersAscending:(ChannelEntry *)other
{
	if (self->numberOfUsers < other->numberOfUsers) return NSOrderedAscending;
	if (self->numberOfUsers > other->numberOfUsers) return NSOrderedDescending;
	return NSOrderedSame;
}

- (NSComparisonResult) sortByNumberOfUsersDescending:(ChannelEntry *)other
{
	if (other->numberOfUsers < self->numberOfUsers) return NSOrderedAscending;
	if (other->numberOfUsers > self->numberOfUsers) return NSOrderedDescending;
	return NSOrderedSame;
}

- (NSComparisonResult) sortByTopicAscending:(ChannelEntry *)other
{
	return [[self->topic string] compare:[other->topic string]];
}

- (NSComparisonResult) sortByTopicDescending:(ChannelEntry *)other;
{
	return [[other->topic string] compare:[self->topic string]];
}

@end

#pragma mark -

@interface ChannelWindow (private)

- (void)makeRegex;
- (void)freeRegex;
- (void)updateCaption;
- (void)resetCounters;
- (BOOL)filter:(ChannelEntry *)entry;
- (void)redraw:(id)sender;
- (void)sortFilteredChannels;

@end


@implementation ChannelWindow

+ (void) initialize {
	NSInteger numberOfSortSelectors = sizeof(sortSelectorNames)/sizeof(char *);
	sortSelectors = (SEL *)malloc(numberOfSortSelectors*sizeof(SEL));
	for ( NSInteger i = 0; i < numberOfSortSelectors; i++ ) {
		sortSelectors[i] = sel_registerName(sortSelectorNames[i]);
	}
}

- (id) ChannelWindowInit {
	[self setServer:current_sess->server];
	self->filteredChannels = [[NSMutableArray alloc] init];
	self->allChannels = [[NSMutableArray alloc] init];
	self->colorPalette = [[[AquaChat sharedAquaChat] palette] clone];
	
	[self->colorPalette setColor:AC_FGCOLOR color:[NSColor blackColor]];
	[self->colorPalette setColor:AC_BGCOLOR color:[NSColor whiteColor]];
	
	return self;	
}

- (id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	return [self ChannelWindowInit];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	return [self ChannelWindowInit];
}

- (void) dealloc
{
	[redrawTimer invalidate];
	[self freeRegex];
	[arrowImage release];
	[colorPalette release];
	[filteredChannels release];
	[allChannels release];
	
	[super dealloc];
}

- (void) awakeFromNib
{	
	arrowImage = [[NSImage imageNamed:@"down.tiff"] retain];
	
	[self setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Channel List (%s)", @"xchat", @""), self->server->servername]];
	[self setTabTitle:NSLocalizedStringFromTable(@"chanlist", @"xchataqua", @"")];

	[self resetCounters];
	
	[channelTableView setTarget:self];
	[channelTableView setDoubleAction:@selector(joinChannel:)];
}

#pragma mark fe-aqua

- (void) addChannelWithName:(NSString *)channel numberOfUsers:(NSString *)users topic:(NSString *)topic
{
	ChannelEntry *newItem = [ChannelEntry entryWithChannel:channel numberOfUsers:users topic:topic colorPalette:colorPalette];
	
	[allChannels addObject:newItem];
	
	added |= [self filter:newItem];
	
	if ( redrawTimer == nil ) {
		redrawTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
													   target:self
													 selector:@selector(redraw:)
													 userInfo:nil
													  repeats:NO];
	}
}

- (void) refreshFinished
{
	[refreshButton setEnabled:YES];
}

#pragma mark IBAction

- (void) applySearch:(id)sender
{
	[filteredChannels removeAllObjects];

	[self resetCounters];
	[self makeRegex];

	filterMin = [minTextField integerValue];
	filterMax = [maxTextField integerValue];

	topicChecked = [regexTopicButton integerValue];
	channelChecked = [regexChannelButton integerValue];

	for (NSUInteger i = 0; i < [allChannels count]; i ++)
		[self filter:[allChannels objectAtIndex:i]];

	[self updateCaption];
	[self sortFilteredChannels];
	[channelTableView reloadData];
}

- (void) refreshList:(id)sender
{
	if (self->server->connected)
	{
		[allChannels removeAllObjects];
		[self applySearch:sender];
		
		[refreshButton setEnabled:NO];
		
		handle_command(self->server->server_session, "list", false);
	}
	else
		[SGAlert alertWithString:NSLocalizedStringFromTable(@"Not connected.", @"xchat", @"") andWait:NO];
}

- (void) saveAs:(id)sender
{
}

- (void) joinChannel:(id)sender
{
	NSInteger row = [channelTableView selectedRow];
	
	if (row < 0) return;
	
	ChannelEntry *entry = [filteredChannels objectAtIndex:row];

	if (self->server->connected && ![[entry channel] isEqualToString:@"*"])
	{
		char tbuf [512];
		snprintf (tbuf, sizeof (tbuf), "join %s", [[entry channel] UTF8String]);
		handle_command(self->server->server_session, tbuf, false);
	}
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [filteredChannels count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	ChannelEntry *entry = [filteredChannels objectAtIndex:rowIndex];
	
	switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
	{
		case 0: return [entry channel];
		case 1: return [entry numberOfUsersString];
		case 2: return [entry topic];
	}
	SGAssert(NO);
	return @"";
}

- (BOOL) tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return NO;
}

#pragma mark NSTableView delegate

- (BOOL) tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn
{
	BOOL flip = [aTableView highlightedTableColumn] == aTableColumn;
	
	NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
	
	if (flip)
	{
		sortDirection [column] = !sortDirection [column];
	}
	else
	{
		[aTableView setIndicatorImage:arrowImage inTableColumn:aTableColumn];
		[aTableView setIndicatorImage:nil inTableColumn:[aTableView highlightedTableColumn]];
		[aTableView setHighlightedTableColumn:aTableColumn];
	}

	[arrowImage setFlipped:sortDirection [column]];
	
	[filteredChannels sortUsingSelector:sortSelectors [(column << 1) + sortDirection [column]]];
	[channelTableView reloadData];
	
	return NO;
}

- (NSSize) tableView:(NSTableView *)aTableView sizeHintForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	// This only supports the last column, for now
	ChannelEntry *entry = [filteredChannels objectAtIndex:rowIndex];
	return entry->size;
}

- (void) tableView:(NSTableView *)aTableView sizeHintForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex size:(NSSize)size
{
	// This only supports the last column, for now
	ChannelEntry *entry = [filteredChannels objectAtIndex:rowIndex];
	entry->size = size;
}

- (BOOL) shouldDoSizeFixupsForTableView
{
	return YES;
}

@end

#pragma mark -

@implementation ChannelWindow (private)

- (void) makeRegex
{
	[self freeRegex];
	
	NSString *text = [regexTextField stringValue];
	
	if ([text length] > 0)
	{
		regexValid = 0 == regcomp (&matchRegex, [text UTF8String], REG_ICASE | REG_EXTENDED | REG_NOSUB);
	}
}

- (void) freeRegex
{
	if (regexValid)
	{
		regfree (&matchRegex);
		regexValid = NO;
	}
}

- (void) updateCaption
{
	NSString *caption = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Displaying %d/%d users on %d/%d filteredChannels.", @"xchat", @""),
						 numberOfShownUsers, numberOfFoundUsers, [filteredChannels count], [allChannels count]];
	[captionTextField setStringValue:caption];
}

- (void) resetCounters
{
	numberOfFoundUsers = 0;
	numberOfShownUsers = 0;
	
	[self updateCaption];
}

- (BOOL) filter:(ChannelEntry *)entry
{
	NSInteger numberOfUsers = [entry numberOfUsers];
	
	numberOfFoundUsers += numberOfUsers;
	
	if (filterMin && numberOfUsers < filterMin)
		return NO;
	
	if (filterMax && numberOfUsers > filterMax)
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
		else if (topicChecked && !channelChecked && regexec (&matchRegex, topic, 0, 0, REG_NOTBOL) != 0)
		{
			return NO;
		}
		else if (!topicChecked && channelChecked && regexec (&matchRegex, chan, 0, 0, REG_NOTBOL) != 0)
		{
			return NO;
		}
	}
	
	numberOfShownUsers += numberOfUsers;
	
	[filteredChannels addObject:entry];
	
	return YES;
}

- (void) redraw:(id)sender
{
	redrawTimer = nil;
	
	[self updateCaption];
	
	if (added)
	{
		[self sortFilteredChannels];
		[channelTableView reloadData];
		added = NO;
	}
}

- (void) sortFilteredChannels
{
	NSTableColumn *tableColumn = [channelTableView highlightedTableColumn];
	if ( tableColumn != nil )
	{
		NSInteger column = [[channelTableView tableColumns] indexOfObjectIdenticalTo:tableColumn];
		[filteredChannels sortUsingSelector:sortSelectors [(column << 1) + sortDirection[column]]];
	}
}

@end

