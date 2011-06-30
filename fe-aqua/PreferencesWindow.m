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

#import "AquaChat.h"
#import "PreferencesWindow.h"
#import "ColorPalette.h"
#import "ChatWindow.h"

#include "../common/text.h"
#include "../common/xchatc.h"
#undef TYPE_BOOL
#include "../common/cfgfiles.h"

extern char *sound_files[];
extern struct text_event te[];
extern struct eventInfo textEventInfo[];

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
    NSNumber *growl;
    NSNumber *show;
    NSNumber *bounce;
}

+ (SoundEvent *) soundEventWithEvent:(int)event sounds:(NSArray *)sounds;

@end

@implementation SoundEvent

+ (SoundEvent *) soundEventWithEvent:(int)event sounds:(NSArray *)sounds
{
    SoundEvent *soundEvent = [[self alloc] init];
    if (soundEvent != nil) {
        soundEvent->name = [[NSString alloc] initWithUTF8String:te[event].name];
        
        int soundIndex = 0;
        
        if (sound_files && sound_files[event])
        {
            soundIndex = [sounds indexOfObject:[NSString stringWithUTF8String:sound_files[event]]];
        }
        
        struct eventInfo *info = &textEventInfo[event];
        
        soundEvent->sound = [[NSNumber alloc] initWithInteger:soundIndex];
        soundEvent->growl = [[NSNumber alloc] initWithInt:info->growl];
        soundEvent->show  = [[NSNumber alloc] initWithInt:info->show];
        soundEvent->bounce= [[NSNumber alloc] initWithInt:info->bounce];
    }
    return [soundEvent autorelease];
}

- (void) dealloc
{
    [name release];
    [sound release];
    [growl release];
    [bounce release];
    [show release];
    [super dealloc];
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
- (void)fillColorWellsFromTag;
- (void)loadSounds;
- (void)makeSoundMenu;
- (void)getSoundEvents;

@end

@implementation PreferencesWindow

- (id) initAsPreferencesWindow {
    sounds = [[NSMutableArray alloc] init];
    soundEvents = [[NSMutableArray alloc] init];
    return self;
}

- (id) initAsPreferencesWindow:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    return [self initAsPreferencesWindow];
}

- (id) initAsPreferencesWindow:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag {
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    return [self initAsPreferencesWindow];
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
    struct preferenceItem items [] = 
    {
        // Text box
        { textBoxFontTextField, &prefs.font_normal, MYPREF_STRING },
        { maxLinesTextField, &prefs.max_lines, MYPREF_INT },
        { coloredNicksCheckBox, &prefs.colorednicks, MYPREF_INT },
        { indentNicksCheckBox, &prefs.indent_nicks, MYPREF_INT },
        { showSeparatorCheckBox, &prefs.show_separator, MYPREF_INT },
        { stripMircColorCheckBox, &prefs.stripcolor, MYPREF_INT },
        { transparentCheckBox, &prefs.transparent, MYPREF_INT },
        { transparentSlider, &prefs.tint_red, MYPREF_INT },
        { timeStampCheckBox, &prefs.timestamp, MYPREF_INT },
        { timeStampFormatTextField, &prefs.stamp_format, MYPREF_STRING },
        { urlLinkCommandTextField, &prefs.xa_urlcommand, MYPREF_STRING },
        { nickLinkCommandTextField, &prefs.xa_nickcommand, MYPREF_STRING },
        { channelLinkCommandTextField, &prefs.xa_channelcommand, MYPREF_STRING },
        // Input box
        { inputBoxUseTextBoxFontCheckBox, &prefs.style_inputbox, MYPREF_INT },
        { spellCheckingCheckBox, &prefs.gui_input_spell, MYPREF_INT },
        { interpretPercentAsciiCheckBox, &prefs.perc_ascii, MYPREF_INT },
        { interpretPercentColorCheckBox, &prefs.perc_color, MYPREF_INT },
        { tabCompletionCheckBox, &prefs.xa_tab_completion, MYPREF_INT },
        { suffixCompletionCheckBox, &prefs.nickcompletion, MYPREF_INT },
        { suffixCompletionTextField, &prefs.nick_suffix, MYPREF_STRING },
        { nickCompletionSortPopUp, &prefs.completion_sort, MYPREF_MENU },
        { scrollingCompletionCheckBox, &prefs.xa_scrolling_completion, MYPREF_INT },
        // User list
        { hideUserlistCheckBox, &prefs.hideuserlist, MYPREF_INT },
        { showUserlistButtonsCheckBox, &prefs.userlistbuttons, MYPREF_INT },
        { showHostnameCheckBox, &prefs.showhostname_in_userlist, MYPREF_INT },
        { userlistSortPopUp, &prefs.userlist_sort, MYPREF_MENU },
        { awayTrackCheckBox, &prefs.away_track, MYPREF_INT },
        { awayMaxSizeTextField, &prefs.away_size_max, MYPREF_INT },
        { doubleClickCommandTextField, &prefs.doubleclickuser, MYPREF_STRING },
        // Channel switcher
        { useServerTabCheckBox, &prefs.use_server_tab, MYPREF_INT },
        { useNoticesTabCheckBox, &prefs.notices_tabs, MYPREF_INT },
        { autoDialogCheckBox, &prefs.autodialog, MYPREF_INT },
        { newTabsToFrontCheckBox, &prefs.newtabstofront, MYPREF_INT },
        { hideTabCloseButtonsCheckBox, &prefs.xa_hide_tab_close_buttons, MYPREF_INT },
        { tabPositionPopUp, &prefs._tabs_position, MYPREF_MENU },
        { shortenTabLabelLengthTextField, &prefs.truncchans, MYPREF_INT },
        { openChannelsInPopUp, &prefs.tabchannels, MYPREF_MENU },
        { openDialogsInPopUp, &prefs.privmsgtab, MYPREF_MENU },
        { openUtilitiesInPopUp, &prefs.windows_as_tabs, MYPREF_MENU },
        // Other
        { showChannelModeButtonsCheckBox, &prefs.chanmodebuttons, MYPREF_INT },
        { defaultCharsetTextField, &prefs.xa_default_charset, MYPREF_STRING },
        // Colors
        // Alerts
        { beepOnChannelCheckBox, &prefs.input_beep_chans, MYPREF_INT },
        { beepOnPrivateCheckBox, &prefs.input_beep_priv, MYPREF_INT },
        { beepOnHighlightedCheckBox, &prefs.input_beep_hilight, MYPREF_INT },
        { extraHighlightWordsTextField, &prefs.irc_extra_hilight, MYPREF_STRING },
        { noHighlightWordsTextField, &prefs.irc_no_hilight, MYPREF_STRING },
        { nickHighlightWordsTextField, &prefs.irc_nick_hilight, MYPREF_STRING },
        // Generals
        { quitMessageTextField, &prefs.quitreason, MYPREF_STRING },
        { partMessageTextField, &prefs.partreason, MYPREF_STRING },
        { awayMessageTextField, &prefs.awayreason, MYPREF_STRING },
        { sleepMessageTextField, &prefs.xa_sleepmessage, MYPREF_STRING },
        { showAwayMessageCheckBox, &prefs.show_away_message, MYPREF_INT },
        { autoUnmarkAwayCheckBox, &prefs.auto_unmark_away, MYPREF_INT },
        { showAwayOnceCheckBox, &prefs.show_away_once, MYPREF_INT },
        { partOnSleepCheckBox, &prefs.xa_partonsleep, MYPREF_INT },
        { autoAwayCheckBox, &prefs.xa_auto_away, MYPREF_INT },
        { autoAwayMinutesTextField, &prefs.xa_auto_away_delay, MYPREF_INT },
        { autoRejoinCheckBox, &prefs.autorejoin, MYPREF_INT },
        { whoisOnNotifyCheckBox, &prefs.whois_on_notifyonline, MYPREF_INT },
        { rawModesCheckBox, &prefs.raw_modes, MYPREF_INT },
        { hideJoinPartCheckBox, &prefs.confmode, MYPREF_INT },
        // Loggings
        { displayPreviousScrollbackCheckBox, &prefs.text_replay, MYPREF_INT },
        { enableLoggingCheckBox, &prefs.logging, MYPREF_INT },
        { logFilenameMaskTextField, &prefs.logmask, MYPREF_STRING },
        { timestampsInLogsCheckBox, &prefs.timestamp_logs, MYPREF_INT },
        { timestampInLogsFormatTextField, &prefs.timestamp_log_format, MYPREF_STRING },
        // Sound
        // Network setup
        { bindAddressTextField, &prefs.hostname, MYPREF_STRING },
        { proxyPortTextField, &prefs.proxy_port, MYPREF_INT },
        { proxyHostTextField, &prefs.proxy_host, MYPREF_STRING },
        { proxyTypePopUp, &prefs.proxy_type, MYPREF_MENU },
        { proxyUsePopup, &prefs.proxy_use, MYPREF_MENU },
        { proxyAuthenicationCheckBox, &prefs.proxy_auth, MYPREF_INT },
        { proxyUsernameTextField, &prefs.proxy_user, MYPREF_STRING },
        { proxyUsernameTextField, &prefs.proxy_pass, MYPREF_STRING },
        { autoReconnectDelayTextField, &prefs.recon_delay, MYPREF_INT },
        { autoReconnectCheckBox, &prefs.autoreconnect, MYPREF_INT },
        { neverGiveUpReconnectionCheckBox, &prefs.autoreconnectonfail, MYPREF_INT },
        { identdCheckBox, &prefs.identd, MYPREF_INT },
        { checkNewVersionCheckBox, &prefs.xa_checkvers, MYPREF_INT },
        // File transfers
        { autoAcceptDccPopUp, &prefs.autodccsend, MYPREF_MENU },
        { downloadsDirectoryTextField, &prefs.dccdir, MYPREF_STRING },
        { completedDownloadsDirectoryTextField, &prefs.dcc_completed_dir, MYPREF_STRING },
        { downloadWithNickCheckBox, &prefs.dccwithnick, MYPREF_INT },
        { downloadSpaceToUnderscoreCheckBox, &prefs.dcc_send_fillspaces, MYPREF_INT },
        { ipFromServerCheckBox, &prefs.ip_from_server, MYPREF_INT },
        { dccAddressTextField, &prefs.dcc_ip_str, MYPREF_STRING },
        { dccFirstSendPortTextField, &prefs.first_dcc_send_port, MYPREF_INT },
        { dccLastSendPortTextField, &prefs.last_dcc_send_port, MYPREF_INT },
        { autoAcceptDccChatPopUp, &prefs.autodccchat, MYPREF_MENU },
        { autoOpenDccChatCheckBox, &prefs.autoopendccchatwindow, MYPREF_INT },
        { autoOpenDccReceiveCheckBox, &prefs.autoopendccrecvwindow, MYPREF_INT },
        { autoOpenDccSendCheckBox, &prefs.autoopendccsendwindow, MYPREF_INT },
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
    
    NSArray *interface= [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Interface", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Text box", @"xchat", @"") pane:0],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Input box", @"xchat", @"") pane:1],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"User list", @"xchat", @"") pane:2],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Channel switcher", @"xchat", @"") pane:3],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Other", @"xchataqua", @"") pane:4],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Colors", @"xchat", @"") pane:5],
                         nil];
    NSArray *chatting = [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Chatting", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Alerts", @"xchat", @"") pane:6],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"General", @"xchat", @"") pane:7],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Logging", @"xchat", @"") pane:8],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Events/Sounds", @"xchataqua", @"") pane:9],
                         nil];
    NSArray  *network = [NSArray arrayWithObjects:NSLocalizedStringFromTable(@"Network", @"xchat", @""),
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"Network setup", @"xchat", @"") pane:10],
                         [PreferenceLeaf leafWithLabel:NSLocalizedStringFromTable(@"File transfers", @"xchat", @"") pane:11],
                         nil];
    categories = [[NSArray alloc] initWithObjects:interface, chatting, network, nil];
    
    [categoryOutlineView reloadData];
    
    [categoryOutlineView setIndentationPerLevel:15];
    
    [categoryOutlineView expandItem:[categories objectAtIndex:0] expandChildren:YES];
    [categoryOutlineView expandItem:[categories objectAtIndex:1] expandChildren:YES];
    [categoryOutlineView expandItem:[categories objectAtIndex:2] expandChildren:YES];
    
    [self fillColorWellsFromTag];
    [self loadSounds];
    [self makeSoundMenu];
    [self getSoundEvents];
    
    NSButtonCell *bcell = [[SoundButtonCell alloc] initTextCell:@""];
    [bcell setButtonType:NSSwitchButton];
    [bcell setControlSize:NSMiniControlSize];
    [bcell setAllowsMixedState:YES];
    [[[soundsTableView tableColumns] objectAtIndex:2] setDataCell:bcell];
    [[[soundsTableView tableColumns] objectAtIndex:3] setDataCell:bcell];
    [bcell release];
    
    bcell = [[SoundButtonCell alloc] initTextCell:@""];
    [bcell setButtonType:NSSwitchButton];
    [bcell setControlSize:NSMiniControlSize];
    [[[soundsTableView tableColumns] objectAtIndex:4] setDataCell:bcell];
    [bcell release];
    
    [self center];
    
    [[NSFontManager sharedFontManager] setDelegate:self];
    
    [self populate];
}

- (void) changeFont:(id) fontManager
{
    NSFont *font = [fontManager convertFont:[[AquaChat sharedAquaChat] font]];
    sprintf (prefs.font_normal, "%s %.1f", [[font fontName] UTF8String], [font pointSize]);
    [textBoxFontTextField setStringValue:[NSString stringWithUTF8String:prefs.font_normal]];
}

#pragma mark IBActions

- (void) applyTranparency:(id)sender
{
    [TabOrWindowView setTransparency:[transparentCheckBox intValue] ? [transparentSlider intValue] : 255];
}

- (void) showRawPreferences:(id)sender
{
    NSString *s = [NSString stringWithFormat:@"file://%s", get_xdir_fs()];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:s]];
}

- (void) applyPreferences:(id)sender
{
    NSUInteger numberOfItems = sizeof (preferenceItems) / sizeof (preferenceItems [0]);
    
    for (NSUInteger i = 0; i < numberOfItems; i ++)
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
                * (int *) preferenceItems [i].pref = [preferenceItems [i].item indexOfSelectedItem];
                break;
        }
    }
    
    prefs.tab_layout = [switcherTypePopUp indexOfSelectedItem]*2; // 1 is reserved
    
    KeyCombo left_combo = [tabLeftRecorderCell keyCombo];
    prefs.tab_left_modifiers = left_combo.flags;
    prefs.tab_left_key = left_combo.code;
    
    KeyCombo right_combo = [tabRightRecorderCell keyCombo];
    prefs.tab_right_modifiers = right_combo.flags;
    prefs.tab_right_key = right_combo.code;
    
    ColorPalette *palette = [[ColorPalette alloc] init];
    for (NSUInteger i = 0; i < [palette numberOfColors]; i++)
        [palette setColor:i color:[colorWells[i] color]];
    [[AquaChat sharedAquaChat] setPalette:palette];
    [palette release];
    
    [[AquaChat sharedAquaChat] preferencesChanged];
}

- (void) performOK:(id)sender
{
    [self applyPreferences:sender];
    [self close];
}

- (void) performCancel:(id)sender
{
    [TabOrWindowView setTransparency:prefs.transparent ? prefs.tint_red : 255];
    [self close];
}

- (void) applyFont:(id)sender
{
    [self makeFirstResponder:self];
    NSFontManager *fontManager = [NSFontManager sharedFontManager];
    [fontManager orderFrontFontPanel:self];
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
        return [categories objectAtIndex:index];
    return [item objectAtIndex:index + 1];
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
    return [item isKindOfClass:[NSArray class]] ? [item objectAtIndex:0] : ((PreferenceLeaf *)item)->label;
}

#pragma mark -
#pragma mark NSTableView dataSource

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    return [soundEvents count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SoundEvent *item = [soundEvents objectAtIndex:row];
    
    switch ([[tableView tableColumns] indexOfObjectIdenticalTo:tableColumn])
    {
        case 0: return item->name;
        case 1: return item->sound;
        case 2: return item->growl;
        case 3: return item->bounce;
        case 4: return item->show;
    }
    SGAssert(NO);
    return @"";
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    SoundEvent *item = [soundEvents objectAtIndex:row];
    
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
            if (num)
            {
                sound_files [row] = strdup ([[sounds objectAtIndex:num] UTF8String]);
                [[AquaChat sharedAquaChat] playWaveNamed:sound_files [row]];
            }
            
            break;
        }
            
        case 2:
            [item->growl release];
            item->growl = [object retain];
            textEventInfo[row].growl = [item->growl intValue];
            break;
            
        case 3:
            [item->bounce release];
            item->bounce = [object retain];
            textEventInfo[row].bounce = [item->bounce intValue];
            break;
            
        case 4:
            [item->show release];
            item->show = [object retain];
            textEventInfo[row].show = [item->show intValue];
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
                NSString *tmp = [NSString stringWithUTF8String:v];
                [preferenceItems[i].item setStringValue:tmp];    
                break;
            }
                
            case MYPREF_MENU:
                [preferenceItems [i].item selectItemAtIndex: * (int *) preferenceItems [i].pref];
                break;
        }
    }
    
    [switcherTypePopUp selectItemAtIndex:prefs.tab_layout/2];
    
    KeyCombo left_combo = { prefs.tab_left_modifiers, prefs.tab_left_key };
    [tabLeftRecorderCell setKeyCombo:left_combo];
    
    KeyCombo right_combo = { prefs.tab_right_modifiers, prefs.tab_right_key };
    [tabRightRecorderCell setKeyCombo:right_combo];
    
    ColorPalette *palette = [[AquaChat sharedAquaChat] palette];
    
    if ([palette numberOfColors] != (sizeof(colorWells)/sizeof(colorWells[0])))
        NSLog(@"COLOR MAP OUT OF SYNC\n");
    
    for (NSUInteger i = 0; i < [palette numberOfColors]; i ++)
        [colorWells[i] setColor:[palette getColor:i]];
}

- (void) fillColorWellsFromTag
{
    // TBD: Magic number here!!!! '5'
    
    NSView *colorsView = [colorsTabViewItem view];
    
    for ( NSView *view in [colorsView subviews] ) {        
        if (![view isKindOfClass:[NSColorWell class]]) continue;
        NSInteger colorIndex = [view tag];
        colorWells[colorIndex] = (NSColorWell *)view;
    }
}

- (void) loadSounds
{    
    [sounds removeAllObjects];
    [sounds addObject:NSLocalizedStringFromTable(@"<none>", @"xchat", @"")];
    
    NSString *directoryName = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:@"/../Sounds"];
    NSFileManager *manager = [NSFileManager defaultManager];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_4
    NSArray *files = [manager contentsOfDirectoryAtPath:directoryName error:NULL];
#else
    NSArray *files = [manager directoryContentsAtPath:directoryName];
#endif
    
    for ( NSString *sound in files ) {
        NSString *fullPath = [directoryName stringByAppendingFormat:@"/%@", sound];
        BOOL isDir;
        if ([manager fileExistsAtPath:fullPath isDirectory:&isDir] && !isDir)
            [sounds addObject:sound];
    }
    
    for ( NSString *sound in [SGSoundUtility systemSounds] ) {
        [sounds addObject:sound];
    }
}

- (void) makeSoundMenu
{
    NSPopUpButtonCell *cell = [[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:NO];
    [cell setBordered:NO];
    for (NSString *sound in sounds)
    {
        NSRange range = [sound rangeOfString:@"/" options:NSBackwardsSearch];
        if (range.location != NSNotFound)
            sound = [sound substringFromIndex:range.location + 1];
        [cell addItemWithTitle:sound];
    }
    [[[soundsTableView tableColumns] objectAtIndex:1] setDataCell:cell];
    [cell release];
}

- (void) getSoundEvents
{
    [soundEvents removeAllObjects];
    
    for (NSUInteger i = 0; i < NUM_XP; i ++)
    {
        [soundEvents addObject:[SoundEvent soundEventWithEvent:i sounds:sounds]];
    }
    
    [soundsTableView reloadData];
}

@end

