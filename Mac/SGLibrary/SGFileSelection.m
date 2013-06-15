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
#import "NSPanelAdditions.h"

static NSString *SGFileSelectionFixPath (NSString *path)
{
    if ([path isAbsolutePath]) return path;
    
    // Assume it's relative to the dir with the app bundle
    return [NSString stringWithFormat:@"%@/../%@", [[NSBundle mainBundle] bundlePath], path];
}

@implementation SGFileSelection

+ (void) getFile:(NSString *)title initial:(NSString *)initial callback:(callback_t)callback userdata:(void *)userdata flags:(int)flags
{
    id panel;
    BOOL dir=NO;
    
    if(flags & FRF_WRITE)
        panel=[NSSavePanel savePanel];
    else
        panel=[NSOpenPanel openPanel];
    
    [panel setTitle:title];
    if(initial)
        [panel setDirectory:initial];
    if(flags & FRF_MULTIPLE)
        [panel setAllowsMultipleSelection:YES];
    if(flags & FRF_CHOOSEFOLDER)
        dir=YES;
    [panel setCanChooseDirectories:dir];
    [panel setCanChooseFiles:!dir];
    
    NSInteger sts = [panel runModal];
        
    if (sts == NSOKButton) {
        if(flags & FRF_MULTIPLE)
        {
            for (NSURL *URL in [panel URLs]) {
                NSString *filename = URL.path;
                callback(userdata, (char *)filename.UTF8String);
            }
            callback(userdata, 0);
        } else {
            NSURL *URL = [panel URLs][0];
            callback(userdata, (char *) URL.path.UTF8String);
        }
    } else {
        callback(userdata, 0);
    }
}

@end
