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

#import <AppKit/AppKit.h>
#import "TabOrWindowView.h"

#ifdef USE_DCC64
#define DCC_SIZE_FMT "qi"
#else
#define DCC_SIZE_FMT "u"
#endif

@interface DCCItem : NSObject
{
  @public
    struct DCC 		*dcc;
	unsigned char prev_dccstat;
    
    NSMutableString	*status;
}

- (id) initWithDCC:(struct DCC *) the_dcc;
- (void) update;

@end

@interface DCCListController : NSResponder
{
	IBOutlet NSTableView		*item_list;
	IBOutlet TabOrWindowView	*dcc_list_view;
    NSMutableArray	*my_items;
	BOOL			hasSelection;
	unsigned char	lastDCCStatus;
	unsigned		activeCount;
}

- (id) initWithNibNamed:(NSString *)nibName;
- (DCCItem *)itemWithDCC:(struct DCC *) dcc;
- (void) show:(bool) and_bring_to_front;
- (void) update:(struct DCC *) dcc;
- (void) add:(struct DCC *) dcc;
- (void) remove:(struct DCC *) dcc;
- (void)setHasSelection:(BOOL)value;
- (void)setTabColorWithStatus:(unsigned char)dcc_status;
- (void) do_abort:(id) sender;

@end
