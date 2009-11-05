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

#import "SGFileSelection.h"

static NSString *fix_path (NSString *path)
{
    if (!path)
        return NULL;
        
    if ([path isAbsolutePath])
        return path;
    
    // Assume it's relative to the dir with the app bundle
    
    NSString *bundle = [[NSBundle mainBundle] bundlePath];
    
    return [NSString stringWithFormat:@"%@/../%@", bundle, path];
}

@implementation SGFileSelection

+ (NSString *) selectWithWindow:(NSWindow *) win
{
    return [self selectWithWindow:win inDir:NULL];
}

+ (NSString *) selectWithWindow:(NSWindow *) win inDir:(NSString *) dir
{
    NSOpenPanel *p = [NSOpenPanel openPanel];
    
    [p setCanChooseFiles:YES];
    [p setResolvesAliases:NO];
    [p setCanChooseDirectories:NO];
    [p setAllowsMultipleSelection:NO];
    [p setPrompt:@"Select"];

    dir = fix_path (dir);
    
    int sts;
    
    if (win)
    {
        [p beginSheetForDirectory:dir file:nil types:nil
            modalForWindow:win modalDelegate:nil didEndSelector:nil
            contextInfo:nil];
    
        sts = [NSApp runModalForWindow:p];
    
        [NSApp endSheet:p];
    }
    else
    	sts = [p runModalForDirectory:dir file:NULL types:NULL] == NSOKButton;
    
    [p orderOut:self];

    if (sts)
    {
        NSArray *a = [p filenames];
        return [a objectAtIndex:0];
    }
    
    return NULL;
}

+ (NSString *) saveWithWindow:(NSWindow *) win
{
    NSSavePanel *p = [NSSavePanel savePanel];
    
    [p setPrompt:@"Select"];
        
    [p beginSheetForDirectory:nil file:nil
       modalForWindow:win modalDelegate:nil didEndSelector:nil
       contextInfo:nil];

    int sts = [NSApp runModalForWindow:p];

    [NSApp endSheet:p];
    
    [p orderOut:self];

    if (sts)
        return [p filename];
    
    return NULL;
}

+ (void) getFile:(const char *)title initial:(const char*)initial callback:(callback_t)callback userdata:(void *)userdata flags:(int)flags
{
	id panel;
	BOOL dir=NO;
	
	if(flags & FRF_WRITE)
		panel=[NSSavePanel savePanel];
	else
		panel=[NSOpenPanel openPanel];
	
	[panel setTitle:[NSString stringWithUTF8String:title]];
	if(initial)
		[panel setDirectory:[NSString stringWithUTF8String:initial]];
	if(flags & FRF_MULTIPLE)
		[panel setAllowsMultipleSelection:YES];
	if(flags & FRF_CHOOSEFOLDER)
		dir=YES;
	[panel setCanChooseDirectories:dir];
	[panel setCanChooseFiles:!dir];
	
	[panel beginSheetForDirectory:nil file:nil
			   modalForWindow:nil modalDelegate:nil didEndSelector:nil
				  contextInfo:nil];
	
    int sts = [NSApp runModalForWindow:panel];
	
    [NSApp endSheet:panel];
    
    [panel orderOut:self];
	
    if (sts)
	{
		if(flags & FRF_MULTIPLE)
		{
			NSArray * arr=[panel filenames];
			for(int i=0;i<[arr count];++i)
			{
				callback(userdata, (char *) [[arr objectAtIndex:i] UTF8String]);
			}
			callback(userdata, 0);
		}else
			callback(userdata, (char *) [[panel filename] UTF8String]);
	}else
		callback(userdata, 0);
}


@end