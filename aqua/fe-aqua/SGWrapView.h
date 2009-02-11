//
//  SGWrapView.h
//  aquachat
//
//  Created by Steve Green on 7/4/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SGView.h>

@interface SGWrapView : SGView 
{
    unsigned rows;
}

- (unsigned) rowCount;

@end
