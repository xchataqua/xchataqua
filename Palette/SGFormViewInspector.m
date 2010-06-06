/* X-Chat Aqua
 * Copyright (C) 2005-2009 Steve Green
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

#import "SGFormViewInspector.h"
#import "SG.h"

@interface NSMenu (SGFormViewInspectorAdditions)
- (void) addSGFormViewInspectorMenuItem:(NSString *)title selector:(SEL)selector target:(id)target tag:(NSInteger)tag;
@end
@implementation NSMenu (SGFormViewInspectorAdditions)
- (void) addSGFormViewInspectorMenuItem:(NSString *)title selector:(SEL)selector target:(id)target tag:(NSInteger)tag
{
	NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""] autorelease];
	[item setTarget:target];
	[item setTag:tag];
	[self addItem:item];
}
@end

@implementation SGFormViewInspector

- (NSString *)viewNibName
{
    return @"SGFormViewInspector";
}

- (void) awakeFromNib
{
    connectionMenus[SGFormViewEdgeLeft] = leftConnectionMenu;
    connectionMenus[SGFormViewEdgeTop] = topConnectionMenu;
    connectionMenus[SGFormViewEdgeRight] = rightConnectionMenu;
    connectionMenus[SGFormViewEdgeBottom] = bottomConnectionMenu;

    relativeMenus[SGFormViewEdgeLeft] = leftRelativeMenu;
    relativeMenus[SGFormViewEdgeTop] = topRelativeMenu;
    relativeMenus[SGFormViewEdgeRight] = rightRelativeMenu;
    relativeMenus[SGFormViewEdgeBottom] = bottomRelativeMenu;

    offsetTexts[SGFormViewEdgeLeft] = leftOffsetText;
    offsetTexts[SGFormViewEdgeTop] = topOffsetText;
    offsetTexts[SGFormViewEdgeRight] = rightOffsetText;
    offsetTexts[SGFormViewEdgeBottom] = bottomOffsetText;

    for (NSInteger edge = 0; edge < SGFormViewEdgeCount; ++edge)
    {
        // This order matches the value of the Enum
        NSMenu *connectionMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
		[connectionMenu addSGFormViewInspectorMenuItem:@"None"     selector:@selector(doConstrain:) target:self tag:SGFormViewAttachmentNone];
		[connectionMenu addSGFormViewInspectorMenuItem:@"Form"     selector:@selector(doConstrain:) target:self tag:SGFormViewAttachmentForm];
		[connectionMenu addSGFormViewInspectorMenuItem:@"View"     selector:@selector(doConstrain:) target:self tag:SGFormViewAttachmentView];
		[connectionMenu addSGFormViewInspectorMenuItem:@"Opposite" selector:@selector(doConstrain:) target:self tag:SGFormViewAttachmentOppositeView];
		[connectionMenu addSGFormViewInspectorMenuItem:@"Center"   selector:@selector(doConstrain:) target:self tag:SGFormViewAttachmentCenter];
        [connectionMenus[edge] setMenu:connectionMenu];
    }
}

- (NSMenu *) makeRelativeMenu:(SGFormView *)form
{
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
	[menu addSGFormViewInspectorMenuItem:@"None" selector:@selector(doConstrain:) target:self tag:0];
    NSArray *views = form.subviews;
    for (NSUInteger i = 0; i < [views count]; i ++)
    {
        NSView *view = [views objectAtIndex:i];
        NSString *ident = [form identifierForView:view];
        if (ident && [ident length] > 0)
			[menu addSGFormViewInspectorMenuItem:ident selector:@selector(doConstrain:) target:self tag:0];
    }

    return menu;
}

- (void)refresh
{
    NSArray * objects = [self inspectedObjects];
	
    if ([objects count] == 1)
    {
        NSView *view = [objects objectAtIndex:0];
        SGFormView *form = (SGFormView *)[view superview];

        NSString *ident = [form identifierForView:view];
		if ( nil == ident ) ident = @"";
        [identifierText setStringValue:ident];

        for (NSInteger edge = 0; edge < SGFormViewEdgeCount; ++edge)
        {
            SGFormViewAttachment attachment_return;
            NSView *view_return;
            CGFloat offset_return;

            BOOL got_it = [form constraintsForEdge:view
                                              edge:(SGFormViewEdge)edge
                                        attachment:&attachment_return
                                        relativeTo:&view_return
                                            offset:&offset_return];

            NSMenu *menu = [self makeRelativeMenu:form];
            [relativeMenus[edge] setMenu:menu];

            if (got_it)
            {
                [offsetTexts[edge] setIntValue:offset_return];
                [connectionMenus[edge] selectItemWithTag:attachment_return];

                if (view_return)
                {
                    NSString *relative = [form identifierForView:view_return];
                    //NSLog (@"V %d %x %x", edge, view_return, relative);
                    [relativeMenus[edge] selectItemWithTitle:relative];
                }
                else
                    [relativeMenus[edge] selectItemAtIndex:0];
            }
            else
            {
                [offsetTexts[edge] setStringValue:@""];
                [connectionMenus[edge] selectItemWithTag:SGFormViewAttachmentNone];
            }
        }
    }
    else
    {
        [identifierText setStringValue:@""];
        for (NSInteger edge = 0; edge < SGFormViewEdgeCount; ++edge)
        {
            [relativeMenus[edge] selectItemAtIndex:0];
        }
    }
    [super refresh];
}

- (void) doConstrain:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSUInteger numObjects = [objects count];

    for(NSUInteger i = 0; i < numObjects; ++i)
    {
        NSView *view = [objects objectAtIndex:i];
        SGFormView *form = (SGFormView*)[view superview];

        for (NSInteger edge = 0; edge < SGFormViewEdgeCount; edge ++)
        {
            SGFormViewAttachment conn = (SGFormViewAttachment)
            [[connectionMenus[edge] selectedItem] tag];
            NSInteger offset = [offsetTexts[edge] integerValue];
            NSView *relative = nil;

            if ([relativeMenus[edge] indexOfSelectedItem] > 0)
            {
                NSString *relative_ident = [relativeMenus[edge] titleOfSelectedItem];

                NSArray *views = [form subviews];
                for (NSUInteger i = 0; i < [views count]; i ++)
                {
                    NSView *view = [views objectAtIndex:i];
                    NSString *ident = [form identifierForView:view];
                    if (ident && [ident length] > 0 && [ident isEqualToString:relative_ident])
                    {
                        relative = view;
                        break;
                    }
                }
            }

            //NSLog (@"%x %d %d %d", view, edge, conn, offset);

            if ((conn == SGFormViewAttachmentView ||
				 conn == SGFormViewAttachmentOppositeView) && relative == nil)
            {
                conn = SGFormViewAttachmentNone;
            }

            [form constrain:view
                       edge:(SGFormViewEdge) edge
                 attachment:conn
                 relativeTo:relative
                     offset:offset];
        }
    }
}

- (void) doIdentifier:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count];

    for(NSInteger i = 0; i < numObjects; ++i)
    {
        NSView *view = [objects objectAtIndex:i];
        SGFormView *form = (SGFormView*)[view superview];

        [form setIdentifier:[sender stringValue] forView:view];
    }
}


@end
