//
//  VirtualMemoryAddress.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-18.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "VirtualMemoryAddress.h"

#import "VariableValue.h"
#import "PrivilegedHelperConnection.h"
#import <mach/mach_error.h>

@implementation VirtualMemoryAddress

@synthesize address = _address, value = _value;

- (id)initWithPID:(pid_t)pid address:(mach_vm_address_t)address value:(VariableValue *)value {
    self = [super init];
    if (self) {
        _pid = pid;
        _address = address;
        _value = value;
    }
    return self;
}

- (void)reflashValue {
    void *data = NULL;
    mach_msg_type_number_t size;
    MASSERT_KERN(helper_vm_read(_pid, _address, _value.size, &data, &size));
    _value = [[VariableValue alloc] initWithData:data size:size type:_value.type];
    if (data)
        helper_vm_free(data, size);
    
}

- (BOOL)updateValue:(VariableValue *)newValue {
    VariableType newType = newValue.type;
    if (newValue.type != _value.type) {
        if (VariableTypeIsNumeric(_value.type) != VariableTypeIsNumeric(newValue.type))
            return NO;
        switch (newValue.type) {
            case VariableTypeUnsignedInteger:
            case VariableTypeASCII:
            case VariableTypeFloat:
                newType = _value.type;
                break;
                
            case VariableTypeInteger:
                if (_value.type == VariableTypeFloat || _value.type == VariableTypeDouble)
                    newType = _value.type;
                break;
                
            case VariableTypeDouble:
            case VariableTypeUnicode:
                break;
        }
    }
    _value = [[VariableValue alloc] initWithValue:newValue type:newType];
    kern_return_t kr = helper_vm_write(_pid, _address, _value.data, (mach_msg_type_number_t)_value.size);
    MASSERT(kr == KERN_SUCCESS, @"cannot write to address: %p for pid: %d with error: %s", (void *)_address, _pid, mach_error_string(kr));
    return YES;
}

@end
