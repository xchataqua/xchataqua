//
//  UserListTableView.m
//  XChatAqua
//
//  Created by Jeong YunWon on 12. 6. 14..
//  Copyright (c) 2012 youknowone.org All rights reserved.
//

#import "UserListTableView.h"
#import "ChatViewController.h"

@implementation UserListTableView

- (void)rightMouseDown:(NSEvent *)theEvent
{
    NSInteger clickedRow = [self rowAtPoint:[self convertPoint:[theEvent locationInWindow] fromView:nil]];
    if (![self isRowSelected:clickedRow])
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:clickedRow] byExtendingSelection:NO];
    [super rightMouseDown:theEvent];
}

/* CL: let the delegate handle this */
- (NSMenu *)menuForEvent:(NSEvent *)theEvent
{
    NSIndexSet *selectedRows = [self selectedRowIndexes];
    if ([selectedRows count] == 0) return [super menuForEvent:theEvent];
    ChatViewController *delegate = (id)self.delegate;
    if ([delegate respondsToSelector:@selector(menuForEvent:rowIndexes:)])
        return [delegate menuForEvent:theEvent rowIndexes:selectedRows];
    return [super menuForEvent:theEvent];
}

@end

#pragma mark -

@implementation UserlistButton
@synthesize popup;

- (id) initWithPopup:(struct popup *) pop
{
    if ((self = [super init]) != nil) {
        self->popup = pop;
        
        [self setButtonType:NSMomentaryPushButton];
        [self setTitle:[NSString stringWithUTF8String:popup->name]];
        [self setFont:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]];
        [[self cell] setControlSize:NSSmallControlSize];
        [self setImagePosition:NSNoImage];
        [self setBezelStyle:NSTexturedSquareBezelStyle];
        [self sizeToFit];
    }
    return self;
}

+ (UserlistButton *) buttonWithPopup:(struct popup *)popup {
    return [[[self alloc] initWithPopup:popup] autorelease];
}

@end
