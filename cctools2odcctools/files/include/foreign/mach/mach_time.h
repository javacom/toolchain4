#ifndef _MACH_TIME_H
#define _MACH_TIME_H
#include <mach/mach.h>
#include <stdint.h>
struct mach_timebase_info {
	uint32_t numer;
	uint32_t denom;
};
typedef struct mach_timebase_info   *mach_timebase_info_t;
typedef struct mach_timebase_info   mach_timebase_info_data_t;

#ifdef __cplusplus
extern "C" {
#endif
kern_return_t     mach_timebase_info( mach_timebase_info_t info);
uint64_t       mach_absolute_time(void);
#ifdef __cplusplus
}
#endif
#endif
