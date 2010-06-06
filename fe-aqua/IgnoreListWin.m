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
#include "../common/network.h"
#include "../common/util.h"
#include "../common/ignore.h"

#import "SG.h"
#import "IgnoreListWin.h"

//////////////////////////////////////////////////////////////////////

@interface OneIgnore : NSObject
{
  @public
    struct ignore		*ign;

    NSMutableString	*mask;
    NSNumber		*ctcp;
    NSNumber		*priv;
    NSNumber		*chan;
    NSNumber		*notice;
    NSNumber		*invite;
    NSNumber		*unignore;
}

- (id) initWithIgnore:(struct ignore *)ign;

@end

@implementation OneIgnore

- (id) initWithIgnore:(struct ignore *)aIgn
{
    self->ign = aIgn;

    mask	= [[NSMutableString stringWithUTF8String:ign->mask] retain];
    ctcp	= [[NSNumber numberWithBool:ign->type & IG_CTCP] retain];
    priv	= [[NSNumber numberWithBool:ign->type & IG_PRIV] retain];
    chan	= [[NSNumber numberWithBool:ign->type & IG_CHAN] retain];
    notice	= [[NSNumber numberWithBool:ign->type & IG_NOTI] retain];
    invite	= [[NSNumber numberWithBool:ign->type & IG_INVI] retain];
    unignore= [[NSNumber numberWithBool:ign->type & IG_UNIG] retain];
    
    return self;
}

- (void) dealloc
{
    [mask release];
    [ctcp release];
    [priv release];
    [chan release];
    [notice release];
    [invite release];
    [unignore release];

    [super dealloc];
}

- (void) setBool:(BOOL)value forField:(id *)field type:(int)type
{
    [*field release];
    *field = [[NSNumber numberWithBool:value] retain];
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
			[mask setString:value];
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
    
    myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"IgnoreList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [ignoreListView release];
    [myItems release];
    [super dealloc];
}

- (void) updateStats
{
    [ignoredCtcpTextField setIntValue:ignored_ctcp];
    [ignoredNoticeTextField setIntValue:ignored_noti];
    [ignoredChannelTextField setIntValue:ignored_chan];
    [ignoredInviteTextField setIntValue:ignored_invi];
    [ignoredPrivateTextField setIntValue:ignored_priv];
}

- (void) loadData
{
	[myItems removeAllObjects];
	
	for (GSList *list = ignore_list; list; list = list->next)
	{
		struct ignore *ign = (struct ignore *) list->data;
		[myItems addObject:[[OneIgnore alloc] initWithIgnore:ign]];
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
	for (OneIgnore *ignoreItem in myItems)
	{
		if (rfc_casecmp (mask, ignoreItem->ign->mask) == 0)
			return [myItems indexOfObject:ignoreItem];
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

    OneIgnore *item = [myItems objectAtIndex:row];

    ignore_del (NULL, item->ign);	// This will call me back

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
    return [myItems count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    OneIgnore *item = [myItems objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->mask;
        case 1: return item->ctcp;
        case 2: return item->priv;
        case 3: return item->chan;
        case 4: return item->notice;
        case 5: return item->invite;
        case 6: return item->unignore;
    }
    
    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn
               row:(NSInteger)rowIndex
{
    [[myItems objectAtIndex:rowIndex] setValue:anObject forField:[[aTableColumn identifier] intValue]];
}

@end
