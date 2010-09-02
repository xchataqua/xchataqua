//
//  DCCFileTransferListController.h
//  aquachat-mod
//
//  Created by Camillo Lugaresi on 20/01/06.
//  Copyright 2006 Camillo Lugaresi. All rights reserved.
//

#import "DCCListController.h"

@interface DCCFileItem : DCCItem
{
	//NSString	*status;
	NSString	*file;
	NSString	*size;
	NSString	*position;
	NSString	*per;
	NSString	*kbs;
	NSString	*eta;
}

@property (nonatomic, retain) NSString *file, *size, *position, *per, *kbs, *eta;

@end

@interface DCCFileTransferListController : DCCListController {
	NSString *globalSpeed;
	int *cpssum;	/* subclasses must set this in init */
}

- (void)updateGlobalSpeed;

@end
