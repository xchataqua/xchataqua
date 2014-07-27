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

#import "AquaChat.h"
#import "AquaPlugins.h"

#include "hexchat-plugin.h"
#include "text.h"
#include "outbound.h"

/////////////////////////////////////////////////////////////////////////////

#define APPLESCRIPT_HELP "Usage: APPLESCRIPT [-o] <script>"
#define BROWSER_HELP "Usage: BROWSER [browser] <url>"

extern struct text_event te[];

static xchat_plugin *XAInternalPluginHandle;

static int
applescript_cb (char *word[], char *word_eol[], void *userdata)
{
    char *command = NULL;
    bool to_channel = false;
    
    if (!word [2][0])
    {
        PrintText (current_sess, APPLESCRIPT_HELP);
        return XCHAT_EAT_ALL;
    }
    
    if (strcmp (word [2], "-o") == 0)
    {
        if (!word [3][0])
        {
            PrintText (current_sess, APPLESCRIPT_HELP);
            return XCHAT_EAT_ALL;
        }
        
        command = word_eol [3];
        to_channel = true;
    }
    else
        command = word_eol [2];
    
    NSMutableString *script = [NSMutableString stringWithUTF8String:command];
    [script replaceOccurrencesOfString:@"\\n" withString:@"\n" 
                               options:0 range:NSMakeRange(0, [script length])];
    NSAppleScript *s = [[[NSAppleScript alloc] initWithSource:script] autorelease];
    
    NSDictionary *errors = nil;
    NSAppleEventDescriptor *d = [s executeAndReturnError:&errors];
    
    if (d)
    {
        const char *return_val = [[d stringValue] UTF8String];
        
        if (return_val)
        {
            if (to_channel)
                handle_multiline (current_sess, (char *) return_val, FALSE, TRUE);
            else
                PrintText (current_sess, (char *) return_val);
        }
    }
    else
        PrintText (current_sess, "Applescript Error\n");
    
    return XCHAT_EAT_ALL;
}

static NSString *fix_url (const char *url)
{
    NSString *ret = @(url);

    // TODO: Replace this with NSRegularExpression or Data Detectors
    // (and phase out SGRegex; this is its only use in XCA)
    SGRegex *regex = [SGRegex
                      regexWithString:@"(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
                      nSubExpr:2];
    
    if (![regex doitWithUTF8String:url])
        return ret;
    
    NSString *scheme = [regex getNthMatch:1];
    
    // Any URL with a protocol is considered good
    if ([scheme length])
        return ret;
    
    // If we have an '@', then it's probably an email address
    // URLs with ftp in their name are probably ftp://
    // Else, just assume http://
    if (strchr (url, '@'))
        scheme = @"mailto:";
    else if (strncasecmp (url, "ftp.", 4) == 0)
        scheme = @"ftp://";
    else
        scheme = @"http://";
    
    return [NSString stringWithFormat:@"%@%@", scheme, ret];
}

static int
browser_cb (char *word[], char *word_eol[], void *userdata)
{
    if (!word [2][0])
    {
        PrintText (current_sess, BROWSER_HELP);
        return XCHAT_EAT_ALL;
    }
    
    const char *browser = NULL;
    const char *url = NULL;
    
    if (word [3][0])
    {
        browser = word[2];
        url = word_eol[3];
    }
    else
    {
        url = word_eol[2];
    }
    
    NSString *new_url = fix_url (url);
    
    if (browser)
    {
        NSString *command =
        [NSString stringWithFormat:
         @"tell application \"%s\" to «event WWW!OURL» (\"%@\")", browser, new_url];
        NSAppleScript *s = [[[NSAppleScript alloc] initWithSource:command] autorelease];
        NSDictionary *errors = nil;
        [s executeAndReturnError:&errors];
    }
    else
    {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:new_url]];
    }
    
    return XCHAT_EAT_ALL;
}

static int
event_cb (char *word[], void *cbd)
{
    int event = (int) (size_t)cbd;
    struct session *sess = (struct session *) hexchat_get_context(XAInternalPluginHandle);
    [[AquaChat sharedAquaChat] event:event args:word session:sess];
    return XCHAT_EAT_NONE;
}

int XAInitInternalPlugin(xchat_plugin *plugin_handle, char **plugin_name,
                         char **plugin_desc, char **plugin_version, char *arg)
{
    /* we need to save this for use with any xchat_* functions */
    XAInternalPluginHandle = plugin_handle;
    
    *plugin_name = (char*)PRODUCT_NAME" Internal Plugin";
    *plugin_desc = (char*)"Does stuff";
    *plugin_version = (char*)"";
    
    hexchat_hook_command (plugin_handle, "APPLESCRIPT", XCHAT_PRI_NORM,
                        applescript_cb, APPLESCRIPT_HELP, plugin_handle);
    
    hexchat_hook_command (plugin_handle, "BROWSER", XCHAT_PRI_NORM,
                        browser_cb, BROWSER_HELP, plugin_handle);
    
    for (NSInteger i = 0; i < NUM_XP; i ++) {
        hexchat_hook_print (plugin_handle, te[i].name, XCHAT_PRI_NORM, event_cb, (void *) i);
    }
    
    return 1;       /* return 1 for success */
}

