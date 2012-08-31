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

#import "ColorPalette.h"
#import "MIRCString.h"

//////////////////////////////////////////////////////////////////////

static char peek_next_char (const char **x, const char *stop_at)
{
    return *x < stop_at ? **x : 0;
}

static char get_next_char (const char **x, const char *stop_at)
{
    if (*x >= stop_at)
        return 0;
    char c = **x;
    if (c) (*x)++;
    return c;
}

static int get_mirc_value (const char **x, const char *stop_at)
{
    // Read from 1 to 2 digits.
    
    if (!isdigit (peek_next_char (x, stop_at)))        // No digits at all
        return -1;
    
    int val = get_next_char (x, stop_at) - '0';

    // We have atleast 1 digit... is there another?
        
    if (isdigit (peek_next_char (x, stop_at)))        // 2 digits.. cool!
        val = val * 10 + get_next_char (x, stop_at) - '0';

    return val;
}

@interface NSMutableAttributedString (MIRCString)

- (NSInteger)appendText:(const char *)text length:(NSUInteger)len
        foregroundColor:(NSInteger)fg backgroundColor:(NSInteger)bg reverse:(bool)reverse
               underbar:(bool)under bold:(bool)bold hidden:(bool)hidden
           colorPalette:(ColorPalette *)p font:(NSFont *)font boldFont:(NSFont *)boldFont;

@end

@implementation MIRCString

NSFont *sharedHiddenFont;

+ (void) initialize {
    sharedHiddenFont = [[NSFont userFontOfSize:0.01] retain];
}

+ (NSFont *) hiddenFont
{    
    return sharedHiddenFont;
}

+ (id) stringWithUTF8String:(const char *) text
                     length:(NSInteger) len
                    palette:(ColorPalette *) palette
                       font:(NSFont *) font
                   boldFont:(NSFont *) boldFont;
{
    NSMutableAttributedString *msgString = [[NSMutableAttributedString alloc] init];
 
    NSInteger fg = -1;
    NSInteger bg = -1;
    bool reverse = false;
    bool under = false;
    bool bold = false;
    bool hidden = false;

    if (len < 0)
        len = strlen (text);
        
    const char *stop_at = text + len;
    
    // Scan the input text looking for format changes.
    // When we find one, we spit out what he have collected, and
    // start collecting again with the new format.
    
    const char *start = text;
            
    for (char x; (x = get_next_char (&text, stop_at)); )
    {
        switch (x)
        {
            case 3:
            {
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                
                // Control-c starts a mIRC color protocol sequence.
                // Read as many as 2 digits, optional comma, and as
                // many as 2 more digits.
                
                fg = get_mirc_value (&text, stop_at);
                //bg = -1;

                if (fg < 0)    // Naked control-c
                {
                    fg = -1;
                    bg = -1;
                }
                else if (peek_next_char (&text, stop_at) == ',')
                {
                    NSInteger new_bg;
                    get_next_char (&text, stop_at);        // Toss out the ','
                    new_bg = get_mirc_value (&text, stop_at);
                    if(new_bg >= 0)
                        bg = new_bg;
                }
                
                start = text;        // Advance 'start' past the color spec.
                
                break;
            }
                
            case 22:                  /* REVERSE */
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                reverse = !reverse;
                start = text;
                break;
                
            case 31:                  /* underline */
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                under = !under;
                start = text;
                break;
                
            case 2:                  /* bold */
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                bold = !bold;
                start = text;
                break;

            case 15:                  /* reset all */
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                reverse = false;
                bold = false;
                under = false;
                fg = -1;
                bg = -1;

                start = text;

                break;
                
            case 8:          /* CL: invisible text code */
                [msgString appendText:start length:text-start-1
                      foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
                         colorPalette:palette font:font boldFont:boldFont];
                hidden = !hidden;
                start = text;
                break;
        }
    }

    [msgString appendText:start length:text-start
          foregroundColor:fg backgroundColor:bg reverse:reverse underbar:under bold:bold hidden:hidden
             colorPalette:palette font:font boldFont:boldFont];

    return [msgString autorelease];
}

+ (id) stringWithUTF8String:(const char *) string
                    palette:(ColorPalette *) palette
                       font:(NSFont *) font
                   boldFont:(NSFont *) boldFont {
    return [self stringWithUTF8String:string
                               length:-1
                              palette:palette
                                 font:font
                             boldFont:boldFont];
}

- (const char *) UTF8String
{
    return [[self string] UTF8String];
}

@end

@implementation NSMutableAttributedString (MIRCString)

- (NSInteger)appendText:(const char *)text length:(NSUInteger)len
        foregroundColor:(NSInteger)fg backgroundColor:(NSInteger)bg reverse:(bool)reverse
               underbar:(bool)under bold:(bool)bold hidden:(bool)hidden
           colorPalette:(ColorPalette *)p font:(NSFont *)font boldFont:(NSFont *)boldFont
{    
    if (len == 0)
        return 0;
    
    NSData *data = [NSData dataWithBytesNoCopy:(void *) text length:len freeWhenDone:NO];
    NSString *s = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!s)
        s = [[NSString alloc] initWithData:data encoding:[NSString defaultCStringEncoding]];
    
    NSMutableDictionary *attr = [NSMutableDictionary dictionary];
    
    if (fg < 0)
        fg = XAColorForeground;
    
    if (reverse)
    {
        // Special case:  Since we don't always have a bg color value, if
        // we are reversing the default colors, we need to do it specifically.
        if (bg < 0)
            bg = XAColorBackground;
        
        NSInteger xx = fg;
        fg = bg;
        bg = xx;
    }
    
    [attr setObject:[p getColor:fg]
             forKey:NSForegroundColorAttributeName];
    
    if (bg >= 0)
    {
        [attr setObject:[p getColor:bg]
                 forKey:NSBackgroundColorAttributeName];
    }
    
    if (under)
        [attr setObject:[NSNumber numberWithInt:NSSingleUnderlineStyle]
                 forKey:NSUnderlineStyleAttributeName];
    
    if (hidden)
    {
        [attr setObject:[MIRCString hiddenFont] forKey:NSFontAttributeName];
        [attr setObject:[NSColor colorWithDeviceWhite:1.0 alpha:0.0] forKey:NSForegroundColorAttributeName];
    }
    else if (bold && boldFont)
    {
        if([boldFont isEqual:font])
        {
            /* emulate bold */
            [attr setObject:[NSNumber numberWithFloat:-3.0f] forKey:NSStrokeWidthAttributeName];
        }
        [attr setObject:boldFont forKey:NSFontAttributeName];
    }
    else if (font)
        [attr setObject:font forKey:NSFontAttributeName];
    
    NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:attr];
    
    [self appendAttributedString:as];
    
    [as release];
    [s release];
    
    return len;
}

@end
