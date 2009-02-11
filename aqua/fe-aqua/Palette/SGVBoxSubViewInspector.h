/* SGVBoxSubViewInspector */

#import <Cocoa/Cocoa.h>
#ifdef __MAC_OS_X_VERSION_10_5
# import <InterfaceBuilderKit/InterfaceBuilderKit.h>
#else
# import <InterfaceBuilder/InterfaceBuilder.h>
#endif


@interface SGVBoxSubViewInspector : IBInspector
{
    IBOutlet NSTextField *order_text;
    IBOutlet NSButton *stretch_check;
}

@end
