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

#include <stdio.h>
#include <AppKit/AppKit.h>
#import "SGVersionCheck.h"

static unsigned parse_vers (const char *vers)
{
    // <int>.<int>.<int>
    
    unsigned a, b, c;
    
    if (sscanf (vers, "%d.%d.%d", &a, &b, &c) != 3)
        return 0;
    
    return a * 1000000 + b * 1000 + c;
}

@interface VersionCheckPrivate : NSObject
{
    NSString        *prefix;
    int             my_vers;
    NSString        *url_str;
    SEL             callback;
    id              target_obj;
    
    NSURLConnection *conn;
    NSMutableData   *data;
}

- (id) initWithVersion:(NSString *) the_vers
               fromUrl:(NSString *) the_url
                prefix:(NSString *) prefix
              callback:(SEL) the_callback
                    to:(id) the_obj;
- (void) start;

@end

@implementation VersionCheckPrivate

- (id) initWithVersion:(NSString *) the_vers
               fromUrl:(NSString *) the_url
                prefix:(NSString *) the_prefix
              callback:(SEL) the_callback
                    to:(id) the_obj
{
    [super init];

    self->url_str = [[NSString stringWithFormat:@"%@/%g", the_url, NSAppKitVersionNumber] retain];
    self->prefix = [the_prefix retain];
    self->callback = the_callback;
    self->target_obj = the_obj;
    
    self->conn = NULL;
    self->data = [[NSMutableData alloc] init];
    
    my_vers = parse_vers ([the_vers UTF8String]);
    
    if (my_vers == 0)       // Must be a development version
    {
        [self release];
        return NULL;
    }
    
    return self;
}

- (void) dealloc
{
    [prefix release];
    [url_str release];
    [conn release];
    [data release];
	[super dealloc];
}

- (void) start
{
    NSURL *url = [NSURL URLWithString:url_str];
    NSURLRequest *req = [NSURLRequest requestWithURL:url 
                                         cachePolicy:NSURLRequestReloadIgnoringCacheData 
                                     timeoutInterval:30];
    conn = [[NSURLConnection connectionWithRequest:req delegate:self] retain];
    if (!conn)
        [self release];
}

- (void) post_process
{
    // The reply must be in the proper form, although it will probably have a newline.
    //      PREFIX: <int>.<int>.<int>

    unsigned len = [data length];
    char *reply = (char *) [data mutableBytes];

    if (len > 0 && reply [len - 1] == '\n')
    {
        reply [len - 1] = 0;
    }
    else
    {
        // We'll NULL Terminate it if there's no newline.
        char null = 0;
        [data appendBytes:&null length:1];    
    }

    const char *pfx = [prefix UTF8String];
    int pfx_len = [prefix length];
    
    if (strncmp (reply, pfx, pfx_len) == 0)
    {
        int new_vers = parse_vers (reply + pfx_len);
        if (new_vers > my_vers)
        {
            // Docs say that we are in the calling thread here, so we are safe to call the callback.
            [target_obj performSelector:callback];
        }
    }
}

- (void) connection:(NSURLConnection *) connection 
     didReceiveData:(NSData *) more_data
{
    [data appendData:more_data];
}

- (void) connection:(NSURLConnection *) connection 
   didFailWithError:(NSError *) error
{
    [self release];
}

- (void) connectionDidFinishLoading:(NSURLConnection *) connection
{
    [self post_process];
    [self release];
}

@end

@implementation SGVersionCheck

+ (void) checkForNewVersion:(NSString *) vers
                    fromUrl:(NSString *) url
                     prefix:(NSString *) prefix
                   callback:(SEL) sel
                         to:(id) obj
{
    VersionCheckPrivate *v = [[VersionCheckPrivate alloc] initWithVersion:vers
                                fromUrl:url prefix:prefix callback:sel to:obj];
    [v start];
}

+ (bool) version:(const char *) v1 isNewerThan:(const char *) v2
{
    unsigned a = parse_vers (v1);
    unsigned b = parse_vers (v2);
    
    return a && b && a > b;
}

@end
