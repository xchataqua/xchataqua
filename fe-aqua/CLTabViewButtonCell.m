/* CLTabViewButtonCell
 * Copyright (C) 2006 Camillo Lugaresi
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA */

/*
 CLTabViewButtonCell.m
 Created by Camillo Lugaresi on 15/01/06.
 This class implements the SGTabViewButtonCell API using a CLTabCell, which
 is theme-compliant.
 */

#import "CLTabViewButtonCell.h"

enum {
    kMyCloseButtonGap = 3,
    kMyCloseButtonHOffset = 4,
    kMyCloseButtonVOffset = 0,
    kMyTabHMarginAdjust = -4
};

@implementation CLTabViewButtonCell

- (void) dealloc
{
    [closeCell release];
    [super dealloc];
}

- (void)updatePosition
{
    if (hasLeftCap) {
        if (hasRightCap) [self setPosition:kHIThemeSegmentPositionOnly];
        else [self setPosition:kHIThemeSegmentPositionFirst];
    } else {
        if (hasRightCap) [self setPosition:kHIThemeSegmentPositionLast];
        else [self setPosition:kHIThemeSegmentPositionMiddle];
    }
}

- (void) setHasCloseButton:(BOOL)has
{
    if (hasCloseCell == has) return;
    hasCloseCell = has;
    if (hasCloseCell && !closeCell) {
        closeCell = [[NSButtonCell alloc] initImageCell:[NSImage imageNamed:@"CLclose13.tiff"]];
        [closeCell setButtonType:NSMomentaryLightButton];
        [closeCell setImagePosition:NSImageOnly];
        [closeCell setBordered:false];
        [closeCell setHighlightsBy:NSContentsCellMask];
        [closeCell setTarget:closeTarget]; /* these might have been set before the closeCell existed */
        [closeCell setAction:closeAction];
    } else if (!hasCloseCell && closeCell) {
        [closeCell release];
        closeCell = nil;
    }
    closeRectValid = NO;
}

- (void) setHasLeftCap:(BOOL)left
{
    hasLeftCap = left;
    [self updatePosition];
}

- (void) setHasRightCap:(BOOL)right
{
    hasRightCap = right;
    [self updatePosition];
}

- (void) setCloseAction:(SEL)action
{
    closeAction = action;
    [closeCell setAction:action];
}

- (void) setCloseTarget:(id)target
{
    closeTarget = target;
    [closeCell setTarget:target];
}

- (void) doClose:(id)sender
{
    [closeTarget performSelector:closeAction];
}

- (void) setTitleColor:(NSColor *)color
{
    NSMutableAttributedString *attrTitle = [[self attributedTitle] mutableCopy];
    [attrTitle beginEditing];
    [attrTitle removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, [attrTitle length])];
    if (color) [attrTitle addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, [attrTitle length])];
    [attrTitle endEditing];
    [self setAttributedTitle:attrTitle];
    [attrTitle release];
}

- (void) setTitle:(NSString *) aString
{
    [super setTitle:aString];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if (!closeRectValid) [self calcDrawInfo:cellFrame];
    [super drawWithFrame:cellFrame inView:controlView];
}

- (NSSize)contentSize
{
    NSSize size = [[self attributedTitle] size];
    if (hasCloseCell) {
        NSSize close_size = [closeCell cellSize];
        size.width += close_size.width + kMyCloseButtonGap;
    }
    size.width += kMyTabHMarginAdjust * 2;
    return size;
}

- (void)drawContentInRect:(NSRect)contentFrame inView:(NSView *)controlView
{
    if (hasCloseCell) {
        NSSize close_size = [closeCell cellSize];
        
        NSDivideRect(contentFrame, &closeRect, &contentFrame, close_size.width + kMyCloseButtonGap, NSMinXEdge);
        closeRect.size = close_size;
        closeRect.origin.y = contentFrame.origin.y + floor((contentFrame.size.height - close_size.height) / 2) + kMyCloseButtonVOffset;
        closeRect.origin.x += kMyCloseButtonHOffset;
        [closeCell drawWithFrame:closeRect inView:controlView];
    }
    closeRectValid = YES;
    [super drawContentInRect:contentFrame inView:controlView];
}

- (void)mouseDown:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView
{
    NSCell *trackCell;
    NSRect trackFrame;
    
    if (!closeRectValid) {
        [self drawWithFrame:cellFrame inView:controlView]; /* the content rect is only accessible inside drawWithFrame:inView: */
    }
    if (hasCloseCell && NSMouseInRect([controlView convertPoint:[theEvent locationInWindow] fromView:nil],
                                      closeRect, [controlView isFlipped]))
    {
        trackCell = closeCell;
        trackFrame = closeRect;
    } else {
        if ([self state] == NSOnState) return;
        trackCell = self;
        trackFrame = cellFrame;
    }
    
    do {
        if (NSMouseInRect([controlView convertPoint:[theEvent locationInWindow] fromView:nil], trackFrame, [controlView isFlipped])) {
            [trackCell highlight:YES withFrame:trackFrame inView:controlView];
            BOOL activated = [trackCell trackMouse:theEvent inRect:trackFrame ofView:controlView untilMouseUp:NO];
            [trackCell highlight:NO withFrame:trackFrame inView:controlView];
            if (activated) break;
        }
        theEvent = [[controlView window] nextEventMatchingMask:NSLeftMouseUpMask | NSLeftMouseDraggedMask];
        if ([theEvent type] == NSLeftMouseUp)
            break;
    } while (1);
}

- (void) setHideCloseButton:(bool) hideit
{
    [self setHasCloseButton:!hideit];
}

- (void) mouseDown:(NSEvent *) e
       controlView:(NSView *) controlView
{
    [self mouseDown:e inRect:[controlView bounds] ofView:controlView];
}

@end