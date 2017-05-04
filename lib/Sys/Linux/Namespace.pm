package Sys::Linux::Namespace;
# ABSTRACT: Sets up linux kernel namespaces

use strict;
use warnings;

use Sys::Linux::Mount qw/:all/;
use Sys::Linux::Unshare qw/:all/;
use POSIX qw/_exit/;

use Moo;
use Carp qw/carp/;

has private_tmp   => (is => 'rw');
has private_mount => (is => 'rw');
has private_pid   => (is => 'rw');
has private_net   => (is => 'rw');

has code => (is => 'rw'); # code to run in the namespace

sub _uflags {
  my $self = shift;
  my $uflags = 0;

  $uflags |= CLONE_NEWNS if ($self->private_tmp || $self->private_mount);
  $uflags |= CLONE_NEWPID if ($self->private_pid);
  $uflags |= CLONE_NEWNET if ($self->private_net);

  return $uflags;
}

sub _subprocess {
  my ($self, $code, %args) = @_;
  die "_subprocess requires a CODE ref" unless ref $code eq 'CODE';

  my $pid = fork();

  carp "Failed to fork: $!" if ($pid < 0);
  if ($pid) {
    waitpid($pid, 0); # block and wait on child
    return $?;
  } else {
    $code->(%args);
    _exit(0);
  }
}

sub pre_setup {
  my ($self, %args) = @_;

  die "Private net is not yet supported" if $self->private_net;
  if ($self->private_pid && 
        ((ref $self->code ne 'CODE') || 
         (ref $args{code} ne 'CODE'))) {

    die "Private PID space requires a coderef to become the new PID 1";
  }
}

sub post_setup {
  my ($self, %args) = @_;
  # If we want a private /tmp, or private mount we need to recursively make every mount private.  it CAN be done without that but this is more reliable.
  if ($self->private_mount || $self->private_tmp) {
      mount("/", "/", undef, MS_REC|MS_PRIVATE, undef);
  }

  if ($self->private_tmp) {
      if (ref $self->private_tmp eq 'HASH') {
          mount("/tmp", "/tmp", "tmpfs", 0, undef);
          mount("/tmp", "/tmp", "tmpfs", MS_PRIVATE, $self->private_tmp);
      } elsif (ref $self->private_tmp) { # TODO do this with a constraint?
          die "Bad ref type passed as private_tmp";
      } else {
          mount("/tmp", "/tmp", "tmpfs", 0, undef);
          mount("/tmp", "/tmp", "tmpfs", MS_PRIVATE, undef);
      }
  }
}

sub setup {
  my ($self, %args) = @_;

  my $uflags = $self->_uflags;
 
  $self->pre_setup(%args);
  
  my $code = $args{code} // $self->code();

  if ($code) {
    $self->_subprocess(sub {
      unshare($uflags);

      # We've just unshared, if we wanted a private pid space we MUST fork again.
      if ($self->private_pid) {
        $self->_subprocess(sub {
          $self->post_setup(%args);
          $code->(%args);
        }, %args);
      } else {
        $self->post_setup(%args);
        $code->(%args);
      }
    }, %args);
  } else {
    unshare($uflags);
    $self->post_setup(%args);
  }

  return 1;
}

1;
