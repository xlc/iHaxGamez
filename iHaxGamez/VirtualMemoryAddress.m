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
    }
    return self;
}

#pragma mark -

- (int64_t)signedIntegerValue {
    int64_t value = 0;
    size_t size = MIN(sizeof(value), _size - _offset);
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, MIN(returnedSize, size));   // assume little endian
    helper_vm_free(data, returnedSize);
    if (_value.eightTimes)
        value /= 8;
    return value;
}

- (uint64_t)unsignedIntegerValue {  // TODO shouldn't copy paste code
    uint64_t value = 0;
    size_t size = MIN(sizeof(value), _size - _offset);
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);   // assume little endian
    helper_vm_free(data, returnedSize);
    if (_value.eightTimes)
        value /= 8;
    return value;
}

- (double)doubleValue {
    double value = 0;
    size_t size = sizeof(value);
    if (_size - _offset < size) {
        return NAN;
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);
    helper_vm_free(data, returnedSize);
    if (_value.eightTimes)
        value /= 8;
    return value;
}

- (float)floatValue {   // TODO shouldn't copy paste code
    float value = 0;
    size_t size = sizeof(value);
    if (_size - _offset < size) {
        return NAN;
    }
    void *data;
    mach_msg_type_number_t returnedSize;
    MASSERT_KERN(helper_vm_read(_pid, _address, size, &data, &returnedSize));
    memcpy(&value, data, returnedSize);
    helper_vm_free(data, returnedSize);
    if (_value.eightTimes)
        value /= 8;
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

- (BOOL)refreshValue {
    void *data = NULL;
    mach_msg_type_number_t size;
    size_t maxSize = MIN(_value.maxSize, _size - _offset);
    kern_return_t kr = helper_vm_read(_pid, _address, maxSize, &data, &size);
    if (kr == KERN_SUCCESS) {
        _value = [[VariableValue alloc] initWithData:data size:_value.size maxSize:size type:_value.type];
        helper_vm_free(data, size);
        return _value != nil;
    }
    MDLOG(@"relash filed with error: %s", mach_error_string(kr));
    return NO;
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
    BOOL eightTimes = _value.eightTimes;
    _value = [[VariableValue alloc] initWithValue:newValue type:newType];
    if (eightTimes) {
        _value = [_value eightTimesValue];
    }
    MASSERT_KERN(helper_vm_write(_pid, _address, _value.data, (mach_msg_type_number_t)_value.size));
    return YES;
}

@end
