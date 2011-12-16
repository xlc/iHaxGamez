//
//  Logger.c
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-16.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

const char * const _MLogLevelName[] = {
    "Debug",
    "Info",
    "Warn",
    "Error",
};

#ifdef DEBUG

#import <unistd.h>
#import <sys/sysctl.h>

// From: http://developer.apple.com/mac/library/qa/qa2004/qa1361.html
int _MIsInDebugger(void) {
    static int result = -1;
    if (result != -1)
        return result;
    
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
        // Initialize the flags so that, if sysctl fails for some bizarre
        // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
        // Initialize mib, which tells sysctl the info we want, in this case
        // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
        // Call sysctl.
    
    size = sizeof(info);
    sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    
        // We're being debugged if the P_TRACED flag is set.
    result = (info.kp_proc.p_flag & P_TRACED) != 0;
    return result;
}

#endif