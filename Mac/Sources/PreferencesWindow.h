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

/* PreferencesWindow.h
 * Correspond to fe-gtk: xchat/src/fe-gtk/setup.c
 * Correspond to main menu: Application -> Preferences...
 */

#import <ShortcutRecorder/ShortcutRecorder.h>
#import "UtilityWindow.h"

enum
{
    MYPREF_STRING,
    MYPREF_INT,
    MYPREF_MENU
};

struct PreferenceItem
{
    id       item;
    void    *pref;
    int      type;
};

@interface PreferencesWindow : UtilityWindow<NSOutlineViewDataSource, NSComboBoxDataSource, NSOpenSavePanelDelegate> {
    IBOutlet NSTabView    *tabView;
    IBOutlet NSBox *contentBox;
    IBOutlet NSOutlineView *categoryOutlineView;
    IBOutlet NSTabViewItem *colorsTabViewItem;
    
    NSColorWell *colorWells[41];
    NSMutableArray *sounds;
    NSMutableArray *soundEvents;
    
    NSArray *categories;
    
    //Interface
    
    // Text box
    //  Text Box Appearance
    IBOutlet NSTextField *textBoxFontTextField, *lineHeightTextField, *backgroundImageTextField, *maxLinesTextField;
    IBOutlet NSButton *scrollbackStripColorCheckBox;
    IBOutlet NSButton *coloredNicksCheckBox, *indentNicksCheckBox, *showSeparatorCheckBox, *stripMircColorCheckBox;
    //  Transparency Settings
    IBOutlet NSButton *transparentCheckBox;    // not in fe-aqua
    IBOutlet NSSlider *transparentSlider;
    //  Time Stamps
    IBOutlet NSButton *timeStampCheckBox;
    IBOutlet NSTextField *timeStampFormatTextField;
 
    // Input box
    //  Input box
    IBOutlet NSButton *inputBoxUseTextBoxFontCheckBox, *spellCheckingCheckBox;
    IBOutlet NSButton *interpretPercentAsciiCheckBox, *interpretPercentColorCheckBox; // not in fe-gtk
    //  Nick Completion
    IBOutlet NSButton *tabCompletionCheckBox; // fe-aqua
    IBOutlet NSButton *suffixCompletionCheckBox; // xchat completion?
    IBOutlet NSTextField *suffixCompletionTextField;
    IBOutlet NSPopUpButton *nickCompletionSortPopUp;
    IBOutlet NSButton *scrollingCompletionCheckBox; // fe-aqua
    
    // User list
    //  User List
    IBOutlet NSButton *hideUserlistCheckBox, *userlistUseTextBoxFontCheckBox, *showUserlistButtonsCheckBox; // not in fe-gtk
    IBOutlet NSButton * showHostnameCheckBox;
    IBOutlet NSPopUpButton *userlistSortPopUp;
    //  missing 'Show user list at' in fe-gtk
    //  Away tracking
    IBOutlet NSButton *awayTrackCheckBox;
    IBOutlet NSTextField *awayMaxSizeTextField;
    //  Action Upon Double Click
    IBOutlet NSTextField *doubleClickCommandTextField;
    
    // Channel switcher
    IBOutlet NSPopUpButton *switcherTypePopUp;
    IBOutlet NSButton *useServerTabCheckBox, *useNoticesTabCheckBox, *autoDialogCheckBox;
    //  missing 'sort tabs' 'smaller text' in fe-gtk
    IBOutlet NSButton *newTabsToFrontCheckBox; // not in fe-gtk
    IBOutlet NSButton *hideTabCloseButtonsCheckBox; // fe-aqua
    IBOutlet NSButton *smallerTextTabCheckBox;
    IBOutlet SRRecorderCell *tabLeftRecorderCell, *tabRightRecorderCell; // fe-aqua
    IBOutlet NSPopUpButton *tabPositionPopUp;
    IBOutlet NSTextField *shortenTabLabelLengthTextField;
    //  missing 'shorten tab labels' in fe-gtk
    //  Tabs or Windows
    IBOutlet NSPopUpButton *openChannelsInPopUp, *openDialogsInPopUp, *openUtilitiesInPopUp;
    
    // Others - not in fe-gtk
    IBOutlet NSButton *showChannelModeButtonsCheckBox;
    IBOutlet NSTextField *defaultCharsetTextField;    // fe-aqua
    
    //  Command - fe-aqua
    IBOutlet NSTextField *urlLinkCommandTextField, *nickLinkCommandTextField, *channelLinkCommandTextField;
    
    // Colors
    //  Text Colors
    //  Marking Text
    //  Interface Colors
    
    //Chatting
    
    // Alerts
    //  Alerts - many part missing
    IBOutlet NSButton *beepOnChannelCheckBox, *beepOnPrivateCheckBox, *beepOnHighlightedCheckBox;
    //  highlighted Messages
    IBOutlet NSTextField *extraHighlightWordsTextField, *noHighlightWordsTextField, *nickHighlightWordsTextField;
    //  missing 'nicknames not to highlight' 'nicknames always to highlight' in fe-gtk
    
    // Generals
    //  Default Messages
    IBOutlet NSTextField *quitMessageTextField, *partMessageTextField, *awayMessageTextField;
    IBOutlet NSTextField *sleepMessageTextField; // fe-aqua
    //  Away
    IBOutlet NSButton *showAwayMessageCheckBox, *autoUnmarkAwayCheckBox, *showAwayOnceCheckBox;
    IBOutlet NSButton *partOnSleepCheckBox, *autoAwayCheckBox; // fe-aqua
    IBOutlet NSTextField *autoAwayMinutesTextField; // fe-aqua
    //  Other - not in fe-gtk
    IBOutlet NSButton *autoRejoinCheckBox, *whoisOnNotifyCheckBox, *rawModesCheckBox, *hideJoinPartCheckBox;
    
    // Logging
    //  Logging
    IBOutlet NSButton *displayPreviousScrollbackCheckBox;
    IBOutlet NSButton *enableLoggingCheckBox;
    IBOutlet NSTextField *logFilenameMaskTextField;
    //  Time Stamps
    IBOutlet NSButton *timestampsInLogsCheckBox;
    IBOutlet NSTextField *timestampInLogsFormatTextField;
    
    // Sound
    //  missing Sound playing method and external player stubs in fe-gtk
    IBOutlet NSTableView *soundsTableView;
    
    //Network
    
    // Network setup
    //  Your Address
    IBOutlet NSTextField *bindAddressTextField;
    //  Proxy Server
    IBOutlet NSTextField *proxyHostTextField, *proxyPortTextField;
    IBOutlet NSPopUpButton *proxyTypePopUp, *proxyUsePopup;
    //  Proxy Authenication
    IBOutlet NSButton *proxyAuthenicationCheckBox;
    IBOutlet NSTextField *proxyUsernameTextField, *proxyPasswordTextField;
    //  Other - not in fe-gtk
    IBOutlet NSTextField *autoReconnectDelayTextField;
    IBOutlet NSButton *autoReconnectCheckBox, *neverGiveUpReconnectionCheckBox, *identdCheckBox;
    
    // File transfers
    //  Files and Directories
    IBOutlet NSPopUpButton *autoAcceptDccPopUp;
    IBOutlet NSTextField *downloadsDirectoryTextField, *completedDownloadsDirectoryTextField;
    IBOutlet NSButton *downloadWithNickCheckBox, *downloadSpaceToUnderscoreCheckBox;
    //  Network Settings
    IBOutlet NSButton *ipFromServerCheckBox;
    IBOutlet NSTextField *dccAddressTextField, *dccFirstSendPortTextField, *dccLastSendPortTextField;
    //  Other - not in fe-gtk
    IBOutlet NSPopUpButton *autoAcceptDccChatPopUp;
    IBOutlet NSButton *autoOpenDccChatCheckBox, *autoOpenDccReceiveCheckBox, *autoOpenDccSendCheckBox;
    
    struct PreferenceItem preferenceItems[96];
}

- (IBAction)applyPreferences:(id)sender;
- (IBAction)performOK:(id)sender;
- (IBAction)performCancel:(id)sender;
- (IBAction)showRawPreferences:(id)sender;

- (IBAction)applyFont:(id)sender;
- (IBAction)applyBackgroundImage:(id)sender;
- (IBAction)removeBackgroundImage:(id)sender;
- (IBAction)applyTranparency:(id)sender;

- (IBAction)loadColorFromDefault:(id)sender;
- (IBAction)loadColorFromFile:(id)sender;

@end
