//
//  PrivilegedHelperConnection.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-17.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrivilegedHelperConnection : NSObject {
@private
    NSMachPort *childReceiveMachPort;
}

+ (PrivilegedHelperConnection *)sharedConnection;
- (BOOL)launchAndConnect:(NSError **)error;
- (BOOL)connectIfNecessary;
- (BOOL)sayHello;

@end

kern_return_t helper_vm_region(pid_t pid, mach_vm_address_t *address, mach_vm_size_t *size);
kern_return_t helper_vm_read(pid_t pid, mach_vm_address_t address, size_t size, Byte **data, mach_msg_type_number_t *dataSize);
kern_return_t helper_vm_write(pid_t pid, mach_vm_address_t address, Byte *data, mach_msg_type_number_t size);
void helper_vm_free(Byte *data, size_t size);