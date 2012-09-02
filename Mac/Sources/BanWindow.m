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

/* BanWindow.c
 * Correspond to fe-gtk: xchat/src/fe-gtk/banlist.*
 * Correspond to main menu: Window -> Ban List...
 */

#include "outbound.h"
#include "modes.h"

#import "AquaChat.h"
#import "BanWindow.h"
#import "TabOrWindowView.h"

@interface BanItem : NSObject
{
    NSString *mask;
    NSString *who;
    NSString *when;
}

@property (nonatomic, retain) NSString *mask, *who, *when;

- (id) initWithMask:(NSString *)mask who:(NSString *)who when:(NSString *)when;
+ (BanItem *) banWithMask:(NSString *)mask who:(NSString *)who when:(NSString *)when;

@end

@implementation BanItem
@synthesize mask, who, when;

- (id) initWithMask:(NSString *)aMask who:(NSString *)aWho when:(NSString *)aWhen
{    
    if ((self = [super init]) != nil) {
        self.mask = aMask;
        self.who  = aWho;
        self.when = aWhen;
    }
    return self;
}

+ (BanItem *) banWithMask:(NSString *)mask who:(NSString *)who when:(NSString *)when {
    return [[[self alloc] initWithMask:mask who:who when:when] autorelease];
}

- (void) dealloc
{
    self.mask = nil;
    self.who  = nil;
    self.when = nil;
    
    [super dealloc];
}

@end

#pragma mark -

@interface BanWindow (private)

- (void)removeBansInvertly:(BOOL)invert;
- (void)redraw:(id)sender;

@end

@implementation BanWindow

- (void)BanWindowInit {
    self->sess = current_sess;
    bans = [[NSMutableArray alloc] init];
}

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    [self BanWindowInit];
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self BanWindowInit];
    return self;
}

- (void) dealloc
{
    [redrawTimer invalidate];
    [bans release];
    [super dealloc];
}

- (void) awakeFromNib
{
    [self setServer:sess->server];
    
    NSString *serverInfo = [NSString stringWithFormat:@"%s, %s", sess->channel, sess->server->servername];
    [self setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Ban List (%s)", @"xchat", @""), [serverInfo UTF8String]]];
    [self setTabTitle:NSLocalizedStringFromTable(@"banlist", @"xchataqua", @"Title of Tab: MainMenu->Window->Ban List...")];
}

- (void)becomeTabOrWindowAndShow:(BOOL)flag
{
    [super becomeTabOrWindowAndShow:flag];
    [self refreshTableView:nil]; // load list when window showed-up
}

#pragma mark fe-aqua

- (void)addBanWithMask:(NSString *)mask who:(NSString *)who when:(NSString *)when isExemption:(BOOL)isExemption
{
    if (isExemption) return;
    
    [bans addObject:[BanItem banWithMask:mask who:who when:when]];
    
    if (redrawTimer == nil) {
        redrawTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                       target:self
                                                     selector:@selector(redraw:)
                                                     userInfo:nil
                                                      repeats:NO];
    }
}

- (void)refreshFinished
{
    [refreshButton setEnabled:YES];
}

#pragma mark IBAction

- (void)refreshTableView:(id)sender
{
    if (sess->server->connected)
    {
        [bans removeAllObjects];
        [banTableView reloadData];
        
        [refreshButton setEnabled:NO];
        
        handle_command(sess, "ban", false);
    }
    else
        [SGAlert alertWithString:NSLocalizedStringFromTable(@"Not connected.", @"xchat", @"") andWait:NO];
}

- (void)removeSelectedBans:(id)sender {
    // Unban selected
    [self removeBansInvertly:NO];
}

- (void)removeUnselectedBans:(id)sender {
    // Unban not-selected
    [self removeBansInvertly:YES];
}

- (void)removeAllBans:(id)sender {
    // Unban all
    [banTableView selectAll:sender];
    [self removeBansInvertly:NO];
}

#pragma mark NSTableView protocols

- (NSInteger) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [bans count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    BanItem *item = [bans objectAtIndex:rowIndex];
    
    switch ( [[aTableView tableColumns] indexOfObjectIdenticalTo:aTableColumn] )
    {
        case 0: return [item mask];
        case 1: return [item who];
        case 2: return [item when];
    }
    
    SGAssert(NO);
    return @"";
}

@end

#pragma mark -

@implementation BanWindow (private)

- (void)removeBansInvertly:(BOOL)invert
{
    NSMutableArray *nicks = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < [bans count]; i ++)
    {
        BOOL isTarget = [banTableView isRowSelected:i];
        if ( invert ) isTarget = !isTarget;
        
        if ( isTarget )
            [nicks addObject:[(BanItem *)[bans objectAtIndex:i] mask]];
    }
    
    const char **masks = (const char **) malloc ([nicks count] * sizeof (const char *));
    for (NSUInteger i = 0; i < [nicks count]; i ++)
        masks[i] = [[nicks objectAtIndex:i] UTF8String];
    
    char tbuf[2048];
    send_channel_modes (sess, tbuf, (char **) masks, 0, (int)[nicks count], '-', 'b', 0);
    
    free (masks);
    
    [nicks release];
    [self refreshTableView:nil];
}

- (void)redraw:(id)sender {
    redrawTimer = nil;
    [banTableView reloadData];
}

@end

