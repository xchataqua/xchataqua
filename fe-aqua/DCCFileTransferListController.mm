//
//  DCCFileTransferListController.m
//  aquachat-mod
//
//  Created by Camillo Lugaresi on 20/01/06.
//  Copyright 2006 Camillo Lugaresi. All rights reserved.
//

extern "C" {
#include "../common/xchat.h"
#include "../common/xchatc.h"
#include "../common/outbound.h"
#include "../common/network.h"
#include "../common/dcc.h"
}

#import "DCCFileTransferListController.h"

#import "XACommon.h"

@implementation DCCFileItem

- (id) initWithDCC:(struct DCC *) the_dcc
{
	[super initWithDCC:the_dcc];

    file = [[NSMutableString stringWithCapacity:0] retain];
    size = [[NSMutableString stringWithCapacity:0] retain];
    position = [[NSMutableString stringWithCapacity:0] retain];
    per = [[NSMutableString stringWithCapacity:0] retain];
    kbs = [[NSMutableString stringWithCapacity:0] retain];
    eta = [[NSMutableString stringWithCapacity:0] retain];
   
    return self;
}

- (void) dealloc
{
    [file release];
    [size release];
    [position release];
    [per release];
    [kbs release];
    [eta release];

    [super dealloc];
}

- (void) update
{
    [super update];
    [file setString:[NSString stringWithUTF8String:dcc->file]];
    [size setString:[NSString stringWithFormat:@"%@", formatNumber (dcc->size)]];
    [position setString:[NSString stringWithFormat:@"%@", formatNumber (dcc->pos)]];
    [per setString:[NSString stringWithFormat:@"%.0f%%", floor((float) dcc->pos / dcc->size * 100.00)]];	// the floor is to ensure that the percent does not display 100% until the file is really finished
    [kbs setString:[NSString stringWithFormat:@"%.1f", (float) dcc->cps / 1024]];
    if (dcc->cps)
    {
        int to_go = (dcc->size - dcc->ack) / dcc->cps;
        [eta setString:[NSString stringWithFormat:@"%.2d:%.2d:%.2d",
                                to_go / 3600, (to_go / 60) % 60, to_go % 60]];
    }
    else
        [eta setString:@"--:--:--"];
}

@end

//////////////////////////////////////////////////////////////////////

@implementation DCCFileTransferListController

- (void)dealloc
{
	[globalSpeed release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	[self updateGlobalSpeed];
}

- (void) copy:(id) sender
{
	NSPasteboard *pb = [NSPasteboard generalPasteboard];
	NSMutableString *copyString = [NSMutableString stringWithCapacity:200];
	
	NSEnumerator *rowEnum = [item_list selectedRowEnumerator];
	NSNumber *rowIndex;
	while (rowIndex = [rowEnum nextObject]) {
		DCCFileItem *item = [my_items objectAtIndex:[rowIndex intValue]];
		[copyString appendFormat:@"%@ (%"DCC_SIZE_FMT" bytes)\n", item->file, item->dcc->size];
	}
	[copyString deleteCharactersInRange:NSMakeRange([copyString length] - 1, 1)];	//chop off last \n

	[pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, nil] owner:nil];
	[pb setString:copyString forType:NSStringPboardType];
}

- (BOOL) validateMenuItem:(NSMenuItem*)menuItem
{
	if ([menuItem action] == @selector(copy:)) {
		return ([item_list numberOfSelectedRows] > 0);
	}
	return [super validateMenuItem:menuItem];
}

- (void)setGlobalSpeed:(NSString *)speed
{
	[speed retain];
	[globalSpeed release];
	globalSpeed = speed;
}

- (void)updateGlobalSpeed
{
	if (cpssum)
		[self setGlobalSpeed:[NSString stringWithFormat:@"%.1f KB/s", (float) *cpssum / 1024]];
}

- (void) update:(struct DCC *) dcc
{
	[self updateGlobalSpeed];
	[super update:dcc];
}

@end
