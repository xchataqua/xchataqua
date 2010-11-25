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

#ifndef DATA_ARRAY
#	error No data array found.
#endif

#define DraggingDataType @"TemporaryDataType"

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
	[tableView registerForDraggedTypes:[NSArray arrayWithObject:DraggingDataType]];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
	[pboard declareTypes:[NSArray arrayWithObject:DraggingDataType] owner:self];
	[pboard setData:data forType:DraggingDataType];
	return YES;
}

- (NSDragOperation) tableView:(NSTableView *)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation {
	return NSDragOperationMove;
}

- (BOOL) tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation {
	NSData *rowData = [[info draggingPasteboard] dataForType:DraggingDataType];
	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
	NSInteger selectedRow = [rowIndexes firstIndex];
	
	NSMutableArray *dataArray = DATA_ARRAY;
	
	id selectedItem = [[dataArray objectAtIndex:selectedRow] retain];
	switch (dropOperation) {
		case NSTableViewDropOn:
			[dataArray replaceObjectAtIndex:selectedRow withObject:[dataArray objectAtIndex:row]];
			[dataArray replaceObjectAtIndex:row withObject:selectedItem];
			break;
		case NSTableViewDropAbove:
			[dataArray removeObjectAtIndex:selectedRow];
			[dataArray insertObject:selectedItem atIndex:row-(row>=selectedRow)];
			[tableView reloadData];
			break;
		default:
			SGAssert(NO);
	}
	[selectedItem release];
	[tableView unregisterDraggedTypes];
	return YES;
}

#undef DraggingDataType
