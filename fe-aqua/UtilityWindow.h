//
//  UtilityWindow.h
//  X-Chat Aqua
//
//  Created by iphary on 10. 11. 14..
//  Copyright 2010 iphary.org. All rights reserved.
//

#import "TabOrWindowView.h"

@interface UtilityWindow : NSWindow
{
	id key;
}

+ (UtilityWindow *)utilityIfExistsByKey:(id)key;
+ (UtilityWindow *)utilityByKey:(id)key;
+ (UtilityWindow *)utilityByKey:(id)key windowNibName:(NSString *)nibName;

@end

@interface UtilityTabOrWindowView : TabOrWindowView
{
	id key;
}

+ (UtilityTabOrWindowView *)utilityIfExistsByKey:(id)key;
+ (UtilityTabOrWindowView *)utilityByKey:(id)key viewNibName:(NSString *)nibName;
- (void)becomeTabOrWindowAndShow;

@end