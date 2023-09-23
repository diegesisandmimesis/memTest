#charset "us-ascii"
//
// memTest.t
//
#include <adv3.h>
#include <en_us.h>

#include "memTest.h"

#ifdef __DEBUG_MEM_TEST

modify memTest
	debug(msg) { log(msg); }
;

#endif // __DEBUG_MEM_TEST
