//
//  SRCommon.m
//  ShortcutRecorder
//
//  Copyright 2006 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import "SRCommon.h"
#import "SRKeyCodeTransformer.h"

#pragma mark -
#pragma mark dummy class 

@implementation SRDummyClass @end

#pragma mark -

//---------------------------------------------------------- 
// SRStringForKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForKeyCode( signed short keyCode )
{
    static SRKeyCodeTransformer *keyCodeTransformer = nil;
    if ( !keyCodeTransformer )
        keyCodeTransformer = [[SRKeyCodeTransformer alloc] init];
    return [keyCodeTransformer transformedValue:[NSNumber numberWithShort:keyCode]];
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlags( unsigned int flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & controlKey ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & optionKey ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & shiftKey ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & cmdKey ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCarbonModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCarbonModifierFlags( flags ), 
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlags()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlags( unsigned int flags )
{
    NSString *modifierFlagsString = [NSString stringWithFormat:@"%@%@%@%@", 
		( flags & NSControlKeyMask ? [NSString stringWithFormat:@"%C", KeyboardControlGlyph] : @"" ),
		( flags & NSAlternateKeyMask ? [NSString stringWithFormat:@"%C", KeyboardOptionGlyph] : @"" ),
		( flags & NSShiftKeyMask ? [NSString stringWithFormat:@"%C", KeyboardShiftGlyph] : @"" ),
		( flags & NSCommandKeyMask ? [NSString stringWithFormat:@"%C", KeyboardCommandGlyph] : @"" )];
	
	return modifierFlagsString;
}

//---------------------------------------------------------- 
// SRStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRStringForCocoaModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode )
{
    return [NSString stringWithFormat: @"%@%@", 
        SRStringForCocoaModifierFlags( flags ),
        SRStringForKeyCode( keyCode )];
}

//---------------------------------------------------------- 
// SRReadableStringForCarbonModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCarbonModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		( flags & cmdKey ? SRLoc(@"Command + ") : @""),
		( flags & optionKey ? SRLoc(@"Option + ") : @""),
		( flags & controlKey ? SRLoc(@"Control + ") : @""),
		( flags & shiftKey ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;    
}

//---------------------------------------------------------- 
// SRReadableStringForCocoaModifierFlagsAndKeyCode()
//---------------------------------------------------------- 
NSString * SRReadableStringForCocoaModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode )
{
    NSString *readableString = [NSString stringWithFormat:@"%@%@%@%@%@", 
		(flags & NSCommandKeyMask ? SRLoc(@"Command + ") : @""),
		(flags & NSAlternateKeyMask ? SRLoc(@"Option + ") : @""),
		(flags & NSControlKeyMask ? SRLoc(@"Control + ") : @""),
		(flags & NSShiftKeyMask ? SRLoc(@"Shift + ") : @""),
        SRStringForKeyCode( keyCode )];
	return readableString;
}

//---------------------------------------------------------- 
// SRCarbonToCocoaFlags()
//---------------------------------------------------------- 
unsigned int SRCarbonToCocoaFlags( unsigned int carbonFlags )
{
	unsigned int cocoaFlags = ShortcutRecorderEmptyFlags;
	
	if (carbonFlags & cmdKey) cocoaFlags += NSCommandKeyMask;
	if (carbonFlags & optionKey) cocoaFlags += NSAlternateKeyMask;
	if (carbonFlags & controlKey) cocoaFlags += NSControlKeyMask;
	if (carbonFlags & shiftKey) cocoaFlags += NSShiftKeyMask;
	
	return cocoaFlags;
}

//---------------------------------------------------------- 
// SRCocoaToCarbonFlags()
//---------------------------------------------------------- 
unsigned int SRCocoaToCarbonFlags( unsigned int cocoaFlags )
{
	unsigned int carbonFlags = ShortcutRecorderEmptyFlags;
	
	if (cocoaFlags & NSCommandKeyMask) carbonFlags += cmdKey;
	if (cocoaFlags & NSAlternateKeyMask) carbonFlags += optionKey;
	if (cocoaFlags & NSControlKeyMask) carbonFlags += controlKey;
	if (cocoaFlags & NSShiftKeyMask) carbonFlags += shiftKey;
	
	return carbonFlags;
}

#pragma mark -
#pragma mark additions

@implementation NSBezierPath( SRAdditions )

//---------------------------------------------------------- 
// + bezierPathWithSRCRoundRectInRect:radius:
//---------------------------------------------------------- 
+ (NSBezierPath*)bezierPathWithSRCRoundRectInRect:(NSRect)aRect radius:(float)radius
{
	NSBezierPath* path = [self bezierPath];
	radius = MIN(radius, 0.5f * MIN(NSWidth(aRect), NSHeight(aRect)));
	NSRect rect = NSInsetRect(aRect, radius, radius);
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMinY(rect)) radius:radius startAngle:180.0 endAngle:270.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMinY(rect)) radius:radius startAngle:270.0 endAngle:360.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(rect), NSMaxY(rect)) radius:radius startAngle:  0.0 endAngle: 90.0];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(rect), NSMaxY(rect)) radius:radius startAngle: 90.0 endAngle:180.0];
	[path closePath];
	return path;
}

@end

@implementation NSError( SRAdditions )

- (NSString *)localizedDescription
{
	return [[self userInfo] objectForKey:@"NSLocalizedDescriptionKey"];
}

- (NSString *)localizedFailureReason
{
	return [[self userInfo] objectForKey:@"NSLocalizedFailureReasonErrorKey"];
}

- (NSString *)localizedRecoverySuggestion
{
	return [[self userInfo] objectForKey:@"NSLocalizedRecoverySuggestionErrorKey"];	
}

- (NSArray *)localizedRecoveryOptions
{
	return [[self userInfo] objectForKey:@"NSLocalizedRecoveryOptionsKey"];
}

@end

@implementation NSAlert( SRAdditions )

//---------------------------------------------------------- 
// + alertWithNonRecoverableError:
//---------------------------------------------------------- 
+ (NSAlert *) alertWithNonRecoverableError:(NSError *)error;
{
	NSString *reason = [error localizedRecoverySuggestion];
	return [self alertWithMessageText:[error localizedDescription]
						defaultButton:[[error localizedRecoveryOptions] objectAtIndex:0U]
					  alternateButton:nil
						  otherButton:nil
			informativeTextWithFormat:(reason ? reason : @"")];
}

@end
