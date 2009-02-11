#import "SGHBoxSubViewInspector.h"
#import "SGHBoxView.h"

@implementation SGHBoxSubViewInspector

- (id) init
{
    self = [super init];
    [NSBundle loadNibNamed:@"SGHBoxSubViewInspector" owner:self];
    return self;
}

- (void) doOrder:(id) sender
{
    NSView *view = [self object];
    SGHBoxView *hbox = [view superview];
    [hbox setOrder:[sender intValue] forView:view];
    [super ok:sender];
}

- (void) doStretch:(id) sender
{
    NSView *view = [self object];
    SGHBoxView *hbox = [view superview];
    
    NSLog (@"%d", [sender intValue]);

    if ([sender intValue])
        [hbox setStretchView:view];
    
    [super ok:sender];
}

- (void) revert:(id) sender
{
    NSView *view = [self object];
    SGHBoxView *hbox = [view superview];
    
    [order_text setIntValue:[hbox viewOrder:view]];
    [stretch_check setIntValue:([hbox stretchView] == view)];
        
    [super revert:sender];
}


@end
