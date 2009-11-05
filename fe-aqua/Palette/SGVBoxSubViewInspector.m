#import "SGVBoxSubViewInspector.h"
#import "SGVBoxView.h"

@implementation SGVBoxSubViewInspector

- (id) init
{
    self = [super init];
    [NSBundle loadNibNamed:@"SGVBoxSubViewInspector" owner:self];
    return self;
}

- (void) doOrder:(id) sender
{
    NSView *view = [self object];
    SGVBoxView *VBox = [view superview];
    [VBox setOrder:[sender intValue] forView:view];
    [super ok:sender];
}

- (void) doStretch:(id) sender
{
    NSView *view = [self object];
    SGVBoxView *VBox = [view superview];
    
    if ([sender intValue])
        [VBox setStretchView:view];
    
    [super ok:sender];
}

- (void) revert:(id) sender
{
    NSView *view = [self object];
    SGVBoxView *VBox = [view superview];
    
    [order_text setIntValue:[VBox viewOrder:view]];
    [stretch_check setIntValue:([VBox stretchView] == view)];
        
    [super revert:sender];
}


@end
