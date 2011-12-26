//
//  VirtualMemoryAddress.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-18.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VariableValue;

@interface VirtualMemoryAddress : NSObject {
@private
    pid_t _pid;
    mach_vm_address_t _startAddress;
    mach_vm_offset_t _offset;
    mach_vm_size_t _size;
    mach_vm_address_t _address;
    
    VariableValue *_value;
}

@property (nonatomic, readonly) mach_vm_address_t address;
@property (nonatomic, readonly) VariableValue *value;
@property (nonatomic, readonly) int64_t signedIntegerValue;
@property (nonatomic, readonly) uint64_t unsignedIntegerValue;
@property (nonatomic, readonly) double doubleValue;
@property (nonatomic, readonly) float floatValue;
@property (nonatomic, readonly) NSString *asciiValue;
@property (nonatomic, readonly) NSString *unicodeValue;

- (id)initWithPID:(pid_t)pid
     startAddress:(mach_vm_address_t)startAddress
           offset:(mach_vm_offset_t)offset
             size:(mach_vm_size_t)size
            value:(VariableValue *)value;

- (BOOL)refreshValue;
- (BOOL)updateValue:(VariableValue *)newValue;

@end
