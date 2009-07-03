/* MenuMaker
 * Copyright (C) 2006 Camillo Lugaresi
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

/*
	MenuMaker.mm
	Created by Camillo Lugaresi on 16/01/06.
	
	This class handles menu generation.
*/

#import "MenuMaker.h"
#import "XACommon.h"
#include "AquaChat.h"	/* ok, I give up. I'll use C++. :( */
#include "ChatWindow.h"

extern "C" {
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/util.h"
#include "../common/server.h"
#undef TYPE_BOOL	/* clash between cfgfiles.h and ConditionalMacros.h  */
#include "../common/cfgfiles.h"
}

#if CLX_BUILD
static unsigned handlerCount = 0;

void incHandlerCount()
{
	handlerCount++;
	printf("handlers allocated: %d\n", handlerCount);
}

void decHandlerCount()
{
	handlerCount--;
	printf("handlers allocated: %d\n", handlerCount);
}
#endif

//////////////////////////////////////////////////////////////////////

@interface CommandHandler : NSObject {
	char *cmd;
	char *target;
	session *sess;
}
@end

@implementation CommandHandler

- (CommandHandler *)initWithCommand:(const char *)inCmd target:(const char *)inTarget session:(session *)inSess
{
	cmd = strdup(inCmd);
	target = inTarget ? strdup(inTarget) : NULL;
	sess = inSess;
#if CLX_BUILD
	incHandlerCount();
#endif
	return self;
}

- (void)dealloc
{
	if (cmd) free(cmd);
	if (target) free(target);
#if CLX_BUILD
	decHandlerCount();
#endif
	[super dealloc];
}

+ (CommandHandler *)handlerWithCommand:(const char *)cmd target:(const char *)target session:(session *)sess
{
	return [[[CommandHandler alloc] initWithCommand:cmd target:target session:sess] autorelease];
}

- (IBAction)execute:(id)sender
{
	session *targetSess = sess ? sess : (current_sess ? current_sess : (session *)sess_list->data);
	if (target)
		nick_command_parse (targetSess, cmd, target, target);
	else
		[targetSess->gui->cw do_userlist_command:cmd];
}

@end

//////////////////////////////////////////////////////////////////////

@interface TogglerHandler : NSObject {
	BOOL ownsEntry;
	menu_entry *entry;
}
@end

@implementation TogglerHandler

- (TogglerHandler *)initWithOption:(const char *)opt
{
	entry = (menu_entry *)malloc (sizeof (menu_entry));
	ownsEntry = YES;
	asprintf(&entry->cmd, "set %s %d", opt, 1);
	asprintf(&entry->ucmd, "set %s %d", opt, 0);
#if CLX_BUILD
	incHandlerCount();
#endif
	return self;
}

- (TogglerHandler *)initWithMenuEntry:(menu_entry *)inEntry
{
	entry = inEntry;
#if CLX_BUILD
	incHandlerCount();
#endif
	return self;
}

- (void)dealloc
{
	if (ownsEntry) {
		free(entry->cmd);
		free(entry->ucmd);
		free(entry);
	}
#if CLX_BUILD
	decHandlerCount();
#endif
	[super dealloc];
}

+ (TogglerHandler *)togglerWithOption:(const char *)opt
{
	return [[[TogglerHandler alloc] initWithOption:opt] autorelease];
}

+ (TogglerHandler *)togglerWithMenuEntry:(menu_entry *)entry
{
	return [[[TogglerHandler alloc] initWithMenuEntry:entry] autorelease];
}

- (IBAction)execute:(id)sender
{
	if ([sender state] == NSOnState) {
		[sender setState:NSOffState];
		entry->state = 0;
		handle_command (current_sess, entry->ucmd, FALSE);
	} else {
		[sender setState:NSOnState];
		entry->state = 1;
		handle_command (current_sess, entry->cmd, FALSE);
	}
}

@end

//////////////////////////////////////////////////////////////////////

@implementation MenuMaker

static MenuMaker *defaultMenuMaker;

+ (MenuMaker *)defaultMenuMaker
{
	if (defaultMenuMaker == nil) defaultMenuMaker = [[MenuMaker alloc] init];
	return defaultMenuMaker;
}

- (MenuMaker *)init
{
	NSString *labels[] = {NSLocalizedStringFromTable(@"Real Name:", @"xchat", @""), NSLocalizedStringFromTable(@"User:", @"xchat", @""), NSLocalizedStringFromTable(@"Country:", @"xchat", @""),
						  NSLocalizedStringFromTable(@"Server:", @"xchat", @""), NSLocalizedStringFromTable(@"Away Msg:", @"xchat", @""), NSLocalizedStringFromTable(@"Last Msg:", @"xchat", @"")};
	NSMutableAttributedString *test;
	NSSize size;

	self = [super init];
	
	for (unsigned i = 0; i < (sizeof(labels) / sizeof(labels[0])); i++) {
		test = [[NSMutableAttributedString alloc] initWithString:[labels[i] stringByAppendingString:@"	"]
				attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:0], NSFontAttributeName, nil]];
		size = [test size];
		if (maxUserInfoLabelWidth < size.width) maxUserInfoLabelWidth = size.width;
		[test dealloc];
	}
	test = [[NSMutableAttributedString alloc] initWithString:@"	"
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:0], NSFontAttributeName, nil]];
	size = [test size];
	userInfoTabWidth = size.width;
	[test dealloc];
	
	return self;
}

- (NSMenuItem *)userInfoItemWithLabel:(NSString *)label value:(const char *)value
{
	NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:[label stringByAppendingString:@"	"]
		attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:0], NSFontAttributeName, nil]];

	do {
		NSSize size = [attrTitle size];
		if (maxUserInfoLabelWidth - size.width < userInfoTabWidth) break;
		[[attrTitle mutableString] appendString:@"	"];
	} while (1);

	NSAttributedString *attrValue = [[NSAttributedString alloc] initWithString:value ? [NSString stringWithUTF8String:value] : NSLocalizedStringFromTable(@"Unknown", @"xchat", @"")
		attributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:0], NSFontAttributeName, nil]];
	[attrTitle appendAttributedString:attrValue];
	[attrValue release];

#if 0	/* menu items ignore paragraph styles! */
	NSMutableParagraphStyle *paraStyle = [[NSMutableParagraphStyle alloc] init];
	NSTextTab *tab = [[NSTextTab alloc] initWithType:NSLeftTabStopType location:300.0];
	[paraStyle addTabStop:tab];
	[attrTitle addAttribute:NSParagraphStyleAttributeName value:paraStyle range:NSMakeRange(0,[attrTitle length])];
	[paraStyle release];
	[tab release];
	[attrTitle fixAttributesInRange:NSMakeRange(0,[attrTitle length])];
#endif

	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[attrTitle string] action:nil keyEquivalent:@""];
	[item setAttributedTitle:attrTitle];
	[attrTitle release];
	return [item autorelease];
}

- (NSMenu *)infoMenuForUser:(struct User *)user inSession:(session *)sess
{
	char min[96];

	NSMenu *userMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[userMenu setAutoenablesItems:false];

	[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"Real Name:", @"xchat", @"") value:user->realname]];
	[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"User:", @"xchat", @"") value:user->hostname]];
	[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"Country:", @"xchat", @"") value:user->hostname ? country(user->hostname) : NULL]];
	[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"Server:", @"xchat", @"") value:user->servername]];

	if (user->away) {
		struct away_msg *away = server_away_find_message (sess->server, user->nick);
		if (away) {
			char *msg = away->message ? strip_color(away->message, -1, STRIP_ALL) : nil;
			[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"Away Msg:", @"xchat", @"") value:msg]];
			if (msg) free(msg);
		}else {
            // Creating a whois for away message
            char buf[512];
            sprintf(buf, "WHOIS %s %s", user->nick, user->nick);
            handle_command(sess, buf, FALSE);
            sess->server->skip_next_whois = 1;
        }
	}
	
	if (user->lasttalk)
		snprintf(min, sizeof(min), XALocalizeString("%u minutes ago"), (unsigned int) ((time (0) - user->lasttalk) / 60));
	
	[userMenu addItem:[self userInfoItemWithLabel:NSLocalizedStringFromTable(@"Last Msg:", @"xchat", @"") value:user->lasttalk ? min : NULL]];

	return userMenu;
}

- (NSMenu *)menuForURL:(NSString *)url inSession:(session *)sess
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu setAutoenablesItems:false];
	[menu addItem:[self commandItemWithName:[url UTF8String] command:"url %s" target:url session:sess]];
	[menu addItem:[NSMenuItem separatorItem]];
	[self appendItemList:urlhandler_list toMenu:menu withTarget:url inSession:NULL];
    return menu;
}

- (NSMenu *)menuForNick:(NSString *)nick inSession:(session *)sess
{
	struct User *user = userlist_find_global(sess->server, (char *)[nick UTF8String]);
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu setAutoenablesItems:false];
	if (user) {
		NSMenuItem *userItem = [menu addItemWithTitle:nick action:nil keyEquivalent:@""];
		[userItem setSubmenu:[self infoMenuForUser:user inSession:sess]];
		[menu addItem:[NSMenuItem separatorItem]];
	}
	[self appendItemList:popup_list toMenu:menu withTarget:nick inSession:sess];
    return menu;
}

- (NSMenu *)menuForChannel:(NSString *)chan inSession:(session *)sess
{
	NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu setAutoenablesItems:false];
	[menu addItem:[self commandItemWithName:[chan UTF8String] command:"join %s" target:chan session:sess]];
	[menu addItem:[NSMenuItem separatorItem]];
	if (find_channel(sess->server, (char *)[chan UTF8String])) {
		[menu addItem:[self commandItemWithName:XALocalizeString("Part Channel") command:"part %s" target:chan session:sess]];
		[menu addItem:[self commandItemWithName:XALocalizeString("Cycle Channel") command:"cycle" target:NULL session:sess]];
	} else {
		[menu addItem:[self commandItemWithName:XALocalizeString("Join Channel") command:"join %s" target:chan session:sess]];
	}
	return menu;
}

- (NSMenuItem *)commandItemWithName:(const char *)name command:(const char *)cmd target:(NSString *)target session:(session *)sess
{
    NSString * icon = nil;
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[self stripImageFromTitle:[NSString stringWithUTF8String:name]  icon:&icon] action:@selector(execute:) keyEquivalent:@""];
	CommandHandler *handler = [CommandHandler handlerWithCommand:cmd target:(target ? [target UTF8String] : NULL) session:sess];
	[item setRepresentedObject:handler];
	[item setTarget:handler];
    if(icon)
    {
        NSString * path = [[NSBundle mainBundle] pathForResource:icon ofType:@"tiff" inDirectory:@"Images"];
        if(path)
            [item setImage:[[[NSImage alloc] initWithContentsOfFile:path] autorelease]];
    }
	return [item autorelease];
}

- (NSMenuItem *)togglerItemWithName:(const char *)name option:(const char *)opt
{
	NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[NSString stringWithUTF8String:name] action:@selector(execute:) keyEquivalent:@""];
	TogglerHandler *handler = [TogglerHandler togglerWithOption:opt];
	[item setRepresentedObject:handler];
	[item setTarget:handler];
	[item setState:cfg_get_bool((char *) opt) ? NSOnState : NSOffState];
	return [item autorelease];
}

- (void) appendItemList:(GSList *)list toMenu:(NSMenu *)menu withTarget:(NSString *)target inSession:(session *)sess
{
	struct popup *pop;
	NSMenu *currentMenu = menu;
	NSMenuItem *item;

	while (list) {
		pop = (struct popup *) list->data;
		if (!strncasecmp (pop->name, "SUB", 3)) {
			item = [currentMenu addItemWithTitle:[self stripImageFromTitle:[NSString stringWithUTF8String:pop->cmd] icon:nil] action:nil keyEquivalent:@""];

			currentMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
			[currentMenu setAutoenablesItems:false];
			[item setSubmenu:currentMenu];
		}
		else if (!strncasecmp (pop->name, "TOGGLE", 6)) {
			[currentMenu addItem:[self togglerItemWithName:pop->name + 7 option:pop->cmd]];
		}
		else if (!strncasecmp (pop->name, "ENDSUB", 6)) {
			if (currentMenu != menu)
				currentMenu = [currentMenu supermenu];
		}
		else if (!strncasecmp (pop->name, "SEP", 3)) {
			[currentMenu addItem:[NSMenuItem separatorItem]];
		}
		else {
			[currentMenu addItem:[self commandItemWithName:pop->name command:pop->cmd target:target session:sess]];
		}
		list = list->next;
	}
}

- (NSMenu *) menu_find_from_path:(char*) path
{
	NSMenu *menu = [NSApp mainMenu];
	char *next, *rest = path;
	char namebuf[128];
	
	while (rest && *rest) {
		next = strchr(rest, '/');
		size_t len = next ? next - rest : strlen(rest);
		len = MIN(len, sizeof(namebuf) - 1);
		memcpy(namebuf, rest, len);
		namebuf[len] = 0;
		
		NSString *name = [NSString stringWithUTF8String:namebuf];
		if (!name) return nil;
		NSMenuItem *item = [menu itemWithTitle:name];
		if (!item) return nil;
		menu = [item submenu];
		if (!menu) return nil;
		rest = next;
	}
	return menu;
}

- (void) menu_del:(menu_entry *) entry
{
	NSMenu *parent = [self menu_find_from_path:entry->path];
	if (parent == nil) return;
	NSMenuItem *item = [parent itemWithTitle:[NSString stringWithUTF8String:entry->label]];
	if (item == nil) return;
	[parent removeItem:item];
}

- (void) menu_add:(menu_entry *) entry
{
	NSMenu *parent = [self menu_find_from_path:entry->path];
	NSMenuItem *item;
	
	if (parent == nil) return;
	if (entry->label) {
		NSString *title = [NSString stringWithUTF8String:entry->label];
		item = [[[NSMenuItem alloc] initWithTitle:title
										   action:nil
									keyEquivalent:@""] autorelease];
		if (entry->ucmd) {	/* toggle */
			TogglerHandler *handler = [TogglerHandler togglerWithMenuEntry:entry];
			[item setAction:@selector(execute:)];
			[item setRepresentedObject:handler];
			[item setTarget:handler];
			[item setState:entry->state ? NSOnState : NSOffState];
		} else if (entry->cmd) {	/* regular item */
			CommandHandler *handler = [CommandHandler handlerWithCommand:entry->cmd target:NULL session:NULL];
			[item setAction:@selector(execute:)];
			[item setRepresentedObject:handler];
			[item setTarget:handler];
		} else {	/* submenu */
			NSMenu *submenu = [[[NSMenu alloc] initWithTitle:title] autorelease];
			[submenu setAutoenablesItems:false];
			[item setSubmenu:submenu];
		}
		[item setEnabled:entry->enable];
	} else {	/* separator */
		item = [NSMenuItem separatorItem];
	}
	if (item == nil) return;
	if (entry->pos == -1) [parent addItem:item];
	else [parent insertItem:item atIndex:entry->pos];
	/* UNIMPLEMENTED: how should we handle modifiers? */
}

- (void) menu_update:(menu_entry *) entry
{
	NSMenu *parent = [self menu_find_from_path:entry->path];
	if (parent == nil) return;
	NSMenuItem *item = [parent itemWithTitle:[NSString stringWithUTF8String:entry->label]];
	if (item == nil) return;
	[item setEnabled:entry->enable];
	[item setState:entry->state ? NSOnState : NSOffState];
}

- (NSString *)stripImageFromTitle:(NSString *)title icon:(NSString **)icon
{
    int length;
    // stringByReplacingOccurrencesOfString is not available on 10.4.
    //    title = [title stringByReplacingOccurrencesOfString:@"_" withString:@""];
    NSMutableString *mTitle = [title mutableCopy];
    [mTitle replaceOccurrencesOfString:@"_" withString:@"" options:NSCaseInsensitiveSearch range:(NSRange){0,[mTitle length]}];
    title = [NSString stringWithString: [mTitle autorelease]];

    length = [title length];
    if([[title substringFromIndex:length-1] isEqualToString:@"~"])
    {
        NSRange r = [title rangeOfString:@"~" options:NSBackwardsSearch range:NSMakeRange(0, length-1)];
        if(r.location == NSNotFound)
            return title;
        
        if(icon)
            *icon = [[title substringWithRange:NSMakeRange(r.location+1, length-r.location-2)] retain];
        title = [title substringToIndex:r.location];
    }
    return title;    
}


@end
