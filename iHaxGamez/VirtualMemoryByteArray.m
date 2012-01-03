//
//  VirtualMemoryByteArray.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-31.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "VirtualMemoryByteArray.h"

#import <mach/mach_error.h>

#import "PrivilegedHelperConnection.h"

@implementation VirtualMemoryByteArray
- (id)initWithPID:(pid_t)pid address:(vm_address_t)address offset:(vm_offset_t)offset size:(vm_offset_t)size {
    MASSERT(offset < size, @"offset %ld greater than size %ld", offset, size);
    self = [super init];
    if (self) {
        _pid = pid;
        _startAddress = address;
        _offset = offset;
        void *data;
        mach_msg_type_number_t returnedSize;
        kern_return_t kr = helper_vm_read(_pid, _startAddress, size, &data, &returnedSize);
        if (kr != KERN_SUCCESS) {
            MILOG(@"fail to create VitrualMemoryByteSlice, error: %s", mach_error_string(kr));
            self = nil;
            return nil;
        }
        _buffer = [[NSMutableData alloc] initWithBytes:data length:returnedSize];
        helper_vm_free(data, returnedSize);
    }
    return self;
}

#pragma mark -

- (unsigned long long)length {
    return [_buffer length] - _offset;
}

- (void)copyBytes:(unsigned char *)dst range:(HFRange)lrange {
    MASSERT(lrange.location + 1 + _offset < [_buffer length], @"invalid range");
    lrange.length = MIN(lrange.length, [_buffer length] - _offset - lrange.location);
    const void *bytes = [_buffer bytes];
    memcpy(dst, bytes+_offset+lrange.location, lrange.length);
}

- (HFByteArray *)subarrayWithRange:(HFRange)lrange {
    MASSERT(lrange.location + 1 + _offset < [_buffer length], @"invalid range");
    lrange.length = MIN(lrange.length, [_buffer length] - _offset - lrange.location);	
    VirtualMemoryByteArray *array = [[[self class] alloc] init];
    array->_pid = _pid;
    array->_startAddress = _startAddress;
    array->_offset = _offset + lrange.location;
    array->_buffer = _buffer;
    return array;
}

- (NSArray *)byteSlices {
    return [NSArray arrayWithObject:[[HFFullMemoryByteSlice alloc] initWithData:_buffer]];
}

- (void)insertByteSlice:(HFByteSlice *)slice inRange:(HFRange)lrange {
    [self incrementGenerationOrRaiseIfLockedForSelector:_cmd];
    NSUInteger length = ll2l([slice length]);
    NSRange range;
    range.location = ll2l(lrange.location);
    range.length = ll2l(lrange.length);
    
    void* buff = malloc(length);
    [slice copyBytes:buff range:HFRangeMake(0, length)];
    [_buffer replaceBytesInRange:range withBytes:buff length:length];
    helper_vm_write(_pid, _startAddress+lrange.location, buff, (mach_msg_type_number_t)lrange.length);
    free(buff); 
}

@end