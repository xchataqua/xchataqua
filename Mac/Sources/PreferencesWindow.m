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

/* PreferencesWindow.m
 * Correspond to fe-gtk: xchat/src/fe-gtk/setup.c
 * Correspond to main menu: Application -> Preferences...
 */

#import "PreferencesWindow.h"
#import "AquaChat.h"
#import "ColorPalette.h"
#import "ChatViewController.h"
#import "NSPanelAdditions.h"
#import "XAFileUtil.h"

#include "text.h"
#undef TYPE_BOOL
#include "cfgfiles.h"

extern char *sound_files[];
extern struct text_event te[];
extern struct XATextEventItem XATextEvents[];

@interface PreferenceLeaf : NSObject
{
@public
    NSString *label;
    int       pane;
}

+ (PreferenceLeaf *)leafWithLabel:(NSString *)label pane:(int)pane;

@end

@implementation PreferenceLeaf

+ (PreferenceLeaf *)leafWithLabel:(NSString *)aLabel pane:(int)aPane {
    PreferenceLeaf *leaf = [[PreferenceLeaf alloc] init];
    if ( leaf != nil ) {
        leaf->label = [aLabel retain];
        leaf->pane = aPane;
    }
    return [leaf autorelease];
}

- (void) dealloc {
    [label release];
    [super dealloc];
}

@end

#pragma mark -

@interface SoundEvent : NSObject
{
@public
    NSString *name;
    NSNumber *sound;
    #if ENABLE_GROWL
    NSNumber *growl;
    #endif
    NSNumber *notification;
    NSNumber *show;
    NSNumber *bounce;
}

- (id)initWithSoundEvent:(int)event sounds:(NSArray *)sounds;
+ (SoundEvent *) soundEventWithEvent:(int)event sounds:(NSArray *)sounds;

@end

@implementation SoundEvent

- (id)initWithSoundEvent:(int)event sounds:(NSArray *)sounds {
    self = [super init];
    if (self != nil) {
        self->name = [[NSString alloc] initWithUTF8String:te[event].name];
        
        NSUInteger soundIndex = 0;
        
        if (sound_files && sound_files[event])
        {
            soundIndex = [sounds indexOfObject:[NSURL fileURLWithPath:@(sound_files[event])]];
        }
        
        struct XATextEventItem *info = &XATextEvents[event];
        
        self->sound = [[NSNumber alloc] initWithInteger:soundIndex];
        #if ENABLE_GROWL
        self->growl = [[NSNumber alloc] initWithInteger:info->growl];
        #endif
        self->notification = [[NSNumber alloc] initWithInteger:info->notification];
        self->show  = [[NSNumber alloc] initWithInteger:info->show];
        self->bounce= [[NSNumber alloc] initWithInteger:info->bounce];
    }
    return self;
}

- (void) dealloc
{
    [name release];
    [sound release];
    #if ENABLE_GROWL
    [growl release];
    #endif
    [notification release];
    [bounce release];
    [show release];
    [super dealloc];
}

+ (SoundEvent *)soundEventWithEvent:(int)event sounds:(NSArray *)sounds
{
    return [[[self alloc] initWithSoundEvent:event sounds:sounds] autorelease];
}

@end

#pragma mark -

@interface SoundButtonCell : NSButtonCell

@end

@implementation SoundButtonCell

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    cellFrame.origin.x += (cellFrame.size.width - [self cellSize].width) / 2;
    [super drawWithFrame:cellFrame inView:controlView];
}

@end

#pragma mark -

@interface PreferencesWindow (Private)

- (void)populate;
- (void)populateColorsFromPalette:(ColorPalette *)palette;
- (void)fillColorWellsFromTag;
- (void)loadSounds;
- (void)makeSoundMenu;
- (void)getSoundEvents;

@end

@implementation PreferencesWindow

- (void)PreferencesWindowInit {
    sounds = [[NSMutableArray alloc] init];
    soundEvents = [[NSMutableArray alloc] init];
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    [self PreferencesWindowInit];
    return self;
}

- (id) initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    [self PreferencesWindowInit];
    return self;
}

- (void) dealloc
{
    [sounds release];
    [soundEvents release];
    [categories release];
    [super dealloc];
}

- (void) awakeFromNib
{
    struct PreferenceItem items [] =
    {
        // Text box
        { textBoxFontTextField, &prefs.hex_text_font_main, MYPREF_STRING },
        { lineHeightTextField, &prefs.xa_line_height, MYPREF_INT },
        { backgroundImageTextField, &prefs.hex_text_background, MYPREF_STRING },
        { maxLinesTextField, &prefs.hex_text_max_lines, MYPREF_INT },
        { scrollbackStripColorCheckBox, &prefs.hex_text_stripcolor_replay, MYPREF_INT },
        { coloredNicksCheckBox, &prefs.hex_text_color_nicks, MYPREF_INT },
        { indentNicksCheckBox, &prefs.hex_text_indent, MYPREF_INT },
        { showSeparatorCheckBox, &prefs.hex_text_show_sep, MYPREF_INT },
        { stripMircColorCheckBox, &prefs.hex_text_stripcolor_msg, MYPREF_INT },
        { transparentCheckBox, &prefs.hex_text_transparent, MYPREF_INT },
        { transparentSlider, &prefs.hex_gui_transparency, MYPREF_INT },
        { timeStampCheckBox, &prefs.hex_stamp_text, MYPREF_INT },
        { timeStampFormatTextField, &prefs.hex_stamp_text_format, MYPREF_STRING },
        // Input box
        { inputBoxUseTextBoxFontCheckBox, &prefs.hex_gui_input_style, MYPREF_INT },
        { userlistUseTextBoxFontCheckBox, &prefs.hex_gui_ulist_style, MYPREF_INT },
        { spellCheckingCheckBox, &prefs.hex_gui_input_spell, MYPREF_INT },
        { grammerCheckingCheckBox, &prefs.xa_input_grammar, MYPREF_INT },
        { autocorrectionCheckBox, &prefs.xa_input_autocorrect, MYPREF_INT },
        { interpretPercentAsciiCheckBox, &prefs.hex_input_perc_ascii, MYPREF_INT },
        { interpretPercentColorCheckBox, &prefs.hex_input_perc_color, MYPREF_INT },
        { tabCompletionCheckBox, &prefs.xa_tab_completion, MYPREF_INT },
        { suffixCompletionCheckBox, &prefs.hex_completion_auto, MYPREF_INT },
        { suffixCompletionTextField, &prefs.hex_completion_suffix, MYPREF_STRING },
        { nickCompletionSortPopUp, &prefs.hex_completion_sort, MYPREF_MENU },
        { scrollingCompletionCheckBox, &prefs.xa_scrolling_completion, MYPREF_INT },
        // User list
        { hideUserlistCheckBox, &prefs.hex_gui_ulist_hide, MYPREF_INT },
        { showUserlistButtonsCheckBox, &prefs.hex_gui_ulist_buttons, MYPREF_INT },
        { showHostnameCheckBox, &prefs.hex_gui_ulist_show_hosts, MYPREF_INT },
        { userlistSortPopUp, &prefs.hex_gui_ulist_sort, MYPREF_MENU },
        { awayTrackCheckBox, &prefs.hex_away_track, MYPREF_INT },
        { awayMaxSizeTextField, &prefs.hex_away_size_max, MYPREF_INT },
        { doubleClickCommandTextField, &prefs.hex_gui_ulist_doubleclick, MYPREF_STRING },
        // Channel switcher
        { useServerTabCheckBox, &prefs.hex_gui_tab_server, MYPREF_INT },
        { useNoticesTabCheckBox, &prefs.hex_gui_tab_server, MYPREF_INT },
        { autoDialogCheckBox, &prefs.hex_gui_autoopen_dialog, MYPREF_INT },
        { newTabsToFrontCheckBox, &prefs.hex_gui_tab_newtofront, MYPREF_INT },
        { hideTabCloseButtonsCheckBox, &prefs.xa_hide_tab_close_buttons, MYPREF_INT },
        { smallerTextTabCheckBox, &prefs.hex_gui_tab_small, MYPREF_INT },
        { tabPositionPopUp, &prefs.hex_gui_tab_pos, MYPREF_MENU },
        { shortenTabLabelLengthTextField, &prefs.hex_gui_tab_trunc, MYPREF_INT },
        { openChannelsInPopUp, &prefs.hex_gui_tab_chans, MYPREF_MENU },
        { openDialogsInPopUp, &prefs.hex_gui_tab_dialogs, MYPREF_MENU },
        { openUtilitiesInPopUp, &prefs.hex_gui_tab_utils, MYPREF_MENU },
        // Other
        { showChannelModeButtonsCheckBox, &prefs.hex_gui_ulist_hide, MYPREF_INT },
        { defaultCharsetTextField, &prefs.xa_default_charset, MYPREF_STRING },
        { urlLinkCommandTextField, &prefs.xa_urlcommand, MYPREF_STRING },
        { nickLinkCommandTextField, &prefs.xa_nickcommand, MYPREF_STRING },
        { channelLinkCommandTextField, &prefs.xa_channelcommand, MYPREF_STRING },
        // Colors
        // Alerts
        { beepOnChannelCheckBox, &prefs.xa_input_beep_chans, MYPREF_INT },
        { beepOnPrivateCheckBox, &prefs.xa_input_beep_priv, MYPREF_INT },
        { beepOnHighlightedCheckBox, &prefs.xa_input_beep_hilight, MYPREF_INT },
        { extraHighlightWordsTextField, &prefs.hex_irc_extra_hilight, MYPREF_STRING },
        { noHighlightWordsTextField, &prefs.hex_irc_no_hilight, MYPREF_STRING },
        { nickHighlightWordsTextField, &prefs.hex_irc_nick_hilight, MYPREF_STRING },
        // Generals
        { quitMessageTextField, &prefs.hex_irc_quit_reason, MYPREF_STRING },
        { partMessageTextField, &prefs.hex_irc_part_reason, MYPREF_STRING },
        { awayMessageTextField, &prefs.hex_away_reason, MYPREF_STRING },
        { sleepMessageTextField, &prefs.xa_sleepmessage, MYPREF_STRING },
        { showAwayMessageCheckBox, &prefs.hex_away_track, MYPREF_INT },
        { autoUnmarkAwayCheckBox, &prefs.hex_away_auto_unmark, MYPREF_INT },
        { showAwayOnceCheckBox, &prefs.hex_away_show_once, MYPREF_INT },
        { partOnSleepCheckBox, &prefs.xa_partonsleep, MYPREF_INT },
        { autoAwayCheckBox, &prefs.xa_auto_away, MYPREF_INT },
        { autoAwayMinutesTextField, &prefs.xa_auto_away_delay, MYPREF_INT },
        { autoRejoinCheckBox, &prefs.hex_irc_auto_rejoin, MYPREF_INT },
        { whoisOnNotifyCheckBox, &prefs.hex_notify_whois_online, MYPREF_INT },
        { rawModesCheckBox, &prefs.hex_irc_raw_modes, MYPREF_INT },
        { hideJoinPartCheckBox, &prefs.hex_irc_conf_mode, MYPREF_INT },
        // Loggings
        { displayPreviousScrollbackCheckBox, &prefs.hex_text_replay, MYPREF_INT },
        { enableLoggingCheckBox, &prefs.hex_irc_logging, MYPREF_INT },
        { logFilenameMaskTextField, &prefs.hex_irc_logmask, MYPREF_STRING },
        { timestampsInLogsCheckBox, &prefs.hex_stamp_log, MYPREF_INT },
        { timestampInLogsFormatTextField, &prefs.hex_stamp_log_format, MYPREF_STRING },
        // Sound
        { bounceCountinuouslyCheckBox, &prefs.xa_bounce_continuously, MYPREF_INT },
        // Network setup
        { bindAddressTextField, &prefs.hex_net_bind_host, MYPREF_STRING },
        { proxyPortTextField, &prefs.hex_net_proxy_port, MYPREF_INT },
        { proxyHostTextField, &prefs.hex_net_proxy_host, MYPREF_STRING },
        { proxyTypePopUp, &prefs.hex_net_proxy_type, MYPREF_MENU },
        { proxyUsePopup, &prefs.hex_net_proxy_use, MYPREF_MENU },
        { proxyAuthenicationCheckBox, &prefs.hex_net_proxy_auth, MYPREF_INT },
        { proxyUsernameTextField, &prefs.hex_net_proxy_user, MYPREF_STRING },
        { proxyUsernameTextField, &prefs.hex_net_proxy_pass, MYPREF_STRING },
        { autoReconnectDelayTextField, &prefs.hex_net_reconnect_delay, MYPREF_INT },
        { autoReconnectCheckBox, &prefs.hex_net_auto_reconnect, MYPREF_INT },
        { neverGiveUpReconnectionCheckBox, &prefs.hex_net_auto_reconnectonfail, MYPREF_INT },
        { identdCheckBox, &prefs.hex_identd, MYPREF_INT },
        // File transfers
        { autoAcceptDccPopUp, &prefs.hex_dcc_auto_recv, MYPREF_MENU },
        { downloadsDirectoryTextField, &prefs.hex_dcc_dir, MYPREF_STRING },
        { completedDownloadsDirectoryTextField, &prefs.hex_dcc_completed_dir, MYPREF_STRING },
        { downloadWithNickCheckBox, &prefs.hex_dcc_save_nick, MYPREF_INT },
        { downloadSpaceToUnderscoreCheckBox, &prefs.hex_dcc_send_fillspaces, MYPREF_INT },
        { ipFromServerCheckBox, &prefs.hex_dcc_ip_from_server, MYPREF_INT },
        { dccAddressTextField, &prefs.dcc_ip, MYPREF_STRING },
        { dccFirstSendPortTextField, &prefs.hex_dcc_port_first, MYPREF_INT },
        { dccLastSendPortTextField, &prefs.hex_dcc_port_last, MYPREF_INT },
        { autoAcceptDccChatPopUp, &prefs.hex_dcc_auto_chat, MYPREF_MENU },
        { autoOpenDccChatCheckBox, &prefs.hex_gui_autoopen_chat, MYPREF_INT },
        { autoOpenDccReceiveCheckBox, &prefs.hex_gui_autoopen_recv, MYPREF_INT },
        { autoOpenDccSendCheckBox, &prefs.hex_gui_autoopen_send, MYPREF_INT },
    };
    
    // I was using #assert totally wrong.. this is the next best thing
    // to get a compile time error if the array sizes are different.
    // Credit where credit is due:
    //    http://www.jaggersoft.com/pubs/CVu11_3.html
    switch (0) { case 0: case (sizeof (items) == sizeof (preferenceItems)):; };
    
    for (NSUInteger i = 0; i < sizeof (items) / sizeof (items[0]); i++ )
    {
        preferenceItems [i] = items [i];
    }
    
    NSArray *interface= @[NSLocalizedStringFromTable(@"Interface", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Text box", @"xchat", @"") pane:0],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Input box", @"xchat", @"") pane:1],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"User list", @"xchat", @"") pane:2],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Channel switcher", @"xchat", @"") pane:3],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Other", @"xchataqua", @"") pane:4],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Colors", @"xchat", @"") pane:5]];
    NSArray *chatting = @[NSLocalizedStringFromTable(@"Chatting", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Alerts", @"xchat", @"") pane:6],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"General", @"xchat", @"") pane:7],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Logging", @"xchat", @"") pane:8],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Events/Sounds", @"xchataqua", @"") pane:9],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Advanced", @"xchat", @"") pane:10]];
    NSArray  *network = @[NSLocalizedStringFromTable(@"Network", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Network setup", @"xchat", @"") pane:11],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"File transfers", @"xchat", @"") pane:12]];
    categories = [[NSArray alloc] initWithObjects:interface, chatting, network, nil];
    
    [categoryOutlineView reloadData];
    
    [categoryOutlineView setIndentationPerLevel:15];
    
    [categoryOutlineView expandItem:categories[0] expandChildren:YES];
    [categoryOutlineView expandItem:categories[1] expandChildren:YES];
    [categoryOutlineView expandItem:categories[2] expandChildren:YES];
    
    [self fillColorWellsFromTag];
    [self loadSounds];
    [self makeSoundMenu];
    [self getSoundEvents];
    
    NSButtonCell *bcell = [[SoundButtonCell alloc] initTextCell:@""];
    [bcell setButtonType:NSSwitchButton];
    [bcell setControlSize:NSMiniControlSize];
    [bcell setAllowsMixedState:YES];
    #if ENABLE_GROWL
    [[soundsTableView tableColumns][2] setDataCell:bcell];
    #endif
    [[soundsTableView tableColumns][4] setDataCell:bcell];
    [bcell release];
    
    bcell = [[SoundButtonCell alloc] initTextCell:@""];
    [bcell setButtonType:NSSwitchButton];
    [bcell setControlSize:NSMiniControlSize];
    [bcell setAllowsMixedState:YES];
    if (NSClassFromString(@"NSUserNotificationCenter") == nil) {
        [bcell setEnabled:NO];
    }
    [[soundsTableView tableColumns][3] setDataCell:bcell];
    [bcell release];
    
    bcell = [[SoundButtonCell alloc] initTextCell:@""];
    [bcell setButtonType:NSSwitchButton];
    [bcell setControlSize:NSMiniControlSize];
    [[soundsTableView tableColumns][5] setDataCell:bcell];
    [bcell release];
    
    [self center];
    
    [[NSFontManager sharedFontManager] setDelegate:self];
    
    [self populate];
}

- (void) changeFont:(id) fontManager
{
    NSFont *font = [fontManager convertFont:[[AquaChat sharedAquaChat] font]];
    sprintf (prefs.hex_text_font_main, "%s %.1f", [[font fontName] UTF8String], [font pointSize]);
    [textBoxFontTextField setStringValue:@(prefs.hex_text_font_main)];
}

#pragma mark IBActions

- (void) applyTranparency:(id)sender
{
    [TabOrWindowView setTransparency:[transparentCheckBox intValue] ? [transparentSlider intValue] : 255];
}

- (void) showRawPreferences:(id)sender
{
    NSString *s = @((const char *)get_xdir_fs());
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:s]];
}

- (void) applyPreferences:(id)sender
{
    NSUInteger numberOfItems = sizeof (preferenceItems) / sizeof (preferenceItems [0]);
    
    for (int i = 0; i < numberOfItems; i ++)
    {
        switch (preferenceItems[i].type)
        {
            case MYPREF_INT:
                * (int *) preferenceItems [i].pref = [preferenceItems [i].item intValue];
                break;
                
            case MYPREF_STRING:
            {
                NSString *s = [preferenceItems [i].item stringValue];    
                strcpy ((char *) preferenceItems [i].pref, [s UTF8String]);
                break;
            }
                
            case MYPREF_MENU:
                * (int *) preferenceItems [i].pref = (int)[preferenceItems [i].item indexOfSelectedItem];
                break;
        }
    }
    
    prefs.hex_gui_tab_layout = (int)[switcherTypePopUp indexOfSelectedItem] * 2; // 1 is reserved
    
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
    for (NSUInteger i = 0; i < [palette numberOfColors]; i++) {
        [palette setColor:i color:[colorWells[i] color]];
    }
    [[AquaChat sharedAquaChat] applyPreferences:sender];
}

- (void) performOK:(id)sender
{
    [self applyPreferences:sender];
    [self close];
}

- (void) performCancel:(id)sender
{
    [TabOrWindowView setTransparency:prefs.hex_text_transparent ? prefs.hex_gui_transparency : 255];
    [self close];
}

- (void) applyFont:(id)sender
{
    [self makeFirstResponder:self];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager orderFrontFontPanel:self];
}

- (void) applyBackgroundImage:(id)sender {
    [self makeFirstResponder:self];
    NSOpenPanel *panel = [NSOpenPanel commonOpenPanel];
    [panel beginSheetModalForWindow:self completionHandler:^(NSInteger result) {
        [backgroundImageTextField setStringValue:panel.URL.path];
    }];
}

- (void) removeBackgroundImage:(id)sender
{
    [backgroundImageTextField setStringValue:@""];
}

- (void)loadColorFromDefault:(id)sender {
    ColorPalette *palette = [[ColorPalette alloc] init];
    [palette loadDefaults];
    [self populateColorsFromPalette:palette];
    [palette release];
}

- (void)loadColorFromFile:(id)sender {
    [self makeFirstResponder:self];
    NSOpenPanel *panel = [NSOpenPanel commonOpenPanel];
    panel.delegate = self;
    panel.directoryURL = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"theme"];
    
    [panel beginSheetModalForWindow:self completionHandler:^(NSInteger result){
        if (result == NSModalResponseOK) {
            ColorPalette *palette = [[ColorPalette alloc] init];
            [palette loadFromURL:panel.URL];
            [self populateColorsFromPalette:palette];
            [palette release];
        }
    }];
}

#pragma mark NSOpenPanel delegate

- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
    NSString *path = url.absoluteString;
    return [path hasSuffix:@"/"] || [path hasSuffix:@"colors.conf"];
}

#pragma mark NSOutlineView delegate

- (BOOL) outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return [item isKindOfClass:[PreferenceLeaf class]];
}

- (void) outlineViewSelectionDidChange:(NSNotification *) notification
{
    NSInteger row = [categoryOutlineView selectedRow];
    PreferenceLeaf *leaf = [categoryOutlineView itemAtRow:row];
    
    if ([leaf isKindOfClass:[PreferenceLeaf class]])
    {
        [contentBox setTitle:leaf->label];
        [tabView selectTabViewItemAtIndex:leaf->pane];
    }
}

#pragma mark NSOutlineView dataSource

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if ( item == nil )
        return categories[index];
    return item[index + 1];
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return item == nil || [item isKindOfClass:[NSArray class]];
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if ( item == nil )
        return [categories count];
    return [item count] - 1;
}

- (id) outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    return [item isKindOfClass:[NSArray class]] ? item[0] : ((PreferenceLeaf *)item)->label;
}

#pragma mark -
#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return [soundEvents count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SoundEvent *item = soundEvents[row];
    
    switch ([[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn])
    {
        case 0: return item->name;
        case 1: return item->sound;
        #if ENABLE_GROWL
        case 2: return item->growl;
        #else
        case 2: return 0;
        #endif
        case 3: return item->notification;
        case 4: return item->bounce;
        case 5: return item->show;
    }
    dassert(NO);
    return @"";
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SoundEvent *item = soundEvents[row];
    
    switch ([[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn])
    {
        case 1:
        {
            [item->sound release];
            item->sound = [object retain];
            
            if (sound_files [row])
            {
                free (sound_files [row]);
                sound_files [row] = NULL;
            }
            
            NSInteger num = [object integerValue];
            if (num > 0)
            {
                NSURL *soundURL = sounds[num];
                sound_files[row] = strdup(soundURL.path.UTF8String);
                [[AquaChat sharedAquaChat] playWaveNamed:sound_files [row]];
            } else {
                sound_files[row] = 0;
            }
            
            break;
        }
        #if ENABLE_GROWL
        case 2:
            [item->growl release];
            item->growl = [object retain];
            XATextEvents[row].growl = [item->growl intValue];
            break;
        #else
        case 2:
            break;
        #endif
        case 3:
            [item->notification release];
            item->notification = [object retain];
            XATextEvents[row].notification = [item->notification intValue];
            break;
            
        case 4:
            [item->bounce release];
            item->bounce = [object retain];
            XATextEvents[row].bounce = [item->bounce intValue];
            break;
            
        case 5:
            [item->show release];
            item->show = [object retain];
            XATextEvents[row].show = [item->show intValue];
            break;
    }
}

@end

@implementation PreferencesWindow (Private)

- (void) populate
{
    NSUInteger numberOfItems = sizeof (preferenceItems) / sizeof (preferenceItems [0]);
    
    for (NSUInteger i = 0; i < numberOfItems; i++)
    {
        switch (preferenceItems[i].type)
        {
            case MYPREF_INT:
                [preferenceItems[i].item setIntValue: * (int *) preferenceItems [i].pref];
                break;
                
            case MYPREF_STRING:
            {
                const char *v = (const char *) preferenceItems[i].pref;
                if (!v) v = "";
                NSString *tmp = @(v);
                [preferenceItems[i].item setStringValue:tmp];    
                break;
            }
                
            case MYPREF_MENU:
                [preferenceItems [i].item selectItemAtIndex: * (int *) preferenceItems [i].pref];
                break;
        }
    }
    
    [switcherTypePopUp selectItemAtIndex:prefs.hex_gui_tab_layout/2];
    
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
    
    if ([palette numberOfColors] != (sizeof(colorWells)/sizeof(colorWells[0])))
        NSLog(@"COLOR MAP OUT OF SYNC\n");
    
    [self populateColorsFromPalette:palette];
}

- (void)populateColorsFromPalette:(ColorPalette *)palette {
    for (NSUInteger i = 0; i < [palette numberOfColors]; i ++) {
        [colorWells[i] setColor:[palette getColor:i]];
    }
}

- (void)fillColorWellsFromTag
{    
    NSView *colorsView = [colorsTabViewItem view];
    
    for (NSView *view in [colorsView subviews]) {
        if (![view isKindOfClass:[NSColorWell class]]) continue;
        NSInteger colorIndex = [view tag];
        colorWells[colorIndex] = (NSColorWell *)view;
    }
}

//
// Find system sound files and stash the list in an ivar (sounds)
//
- (void) loadSounds {
    // Clean out any (possibly stale) sounds
    [sounds removeAllObjects];

    // Add a "<none>" selection (default) to the top of the menu
    [sounds addObject:NSLocalizedStringFromTable(@"<none>", @"xchat", @"")];

    // Ask XAFileUtil to find all named system sounds...
    NSArray *systemSounds = [XAFileUtil findSystemSounds];

    // ...and add them to the popup
    [sounds addObjectsFromArray:systemSounds];
}

//
// Populate the sounds popup menu for the "Event/Sounds" preferences
//
- (void) makeSoundMenu {
    // Allocate a NSPopUpButtonCell and configure it
    NSPopUpButtonCell *cell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [cell setBordered:NO];

    // Add all the previously found system sounds as menu items
    for (NSURL *sound in sounds) {
        [cell addItemWithTitle:[sound lastPathComponent]];
    }

    // Add it to the soundsTableView
    [[soundsTableView tableColumns][1] setDataCell:cell];

    [cell release]; // Retained by the tableview, so release it here
}

- (void) getSoundEvents
{
    [soundEvents removeAllObjects];
    
    for (int i = 0; i < NUM_XP; i ++)
    {
        [soundEvents addObject:[SoundEvent soundEventWithEvent:i sounds:sounds]];
    }
    
    [soundsTableView reloadData];
}

@end

