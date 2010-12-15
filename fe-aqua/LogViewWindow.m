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

#include <sys/stat.h>

#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/cfgfiles.h"

#import "LogViewWindow.h"

@interface LogItem : NSObject
{
	NSString	*filename;
}

@property (nonatomic, readonly) NSString *filename;
@property (nonatomic, readonly) NSString *path;
@property (nonatomic, readonly) NSString *contents;

+ (LogItem *)logWithFilename:(NSString *)filename;
- (BOOL)filter:(NSString *)filter;

@end

@implementation LogItem
@synthesize filename;

- (void) dealloc
{
	[filename release];
	[super dealloc];
}

+ (LogItem *) logWithFilename:(NSString *)aFilename {
	LogItem *log = [[self alloc] init];
	if ( log != nil ) {
		log->filename = [aFilename retain];
	}
	return [log autorelease];
}

- (BOOL) filter:(NSString *)filter
{
	if (filter == nil || [filter length] == 0)
		return YES;
	NSRange where = [filename rangeOfString:filter options:NSCaseInsensitiveSearch];
	return where.location != NSNotFound;
}


- (NSString *) path
{
	return [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), filename];
}

- (NSString *) contents
{	
	int fd = open ([[self path] fileSystemRepresentation], O_RDONLY);
	
	struct stat sb;
	fstat (fd, &sb);
	
	char *buff = (char *) malloc (sb.st_size + 1);
	
	char *ptr = buff;
	ssize_t len;
	while ((len = read (fd, ptr, sb.st_size - (ptr - buff))) > 0)
		;
	buff[sb.st_size] = 0;
	
	NSString *contents = [NSString stringWithUTF8String:buff];
	
	free(buff);
	
	return contents;
}

@end

#pragma mark -

@implementation LogViewWindow

- (id) LogViewWindowInit {
	filteredLogs = [[NSMutableArray alloc] init];
	allLogs = [[NSMutableArray alloc] init];
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	return [self LogViewWindowInit];
}

- (id) initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	[self LogViewWindowInit];
	return self;
}

- (void) dealloc
{
	[filteredLogs release];
	[allLogs release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self setTitle:NSLocalizedStringFromTable(@"XChat: Log Viewer", @"xchataqua", @"Title of Window: MainMenu->Window->Log List")];
	[self setTabTitle:NSLocalizedStringFromTable(@"logviewer", @"xchataqua", @"Title of Tab: MainMenu->Window->Log List")];

#if 0
	[logTextView setPalette:[[AquaChat sharedAquaChat] palette]];
	[logTextView setFont:[[AquaChat sharedAquaChat] font]
				boldFont:[[AquaChat sharedAquaChat] boldFont]];
#endif

	[self refreshList:nil];
}

#pragma mark Private method

- (void) removeSelectedLogFiles
{
	if (![SGAlert confirmWithString:NSLocalizedStringFromTable(@"Are you sure you want to remove the selected log files?", @"xchataqua", @"Alert message at: MainMenu->Window->Log List")])
		return;

	NSIndexSet *set = [logTableView selectedRowIndexes];
	if (set == nil)
		return;
		
	NSInteger row = [set firstIndex];
	while (row != NSNotFound)
	{
		LogItem *logItem = [filteredLogs objectAtIndex:row];
		unlink([[logItem path] fileSystemRepresentation]);
		row = [set indexGreaterThanIndex:row];
	}
		
	[logTableView deselectAll:nil];
	[self refreshList:nil];
}

#pragma mark IBActions

- (void) doFilter:(id)sender
{
	[filteredLogs removeAllObjects];
	
	NSString *filter = [filterSearchField stringValue];
	
	for (NSUInteger i = 0; i < [allLogs count]; i ++)
	{
		LogItem *log = [allLogs objectAtIndex:i];
		if ([log filter:filter])
			[filteredLogs addObject:log];
	}
	
	[logTableView reloadData];
}


- (void) revealInFinder:(id)sender
{
	NSInteger row = [logTableView selectedRow];
	if (row < 0) return;
	LogItem *log = [filteredLogs objectAtIndex:row];
	[[NSWorkspace sharedWorkspace] selectFile:[log path] inFileViewerRootedAtPath:@""];
}

- (void) openInTextEdit:(id)sender
{
	NSIndexSet *set = [logTableView selectedRowIndexes];
	if (!set)
		return;
	
	NSInteger row = [set firstIndex];
	while (row != NSNotFound)
	{
		LogItem *log = [filteredLogs objectAtIndex:row];
		[[NSWorkspace sharedWorkspace] openFile:[log path] withApplication:@"TextEdit"];
		row = [set indexGreaterThanIndex:row];
	}
}

- (void) refreshList:(id)sender
{
	[allLogs removeAllObjects];
	
	NSString *dir = [NSString stringWithFormat:@"%s/xchatlogs", get_xdir_fs ()];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
	for (NSString *filename = [enumerator nextObject]; filename != nil; filename = [enumerator nextObject])
	{
		if ([filename compare:@".DS_Store"] == NSOrderedSame)
			continue;
		
		[allLogs addObject:[LogItem logWithFilename:filename]];
	}
	
	[self doFilter:nil];
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView {
	return [filteredLogs count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	LogItem *item = [filteredLogs objectAtIndex:rowIndex];

	switch ([[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn])
	{
		case 0: return [item filename];
	}
	
	SGAssert(NO);
	return @"";
}

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
	NSString *contents = @"";
	
	NSInteger row = [logTableView selectedRow];
	if (row >= 0 && [logTableView numberOfSelectedRows] == 1)
	{
		LogItem *logItem = [filteredLogs objectAtIndex:row];
		contents = [logItem contents];
	}
	
	[logTextView setString:contents];
}

@end

#pragma mark -

@interface LogTableView : NSTableView

@end

@implementation LogTableView

- (void) keyDown:(NSEvent *) event 
{ 
	if ( [self selectedRow] < 0 ) return;
	
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0]; 
	NSUInteger flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask; 
	if (key == NSDeleteCharacter && flags == 0) 
	{ 
		[(LogViewWindow *)[self delegate] removeSelectedLogFiles];
	}
	else
	{ 
		[super keyDown:event];
	} 
} 

@end