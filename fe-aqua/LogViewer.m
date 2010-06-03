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
#include "../common/cfgfiles.h"

#import "SG.h"
#import "LogViewer.h"

#include <sys/stat.h>

//////////////////////////////////////////////////////////////////////

@interface LogTableView : NSTableView

@end

@implementation LogTableView

- (void) keyDown:(NSEvent *) event 
{ 
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0]; 
    NSUInteger flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask; 
    if (key == NSDeleteCharacter && flags == 0 && [self selectedRow] != -1) 
    { 
        [(LogViewer *)[self delegate] tableViewRemoveRows:self];
    }
    else
    { 
        [super keyDown:event];
    } 
} 

@end

//////////////////////////////////////////////////////////////////////

@interface OneLog : NSObject
{
  @public
    NSString    *filename;
}

@property (nonatomic, readonly) NSString *path;

- (id) initWithFilename:(NSString *)filename;

@end

@implementation OneLog

- (id) initWithFilename:(NSString *)aFilename
{
    self = [super init];
    
    filename = [aFilename retain];
    
    return self;
}

- (void) dealloc
{
    [filename release];
    [super dealloc];
}

- (BOOL) filter:(NSString *) filter
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
    NSString *path = [self path];
    
    int fd = open ([path fileSystemRepresentation], O_RDONLY);
    
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

- (void) reveal
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), filename];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void) edit
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), filename];
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"/Applications/TextEdit.app"];
}

- (void) delete
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), filename];
    unlink ([path fileSystemRepresentation]);
}

@end

//////////////////////////////////////////////////////////////////////

@implementation LogViewer

- (id) init
{
    self = [super init];
    
    myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    allItems = [[NSMutableArray arrayWithCapacity:0] retain];

    [NSBundle loadNibNamed:@"LogWindow" owner:self];
    
    return self;
}

- (void) dealloc
{
    [logView release];
    [myItems release];
    [allItems release];
    [super dealloc];
}

- (void) doFilter:(id) sender
{
    [myItems removeAllObjects];

    NSString *filter = [filterSearchField stringValue];
    
    for (NSUInteger i = 0; i < [allItems count]; i ++)
    {
        OneLog *row = [allItems objectAtIndex:i];
        if ([row filter:filter])
            [myItems addObject:row];
    }
    
    [logTableView reloadData];
}

- (void) loadData
{
    [allItems removeAllObjects];

    NSString *dir = [NSString stringWithFormat:@"%s/xchatlogs", get_xdir_fs ()];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
    
    for (NSString *filename = [enumerator nextObject]; filename != nil; filename = [enumerator nextObject])
    {
		if ([filename compare:@".DS_Store"] == NSOrderedSame)
			continue;
			
        OneLog *log = [[OneLog alloc] initWithFilename:filename];
        [allItems addObject:log];
        [log release];
    }

    [self doFilter:nil];
}

- (void) awakeFromNib
{
    [logView setTitle:NSLocalizedStringFromTable(@"XChat: Log Viewer", @"xchataqua", @"Title of Window: MainMenu->Window->Log List")];
    [logView setTabTitle:NSLocalizedStringFromTable(@"logviewer", @"xchataqua", @"Title of Tab: MainMenu->Window->Log List")];
    
    for (NSUInteger i = 0; i < [logTableView numberOfColumns]; i ++)
        [[[logTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

#if 0
    [logTextView setPalette:[[AquaChat sharedAquaChat] palette]];
    [logTextView setFont:[[AquaChat sharedAquaChat] font]
              boldFont:[[AquaChat sharedAquaChat] boldFont]];
#endif

    [self loadData];
}

- (void) doReveal:(id) sender
{
	NSInteger row = [logTableView selectedRow];
	if (row < 0) return;
	OneLog *log = [myItems objectAtIndex:row];
	[log reveal];
}

- (void) doEdit:(id) sender
{
    NSIndexSet *set = [logTableView selectedRowIndexes];
    if (!set)
        return;
    
    NSInteger row = [set firstIndex];
    while (row != NSNotFound)
    {
        OneLog *log = [myItems objectAtIndex:row];
        [log edit];
        row = [set indexGreaterThanIndex:row];
    }
}

- (void) doRefresh:(id) sender
{
    [self loadData];
}

- (void) doDelete:(id) sender
{
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [logView becomeTabAndShow:YES];
    else
        [logView becomeWindowAndShow:YES];
}

//////////////
//
// Delegate Methods

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [myItems count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    OneLog *item = [myItems objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] integerValue])
    {
        case 0: return item->filename;
    }
    
    return @"";
}

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    NSString *contents = @"";
    
    NSInteger row = [logTableView selectedRow];
    if (row >= 0 && [logTableView numberOfSelectedRows] == 1)
    {
        OneLog *log = [myItems objectAtIndex:row];
        contents = [log contents];
    }
    
    [logTextView setString:contents];
}

// custom method
- (void) tableViewRemoveRows:(NSTableView *) tableView
{
    if ([SGAlert confirmWithString:NSLocalizedStringFromTable(@"Are you sure you want to remove the selected log files?", @"xchataqua", @"Alert message at: MainMenu->Window->Log List")])
    {
        NSIndexSet *set = [logTableView selectedRowIndexes];
        if (!set)
            return;
        
        NSInteger row = [set firstIndex];
        while (row != NSNotFound)
        {
            OneLog *log = [myItems objectAtIndex:row];
            [log delete];
            row = [set indexGreaterThanIndex:row];
        }
        
        [self loadData];
    }
}

@end
