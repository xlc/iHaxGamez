/*
 iHaxGamez - External process memory search-and-replace tool for MAC OS X
 Copyright (C) <2007>  <Raymond Wilfong>
 
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

#import "MemoryAccess.h"
#import "AppAddressData.h"
#import <mach/vm_map.h>
#import <mach/mach_traps.h>

@implementation MemoryAccess
- (id)init
{
    return [self initWithPID:0];
}

- (id)initWithPID:(pid_t)PID
{
    [super init];
    AppPid = PID;
    return self;
}

- (NSMutableArray *)getSearchArray:(Byte *)Value ByteSize:(int)Bytes SoughtValueString:(NSString *)ValueString PrgBar:(NSProgressIndicator *)pBar;
{
    NSMutableArray *AddrList = [[NSMutableArray alloc] initWithCapacity:1000];
    int MemSize = Bytes;

    // First we need a Task based on our pid
    kern_return_t KernelResult = task_for_pid(current_task(), AppPid, &MySlaveTask);
    if (KERN_SUCCESS == KernelResult)
	{
        // Cool! we have a task...
        // Now we need to start grabbing blocks of memory from our slave task and copying it into our memory space for analysis
        vm_address_t SourceAddress = 0;
        vm_size_t SourceSize = 0;
        vm_region_basic_info_data_t SourceInfo;
        mach_msg_type_number_t SourceInfoSize = VM_REGION_BASIC_INFO_COUNT;
        mach_port_t ObjectName = MACH_PORT_NULL;

        int x;
        int y;
        bool isMatchingValue;
        vm_size_t ReturnedBufferContentSize;
        Byte *ReturnedBuffer = nil;
        
        double PercentDone = 0.0;
        [pBar setDoubleValue:0.0];
        [pBar setHidden:false];
        [pBar displayIfNeeded];
        
        while(KERN_SUCCESS == (KernelResult = vm_region(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO,(vm_region_info_t) &SourceInfo,&SourceInfoSize,&ObjectName)))
        {
            // If we get here then we have a block of memory and we know how big it is... let's copy writable blocks and see what we've got!
            PercentDone = 100.0 * (uint)SourceAddress / (uint)(UINT32_MAX);
            if ((PercentDone - [pBar doubleValue]) > 0.25)
            {
                [pBar setDoubleValue:PercentDone];
                [pBar displayIfNeeded];
            }
            
            if ((SourceInfo.protection & VM_PROT_WRITE) && (SourceInfo.protection & VM_PROT_READ))
            {
NS_DURING
                ReturnedBuffer = malloc(SourceSize);
                ReturnedBufferContentSize = SourceSize;
                if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                     (ReturnedBufferContentSize > 0) )
                {
                    // the last address we check must be far enough from the end of the buffer to check all the bytes of our sought value
                    ReturnedBufferContentSize -= MemSize - 1;
                    
                    // Note: we cannot assume memory alignment so each address could be the start of a multi-byte value
                    for (x=0 ; x<ReturnedBufferContentSize ; x++)
                    {
                        isMatchingValue = true;
                        for (y=MemSize-1 ; isMatchingValue && (y>-1) ; y--) // compare the bytes (lowest order first for speed gains)
                        {
                            isMatchingValue = Value[y] == ReturnedBuffer[x + y];
                        }
                        
                        if (isMatchingValue)
                        {
                            [AddrList addObject:[[[AppAddressData alloc] initWithValues:SourceAddress + x val:ValueString] autorelease]];
                        }
                    }
                }
NS_HANDLER
NS_ENDHANDLER
                if (ReturnedBuffer != nil)
                {
                    free(ReturnedBuffer);
                    ReturnedBuffer = nil;
                }
            }
            
            // reset some values to search some more
            SourceAddress += SourceSize;
        }
        [pBar setHidden:true];
    }
	else
	{
		NSAlert *MyAlert = [NSAlert alertWithMessageText:@"The external process could not be accessed."
										   defaultButton:nil
										 alternateButton:nil
											 otherButton:nil 
							   informativeTextWithFormat:@"You may not have rights to access this process, or this process may have ended."];
		[MyAlert runModal];
	}

    return [AddrList autorelease];
}

- (NSMutableArray *)getFilteredArray:(Byte *)Value ByteSize:(int)Bytes SoughtValueString:(NSString *)ValueString Addresses:(NSMutableArray *)Addrs PrgBar:(NSProgressIndicator *)pBar
{
    AppAddressData *MyAddrRec;
    uint MyAddrRecAddress;
    int recCount = [Addrs count];

    int x;
    int y;
    bool isMatchingValue;
    vm_size_t ReturnedBufferContentSize;
    Byte *ReturnedBuffer = nil;

    double PercentDone = 0.0;
    [pBar setDoubleValue:0.0];
    [pBar setHidden:false];
    [pBar displayIfNeeded];

    ReturnedBuffer = malloc(Bytes);
    NS_DURING
    for (x=recCount-1; x>-1 ; x--) // count down so we can remove from object array by index number
    {
        PercentDone = 100.0 * (recCount - x) / recCount;
        if (PercentDone - [pBar doubleValue] > 1.0)
        {
            [pBar setDoubleValue:PercentDone];
            [pBar displayIfNeeded];
        }
        
        isMatchingValue = false;
        MyAddrRec = [Addrs objectAtIndex:x];
        MyAddrRecAddress = [MyAddrRec address];
        NS_DURING
                ReturnedBufferContentSize = Bytes;
                if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,MyAddrRecAddress,Bytes,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
                    (ReturnedBufferContentSize > 0) )
                {
                    if (ReturnedBufferContentSize == Bytes)
                    {
                        isMatchingValue = true;
                        for (y=Bytes-1 ; isMatchingValue && (y>-1) ; y--) // compare the bytes (lowest order first for speed gains)
                        {
                            isMatchingValue = Value[y] == ReturnedBuffer[y];
                        }
                    }
                }
            NS_HANDLER
                isMatchingValue = false;
            NS_ENDHANDLER
            // check for match here -- removes record if any errors occurred along the way
            if (isMatchingValue)
            {
                [MyAddrRec setValue:ValueString];
            }
            else
            {
                [Addrs removeObjectAtIndex:x];
            }
        }
    NS_HANDLER
    NS_ENDHANDLER
    [pBar setHidden:true];

    if (ReturnedBuffer != nil)
    {
        free(ReturnedBuffer);
        ReturnedBuffer = nil;
    }

    return Addrs;
}

- (bool)saveDataForAddress:(uint)Address Buffer:(Byte *)DataBuffer BufLength:(int)Bytes
{
    bool retVal;
NS_DURING
    retVal = (KERN_SUCCESS == vm_write(MySlaveTask,Address,(vm_offset_t)DataBuffer,Bytes));
NS_HANDLER
    retVal = false;
NS_ENDHANDLER

    return retVal;
}

- (bool)loadDataForAddress:(uint)Address Buffer:(Byte *)DataBuffer BufLength:(vm_size_t)Bytes
{
    bool retVal;
    vm_size_t retBytes = Bytes;
NS_DURING
    retVal = ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,Address,Bytes,(vm_address_t)DataBuffer,&retBytes)) && (retBytes == Bytes) );
NS_HANDLER
    retVal = false;
NS_ENDHANDLER
    
    return retVal;
}

@end
