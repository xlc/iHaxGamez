//
//  VirtualMemoryException.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-26.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "VirtualMemoryException.h"

#import <mach/mach_error.h>

@implementation VirtualMemoryException

+ (id)exceptionWithPID:(pid_t)pid address:(mach_vm_address_t)address kernReturn:(kern_return_t)kr {
    NSString *reason = [NSString stringWithFormat:@"Cannot access address %p for pid %d with error %s", address, pid, mach_error_string(kr)];
    return [self exceptionWithName:@"VirtualMemoryException" reason:reason userInfo:nil];
}

@end
