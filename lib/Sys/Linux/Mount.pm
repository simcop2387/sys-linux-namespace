package Sys::Linux::Mount;

use strict;
use warnings;
require Exporter;
our @ISA = qw/Exporter/;

my @mount_consts = qw/MS_RDONLY MS_NOSUID MS_NODEV MS_NOEXEC MS_SYNCHRONOUS MS_REMOUNT MS_MANDLOCK MS_DIRSYNC MS_NOATIME MS_NODIRATIME MS_BIND MS_MOVE MS_REC MS_SILENT MS_POSIXACL MS_UNBINDABLE MS_PRIVATE MS_SLAVE MS_SHARED MS_RELATIME MS_KERNMOUNT MS_I_VERSION MS_STRICTATIME MS_LAZYTIME MS_ACTIVE MS_NOUSER/;

our @EXPORT_OK = (@mount_consts, qw/mount/);

our %EXPORT_TAGS = (
  'consts' => \@mount_consts,
  'all' => [@mount_consts, qw/mount/],
);

sub mount {
    my ($source, $target, $filesystem, $flags, $options_hr) = @_;

    my $options_str = join ',', map {"$_=".$options_hr->{$_}} keys %$options_hr;

    my $ret = syscall(SYS_mount(), $source, $target, $filesystem//undef, $flags, $options_str);

    if ($ret != 0) {
        die "mount failed: $ret $!";
    }

    return;
}

use constant {MS_RDONLY => 1,        
             MS_NOSUID => 2,        
             MS_NODEV => 4,         
             MS_NOEXEC => 8,        
             MS_SYNCHRONOUS => 16,      
             MS_REMOUNT => 32,      
             MS_MANDLOCK => 64,     
             MS_DIRSYNC => 128,     
             MS_NOATIME => 1024,        
             MS_NODIRATIME => 2048,     
             MS_BIND => 4096,       
             MS_MOVE => 8192,
             MS_REC => 16384,
             MS_SILENT => 32768,
             MS_POSIXACL => 1 << 16,    
             MS_UNBINDABLE => 1 << 17,  
             MS_PRIVATE => 1 << 18,     
             MS_SLAVE => 1 << 19,       
             MS_SHARED => 1 << 20,      
             MS_RELATIME => 1 << 21,    
             MS_KERNMOUNT => 1 << 22,   
             MS_I_VERSION =>  1 << 23,  
             MS_STRICTATIME => 1 << 24, 
             MS_LAZYTIME => 1 << 25,    
             MS_ACTIVE => 1 << 30,
             MS_NOUSER => 1 << 31};

1;
