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

#import <Cocoa/Cocoa.h>
#ifdef __MAC_OS_X_VERSION_10_5
#import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#else
#import <InterfaceBuilder/InterfaceBuilder.h>
#endif

@interface SGFormViewInspector : IBInspector
{
    IBOutlet NSPopUpButton *bottomConnectionMenu;
    IBOutlet NSTextField *bottomOffsetText;
    IBOutlet NSPopUpButton *bottomRelativeMenu;
    IBOutlet NSTextField *identifierText;
    IBOutlet NSPopUpButton *leftConnectionMenu;
    IBOutlet NSTextField *leftOffsetText;
    IBOutlet NSPopUpButton *leftRelativeMenu;
    IBOutlet NSPopUpButton *rightConnectionMenu;
    IBOutlet NSTextField *rightOffsetText;
    IBOutlet NSPopUpButton *rightRelativeMenu;
    IBOutlet NSPopUpButton *topConnectionMenu;
    IBOutlet NSTextField *topOffsetText;
    IBOutlet NSPopUpButton *topRelativeMenu;
	
	NSPopUpButton *connectionMenus [4];
	NSPopUpButton *relativeMenus [4];
	NSTextField   *offsetTexts [4];
}
- (IBAction)doConstrain:(id)sender;
- (IBAction)doIdentifier:(id)sender;
@end
