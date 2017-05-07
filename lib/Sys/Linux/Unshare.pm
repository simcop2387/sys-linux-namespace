package Sys::Linux::Unshare;

#use strict;
use warnings;
use Data::Dumper;
require Exporter;
our @ISA = qw/Exporter/;
use Carp qw/croak/;

require XSLoader;

XSLoader::load();

my @unshare_consts = qw/CSIGNAL CLONE_VM CLONE_FS CLONE_FILES CLONE_SIGHAND CLONE_PTRACE CLONE_VFORK CLONE_PARENT CLONE_THREAD CLONE_NEWNS CLONE_SYSVSEM CLONE_SETTLS CLONE_PARENT_SETTID CLONE_CHILD_CLEARTID CLONE_DETACHED CLONE_UNTRACED CLONE_CHILD_SETTID CLONE_NEWCGROUP CLONE_NEWUTS CLONE_NEWIPC CLONE_NEWUSER CLONE_NEWPID CLONE_NEWNET CLONE_IO/;

our @EXPORT_OK = (@unshare_consts, qw/unshare/);

our %EXPORT_TAGS = (
    'consts' => \@unshare_consts,
    'all' => [@unshare_consts, qw/unshare/],
);

sub clone {
  my ($flags) = @_;
  local $! = 0;
  my $ret_pid = _clone_sys($flags);

  if ($ret_pid < 0) {
    croak "Clone call failed: $ret_pid $!";
  }

  return $ret_pid;
}

sub unshare {
    my ($flags) = @_;

    local $! = 0;
    my $ret = _unshare_sys($flags);

    if ($ret != 0) {
        croak "unshare failed $ret $!";
    }

    return;
}

use constant {CSIGNAL =>              0x000000ff,
             CLONE_VM =>             0x00000100,
             CLONE_FS =>             0x00000200,
             CLONE_FILES =>          0x00000400,
             CLONE_SIGHAND =>        0x00000800,
             CLONE_PTRACE =>         0x00002000,
             CLONE_VFORK =>          0x00004000,
             CLONE_PARENT =>         0x00008000,
             CLONE_THREAD =>         0x00010000,
             CLONE_NEWNS =>          0x00020000,
             CLONE_SYSVSEM =>        0x00040000,
             CLONE_SETTLS =>         0x00080000,
             CLONE_PARENT_SETTID =>  0x00100000,
             CLONE_CHILD_CLEARTID => 0x00200000,
             CLONE_DETACHED =>       0x00400000,
             CLONE_UNTRACED =>       0x00800000,
             CLONE_CHILD_SETTID =>   0x01000000,
             CLONE_NEWCGROUP =>      0x02000000,
             CLONE_NEWUTS =>         0x04000000,
             CLONE_NEWIPC =>         0x08000000,
             CLONE_NEWUSER =>        0x10000000,
             CLONE_NEWPID =>         0x20000000,
             CLONE_NEWNET =>         0x40000000,
             CLONE_IO =>             0x80000000};

1;
  
