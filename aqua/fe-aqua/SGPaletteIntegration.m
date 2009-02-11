//
//  SGPaletteLeopard.m
//  aquachat
//
//  Created by libc on 30.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <InterfaceBuilderKit/InterfaceBuilderKit.h>

// Import your framework view and your inspector 
// #import <MyFramework/MyView.h>
// #import "MyInspector.h"
#import "SGFormView.h"
#import "SGHBoxView.h"
#import "SGVBoxView.h"
#import "LeopardPalette/SGFormViewInspector.h"
#import "LeopardPalette/SGHBoxViewInspector.h"
#import "LeopardPalette/SGVBoxViewInspector.h"

@implementation SGFormView ( SGPaletteLeopard )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "SGPaletteLeopardInspector" with the name of your inspector class.
    [classes addObject:[SGFormViewInspector class]];
}

- (NSView*)ibDesignableContentView {
	return self;
}

@end

@implementation SGHBoxView ( SGPaletteLeopard )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
}

- (void)ibPopulateAttributeInspectorClasses:(NSMutableArray *)classes {
    [super ibPopulateAttributeInspectorClasses:classes];
	// Replace "SGPaletteLeopardInspector" with the name of your inspector class.
    [classes addObject:[SGHBoxViewInspector class]];
}

- (NSView*)ibDesignableContentView {
	return self;
}

@end

@implementation SGVBoxView ( SGPaletteLeopard )

- (void)ibPopulateKeyPaths:(NSMutableDictionary *)keyPaths {
    [super ibPopulateKeyPaths:keyPaths];

	// Remove the comments and replace "MyFirstProperty" and "MySecondProperty" 
	// in the following line with a list of your view's KVC-compliant properties.
    [[keyPaths objectForKey:IBAttributeKeyPaths] addObjectsFromArray:[NSArray arrayWithObjects:/* @"MyFirstProperty", @"MySecondProperty",*/ nil]];
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


