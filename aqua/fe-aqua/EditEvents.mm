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

#include <sys/types.h>
#include <dirent.h>

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/cfgfiles.h"
#include "../common/text.h"
}

#import "AquaChat.h"
#import "EditEvents.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

extern struct text_event te[];
extern char *pntevts_text[];
extern char *pntevts[];

//////////////////////////////////////////////////////////////////////

@interface oneEvent : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*text;
    NSMutableArray	*help;
}

- (int) help_count;
- (id)  help_row:(int) row;

@end

@implementation oneEvent

- (id) initWithEvent:(struct text_event *) event
		text:(const char *) the_text
{
    name = [[NSMutableString stringWithUTF8String:event->name] retain];
    text = [[NSMutableString stringWithUTF8String:the_text] retain];
    help = [[NSMutableArray arrayWithCapacity:(event->num_args & 0x7f)] retain];

    for (int i = 0; i < (event->num_args & 0x7f); i ++)
		[help addObject:[NSMutableString stringWithUTF8String:event->help [i]]];
    
    return self;
}

- (void) dealloc
{
    [name release];
    [help release];

    [super dealloc];
}

- (int) help_count
{
    return [help count];
}

- (id)  help_row:(int) row
{
    return [help objectAtIndex:row];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditEvents

- (id) init
{
    [super init];
     
    my_items = NULL;

    [NSBundle loadNibNamed:@"EditEvents" owner:self];
	[[event_list window] setTitle:NSLocalizedStringFromTable(@"Edit Events", @"xchat", @"")];
    return self;
}

- (void) dealloc
{
    [[event_list window] release];
    [my_items release];
    [super dealloc];
}

- (void) awakeFromNib
{
    my_items = [[NSMutableArray arrayWithCapacity:NUM_XP] retain];
	
    for (int i = 0; i < [event_list numberOfColumns]; i ++)
        [[[event_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    for (int i = 0; i < [help_list numberOfColumns]; i ++)
        [[[help_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];
    
    [event_list setDataSource:self];
    [event_list setDelegate:self];

    [help_list setDataSource:self];

    [test_text setPalette:[[AquaChat sharedAquaChat] getPalette]];
    [test_text setFont:[[AquaChat sharedAquaChat] getFont]
	      boldFont:[[AquaChat sharedAquaChat] getBoldFont]];

    [[event_list window] center];
}

- (void) load_items
{
	prefs.save_pevents = true;

    [my_items removeAllObjects];

    for (int i = 0; i < NUM_XP; i ++)                      
    {
		oneEvent *item = [[[oneEvent alloc] initWithEvent:&te [i]
												     text:pntevts_text [i]] autorelease];
		[my_items addObject:item];
    }

    [event_list reloadData];
}

- (void) show
{
    [self load_items];
    [[event_list window] makeKeyAndOrderFront:self];
}

- (void) do_ok:(id) sender
{
    pevent_save (NULL);
    [[sender window] orderOut:sender];
}

- (void) test_one:(int) row
{
    const char *text = pntevts_text[row];
    char *out = strdup (text);
    check_special_chars (out, TRUE);
    // Events have $t which need to be converted to tabs.. stupid design :)
    char *x = out;
    char *y = out;
    while (*x)
    {
        if (x[0] == '$' && x[1] == 't')
        {
            *y = '\t';
            x ++;
        }
        else
            *y = *x;
        x ++;
        y ++;
    }
    *y = 0;
    [test_text print_text:out];
    free (out);
}

- (void) do_test_all:(id) sender
{
    [test_text setString:@""];
    for (int i = 0; i < NUM_XP; i ++)                      
        [self test_one:i];
}

- (void) do_load:(id) sender
{
    NSString *fname = [SGFileSelection selectWithWindow:[sender window]];
    if (fname)
    {
        pevent_load ((char *) [fname UTF8String]);
        pevent_make_pntevts ();
        [self load_items];
        [event_list reloadData];
        [help_list reloadData];
    }
}

- (void) do_save_as:(id) sender
{
    NSString *fname = [SGFileSelection saveWithWindow:[sender window]];
    if (fname)
        pevent_save ((char *) [fname UTF8String]);
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self do_ok:self];
}

////////////
// Delegate

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    [help_list reloadData];
    [test_text setString:@""];
    int row = [event_list selectedRow];
    if (row >= 0)
        [self test_one:row];
}

////////////
// Data Source

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    if (aTableView == event_list)
	return [my_items count];

    if (aTableView == help_list)
    {
        int row = [event_list selectedRow];
		return row < 0 ? 0 : [[my_items objectAtIndex:row] help_count];
    }

    return 0;
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    if (aTableView == event_list)
    {
		oneEvent *item = [my_items objectAtIndex:rowIndex];
		
		switch ([[aTableColumn identifier] intValue])
		{
			case 0: return item->name;
			case 1: return item->text;
		}
    }

    if (aTableView == help_list)
    {
		switch ([[aTableColumn identifier] intValue])
		{
			case 0:
				return [NSNumber numberWithInt:rowIndex + 1];

			case 1:
			{
				int row = [event_list selectedRow];
				return row < 0 ? @"" :
					[[my_items objectAtIndex:row] help_row:rowIndex];
			}
		}
    }

    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(int)rowIndex
{
    if (aTableView == event_list)
    {
		prefs.save_pevents = true;
		
		oneEvent *item = [my_items objectAtIndex:rowIndex];

		switch ([[aTableColumn identifier] intValue])
		{
			case 1:
			{
				const char *text = [anObject UTF8String];

				char *out;
				int m;
				if (pevt_build_string (text, &out, &m) != 0)
				{
					[SGAlert alertWithString:NSLocalizedStringFromTable(@"There was an error parsing the string", @"xchat", @"") andWait:false];
					return;
				}

				if (m > te [rowIndex].num_args)
				{
					free (out);
					[SGAlert alertWithString:[NSString stringWithFormat:NSLocalizedStringFromTable(@"This signal is only passed %d args, $%d is invalid", @"xchat", @""), te [rowIndex].num_args, m] andWait:false];
					return;
				}

				[item->text setString:anObject];
			
				if (pntevts_text [rowIndex])
					free (pntevts_text [rowIndex]);
				if (pntevts [rowIndex])
					free (pntevts [rowIndex]);

				int len = strlen (text);
				pntevts_text [rowIndex] = (char *) malloc (len + 1);
				memcpy (pntevts_text [rowIndex], text, len + 1);
				pntevts [rowIndex] = out;

				break;
			}
		}
    }
}

@end
