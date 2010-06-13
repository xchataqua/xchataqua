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

/////////////////////////////////////////////////////////////////////////////

@implementation SGLockableTextFieldCell
@synthesize lockImage;
@synthesize unlockImage;
@synthesize lockCell;

- (id)initTextCell:(NSString *)aString
{
	self = [super initTextCell:aString];

  self.lockImage   = [NSImage imageNamed:@"lock.tiff"];
  self.unlockImage = [NSImage imageNamed:@"unlock.tiff"];

	return self;
}

/*
 * ???: Do we really need explicit dealloc here?
 */
- (void) dealloc 
{
  [self.lockCell release];
  [self.lockImage release];
  [self.unlockImage release];
  [super dealloc];
}

/*
 * ???: Why do we need to implement copyWithZone:?
 */
-(SGLockableTextFieldCell *) copyWithZone:(NSZone *) zone
{
  SGLockableTextFieldCell *cell = [super copyWithZone:zone];
  cell.lockCell = [self.lockCell copyWithZone:zone];
  return cell;
}

/*
 * Convenience method to tell us whether the current state is locked or unlocked.
 *
 * This is only needed because NSButtonCell's state: method returns an integer
 * constant rather than a BOOL type; or we'd have just tested that directly.
 */
- (BOOL) isLocked
{
  return ([lockCell state] == NSOffState ? YES : NO);
}

- (void) doLock:(id) sender
{
	if ([self isLocked])
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
	
	[super setEditable:(isEditable && ![self isLocked])];
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

- (void) setLocked:(BOOL)shouldLock
{
	[self.lockCell setState:(shouldLock ? NSOffState : NSOnState)];

    // This may not actually set us as editable.
    // We just need it to add/remove the lock icon
  [self setEditable:YES];
}

@end

/*
 * MARK: -
 */
@implementation SGLockableTextField
@synthesize prevValue;

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
	[super dealloc]; // ???: Do we really need to explicitly call super's dealloc?
}

- (id) initWithFrame:(NSRect)frameRect
{
	self = [super initWithFrame:frameRect];
	[self privateInit];
	[self calcSize];
	return self;
}

/*
 * IB is going to try to stuff the wrong cell down our throats.
 * This is really sneaky, but short of creating a palette for this view,
 * I don't know another way.
 */
- (id) initWithCoder:(NSCoder *) decoder
{
	self = [super initWithCoder:decoder];
	[self privateInit];
	[self calcSize];
	return self;
}

/*
 * Called when user (typically) sets focus in the text field.
 */
- (void) textDidBeginEditing:(NSNotification *) aNotification
{
  id currentVal = [self objectValue];
  if (currentVal == nil)	// This is pure paranoia. We depend on non-null prev
    currentVal = @"";   	// values below. This guarantees it.
  self.prevValue = [currentVal retain];
  [super textDidBeginEditing:aNotification];
}

/*
 * NSTextField delegate selector to handle key-press events for “special” keys
 * like insertNewline: (return), insertTab:, etc.
 */
- (BOOL) textView:(NSTextView *) textView doCommandBySelector:(SEL) command
{
    // If the user presses return, we don't want the previous value anymore.
  if (command == @selector (insertNewline:))
  {
    [self.prevValue release];
    self.prevValue = nil;
  }
    // NO means we didn't handle the key pressed, so the field editor should
    // keep passing it through the responder chain until something does. This
    // means, from our point of view: “Give us the default behavior.”
  return NO;
}

/*
 * Called by NSAlert after the user dismisses the confirmation sheet.
 *
 * Sets topic, cancels the change, or returns the user to editing, depending on
 * which button he pushed.
 *
 */
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
  if (returnCode == NSAlertThirdButtonReturn) { // Don't Save.
    [self setObjectValue:self.prevValue];
    [self abortEditing];
    [[self window] selectNextKeyView:self];
    [[self cell] setLocked:YES];
  } else if (returnCode == NSAlertFirstButtonReturn) { // OK
    [self.prevValue release];
    self.prevValue = nil;
    [NSApp sendAction:self.action to:self.target from:self];
    [[self window] selectNextKeyView:self];
  } else if (returnCode == NSAlertSecondButtonReturn) { // Cancel.
      // Cancel means to stay in the text field, and since we returned NO from
      // the textShouldEndEditing: selector earlier, no action is needed here.
  }
}

/*
 * Invoked when a user action (typically) moves focus away from the text field.
 *
 * This is where we check what is entered, and possibly ask for confirmation
 * that the user really wants to set the topic.
 *
 */
- (BOOL) textShouldEndEditing:(NSText *) aTextObject
{
    // If it didn't change, just end editing.
	if (!self.prevValue || [[self objectValue] isEqual:self.prevValue])
		return YES;

    // Otherwise, since the text changed but the user didn't hit return, put up
    // a confirmation dialog to let him pick which action to take.
  NSAlert *alert = [[[NSAlert alloc] init] autorelease];
  [alert addButtonWithTitle:NSLocalizedStringFromTable(@"OK", @"xchataqua", @"")];
  [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Cancel", @"xchataqua", @"")];
  [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Don't Save", @"xchataqua", @"")];
  [alert setMessageText:NSLocalizedStringFromTable(@"Do you want to set the topic?", @"xchataqua", @"")];
  [alert setInformativeText:NSLocalizedStringFromTable(@"You have changed the topic. Do you want to save the changes and set the topic for this channel?", @"xchataqua", @"")];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];

    // Return NO so the focus stays on the text field. We'll remove focus from
    // the alertDidEnd:returnCode:contextInfo: selector if appropriate.
	return NO;
}

- (void) textDidEndEditing:(NSNotification *) notif
{
  [self.prevValue release];
  self.prevValue = nil;
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

/*
 * Selector called by the app delegate to check whether we accept First Responder
 * status.
 *
 * Seems like the answer should be YES, but it's a little more complicated.
 *
 * From inspection (i.e. guessing), it looks like the following is happening:
 * When the field editor is over us, and someone clicks on the lock, NSWindow
 * will try to take the first responder away from the field editor, and assign
 * it to us... which will end up being a no-op since the field editor will
 * get the first responder status again.  Unfortunately, when we give up first
 * responder, textDidEndEditing() gets called, which we don't want!
 *
 * If the field editor has first responder, and the field editor is over us,
 * then tell NSWindow we don't accept first responder!
*/
- (BOOL) acceptsFirstResponder
{
  NSTextView *resp = (NSTextView *) [[self window] firstResponder];

  return ! ([resp isKindOfClass:[NSTextView class]] &&
            [[self window] fieldEditor:NO forObject:nil] &&
            (SGLockableTextField *)[resp delegate] == self);
}

/*
 * Only accept First Responder status if the text field is unlocked.
 */
- (BOOL) becomeFirstResponder
{
  return ! [[self cell] isLocked];
}

@end
