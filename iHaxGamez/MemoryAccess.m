//
//  MemoryAccess.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-20.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "MemoryAccess.h"

#import <mach/vm_types.h>
#import <mach/mach_types.h>

#import "PrivilegedHelperConnection.h"
#import "VariableValue.h"
#import "VirtualMemoryAddress.h"

@implementation MemoryAccess

+ (void)searchValue:(VariableValue *)value pid:(pid_t)pid option:(NSInteger)option callback:(void (^)(double percent, NSArray *result, BOOL done))callback {
    if (![self checkProcessAlive:pid]) return;
    callback = [callback copy];
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:1000];
    mach_vm_address_t address = 0;
    mach_vm_size_t size = 0;
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    __block int count = 0;
    __block int totalCount = 0;
    __block BOOL totalCountValid = NO;
    size_t minSize;
    if (option & SearchOptionLimitSizeRange) {
        minSize = sizeof(int32_t);
    } else {
        minSize = sizeof(int8_t);
    }
    if (option & SearchOptionEightTimesMode) {
        value = [value eightTimesValue];
    }
    while (helper_vm_region(pid, &address, &size) == KERN_SUCCESS) {
        totalCount++;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            void *buffer = NULL;
            mach_msg_type_name_t bufferSize;
            NSMutableArray *localResult;
            if (helper_vm_read(pid, address, size, &buffer, &bufferSize) == KERN_SUCCESS) {
                localResult = [NSMutableArray arrayWithCapacity:100];
                size_t remain = size - value.size;
                void *endAddress = buffer + remain;
                for (void *localAddress = buffer; localAddress <= endAddress; localAddress++) {
                    VariableType type;
                    if ([value compareAtAddress:localAddress minSize:minSize maxSize:remain matchedType:&type]) {
                        VariableValue *newValue = [[VariableValue alloc] initWithValue:value type: type];
                        VirtualMemoryAddress *vmAddr = [[VirtualMemoryAddress alloc] initWithPID:pid startAddress:address offset:localAddress-buffer size:size value:newValue];
                        [localResult addObject:vmAddr];
                    }
                    remain--;
                }
                
            }
            if (buffer)
                helper_vm_free(buffer, bufferSize);
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            count++;
            if (localResult)
                [result addObjectsFromArray:localResult];
            dispatch_semaphore_signal(semaphore);
            
            if (totalCountValid) {
                BOOL done = count == totalCount;
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback((double)count/(double)totalCount, result, done);
                });
                if (done) {
                    @synchronized(result) { // make sure semaphore only get free once
                        if (semaphore) {
                            dispatch_release(semaphore);
                            semaphore = NULL;
                        }
                    }
                }
            }
        });
        address += size;
    }
    totalCountValid = YES;
    
}

+ (void)filterDatas:(NSArray *)datas withValue:(VariableValue *)value callback:(void (^)(double percent, NSArray *result, BOOL done))callback {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[datas count] / 100 + 10];
    __block dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);
    __block NSUInteger count = 0;
    NSUInteger totalCount = [datas count];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_apply([datas count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t i) {
            VirtualMemoryAddress *vmAddr = [datas objectAtIndex:i];
            VariableType matchedType;
            BOOL found = NO;
            if (vmAddr.locked) {
                found = YES;
            } else if ([vmAddr refreshValue] && [value compareAtAddress:vmAddr.value.data minSize:vmAddr.value.size maxSize:vmAddr.value.maxSize matchedType:&matchedType]) {
                if (matchedType != vmAddr.value.type)   // update type if need
                    vmAddr.value = [[VariableValue alloc] initWithValue:vmAddr.value type:matchedType];
                found = YES;
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (found)
                [result addObject:vmAddr];
            count++;
            dispatch_semaphore_signal(semaphore);
            BOOL done = count == totalCount;
            dispatch_async(dispatch_get_main_queue(), ^{
                callback((double)count/(double)totalCount, result, done);
            });
            if (done) {
                @synchronized(result) {
                    if (semaphore) {
                        dispatch_release(semaphore);
                        semaphore = NULL;
                    }
                }
            }
        });
    });
}

+ (BOOL)checkProcessAlive:(pid_t)pid {
    ProcessSerialNumber psn;
    if (GetProcessForPID(pid, &psn) == 0) {
        return YES;
    } else {
        NSAlert *MyAlert = [NSAlert alertWithMessageText:@"The external process could not be accessed."
										   defaultButton:nil
										 alternateButton:nil
											 otherButton:nil 
							   informativeTextWithFormat:@"You may not have rights to access this process, or this process may have ended."];
		[MyAlert runModal];
        return NO;
    }
}

@end
