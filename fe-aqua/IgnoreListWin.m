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

#import "IgnoreListWin.h"
#import "TabOrWindowView.h"

//////////////////////////////////////////////////////////////////////

@interface IgnoreListItem : NSObject
{
	struct ignore	*ign;

	NSString	*mask;
	NSNumber	*ctcp;
	NSNumber	*priv;
	NSNumber	*chan;
	NSNumber	*notice;
	NSNumber	*invite;
	NSNumber	*unignore;
}

@property (nonatomic, readonly) struct ignore *ign;
@property (nonatomic, retain) NSString *mask;
@property (nonatomic, retain) NSNumber *ctcp, *priv, *chan, *notice, *invite, *unignore;

@end

@implementation IgnoreListItem
@synthesize ign, mask, ctcp, priv, chan, notice, invite, unignore;

- (id) initWithIgnore:(struct ignore *)aIgnore
{
	self->ign = aIgnore;

	self.mask	= [NSString stringWithUTF8String:ign->mask];
	self.ctcp	= [NSNumber numberWithBool:ign->type & IG_CTCP];
	self.priv	= [NSNumber numberWithBool:ign->type & IG_PRIV];
	self.chan	= [NSNumber numberWithBool:ign->type & IG_CHAN];
	self.notice	= [NSNumber numberWithBool:ign->type & IG_NOTI];
	self.invite	= [NSNumber numberWithBool:ign->type & IG_INVI];
	self.unignore= [NSNumber numberWithBool:ign->type & IG_UNIG];
	
	return self;
}

- (void) dealloc
{
	self.mask = nil;	
	self.ctcp = nil;
	self.priv = nil;
	self.chan = nil;
	self.notice = nil;
	self.invite = nil;
	self.unignore = nil;
	
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
		case 1: [self setBool:[value boolValue] forField:&ctcp type:IG_CTCP]; break;
		case 2: [self setBool:[value boolValue] forField:&priv type:IG_PRIV]; break;
		case 3: [self setBool:[value boolValue] forField:&chan type:IG_CHAN]; break;
		case 4: [self setBool:[value boolValue] forField:&notice type:IG_NOTI];break;
		case 5: [self setBool:[value boolValue] forField:&invite type:IG_INVI];break;
		case 6: [self setBool:[value boolValue] forField:&unignore type:IG_UNIG];break;
	}
}

@end

//////////////////////////////////////////////////////////////////////

@implementation IgnoreListWin

- (id) initWithSelfPtr:(id *)self_ptr;
{
	[super initWithSelfPtr:self_ptr];
	
	ignoreItems = [[NSMutableArray arrayWithCapacity:0] retain];
	
	[NSBundle loadNibNamed:@"IgnoreList" owner:self];
	
	return self;
}

- (void) dealloc
{
	[ignoreListView release];
	[ignoreItems release];
	[super dealloc];
}

- (void) updateStats
{
	[ignoredCtcpTextField setIntegerValue:ignored_ctcp];
	[ignoredNoticeTextField setIntegerValue:ignored_noti];
	[ignoredChannelTextField setIntegerValue:ignored_chan];
	[ignoredInviteTextField setIntegerValue:ignored_invi];
	[ignoredPrivateTextField setIntegerValue:ignored_priv];
}

- (void) loadData
{
	[ignoreItems removeAllObjects];
	
	for (GSList *list = ignore_list; list; list = list->next)
	{
		struct ignore *ign = (struct ignore *) list->data;
		[ignoreItems addObject:[[IgnoreListItem alloc] initWithIgnore:ign]];
	}
	
	[self->ignoreListTableView reloadData];
	[self updateStats];
}

- (void) awakeFromNib
{
	[ignoreListView setTitle:NSLocalizedStringFromTable(@"XChat: Ignore list", @"xchat", @"")];
	[ignoreListView setTabTitle:NSLocalizedStringFromTable(@"ignore", @"xchataqua", @"")];
	
	for (NSUInteger i = 0; i < [self->ignoreListTableView numberOfColumns]; i++)
		[[[self->ignoreListTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];
	
	NSButtonCell *button = [[NSButtonCell alloc] init];
	[button setButtonType:NSSwitchButton];
	[button setControlSize:NSSmallControlSize];
	[button setTitle:@""];
	for (NSUInteger i = 1; i < [self->ignoreListTableView numberOfColumns]; i++)
		[[[self->ignoreListTableView tableColumns] objectAtIndex:i] setDataCell:button];
	[button release];
	
	[self->ignoreListTableView setDataSource:self];
	[self->ignoreListView setDelegate:self];
	
	[self loadData];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
	ignore_save();

	[self release];
}

- (NSInteger)find:(const char *)mask
{
	for (IgnoreListItem *ignoreItem in ignoreItems)
	{
		if (rfc_casecmp (mask, ignoreItem.ign->mask) == 0)
			return [ignoreItems indexOfObject:ignoreItem];
	}
	return -1;
}

- (void) doNew:(id) sender
{
	[[ignoreListTableView window] makeFirstResponder:ignoreListTableView];

	if ([self find:"new!new@new.com"] < 0)
		ignore_add ("new!new@new.com", 0); // Calls me back to create my list
  
	NSInteger row = [self find:"new!new@new.com"];

	if (row >= 0)		// It should always be 0
	{
		[ignoreListTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		[ignoreListTableView editColumn:0 row:row withEvent:nil select:YES];
	}
}

- (void) doDelete:(id) sender
{
	NSInteger row = [ignoreListTableView selectedRow];
	if (row < 0) return;

	[[ignoreListTableView window] makeFirstResponder:ignoreListTableView];

	IgnoreListItem *item = [ignoreItems objectAtIndex:row];

	ignore_del (NULL, item.ign);	// This will call me back

	// item is gone when we get here
}

- (void) show
{
	if (prefs.windows_as_tabs)
		[ignoreListView becomeTabAndShow:YES];
	else
		[ignoreListView becomeWindowAndShow:YES];
}

- (void) update:(int)level
{
	if (level == 1)
		[self loadData];
	else if (level == 2)
		[self updateStats];
}

//////////////
//

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [ignoreItems count];
}

- (id) tableView:(NSTableView *) aTableView
	objectValueForTableColumn:(NSTableColumn *) aTableColumn
	row:(NSInteger) rowIndex
{
	IgnoreListItem *item = [ignoreItems objectAtIndex:rowIndex];

	switch ([[aTableColumn identifier] integerValue])
	{
		case 0: return item.mask;
		case 1: return item.ctcp;
		case 2: return item.priv;
		case 3: return item.chan;
		case 4: return item.notice;
		case 5: return item.invite;
		case 6: return item.unignore;
	}
	
	return @"";
}

- (void) tableView:(NSTableView *) aTableView
	setObjectValue:(id) anObject
	forTableColumn:(NSTableColumn *) aTableColumn
			   row:(NSInteger)rowIndex
{
	[[ignoreItems objectAtIndex:rowIndex] setValue:anObject forField:[[aTableColumn identifier] integerValue]];
}

@end
