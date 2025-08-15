package dxcagg::logging;

use strict;
use warnings;
use POSIX qw(strftime);

sub log_message {
    my ($message, $level) = @_;
    $level //= 'info';  # Default to 'info' if no level is provided

    # if($level <= 1){
        my $filename = '/var/log/dxcagg/dxcagg.log';
        my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime); #localtime();
        open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
        say $fh "[$timestamp] [$level] $message";
        close $fh;
    # }
}

1;