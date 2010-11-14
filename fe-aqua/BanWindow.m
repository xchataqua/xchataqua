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
#include "../common/modes.h"

#import "AquaChat.h"
#import "BanWindow.h"
#import "TabOrWindowView.h"
#import "NSTimerAdditions.h"
#import "SGAlert.h"

//////////////////////////////////////////////////////////////////////

@interface BanItem : NSObject
{
	NSString *mask;
	NSString *who;
	NSString *when;
}

@property (nonatomic, retain) NSString *mask, *who, *when;

- (id) initWithMask:(NSString *)mask who:(NSString *)who when:(NSString *)when;

@end

@implementation BanItem
@synthesize mask, who, when;

- (id) initWithMask:(NSString *)aMask who:(NSString *)aWho when:(NSString *)aWhen
{	
	self.mask = aMask;
	self.who  = aWho;
	self.when = aWhen;
	
	return self;
}

- (void) dealloc
{
	self.mask = nil;
	self.who  = nil;
	self.when = nil;
	
	[super dealloc];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation BanWindow

- (id)BanWindowInit {
	self->sess = current_sess;
	bans = [[NSMutableArray alloc] init];
	return self;
}

- (id)initWithFrame:(NSRect)frameRect {
	[super initWithFrame:frameRect];
	return [self BanWindowInit];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	[super initWithCoder:aDecoder];
	return [self BanWindowInit];
}

- (void) dealloc
{
	if (timer != nil) [timer invalidate];
	[bans release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[self setServer:sess->server];

	NSString *serverInfo = [NSString stringWithFormat:@"%s, %s", sess->channel, sess->server->servername];
	[self setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"XChat: Ban List (%s)", @"xchat", @""), [serverInfo UTF8String]]];
	[self setTabTitle:NSLocalizedStringFromTable(@"banlist", @"xchataqua", @"Title of Tab: MainMenu->Window->Ban List...")];
	
	for ( NSInteger i = 0; i < [self->banTableView numberOfColumns]; i++ )
		[[[self->banTableView tableColumns] objectAtIndex:i] setIdentifier:[NSNumber numberWithInteger:i]];
}

- (void)becomeTabOrWindowAndShow
{
	[super becomeTabOrWindowAndShow];
	[self doRefresh:nil]; // load list when window showed-up
}

- (void) doRefresh:(id) sender
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

- (void) performUnban:(BOOL)all invert:(BOOL)invert
{
	NSMutableArray *nicks = [NSMutableArray array];
	
	for (NSUInteger i = 0; i < [bans count]; i ++)
	{
		BOOL unban_this_one = all || [banTableView isRowSelected:i];
		if (invert) unban_this_one = !unban_this_one;
		
		if (unban_this_one)
			[nicks addObject:[(BanItem *)[bans objectAtIndex:i] mask]];
	}
	
	const char **masks = (const char **) malloc ([nicks count] * sizeof (const char *));
	for (NSUInteger i = 0; i < [nicks count]; i ++)
		masks [i] = [[nicks objectAtIndex:i] UTF8String];
		
	char tbuf[2048];
	send_channel_modes (sess, tbuf, (char **) masks, 0, [nicks count], '-', 'b', 0);
	
	free (masks);
	
	[self doRefresh:nil];
}

- (void) doUnban:(id) sender
{
	// Unban selected
	[self performUnban:NO invert:NO];
}

- (void) doCrop:(id) sender
{
	// Unban not-selected
	[self performUnban:NO invert:YES];
}

- (void) doWipe:(id) sender
{
	// Unban all
	[self performUnban:YES invert:NO];
}

- (void) redraw:(id) sender
{
	[timer release];
	timer = nil;
	[banTableView reloadData];
}

- (void) addBanList:(NSString *)mask who:(NSString *)who when:(NSString *)when isExemption:(BOOL)isExemption
{
	if (isExemption) return;
		
	[bans addObject:[[[BanItem alloc] initWithMask:mask who:who when:when] autorelease]];
	
	if (!timer)
		timer = [[NSTimer scheduledTimerWithTimeInterval:1
												  target:self
												selector:@selector(redraw:)
												userInfo:nil
												 repeats:NO
											  retainArgs:NO] retain];
}

- (void) banListEnd
{
	[refreshButton setEnabled:YES];
}

//////////////
//

- (NSInteger) numberOfRowsInTableView:(NSTableView *) aTableView
{
	return [bans count];
}

- (id) tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	BanItem *item = [bans objectAtIndex:rowIndex];

	switch ( [[aTableColumn identifier] integerValue] )
	{
		case 0: return [item mask];
		case 1: return [item who];
		case 2: return [item when];
	}
	
	return @"";
}

@end
