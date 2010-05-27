/* X-Chat Aqua
 * Copyright (C) 2002 Steve Green
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

#import "SG.h"

@implementation SGTableView

- (id) initWithFrame:(NSRect) frameRect
{
    [super initWithFrame:frameRect];
    timer = nil;
    return self;
}

- (void) dealloc
{
    if (timer)
    {
        [timer invalidate];
        [timer release];
    }
    [super dealloc];
}

- (void) sizeFixups:(id) sender
{
    [timer release];
    timer = nil;

    id col = [[self tableColumns] lastObject];
    id cell = [col dataCell];
    
    float width = 0;
    float height = 16;
    
    id datasource = [self dataSource];
    bool do_hints = [datasource respondsToSelector:@selector(tableView:sizeHintForTableColumn:row:)];
    
    for (int i = 0; i < [self numberOfRows]; i ++)
    {
        NSSize sz = NSZeroSize;
        
        if (do_hints)
            sz = [datasource tableView:self sizeHintForTableColumn:nil row:i];
            
        if (sz.width == 0 && sz.height == 0)
        {
            id val = [[self dataSource] tableView:self objectValueForTableColumn:col row:i];
            [cell setObjectValue:val];
            sz = [cell cellSize];
            
            if (do_hints)
                [datasource tableView:self sizeHintForTableColumn:nil row:i size:sz];
        }
        
        if (sz.width > width)
            width = sz.width;
        if (sz.height > height)
            height = sz.height;
    }
    
    [col setWidth:width];
    if (height != [self rowHeight])
        [self setRowHeight:height];
}

- (void) startTimer
{
    id datasource = [self dataSource];
    bool do_fixups = [datasource respondsToSelector:@selector(shouldDoSizeFixupsForTableView:)] &&
		[datasource performSelector:@selector(shouldDoSizeFixupsForTableView:) withObject:self];
	if (!do_fixups)
		return;

    if (!timer)
        timer = [[NSTimer scheduledTimerWithTimeInterval:1
                            target:self
                            selector:@selector(sizeFixups:)
                            userInfo:nil
                            repeats:NO
                            retainArgs:NO] retain];
}

- (void) reloadData
{
	[self startTimer];
    [super reloadData];
}

-(void) textDidEndEditing:(NSNotification*) notification 
{
	if ([[[notification userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement)
	{
		NSMutableDictionary *newUserInfo = [NSMutableDictionary dictionaryWithDictionary:[notification userInfo]];
		[newUserInfo setObject:[NSNumber numberWithInt:NSIllegalTextMovement] forKey:@"NSTextMovement"];
		notification = [NSNotification notificationWithName:[notification name]
						  object:[notification object] 
						userInfo:newUserInfo];
		[super textDidEndEditing:notification];
		[[self window] makeFirstResponder:self];
		[self startTimer];
	}
	else
		[super textDidEndEditing:notification];
}

@end