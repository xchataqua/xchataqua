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

/* ColorPalette.m
 * Correspond to fe-gtk: xchat/src/fe-gtk/palette.*
 */

#import "ColorPalette.h"

#include <sys/stat.h>
#include "cfgfiles.h"

// Constants are copied from fe-gtk

struct GdkColor {
    guint32 pixel;
    guint16 red;
    guint16 green;
    guint16 blue;
};

struct GdkColor ColorPalleteDefaultColors[] = {
	/* colors for xtext */
	{0, 0xcccc, 0xcccc, 0xcccc}, /* 16 white */
	{0, 0x0000, 0x0000, 0x0000}, /* 17 black */
	{0, 0x35c2, 0x35c2, 0xb332}, /* 18 blue */
	{0, 0x2a3d, 0x8ccc, 0x2a3d}, /* 19 green */
	{0, 0xc3c3, 0x3b3b, 0x3b3b}, /* 20 red */
	{0, 0xc7c7, 0x3232, 0x3232}, /* 21 light red */
	{0, 0x8000, 0x2666, 0x7fff}, /* 22 purple */
	{0, 0x6666, 0x3636, 0x1f1f}, /* 23 orange */
	{0, 0xd999, 0xa6d3, 0x4147}, /* 24 yellow */
	{0, 0x3d70, 0xcccc, 0x3d70}, /* 25 green */
	{0, 0x199a, 0x5555, 0x5555}, /* 26 aqua */
	{0, 0x2eef, 0x8ccc, 0x74df}, /* 27 light aqua */
	{0, 0x451e, 0x451e, 0xe666}, /* 28 blue */
	{0, 0xb0b0, 0x3737, 0xb0b0}, /* 29 light purple */
	{0, 0x4c4c, 0x4c4c, 0x4c4c}, /* 30 grey */
	{0, 0x9595, 0x9595, 0x9595}, /* 31 light grey */
    
	{0, 0xcccc, 0xcccc, 0xcccc}, /* 16 white */
	{0, 0x0000, 0x0000, 0x0000}, /* 17 black */
	{0, 0x35c2, 0x35c2, 0xb332}, /* 18 blue */
	{0, 0x2a3d, 0x8ccc, 0x2a3d}, /* 19 green */
	{0, 0xc3c3, 0x3b3b, 0x3b3b}, /* 20 red */
	{0, 0xc7c7, 0x3232, 0x3232}, /* 21 light red */
	{0, 0x8000, 0x2666, 0x7fff}, /* 22 purple */
	{0, 0x6666, 0x3636, 0x1f1f}, /* 23 orange */
	{0, 0xd999, 0xa6d3, 0x4147}, /* 24 yellow */
	{0, 0x3d70, 0xcccc, 0x3d70}, /* 25 green */
	{0, 0x199a, 0x5555, 0x5555}, /* 26 aqua */
	{0, 0x2eef, 0x8ccc, 0x74df}, /* 27 light aqua */
	{0, 0x451e, 0x451e, 0xe666}, /* 28 blue */
	{0, 0xb0b0, 0x3737, 0xb0b0}, /* 29 light purple */
	{0, 0x4c4c, 0x4c4c, 0x4c4c}, /* 30 grey */
	{0, 0x9595, 0x9595, 0x9595}, /* 31 light grey */
    
	{0, 0xffff, 0xffff, 0xffff}, /* 32 marktext Fore (white) */
	{0, 0x3535, 0x6e6e, 0xc1c1}, /* 33 marktext Back (blue) */
	{0, 0x0000, 0x0000, 0x0000}, /* 34 foreground (black) */
	{0, 0xf0f0, 0xf0f0, 0xf0f0}, /* 35 background (white) */
	{0, 0xcccc, 0x1010, 0x1010}, /* 36 marker line (red) */
    
	/* colors for GUI */
	{0, 0x9999, 0x0000, 0x0000}, /* 37 tab New Data (dark red) */
	{0, 0x0000, 0x0000, 0xffff}, /* 38 tab Nick Mentioned (blue) */
	{0, 0xffff, 0x0000, 0x0000}, /* 39 tab New Message (red) */
	{0, 0x9595, 0x9595, 0x9595}, /* 40 away user (grey) */
};

static int color_remap [] =
{
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
    0, 0,                                        // Mark text (unused)
    18, 19,                                        // fg, bg
    0,                                            // Marked line (unused)
    20, 21, 22, 23
};

//////////////////////////////////////////////////////////////////////

@implementation ColorPalette

- (id) init
{
    self = [super init];
    if (self != nil) {
        colors = (NSColor **) malloc ([self numberOfColors] * sizeof(NSColor *));
        for (NSUInteger i = 0; i < [self numberOfColors]; i++) {
            colors[i] = nil;
        }
    }
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    ColorPalette *copy = [[ColorPalette alloc] init];
    for (NSUInteger i = 0; i < [self numberOfColors]; i++) {
        copy->colors[i] = [colors[i] retain];
    }
    return copy;
}

- (void) dealloc
{
    for (NSUInteger i = 0; i < [self numberOfColors]; i ++) {
        [colors[i] release];
    }
    free (colors);
    [super dealloc];
}

- (void)loadDefaults {
    for (NSUInteger i = 0; i < [self numberOfColors]; i++) {
        struct GdkColor *defaultColor = &ColorPalleteDefaultColors[i];
        colors[i] = [[NSColor colorWithDeviceRed:(CGFloat)defaultColor->red  / 0xffff
                                           green:(CGFloat)defaultColor->green/ 0xffff
                                            blue:(CGFloat)defaultColor->blue / 0xffff
                                           alpha:1.0f] retain];
    }
}

- (void) loadLegacy // load palette.conf
{
    // Load saved value
    char *url = get_xdir_fs();
    dassert(url);
    NSString *fn = [NSString stringWithFormat:@"%s/palette.conf", url];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fn];

    if (!dict) {
        [self loadDefaults];
        return;
    }

    // If there are only 24 colors, then we'll need to move things around
    // to map into the new color palette.
    // 24 * 4 = 96
    BOOL remap = [dict count] == 24 * 4;
    
    for (unsigned i = 0; i < [self numberOfColors]; i++)
    {
        int x = remap ? color_remap [i] : i;

        id rid = dict[[NSString stringWithFormat:@"color_%d_red", x]];
        id gid = dict[[NSString stringWithFormat:@"color_%d_green", x]];
        id bid = dict[[NSString stringWithFormat:@"color_%d_blue", x]];
        id aid = dict[[NSString stringWithFormat:@"color_%d_alpha", x]];
            
        if (!rid || !gid || !bid || !aid) continue;
                
        CGFloat r = [rid floatValue];
        CGFloat g = [gid floatValue];
        CGFloat b = [bid floatValue];
        CGFloat a = [aid floatValue];

        NSColor *color = [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] retain];

        if (color)
        {            
            [colors[i] release];
            colors[i] = [color retain]; // isn't this duplicated retain?
        }
    }
}

- (void)loadFromXChatFile:(int)file {
    struct stat filestat;
    fstat(file, &filestat);
    char *cfg = malloc((size_t)filestat.st_size + 1);
    if (cfg != NULL) {
        cfg[0]  = '\0';
        ssize_t cfglen = read(file, cfg, (size_t)filestat.st_size);
        if (cfglen >= 0)
            cfg[cfglen] = '\0';
        
        int red, green, blue;
        for (unsigned i = 0; i < 32; i++) {
            const char *name = [[NSString stringWithFormat:@"color_%d", i] UTF8String];
            cfg_get_color(cfg, (char *)name, &red, &green, &blue);
            [colors[i] release];
            colors[i] = [[NSColor colorWithDeviceRed:(CGFloat)red/0xffff green:(CGFloat)green/0xffff blue:(CGFloat)blue/0xffff alpha:1.0f] retain];
        }
        for (unsigned i = 256, j = 32; j < [self numberOfColors]; i++, j++) {
            const char *name = [[NSString stringWithFormat:@"color_%d", i] UTF8String];
            cfg_get_color(cfg, (char *)name, &red, &green, &blue);
            [colors[j] release];
            colors[j] = [[NSColor colorWithDeviceRed:(CGFloat)red/0xffff green:(CGFloat)green/0xffff blue:(CGFloat)blue/0xffff alpha:1.0f] retain];
        }
        free(cfg);
    }
    close(file);
}

- (void)loadFromURL:(NSURL *)fileURL {
    const char *filename = fileURL.path.UTF8String;
    int file = hexchat_open_file((char *)filename, O_RDONLY, 0, XOF_FULLPATH);
    [self loadFromXChatFile:file];
}

- (void)loadFromConfiguration {
    int file = hexchat_open_file("colors.conf", O_RDONLY, 0, 0);
    if (file == -1) {
        [self loadLegacy];
        return;
    }
    [self loadFromXChatFile:file];
}

- (void) save
{
    int file = hexchat_open_file ("colors.conf", O_TRUNC | O_WRONLY | O_CREAT, 0600, XOF_DOMODE);
	if (file != -1)
	{
		/* mIRC colors 0-31 are here */
		for (int i = 0; i < 32; i++)
		{
            const char *name = [[NSString stringWithFormat:@"color_%d", i] UTF8String];
			cfg_put_color(file, colors[i].redComponent * 0xffff, colors[i].greenComponent * 0xffff, colors[i].blueComponent * 0xffff, (char *)name);
		}
        
		/* our special colors are mapped at 256+ */
		for (unsigned i = 256, j = 32; j < self.numberOfColors; i++, j++)
		{
			const char *name = [[NSString stringWithFormat:@"color_%d", i] UTF8String];
			cfg_put_color (file, colors[j].redComponent * 0xffff, colors[j].greenComponent * 0xffff, colors[j].blueComponent * 0xffff, (char *)name);
		}
        
		close (file);
	}
}

- (NSColor *) getColor:(NSInteger)n
{
    return colors[n % [self numberOfColors]];
}

- (void) setColor:(NSUInteger) n color:(NSColor *) color
{
    [colors [n] release];
    colors [n] = [color retain];
}

- (NSUInteger) numberOfColors
{
    return sizeof(ColorPalleteDefaultColors) / sizeof(ColorPalleteDefaultColors[0]);
}

@end
