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

static void addMenuItem (NSMenu *menu, NSString *title, SEL sel, id target, int tag)
{
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
                                                   action:sel
                                            keyEquivalent:@""] autorelease];
    [item setTarget:target];
    [item setTag:tag];
    [menu addItem:item];
}


@implementation SGFormViewInspector

- (NSString *)viewNibName
{
    return @"SGFormViewInspector";
}

- (void) awakeFromNib
{
    connectionMenus[SGFormView_EDGE_LEFT] = leftConnectionMenu;
    connectionMenus[SGFormView_EDGE_TOP] = topConnectionMenu;
    connectionMenus[SGFormView_EDGE_RIGHT] = rightConnectionMenu;
    connectionMenus[SGFormView_EDGE_BOTTOM] = bottomConnectionMenu;

    relativeMenus[SGFormView_EDGE_LEFT] = leftRelativeMenu;
    relativeMenus[SGFormView_EDGE_TOP] = topRelativeMenu;
    relativeMenus[SGFormView_EDGE_RIGHT] = rightRelativeMenu;
    relativeMenus[SGFormView_EDGE_BOTTOM] = bottomRelativeMenu;

    offsetTexts[SGFormView_EDGE_LEFT] = leftOffsetText;
    offsetTexts[SGFormView_EDGE_TOP] = topOffsetText;
    offsetTexts[SGFormView_EDGE_RIGHT] = rightOffsetText;
    offsetTexts[SGFormView_EDGE_BOTTOM] = bottomOffsetText;

    for (int i = 0; i < 4; ++i)
    {
        // This order matches the value of the Enum
        NSMenu *conn_menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
        addMenuItem (conn_menu, @"None", @selector(doConstrain:), self, SGFormView_ATTACH_NONE);
        addMenuItem (conn_menu, @"Form", @selector(doConstrain:), self, SGFormView_ATTACH_FORM);
        addMenuItem (conn_menu, @"View", @selector(doConstrain:), self, SGFormView_ATTACH_VIEW);
        addMenuItem (conn_menu, @"Opposite", @selector(doConstrain:), self, SGFormView_ATTACH_OPPOSITE_VIEW);
        addMenuItem (conn_menu, @"Center", @selector(doConstrain:), self, SGFormView_ATTACH_CENTER);
        [connectionMenus[i] setMenu:conn_menu];
    }
}

- (NSMenu *) makeRelativeMenu:(SGFormView *) form
{
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    addMenuItem (menu, @"None", @selector(doConstrain:), self, 0);
    NSArray *views = [form subviews];
    for (unsigned i = 0; i < [views count]; i ++)
    {
        NSView *view = [views objectAtIndex:i];
        NSString *ident = [form identifierForView:view];
        if (ident && [ident length] > 0)
            addMenuItem (menu, ident, @selector(doConstrain:), self, 0);
    }

    return menu;
}

- (void)refresh
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count];

    if (numObjects == 1)
    {
        NSView *view = [objects objectAtIndex:0];
        SGFormView *form = (SGFormView*)[view superview];

        NSString *ident = [form identifierForView:view];
        [identifierText setStringValue:ident ? ident : @""];

        for (int edge = 0; edge < 4; ++edge)
        {
            SGFormViewAttachment attachment_return;
            NSView *view_return;
            int offset_return;

            BOOL got_it = [form constraintsForEdge:view
                                              edge:(SGFormViewEdge) edge
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
                [connectionMenus[edge] selectItemWithTag:SGFormView_ATTACH_NONE];
            }
        }
    }
    else
    {
        [identifierText setStringValue:@""];
        for(int edge = 0; edge < 4; ++edge)
        {
            [relativeMenus[edge] selectItemAtIndex:0];
        }
    }
    [super refresh];
}

- (void) doConstrain:(id) sender
{
    NSArray * objects = [self inspectedObjects];
    NSInteger numObjects = [objects count];

    for(NSInteger i = 0; i < numObjects; ++i)
    {
        NSView *view = [objects objectAtIndex:i];
        SGFormView *form = (SGFormView*)[view superview];

        for (int edge = 0; edge < 4; edge ++)
        {
            SGFormViewAttachment conn = (SGFormViewAttachment)
            [[connectionMenus[edge] selectedItem] tag];
            int offset = [offsetTexts[edge] intValue];
            NSView *relative = NULL;

            if ([relativeMenus[edge] indexOfSelectedItem] > 0)
            {
                NSString *relative_ident = [relativeMenus[edge] titleOfSelectedItem];

                NSArray *views = [form subviews];
                for (unsigned i = 0; i < [views count]; i ++)
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

            if ((conn == SGFormView_ATTACH_VIEW ||
                 conn == SGFormView_ATTACH_OPPOSITE_VIEW) && relative == NULL)
            {
                conn = SGFormView_ATTACH_NONE;
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
