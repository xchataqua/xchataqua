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
#include "../common/text.h"

#import "AquaChat.h"
#import "EditEvents.h"
#import "SG.h"

//////////////////////////////////////////////////////////////////////

extern struct text_event te[];
extern char *pntevts_text[];
extern char *pntevts[];

//////////////////////////////////////////////////////////////////////

@interface EditEventsItem : NSObject
{
	NSString	*name;
	NSString	*text;
	NSMutableArray	*helps;
}

@property (nonatomic, retain) NSString *name, *text;
@property (nonatomic, readonly) NSMutableArray *helps;

- (id) initWithEvent:(struct text_event *)event text:(const char *)text;

@end

@implementation EditEventsItem
@synthesize name, text, helps;

- (id) initWithEvent:(struct text_event *)event text:(const char *)aText
{
	self.name = [NSString stringWithUTF8String:event->name];
	self.text = [NSString stringWithUTF8String:aText];
	self->helps = [[NSMutableArray alloc] initWithCapacity:event->num_args & 0x7f];

	for (NSInteger i = 0; i < (event->num_args & 0x7f); i ++)
		[helps addObject:[NSString stringWithUTF8String:event->help[i]]];
	
	return self;
}

- (void) dealloc
{
	self.name = nil;
	self.text = nil;
	[self->helps release];
	
	[super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation EditEvents

- (id) init
{
	[super init];
	 
	eventsItems = nil;

	[NSBundle loadNibNamed:@"EditEvents" owner:self];
	[[eventTableView window] setTitle:NSLocalizedStringFromTable(@"Edit Events", @"xchat", @"")];
	return self;
}

- (void) dealloc
{
	[[eventTableView window] release];
	[eventsItems release];
	[super dealloc];
}

- (void) awakeFromNib
{
	eventsItems = [[NSMutableArray alloc] initWithCapacity:NUM_XP];
	
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

	[eventsItems removeAllObjects];

	for (int i = 0; i < NUM_XP; i ++)					  
	{
		EditEventsItem *item = [[EditEventsItem alloc] initWithEvent:&te[i] text:pntevts_text[i]];
		[eventsItems addObject:item];
		[item release];
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
	char *output = strdup(text);
	check_special_chars(output, true);
	// Events have $t which need to be converted to tabs.. stupid design :)
	char *x = output;
	char *y = output;
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
	[testText printText:[NSString stringWithUTF8String:output]];
	free(output);
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
	return [eventsItems count];

	if (aTableView == helpTableView)
	{
		NSInteger row = [eventTableView selectedRow];
		return row < 0 ? 0 : [[[eventsItems objectAtIndex:row] helps] count];
	}

	return 0;
}

- (id) tableView:(NSTableView *) aTableView
	objectValueForTableColumn:(NSTableColumn *) aTableColumn
	row:(NSInteger) rowIndex
{
	if (aTableView == eventTableView)
	{
		EditEventsItem *item = [eventsItems objectAtIndex:rowIndex];
		
		switch ([[aTableColumn identifier] integerValue])
		{
			case 0: return [item name];
			case 1: return [item text];
		}
	}

	if (aTableView == helpTableView)
	{
		switch ([[aTableColumn identifier] integerValue])
		{
			case 0: return [NSNumber numberWithInteger:rowIndex+1];
			case 1:
			{
				NSInteger row = [eventTableView selectedRow]; // diffrent to rowIndex?
				return row < 0 ? @"" : [[[eventsItems objectAtIndex:row] helps] objectAtIndex:rowIndex];
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
		
		EditEventsItem *item = [eventsItems objectAtIndex:rowIndex];

		switch ([[aTableColumn identifier] integerValue])
		{
			case 1:
			{
				const char *text = [anObject UTF8String];

				char *output;
				int m;
				if (pevt_build_string (text, &output, &m) != 0)
				{
					[SGAlert alertWithString:NSLocalizedStringFromTable(@"There was an error parsing the string", @"xchat", @"") andWait:false];
					return;
				}

				if (m > te[rowIndex].num_args)
				{
					free (output);
					[SGAlert alertWithString:[NSString stringWithFormat:NSLocalizedStringFromTable(@"This signal is only passed %d args, $%d is invalid", @"xchat", @""), te[rowIndex].num_args, m] andWait:false];
					return;
				}

				[item setText:anObject];
			
				if (pntevts_text[rowIndex])
					free(pntevts_text[rowIndex]);
				if (pntevts[rowIndex])
					free(pntevts[rowIndex]);

				int len = strlen (text);
				pntevts_text[rowIndex] = (char *) malloc (len + 1);
				memcpy(pntevts_text[rowIndex], text, len + 1);
				pntevts[rowIndex] = output;

				break;
			}
		}
	}
}

@end
