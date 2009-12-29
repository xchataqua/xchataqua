/* X-Chat Aqua
 * Copyright (C) 2005 Steve Green
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
 
 #import "SGPalette.h"

@implementation SGPalette

- init
{
    [super init];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(willInspectObject:)
                                          name:IBWillInspectObjectNotification
                                          object:nil];
	
    return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void) willInspectObject:(NSNotification *)notification
{
    id object = [notification object];

    if (![object isKindOfClass:[NSView class]])
		return;

	id parent = [object superview];

	if ([parent isKindOfClass:[SGFormView class]])
    {
        [[IBInspectorManager sharedInspectorManager]
            addInspectorModeWithIdentifier:@"SGFormViewAttributes"
                                 forObject:object                  	// object being inspected
                            localizedLabel:@"SGFormView"            // Label to show in the popup
                        inspectorClassName:@"SGFormViewInspector" 	// Inspector class name
                                  ordering:-1.0];                   // Order of mode in inspector popup.
                                                                    // -1 implies the end
    }

	if ([parent isKindOfClass:[SGHBoxView class]])
    {
        [[IBInspectorManager sharedInspectorManager]
            addInspectorModeWithIdentifier:@"SGHBoxViewAttributes"
                                 forObject:object                  	// object being inspected
                            localizedLabel:@"SGHBoxView"            // Label to show in the popup
                        inspectorClassName:@"SGHBoxSubViewInspector"// Inspector class name
                                  ordering:-1.0];                   // Order of mode in inspector popup.
                                                                    // -1 implies the end
    }

	if ([parent isKindOfClass:[SGVBoxView class]])
    {
        [[IBInspectorManager sharedInspectorManager]
            addInspectorModeWithIdentifier:@"SGVBoxViewAttributes"
                                 forObject:object                  	// object being inspected
                            localizedLabel:@"SGVBoxView"            // Label to show in the popup
                        inspectorClassName:@"SGVBoxSubViewInspector"// Inspector class name
                                  ordering:-1.0];                   // Order of mode in inspector popup.
                                                                    // -1 implies the end
    }

}

@end

