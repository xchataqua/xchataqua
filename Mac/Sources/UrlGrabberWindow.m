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

/* UrlGrabberWindow.m
 * Correspond to fe-gtk: xchat/src/fe-gtk/urlgrab.*
 * Correspond to main menu: Window -> URL Grabber...
 */

#include "url.h"
#include "tree.h"

#import "UrlGrabberWindow.h"
#import "MenuMaker.h"

@implementation UrlGrabberWindow

- (id) UrlGrabberWindowInit
{
    urls = [[NSMutableArray alloc] init];
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return self;
}

- (id) initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    return self;
}

- (void) dealloc
{
    [urls release];
    [super dealloc];
}

static int do_add_url (const void *key, void *cbd)
{
    [(UrlGrabberWindow *)cbd addUrl:@((const char *)key)];
    return true;
}

- (void) awakeFromNib
{
    [self->urlTableView setTarget:self];
    
    [self setTitle:NSLocalizedStringFromTable(@"XChat: URL Grabber", @"xchat", @"Title of Window: MainMenu->Window->URL Grabber...")];
    [self setTabTitle:NSLocalizedStringFromTable(@"urlgrabber", @"xchataqua", @"")];
    
    tree_foreach ((tree *)url_tree, do_add_url, self);
}

#pragma mark fe-aqua

- (void) addUrl:(NSString *)url
{
    [urls addObject:url];
    [self->urlTableView reloadData];
}

#pragma mark IBActions

- (void) buildMenu:(id)sender
{
    NSInteger urlIndex = [self->urlTableView selectedRow];
    if (urlIndex < 0) return;
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
    NSString *url = urls[urlIndex];
    NSString *menuTitle = url;
    // TODO: encode 'url' like menu_urlmenu??
    if ([url length] > 50)
        menuTitle = [@"%@..." format:[url substringWithRange:NSMakeRange (0, 45)]];
    NSMenuItem *item = [menu addItemWithTitle:menuTitle action:nil keyEquivalent:@""];
    [item setEnabled:NO];
    [[MenuMaker defaultMenuMaker] appendItemList:urlhandler_list toMenu:menu withTarget:url inSession:NULL];
    
    [self->urlTableView setMenu:menu];
    [menu release];
}

- (void) save:(id)sender
{
    NSSavePanel *panel = [NSSavePanel savePanel];
    [panel beginSheetModalForWindow:[sender window] completionHandler:^(NSInteger result) {
        if (result == NSOKButton) {
            url_save((char *)panel.URL.path, "w", true);
        }
    }];
}

- (void)removeAllURLs:(id)sender
{
    url_clear();
    [urls removeAllObjects];
    [self->urlTableView reloadData];
}

#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [urls count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return urls[rowIndex];
}

@end
