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

static void print_error(const char *fmt, ...) __attribute__ ((format (printf, 1, 2)));
static void print_error(const char *fmt, ...) {
    va_list argp;
    va_start(argp, fmt);
    vfprintf(stderr, fmt, argp);
    va_end(argp);
    fputc('\n', stderr);
    fflush(stderr);
}

static void *allocate_mach_memory(vm_size_t *size) {
    vm_size_t localSize = mach_vm_round_page(*size);
    void *localAddress = NULL;
    kern_return_t kr = vm_allocate(mach_task_self(), (vm_address_t *)&localAddress, localSize, VM_FLAGS_ANYWHERE);
    if (kr != KERN_SUCCESS) {
        fprintf(stdout, "failed to vm_allocate(%ld)\nmach error: %s\n", (long)localSize, (char*)mach_error_string(kr));
        exit(-1);
    }
    *size = localSize;
    return (void *)localAddress;
}

static void free_mach_memory(void *ptr, vm_size_t size) {
    kern_return_t kr = vm_deallocate(mach_task_self(), (vm_address_t)ptr, size);
    if (kr != KERN_SUCCESS) {
	fprintf(stdout, "failed to vm_deallocate(%p)\nmach error: %s\n", ptr, (char*) mach_error_string(kr));
	exit(-1);
    }    
}

kern_return_t _FortunateSonSayHey(mach_port_t server, int *result) {
    fprintf(stderr, "Hey guys this is my function \n");
    *result = getuid();
    return KERN_SUCCESS;
}

static mach_port_name_t check_task_for_pid(pid_t pid) {
    mach_port_name_t task = MACH_PORT_NULL;
    kern_return_t kr = task_for_pid(mach_task_self(), pid, &task);
    if (kr != KERN_SUCCESS) {
        fprintf(stdout, "failed to get task for pid %d\nmach error: %s\n", pid, (char*) mach_error_string(kr));
        exit(-1);
    }
    return task;
}

kern_return_t _FortunateSonVMRegion (mach_port_t server, int pid, mach_vm_address_t *address, mach_vm_size_t *size) {
    return KERN_SUCCESS;
}

kern_return_t _FortunateSonVMRead (mach_port_t server, int pid, mach_vm_address_t address, mach_vm_size_t size, vm_offset_t *data, mach_msg_type_number_t *dataCnt) {
    return KERN_SUCCESS;
}

kern_return_t _FortunateSonVMWrite (mach_port_t server, int pid, mach_vm_address_t address, vm_offset_t data, mach_msg_type_number_t dataCnt
 ) {
    return KERN_SUCCESS;
}
