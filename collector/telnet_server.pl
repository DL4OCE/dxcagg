#!/usr/bin/perl

use strict;
use warnings;
use IO::Socket::INET;
use POSIX qw(setsid);
use POSIX qw(strftime);
use POSIX ":sys_wait_h";

use lib '/var/www/html/dxcagg/lib/';
use dxcagg::logging; 

use Data::Dumper;
$Data::Dumper::Terse = 1;
$Data::Dumper::Useqq = 1;

my $socket = new IO::Socket::INET (
    LocalHost => '192.168.6.25',
    LocalPort => '7373',
    Proto => 'tcp',
    Listen => SOMAXCONN,
    ReuseAddr => 1
);

my $waitedpid = 0;
my $client_data;
my $client_socket;
my $phase = "before_login";
my $logged_in = 0;

sub REAPER {
    local $!;   # don't let waitpid() overwrite current error
    &dxcagg::logging::log_message("[dxgagg telnet server] Client disconnected", "info");
    while ((my $pid = waitpid(-1, WNOHANG)) > 0 && WIFEXITED($?)) {
        &dxcagg::logging::log_message("[dxgagg telnet server] Closed Game ID:$pid : WaitPid:$waitedpid", "info");
        # logmsg "Closed Game ID:$pid : WaitPid:$waitedpid : " . ($? ? " with exit $?" : "");
    }
    $SIG{CHLD} = \&REAPER;  # loathe SysV
}
#if we get the CHLD signal call REAPER sub
$SIG{CHLD} = \&REAPER;

&dxcagg::logging::log_message("[dxgagg telnet server] Ready and waiting for connection", "info");

while(1){
    next unless $client_socket = $socket->accept();
    &dxcagg::logging::log_message("[dxgagg telnet server] Incoming Connection", "info");
    my $pid = fork();

    next if $pid; #NEXT if $pid exists (parent)

    #As Child
    setsid();
    my $proc = $$;

    &dxcagg::logging::log_message("[dxgagg telnet server] Proc ID: $proc", "info");

    # get information about a newly connected player
    my $source_address = $client_socket->peerhost();
    my $source_port    = $client_socket->peerport();
    &dxcagg::logging::log_message("[dxgagg telnet server] -> Connection from $source_address:$source_port", "info");

    my $response = "-------------------------------------------------------------------
|                                                                 |
|        Welcome to the DL4OCE V6 AR-Cluster Telnet Server        |
|             Located near Braunschweig, Germany                  |
|                 Serving filtered spots                          |
|                                                                 |
|                 Configure your personal filter at:              |
|                       http://1.2.3.4/dxcagg/                    |
|                                                                 |
-------------------------------------------------------------------
At the login prompt please enter your amateur radio callsign.
Please enter your call:";
    $client_socket->send($response);

    while ($client_socket->connected()) {
        $client_socket->recv($client_data, 1024);
            if ($client_data) {
                # printf "$client_data\n";
                print Dumper $client_data;
                if($logged_in == 1){
                    if($client_data eq "exit\r\n" || $client_data eq "quit\r\n") {
                        &dxcagg::logging::log_message("[dxgagg telnet server] -> Disconnected: $source_address:$source_port", "info");
                        $client_socket->close();
                        last;
                    }
                }
            }
    }
    last;
}
exit;


sub timestamp {
    my $epoc_seconds = time();
    my $time = strftime "%H:%M:%S", localtime($epoc_seconds);
    my $date = strftime "%m/%d/%Y", localtime;
    my $return = $date . " " . $time;
    return ($return);
}