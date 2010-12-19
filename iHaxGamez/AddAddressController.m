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

#import "AddAddressController.h"


@implementation AddAddressController

- (id) initWithValues:(SearchWindowController*)searchWindow withDS:(AddressListDataSource*)dataSource table:(NSTableView*)tableSource
{
    [super init];
    
	self = [self initWithWindowNibName:@"AddAddress"];
	[self showWindow:self];
	
	searchWindowController = searchWindow;
	addressListDS = dataSource;
	tblAddressList = tableSource;
	
	[NSApp runModalForWindow:[self window]];
	
	return self;
}

- (IBAction) addToAddressList:(id)sender
{
	NSString* addressString = [txtAddress stringValue];
	
	if ([addressString isEqualToString:@""])
	{
		return;
	}
	
	NSScanner* scanner = [NSScanner scannerWithString:addressString];
	
	if ([addressString length] >= 3 && [[addressString substringToIndex:2] isEqualToString:@"0x"])
	{
		addressString = [addressString substringFromIndex:2];
	}
	
	NSString* validCharacters = @"0123456789abcdef";
	
	uint i;
	for (i = 0; i < [validCharacters length]; i++)
	{
		int index = [self getIndexOf:[validCharacters characterAtIndex:i] inString:addressString];
		
		if (i == [validCharacters length] - 1 && index == -1)
		{
			AlertSoundPlay();
			return;
		}
	}

	uint address;
	[scanner scanHexInt:&address];
	
	[addressListDS addAppAddressDataRec:address val:nil dataType:(int)[popupDataType indexOfSelectedItem]];
	[tblAddressList reloadData];
	[searchWindowController performSelector:@selector(refreshAddressList) withObject:nil afterDelay:1];
	[self closeWindow:sender];
}

- (int) getIndexOf:(char)c inString:(NSString*)string
{
	uint i;
	for (i = 0; i < [string length]; i++)
	{
		if (c == [string characterAtIndex:i])
		{
			return i;
		}
	}
	
	return -1;
}

- (IBAction) closeWindow:(id)sender
{
	[NSApp stopModal];
	[self release];
	[self close];
}

- (void) dealloc
{
	[super dealloc];
}

@end
