//
//  NetworkViewController.m
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 16..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#include "servlist.h"
#include "cfgfiles.h"

#import "AppDelegate.h"
#import "NetworkViewController.h"

@interface OneChannel : NSObject
{
    NSString *name;
    NSString *key;
}
@property(nonatomic,retain) NSString *name, *key;

+ (OneChannel *)channelWithName:(NSString *)name;

@end

@implementation OneChannel
@synthesize name, key;

- (void) dealloc
{
    self.name = nil;
    self.key = nil;
    [super dealloc];
}

+ (OneChannel *) channelWithName:(NSString *)aName {
    OneChannel *channel = [[self alloc] init];
    channel.name = aName;
    return [channel autorelease];
}

@end

@interface ServerItem : NSObject
{
  @public
    struct ircserver *ircServer;
    NSString *name;
    NSString *port;
    BOOL ssl;
}

+ (ServerItem *)serverWithIrcServer:(struct ircserver *)ircServer;
- (void)setServer:(NSString *)newName;
- (void)setPort:(NSString *)newPort;
- (BOOL)setSSL:(NSNumber *)newSSL;

@end

@implementation ServerItem

+ (ServerItem *) serverWithIrcServer:(struct ircserver *)anIrcServer {
    ServerItem *serverItem = [[self alloc] init];
    serverItem->ircServer = anIrcServer;
    
    const char *serverHostname = serverItem->ircServer->hostname;
    const char *slash = strchr(serverHostname, '/');
    
    const char *cPort;
    
    if (slash)
    {
        NSUInteger length = slash - serverHostname;
        serverItem->name = [[NSString alloc] initWithBytes:serverHostname length:length encoding:NSUTF8StringEncoding];
        cPort = slash + 1;
    }
    else
    {
        serverItem->name = [[NSString alloc] initWithUTF8String:serverHostname];
        cPort = "";
    }

    serverItem->ssl = (*cPort == '+');
    if (serverItem->ssl)
    {
        cPort++;
    }
    
    serverItem->port = [[NSString alloc] initWithUTF8String:cPort];
    
    return [serverItem autorelease];
}

- (void) dealloc
{
    [self->name release];
    [self->port release];
    [super dealloc];
}

#pragma mark setters

- (void) setIrcServerHostName
{
    free(ircServer->hostname);
    NSString *hostName = self->name;
    if ( [port length] > 0 )
        hostName = [hostName stringByAppendingFormat:@"/%@%@", ssl ? @"+" : @"", self->port];
    ircServer->hostname = strdup([hostName UTF8String]);
}

- (void) setServer:(NSString *)newName
{
    [self->name release];
    self->name = [newName retain];
    [self setIrcServerHostName];
}

- (void) setPort:(NSString *)newPort
{
    [self->port release];
    self->port = [newPort retain];
    [self setIrcServerHostName];
}

- (BOOL) setSSL:(NSNumber *)newSSL
{
    ssl = [newSSL boolValue];
    BOOL willSetPort = ssl && [port length] == 0;
    if (willSetPort)
        [self setPort:@"6667"];
    [self setIrcServerHostName];
    return willSetPort;
}

@end

@interface NetworkItem : NSObject
{
    NSMutableArray *servers;
    NSMutableArray *favoriteChannels;
    NSMutableArray *connectCommands;
    struct ircnet *ircNet;
}

@property BOOL autoconnect, favorite;
@property(readonly) NSString *name;
@property(readonly) NSArray *servers;
@property(readonly) struct ircnet *ircNet;

+ (NetworkItem *)networkWithIrcnet:(ircnet *)ircNet;
- (void)addServerWithIrcServer:(struct ircserver *)ircServer;
- (void)resetCommands;
- (void)resetFavoriteChannels;

@end

@interface NetworkItem (private)

- (void)parseFavoriteChannels;
- (void)parseCommands;

@end

@implementation NetworkItem
@synthesize name;
@synthesize servers, favoriteChannels, connectCommands;
@synthesize ircNet;

+ (NetworkItem *) networkWithIrcnet:(ircnet *)anIrcNet
{
    NetworkItem *network = [[self alloc] init];
    network->ircNet = anIrcNet;

    network->servers = [[NSMutableArray alloc] init];
    network->favoriteChannels = [[NSMutableArray alloc] init];
    network->connectCommands = [[NSMutableArray alloc] init];
    
    for (GSList *list = network->ircNet->servlist; list; list = list->next)
    {
        [network addServerWithIrcServer:(ircserver *)list->data];
    }
    
    [network parseFavoriteChannels];
    [network parseCommands];
    
    return [network autorelease];
}

- (void) dealloc
{
    [name release];
    [servers release];
    [favoriteChannels release];
    [connectCommands release];
    [super dealloc];
}

- (void) addServerWithIrcServer:(ircserver *)ircServer
{
    [servers addObject:[ServerItem serverWithIrcServer:ircServer]];
}

- (void) resetCommands
{
    free(ircNet->command);
    ircNet->command = strdup([[connectCommands componentsJoinedByString:@"\n"] UTF8String]);
}

- (void) resetFavoriteChannels
{
    free(ircNet->autojoin);
    
    // TODO: should be replaced to autojoin_merge and autojoin_split
    
    NSMutableString *ircNetChannels = [NSMutableString string];
    NSMutableString *ircNetKeys = [NSMutableString string];
    
    // Collect the channels and keys.  Since some channels might not have
    // keys, we need to collec any channels with keys first!  The simplest
    // way to do this is to do it in 2 passes.
    
    // First, the channels with keys
    for ( OneChannel *channel in favoriteChannels )
    {
        NSString *key = [channel key];
        if (key && [key length])
        {
            if ([ircNetChannels length])
            {
                [ircNetChannels appendString:@","];
                [ircNetKeys appendString:@","];
            }
            
            [ircNetChannels appendString:[channel name]];
            [ircNetKeys appendString:key];
        }
    }
    
    // and then the channels without keys
    for ( OneChannel *channel in favoriteChannels )
    {
        NSString *key = [channel key];
        if ( !key || [key length] == 0)
        {
            if ([ircNetChannels length])
                [ircNetChannels appendString:@","];
            
            [ircNetChannels appendString:[channel name]];
        }
    }
    
    if ([ircNetKeys length] > 0)
    {
        [ircNetChannels appendString:@" "];
        [ircNetChannels appendString:ircNetKeys];
    }
    
    ircNet->autojoin = strdup([ircNetChannels UTF8String]);
}

#pragma mark Property Interfaces

- (NSString *) name {
    return @(ircNet->name);
}

- (void) setAutoconnect:(BOOL)flag
{
    if (flag)
        ircNet->flags |= FLAG_AUTO_CONNECT;
    else
        ircNet->flags &= ~FLAG_AUTO_CONNECT;
}

- (BOOL) autoconnect
{
    return (ircNet->flags & FLAG_AUTO_CONNECT) > 0;
}

- (void) setFavorite:(BOOL)flag
{
    if (flag)
        ircNet->flags |= FLAG_FAVORITE;
    else
        ircNet->flags &= ~FLAG_FAVORITE;
}

- (BOOL) favorite
{
    return (ircNet->flags & FLAG_FAVORITE) > 0;
}

@end

@implementation NetworkItem (private)

- (void) parseFavoriteChannels {
    const char *autojoin = ircNet->autojoin;
    if (autojoin == NULL || autojoin[0] == 0)
        return;
    
    // TODO: should be replaced to autojoin_merge and autojoin_split
    
    // autojoin is in the form of the irc join string
    //
    //        <channel>{,<channel>} [<key>{,<key>}]
    NSString *autojoins = @(autojoin);
    NSArray *autojoinParts = [autojoins componentsSeparatedByString:@" \t\n"];
    
    NSString *channelsString = autojoinParts[0];
    NSString *keysString = [autojoinParts count]>1 ? autojoinParts[1] : @"";
    
    for ( NSString *channelName in [channelsString componentsSeparatedByString:@","] ) {
        [favoriteChannels addObject:[OneChannel channelWithName:channelName]];
    }
    
    // Then assign any keys..
    NSArray *keys = [keysString componentsSeparatedByString:@","];
    
    for ( NSUInteger i = 0; i < [keys count]; i++ ) {
        [favoriteChannels[i] setKey:keys[i]];
    }
}

- (void) parseCommands
{
    const char *commandsCString = ircNet->command;
    if ( commandsCString == NULL || commandsCString[0] == 0)
        return;
    
    for ( NSString *command in [@(commandsCString) componentsSeparatedByString:@"\n"] ) {
        [connectCommands addObject:command];
    }
}

@end

@interface NetworkViewController (Private)

@property (nonatomic, readonly) NetworkItem *selectedNetworkItem;

- (void)savePreferences;
- (void)loadFlag:(id)field fromNetwork:(NetworkItem *)network;
- (void)loadField:(id)field fromNetwork:(NetworkItem *)network;
- (void)loadNetwork;
- (void)loadPreferences;
- (void)setFieldWithControl:(UITextField *)control;

@end

@implementation NetworkViewController

- (NSString *) nibName {
    return @"NetworkViewController";
}

- (void) dealloc {
    [charsets release];
    [networks release];
    [super dealloc];
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) != nil) {
        charsets = [[NSArray alloc] initWithObjects:
                    @"UTF-8",
                    @"IRC (Latin/Unicode Hybrid)",
                    @"ISO-8859-15 (Western Europe)",
                    @"ISO-8859-2 (Central Europe)",
                    @"ISO-8859-7 (Greek)",
                    @"ISO-8859-8 (Hebrew)",
                    @"ISO-8859-9 (Turkish)",
                    @"ISO-2022-JP (Japanese)",
                    @"SJIS (Japanese)",
                    @"CP949 (Korean)",
                    @"KOI8-R (Cyrillic)",
                    @"CP1251 (Cyrillic)",
                    @"CP1256 (Arabic)",
                    @"CP1257 (Baltic)",
                    @"GB18030 (Chinese)",
                    @"TIS-620 (Thai)",
                    nil];
    }
    return self;
}

- (void) viewDidLoad {
    self.title = XCHATLSTR(@"Networks");
    self.navigationItem.rightBarButtonItem = networkTableViewController.editButtonItem;
    
    [selectedServerOnlySwitch setTag:~FLAG_CYCLE];
    
    [networkGlobalInformationSwitch setTag:FLAG_USE_GLOBAL];
    [networkNickname1TextField setTag:STRUCT_OFFSET_STR(struct ircnet, nick)];
    [networkNickname2TextField setTag:STRUCT_OFFSET_STR(struct ircnet, nick2)];
    [networkUsernameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, user)];
    [networkRealnameTextField setTag:STRUCT_OFFSET_STR(struct ircnet, real)];
    
    [autoConnectSwitch setTag:FLAG_AUTO_CONNECT];
    [bypassProxySwitch setTag:~FLAG_USE_PROXY];
    [useSslSwitch setTag:FLAG_USE_SSL];
    [acceptInvalidSslSwitch setTag:FLAG_ALLOW_INVALID];
    
    [nickservPasswordTextField setTag:STRUCT_OFFSET_STR(struct ircnet, nickserv)];
    [serverPasswordTextField setTag:STRUCT_OFFSET_STR(struct ircnet, pass)];
    
    [charsetPickerView setTag:STRUCT_OFFSET_STR(struct ircnet, encoding)];
    
    [self loadPreferences];
}

- (void) viewWillAppear:(BOOL)animated {
    [networkTableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self savePreferences];
}

#pragma mark Event Handlers

- (void) showUserInformation {
    [self.navigationController pushViewController:userViewController animated:YES];
}

- (void)setFlagWithSwitch:(UISwitch *)control {
    BOOL value = control.on;
    NSInteger flag = [control tag];
    if ( flag < 0 ) {
        flag = ~flag;
        value = !value;
    }
    guint32 *flags = &[selectedNetworkItem ircNet]->flags;
    if (value)
        *flags |= flag;
    else
        *flags &= ~flag;
}

- (void) toggleUseGlobalInformation:(UISwitch *)sender {
    BOOL enabled = !sender.on;
    [networkNickname1TextField setEnabled:enabled];
    [networkNickname2TextField setEnabled:enabled];
    [networkUsernameTextField  setEnabled:enabled];
    [networkRealnameTextField  setEnabled:enabled];
}

#pragma mark UISearchDisplayController delegate

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller {
    [networks release];
    networks = [allNetworks retain];
}

#pragma mark UISearchBar delegate

- (void) searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [networks release];
    if ( [searchText length] == 0 ) {
        networks = [allNetworks retain];
    } else {
        networks = [[NSMutableArray alloc] init];
        for ( NetworkItem *network in allNetworks ) {
            if ( strcasestr([network ircNet]->name, CSTR(searchText)) )
                [networks addObject:network];
        }
    }
}

#pragma mark UITextField delegate

- (void) textFieldDidEndEditing:(UITextField *)textField {
    [self setFieldWithControl:textField];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [self setFieldWithControl:textField];
    [textField endEditing:YES];
    return YES;
}

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ( section == 0 ) return 1;
    return [networks count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
        NSString *cellIdentifier = @"NEW";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if ( cell == nil ) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.textLabel.textColor = [UIColor grayColor];
        }
        cell.textLabel.text = XCHATLSTR(@"*NEW*");
        return cell;        
    }
    
    NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    }
    cell.textLabel.text = [networks[indexPath.row] name];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section == 0 ) {
        struct ircnet *ircNet = servlist_net_add(_("New Network"), "", false);
        servlist_server_add(ircNet, _("NewServer"));
        [networks addObject:[NetworkItem networkWithIrcnet:ircNet]]; // add to filtered one?
        [networkTableView reloadData];
        [networkTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[networks count]-1 inSection:1] animated:YES scrollPosition:UITableViewScrollPositionBottom];
        return;
    }
    
    [self savePreferences];
    
    NetworkItem *network = networks[indexPath.row];
    
    prefs.slist_select = [allNetworks indexOfObject:network];
    
    if ( !is_session([self session]) )
        self->session = NULL;
    
    [network ircNet]->selected = indexPath.row;
    servlist_connect([self session], [network ircNet], true);
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    selectedNetworkItem = networks[indexPath.row];
    [self loadNetwork];
    [self.navigationController pushViewController:networkPreferenceViewController animated:YES];
}

#pragma mark UIPickerView delegate

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [charsets count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return charsets[row];
}

- (void) pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSInteger offset = [pickerView tag];
    char **f = (char **)(((char *)[selectedNetworkItem ircNet]) + offset);
    free (*f);
    const char *v = CSTR(charsets[row]);
    *f = *v ? strdup (v) : NULL;
}

@end

@implementation NetworkViewController (Private)

- (NetworkItem *)selectedNetworkItem {
    return selectedNetworkItem;
}

- (void)loadFlag:(UISwitch *)field fromNetwork:(NetworkItem *)network {
    BOOL flag = [field tag];
    BOOL invert = flag < 0;
    if ( invert )
        flag = ~flag;
    BOOL val = ([network ircNet]->flags & flag) != 0;
    if ( invert )
        val = !val;
    [field setOn:val];
}

- (void)loadField:(UITextField *)field fromNetwork:(NetworkItem *)network {
    NSInteger offset = [field tag];
    char **f = (char **)(((char *)[network ircNet]) + offset);
    char *str= *f;
    
    NSString *val = str ? @(str) : @"";
    
    [field setText:val];
}

- (void)loadNetwork {
    [self loadField:networkNameTextField fromNetwork:selectedNetworkItem];
    [self loadFlag:selectedServerOnlySwitch fromNetwork:selectedNetworkItem];
    
    [self loadFlag:networkGlobalInformationSwitch fromNetwork:selectedNetworkItem];
    [self loadField:networkNickname1TextField fromNetwork:selectedNetworkItem];
    [self loadField:networkNickname2TextField fromNetwork:selectedNetworkItem];
    [self loadField:networkUsernameTextField fromNetwork:selectedNetworkItem];
    [self loadField:networkRealnameTextField fromNetwork:selectedNetworkItem];
    [self loadField:nickservPasswordTextField fromNetwork:selectedNetworkItem];
    [self loadField:serverPasswordTextField fromNetwork:selectedNetworkItem];

    [self loadFlag:autoConnectSwitch fromNetwork:selectedNetworkItem];
    [self loadFlag:bypassProxySwitch fromNetwork:selectedNetworkItem];
    [self loadFlag:useSslSwitch fromNetwork:selectedNetworkItem];
    [self loadFlag:acceptInvalidSslSwitch fromNetwork:selectedNetworkItem];

    NSInteger offset = [charsetPickerView tag];
    char **f = (char **)(((char *)[selectedNetworkItem ircNet]) + offset);
    char *str= *f;
    
    NSString *val = str ? @(str) : @"";
    
    [charsetPickerView selectRow:[charsets indexOfObject:val] inComponent:0 animated:NO];

    [self toggleUseGlobalInformation:networkGlobalInformationSwitch];
}

- (void)loadPreferences {
    [userViewController->skipOnStartUpSwitch setOn:prefs.slist_skip animated:NO];
    [userViewController->nickname1TextField setText:@(prefs.nick1)];
    [userViewController->nickname2TextField setText:@(prefs.nick2)];
    [userViewController->nickname3TextField setText:@(prefs.nick3)];
    [userViewController->usernameTextField setText:@(prefs.username)];
    [userViewController->realnameTextField setText:@(prefs.realname)];
    
    [networks release];
    [allNetworks release];
    allNetworks = [[NSMutableArray alloc] init];
    networks = [allNetworks retain];
    
    for (GSList *list = network_list; list; list = list->next) {
        [allNetworks addObject:[NetworkItem networkWithIrcnet:(struct ircnet *)list->data]];
    }
}

- (void)savePreferences {
    prefs.slist_skip = userViewController->skipOnStartUpSwitch.on;
    strcpy(prefs.nick1,        CSTR(userViewController->nickname1TextField.text));
    strcpy(prefs.nick2,        CSTR(userViewController->nickname2TextField.text));
    strcpy(prefs.nick3,        CSTR(userViewController->nickname3TextField.text));
    strcpy(prefs.username,    CSTR(userViewController->usernameTextField.text));
    strcpy(prefs.realname,    CSTR(userViewController->realnameTextField.text));
    servlist_save();
}

- (void)setFieldWithControl:(UITextField *)control {
    NSInteger offset = [control tag];
    char **f = (char **)(((char *)[selectedNetworkItem ircNet]) + offset);
    free (*f);
    const char *v = CSTR([control text]);
    *f = *v ? strdup (v) : NULL;
}

@end

@implementation UserInformationTableViewController

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return 3;
        case 2: return 2;
    }
    dassert(NO);
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"%d_%d", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewStylePlain reuseIdentifier:cellIdentifier];
        switch (indexPath.section*0x10+indexPath.row) {
            case 0x00:
                cell.textLabel.text = XCHATLSTR(@"Skip network list on startup");
                cell.accessoryView = skipOnStartUpSwitch;
                break;
            case 0x10:
                cell.textLabel.text = XCHATLSTR(@"Nick name:");
                cell.accessoryView = nickname1TextField;
                break;
            case 0x11:
                cell.textLabel.text = XCHATLSTR(@"Second choice:");
                cell.accessoryView = nickname2TextField;
                break;
            case 0x12:
                cell.textLabel.text = XCHATLSTR(@"Third choice:");
                cell.accessoryView = nickname3TextField;
                break;
            case 0x20:
                cell.textLabel.text = XCHATLSTR(@"User name:");
                cell.accessoryView = usernameTextField;
                break;
            case 0x21:
                cell.textLabel.text = XCHATLSTR(@"Real name:");
                cell.accessoryView = realnameTextField;
                break;
        }
    }
    return cell;
}

#pragma mark UIScrollView delegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    [nickname1TextField endEditing:YES];
    [nickname2TextField endEditing:YES];
    [nickname3TextField endEditing:YES];
    [usernameTextField  endEditing:YES];
    [realnameTextField  endEditing:YES];
}

@end

@implementation NetworkPreferenceTableViewController 

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.title = self.title;
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    [self.tableView reloadData];
}

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"NEW";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.textColor = [UIColor grayColor];
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
    cell.textLabel.text = XCHATLSTR(@"*NEW*");
    return cell;
}

- (UITableViewCellEditingStyle) tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0: return UITableViewCellEditingStyleDelete;
        case 1: return UITableViewCellEditingStyleInsert;
    }
    dassert(NO);
    return UITableViewCellEditingStyleNone;
}

@end

@interface ServersEditTableViewController : UITableViewController {
  @public
    NetworkItem *selectedNetworkItem;
    ServerItem *selectedServerItem;
}
@end

@implementation ServersTableViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark UITableView protocols

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section > 0) return 1;
    return [[[networkViewController selectedNetworkItem] servers] count];
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ( section > 0 ) return nil;
    return [NSString stringWithFormat:NSLocalizedStringFromTable(@"Servers for %s", @"xchat", @""), CSTR([[networkViewController selectedNetworkItem] name])];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section > 0 ) return [super tableView:tableView cellForRowAtIndexPath:indexPath];
                                         
    NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    ServerItem *server = [[networkViewController selectedNetworkItem] servers][indexPath.row];
    cell.textLabel.text = @(server->ircServer->hostname);
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *servers = (NSMutableArray *)[[networkViewController selectedNetworkItem] servers];
    if (indexPath.section > 0) {
        ircserver *ircServer = servlist_server_add ([[networkViewController selectedNetworkItem] ircNet], _("NewServer"));
        [servers addObject:[ServerItem serverWithIrcServer:ircServer]];
        indexPath = [NSIndexPath indexPathForRow:[servers count]-1 inSection:0];
        goto edit;
    }
    if ([tableView isEditing]) {
    edit:
        {
            ServerItem *selectedServerItem = servers[indexPath.row];
            ServersEditTableViewController *editTableViewController = [[ServersEditTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            editTableViewController->selectedNetworkItem = [networkViewController selectedNetworkItem];
            editTableViewController->selectedServerItem = selectedServerItem;
            [self.navigationController pushViewController:editTableViewController animated:YES];
            [editTableViewController release];
        }
    }
}

- (void) tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSMutableArray *servers = (NSMutableArray *)[[networkViewController selectedNetworkItem] servers];
        ServerItem *selectedServerItem = servers[indexPath.row];
        
        servlist_server_remove([[networkViewController selectedNetworkItem] ircNet], selectedServerItem->ircServer);
        [servers removeObjectAtIndex:indexPath.row];
    }
    [tableView reloadData];
}

@end

@implementation ServersEditTableViewController

- (void) viewWillDisappear:(BOOL)animated {
    UITextField *hostTextField = (UITextField *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].accessoryView;
    [selectedServerItem setServer:hostTextField.text];
    UITextField *portTextField = (UITextField *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].accessoryView;
    [selectedServerItem setPort:portTextField.text];
    [selectedNetworkItem resetFavoriteChannels];
}

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return XCHATLSTR(@"Favorite channels:");
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"cell_%d", indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UITextField *textField;
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = XCHATLSTR(@"Host");
                textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
                [textField setBorderStyle:UITextBorderStyleRoundedRect];
                cell.accessoryView = textField;
                [textField release];                
                textField.text = selectedServerItem->name;
                break;
            case 1:
                cell.textLabel.text = XCHATLSTR(@"Port");
                textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
                [textField setBorderStyle:UITextBorderStyleRoundedRect];
                cell.accessoryView = textField;
                [textField release];                
                textField.text = selectedServerItem->port;
                break;
            case 2:
                cell.textLabel.text = XCHATLSTR(@"SSL");
                UISwitch *sslSwitch = [[UISwitch alloc] init];
                [sslSwitch setOn:NO];
                [sslSwitch setEnabled:NO];
                cell.accessoryView = sslSwitch;
                [textField release];
                
        }
    }
    return cell;
}

@end

@implementation UserDetailsTableViewController

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 1;
        case 1: return 2;
        case 2: return 2;
    }
    dassert(NO);
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"%x_%x", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.minimumFontSize = 8.0f;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        switch (indexPath.section) {
            case 0:
                cell.textLabel.text = XCHATLSTR(@"Use global user information");
                cell.accessoryView = networkViewController->networkGlobalInformationSwitch;
                break;
            case 1:
                switch (indexPath.row) {
                    case 0:
                        cell.textLabel.text = XCHATLSTR(@"Nick name:");
                        cell.accessoryView = networkViewController->networkNickname1TextField;
                        break;
                    case 1:
                        cell.textLabel.text = XCHATLSTR(@"Second choice:");
                        cell.accessoryView = networkViewController->networkNickname2TextField;
                        break;
                }
                break;
            case 2:
                switch (indexPath.row) {
                    case 0:
                        cell.textLabel.text = XCHATLSTR(@"User name:");
                        cell.accessoryView = networkViewController->networkUsernameTextField;
                        break;
                    case 1:
                        cell.textLabel.text = XCHATLSTR(@"Real choice:");
                        cell.accessoryView = networkViewController->networkRealnameTextField;
                        break;
                }
                break;
        }
    }
    return cell;
}

@end

@implementation ConnectingTableViewController

- (void) viewWillAppear:(BOOL)animated {
    self.tabBarController.navigationItem.rightBarButtonItem = nil;
    self.tabBarController.title = self.title;
}

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 4;
        case 1: return 2;
    }
    dassert(NO);
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"%x_%x", indexPath.section, indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.textLabel.minimumFontSize = 8.0f;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        switch (indexPath.section) {
            case 0:
                switch (indexPath.row) {
                    case 0:
                        cell.textLabel.text = XCHATLSTR(@"Auto connect to this network at startup");
                        cell.accessoryView = networkViewController->autoConnectSwitch;
                        break;
                    case 1:
                        cell.textLabel.text = XCHATLSTR(@"Bypass proxy server");
                        cell.accessoryView = networkViewController->bypassProxySwitch;
                        break;
                    case 2:
                        cell.textLabel.text = XCHATLSTR(@"Use SSL for all the servers on this network");
                        cell.accessoryView = networkViewController->useSslSwitch;
                        break;
                    case 3:
                        cell.textLabel.text = XCHATLSTR(@"Accept invalid SSL certificate");
                        cell.accessoryView = networkViewController->acceptInvalidSslSwitch;
                        break;
                    default:
                        dassert(NO);
                }
                break;
            case 1:
                switch (indexPath.row) {
                    case 0:
                        cell.textLabel.text = XCHATLSTR(@"Nickserv password:");
                        cell.accessoryView = networkViewController->nickservPasswordTextField;
                        break;
                    case 1:
                        cell.textLabel.text = XCHATLSTR(@"Server password:");
                        cell.accessoryView = networkViewController->serverPasswordTextField;
                        break;
                    default:
                        dassert(NO);
                }
                break;
            default:
                dassert(NO);
        }
    }
    return cell;
}

@end

@interface FavoriteChannelsEditTableViewController : UITableViewController {
@public
    NetworkItem *selectedNetworkItem;
    OneChannel *selectedChannel;
}
@end

@implementation FavoriteChannelsTableViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark UITableView protocols

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section > 0) return 1;
    return [[[networkViewController selectedNetworkItem] favoriteChannels] count];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section > 0 ) return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    OneChannel *channel = [[networkViewController selectedNetworkItem] favoriteChannels][indexPath.row];
    cell.textLabel.text = [channel name];
    if ( [[channel key] length] > 0 )
        cell.textLabel.text = [cell.textLabel.text stringByAppendingFormat:@" / %@", [channel key]];
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *favoriteChannels = (NSMutableArray *)[[networkViewController selectedNetworkItem] favoriteChannels];
    if ( indexPath.section > 0 ) {
        [favoriteChannels addObject:[OneChannel channelWithName:NSLocalizedStringFromTable(@"#(new)", @"xchataqua", @"Default channel name: MainMenu->File->Server List... => (Select server)->On Join->channels->'+'")]];
        indexPath = [NSIndexPath indexPathForRow:[favoriteChannels count]-1 inSection:0];
        goto edit;
    }
    if ( [tableView isEditing] ) {
    edit:
        {
            OneChannel *selectedChannel = favoriteChannels[indexPath.row];
            FavoriteChannelsEditTableViewController *editTableViewController = [[FavoriteChannelsEditTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
            editTableViewController->selectedNetworkItem = [networkViewController selectedNetworkItem];
            editTableViewController->selectedChannel = selectedChannel;
            [self.navigationController pushViewController:editTableViewController animated:YES];
            [editTableViewController release];
        }
    }
}

@end

@implementation FavoriteChannelsEditTableViewController

- (void) viewWillDisappear:(BOOL)animated {
    UITextField *channelTextField = (UITextField *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].accessoryView;
    selectedChannel.name = channelTextField.text;
    UITextField *keyTextField = (UITextField *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]].accessoryView;
    selectedChannel.key = keyTextField.text;
    [selectedNetworkItem resetFavoriteChannels];
}

#pragma mark UITableView protocols

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return XCHATLSTR(@"Favorite channels:");
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = [NSString stringWithFormat:@"cell_%d", indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 120.0f, 30.0f)];
        [textField setBorderStyle:UITextBorderStyleRoundedRect];
        cell.accessoryView = textField;
        [textField release];
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = XCHATLSTR(@"Channel");
                textField.text = [selectedChannel name];
                break;
            case 1:
                cell.textLabel.text = XCHATLSTR(@"Password");
                textField.text = [selectedChannel key];
                break;
        }
    }
    return cell;
}

@end


@implementation ConnectCommandsTableViewController

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tabBarController.navigationItem.rightBarButtonItem = self.editButtonItem;
}

#pragma mark UITableView protocols

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section > 0) return 1;
    return [[[networkViewController selectedNetworkItem] connectCommands] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ( indexPath.section > 0 ) return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    NSString *cellIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.textLabel.text = [[networkViewController selectedNetworkItem] connectCommands][indexPath.row];
    return cell;
}

@end


