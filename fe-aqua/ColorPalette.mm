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

extern "C"
{
#include "../common/xchat.h"
#include "../common/cfgfiles.h"
}

#import "ColorPalette.h"

//////////////////////////////////////////////////////////////////////

struct color_def
{
    int r;
    int g;
    int b;
};

static color_def def_color_vals [] =
{
        {0xcccc, 0xcccc, 0xcccc}, /* 0 white */
        {0x0000, 0x0000, 0x0000}, /* 1 black */
        {0x35c2, 0x35c2, 0xb332}, /* 2 blue */
        {0x2a3d, 0x8ccc, 0x2a3d}, /* 3 green */
        {0xc3c3, 0x3b3b, 0x3b3b}, /* 4 red */
        {0xc7c7, 0x3232, 0x3232}, /* 5 light red */
        {0x8000, 0x2666, 0x7fff}, /* 6 purple */
        {0x6666, 0x3636, 0x1f1f}, /* 7 orange */
        {0xd999, 0xa6d3, 0x4147}, /* 8 yellow */
        {0x3d70, 0xcccc, 0x3d70}, /* 9 green */
        {0x199a, 0x5555, 0x5555}, /* 10 aqua */
        {0x2eef, 0x8ccc, 0x74df}, /* 11 light aqua */
        {0x451e, 0x451e, 0xe666}, /* 12 blue */
        {0xb0b0, 0x3737, 0xb0b0}, /* 13 light purple */
        {0x4c4c, 0x4c4c, 0x4c4c}, /* 14 grey */
        {0x9595, 0x9595, 0x9595}, /* 15 light grey */

        {0xcccc, 0xcccc, 0xcccc}, /* 16 white */
        {0x0000, 0x0000, 0x0000}, /* 17 black */
        {0x35c2, 0x35c2, 0xb332}, /* 18 blue */
        {0x2a3d, 0x8ccc, 0x2a3d}, /* 19 green */
        {0xc3c3, 0x3b3b, 0x3b3b}, /* 20 red */
        {0xc7c7, 0x3232, 0x3232}, /* 21 light red */
        {0x8000, 0x2666, 0x7fff}, /* 22 purple */
        {0x6666, 0x3636, 0x1f1f}, /* 23 orange */
        {0xd999, 0xa6d3, 0x4147}, /* 24 yellow */
        {0x3d70, 0xcccc, 0x3d70}, /* 25 green */
        {0x199a, 0x5555, 0x5555}, /* 26 aqua */
        {0x2eef, 0x8ccc, 0x74df}, /* 27 light aqua */
        {0x451e, 0x451e, 0xe666}, /* 28 blue */
        {0xb0b0, 0x3737, 0xb0b0}, /* 29 light purple */
        {0x4c4c, 0x4c4c, 0x4c4c}, /* 30 grey */
        {0x9595, 0x9595, 0x9595}, /* 31 light grey */

        {0xffff, 0xffff, 0xffff}, /* 32 marktext Fore (white) */	// Text highlight (unused)
        {0x3535, 0x6e6e, 0xc1c1}, /* 33 marktext Back (blue) */		// Text highlight (unused)
        {0x0000, 0x0000, 0x0000}, /* 34 foreground (black) */
        {0xf0f0, 0xf0f0, 0xf0f0}, /* 35 background (white) */
        {0xcccc, 0x1010, 0x1010}, /* 36 marker line (red) */		// Not sure (unused)

        /* colors for GUI */
        {0x9999, 0x0000, 0x0000}, /* 37 tab New Data (dark red) */
        {0x0000, 0x0000, 0xffff}, /* 38 tab Nick Mentioned (blue) */
        {0xffff, 0x0000, 0x0000}, /* 39 tab New Message (red) */
        {0x9595, 0x9595, 0x9595}, /* 40 away user (grey) */
};

static int cn = sizeof (def_color_vals) / sizeof (def_color_vals [0]);

static int color_remap [] =
{
	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
	0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,
	0, 0,										// Mark text (unused)
	18, 19,										// fg, bg
	0,											// Marked line (unused)
	20, 21, 22, 23
};

//////////////////////////////////////////////////////////////////////

@implementation ColorPalette

- (void) load
{
	// Initialize defaults

	for (NSUInteger i = 0; i < cn; i ++)
	{
		[colors[i] release];
		color_def *def = &def_color_vals[i];
		colors[i] = [[NSColor colorWithDeviceRed:(CGFloat)def->r / 0xffff
										   green:(CGFloat)def->g / 0xffff
											blue:(CGFloat)def->b / 0xffff
										   alpha:1] retain];
    }

    // Load saved value

    NSString *fn = [NSString stringWithFormat:@"%s/palette.conf", get_xdir_fs()];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:fn];

    if (!dict) return;

	// If there are only 24 colors, then we'll need to move things around
	// to map into the new color palette.
	// 24 * 4 = 96
	bool remap = [dict count] == 24 * 4;
	
    for (NSUInteger i = 0; i < cn; i++)
    {
		NSUInteger x = remap ? color_remap [i] : i;

		id rid = [dict objectForKey:[NSString stringWithFormat:@"color_%d_red", x]];
		id gid = [dict objectForKey:[NSString stringWithFormat:@"color_%d_green", x]];
		id bid = [dict objectForKey:[NSString stringWithFormat:@"color_%d_blue", x]];
		id aid = [dict objectForKey:[NSString stringWithFormat:@"color_%d_alpha", x]];
			
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

- (void) save
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithCapacity:cn];
    for (NSUInteger i = 0; i < cn; i++)
    {
        NSColor *color = colors[i];
        NSColor *c = [color colorUsingColorSpaceName:NSDeviceRGBColorSpace];
        
    	[dict setObject:[NSNumber numberWithFloat:[c redComponent]]   forKey:[NSString stringWithFormat:@"color_%d_red",   i]];
    	[dict setObject:[NSNumber numberWithFloat:[c greenComponent]] forKey:[NSString stringWithFormat:@"color_%d_green", i]];
    	[dict setObject:[NSNumber numberWithFloat:[c blueComponent]]  forKey:[NSString stringWithFormat:@"color_%d_blue",  i]];
    	[dict setObject:[NSNumber numberWithFloat:[c alphaComponent]] forKey:[NSString stringWithFormat:@"color_%d_alpha", i]];
    }
    NSString *fn = [NSString stringWithFormat:@"%s/palette.conf", get_xdir_fs ()];
    [dict writeToFile:fn atomically:true];
}

- (id) init
{
	colors = (NSColor **) malloc (cn * sizeof(NSColor *));

	for (NSUInteger i = 0; i < cn; i++)
		colors[i] = nil;

	return self;
}

- (id) clone
{
	ColorPalette *copy = [[ColorPalette alloc] init];
	for (NSUInteger i = 0; i < cn; i++)
		copy->colors[i] = [colors[i] retain];
	return copy;
}

- (void) dealloc
{
	for (NSUInteger i = 0; i < cn; i ++)
		[colors[i] release];
	free (colors);
	[super dealloc];
}

- (NSColor *) getColor:(int) color
{
	return colors[color % cn];
}

- (NSUInteger) numberOfColors
{
	return cn;
}

- (void) setColor:(NSUInteger) n color:(NSColor *) color
{
	[colors [n] release];
	colors [n] = [color retain];
}

@end
