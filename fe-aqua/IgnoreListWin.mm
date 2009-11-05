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

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/util.h"
#include "../common/ignore.h"
}

#import "SG.h"
#import "IgnoreListWin.h"

//////////////////////////////////////////////////////////////////////

@interface oneIgnore : NSObject
{
  @public
    ignore		*ign;

    NSMutableString	*mask;
    NSNumber		*ctcp;
    NSNumber		*priv;
    NSNumber		*chan;
    NSNumber		*notice;
    NSNumber		*invite;
    NSNumber		*unignore;
}

- (id) initWithIgnore:(ignore *) ign;

@end

@implementation oneIgnore

- (id) initWithIgnore:(ignore *) the_ign
{
    self->ign = the_ign;

    mask = [[NSMutableString stringWithUTF8String:ign->mask] retain];
    ctcp = [[NSNumber numberWithBool:ign->type & IG_CTCP] retain];
    priv = [[NSNumber numberWithBool:ign->type & IG_PRIV] retain];
    chan = [[NSNumber numberWithBool:ign->type & IG_CHAN] retain];
    notice = [[NSNumber numberWithBool:ign->type & IG_NOTI] retain];
    invite = [[NSNumber numberWithBool:ign->type & IG_INVI] retain];
    unignore = [[NSNumber numberWithBool:ign->type & IG_UNIG] retain];
    
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

- (void) set_bool:(bool) value
	for_field:(id *) field
	     type:(int) type
{
    [*field release];
    *field = [[NSNumber numberWithBool:value] retain];
    if (value)
    	ign->type |= type;
    else
    	ign->type &= ~type;
}

- (void) setValue:(id) value
	 forField:(int) field
{
    switch (field)
    {
        case 0:
	    [mask setString:value];
	    free (ign->mask);
	    ign->mask = strdup ([mask UTF8String]);
	    break;

        case 1:
	    [self set_bool:[value boolValue] for_field:&ctcp type:IG_CTCP];
	    break;

        case 2:
	    [self set_bool:[value boolValue] for_field:&priv type:IG_PRIV];
	    break;

        case 3:
	    [self set_bool:[value boolValue] for_field:&chan type:IG_CHAN];
	    break;

        case 4:
	    [self set_bool:[value boolValue] for_field:&notice type:IG_NOTI];
	    break;

        case 5:
	    [self set_bool:[value boolValue] for_field:&invite type:IG_INVI];
	    break;

        case 6:
	    [self set_bool:[value boolValue] for_field:&unignore type:IG_UNIG];
	    break;
    }
}

@end

//////////////////////////////////////////////////////////////////////

@implementation IgnoreListWin

- (id) initWithSelfPtr:(id *) self_ptr;
{
    [super initWithSelfPtr:self_ptr];
    
    my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"IgnoreList" owner:self];
    
    return self;
}

- (void) dealloc
{
    [ignore_list_view release];
    [my_items release];
    [super dealloc];
}

- (void) update_stats
{
    [ignored_ctcp_text setIntValue:ignored_ctcp];
    [ignored_noti_text setIntValue:ignored_noti];
    [ignored_chan_text setIntValue:ignored_chan];
    [ignored_invi_text setIntValue:ignored_invi];
    [ignored_priv_text setIntValue:ignored_priv];
}

- (void) load_data
{
    [my_items removeAllObjects];

    for (GSList *list = ignore_list; list; list = list->next)
    {
        struct ignore *ign = (struct ignore *) list->data;
	[my_items addObject:[[oneIgnore alloc] initWithIgnore:ign]];
    }

    [self->ignore_list_table reloadData];

    [self update_stats];
}

- (void) awakeFromNib
{
    [ignore_list_view setTitle:NSLocalizedStringFromTable(@"XChat: Ignore list", @"xchat", @"")];
    [ignore_list_view setTabTitle:NSLocalizedStringFromTable(@"ignore", @"xchataqua", @"")];
    
    for (int i = 0; i < [self->ignore_list_table numberOfColumns]; i ++)
        [[[self->ignore_list_table tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    NSButtonCell *b = [[NSButtonCell alloc] init];
    [b setButtonType:NSSwitchButton];
    [b setControlSize:NSSmallControlSize];
    [b setTitle:@""];
    for (int i = 1; i < [self->ignore_list_table numberOfColumns]; i ++)
		[[[self->ignore_list_table tableColumns] objectAtIndex:i] setDataCell:b];
	[b release];

    [self->ignore_list_table setDataSource:self];
    [self->ignore_list_view setDelegate:self];
    
    [self load_data];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    ignore_save ();

    [self release];
}

- (int) find:(const char *) mask
{
    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        oneIgnore *item = (oneIgnore *) [my_items objectAtIndex:i];
	if (rfc_casecmp (mask, item->ign->mask) == 0)
	    return i;
    }

    return -1;
}

- (void) do_new:(id) sender
{
    [[ignore_list_table window] makeFirstResponder:ignore_list_table];

    if ([self find:"new!new@new.com"] < 0)
	ignore_add ("new!new@new.com", 0); // Calls me back to create my list

    int row = [self find:"new!new@new.com"];

    if (row >= 0)		// It should always be 0
    {
    	[ignore_list_table selectRow:row byExtendingSelection:false];
		[ignore_list_table editColumn:0 row:row withEvent:NULL select:true];
    }
}

- (void) do_delete:(id) sender
{
    int row = [ignore_list_table selectedRow];
    if (row < 0)
    	return;

    [[ignore_list_table window] makeFirstResponder:ignore_list_table];

    oneIgnore *item = (oneIgnore *) [my_items objectAtIndex:row];

    ignore_del (NULL, item->ign);	// This will call me back

    // item is gone when we get here
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [ignore_list_view becomeTabAndShow:true];
    else
        [ignore_list_view becomeWindowAndShow:true];
}

- (void) update:(int) level
{
    if (level == 1)
        [self load_data];
    else if (level == 2)
        [self update_stats];
}

//////////////
//

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    oneIgnore *item = [my_items objectAtIndex:rowIndex];

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
               row:(int)rowIndex
{
    id item = [my_items objectAtIndex:rowIndex];
    [item setValue:anObject forField:[[aTableColumn identifier] intValue]];
}

@end
