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

- (id)initWithPID:(pid_t)pid
     startAddress:(mach_vm_address_t)startAddress
           offset:(mach_vm_offset_t)offset
             size:(mach_vm_size_t)size
            value:(VariableValue *)value; {
    self = [super init];
    if (self) {
        _startAddress = startAddress;
        _offset = offset;
        _size = size;
        _pid = pid;
        _value = value;
        _address = _startAddress + _offset;
        _lastAddress = _startAddress + _size + 1;   // first invalid address
    }
    return self;
}

#pragma mark -

- (int64_t)signedIntegerValue {
    int64_t value = 0;
    size_t size = sizeof(int64_t);
    if (_address+size > _lastAddress) {
        size = sizeof(int32_t);
        if (_address+size > _lastAddress) {
            size = sizeof(int16_t);
            if (_address+size > _lastAddress)
                size = sizeof(int8_t);
        }
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, MIN(returnedSize, size));   // assume little endian
    helper_vm_free(data, returnedSize);
    return value;
}

- (uint64_t)unsignedIntegerValue {  // TODO shouldn't copy paste code
    uint64_t value = 0;
    size_t size = sizeof(int64_t);
    if (_address+size > _lastAddress) {
        size = sizeof(int32_t);
        if (_address+size > _lastAddress) {
            size = sizeof(int16_t);
            if (_address+size > _lastAddress)
                size = sizeof(int8_t);
        }
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);   // assume little endian
    helper_vm_free(data, returnedSize);
    return value;
}

- (double)doubleValue {
    double value = 0;
    size_t size = sizeof(value);
    if (_address+size > _lastAddress) {
        return NAN;
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);
    helper_vm_free(data, returnedSize);
    return value;
}

- (float)floatValue {   // TODO shouldn't copy paste code
    float value = 0;
    size_t size = sizeof(value);
    if (_address+size > _lastAddress) {
        return NAN;
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);
    helper_vm_free(data, returnedSize);
    return value;
}

- (NSString *)asciiValue {
    size_t maxLength = _size - _offset + 1;
    if (maxLength > 20)
        maxLength = 20;
    NSString *value = @"";
    char *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, maxLength, (void **)&data, &returnedSize));
    data[returnedSize-1] = '\0';    // so it is a null terminated c string
    value = [[NSString alloc] initWithCString:data encoding:NSASCIIStringEncoding];
    helper_vm_free(data, returnedSize);
    return value;
}

- (NSString *)unicodeValue {    // TODO shouldn't copy paste code
    size_t maxLength = _size - _offset;
    if (maxLength > 20)
        maxLength = 20;
    NSString *value = @"";
    char *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, maxLength, (void **)&data, &returnedSize));
    data[returnedSize-1] = '\0';    // so it is a null terminated c string
    value = [[NSString alloc] initWithCString:data encoding:NSUnicodeStringEncoding];
    helper_vm_free(data, returnedSize);
    return value;
}

#pragma mark -

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
    MASSERT_KERN(helper_vm_write(_pid, _address, _value.data, (mach_msg_type_number_t)_value.size));
    return YES;
}

@end
