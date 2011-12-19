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
    mach_vm_address_t _address;
    VariableValue *_value;
}

@property (nonatomic, readonly) mach_vm_address_t address;
@property (nonatomic, readonly) VariableValue *value;

- (id)initWithPID:(pid_t)pid address:(mach_vm_address_t)address value:(VariableValue *)value;

- (void)reflashValue;
- (BOOL)updateValue:(VariableValue *)newValue;

@end
