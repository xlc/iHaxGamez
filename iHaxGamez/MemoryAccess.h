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

#import <Foundation/Foundation.h>
#import <AppKit/Appkit.h>

@interface MemoryAccess : NSObject
{
    pid_t AppPid;
    mach_port_t MySlaveTask;
}
- (id)init;
- (id)initWithPID:(pid_t)PID;
- (NSMutableArray *)getSearchArray:(Byte *)Value ByteSize:(int)Bytes SoughtValueString:(NSString *)ValueString PrgBar:(NSProgressIndicator *)pBar;
- (NSMutableArray *)getFilteredArray:(Byte *)Value ByteSize:(int)Bytes SoughtValueString:(NSString *)ValueString Addresses:(NSMutableArray *)Addrs PrgBar:(NSProgressIndicator *)pBar;

// save record to application addresses
- (bool)saveDataForAddress:(vm_address_t)Address Buffer:(Byte *)DataBuffer BufLength:(int)Bytes;

// load record from application addresses
- (bool)loadDataForAddress:(vm_address_t)Address Buffer:(Byte *)DataBuffer BufLength:(vm_size_t)Bytes;

- (NSString*)readString: (UInt32)address;
- (int)readInt: (UInt32)address withSize:(size_t)size;

@end
