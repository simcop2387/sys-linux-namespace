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
 
SV * _unshare_sys(int flags)
	CODE:
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), unshare(flags));

SV * _clone_sys(int flags)
	CODE:
	ST(0) = sv_newmortal();
	sv_setiv(ST(0), clone(NULL, NULL, CLONE_CHILD_CLEARTID|SIGCHLD|flags, NULL));
