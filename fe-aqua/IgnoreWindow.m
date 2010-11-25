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
#include "../common/util.h"
#include "../common/ignore.h"

#import "TabOrWindowView.h"
#import "IgnoreWindow.h"

@interface IgnoreItem : NSObject
{
	struct ignore *ign;

	NSString *mask;
  @public
	NSNumber *ctcp;
	NSNumber *private;
	NSNumber *channel;
	NSNumber *notice;
	NSNumber *invite;
	NSNumber *unignore;
}

@property (nonatomic, readonly) struct ignore *ign;
@property (nonatomic, retain) NSString *mask;

@end

@implementation IgnoreItem
@synthesize ign, mask;

- (id) initWithIgnore:(struct ignore *)anIgnore
{
	if ((self = [super init]) != nil) {
		self->ign = anIgnore;

		self->mask    = [[NSString alloc] initWithUTF8String:ign->mask];
		self->ctcp    = [[NSNumber alloc] initWithBool:ign->type & IG_CTCP];
		self->private = [[NSNumber alloc] initWithBool:ign->type & IG_PRIV];
		self->channel = [[NSNumber alloc] initWithBool:ign->type & IG_CHAN];
		self->notice  = [[NSNumber alloc] initWithBool:ign->type & IG_NOTI];
		self->invite  = [[NSNumber alloc] initWithBool:ign->type & IG_INVI];
		self->unignore= [[NSNumber alloc] initWithBool:ign->type & IG_UNIG];
	}	
	return self;
}

- (void) dealloc
{
	self.mask = nil;
	[ctcp release];
	[private release];
	[channel release];
	[notice release];
	[invite release];
	[unignore release];
	
	[super dealloc];
}

- (void) setBool:(BOOL)value forField:(id *)field type:(int)type
{
	[*field release];
	*field = [[NSNumber alloc] initWithBool:value];
	if (value)
		ign->type |= type;
	else
		ign->type &= ~type;
}

- (void) setValue:(id)value forField:(int)field
{
	switch (field)
	{
		case 0:
			self.mask = value;
			free (ign->mask);
			ign->mask = strdup ([mask UTF8String]);
			break;			
		case 1: [self setBool:[value boolValue] forField:&ctcp     type:IG_CTCP]; break;
		case 2: [self setBool:[value boolValue] forField:&private  type:IG_PRIV]; break;
		case 3: [self setBool:[value boolValue] forField:&channel  type:IG_CHAN]; break;
		case 4: [self setBool:[value boolValue] forField:&notice   type:IG_NOTI]; break;
		case 5: [self setBool:[value boolValue] forField:&invite   type:IG_INVI]; break;
		case 6: [self setBool:[value boolValue] forField:&unignore type:IG_UNIG]; break;
	}
}

@end

#pragma mark -

@interface IgnoreWindow (private)

- (void)updateStats;
- (void)loadData;
- (NSInteger)find:(const char *)mask; // used to find 'new' only

@end

@implementation IgnoreWindow

- (id) IgnoreWindowInit {
	ignores = [[NSMutableArray alloc] init];
	return self;
}

- (id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	return [self IgnoreWindowInit];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	return [self IgnoreWindowInit];
}

- (void) dealloc
{
	[ignores release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self setTitle:NSLocalizedStringFromTable(@"XChat: Ignore list", @"xchat", @"")];
	[self setTabTitle:NSLocalizedStringFromTable(@"ignore", @"xchataqua", @"")];
	
	NSButtonCell *button = [[NSButtonCell alloc] init];
	[button setButtonType:NSSwitchButton];
	[button setControlSize:NSSmallControlSize];
	[button setTitle:@""];
	for (NSUInteger i = 1; i < [self->ignoreTableView numberOfColumns]; i++)
		[[[self->ignoreTableView tableColumns] objectAtIndex:i] setDataCell:button];
	[button release];
	
	[self loadData];
}

- (void) windowWillClose:(NSNotification *)notification
{
	ignore_save();
	[super windowWillClose:notification];
}

- (void) update:(int)level
{
	if (level == 1)
		[self loadData];
	else if (level == 2)
		[self updateStats];
}

#pragma mark -
#pragma mark IBAction

- (void) addIgnore:(id)sender
{
	[[ignoreTableView window] makeFirstResponder:ignoreTableView];

	if ([self find:"new!new@new.com"] < 0)
		ignore_add("new!new@new.com", 0); // Calls me back to create my list
  
	NSInteger row = [self find:"new!new@new.com"];

	if (row >= 0)		// It should always be 0
	{
		[ignoreTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		[ignoreTableView editColumn:0 row:row withEvent:nil select:YES];
	}
}

- (void) removeIgnore:(id)sender
{
	NSInteger row = [ignoreTableView selectedRow];
	if (row < 0) return;

	[[ignoreTableView window] makeFirstResponder:ignoreTableView];

	IgnoreItem *item = [ignores objectAtIndex:row];

	ignore_del (NULL, item.ign);	// This will call me back

	// item is gone when we get here
}

- (void) removeAllIgnores:(id)sender {
	while ( [ignores count] > 0 ) {
		ignore_del(NULL, ((IgnoreItem *)[ignores lastObject]).ign);
	}
}

#pragma mark -
#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [ignores count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	IgnoreItem *item = [ignores objectAtIndex:rowIndex];

	switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
	{
		case 0: return [item mask];
		case 1: return item->ctcp;
		case 2: return item->private;
		case 3: return item->channel;
		case 4: return item->notice;
		case 5: return item->invite;
		case 6: return item->unignore;
	}
	SGAssert(NO);
	return @"";
}

-(void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	[[ignores objectAtIndex:rowIndex] setValue:anObject forField:[[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn]];
}

@end

#pragma mark -

@implementation IgnoreWindow (private)

- (void) updateStats
{
	[ctcpTextField    setIntegerValue:ignored_ctcp];
	[noticeTextField  setIntegerValue:ignored_noti];
	[channelTextField setIntegerValue:ignored_chan];
	[inviteTextField  setIntegerValue:ignored_invi];
	[privateTextField setIntegerValue:ignored_priv];
}

- (void) loadData
{
	[ignores removeAllObjects];
	
	for (GSList *list = ignore_list; list; list = list->next)
	{
		struct ignore *ign = (struct ignore *) list->data;
		IgnoreItem *item = [[IgnoreItem alloc] initWithIgnore:ign];
		[ignores addObject:item];
		[item release];
	}
	
	[self->ignoreTableView reloadData];
	[self updateStats];
}


- (NSInteger) find:(const char *)mask
{
	for (IgnoreItem *ignoreItem in ignores)
	{
		if (rfc_casecmp (mask, ignoreItem.ign->mask) == 0)
			return [ignores indexOfObject:ignoreItem];
	}
	return -1;
}

@end