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

#import "AddressListDataSource.h"
#import "AddressListData.h"
#import "SearchWindowController.h"

@implementation AddressListDataSource

- (id)init
{
    [self setAppAddresses:[NSMutableArray arrayWithCapacity:1000]];
    searchWindowController = nil;
    return self;
}

- (void)dealloc
{
	[searchWindowController release];
    [appAddresses release];
    [super dealloc];
}

- (SearchWindowController *)searchWindowController
{
    return searchWindowController;
}

- (void)setSearchWindowController:(SearchWindowController *)SWC
{
    if (searchWindowController != SWC)
    {
        [searchWindowController release];
		searchWindowController = [SWC retain];
    }
}

- (NSMutableArray *)appAddresses
{
    return appAddresses;
}

- (void)setAppAddresses:(NSMutableArray *)newAppAddresses
{
	if (appAddresses != newAppAddresses)
	{
		[appAddresses release];
		appAddresses = [newAppAddresses retain];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [appAddresses count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    AddressListData *appAddressData = [appAddresses objectAtIndex:row];
    
	if (NSOrderedSame == [identifier caseInsensitiveCompare:@"address"])
    {
        // convert address to hexadecimal
        return [NSString stringWithFormat:@"0x%qX",(vm_address_t)[[appAddressData valueForKey:identifier] longValue]];
    }
	
	if (NSOrderedSame == [identifier caseInsensitiveCompare:@"type"])
    {
		NSString* valueType;
		
		switch([appAddressData type])
		{
			case 0: // byte
				valueType = @"Integer (1 byte)";
				break;
			case 1: // int16
				valueType = @"Integer (2 bytes)";
				break;
			case 2: // int32
				valueType = @"Integer (4 bytes)";
				break;
			case 3: // int64
				valueType = @"Integer (8 bytes)";
				break;
			case 4: // float
				valueType = @"Float (4 bytes)";
				break;
			case 5: // double
				valueType = @"Float (8 bytes)";
				break;
			case 6: // ASCII string
				valueType = @"String (1 byte) ASCII";
				break;
			case 7: // UNICODE string
				valueType = @"String (2 bytes) UNICODE";
				break;
			default:
				valueType = @"Unkown";
				break;
		}
		
		return valueType;
    }
    else
    {
        return [appAddressData valueForKey:identifier];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    AddressListData *appAddressData = [appAddresses objectAtIndex:row];
    [appAddressData setValue:object forKey:identifier];
	
    // tell the window controller to save the data to the connected application
    if (searchWindowController != nil)
    {
        [searchWindowController valueChangedAtRow:row];
    }
}

- (void)addAppAddressDataRec:(vm_address_t)address val:(NSString *)val dataType:(int)type
{
    [appAddresses addObject:[[[AddressListData alloc] initWithValues:address val:val dataType:type] autorelease]];
}

- (void)removeAllObjects
{
    [appAddresses removeAllObjects];
}

@end
