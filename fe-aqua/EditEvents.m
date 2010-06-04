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

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/cfgfiles.h"
#include "../common/text.h"

#import "AquaChat.h"
#import "EditEvents.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

extern struct text_event te[];
extern char *pntevts_text[];
extern char *pntevts[];

//////////////////////////////////////////////////////////////////////

@interface OneEvent : NSObject
{
  @public
    NSMutableString	*name;
    NSMutableString	*text;
    NSMutableArray	*help;
}

- (NSUInteger) helpCount;
- (id) helpRow:(NSInteger)row;

@end

@implementation OneEvent

- (id) initWithEvent:(struct text_event *)event text:(const char *)the_text
{
    name = [[NSMutableString stringWithUTF8String:event->name] retain];
    text = [[NSMutableString stringWithUTF8String:the_text] retain];
    help = [[NSMutableArray arrayWithCapacity:(event->num_args & 0x7f)] retain];

    for (NSInteger i = 0; i < (event->num_args & 0x7f); i ++)
		[help addObject:[NSMutableString stringWithUTF8String:event->help[i]]];
    
    return self;
}

- (void) dealloc
{
    [name release];
    [help release];

    [super dealloc];
}

- (NSUInteger) helpCount
{
    return [help count];
}

- (id) helpRow:(NSInteger)row
{
    return [help objectAtIndex:row];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditEvents

- (id) init
{
    [super init];
     
    myItems = nil;

    [NSBundle loadNibNamed:@"EditEvents" owner:self];
	[[eventTableView window] setTitle:NSLocalizedStringFromTable(@"Edit Events", @"xchat", @"")];
    return self;
}

- (void) dealloc
{
    [[eventTableView window] release];
    [myItems release];
    [super dealloc];
}

- (void) awakeFromNib
{
    myItems = [[NSMutableArray arrayWithCapacity:NUM_XP] retain];
	
    for (NSUInteger i = 0; i < [eventTableView numberOfColumns]; i ++)
        [[[eventTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInteger:i]];

    for (NSUInteger i = 0; i < [helpTableView numberOfColumns]; i ++)
        [[[helpTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInteger:i]];
    
    [eventTableView setDataSource:self];
    [eventTableView setDelegate:self];

    [helpTableView setDataSource:self];

    [testText setPalette:[[AquaChat sharedAquaChat] palette]];
    [testText setFont:[[AquaChat sharedAquaChat] font] boldFont:[[AquaChat sharedAquaChat] boldFont]];

    [[eventTableView window] center];
}

- (void) loadItems
{
	prefs.save_pevents = true;

    [myItems removeAllObjects];

    for (int i = 0; i < NUM_XP; i ++)                      
    {
		OneEvent *item = [[[OneEvent alloc] initWithEvent:&te[i] text:pntevts_text[i]] autorelease];
		[myItems addObject:item];
    }

    [eventTableView reloadData];
}

- (void) show
{
    [self loadItems];
    [[eventTableView window] makeKeyAndOrderFront:self];
}

- (void) doOk:(id)sender
{
    pevent_save(NULL);
    [[sender window] orderOut:sender];
}

- (void) testOne:(int) row
{
	const char *text = pntevts_text[row];
	char *out = strdup(text);
	check_special_chars(out, true);
	// Events have $t which need to be converted to tabs.. stupid design :)
	char *x = out;
	char *y = out;
	while (*x)
	{
		if (x[0] == '$' && x[1] == 't') {
			*y = '\t';
			x ++;
		}
		else {
			*y = *x;
		}
		x ++;
		y ++;
	}
	*y = 0;
	[testText printText:[NSString stringWithUTF8String:out]];
	free(out);
}

- (void) doTestAll:(id) sender
{
    [testText setString:@""];
    for (int i = 0; i < NUM_XP; i ++)                      
        [self testOne:i];
}

- (void) doLoad:(id) sender
{
    NSString *fname = [SGFileSelection selectWithWindow:[sender window]];
    if (fname)
    {
        pevent_load ((char *) [fname UTF8String]);
        pevent_make_pntevts ();
        [self loadItems];
        [eventTableView reloadData];
        [helpTableView reloadData];
    }
}

- (void) doSaveAs:(id) sender
{
    NSString *fname = [SGFileSelection saveWithWindow:[sender window]];
    if (fname)
        pevent_save ((char *) [fname UTF8String]);
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self doOk:self];
}

////////////
// Delegate

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    [helpTableView reloadData];
    [testText setString:@""];
    NSInteger row = [eventTableView selectedRow];
    if (row >= 0)
        [self testOne:row];
}

////////////
// Data Source

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    if (aTableView == eventTableView)
	return [myItems count];

    if (aTableView == helpTableView)
    {
        NSInteger row = [eventTableView selectedRow];
		return row < 0 ? 0 : [[myItems objectAtIndex:row] helpCount];
    }

    return 0;
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    if (aTableView == eventTableView)
    {
		OneEvent *item = [myItems objectAtIndex:rowIndex];
		
		switch ([[aTableColumn identifier] integerValue])
		{
			case 0: return item->name;
			case 1: return item->text;
		}
    }

    if (aTableView == helpTableView)
    {
		switch ([[aTableColumn identifier] integerValue])
		{
			case 0: return [NSNumber numberWithInt:rowIndex + 1];
			case 1:
			{
				NSInteger row = [eventTableView selectedRow];
				return row < 0 ? @"" : [[myItems objectAtIndex:row] helpRow:rowIndex];
			}
		}
    }

    return @"";
}

- (void) tableView:(NSTableView *) aTableView
    setObjectValue:(id) anObject
    forTableColumn:(NSTableColumn *) aTableColumn 
               row:(NSInteger)rowIndex
{
    if (aTableView == eventTableView)
    {
		prefs.save_pevents = true;
		
		OneEvent *item = [myItems objectAtIndex:rowIndex];

		switch ([[aTableColumn identifier] integerValue])
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

				if (m > te[rowIndex].num_args)
				{
					free (out);
					[SGAlert alertWithString:[NSString stringWithFormat:NSLocalizedStringFromTable(@"This signal is only passed %d args, $%d is invalid", @"xchat", @""), te[rowIndex].num_args, m] andWait:false];
					return;
				}

				[item->text setString:anObject];
			
				if (pntevts_text[rowIndex])
					free(pntevts_text[rowIndex]);
				if (pntevts[rowIndex])
					free(pntevts[rowIndex]);

				int len = strlen (text);
				pntevts_text[rowIndex] = (char *) malloc (len + 1);
				memcpy(pntevts_text[rowIndex], text, len + 1);
				pntevts[rowIndex] = out;

				break;
			}
		}
    }
}

@end
