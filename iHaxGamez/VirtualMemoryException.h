//
//  VirtualMemoryException.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-26.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VirtualMemoryException : NSException

+ (id)exceptionWithPID:(pid_t)pid address:(mach_vm_address_t)address kernReturn:(kern_return_t)kr;

@end
