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

#import "AppAddressDataSource.h"
#import "AppAddressData.h"
#import "SearchWindowController.h"

@implementation AppAddressDataSource

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
    AppAddressData *appAddressData = [appAddresses objectAtIndex:row];
    if (NSOrderedSame == [identifier caseInsensitiveCompare:@"address"])
    {
        // convert address to hexadecimal
        return [NSString stringWithFormat:@"0x%qX",(vm_address_t)[[appAddressData valueForKey:identifier] longValue]];
    }
    else
    {
        return [appAddressData valueForKey:identifier];
    }
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    AppAddressData *appAddressData = [appAddresses objectAtIndex:row];
    [appAddressData setValue:object forKey:identifier];

    // tell the window controller to save the data to the connected application
    if (searchWindowController != nil)
    {
        [searchWindowController valueChangedAtRow:row];
    }
}

- (void)addAppAddressDataRec:(vm_address_t)address val:(NSString *)val dataType:(int)type
{
    [appAddresses addObject:[[[AppAddressData alloc] initWithValues:address val:val dataType:type] autorelease]];
}

- (void)removeAllObjects
{
    [appAddresses removeAllObjects];
}

@end
