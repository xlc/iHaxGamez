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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
@class SearchWindowController;


#if defined MAC_OS_X_VERSION_10_6 && MAC_OS_X_VERSION_10_6 <= MAC_OS_X_VERSION_MAX_ALLOWED
@interface AppAddressDataSource : NSObject <NSTableViewDataSource>
#else
@interface AppAddressDataSource : NSObject
#endif
{
    NSMutableArray *appAddresses;
    NSWindowController* searchWindowController;
}

- (id)init;
- (void)dealloc;

- (NSMutableArray *)appAddresses;
- (void)setAppAddresses:(NSMutableArray *)newAppAddresses;
- (NSWindowController *)searchWindowController;
- (void)setSearchWindowController:(NSWindowController *)SWC;

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
- (void)addAppAddressDataRec:(vm_address_t)address val:(NSString *)val;
- (void)removeAllObjects;

@end
