//
//  NSObject.m
//  FoundationExtension
//
//  Created by Jeong YunWon on 12. 10. 16..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import <objc/runtime.h>
#import <objc/message.h>

#import "NSObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSAMethod ()

- (instancetype)initWithMethod:(Method)method;
+ (instancetype)methodWithMethod:(Method)method;

@end


@implementation NSObject (ObjCRuntime)

- (nullable id)performSelector:(SEL)sel withObject:(nullable id)obj1 withObject:(nullable id)obj2 withObject:(nullable id)obj3 {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id, id, id))objc_msgSend)(self, sel, obj1, obj2, obj3);
}

- (nullable id)performSelector:(SEL)sel withObject:(nullable id)obj1 withObject:(nullable id)obj2 withObject:(nullable id)obj3 withObject:(nullable id)obj4 {
    if (!sel) [self doesNotRecognizeSelector:sel];
    return ((id(*)(id, SEL, id, id, id, id))objc_msgSend)(self, sel, obj1, obj2, obj3, obj4);
}

- (nullable id)associatedObjectForKey:(void *)key {
    return objc_getAssociatedObject(self, key);
}

- (void)setAssociatedObject:(nullable id)object forKey:(void *)key {
    [self setAssociatedObject:object forKey:key policy:OBJC_ASSOCIATION_RETAIN];
}

- (void)setAssociatedObject:(nullable id)object forKey:(void *)key policy:(objc_AssociationPolicy)policy {
    objc_setAssociatedObject(self, key, object, policy);
}

- (void)removeAssociatedObjectForKey:(void *)key {
    [self removeAssociatedObjectForKey:key policy:OBJC_ASSOCIATION_RETAIN];
}

- (void)removeAssociatedObjectForKey:(void *)key policy:(objc_AssociationPolicy)policy {
    [self setAssociatedObject:nil forKey:key policy:policy];
}

@end


@implementation NSObject (ObjCRuntimeClass)

+ (NSString *)name {
    return @(class_getName(self));
}

+ (Method)methodValueForSelector:(SEL)selector {
    return class_getInstanceMethod(self, selector);
}

+ (NSAMethod *)methodObjectForSelector:(SEL)selector {
    return [NSAMethod methodWithMethod:class_getInstanceMethod(self, selector)];
}

+ (Method)classMethodValueForSelector:(SEL)selector {
    return class_getClassMethod(self, selector);
}

+ (NSAMethod *)classMethodObjectForSelector:(SEL)selector {
    return [NSAMethod methodWithMethod:class_getClassMethod(self, selector)];
}

+ (IMP)methodImplementationForSelector:(SEL)selector {
    return class_getMethodImplementation(self, selector);
}

+ (void)addMethodForSelector:(SEL)selector fromMethod:(NSAMethod *)method {
    [self addMethodForSelector:selector implementation:method.implementation types:method.typeEncoding];
}

+ (void)addMethodForSelector:(SEL)selector implementation:(IMP)implementation types:(NSString *)implementationTypes {
    class_addMethod(self, selector, implementation, implementationTypes.UTF8String);
}

+ (void)addClassMethodForSelector:(SEL)selector fromMethod:(NSAMethod *)method {
    [self addClassMethodForSelector:selector implementation:method.implementation types:method.typeEncoding];
}

+ (void)addClassMethodForSelector:(SEL)selector implementation:(IMP)implementation types:(NSString *)implementationTypes {
    Class class = object_getClass(self.class);
    class_addMethod(class, selector, implementation, implementationTypes.UTF8String);
}

@end


@implementation NSAMethod
@synthesize method=_method;

- (instancetype)initWithMethod:(Method)method {
    if (method == nil) {
        return nil;
    }
    self = [super init];
    if (self != nil) {
        self->_method = method;
    }
    return self;
}

+ (instancetype)methodWithMethod:(Method)method {
    return [[self alloc] initWithMethod:method];
}

- (IMP)implementation {
    return method_getImplementation(self->_method);
}

- (void)setImplementation:(IMP)implementation {
    method_setImplementation(self->_method, implementation);
}

- (NSString *_Nullable)typeEncoding {
    return @(method_getTypeEncoding(self->_method));
}

- (void)exchangeImplementationWith:(NSAMethod *)method {
    method_exchangeImplementations(self.method, method.method);
}

#pragma mark NSObject protocols

- (NSUInteger)hash {
    return (NSUInteger)self.method;
}

- (BOOL)isEqualToMethod:(NSAMethod *)object {
    return self.hash == object.hash;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[NSAMethod class]]) {
        return [self isEqualToMethod:object];
    }
    return NO;
}

@end

@implementation NSObject (AntiARC)

- (instancetype)_retain {
    CFRetain((__bridge CFTypeRef)self);
    return self;
}

- (oneway void)_release {
    CFRelease((__bridge CFTypeRef)self);
}

- (instancetype)_autorelease {
    CFAutorelease((__bridge CFTypeRef)self);
    return self;
}

@end

NS_ASSUME_NONNULL_END
