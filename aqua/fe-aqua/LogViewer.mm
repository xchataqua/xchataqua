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
#include "../common/cfgfiles.h"
}

#import "SG.h"
#import "LogViewer.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <unistd.h>

//////////////////////////////////////////////////////////////////////

@interface LogTableView : NSTableView
{
}
@end

@implementation LogTableView

- (void) keyDown:(NSEvent *) event 
{ 
    unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0]; 
    unsigned int flags = [event modifierFlags] & NSDeviceIndependentModifierFlagsMask; 
    if (key == NSDeleteCharacter && flags == 0 && [self selectedRow] != -1) 
    { 
        [[self delegate] tableViewRemoveRows:self];
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
    NSString    *fname;
}

- (id) initWithFile:(NSString *) fname;

@end

@implementation OneLog

- (id) initWithFile:(NSString *) theFname
{
    self = [super init];
    
    fname = [theFname retain];
    
    return self;
}

- (void) dealloc
{
    [fname release];
    [super dealloc];
}

- (bool) filter:(NSString *) filter
{
    if (filter == NULL || [filter length] == 0)
        return true;    
    NSRange where = [fname rangeOfString:filter options:NSCaseInsensitiveSearch];
    return where.location != NSNotFound;
}

- (NSString *) getPath
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), fname];
    return path;
}

- (NSString *) contents
{
    NSString *path = [self getPath];
    
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
    
    free (buff);
    
    return contents;
}

- (void) reveal
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), fname];
    [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:@""];
}

- (void) edit
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), fname];
    [[NSWorkspace sharedWorkspace] openFile:path withApplication:@"/Applications/TextEdit.app"];
}

- (void) delete
{
    NSString *path = [NSString stringWithFormat:@"%s/xchatlogs/%@", get_xdir_fs (), fname];
    unlink ([path fileSystemRepresentation]);
}

@end

//////////////////////////////////////////////////////////////////////

@implementation LogViewer

- (id) init
{
    self = [super init];
    
    my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    all_items = [[NSMutableArray arrayWithCapacity:0] retain];

    [NSBundle loadNibNamed:@"LogWindow" owner:self];
    
    return self;
}

- (void) dealloc
{
    [log_viewer_view release];
    [my_items release];
    [all_items release];
    [super dealloc];
}

- (void) do_filter:(id) sender
{
    [my_items removeAllObjects];

    NSString *filter = [filter_text stringValue];
    
    for (unsigned i = 0; i < [all_items count]; i ++)
    {
        OneLog *row = [all_items objectAtIndex:i];
        if ([row filter:filter])
            [my_items addObject:row];
    }
    
    [log_list reloadData];
}

- (void) load_data
{
    [all_items removeAllObjects];

    NSString *dir = [NSString stringWithFormat:@"%s/xchatlogs", get_xdir_fs ()];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtPath:dir];
    
    for (NSString *fname; fname = [enumerator nextObject]; )
    {
		if ([fname compare:@".DS_Store"] == NSOrderedSame)
			continue;
			
        OneLog *log = [[OneLog alloc] initWithFile:fname];
        [all_items addObject:log];
        [log release];
    }

    [self do_filter:NULL];
}

- (void) awakeFromNib
{
    [log_viewer_view setTitle:NSLocalizedStringFromTable(@"XChat: Log Viewer", @"xchataqua", @"Title of Window: MainMenu->Window->Log List")];
    [log_viewer_view setTabTitle:NSLocalizedStringFromTable(@"logviewer", @"xchataqua", @"Title of Tab: MainMenu->Window->Log List")];
    
    for (int i = 0; i < [log_list numberOfColumns]; i ++)
        [[[log_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

#if 0
    [log_text setPalette:[[AquaChat sharedAquaChat] getPalette]];
    [log_text setFont:[[AquaChat sharedAquaChat] getFont]
              boldFont:[[AquaChat sharedAquaChat] getBoldFont]];
#endif

    [self load_data];
}

- (void) do_reveal:(id) sender
{
    unsigned row = [log_list selectedRow];
    if (row < 0)
        return;
    OneLog *log = [my_items objectAtIndex:row];
    [log reveal];
}

- (void) do_edit:(id) sender
{
    NSIndexSet *set = [log_list selectedRowIndexes];
    if (!set)
        return;
    
    unsigned row = [set firstIndex];
    while (row != NSNotFound)
    {
        OneLog *log = [my_items objectAtIndex:row];
        [log edit];
        row = [set indexGreaterThanIndex:row];
    }
}

- (void) do_refresh:(id) sender
{
    [self load_data];
}

- (void) do_delete:(id) sender
{
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [log_viewer_view becomeTabAndShow:true];
    else
        [log_viewer_view becomeWindowAndShow:true];
}

//////////////
//
// Delegate Methods

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    OneLog *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->fname;
    }
    
    return @"";
}

- (void) tableViewSelectionDidChange:(NSNotification *) aNotification
{
    NSString *contents = @"";
    
    int row = [log_list selectedRow];
    if (row >= 0 && [log_list numberOfSelectedRows] == 1)
    {
        OneLog *log = [my_items objectAtIndex:row];
        contents = [log contents];
    }
    
    [log_text setString:contents];
}

// custom method
- (void) tableViewRemoveRows:(NSTableView *) tableView
{
    if ([SGAlert confirmWithString:NSLocalizedStringFromTable(@"Are you sure you want to remove the selected log files?", @"xchataqua", @"Alert message at: MainMenu->Window->Log List")])
    {
        NSIndexSet *set = [log_list selectedRowIndexes];
        if (!set)
            return;
        
        unsigned row = [set firstIndex];
        while (row != NSNotFound)
        {
            OneLog *log = [my_items objectAtIndex:row];
            [log delete];
            row = [set indexGreaterThanIndex:row];
        }
        
        [self load_data];
    }
}

@end
