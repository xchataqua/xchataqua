//
//  ReleaseNotesWindow.h
//  aquachat
//
//  Created by libc on 31.10.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ReleaseNotesWindow : NSWindowController {
	IBOutlet NSTextView * release_notes;
}
-(id)   init;
-(void) show;
@end
