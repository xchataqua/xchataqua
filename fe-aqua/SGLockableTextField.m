/* X-Chat Aqua
 * Copyright (C) 2006 Steve Green
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */


#import "SGGuiUtil.h"
#import "SGAlert.h"
#import "SGLockableTextField.h"

@interface SGLockableTextFieldCell : NSTextFieldCell
{
	NSButtonCell *lockCell;
	BOOL		  tracking_lock;
}

@property (nonatomic, assign) BOOL locked;
@property (nonatomic, readonly) NSImage *lockImage, *unlockImage;

@end

/////////////////////////////////////////////////////////////////////////////

@implementation SGLockableTextFieldCell

- (NSImage *) lockImage
{
	static NSImage *lockImage;
	if (!lockImage)
	    lockImage = [NSImage imageNamed:@"lock.tiff"];
	return lockImage;
}

- (NSImage *) unlockImage
{
	static NSImage *unlockImage;
	if (!unlockImage)
	    unlockImage = [NSImage imageNamed:@"unlock.tiff"];
	return unlockImage;
}

- (id)initTextCell:(NSString *)aString
{
	self = [super initTextCell:aString];

	return self;
}

- (void) dealloc 
{
    [lockCell release];
    [super dealloc];
}

-(SGLockableTextFieldCell *) copyWithZone:(NSZone *) zone
{
    SGLockableTextFieldCell *cell = [super copyWithZone:zone];
    cell->lockCell = [lockCell copyWithZone:zone];
    return cell;
}

- (BOOL) locked
{
	return lockCell && [lockCell integerValue] == 0;
}

- (void) doLock:(id) sender
{
	if ([self locked])
	{
		// If the field editor has focus, and the field editor is for us,
		// then commit our changes and move to the next field.
		
		NSWindow *win = [[self controlView] window];
		NSTextView *responder = (NSTextView *)[win firstResponder];
		if ([responder isKindOfClass:[NSTextView class]] &&
			[win fieldEditor:NO forObject:nil] &&
			(NSView *)[responder delegate] == [self controlView])
		{
			[win selectKeyViewFollowingView:[self controlView]];
		}
	}
	
	// We're already supposed to be editable or the lock button wouldn't be there,
	// but we may need to actually become editable, or give up editable based on
	// the lock state.
	[self setEditable:YES];
}

- (void) setEditable:(BOOL) isEditable
{
	if (isEditable)
	{
		if (!lockCell)
		{
			lockCell = [[NSButtonCell alloc] initImageCell:self.lockImage];
			[lockCell setAlternateImage:self.unlockImage];
			[lockCell setButtonType:NSToggleButton];
			[lockCell setImagePosition:NSImageOnly];
			[lockCell setBordered:NO];
			[lockCell setHighlightsBy:NSContentsCellMask];
			[lockCell setTarget:self];
			[lockCell setAction:@selector(doLock:)];
		}
	}
	else
	{
		[lockCell release];
		lockCell = nil;
	}
	
	[(NSControl *)[self controlView] calcSize];
	[[self controlView] setNeedsDisplay:YES];
	
	[super setEditable:isEditable && ![self locked]];
}

- (void) computeTextFrame:(NSRect *) textFrame
			 andLockFrame:(NSRect *) lockFrame
			fromCellFrame:(NSRect) aRect
{
	if (!lockCell)
	{
		*textFrame = aRect;
		return;
	}
		
	NSSize lockSize = [lockCell cellSize];
    NSDivideRect (aRect, lockFrame, textFrame, 3 + lockSize.width, NSMinXEdge);
	lockFrame->origin.x += 3.0f;
	lockFrame->origin.y += floor ((aRect.size.height - lockSize.height) / 2);
	lockFrame->size = lockSize;
}

- (NSRect) drawingRectForBounds:(NSRect) theRect
{
    NSRect textFrame, lockFrame;
	[self computeTextFrame:&textFrame andLockFrame:&lockFrame fromCellFrame:theRect];
	return [super drawingRectForBounds:textFrame];
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView 
{
    NSRect textFrame, lockFrame;
	[self computeTextFrame:&textFrame andLockFrame:&lockFrame fromCellFrame:cellFrame];
	
	[super drawWithFrame:cellFrame inView:controlView];

	[lockCell drawWithFrame:lockFrame inView:controlView];
}

- (BOOL) mouseDown:(NSEvent *) theEvent
		 cellFrame:(NSRect) cellFrame
	   controlView:(NSView *) controlView
{
	NSPoint point = [theEvent locationInWindow];
    NSPoint where = [controlView convertPoint:point fromView:nil];

    NSRect textFrame, lockFrame;
	[self computeTextFrame:&textFrame andLockFrame:&lockFrame fromCellFrame:cellFrame];
		
    if (NSPointInRect (where, lockFrame))
	{
		[SGGuiUtil trackButtonCell:lockCell withEvent:theEvent inRect:lockFrame controlView:controlView];
		return YES;
	}
	
	return NO;
}

- (void) setLocked:(BOOL)locked
{
	[lockCell setIntValue:!locked];
	
	// This may not actually set us as editable.
	// We just need it to add/remove the lock icon
	[self setEditable:YES];
}

@end

/////////////////////////////////////////////////////////////////////////////

@implementation SGLockableTextField

+ (Class) cellClass
{
	return [SGLockableTextFieldCell class];
}

- (void) privateInit
{
	NSTextFieldCell *cell = [[SGLockableTextFieldCell alloc] initTextCell:@""];
	[cell setEditable:[self isEditable]];
	[cell setDrawsBackground:[self drawsBackground]];
	[cell setBordered:[self isBordered]];
	[cell setBezeled:[self isBezeled]];
	[cell setFont:[self font]];
	[cell setScrollable:YES];
	[self setCell:cell];
	[cell release];
}

- (void) dealloc
{
	[super dealloc];
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	[self privateInit];
	[self calcSize];
	return self;
}

// IB is going to try to stuff the wrong cell down our throats.
// This is really sneaky, but short of creating a palette for this view, I don't know another way.
- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];
	[self privateInit];
	[self calcSize];
	return self;
}

- (void) textDidBeginEditing:(NSNotification *) aNotification
{
	id currentVal = [self objectValue];
	if (currentVal == nil)	// This is pure paranoia.  We depend on non-null prev values
		currentVal = @"";	// below.  This guarantees it.
	prevValue = [currentVal retain];
	[super textDidBeginEditing:aNotification];
}

- (BOOL) textView:(NSTextView *) textView doCommandBySelector:(SEL) command
{
	// If the user presses return, we'll don't want the prev value
	if (command == @selector (insertNewline:))
	{
		[prevValue release];
		prevValue = nil;
	}
	
    return NO; // why this should be NO ?
}

- (BOOL) textShouldEndEditing:(NSText *) aTextObject
{
	if (!prevValue || [[self objectValue] isEqual:prevValue])
		return YES;
		
	NSInteger ret = NSRunAlertPanel(NSLocalizedStringFromTable(@"Confirm",@"xchataqua",@""),
									NSLocalizedStringFromTable(@"You have uncommited changes. Do you want to save the changes?",@"xchataqua",@""),
									NSLocalizedStringFromTable(@"Cancel",@"xchataqua",@""), NSLocalizedStringFromTable(@"Yes",@"xchataqua",@""), NSLocalizedStringFromTable(@"No",@"xchataqua",@""), nil);

	// If he doesn't want to save his changes, we need to put the old value in place, and then
	// let whatever key press action take effect (tab vs shift-tab vs mouse press, etc..).
	switch (ret) {
		case NSAlertOtherReturn: // No
			// Can't use abortEditing.. it seems to break the notifiction action.
			// i.e. Tab key doesn't move the next responder.
			//[self abortEditing];
			[self setObjectValue:prevValue];
			return YES;
		case NSAlertAlternateReturn: // YES
			return YES;	
		case NSAlertDefaultReturn: // Cancel
		default:
			[[self cell] setLocked:NO];
	}
	return NO;
}

- (void) textDidEndEditing:(NSNotification *) notif
{
	[prevValue release];
	prevValue = nil;
	[[self cell] setLocked:YES];
	[super textDidEndEditing:notif];
}

- (void) mouseDown:(NSEvent *)event
{
	// Track the lock
    if ([[self cell] mouseDown:event cellFrame:[self frame] controlView:self])
		return;
	
	// else...
	[super mouseDown:event];
}

- (BOOL) acceptsFirstResponder
{
	// Seems like the answer should be YES, but it's a little more complicated.
	//
	// From inspection (i.e. guessing), it looks like the following is happening:
	// When the field editor is over us, and someone clicks on the lock, NSWindow
	// will try to take the first responder away from the field editor, and assign
	// it to us... which will end up being a no-op since the field editor will
	// get the first responder status again.  Unfortunately, when we give up first
	// responder, textDidEndEditing() gets called, which we don't want!
	//
	// If the field editor has first responder, and the field editor is over us,
	// then tell NSWindow we don't accept first responder!
	
	NSTextView *resp = (NSTextView *) [[self window] firstResponder];
	
	return ! ([resp isKindOfClass:[NSTextView class]] &&
		      [[self window] fieldEditor:NO forObject:nil] &&
		      (SGLockableTextField *)[resp delegate] == self);
}

- (BOOL) becomeFirstResponder
{
	return ! [[self cell] locked];
}

@end
