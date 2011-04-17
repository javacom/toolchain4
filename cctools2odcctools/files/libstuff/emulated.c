#include <config.h>
#include <mach/mach.h>
#include <mach/mach_error.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <sys/attr.h>
#include <errno.h>
#include <inttypes.h>
#include <mach/mach_time.h>
#include <mach/mach_host.h>
#include <mach/host_info.h>
#include <sys/time.h>

kern_return_t     mach_timebase_info( mach_timebase_info_t info) {
   info->numer = 1;
   info->denom = 1;
   return 0;
}

char            *mach_error_string(mach_error_t error_value)
{
  return "Unknown mach error";
}

mach_port_t mach_host_self(void)
{
  return 0;
}

kern_return_t host_info
(
 host_t host,
 host_flavor_t flavor,
 host_info_t host_info_out,
 mach_msg_type_number_t *host_info_outCnt
 )
{
  if(flavor == HOST_BASIC_INFO) {
    host_basic_info_t      basic_info;

    basic_info = (host_basic_info_t) host_info_out;
    memset(basic_info, 0x00, sizeof(*basic_info));
    basic_info->cpu_type = EMULATED_HOST_CPU_TYPE;
    basic_info->cpu_subtype = EMULATED_HOST_CPU_SUBTYPE;
  }

  return 0;
}

mach_port_t     mach_task_self_ = 0;

kern_return_t mach_port_deallocate
(
 ipc_space_t task,
 mach_port_name_t name
 )
{
  return 0;
}

kern_return_t vm_allocate
(
 vm_map_t target_task,
 vm_address_t *address,
 vm_size_t size,
        int flags
 )
{

  vm_address_t addr = 0;

  addr = (vm_address_t)calloc(size, sizeof(char));
  if(addr == 0)
    return 1;

  *address = addr;

  return 0;
}

kern_return_t vm_deallocate
(
 vm_map_t target_task,
 vm_address_t address,
        vm_size_t size
 )
{
  //  free((void *)address); leak it here

  return 0;
}
kern_return_t host_statistics ( host_t host_priv, host_flavor_t flavor, host_info_t host_info_out, mach_msg_type_number_t *host_info_outCnt)
{
 return ENOTSUP;
}
kern_return_t map_fd(
                     int fd,
                     vm_offset_t offset,
                     vm_offset_t *va,
                     boolean_t findspace,
                     vm_size_t size)
{

  void *addr = NULL;

  addr = mmap(0, size, PROT_READ|PROT_WRITE,
	      MAP_PRIVATE|MAP_FILE, fd, offset);

  if(addr == (void *)-1) {
    return 1;
  }

  *va = (vm_offset_t)addr;

  return 0;
}


uint64_t  mach_absolute_time(void) {
  uint64_t t = 0;
  struct timeval tv;
  if (gettimeofday(&tv,NULL)) return t;
  t = ((uint64_t)tv.tv_sec << 32)  | tv.tv_usec;
  return t;
}


#ifndef HAVE_STRMODE
void strmode(mode_t mode, char *bp)
{
  sprintf(bp, "xxxxxxxxxx");
}
#endif

#ifndef HAVE_QSORT_R
void *_qsort_thunk = NULL;
int (*_qsort_saved_func)(void *, const void *, const void *) = NULL;

static int _qsort_comparator(const void *a, const void *b);

static int _qsort_comparator(const void *a, const void *b)
{
  return _qsort_saved_func(_qsort_thunk, a, b);
}

void
qsort_r(void *base, size_t nmemb, size_t size, void *thunk,
	int (*compar)(void *, const void *, const void *))
{
  _qsort_thunk = thunk;
  _qsort_saved_func = compar;

  qsort(base, nmemb, size, _qsort_comparator);
}

#endif


int    getattrlist(const char* a,void* b,void* c,size_t d,unsigned int e)
{
  errno = ENOTSUP;
  return -1;
}

vm_size_t       vm_page_size = 4096; // hardcoded to match expectations of darwin


#ifndef HAVE_STRLCPY

/*      $OpenBSD: strlcpy.c,v 1.11 2006/05/05 15:27:38 millert Exp $        */

/*
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <sys/types.h>
#include <string.h>


/*
 * Copy src to string dst of size siz.  At most siz-1 characters
 * will be copied.  Always NUL terminates (unless siz == 0).
 * Returns strlen(src); if retval >= siz, truncation occurred.
 */
size_t
strlcpy(char *dst, const char *src, size_t siz)
{
        char *d = dst;
        const char *s = src;
        size_t n = siz;

        /* Copy as many bytes as will fit */
        if (n != 0) {
                while (--n != 0) {
                        if ((*d++ = *s++) == '\0')
                                break;
                }
        }

        /* Not enough room in dst, add NUL and traverse rest of src */
        if (n == 0) {
                if (siz != 0)
                        *d = '\0';                /* NUL-terminate dst */
                while (*s++)
                        ;
        }

        return(s - src - 1);        /* count does not include NUL */
}

#endif
