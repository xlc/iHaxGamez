//
//  PrivilegedHelperConnection.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-17.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//
//  Modified from HFPrivilegedHelperConnection from HexFiend

#import "PrivilegedHelperConnection.h"

#import "HelperProcessSharedCode.h"
#import "FortunateSon.h"
#import <ServiceManagement/ServiceManagement.h>
#import <Security/Authorization.h>
#import <mach/mach_vm.h>

static PrivilegedHelperConnection *sharedConnection;

@interface PrivilegedHelperConnection ()

- (BOOL)getMachPort:(mach_port_t *)port;

@end

@implementation PrivilegedHelperConnection

+ (PrivilegedHelperConnection *)sharedConnection {
    if (!sharedConnection) {
        sharedConnection = [[self alloc] init];
    }
    return sharedConnection;
}

- (BOOL)connectIfNecessary {
    if (childReceiveMachPort == nil) {
        NSError *oops = nil;
        if (! [self launchAndConnect:&oops]) {
            if (oops) [NSApp presentError:oops];
        }
    }
    return [childReceiveMachPort isValid];
}

- (BOOL)launchAndConnect:(NSError **)error {
    /* If we're already connected, we're done */
    if ([childReceiveMachPort isValid]) return YES;
    
    /* Guess not. This is probably the first connection. */
    [childReceiveMachPort invalidate];
    [childReceiveMachPort release];
    childReceiveMachPort = nil;
    int err = 0;
    
    /* Our label and port name happen to be the same */
    CFStringRef label = CFSTR(kPrivilegedHelperLaunchdLabel);
    NSString *portName = @kPrivilegedHelperLaunchdLabel;
    
    /* Always remove the job if we've previously submitted it. This is to help with versioning (we always install the latest tool). It also avoids conflicts where the installed tool was signed with a different key (i.e. someone building Hex Fiend while also having run the signed distribution). A potentially negative consequence is that we have to authenticate every launch, but that is actually a benefit, because it serves as a sort of notification that user's action requires elevated privileges, instead of just (potentially silently) doing it. */
    BOOL helperIsAlreadyInstalled = NO;
    CFDictionaryRef existingJob = SMJobCopyDictionary(kSMDomainSystemLaunchd, label);
    if (existingJob) {
        helperIsAlreadyInstalled = YES;
        CFRelease(existingJob);
    }
    
    if (!helperIsAlreadyInstalled) {
        
        /* Decide what rights to authorize with. If the helper is not installed, we only need the privileged helper; if it is installed we need ModifySystemDaemons too, to uninstall it. */
        AuthorizationItem authItems[2] = {{ kSMRightBlessPrivilegedHelper, 0, NULL, 0 }, { kSMRightModifySystemDaemons, 0, NULL, 0 }};
        AuthorizationRights authRights = { (helperIsAlreadyInstalled ? 2 : 1), authItems };
        AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
        AuthorizationRef authRef = NULL;
        
        /* Now authorize. */
        err = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
        if (err != errAuthorizationSuccess) {
            if (error) {
                if (err == errAuthorizationCanceled) {
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil];
                } else {
                    NSString *description = [NSString stringWithFormat:@"Failed to create AuthorizationRef (error code %ld).", (long)err];
                    *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadNoPermissionError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:description, NSLocalizedDescriptionKey, nil]];
                }
            }
        }
        
        /* Remove the existing helper. If this fails it's not a fatal error (SMJobBless can handle the case when a job is already installed). */
        if (! err && helperIsAlreadyInstalled) {
            CFErrorRef localError = NULL;
            SMJobRemove(kSMDomainSystemLaunchd, label, authRef, true /* wait */, &localError);
            if (localError) {
                NSLog(@"SMJobRemove() failed with error %@", localError);
                CFRelease(localError);
            }
        }
        
        /* Bless the job */
        if (! err) {
            CFErrorRef localError = NULL;
            err = ! SMJobBless(kSMDomainSystemLaunchd, label, authRef, (CFErrorRef *)&localError);
            if (localError) {
                if (error) *error = [[(id)localError retain] autorelease];
                CFRelease(localError);
            }
        }
        
        /* Done with any AuthRef */
        if (authRef) AuthorizationFree(authRef, kAuthorizationFlagDestroyRights);
	}
    
    /* Get the port for our helper as provided by launchd */
    NSMachPort *helperLaunchdPort = nil;
    if (! err) {
        NSMachBootstrapServer *boots = [NSMachBootstrapServer sharedInstance];
        helperLaunchdPort = (NSMachPort *)[boots portForName:portName];
        err = ! [helperLaunchdPort isValid];
    }
    
    /* Create our own port, and give it a send right */
    mach_port_t ourSendPort = MACH_PORT_NULL;
    if (! err) err = mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_RECEIVE, &ourSendPort);
    if (! err) err = mach_port_insert_right(mach_task_self(), ourSendPort, ourSendPort, MACH_MSG_TYPE_MAKE_SEND);
    
    /* Tell our privileged helper about it, moving the receive right over */
    if (! err) err = send_port([helperLaunchdPort machPort], ourSendPort, MACH_MSG_TYPE_MOVE_RECEIVE);
    
    /* Now we have the ability to send on this port, and only the privileged helper can receive on it. We are responsible for cleaning up the send right we created. */
    if (! err) childReceiveMachPort = [[NSMachPort alloc] initWithMachPort:ourSendPort options:NSMachPortDeallocateSendRight];
    
    /* Done with helperLaunchdPort */
    [helperLaunchdPort invalidate];
	return ! err;
}

- (BOOL)getMachPort:(mach_port_t *)port {
    if (![self connectIfNecessary]) return NO;
    *port = [childReceiveMachPort machPort];
    return YES;
}

#pragma mark -

- (BOOL)sayHello {
    if (! [self connectIfNecessary]) return NO;
    int result = -1;
    kern_return_t kr = _GratefulFatherSayHey([childReceiveMachPort machPort], &result);
    MASSERT_KERN(kr);
    return kr == KERN_SUCCESS;
}

@end

kern_return_t helper_vm_region(pid_t pid, mach_vm_address_t *address, mach_vm_size_t *size) {
    mach_port_t port;
    if (![[PrivilegedHelperConnection sharedConnection] getMachPort:&port]) return KERN_FAILURE;
    return _GratefulFatherVMRegion(port, pid, address, size);
}

kern_return_t helper_vm_read(pid_t pid, mach_vm_address_t address, size_t size, void **data, mach_msg_type_number_t *dataSize) {
    mach_port_t port;
    if (![[PrivilegedHelperConnection sharedConnection] getMachPort:&port]) return KERN_FAILURE;
    kern_return_t kr = _GratefulFatherVMRead(port, pid, address, size, (VarData_t *)data, dataSize);
    return kr;    
}

kern_return_t helper_vm_write(pid_t pid, mach_vm_address_t address, void *data, mach_msg_type_number_t size) {
    mach_port_t port;
    if (![[PrivilegedHelperConnection sharedConnection] getMachPort:&port]) return KERN_FAILURE;
    kern_return_t kr;
    kr = _GratefulFatherVMWrite(port, pid, address, data, size);
    return kr;
}

void helper_vm_free(void *data, size_t size) {
    MASSERT_KERN(mach_vm_deallocate(mach_task_self(), (vm_offset_t)data, size));
}