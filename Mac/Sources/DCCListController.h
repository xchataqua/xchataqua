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

/* DCCListController.h
 * Correspond to fe-gtk: xchat/src/fe-gtk/dccgui.c
 */

#import "TabOrWindowView.h"

#ifdef USE_DCC64
#   define DCC_SIZE_FMT "qi"
#else
#   define DCC_SIZE_FMT "u"
#endif

@interface DCCItem : NSObject
{
    NSString *status;    
@public
    struct DCC *dcc;
    unsigned char prevDccStat;
}

@property (nonatomic, retain) NSString *status;

- (id) initWithDCC:(struct DCC *)dcc;
- (void) update;

@end

@interface DCCListController : NSResponder <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTableView *itemTableView;
    IBOutlet TabOrWindowView *dccListView;
    NSMutableArray *dccItems;
    BOOL hasSelection;
    unsigned char lastDCCStatus;
    unsigned activeCount;
}

@property (nonatomic, assign) BOOL hasSelection;

- (IBAction) doAbort:(id) sender;

- (id)initWithNibNamed:(NSString *)nibName;
- (DCCItem *)itemWithDCC:(struct DCC *) dcc;
- (void)show:(BOOL)bringToFront;
- (void)update:(struct DCC *) dcc;
- (void)add:(struct DCC *) dcc;
- (void)remove:(struct DCC *) dcc;
- (void)setTabColorWithStatus:(unsigned char)status;

@end
