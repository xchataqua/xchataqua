/* GLikeTimer
 * Copyright (C) 2005 Camillo Lugaresi
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

/*
	GLikeTimer.h
	Created by Camillo Lugaresi on 04/09/05.
	
	An NSTimer wrapper with semantics compatible with those of glib's timers.
	g_timeout_add -> addTaggedTimerWithMSInterval:callback:userData:
	g_source_remove -> removeTimerWithTag:
*/

#import <Cocoa/Cocoa.h>
#include <glib.h>

@interface GLikeTimer : NSObject {
@private
	GSourceFunc		function;
	gpointer		userdata;
}
+ (guint)addTaggedTimerWithMSInterval:(guint)ms callback:(GSourceFunc)function userData:(gpointer)data;
+ (gboolean)removeTimerWithTag:(guint)tag;
@end
