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
 CLTabViewButtonCell.h
 Created by Camillo Lugaresi on 15/01/06.
 This class implements the SGTabViewButtonCell API using a CLTabCell, which
 is theme-compliant.
 */

#import <Cocoa/Cocoa.h>
#import "CLTabCell.h"

@interface CLTabViewButtonCell : CLTabCell {
    BOOL hasCloseCell;
    BOOL hasLeftCap;
    BOOL hasRightCap;
    NSButtonCell *closeCell;
    NSRect closeRect;
    BOOL closeRectValid;
    SEL closeAction;
    id closeTarget;
}

- (void)setHasCloseButton:(BOOL)has;
- (void)setHasLeftCap:(BOOL)left;
- (void)setHasRightCap:(BOOL)right;
- (void)setCloseAction:(SEL)action;
- (void)setCloseTarget:(id)target;
- (void)doClose:(id)sender;
- (void)setTitleColor:(NSColor *)color;
- (void)mouseDown:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(NSView *)controlView;

@end

