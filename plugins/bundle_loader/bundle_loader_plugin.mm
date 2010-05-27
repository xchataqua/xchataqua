/* X-Chat Aqua
 * Copyright (C) 2008 Eugene Pimenov
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

#include <string.h>
#include <stdio.h>
#include <CoreFoundation/CoreFoundation.h>
#import "Cocoa/Cocoa.h"
#import "SystemVersion.h"
extern "C" {
#include "xchat.h"
#include "outbound.h"
#include "xchatc.h"
#define PLUGIN_C
typedef struct session xchat_context;
#include "xchat-plugin.h"
#include "plugin.h"
#include <dirent.h>
}
static xchat_plugin *ph;

static void bundle_loader_load_bundle( char * word[], char * word_eol[])
{
    char * arg, * error;
    CFURLRef url;
    CFBundleRef bundle;
    CFStringRef bundle_path;
    NSString * version_str;
    char filename[1024];
    
    arg = NULL;
    if (word_eol[3][0])
        arg = word_eol[3];
    
    bundle_path = CFStringCreateWithCString(0, word[2], kCFStringEncodingUTF8);
    
    url = CFURLCreateWithFileSystemPath(0, bundle_path, (CFURLPathStyle)0, 0);
    bundle = CFBundleCreate(0, url);
    
    CFRelease(url);
    CFRelease(bundle_path);
    if(!bundle)
        return;

    do{
        url = CFBundleCopyExecutableURL(bundle);
        CFURLGetFileSystemRepresentation(url, true, (UInt8*)filename, sizeof(filename));
        
        version_str = (NSString*)CFBundleGetValueForInfoDictionaryKey(bundle, CFSTR("XChatAquaMacOSVersionBranch"));
        if(version_str != nil && [[SystemVersion systemBranch] compare:version_str options:NSNumericSearch] != NSOrderedSame)
            break;
        
        error = plugin_load(current_sess, filename, arg);
        if(error)
            xchat_print(ph, error);
    }while(0);
    CFRelease(bundle);
    CFRelease(url);
}

static int bundle_loader_load(char *word[], char *word_eol[], void *userdata)
{
    int len = strlen(word[2]);
	if (len > 7 && strcasecmp(".bundle", word[2]+len-7) == 0) {
		bundle_loader_load_bundle(word, word_eol);
		return XCHAT_EAT_XCHAT;
	}
	return XCHAT_EAT_NONE;
}


//Tries to load all files in plugins dir
void bundle_loader_auto_load(int pass)
{
    NSString * plugins_dir = [[NSBundle mainBundle] builtInPlugInsPath];
    DIR * dir;
    
    dir = opendir([plugins_dir UTF8String]);
    if(!dir)
        return;
    for ( dirent *de=readdir(dir); de!=NULL; de=readdir(dir)) {
        if((de->d_namlen < 3 && de->d_name[0] == '.') || (de->d_namlen == 2 && de->d_name[1] == 0))
            continue;
        
        if ( pass ==
            (((de->d_namlen > 7 && strcasecmp(".bundle", de->d_name+de->d_namlen-7) == 0))
            ||(de->d_namlen > 3 && strcasecmp(".so", de->d_name+de->d_namlen-3) == 0 ))){
            NSString *cmd = [NSString stringWithFormat:@"LOAD \"%@/%@\"", plugins_dir, [NSString stringWithUTF8String:de->d_name]];
            handle_command (current_sess, (char *) [cmd UTF8String], FALSE);
        }
    }
    
    closedir(dir);
}

int bundle_loader_init (xchat_plugin *plugin_handle, char **plugin_name,
                        char **plugin_desc, char **plugin_version, char *arg)
{
	/* we need to save this for use with any xchat_* functions */
	ph = plugin_handle;
    
	*plugin_name = (char*)"Bundle loader";
	*plugin_desc = (char*)"X-Chat Aqua Bundle loader";
	*plugin_version = (char*)"";
    
	xchat_hook_command (ph, "LOAD", XCHAT_PRI_NORM, bundle_loader_load, 0, 0);
    
    bundle_loader_auto_load(1);
    bundle_loader_auto_load(0);
    
	return 1;       /* return 1 for success */
}
