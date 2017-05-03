package Sys::Linux::Namespace;

use strict;
use warnings;

use Sys::Linux::Mount qw/:all/;
use Sys::Linux::Unshare qw/:all/;

sub namespace {
    my ($options) = @_;

    my $uflags = 0;
    my $mflags = 0;

    if ($options->{pid}) {
        die "TODO, need to setup a proper 'init' PID 1";
    }

    if ($options->{mount} || $options->{private_mount} || $options->{private_tmp}) {
        $uflags |= CLONE_NEWNS;
    }

    if ($options->{net}) {
        die "TODO, need to setup network interfaces";
    }

    unshare($uflags);

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
}
