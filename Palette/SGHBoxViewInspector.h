/* SGHBoxViewInspector */

#import <Cocoa/Cocoa.h>
#ifdef MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_5
# import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#else
# import <InterfaceBuilder/InterfaceBuilder.h>
#endif

@interface SGHBoxViewInspector : IBInspector
{
    IBOutlet NSPopUpButton *HJustMenu;
    IBOutlet NSTextField *inner_text;
    IBOutlet NSTextField *outter_text;
}
@end
