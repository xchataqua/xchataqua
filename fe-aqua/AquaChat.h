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
/* AquaChat */

#include "../common/xchat.h"

#import <Growl/GrowlApplicationBridge.h>

#define PreferencesWindowKey    @"PreferencesWindow"

#define AsciiWindowKey          @"AsciiWindow"
#define BanWindowKey            @"BanWindow"
#define ChannelWindowKey        @"ChannelWindow"
#define FriendWindowKey         @"FriendWindow"
#define IgnoreWindowKey         @"IgnoreWindow"
#define NetworkWindowKey        @"NetworkWindow"
#define PluginWindowKey         @"PluginWindow"
#define RawLogWindowKey         @"RawLogWindow"
#define UrlGrabberWindowKey     @"UrlGrabberWindow"
#define UserCommandsWindowKey   @"UserCommandsWindow"
#define TextEventsWindowKey     @"TextEventsWindow"
#define LogViewWindowKey        @"LogViewWindow"

#define CTCPRepliesWindowKey    @"CTCPRepliesWindow"
#define UserlistButtonsWindowKey @"UserlistButtonsWindow"
#define UserlistPopupWindowKey  @"UserlistPopupWindow"
#define DialogButtonsWindowKey  @"DialogButtonsWindow"
#define ReplacePopupWindowKey   @"ReplacePopupWindow"
#define URLHandlersWindowKey    @"URLHandlersWindow"
#define UserMenusWindowKey      @"UserMenusWindow"

#define UtilityWindowKey(KEY, ADDR) [KEY stringByAppendingFormat:@"_%x", ADDR]

struct eventInfo
{
    int growl;
    int show;
    int bounce;
};

extern struct eventInfo textEventInfo[];

@class ColorPalette;
@class DccSendWin;
@class DccRecvWin;
@class DccChatWin;

@interface AquaChat : NSObject <GrowlApplicationBridgeDelegate>
{
@public
    IBOutlet NSMenuItem *awayMenuItem;
    IBOutlet NSMenuItem *invisibleMenuItem;
    IBOutlet NSMenuItem *newChannelTabMenuItem;
    IBOutlet NSMenuItem *newServerTabMenuItem;
    IBOutlet NSMenuItem *nextWindowMenuItem;
    IBOutlet NSMenuItem *previousWindowMenuItem;
    IBOutlet NSMenuItem *receiveNoticesMenuItem;
    IBOutlet NSMenuItem *receiveWallopsMenuItem;
    IBOutlet NSMenu *userMenu;
    
    NSString *searchString;
    
    ColorPalette *palette;
    
    NSFont *font;
    NSFont *boldFont;
    
    DccSendWin *dcc_send_window;
    DccRecvWin *dcc_recv_window;
    DccChatWin *dcc_chat_window;
    
    NSMutableDictionary *soundCache;
    NSImage *appImage, *alertImage;
}

@property (nonatomic, readonly) NSFont *font, *boldFont;
@property (nonatomic, retain) ColorPalette *palette;

- (void) preferencesChanged;

- (void) event:(int) event args:(char **) args session:(struct session *) sess;

+ (AquaChat *) sharedAquaChat;

+ (void) forEachSessionOnServer:(struct server *)server performSelector:(SEL)sel;
+ (void) forEachSessionOnServer:(struct server *)server performSelector:(SEL)sel withObject:(id) obj;

// fe-aqua
- (void) post_init;
- (void) toggleAwayToValue:(bool)is_away;
- (void) cleanup;
- (void) updatePluginWindow;
- (void) updateIgnoreWindowForLevel:(int)level;
- (void) updateFriendWindow;
- (void) updateDcc:(struct DCC *) dcc;
- (void) addDcc:(struct DCC *) dcc;
- (void) removeDcc:(struct DCC *) dcc;
- (int) openDccSendWindowAndShow:(BOOL)show;
- (int) openDccRecieveWindowAndShow:(BOOL)show;
- (int) openDccChatWindowAndShow:(BOOL)show;
- (void) addUrl:(const char *) url;
- (void) playWaveNamed:(const char *)filename;
- (void) openNetworkWindowForSession:(struct session *) sess;
- (void) growl:(NSString *)text title:(NSString *)title;
- (void) ctrl_gui:(struct session *) sess action:(int) action arg:(int) arg;
- (void) server_event:(struct server *)server event_type:(int)type arg:(int)arg;

// MainMenu IBAction
// Standard menu
- (IBAction) showPreferencesWindow:(id)sender;
- (IBAction) showUserCommandsWindow:(id)sender;
- (IBAction) showCtcpRepliesWindow:(id)sender;
- (IBAction) showUserlistButtonsWindow:(id)sender;
- (IBAction) showUserlistPopupWindow:(id)sender;
- (IBAction) showDialogButtonsWindow:(id)sender;
- (IBAction) showReplacePopupWindow:(id)sender;
- (IBAction) showUrlHandlersWindow:(id)sender;
- (IBAction) showTextEventsWindow:(id)sender;
// File menu
- (IBAction) showNetworkWindow:(id)sender;
- (IBAction) openNewServer:(id)sender;
- (IBAction) openNewChannel:(id)sender;
- (IBAction) loadPlugin:(id)sender;
// Edit menu
- (IBAction) clearWindow:(id)sender;
- (IBAction) showSearchPanel:(id)sender;
- (IBAction) searchAgain:(id)sender;
// IRC menu
- (IBAction) toggleInvisible:(id)sender;
- (IBAction) toggleReceiveWallops:(id)sender;
- (IBAction) toggleReceiveServerNotices:(id)sender;
- (IBAction) toggleAway:(id)sender;
// Usermenu menu
- (IBAction) showUserMenusWindow:(id)sender;
// Window menu
- (IBAction) closeTab:(id)sender;
- (IBAction) toggleTabAttachment:(id)sender;
- (IBAction) selectNextTab:(id)sender;
- (IBAction) selectPreviousTab:(id)sender;
- (IBAction) showChannelWindow:(id)sender;
- (IBAction) showBanWindow:(id)sender;
- (IBAction) showAsciiWindow:(id)sender;
- (IBAction) showDccChatWindow:(id)sender;
- (IBAction) showDccRecieveWindow:(id)sender;
- (IBAction) showDccSendWindow:(id)sender;
- (IBAction) showIgnoreWindow:(id)sender;
- (IBAction) showFriendWindow:(id)sender;
- (IBAction) showPluginWindow:(id)sender;
- (IBAction) showRawLogWindow:(id)sender;
- (IBAction) showUrlGrabberWindow:(id)sender;
- (IBAction) showLogViewWindow:(id)sender;
// Help menu
- (IBAction) openHomepage:(id)sender;
- (IBAction) openDownload:(id)sender;
- (IBAction) showReleaseNotes:(id)sender;
- (IBAction) openOnlineDocs:(id)sender;

@end
