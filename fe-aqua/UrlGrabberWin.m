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
#include "../common/url.h"
#include "../common/tree.h"

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
    self->myItems = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"UrlGrabber" owner:self];
    
    *pointer = self;
    
    return self;
}

- (void) dealloc
{
    *pointer = NULL;
    [urlGrabberView release];
    [myItems release];
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
    [(UrlGrabberWin *)cbd addUrl:[NSString stringWithUTF8String:(const char *)key]];
	return true;
}

- (void) awakeFromNib
{
    for (NSUInteger i = 0; i < [self->urlTableView numberOfColumns]; i ++)
        [[[self->urlTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->urlTableView setDataSource:self];
    [self->urlTableView setTarget:self];
    [self->urlTableView setAction:@selector (item_selected:)];

    [urlGrabberView setTitle:NSLocalizedStringFromTable(@"XChat: URL Grabber", @"xchat", @"Title of Window: MainMenu->Window->URL Grabber...")];
    [urlGrabberView setTabTitle:NSLocalizedStringFromTable(@"urlgrabber", @"xchataqua", @"")];
    [urlGrabberView setDelegate:self];
    
    tree_foreach ((tree *) url_tree, do_add_url, self);
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [urlGrabberView becomeTabAndShow:YES];
    else
        [urlGrabberView becomeWindowAndShow:YES];
}

- (void) item_selected:(id) sender
{
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    
    NSInteger row = [self->urlTableView selectedRow];
    if (row >= 0)
    {
        NSString *url = [myItems objectAtIndex:row];
        NSString *title;
        // TBD: encode 'url' like menu_urlmenu??
        if ([url length] > 50)
            title = [NSString stringWithFormat:@"%@...", [url substringWithRange:NSMakeRange (0, 49)]];
        else
            title = url;
        NSMenuItem *item = [menu addItemWithTitle:title action:nil keyEquivalent:@""];
        [item setEnabled:NO];
		[[MenuMaker defaultMenuMaker] appendItemList:urlhandler_list toMenu:menu withTarget:url inSession:NULL];
    }
    
    [self->urlTableView setMenu:menu];
}

- (void) addUrl:(NSString *) msg
{
    [myItems addObject:msg];
    [self->urlTableView reloadData];
}

- (void) doSave:(id) sender
{
    NSString *fname = [SGFileSelection saveWithWindow:[sender window]];
    if (fname)
        url_save([fname UTF8String], "w", true);
}

- (void) doClear:(id) sender
{
    url_clear();
    [myItems removeAllObjects];
    [self->urlTableView reloadData];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [myItems count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(NSInteger) rowIndex
{
    return [myItems objectAtIndex:rowIndex];
}

@end
