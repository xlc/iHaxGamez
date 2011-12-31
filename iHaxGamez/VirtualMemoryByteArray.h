//
//  VirtualMemoryByteArray.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-31.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <HexFiend/HexFiend.h>

@interface VirtualMemoryByteArray : HFByteArray{
@private
    pid_t _pid;
    vm_address_t _startAddress;
    vm_offset_t _offset;
    NSMutableData *_buffer;
}

- (id)initWithPID:(pid_t)pid address:(vm_address_t)address offset:(vm_offset_t)offset size:(vm_offset_t)size;

@end
