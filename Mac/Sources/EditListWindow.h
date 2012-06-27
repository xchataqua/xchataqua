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

/* EditListWindow.h
 * Correspond to fe-gtk: xchat/src/fe-gtk/editlist.*
 */

#include <glib/glib.h>
#import "UtilityWindow.h"

@interface EditListWindow : UtilityWindow <NSTableViewDataSource, NSTableViewDelegate> {
    GSList*  *slist;
    NSString *filename;
    NSMutableArray *items;
    IBOutlet NSTableView *itemTableView;
    char *help;
    
    id target;
    SEL didCloseSelector;
    BOOL isEdited;
}

@property (nonatomic, assign) char *help;

- (IBAction)addItem:(id)sender;
- (IBAction)removeItem:(id)sender;

- (IBAction)saveToFile:(id)sender;
- (IBAction)showHelp:(id)sender;
- (IBAction)sortList:(id)sender;

- (void)loadDataFromList:(GSList **)slist filename:(NSString *)filename;
- (void)setTarget:(id)target didCloseSelector:(SEL)selector;

@end

@interface UserlistButtonsWindowDelegate : NSObject <NSWindowDelegate>

@end
