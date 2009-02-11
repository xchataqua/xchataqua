//
//  SRCommon.h
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

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>

#pragma mark -
#pragma mark dummy class 

@interface SRDummyClass : NSObject {} @end

#pragma mark -
#pragma mark typedefs

typedef struct _KeyCombo {
	unsigned int flags; // 0 for no flags
	signed short code; // -1 for no code
} KeyCombo;

#pragma mark -
#pragma mark enums

// Unicode values of some keyboard glyphs
enum {
	KeyboardTabRightGlyph       = 0x21E5,
	KeyboardTabLeftGlyph        = 0x21E4,
	KeyboardCommandGlyph        = kCommandUnicode,
	KeyboardOptionGlyph         = kOptionUnicode,
	KeyboardShiftGlyph          = kShiftUnicode,
	KeyboardControlGlyph        = kControlUnicode,
	KeyboardReturnGlyph         = 0x2305,
	KeyboardReturnR2LGlyph      = 0x21A9,	
	KeyboardDeleteLeftGlyph     = 0x232B,
	KeyboardDeleteRightGlyph    = 0x2326,	
	KeyboardPadClearGlyph       = 0x2327,
    KeyboardLeftArrowGlyph      = 0x2190,
	KeyboardRightArrowGlyph     = 0x2192,
	KeyboardUpArrowGlyph        = 0x2191,
	KeyboardDownArrowGlyph      = 0x2193,
    KeyboardPageDownGlyph       = 0x21DF,
	KeyboardPageUpGlyph         = 0x21DE,
	KeyboardNorthwestArrowGlyph = 0x2196,
	KeyboardSoutheastArrowGlyph = 0x2198,
	KeyboardEscapeGlyph         = 0x238B,
	KeyboardHelpGlyph           = 0x003F,
	KeyboardUpArrowheadGlyph    = 0x2303,
};

#pragma mark -
#pragma mark macros

// Localization macros, for use in any bundle
#define SRLoc(key) SRLocalizedString(key, nil)
#define SRLocalizedString(key, comment) NSLocalizedStringFromTableInBundle(key, nil, [NSBundle bundleForClass: [SRDummyClass class]], comment)

// Image macros, for use in any bundle
#define SRImage(name) [[[NSImage alloc] initWithContentsOfFile: [[NSBundle bundleForClass: [self class]] pathForImageResource: name]] autorelease]

// Macros for glyps
#define SRInt(x) [NSNumber numberWithInt: x]
#define SRChar(x) [NSString stringWithFormat: @"%C", x]

// Some default values
#define ShortcutRecorderEmptyFlags 0
#define ShortcutRecorderAllFlags ShortcutRecorderEmptyFlags + (NSCommandKeyMask + NSAlternateKeyMask + NSControlKeyMask + NSShiftKeyMask)
#define ShortcutRecorderEmptyCode -1

// These keys will cancel the recoding mode if not pressed with any modifier
#define ShortcutRecorderEscapeKey 53
#define ShortcutRecorderBackspaceKey 51
#define ShortcutRecorderDeleteKey 117

#pragma mark -
#pragma mark functions

#ifdef __cplusplus
extern "C" {
#endif
NSString * SRStringForKeyCode( signed short keyCode );
NSString * SRStringForCarbonModifierFlags( unsigned int flags );
NSString * SRStringForCarbonModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode );
NSString * SRStringForCocoaModifierFlags( unsigned int flags );
NSString * SRStringForCocoaModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode );
NSString * SRReadableStringForCarbonModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode );
NSString * SRReadableStringForCocoaModifierFlagsAndKeyCode( unsigned int flags, signed short keyCode );
unsigned int SRCarbonToCocoaFlags( unsigned int carbonFlags );
unsigned int SRCocoaToCarbonFlags( unsigned int cocoaFlags );
#ifdef __cplusplus
}
#endif

#pragma mark -
#pragma mark inlines

FOUNDATION_STATIC_INLINE KeyCombo SRMakeKeyCombo(signed short code, unsigned int flags) {
	KeyCombo kc;
	kc.code = code;
	kc.flags = flags;
	return kc;
}

#pragma mark -
#pragma mark additions

//
// This segment is a category on NSBezierPath to supply roundrects. It's a common thing if you're drawing,
// so to integrate well, we use an oddball method signature to not implement the same method twice.
//
// This code is originally from http://www.cocoadev.com/index.pl?RoundedRectangles and no license demands
// (or Copyright demands) are stated, so we pretend it's public domain. 
//
@interface NSBezierPath( SRAdditions )
+ (NSBezierPath*)bezierPathWithSRCRoundRectInRect:(NSRect)aRect radius:(float)radius;
@end

@interface NSError( SRAdditions )
- (NSString *)localizedFailureReason;
- (NSString *)localizedRecoverySuggestion;
- (NSArray *)localizedRecoveryOptions;
@end

@interface NSAlert( SRAdditions )
+ (NSAlert *) alertWithNonRecoverableError:(NSError *)error;
@end
