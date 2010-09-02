//
//  SGArray.mm
//  aquachat
//
//  Created by Steve Green on Fri Apr 23 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "SGArray.h"


@implementation SGArray

- (id) init
{
	items = NULL;
	count = 0;
	capacity = 0;
	
	return self;
}

- (void) dealloc
{
	free (items);
	[super dealloc];
}

- (NSUInteger) count
{
	return count;
}

- (id) objectAtIndex:(NSUInteger) index
{
	return (id) items [index];
}

- (void) addObject:(id) object
{
	NSUInteger where = count ++;
	
	if (count > capacity)
	{
		capacity += 1 + capacity / 10;
		items = (void **) realloc (items, capacity * sizeof (void *));
	}
	
	items [where] = object;
}

- (void) removeObject:(id) object
{
	NSUInteger s = 0;
	NSUInteger d = 0;
	
	for ( ; s < count; s++)
	{
		if (items [s] == object)
			continue;
		items [d++] = items [s];
	}
	
	count = d;
}

@end
