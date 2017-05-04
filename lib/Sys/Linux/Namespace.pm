package Sys::Linux::Namespace;
# ABSTRACT: Sets up linux kernel namespaces

use strict;
use warnings;

use Sys::Linux::Mount qw/:all/;
use Sys::Linux::Unshare qw/:all/;
use POSIX qw/_exit/;

use Moo;
use Carp qw/croak/;

use Data::Dumper;

has no_proc => (is => 'rw');

for my $p (qw/tmp mount pid net ipc user uts sysvsem/) {
  my $pp = "private_$p";
  has $pp => (is => 'rw');
}

sub _uflags {
  my $self = shift;
  my $uflags = 0;

  $uflags |= CLONE_NEWNS if ($self->private_tmp || $self->private_mount || ($self->private_pid && !$self->no_proc));
  $uflags |= CLONE_NEWPID if ($self->private_pid);
  $uflags |= CLONE_NEWNET if ($self->private_net);
  $uflags |= CLONE_NEWIPC if ($self->private_ipc);
  $uflags |= CLONE_NEWUSER if ($self->private_user);
  $uflags |= CLONE_NEWUTS if ($self->private_uts);
  $uflags |= CLONE_SYSVSEM if ($self->private_sysvsem);

  return $uflags;
}

sub _subprocess {
  my ($self, $code, %args) = @_;
  croak "_subprocess requires a CODE ref" unless ref $code eq 'CODE';

  my $pid = fork();

  croak "Failed to fork: $!" if ($pid < 0);
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

  croak "Private net is not yet supported" if $self->private_net;
  if ($self->private_pid && (ref $args{code} ne 'CODE' || !$args{_run})) {
    warn Dumper(\%args);
    croak "Private PID space requires a coderef to become the new PID 1";
  }
}

sub post_setup {
  my ($self, %args) = @_;
  # If we want a private /tmp, or private mount we need to recursively make every mount private.  it CAN be done without that but this is more reliable.
  if ($self->private_tmp || $self->private_mount || ($self->private_pid && !$self->no_proc)) {
      mount("/", "/", undef, MS_REC|MS_PRIVATE, undef);
  }

  if ($self->private_tmp) {
    my $data = undef;
    $data = $self->private_tmp if (ref $self->private_tmp eq 'HASH');

    mount("none", "/tmp", "tmpfs", 0, undef);
    mount("none", "/tmp", "tmpfs", MS_PRIVATE, $data);
  }

  if ($self->private_pid && !$self->no_proc) {
    mount("proc", "/proc", "proc", MS_MGC_VAL, undef);
    mount("proc", "/proc", "proc", MS_PRIVATE|MS_REC, undef);
  }
}

sub setup {
  my ($self, %args) = @_;

  warn Dumper(\%args);
  my $uflags = $self->_uflags;
  $self->pre_setup(%args);
  
  unshare($uflags);
  $self->post_setup(%args);

  return 1;
}

sub run {
  my ($self, %args) = @_;

  my $code = $args{code};
  $args{_run} = 1;

  croak "Run must be given a codref to run" unless ref $code eq "CODE";

  $self->_subprocess(sub {
    $self->setup(%args);

    # We've just unshared, if we wanted a private pid space we MUST fork again.
    if ($self->private_pid) {
      $self->_subprocess(sub {
        $code->(%args);
      }, %args);
    } else {
      $code->(%args);
    }
  }, %args);

  return 1;
}

1;

__END__
=head1 NAME

Sys::Linux::Namespace - A Module for setting up linux namespaces

=head1 SYNOPSIS

    use Sys::Linux::Namespace;
    
    # Create a namespace with a private /tmp
    my $ns1 = Sys::Linux::Namespace->new(private_tmp => 1);
    
    $ns1->run(code => sub {
        # This code has it's own completely private /tmp filesystem
        open(my $fh, "</tmp/private");
        print $fh "Hello Void";
    });	
    
    # The private /tmp has been destroyed and we're back to our previous state
    
    # Let's do it again, but this time with a private PID space too
    my $ns2 = Sys::Linux::Namespace->new(private_tmp => 1, private_pid => 1);
    $ns2->run(code => sub {
        # I will only see PID 1.  I can fork anything I want and they will only see me
        # if I die they  die too.
        use Data::Dumper;
        print Dumper([glob "/proc/*"]);
    });
    # We're back to our previous global /tmp and PID namespace
    # all processes and private filesystems have been removed
    
    # Now let's set up a private /tmp for the rest of the process 
    $ns1->setup();
    # We're now permanently (for this process) using a private /tmp.

=head1 REQUIREMENTS

This module requires your script to have CAP_SYS_ADMIN, usually by running as C<root>.  Without that it will fail to setup the namespaces and cause your program to exit.

=head1 METHODS

=head2 C<new>

Construct a new Sys::Linux::Namespace object.  This collects all the options you want to enable, but does not engage them.

All arguments are passed in like a hash.

=over 1

=item private_mount

Setup a private mount namespace, this makes every currently mounted filesystem private to our process.
This means we can unmount and mount new filesystems without other processes seeing the mounts.

=item private_tmp

Sets up the private mount namespace as above, but also automatically sets up /tmp to be a clean private tmpfs mount.
Takes either a true value, or a hashref with options to pass to the mount syscall.  See C<man 8 mount> for a list of possible options.

=item private_pid

Create a private PID namespace.  This requires the use of C<< ->run() >>.
This requires a C<code> parameter either to C<new()> or to C<setup()>
Also sets up a private /proc mount by default

=item no_proc

Don't setup a private /proc mount when doing private_pid

=item private_net

TODO This is not yet implemented.  Once done however, it will allow a child process to execute with a private network preventing communication.  Will require a C<code> parameter to C<new()> or C<setup>.

=item private_ipc

Create a private IPC namespace.

=item private_user

Create a new user namespace.  See C<man 7 user_namespaces> for more information.

=item private_uts

Create a new UTS namespace.  This will let you safely change the hostname of the system without affect anyone else.

=item private_sysvsem

Create a new System V Semaphore namespace.  This will let you create new semaphores without anyone else touching them.

=back

=head2 C<setup>

Engage the namespaces with all the configured options.

=head2 C<run>

Engage the namespaces on an unsuspecting coderef.  Arguments are passed in like a hash

=over 1

=item code

The coderef to run.  It will receive all arguments passed to C<< ->run() >> as a hash.

=back

=head1 AUTHOR

Ryan Voots L<simcop@cpan.org|mailto:SIMCOP@cpan.org>

=cut
