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
	
    // First we need a Task based on our pid
    kern_return_t KernelResult = task_for_pid(current_task(), AppPid, &MySlaveTask);
    if (KERN_SUCCESS == KernelResult)
	{
        // Cool! we have a task...
        // Now we need to start grabbing blocks of memory from our slave task and copying it into our memory space for analysis
        vm_address_t SourceAddress = 0;
        vm_size_t SourceSize = 0;
		
#ifdef __LP64__
        vm_region_basic_info_data_64_t SourceInfo;
		uint64 BarMaxValue = UINT64_MAX;
#else
        vm_region_basic_info_data_t SourceInfo;
		uint BarMaxValue = UINT_MAX;
#endif
		
		mach_msg_type_number_t SourceInfoSize = sizeof(SourceInfo)/sizeof(int);
        mach_port_t ObjectName = MACH_PORT_NULL;
		
        double PercentDone = 0.0;
        [pBar setDoubleValue:0.0];
        [pBar setHidden:false];
        [pBar displayIfNeeded];
        
#ifdef __LP64__
        while(KERN_SUCCESS == (KernelResult = vm_region_64(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO_64,(vm_region_info_64_t) &SourceInfo,&SourceInfoSize,&ObjectName)))
#else
        while(KERN_SUCCESS == (KernelResult = vm_region(MySlaveTask,&SourceAddress,&SourceSize,VM_REGION_BASIC_INFO,(vm_region_info_t) &SourceInfo,&SourceInfoSize,&ObjectName)))
#endif
        {
            // If we get here then we have a block of memory and we know how big it is... let's copy writable blocks and see what we've got!
            PercentDone = 100.0 * SourceAddress / BarMaxValue; // bar represents position in total app memory
            if ((PercentDone - [pBar doubleValue]) > 0.25)
            {
                [pBar setDoubleValue:PercentDone];
                [pBar displayIfNeeded];
            }
            
			
            if ((SourceInfo.protection & VM_PROT_WRITE) && (SourceInfo.protection & VM_PROT_READ))
            {
				Byte *ReturnedBuffer = nil;
				NS_DURING
                ReturnedBuffer = malloc(SourceSize);
                vm_size_t ReturnedBufferContentSize = SourceSize;
                if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,SourceAddress,SourceSize,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
					(ReturnedBufferContentSize > 0) )
                {
					uint SearchSize = Bytes;
					
					// Note: we cannot assume memory alignment so each address could be the start of our multi-byte value
					
					// incrementing addresses instead of calculating offsets for speed
					Byte* valuePosition;
					Byte* valueEnd;
					Byte* resetDestPosition;
					Byte* endDestPosition = ReturnedBuffer + ReturnedBufferContentSize - SearchSize;
					Byte* destPosition = ReturnedBuffer;
					while(destPosition <= endDestPosition)
					{
						// speed processing by skipping all these calcs when we have no match
						// NOTE: No match happens more often then match
						if (destPosition[0] == Value[0])
						{
							// store the destPosition to reset position without expensive calculation
							resetDestPosition = destPosition;
							valuePosition = Value; // we just tested position 0 (first byte) so start pointing there so that we can check to see if we are done with inner loop
							valueEnd = Value + SearchSize - 1; // we stop when we've checked all bytes in the search value
							do
							{
								if (valueEnd == valuePosition) // success
								{
									[AddrList addObject:[[[AppAddressData alloc] initWithValues:(vm_address_t)(SourceAddress + (resetDestPosition - ReturnedBuffer)) val:ValueString] autorelease]];
									break;
								}
								else // not yet done testing all bytes
								{
									// set indexes so we can test next bytes
									valuePosition++;
									destPosition++;
								}
							} while (destPosition[0] == valuePosition[0]); // continue ONLY if we still match at this byte position
							
							// back where we started -- testing is complete for now (we may OR may not have found a match, but we dont care any more)
							destPosition = resetDestPosition;
						}
						destPosition++; // start search on the next character in the destination byte array
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
    vm_address_t MyAddrRecAddress;
    NSUInteger recCount = [Addrs count];

    bool isMatchingValue;
    vm_size_t ReturnedBufferContentSize;
	
    double PercentDone = 0.0;
    [pBar setDoubleValue:0.0];
    [pBar setHidden:false];
    [pBar displayIfNeeded];
	
    Byte *ReturnedBuffer = malloc(Bytes);
	NSUInteger x;
    NS_DURING
    for (x=recCount; x>0 ; /* Decrementing in body at beginning of use instead of end */ ) // count down so we can remove from object array by index number
    {
        PercentDone = 100.0 * (recCount - x) / recCount;
        if (PercentDone - [pBar doubleValue] > 0.25)
        {
            [pBar setDoubleValue:PercentDone];
            [pBar displayIfNeeded];
        }
        
        isMatchingValue = false;
		x--;
        MyAddrRec = [Addrs objectAtIndex:x];
        MyAddrRecAddress = [MyAddrRec address];
        NS_DURING
		ReturnedBufferContentSize = Bytes;
		if ( (KERN_SUCCESS == vm_read_overwrite(MySlaveTask,MyAddrRecAddress,Bytes,(vm_address_t)ReturnedBuffer,&ReturnedBufferContentSize)) &&
			(ReturnedBufferContentSize > 0) )
		{
			if (ReturnedBufferContentSize == (uint)Bytes)
			{
				NSUInteger y;
				isMatchingValue = true;
				for (y=Bytes ; isMatchingValue && (y>0) ; /* Decrementing in body at beginning of use instead of end */ )
				{
					y--;
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

- (bool)saveDataForAddress:(vm_address_t)Address Buffer:(Byte *)DataBuffer BufLength:(int)Bytes
{
    bool retVal;
	NS_DURING
    retVal = (KERN_SUCCESS == vm_write(MySlaveTask,Address,(vm_offset_t)DataBuffer,Bytes));
	NS_HANDLER
    retVal = false;
	NS_ENDHANDLER
	
    return retVal;
}

- (bool)loadDataForAddress:(vm_address_t)Address Buffer:(Byte *)DataBuffer BufLength:(vm_size_t)Bytes
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
