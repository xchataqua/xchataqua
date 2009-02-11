//
//  SRRecorderCell.h
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
#import "SRCommon.h"

#define SRMinWidth 50
#define SRMaxHeight 22

@class SRRecorderControl, CTGradient, SRValidator;

@interface SRRecorderCell : NSActionCell <NSCoding>
{	
	CTGradient          *recordingGradient;
	NSString            *autosaveName;

	BOOL                isRecording;
	BOOL                mouseInsideTrackingArea;
	BOOL                mouseDown;
	
	NSTrackingRectTag   removeTrackingRectTag;
	NSTrackingRectTag   snapbackTrackingRectTag;
	
	KeyCombo            keyCombo;
	
	unsigned int        allowedFlags;
	unsigned int        requiredFlags;
	unsigned int        recordingFlags;
	
	NSSet               *cancelCharacterSet;
	
    SRValidator         *validator;
    
	IBOutlet id         delegate;
}

- (void)resetTrackingRects;

#pragma mark *** Delegate ***

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
 
#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;

- (unsigned int)allowedFlags;
- (void)setAllowedFlags:(unsigned int)flags;

- (unsigned int)requiredFlags;
- (void)setRequiredFlags:(unsigned int)flags;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)aKeyCombo;

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)aName;

// Returns the displayed key combination if set
- (NSString *)keyComboString;

@end

// Delegate Methods
@interface NSObject (SRRecorderCellDelegate)
- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason;
- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newCombo;
@end
