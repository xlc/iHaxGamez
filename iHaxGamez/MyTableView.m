/*
 iHaxGamez - External process memory search-and-replace tool for MAC OS X
 Copyright (C) <2007>  <Raymond Wilfong and Glenn Hartmann>
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 You may contact Raymond Wilfong by email at rwilfong@rewnet.com
 */

#import "MyTableView.h"

@implementation MyTableView

// the whole idea behind this subclass is to keep the table view from moving to another record when changes are made and
// the user clicks return

- (void)awakeFromNib
{
    BlockEditRequests = false;
}

- (void)editColumn:(NSInteger)columnIndex row:(NSInteger)rowIndex withEvent:(NSEvent *)theEvent select:(BOOL)flag
{
    if (!BlockEditRequests)
    {
        [super editColumn:columnIndex row:rowIndex withEvent:theEvent select:flag];
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    NSIndexSet *MyIndexes = [self selectedRowIndexes];
    BlockEditRequests = true;
    [super textDidEndEditing:aNotification];
    BlockEditRequests = false;
    [self selectRowIndexes:MyIndexes byExtendingSelection:NO];
    [self reloadData];
}

@end
