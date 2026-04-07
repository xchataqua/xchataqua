//
//  NSMacros.h
//  FoundationExtension
//
//  Created by Jeong YunWon on 2016. 3. 21..
//  Copyright © 2016년 youknowone.org. All rights reserved.
//

#if __has_feature(modules)
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif

#if !defined(NS_ASSUME_NONNULL_BEGIN)
#define NS_ASSUME_NONNULL_BEGIN
#define NS_ASSUME_NONNULL_END
#endif

#if !__has_feature(nullability)
#define nullable
#define nonnull
#define __nullable
#define __nonnull
#endif
