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
#include "../common/modes.h"
#include "../common/util.h"
}

#import "AquaChat.h"
#import "SG.h"
#import "BanListWin.h"

//////////////////////////////////////////////////////////////////////

@interface oneBan : NSObject
{
  @public
    NSString	*mask;
    NSString	*who;
    NSString	*when;
}

- (id) initWithMask:(const char *) the_mask
                who:(const char *) the_who
               when:(const char *) the_when;

@end

@implementation oneBan

- (id) initWithMask:(const char *) the_mask
                who:(const char *) the_who
               when:(const char *) the_when
{
    mask = [[NSString stringWithUTF8String:the_mask] retain];
    who = [[NSString stringWithUTF8String:the_who] retain];
    when = [[NSString stringWithUTF8String:the_when] retain];
    
    return self;
}

- (void) dealloc
{
    [mask release];
    [who release];
    [when release];
    [super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation BanListWin

- (id) initWithSelfPtr:(id *) self_ptr session:(session *) the_sess
{
    [super initWithSelfPtr:self_ptr];
    
    self->sess = the_sess;
    self->timer = NULL;
    
    my_items = [[NSMutableArray arrayWithCapacity:0] retain];
    
    [NSBundle loadNibNamed:@"BanList" owner:self];
	
	return self;
}

- (void) dealloc
{
    if (timer)
        [timer invalidate];
    [ban_list_view release];
    [my_items release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [ban_list_view setServer:sess->server];

    [ban_list_view setTitle:[NSString stringWithFormat:
							 [NSString stringWithFormat:
							  NSLocalizedStringFromTable(@"XChat: Ban List (%s)", @"xchat", @""),
							  "%s, %s"],
							 sess->channel, sess->server->servername]];
    [ban_list_view setTabTitle:NSLocalizedStringFromTable(@"banlist", @"xchataqua", @"Title of Tab: MainMenu->Window->Ban List...")];
    
	
    for (int i = 0; i < [self->ban_list numberOfColumns]; i ++)
        [[[self->ban_list tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInt:i]];

    [self->ban_list setDataSource:self];
    [self->ban_list_view setDelegate:self];
}

- (void) windowDidBecomeKey:(NSNotification *) xx
{
}

- (void) windowWillClose:(NSNotification *) xx
{
    [self release];
}

- (void) show
{
    if (prefs.windows_as_tabs)
        [ban_list_view becomeTabAndShow:true];
    else
        [ban_list_view becomeWindowAndShow:true];
}

- (void) do_refresh:(id) sender
{
    if (sess->server->connected)
    {
        [my_items removeAllObjects];
        [ban_list reloadData];

        [refresh_button setEnabled:false];
        
        handle_command (sess, "ban", FALSE);
    }
    else
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"Not connected.", @"xchat", @"") andWait:false];
}

- (void) perform_unban:(bool) all invert:(bool) invert
{
    NSMutableArray *nicks = [NSMutableArray arrayWithCapacity:0];
    
    for (unsigned int i = 0; i < [my_items count]; i ++)
    {
        bool unban_this_one = all || [ban_list isRowSelected:i];
        if (invert)
            unban_this_one = !unban_this_one;
        
        if (unban_this_one)
            [nicks addObject:((oneBan *) [my_items objectAtIndex:i])->mask];
    }
    
    const char **masks = (const char **) malloc ([nicks count] * sizeof (const char *));
    for (unsigned int i = 0; i < [nicks count]; i ++)
        masks [i] = [[nicks objectAtIndex:i] UTF8String];
        
    char tbuf[2048];
    send_channel_modes (sess, tbuf, (char **) masks, 0, [nicks count], '-', 'b', 0);
    
    free (masks);
    
    [self do_refresh:nil];
}

- (void) do_unban:(id) sender
{
    // Unban selected
    [self perform_unban:false invert:false];
}

- (void) do_crop:(id) sender
{
    // Unban not-selected
    [self perform_unban:false invert:true];
}

- (void) do_wipe:(id) sender
{
    // Unban all
    [self perform_unban:true invert:false];
}

- (void) redraw:(id) sender
{
    [timer release];
    timer = NULL;
    [ban_list reloadData];
}

- (void) add_ban_list:(const char *)mask who:(const char *) who
	when:(const char *) when is_exemption:(bool) is_exemption
{
	if (is_exemption)
		return;
		
    [my_items addObject:[[oneBan alloc] initWithMask:mask who:who when:when]];

    if (!timer)
        timer = [[NSTimer scheduledTimerWithTimeInterval:1
                            target:self
                            selector:@selector(redraw:)
                            userInfo:nil
                            repeats:NO
                            retainArgs:NO] retain];
}

- (void) ban_list_end
{
    [refresh_button setEnabled:true];
}

//////////////
//

- (int) numberOfRowsInTableView:(NSTableView *) aTableView
{
    return [my_items count];
}

- (id) tableView:(NSTableView *) aTableView
    objectValueForTableColumn:(NSTableColumn *) aTableColumn
    row:(int) rowIndex
{
    oneBan *item = [my_items objectAtIndex:rowIndex];

    switch ([[aTableColumn identifier] intValue])
    {
        case 0: return item->mask;
        case 1: return item->who;
        case 2: return item->when;
    }
    
    return @"";
}

@end
