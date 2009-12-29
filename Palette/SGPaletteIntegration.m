/* X-Chat Aqua
 * Copyright (C) 2005-2009 Steve Green
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


#import <InterfaceBuilderKit/InterfaceBuilderKit.h>

// Import your framework view and your inspector 
// #import <MyFramework/MyView.h>
// #import "MyInspector.h"
#import "SGFormView.h"
#import "SGHBoxView.h"
#import "SGVBoxView.h"
#import "fe-aqua/Palette/SGFormViewInspector.h"
#import "fe-aqua/Palette/SGHBoxViewInspector.h"
#import "fe-aqua/Palette/SGVBoxViewInspector.h"

@implementation SGFormView ( SGPalette )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

//    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];

    [classes addObject:[SGFormViewInspector class]];
}

- (NSView*)ibDesignableContentView {
	return self;
}

@end

@implementation SGHBoxView ( SGPalette )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];
    
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:@"hJustification", @"hInnerMargin", @"hOutterMargin", nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];

    [classes addObject:[SGHBoxViewInspector class]];
}

- (NSView*)ibDesignableContentView {
	return self;
}

@end

@implementation SGVBoxView ( SGPalette )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:@"vInnerMargin", @"vOutterMargin", @"vJustification", @"hJustification", nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "SGPaletteLeopardInspector" with the name of your inspector class.
    [classes addObject:[SGVBoxViewInspector class]];
}

- (NSView*)ibDesignableContentView {
	return self;
}

@end


