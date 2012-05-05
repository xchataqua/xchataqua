//
//  UserListView.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 19..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include "userlist.h"

#import "AppDelegate.h"
#import "ColorPalette.h"

#import "UserListView.h"

@interface ChannelUser : NSObject
{
	NSString *nickname, *hostname; // NSString or NSAttributedString
	UIColor *color;
	struct User *user;
}

@property (nonatomic, readonly) struct User *user;
@property (nonatomic, readonly) UIColor *color;
@property (nonatomic, readonly) NSString *nickname, *hostname;

- (id) initWithUser:(struct User *)user;
- (void) rehash;

@end

@implementation ChannelUser
@synthesize user;
@synthesize color;
@synthesize nickname, hostname;

- (id) initWithUser:(struct User *)aUser {
	if ((self = [super init]) != nil) {
		self->user = aUser;
		[self rehash];
	}
	return self;
}

- (void) dealloc
{
	[nickname release];
	[hostname release];
	[color release];
	[super dealloc];
}

- (void) rehash {
	[nickname release];
	[hostname release];
	[color release];
	
	ColorPalette *palette = [ApplicationDelegate colorPalette];
	
	if (user->away) {
		color = [palette getColor:AC_AWAY_USER];
	} else {
		if ( prefs.style_inputbox ) {
			color = [palette getColor:AC_FGCOLOR];
		} else {
			color = [UIColor blackColor];
		}
	}
	[color retain];
	
	nickname = [[NSString alloc] initWithUTF8String:user->nick];
	hostname = user->hostname ? [[NSString alloc] initWithUTF8String:user->hostname] : [@"" retain];
}

@end

@interface UserListView (Private)

- (UIImage *) imageForUser:(struct User *)user;
- (NSInteger) indexOfUser:(struct User *)user;

@end

static UIImage *redBulletImage;
static UIImage *purpleBulletImage;
static UIImage *greenBulletImage;
static UIImage *blueBulletImage;
static UIImage *yellowBulletImage;
static UIImage *emptyBulletImage;

@implementation UserListView
@synthesize session;

+ (void) initialize {
	redBulletImage = [[UIImage imageNamed:@"red.tiff"] retain];
	purpleBulletImage = [[UIImage imageNamed:@"purple.tiff"] retain];
	greenBulletImage = [[UIImage imageNamed:@"green.tiff"] retain];
	blueBulletImage = [[UIImage imageNamed:@"blue.tiff"] retain];
	yellowBulletImage = [[UIImage imageNamed:@"yellow.tiff"] retain];
	emptyBulletImage = nil;
}

- (id)initUserListView {
	users = [[NSMutableArray alloc] init];
	return self;
}

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	return [self initUserListView];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	return [self initUserListView];
}

- (void) dealloc {
	[users release];
	[super dealloc];
}

#pragma mark fe-iphone

- (void) updateStatus {
	[statusLabel setText:[NSString stringWithFormat:XCHATLSTR(@"%d ops, %d total"), self->session->ops, self->session->total]];
}

- (void) rehashUser:(struct User *)user {
	NSInteger idx = [self indexOfUser:user];
	if ( idx == NSNotFound ) return;
	[[users objectAtIndex:idx] rehash];
	[userListTableView reloadData];
}

- (void) insertUser:(struct User *)user row:(NSInteger)row select:(BOOL)select {
	ChannelUser *u = [(ChannelUser *)[ChannelUser alloc] initWithUser:user];
	
	if (row < 0) {
		[users addObject:u];
	} else
	{
		NSInteger selectedRow = [[userListTableView indexPathForSelectedRow] row];
		[users insertObject:u atIndex:row];
		if (selectedRow >= 0 && row <= selectedRow) {
			[userListTableView deselectRowAtIndexPath:[userListTableView indexPathForSelectedRow] animated:NO];
			[userListTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedRow+1 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
		}
	}
	
	if (select) {
		[userListTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
	}
	
	[userListTableView reloadData];
	
	if (user->me)
	{
		UIImage *img = [self imageForUser:user];
		if (img == emptyBulletImage) {
			[myOpOrVoiceImageView setHidden:YES];
		}
		else
		{
			[myOpOrVoiceImageView setImage:img];
			[myOpOrVoiceImageView setHidden:NO];
		}
	}
	[u release];
}

- (BOOL) removeUser:(struct User *)user {
	NSInteger idx = [self indexOfUser:user];
	if (idx == NSNotFound) return NO;
	
	[users removeObjectAtIndex:idx];
	
	NSIndexPath *selectedIndexPath = [userListTableView indexPathForSelectedRow];
	if ( selectedIndexPath.row == idx )
		[userListTableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
	
	[userListTableView reloadData];
	
	return selectedIndexPath.row == idx;
}

- (void) moveUser:(struct User *)user toRow:(NSInteger)row {
	NSInteger idx = [self indexOfUser:user];
	if ( idx == NSNotFound ) return;
	if ( idx != row ) {
		[users exchangeObjectAtIndex:idx withObjectAtIndex:row];
		// TODO: selections
	}
	[userListTableView reloadData];
}

- (void) updateUser:(struct User *)user {
	//[self rehashUser:user]; // FIXME: needed?
	
}

- (void) userlistSelectNames:(char **)names clear:(int)clear scrollTo:(int)scroll_to
{
	if (clear) [userListTableView deselectRowAtIndexPath:[userListTableView indexPathForSelectedRow] animated:NO];
	
	if (*names[0]) {
		for (NSUInteger i = 0, n = [users count]; i < n; i++) {
			struct User *user = [(ChannelUser *)[users objectAtIndex:i] user];
			NSUInteger j = 0;
			do {
				if (self->session->server->p_cmp (user->nick, names[j]) == 0) {
					[userListTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionBottom];
				}
			} while (*names[++j]);
		}
	}
}

- (void) removeAllUsers {
	[users removeAllObjects];
	[userListTableView reloadData];
}

#pragma mark UITableView dataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [users count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *cellIdentifier = @"cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if ( cell == nil ) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
	
	}
	ChannelUser *u = [users objectAtIndex:indexPath.row];
	cell.imageView.image = [self imageForUser:[u user]];
	cell.textLabel.text = [u nickname];
	cell.textLabel.textColor = [u color];
	cell.detailTextLabel.text = [u hostname];
	cell.detailTextLabel.textColor = [u color];
	return cell;
}

@end

@implementation UserListView (Private)

- (UIImage *) imageForUser:(struct User *)user
{
	switch (user->prefix [0])
	{
		case '@': return greenBulletImage;
		case '%': return blueBulletImage;
		case '+': return yellowBulletImage;
	}
	
	/* find out how many levels above Op this user is */
	char *pre = strchr (self->session->server->nick_prefixes, '@');
	if (pre && pre != self->session->server->nick_prefixes)
	{
		pre--;
		NSInteger level = 0;
		while (1)
		{
			if (pre[0] == user->prefix[0])
			{
				switch (level)
				{
					case 0: return redBulletImage;		/* 1 level above op */
					case 1: return purpleBulletImage;	/* 2 levels above op */
				}
				break;								/* 3+, no icons */
			}
			level++;
			if (pre == self->session->server->nick_prefixes)
				break;
			pre--;
		}
	}
	return emptyBulletImage;
}

- (NSInteger) indexOfUser:(struct User *)user {
	for (NSUInteger i = 0; i < [users count]; i++) {
		if ([(ChannelUser *)[users objectAtIndex:i] user] == user)
			return i;
	}
	return NSNotFound;
}

@end

