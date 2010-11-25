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

#import "XAChatTextView.h"
#import "AquaChat.h"
#import "TextEventsWindow.h"

extern struct text_event te[];
extern char *pntevts_text[];
extern char *pntevts[];

@interface TextEventsItem : NSObject
{
	NSString *name;
	NSString *text;
	NSMutableArray *helps;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, readonly) NSMutableArray *helps;

+ (TextEventsItem *)textEventWithEvent:(struct text_event *)event text:(NSString *)text;

@end

@implementation TextEventsItem
@synthesize name, text, helps;

+ (TextEventsItem *) textEventWithEvent:(struct text_event *)event text:(NSString *)aText
{
	TextEventsItem *textEvent = [[self alloc] init];
	if ( textEvent != nil ) {
		textEvent->name = [[NSString alloc] initWithUTF8String:event->name];
		textEvent.text = aText;
		textEvent->helps = [[NSMutableArray alloc] initWithCapacity:event->num_args & 0x7f];

		for (NSInteger i = 0; i < (event->num_args & 0x7f); i++)
			[textEvent->helps addObject:[NSString stringWithUTF8String:event->help[i]]];
	}
	return [textEvent autorelease];
}

- (void) dealloc
{
	self.text = nil;
	[self->name release];
	[self->helps release];
	
	[super dealloc];
}

@end

#pragma mark -

@interface TextEventsWindow (Private)

- (void)loadItems;
- (void)testOne:(int)row;

@end


@implementation TextEventsWindow

- (void) dealloc
{
	[eventsItems release];
	[super dealloc];
}

- (void) awakeFromNib
{
	eventsItems = [[NSMutableArray alloc] initWithCapacity:NUM_XP];
	
	[testTextView setPalette:[[AquaChat sharedAquaChat] palette]];
	[testTextView setFont:[[AquaChat sharedAquaChat] font] boldFont:[[AquaChat sharedAquaChat] boldFont]];

	[self center];
	
	[self loadItems];
}

- (void) close
{
	pevent_save(NULL);
	[super close];
}

#pragma mark -
#pragma mark IBActions

- (void) testAll:(id)sender
{
	[eventTableView deselectAll:nil];
	[testTextView setString:@""];
	for (int i = 0; i < NUM_XP; i ++)					  
		[self testOne:i];
}

- (void) loadFrom:(id)sender
{
	NSString *fname = [SGFileSelection selectWithWindow:self];
	if (fname)
	{
		pevent_load ((char *) [fname UTF8String]);
		pevent_make_pntevts ();
		[self loadItems];
		[eventTableView reloadData];
		[helpTableView reloadData];
	}
}

- (void) saveAs:(id)sender
{
	NSString *fname = [SGFileSelection saveWithWindow:self];
	if (fname)
		pevent_save ((char *) [fname UTF8String]);
}

#pragma mark -
#pragma mark NSTableView delegate

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
	[helpTableView reloadData];
	[testTextView setString:@""];
	NSInteger row = [eventTableView selectedRow];
	if (row >= 0)
		[self testOne:row];
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
	if (aTableView == eventTableView)
		return [eventsItems count];

	if (aTableView == helpTableView)
	{
		NSInteger row = [eventTableView selectedRow];
		return row < 0 ? 0 : [[(TextEventsItem *)[eventsItems objectAtIndex:row] helps] count];
	}

	SGAssert(NO);
	return 0;
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	NSInteger column = [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn];
	
	if (aTableView == eventTableView)
	{
		TextEventsItem *item = [eventsItems objectAtIndex:rowIndex];
		
		switch ( column )
		{
			case 0: return [item name];
			case 1: return [item text];
		}
	}

	if (aTableView == helpTableView)
	{
		switch ( column )
		{
			case 0: return [NSNumber numberWithInteger:rowIndex+1];
			case 1:
			{
				NSInteger eventIndex = [eventTableView selectedRow];
				return eventIndex < 0 ? @"" : [[(TextEventsItem *)[eventsItems objectAtIndex:eventIndex] helps] objectAtIndex:rowIndex];
			}
		}
	}

	SGAssert(NO);
	return @"";
}

- (void) tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	if (aTableView == eventTableView)
	{
		prefs.save_pevents = true;
		
		TextEventsItem *item = [eventsItems objectAtIndex:rowIndex];

		switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
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

#pragma mark -

@implementation TextEventsWindow (Private)

- (void) loadItems
{
	prefs.save_pevents = true;
	
	[eventsItems removeAllObjects];
	
	for (int i = 0; i < NUM_XP; i ++)					  
	{
		[eventsItems addObject:[TextEventsItem textEventWithEvent:&te[i] text:[NSString stringWithUTF8String:pntevts_text[i]]]];
	}
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
	[testTextView printText:[NSString stringWithUTF8String:output]];
	free(output);
}

@end
