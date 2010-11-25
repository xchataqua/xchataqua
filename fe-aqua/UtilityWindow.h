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
	id windowKey;
}

@property (nonatomic, readonly) id windowKey;

+ (id)utilityIfExistsByKey:(id)key;
+ (id)utilityByKey:(id)key;
+ (id)utilityByKey:(id)key windowNibName:(NSString *)nibName;

@end

@interface UtilityTabOrWindowView : TabOrWindowView
{
	id windowKey;
}

@property (nonatomic, readonly) id windowKey;

+ (id)utilityIfExistsByKey:(id)key;
+ (id)utilityByKey:(id)key viewNibName:(NSString *)nibName;
- (void)becomeTabOrWindowAndShow:(BOOL)flag;

@end