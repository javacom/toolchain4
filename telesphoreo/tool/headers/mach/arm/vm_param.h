/*
 * Copyright (c) 2000-2004 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * The contents of this file constitute Original Code as defined in and
 * are subject to the Apple Public Source License Version 1.1 (the
 * "License").  You may not use this file except in compliance with the
 * License.  Please obtain a copy of the License at
 * http://www.apple.com/publicsource and read it before using this file.
 * 
 * This Original Code and all software distributed under the License are
 * distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT.  Please see the
 * License for the specific language governing rights and limitations
 * under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@
 */
/*
 * @OSF_COPYRIGHT@
 */
/* 
 * Mach Operating System
 * Copyright (c) 1991,1990,1989,1988 Carnegie Mellon University
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
 * Copyright (c) 1994 The University of Utah and
 * the Computer Systems Laboratory at the University of Utah (CSL).
 * All rights reserved.
 *
 * Permission to use, copy, modify and distribute this software is hereby
 * granted provided that (1) source code retains these copyright, permission,
 * and disclaimer notices, and (2) redistributions including binaries
 * reproduce the notices in supporting documentation, and (3) all advertising
 * materials mentioning features or use of this software display the following
 * acknowledgement: ``This product includes software developed by the
 * Computer Systems Laboratory at the University of Utah.''
 *
 * THE UNIVERSITY OF UTAH AND CSL ALLOW FREE USE OF THIS SOFTWARE IN ITS "AS
 * IS" CONDITION.  THE UNIVERSITY OF UTAH AND CSL DISCLAIM ANY LIABILITY OF
 * ANY KIND FOR ANY DAMAGES WHATSOEVER RESULTING FROM THE USE OF THIS SOFTWARE.
 *
 * CSL requests users of this software to return to csl-dist@cs.utah.edu any
 * improvements that they make and grant CSL redistribution rights.
 *
 */

/*
 *	File:	vm_param.h
 *
 *	ARM machine dependent virtual memory parameters.
 *	Most of the declarations are preceeded by ARM_ (or arm_)
 *	which is OK because only ARM specific code will be using
 *	them.
 */

#ifndef	_MACH_ARM_VM_PARAM_H_
#define _MACH_ARM_VM_PARAM_H_

#define BYTE_SIZE		8		/* byte size in bits */

/* FIXME: is this right? */
#define ARM_PGBYTES	4096	/* bytes per 80386 page */
#define ARM_PGSHIFT	12		/* number of bits to shift for pages */

#define	PAGE_SIZE		ARM_PGBYTES
#define	PAGE_SHIFT		ARM_PGSHIFT
#define	PAGE_MASK		(PAGE_SIZE - 1)



#define VM_MIN_ADDRESS64	((user_addr_t) 0x0000000000000000ULL)
/*
 * default top of user stack... it grows down from here
 */
#define VM_USRSTACK64		((user_addr_t) 0x00007FFF5FC00000ULL)
#define VM_DYLD64		((user_addr_t) 0x00007FFF5FC00000ULL)
#define VM_LIB64_SHR_DATA	((user_addr_t) 0x00007FFF60000000ULL)
#define VM_LIB64_SHR_TEXT	((user_addr_t) 0x00007FFF80000000ULL)
/*
 * the end of the usable user address space , for now about 47 bits.
 * the 64 bit commpage is past the end of this
 */
#define VM_MAX_PAGE_ADDRESS	((user_addr_t) 0x00007FFFFFE00000ULL)
/*
 * canonical end of user address space for limits checking
 */
#define VM_MAX_USER_PAGE_ADDRESS ((user_addr_t)0x00007FFFFFFFF000ULL)



/* system-wide values */
#define MACH_VM_MIN_ADDRESS		((mach_vm_offset_t) 0)
#define MACH_VM_MAX_ADDRESS		((mach_vm_offset_t) VM_MAX_PAGE_ADDRESS)

/* process-relative values (all 32-bit legacy only for now) */
#define VM_MIN_ADDRESS		((vm_offset_t) 0)
#define VM_USRSTACK32		((vm_offset_t) 0xC0000000)
#define VM_MAX_ADDRESS		((vm_offset_t) 0xFFE00000)


#endif	/* _MACH_ARM_VM_PARAM_H_ */

