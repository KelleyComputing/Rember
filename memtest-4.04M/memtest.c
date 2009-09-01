/*
 * memtest version 4.04M
 *
 * Very simple but very effective user-space memory tester.
 * Originally by Simon Kirby <sim@stormix.com> <sim@neato.org>
 * Version 2 by Charles Cazabon <memtest@discworld.dyndns.org>
 * Version 3 not publicly released.
 * Version 4 rewrite:
 * Copyright (C) 2004 Charles Cazabon <memtest@discworld.dyndns.org>
 * Copyright (C) 2004 Tony Scaminaci (Version 4.04M port to Macintosh)
 * Licensed under the terms of the GNU General Public License version 2 (only).
 * See the file COPYING for details.
 *
 */

#define __version__ "4.04M"
#define EXIT_FAIL_NONSTARTER    0x01
#define EXIT_FAIL_ADDRESSLINES  0x02
#define EXIT_FAIL_OTHERTEST     0x04

#include <stddef.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <unistd.h>
#include <errno.h>

#include "types.h"
#include "sizes.h"
#include "tests.h"

// MacOS X includes (Tony Scaminaci 8/2004)

#include <sys/sysctl.h>
#include <mach/mach.h>
#include <mach/bootstrap.h>
#include <mach/host_info.h>
#include <mach/mach_error.h>
#include <mach/mach_types.h>
#include <mach/message.h>
#include <mach/vm_region.h>
#include <mach/vm_map.h>
#include <mach/vm_types.h>
#include <mach/vm_prot.h>
#include <mach/shared_memory_server.h>

// MacOS X global variables

vm_size_t		mac_pagesize;

// MacOS X function prototypes

unsigned long GetFreeMem(void);

struct test tests[] = {
	{ "Random Value", test_random_value },
	{ "Compare XOR", test_xor_comparison },
	{ "Compare SUB", test_sub_comparison },
	{ "Compare MUL", test_mul_comparison },
	{ "Compare DIV",test_div_comparison },
	{ "Compare OR", test_or_comparison },
	{ "Compare AND", test_and_comparison },
	{ "Sequential Increment", test_seqinc_comparison },
	{ "Solid Bits", test_solidbits_comparison },
	{ "Block Sequential", test_blockseq_comparison },
	{ "Checkerboard", test_checkerboard_comparison },
	{ "Bit Spread", test_bitspread_comparison },
	{ "Bit Flip", test_bitflip_comparison },
	{ "Walking Ones", test_walkbits1_comparison },
	{ "Walking Zeroes", test_walkbits0_comparison },
	{ NULL, NULL }
};

#ifdef _SC_VERSION
void check_posix_system(void)
  {
    if (sysconf(_SC_VERSION) < 198808L)
	  {
        fprintf(stderr, "A POSIX system is required.  Don't be surprised if "
            "this craps out.\n");
        fprintf(stderr, "_SC_VERSION is %lu\n", sysconf(_SC_VERSION));
      }
	else
		printf("POSIX version %lu\n", sysconf(_SC_VERSION));
  }
#else
#define check_posix_system()
#endif

#ifdef _SC_PAGE_SIZE
size_t memtest_pagesize(void)
  {
    int pagesize = sysconf(_SC_PAGE_SIZE);
    if (pagesize == -1)
	  {
        perror("get page size failed");
        exit(EXIT_FAIL_NONSTARTER);
      }
    printf("Pagesize is %ld\n", pagesize);
    return pagesize;
  }
#else
size_t memtest_pagesize(void)
  {
	GetFreeMem();
	printf("Pagesize is %lu\n", (unsigned long) mac_pagesize);
	return mac_pagesize;
  }
#endif

// For MacOS X, get amount of free physical RAM at the instant GetFreeMem is called
// Added by Tony Scaminaci 8/15/2004

unsigned long GetFreeMem()
{
  vm_statistics_data_t	vm_stat;
  mach_port_t			host_priv_port, host_port;
  int					host_count;
  kern_return_t			kern_error;
  unsigned long			FreeMem;		// Free real (physical) memory

// Get host machine information

  mach_port_t get_host_priv()
	{
	  return(mach_host_self());
	}

  mach_port_t get_host_port()
	{
	  return(mach_host_self());
	}

// Get total system-wide memory usage structure
    
  host_priv_port = get_host_priv();
  host_port = get_host_port();
  host_count = sizeof(vm_stat)/sizeof(integer_t);
  kern_error = host_statistics(host_priv_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_count);
  if (kern_error != KERN_SUCCESS)
	{
	  mach_error("host_info", kern_error);
	  exit(EXIT_FAILURE);
	}
  host_page_size(host_port, &mac_pagesize);			// Get page size for this machine    
  FreeMem = (vm_stat.free_count) * mac_pagesize;	// Calculate total free memory in bytes
  FreeMem = FreeMem & 0xFFFFFFC0;					// Make sure it's a multiple of 64 bytes
  return(FreeMem);
}

// Check current user level. If it's 0, we're in single-user mode, if it's 1,
// we're in multiuser mode.

int	get_user_level()
  {
	int		Selectors[2] = {CTL_KERN, KERN_SECURELVL};
	int		UserLevel;
	size_t	Length = sizeof(UserLevel);
	
	sysctl(Selectors, 2, &UserLevel, &Length, NULL, 0);
	return UserLevel;
  }

int main(int argc, char **argv) {
    ul loop, i;
	int loops;
    size_t pagesize, wantmb, wantbytes, bufsize, halflen, count;
    ptrdiff_t pagesizemask;
    void volatile *buf, *aligned;
    ulv *bufa, *bufb;
    int do_mlock = 1, done_mem = 0;
	int exit_code = 0;
	unsigned long MemAvail, MBAvail;			// Physical memory available for testing
	int	user_level;								// Single-user or multiuser mode

    printf("\nMemtest version " __version__ " (%d-bit)\n", UL_LEN);
    printf("Copyright (C) 2004 Charles Cazabon\n");
	printf("Copyright (C) 2004 Tony Scaminaci (Macintosh port)\n");
    printf("Licensed under the GNU General Public License version 2 only\n\n");
	if (argc < 2)
	  {
		fprintf(stderr, "ERROR: Amount of memory to be tested (argument 2) is missing.\n");
		fprintf(stderr, "       Relaunch with memory test size in MB or 'all'.\n\n");
        exit(1);
	  }
	user_level = get_user_level();
	if (!user_level)
	  printf("MacOS X (Darwin) running in single-user mode\n");
	else
	  printf("MacOS X (Darwin) running in multi-user mode\n");
	check_posix_system();
	pagesize = memtest_pagesize();
    pagesizemask = (ptrdiff_t) ~(pagesize - 1);
    printf("Pagesizemask is 0x%tx\n", pagesizemask);
	MemAvail = GetFreeMem();
	MBAvail = MemAvail >> 20;
	if (!strcmp(argv[1], "all") || !strcmp(argv[1], "ALL"))
	    wantmb = (size_t) MBAvail;
	else
		wantmb = (size_t) strtoul(argv[1], NULL, 0);
    wantbytes = (size_t) (wantmb << 20);
	printf("Requested memory: %lluMB (%llu bytes)\n", (ull) wantmb, (ull) wantbytes);
	printf("Available memory: %lluMB (%llu bytes)\n", (ull) MBAvail, (ull) MemAvail);
    if (wantbytes < pagesize)
	  {
        fprintf(stderr, "\nERROR: Memory test size in MB (argument 2) must be a positive integer or 'all'.\n\n");
	        exit(EXIT_FAIL_NONSTARTER);
      }
	if (user_level && wantmb > MBAvail)					// Limit memory allocation in multiuser modes
	  {
		fprintf(stderr, "NOTE: Memory request is too large, reducing to acceptable value...\n");
		wantbytes = (size_t) (MBAvail << 20);			// Guarantee that no paging will occur
	  }
	if (!user_level && wantmb > (size_t) (MBAvail * 0.977))	// Limit memory allocation further in single-user mode
	  {
		fprintf(stderr, "NOTE: Memory request is too large, reducing to acceptable value\n");
		wantbytes = (size_t) ((size_t) (MBAvail * 0.977) << 20);	// Prevent the kernel from becoming unresponsive
	  }
    if (argc < 3)
	  {
        loops = 0;
      }
	else
	  {
        loops = strtoul(argv[2], NULL, 0);
		if (loops < 0)
		  loops = 0;
      }
	  
    buf = NULL;

    while (!done_mem) {
        while (!buf && wantbytes) {
            buf = (void volatile *) malloc(wantbytes);
            if (!buf) wantbytes -= pagesize;
        }
        bufsize = wantbytes;
        printf("Allocated memory: %lluMB (%llu bytes)\n", (ull) wantbytes >> 20, 
            (ull) wantbytes);
        fflush(stdout);
        if ((size_t) buf % pagesize) {
            /* printf("aligning to page\n"); */
            aligned = (void volatile *) ((size_t) buf & pagesizemask);
            bufsize -= ((size_t) aligned - (size_t) buf);
        } else {
            aligned = buf;
        }
        /* Try memlock */
		printf("Attempting to lock allocated physical memory....");
        if (mlock((void *) aligned, bufsize) < 0)
		  {
            switch(errno)
			  {
                case ENOMEM:
                    printf("WARNING: Too many pages requested - reducing requested amount....\n\n");
                    free((void *) buf);
                    buf = NULL;
                    wantbytes -= pagesize;
                    break;
                case EPERM:
                    printf("ERROR: Insufficient permissions - please log in with an admin account\n\n");
                    do_mlock = 0;
                    done_mem = 1;
                    break;
                default:
                    printf("ERROR: Mlock failer - reason unknown.\n\n");
                    do_mlock = 0;
                    done_mem = 1;
             }
		  }
		else
		  {
            printf("memory locked successfully\n\n");
            done_mem = 1;
          }
    }

    if (!do_mlock) fprintf(stderr, "WARNING: Continuing with unlocked memory - testing "
        "will be slower and less reliable\n\n");

    halflen = bufsize / 2;
    count = halflen / sizeof(ul);
    bufa = (ulv *) aligned;
    bufb = (ulv *) ((size_t) aligned + halflen);
	if (!loops)
	  printf("NOTE: Test sequences will run continuously until terminated by Ctrl-C...\n\n");
	else
	  {
		if (loops == 1)
		  printf("Running %d test sequence...\n\n", loops);
		else
		  printf("Running %d test sequences...\n\n", loops);
	  }
    for(loop = 1; ((!loops) ||  loop <= loops); loop++) {
        printf("Test sequence %lu", loop);
        if (loops) {
            printf(" of %d", loops);
        }
        printf(":\n");
    	printf("  %-20s: ", "Stuck Address");
    	fflush(stdout);
    	if (!test_stuck_address(aligned, bufsize / sizeof(ul)))
		  printf("ok\n");
		else
		  exit_code |= EXIT_FAIL_ADDRESSLINES;		
    	for (i=0;;i++) {
		  if (!tests[i].name) break;
		    printf("  %-20s: ", tests[i].name);
		  if (!tests[i].fp(bufa, bufb, count))
			printf("ok\n");
		  else
			exit_code |= EXIT_FAIL_OTHERTEST;
		  fflush(stdout);
    	}
    	printf("\n");
    	fflush(stdout);
    }
    if (do_mlock) munlock((void *) aligned, bufsize);
	printf("All tests passed.\n\n");
	fflush(stdout);
    exit(0);
}
