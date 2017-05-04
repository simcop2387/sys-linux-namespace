#define PERL_NO_GET_CONTEXT // we'll define thread context if necessary (faster)
#include "EXTERN.h"         // globals/constant import locations
#include "perl.h"           // Perl symbols, structures and constants definition
#include "XSUB.h"           // xsubpp functions and macros
#include <sys/mount.h>
 
MODULE = Sys::Linux::Mount  PACKAGE = Sys::Linux::Mount
PROTOTYPES: ENABLE
 
 # XS code goes here
 
 # XS comments begin with " #" to avoid them being interpreted as pre-processor
 # directives
 
int 
_unshare_sys(source, target, filesystem, mount, data)
const char *source
const char *target
const char *filesystem
unsigned long mountflags
const char *data
	CODE:
	return mount(source, target, filesystem, mount, (const void *) data);
