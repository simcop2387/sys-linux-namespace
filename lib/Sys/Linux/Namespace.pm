package Sys::Linux::Namespace;

use strict;
use warnings;

use Sys::Linux::Mount qw/:all/;
use Sys::Linux::Unshare qw/:all/;
use POSIX qw/_exit/;

sub namespace {
    my ($options) = @_;

    my $uflags = 0;
    my $mflags = 0;

    my $post_setup = sub {
        # If we want a private /tmp, or private mount we need to recursively make every mount private.  it CAN be done without that but this is more reliable.
        if ($options->{private_mount} || $options->{private_tmp}) {
            mount("/", "/", undef, MS_REC|MS_PRIVATE, undef);
        }

        if ($options->{private_tmp}) {
            if (ref $options->{private_tmp} eq 'HASH') {
                mount("/tmp", "/tmp",  "tmpfs", MS_PRIVATE, $options->{private_tmp});
            } elsif (ref $options->{private_tmp}) {
                die "Bad ref type passed as private_tmp";
            } else {
                mount("/tmp", "/tmp", "tmpfs", MS_PRIVATE, undef);
            }
        }
    };

    if (ref $options->{pid} eq 'CODE') {
      $uflags |= CLONE_NEWPID;
    } elsif (ref $options->{pid}) {
      die "New PID namespace requires a coderef";
    }

    if ($options->{mount} || $options->{private_mount} || $options->{private_tmp}) {
        $uflags |= CLONE_NEWNS;
    }

    if ($options->{net}) {
        die "TODO, need to setup network interfaces";
    }

    if (ref $options->{pid} eq 'CODE') {
      my $mid_pid = fork();

      unless($mid_pid == -1) {
          if($mid_pid) {
            # Original Process
            waitpid($mid_pid); # WE MUST BLOCK
            return; # don't run anything else in here
          } else {
            # Middle child process
            unshare($uflags); # Setup the namespaces
            $post_setup->();
            my $child_pid = fork();

            unless($child_pid == -1) {
              if ($child_pid) {
                waitpid($child_pid);
              } else {
                $options->{pid}->();
              }
              
              # exit and do no cleanup, don't continue running the program, or any END{} blocks
              # This is so that we don't cause anything to go wrong in the parent because something was left around
              _exit(0);
            } else {
              die "Couldn't make PID 1: $!";
            }
          }
      } else {
          die "Couldn't fork $!";
      }
    } else {
        unshare($uflags);
        $post_setup->();
    }
}
