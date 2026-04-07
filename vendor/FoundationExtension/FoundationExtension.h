//
//  FoundationExtension.h
//  Minimal vendor copy - only NSObject runtime extensions are used.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#import <FoundationExtension/NSObject.h>
