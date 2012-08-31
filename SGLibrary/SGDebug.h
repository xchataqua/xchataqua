/*
 *  SGDebug.h
 *  X-Chat Aqua
 *
 *  Created by 정윤원 on 10. 9. 3..
 *  Copyright 2010 __MyCompanyName__. All rights reserved.
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

#ifndef SG_DEBUG
#   define SG_DEBUG DEBUG
#endif

#ifdef SG_DEBUG
#   define SGLog(TAG, ...)		{ if ( TAG ) [SGDebug log:[NSString stringWithFormat:__VA_ARGS__] file:__FILE__ line:__LINE__]; }
#   define SGLogRect(TAG, NAME, RECT) { SGLog(TAG, NAME @": origin<%.0f,%.0f> size<%.0f,%.0f>", RECT.origin.x, RECT.origin.y, RECT.size.width, RECT.size.height); }
#   define SGAssert(ASSERTION)	assert(ASSERTION)
#else
#   define SGLog(TAG, ...)
#   define SGAssert(ASSERTION)
#endif

@interface SGDebug : NSObject 
+ (void) log:(NSString *)log file:(const char *)file line:(int)line;
@end
