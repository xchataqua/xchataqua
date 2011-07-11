//
//  NetworkViewController.h
//  X-Chat iOS
//
//  Created by 정윤원 on 10. 12. 16..
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "UtilityViewController.h"

@class UserInformationTableViewController;
@interface NetworkViewController : UtilityViewController<UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
    NSMutableArray *networks, *allNetworks;
    id selectedNetworkItem;
    
    NSArray *charsets;
    
    IBOutlet UserInformationTableViewController *userViewController;
    IBOutlet UITabBarController *networkPreferenceViewController;
    IBOutlet UITableViewController *networkTableViewController;
    IBOutlet UITableView *networkTableView;
    
    IBOutlet UITextField *networkNameTextField;
    
  @public
    IBOutlet UISwitch *selectedServerOnlySwitch;
    
    IBOutlet UISwitch *networkGlobalInformationSwitch;
    IBOutlet UITextField *networkNickname1TextField, *networkNickname2TextField;
    IBOutlet UITextField *networkUsernameTextField, *networkRealnameTextField;
    
    IBOutlet UISwitch *autoConnectSwitch, *bypassProxySwitch;
    IBOutlet UISwitch *useSslSwitch, *acceptInvalidSslSwitch;
    IBOutlet UITextField *nickservPasswordTextField, *serverPasswordTextField;
    IBOutlet UIPickerView *charsetPickerView;
}

- (IBAction)showUserInformation;
- (IBAction)setFlagWithSwitch:(UISwitch *)control;
- (IBAction)toggleUseGlobalInformation:(UISwitch *)sender;

@end

@interface UserInformationTableViewController : UITableViewController {
  @public
    IBOutlet UISwitch *skipOnStartUpSwitch;
    IBOutlet UITextField *nickname1TextField, *nickname2TextField, *nickname3TextField;
    IBOutlet UITextField *usernameTextField, *realnameTextField;
}

@end

@interface NetworkPreferenceTableViewController : UITableViewController {
  @public
    IBOutlet NetworkViewController *networkViewController;
}

@end

@interface ServersTableViewController            : NetworkPreferenceTableViewController @end
@interface UserDetailsTableViewController        : NetworkPreferenceTableViewController<UIScrollViewDelegate> @end
@interface ConnectingTableViewController        : UIViewController<UIScrollViewDelegate> {
  @public
    IBOutlet NetworkViewController *networkViewController;
}
@end
@interface FavoriteChannelsTableViewController    : NetworkPreferenceTableViewController @end
@interface ConnectCommandsTableViewController    : NetworkPreferenceTableViewController @end

