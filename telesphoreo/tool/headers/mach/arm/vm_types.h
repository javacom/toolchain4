#ifndef _MACH_ARM_VM_TYPES_H_
#define _MACH_ARM_VM_TYPES_H_

#include <arm/_types.h>
#include <stdint.h>

typedef __darwin_natural_t natural_t;
typedef int integer_t;

typedef natural_t vm_offset_t;
typedef natural_t vm_size_t;

typedef uint64_t mach_vm_address_t;
typedef uint64_t mach_vm_offset_t;
typedef uint64_t mach_vm_size_t;

#define MACH_MSG_TYPE_INTEGER_T MACH_MSG_TYPE_INTEGER_32

#endif

