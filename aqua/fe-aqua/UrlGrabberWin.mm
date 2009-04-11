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
#include "../common/url.h"
#include "../common/tree.h"
}

#import "AquaChat.h"
#import "SG.h"
#import "UrlGrabberWin.h"
#import "XACommon.h"
#import "MenuMaker.h"

//////////////////////////////////////////////////////////////////////

@implementation UrlGrabberWin

- (id) initWithObjPtr:(id *) the_pointer
{
    [super init];
    
    self->pointer = the_pointer;
    self->my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"UrlGrabber" owner:self];
    
    *pointer = self;
    
    return self;
}

- (void) dealloc
{
    *pointer = NULL;
    [url_grabber_view release];
    [my_items release];
    [super dealloc];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    *pointer = NULL;
    [self release];
}

static int do_add_url (const void *key, void *cbd)
{
    [(UrlGrabberWin *) cbd add_url:(const char *) key];
	return true;
}

- (void) awakeFromNib
{
    for (int i = 0; i < [self->url_list numberOfColumns]; i ++)
        [[[self->url_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->url_list setDataSource:self];
    [self->url_list setTarget:self];
    [self->url_list setAction:@selector (item_selected:)];

    [url_grabber_view setTitle:NSLocalizedStringFromTable(@"XChat: URL Grabber", @"xchat", @"Title of Window: MainMenu->Window->URL Grabber...")];
    [url_grabber_view setTabTitle:NSLocalizedStringFromTable(@"UrlGrabber", @"xchataqua", @"")];
    [url_grabber_view setDelegate:self];
    
    tree_foreach ((tree *) url_tree, do_add_url, self);
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [url_grabber_view becomeTabAndShow:true];
    else
        [url_grabber_view becomeWindowAndShow:true];
}

- (void) item_selected:(id) sender
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    int row = [self->url_list selectedRow];
    if (row >= 0)
    {
        NSString *url = [my_items objectAtIndex:row];
        NSString *title;
        // TBD: encode 'url' like menu_urlmenu??
        if ([url length] > 50)
            title = [NSString stringWithFormat:@"%@...",
                        [url substringWithRange:NSMakeRange (0, 49)]];
        else
            title = url;
        NSMenuItem *item = [menu addItemWithTitle:title action:NULL keyEquivalent:@""];
        [item setEnabled:false];
		[[MenuMaker defaultMenuMaker] appendItemList:urlhandler_list toMenu:menu withTarget:url inSession:NULL];
    }
    
    [self->url_list setMenu:menu];
}

- (void) add_url:(const char *) msg
{
    [my_items addObject:[NSString stringWithUTF8String:msg]];
    [self->url_list reloadData];
}

- (void) do_save:(id) sender
{
    NSString *fname = [SGFileSelection saveWithWindow:[sender window]];
    if (fname)
        url_save ([fname UTF8String], "w", true);
}

- (void) do_clear:(id) sender
{
    url_clear ();
    [my_items removeAllObjects];
    [self->url_list reloadData];
}

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    return [my_items objectAtIndex:rowIndex];
}

@end
