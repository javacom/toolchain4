/*
 * Copyright (c) 2000-2007 Apple Inc. All rights reserved.
 *
 * @APPLE_OSREFERENCE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. The rights granted to you under the License
 * may not be used to create, or enable the creation or redistribution of,
 * unlawful or unlicensed copies of an Apple operating system, or to
 * circumvent, violate, or enable the circumvention or violation of, any
 * terms of an Apple operating system software license agreement.
 * 
 * Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_OSREFERENCE_LICENSE_HEADER_END@
 */
/* 
 * Mach Operating System
 * Copyright (c) 1991,1990,1989,1988,1987 Carnegie Mellon University
 * All Rights Reserved.
 * 
 * Permission to use, copy, modify and distribute this software and its
 * documentation is hereby granted, provided that both the copyright
 * notice and this permission notice appear in all copies of the
 * software, derivative works or modified versions, and any portions
 * thereof, and that both notices appear in supporting documentation.
 * 
 * CARNEGIE MELLON ALLOWS FREE USE OF THIS SOFTWARE IN ITS "AS IS"
 * CONDITION.  CARNEGIE MELLON DISCLAIMS ANY LIABILITY OF ANY KIND FOR
 * ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 * 
 * Carnegie Mellon requests users of this software to return to
 * 
 *  Software Distribution Coordinator  or  Software.Distribution@CS.CMU.EDU
 *  School of Computer Science
 *  Carnegie Mellon University
 *  Pittsburgh PA 15213-3890
 * 
 * any improvements or extensions that they make and grant Carnegie Mellon
 * the rights to redistribute these changes.
 */
/*
 */
/*
 * File: mach/vm_statistics.h
 * Author:  Avadis Tevanian, Jr., Michael Wayne Young, David Golub
 *
 * Virtual memory statistics structure.
 *
 */


#ifndef  _MACH_VM_STATISTICS_H_
#define  _MACH_VM_STATISTICS_H_
#include <mach/machine/vm_types.h>

struct vm_statistics {
   natural_t   free_count;    /* # of pages free */
   natural_t   active_count;     /* # of pages active */
   natural_t   inactive_count;      /* # of pages inactive */
   natural_t   wire_count;    /* # of pages wired down */
   natural_t   zero_fill_count;  /* # of zero fill pages */
   natural_t   reactivations;    /* # of pages reactivated */
   natural_t   pageins;    /* # of pageins */
   natural_t   pageouts;      /* # of pageouts */
   natural_t   faults;        /* # of faults */
   natural_t   cow_faults;    /* # of copy-on-writes */
   natural_t   lookups;    /* object cache lookups */
   natural_t   hits;       /* object cache hits */

   /* added for rev1 */
   natural_t   purgeable_count;  /* # of pages purgeable */
   natural_t   purges;        /* # of pages purged */

   /* added for rev2 */
   /*
    * NB: speculative pages are already accounted for in "free_count",
    * so "speculative_count" is the number of "free" pages that are
    * used to hold data that was read speculatively from disk but
    * haven't actually been used by anyone so far.
    */
   natural_t   speculative_count;   /* # of pages speculative */
};

typedef struct vm_statistics  *vm_statistics_t;
typedef struct vm_statistics  vm_statistics_data_t;


/* included for the vm_map_page_query call */

#define VM_PAGE_QUERY_PAGE_PRESENT      0x1
#define VM_PAGE_QUERY_PAGE_FICTITIOUS   0x2
#define VM_PAGE_QUERY_PAGE_REF          0x4
#define VM_PAGE_QUERY_PAGE_DIRTY        0x8
#define VM_PAGE_QUERY_PAGE_PAGED_OUT    0x10
#define VM_PAGE_QUERY_PAGE_COPIED       0x20
#define VM_PAGE_QUERY_PAGE_SPECULATIVE 0x40


#endif
