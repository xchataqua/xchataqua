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

#import <Cocoa/Cocoa.h>
#include <glib/gslist.h>

@interface EditList : NSObject
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
<NSTableViewDataSource,NSTableViewDelegate>
#endif
{
    GSList		**slist;
    NSString 	*filename;
    NSString 	*title;
    NSMutableArray *myItems;
	IBOutlet NSTableView *commandTableView;
}

- (IBAction) doDelete:(id)sender;
- (IBAction) doDown:(id)sender;
- (IBAction) doHelp:(id)sender;
- (IBAction) doNew:(id)sender;
- (IBAction) doSort:(id)sender;
- (IBAction) doUp:(id)sender;

- (IBAction) doSave:(id)sender;

- (id) initWithList:(GSList **)slist filename:(NSString *)filename title:(NSString *)title;
- (void) show;

@end
