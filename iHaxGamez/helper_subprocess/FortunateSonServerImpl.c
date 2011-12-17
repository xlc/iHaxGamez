#include "FortunateSonServer.h"
#include <stdio.h>
#include <limits.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <stdarg.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/disk.h>
#include <sys/stat.h>
#include <sys/sysctl.h>
#include <mach/mach_vm.h>
#include <mach/mach_init.h>
#include <mach/vm_map.h>
#include <mach/task.h>
#include <mach/mach_traps.h>
#include <mach/mach_error.h>
#include <mach/machine.h>
#include <mach/vm_prot.h>

static void print_error(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
static void print_error(const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    va_end(argp);
    fflush(stderr);
}

static mach_port_name_t check_task_for_pid(pid_t pid) {
    mach_port_name_t task = MACH_PORT_NULL;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS) {
        print_error("failed to get task for pid %d\nmach error: %s\n", pid, (char*) mach_error_string(kr));
        exit(-1);
    }
    return task;
}

kern_return_t _FortunateSonSayHey(mach_port_t server, int *result) {
    fprintf(stderr, "Hey guys this is my function \n");
    *result = getuid();
    return KERN_SUCCESS;
}

kern_return_t _FortunateSonVMRegion (mach_port_t server, int pid, mach_vm_address_t *address, mach_vm_size_t *size) {
    kern_return_t kr;
    vm_region_basic_info_data_64_t info;
    mach_msg_type_number_t infoCount = VM_REGION_BASIC_INFO_COUNT_64;
    mach_vm_address_t localAddress = *address;
    mach_vm_size_t localSize;
    mach_port_t unused;
    int isReadWrite = 0;
        // find next readwriteable vm region
    do {
        kr = mach_vm_region(check_task_for_pid(pid), &localAddress, &localSize, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &infoCount, &unused);
        if (kr == KERN_SUCCESS) {
            isReadWrite = (info.protection & VM_PROT_WRITE) && (info.protection & VM_PROT_READ);
            if (!isReadWrite) {
                localAddress += localSize;
            } else {
                *address = localAddress;
                *size = localSize;
            }
        }
    } while (!isReadWrite && kr == KERN_SUCCESS);
    return kr;
}

kern_return_t _FortunateSonVMRead (mach_port_t server, int pid, mach_vm_address_t address, mach_vm_size_t size, VarData_t *data, mach_msg_type_number_t *dataCnt) {
    kern_return_t kr;
    vm_offset_t localData;
    mach_msg_type_number_t localCount;
    kr = mach_vm_read(check_task_for_pid(pid), address, size, &localData, &localCount);
    if (kr == KERN_SUCCESS) {
        *dataCnt = localCount;
        *data = (VarData_t)localData;
    }
    return kr;
}

kern_return_t _FortunateSonVMWrite (mach_port_t server, int pid, mach_vm_address_t address, VarData_t data, mach_msg_type_number_t dataCnt
                                    ) {
    kern_return_t kr;
    kr = mach_vm_write(check_task_for_pid(pid), address, (vm_offset_t)data, dataCnt);
    return kr;
}
