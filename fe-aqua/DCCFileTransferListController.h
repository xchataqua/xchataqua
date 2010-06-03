//
//  DCCFileTransferListController.h
//  aquachat-mod
//
//  Created by Camillo Lugaresi on 20/01/06.
//  Copyright 2006 Camillo Lugaresi. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DCCListController.h"


@interface DCCFileItem : DCCItem
{
  @public
    //NSMutableString	*status;
    NSMutableString	*file;
    NSMutableString	*size;
    NSMutableString	*position;
    NSMutableString	*per;
    NSMutableString	*kbs;
    NSMutableString	*eta;
}

@end

@interface DCCFileTransferListController : DCCListController {
	NSString *globalSpeed;
	int *cpssum;	/* subclasses must set this in init */
}

- (void)updateGlobalSpeed;

@end
