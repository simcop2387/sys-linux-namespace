#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#define _GNU_SOURCE
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <sched.h>

// additional c code goes here
 
MODULE = Sys::Linux::Unshare  PACKAGE = Sys::Linux::Unshare
PROTOTYPES: ENABLE
 
 # XS code goes here
 
 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives
 
int 
_unshare_sys(flags)
int flags
	CODE:
	RETVAL = unshare(flags);

