#!/usr/bin/perl

use strict;
use warnings;
use Net::Telnet;
use DBI;
use JSON;
use lib '/var/www/html/dxcagg/lib/';
use dxcagg::logging; 
# use lib '/var/www/html/dxcagg/collector/perl/';
# require './lib/database.pl';
# use lib '/var/www/html/dxcagg/collector/perl/';
# require './lib/database.pl';
# require './lib/database.pl';



# Main entry point
my ($dxc_type, $dxc_hostname, $dxc_port, $dxc_expect_prompt, $dxc_my_call) = @ARGV;
my $telnet;
my $connDB;
my $config;
# my $dbh;

sub read_config {
    my $config_file = "../config/main.json";
    open my $fh, "<", $config_file or die "Cannot open '$config_file': $!";
    local $/;
    my $json_text = <$fh>;
    close $fh;

    return decode_json($json_text);
}

sub main {
    $config = read_config();
    connect_to_database();
    connect_to_dxc();
    while (1) {
        # Read data from DXC
        my $band='';
        my $qrg=0;
        my $mode='';
        my $line = $telnet->getline();
        if ($line) {
            chomp $line;
            &dxcagg::logging::log_message("###### Spot received #####", "info");
            # DX de RU9CZD-#:  21057.8  DK2VM        CW 5 dB 22 WPM CQ              1114Z
            my ($spotter, $qrg, $call, $comment, $utc) = $line =~ m/^DX de\s*(\S*)-#:\s*(\S*)\s*(\S*)\s*(.*)(\d{4})Z$/;
            if( $spotter && $qrg && $call && $utc) {
                # $comment=trim($comment);
                $comment =~ s/^\s+|\s+$//g;
                if (($qrg >= 1810) and ($qrg <= 2000)){
                    $band="160m";
                    if($qrg<=1838){$mode="CW"; }
                }
                if (($qrg >= 3500) and ($qrg <= 3800)){
                    $band="80m";
                    if($qrg<=3580){$mode="CW"; }
                    else {$mode="LSB"; }
                }
                if (($qrg >= 7000) and ($qrg <= 7300)){
                    $band="40m";
                    if($qrg<7035){$mode="CW"; }
                    else {$mode="LSB"; }
                }
                if (($qrg >= 10100) and ($qrg <= 10150)){
                    $band="30m";
                    if($qrg<=10140){$mode="CW"; }
                }
                if (($qrg >= 14000) and ($qrg <= 14350)){
                    $band="20m";
                    if($qrg<=14070){$mode="CW"; }
                    else {$mode="USB"; }
                }
                if (($qrg >= 18068) and ($qrg <= 18168)){
                    $band="17m";
                    if($qrg<=18095){$mode="CW"; }
                    else {$mode="USB"; }
                }
                if (($qrg >= 21000) and ($qrg <= 21450)){
                    $band="15m";
                    if($qrg<=21070){$mode="CW"; }
                    else {$mode="USB"; }
                }
                if (($qrg >= 24890) and ($qrg <= 24990)){
                    $band="12m";
                    if($qrg<=24915){$mode="CW"; }
                    else {$mode="USB"; }
                }
                if (($qrg >= 28000) and ($qrg <= 29700)){
                    $band="10m";
                    if($qrg<=28070){$mode="CW"; }
                    elsif (($qrg>28070) and ($qrg<=29200)) {$mode="USB"; }
                    elsif (($qrg>29200) and ($qrg<=29700)) {$mode="FM"; }
                }
                if (($qrg >= 50000) and ($qrg <= 52000)){
                    $band="6m";
                    if($qrg<=50100){$mode="CW"; }
                    elsif (($qrg>50100) and ($qrg<=50710)) {$mode="USB"; }
                    elsif (($qrg>50710) and ($qrg<=52000)) {$mode="FM"; }
                }
                if (($qrg >= 144000) and ($qrg <= 146000)){
                    $band="2m";
                    if($qrg<=144180){$mode="CW"; }
                    elsif (($qrg>144180) and ($qrg<=144500)) {$mode="USB"; }
                    elsif (($qrg>144500) and ($qrg<=146000)) {$mode="FM"; }
                }
                if (($qrg >= 430000) and ($qrg <= 44000)){
                    $band="70cm";
                    #if($qrg<=28070){$mode="CW"; }
                    #elsif (($qrg>28070) and ($qrg<=29200)) {$mode="USB"; }
                    #elsif (($qrg>29200) and ($qrg<=29700)) {$mode="FM"; }
                }
                # print "Spotter: $spotter, QRG: $qrg, Call: $call, Comment: $comment, UTC: $utc, Band: $band\n";
                &dxcagg::logging::log_message("Spotter: $spotter, QRG: $qrg, Call: $call, Comment: $comment, UTC: $utc, Band: $band", "info");
                # dupe-check
                my $sql = "SELECT COUNT(*) num FROM spot WHERE dx_call='$call' AND utc='$utc' AND band='$band';";
                # print "SQL: $sql\n";
                &dxcagg::logging::log_message("SQL: $sql", "info");
                my $sth = $connDB->prepare($sql);
                $sth->execute();
                my @row = $sth->fetchrow_array;
                my $rows = $row[0];
                # print "rows: $rows\n";
                &dxcagg::logging::log_message("rows: $rows", "info");
                # only store if not a dupe
                if ($row[0] eq 0){ 
                    my $comment = "";
                    $comment =~ s/\s+$//;
                    if($comment =~ m/\<TR\>/i){ my $tropo=1; } else { my $tropo=0; }
                    if($comment =~ m/\<MS\>/i){ my $ms=1; } else { my $ms=0; }
                    #$comment =~ s/[\<\>\;\?\*\/]//;
                    #$comment =~ s/(\<\>\;\?\*\/)//;
                    $comment =~ s/(\<)/\(/;
                    $comment =~ s/(\>)/\)/;
                    $comment =~ s/(\')//;
                    $comment =~ s/(\")//;
                    my $rda = "", my $rda1 = "", my $rda2 = "", my $dok_district = "", my $dok_number = "", my $dok = "", my $source = "", my $iota_number = "", my $iota_continent = "", my $sota_assoc = "", my $sota_region = "", my $sota_number = "", my $qsl_manager = "";
                    my $special_event = 0, my $suffix_p = 0, my $suffix_m = 0, my $suffix_mm = 0, my $suffix_am = 0, my $suffix_qrp = 0, my $suffix_a = 0, my $suffix_lh = 0, my $beacon = 0, my $ms = 0, my $tropo = 0, my $split = 0;

                    if(($comment =~ m/UP /i) or ($comment =~ m/SPLIT /i) or ($comment =~ m/QSX /i) or ($comment =~ m/UP$/i) or ($comment =~ m/SPLIT$/i) or ($comment =~ m/QSX$/i)){ my $split=1; } else { my $split=0; }
                    $qsl_manager = $comment =~ m/QSL VIA\s(\S*)\s.*/i;
                    $qsl_manager = $comment =~ m/VIA\s(\S*)\s.*/i;
                    if ($comment =~ m/RDA\s.*$/i){ ($rda1, $rda2) = $comment =~ m/RDA\s(\S*)-(\d+)\s.*/i; } else { $rda1 = ""; $rda2 = ""; }
                    if ($comment =~ m/RDA:.*$/i){ ($rda1, $rda2) = $comment =~ m/RDA:(\S*)-(\d+)\s.*/i; } else { $rda1 = ""; $rda2 = "";}
                    if ($comment =~ m/SOTA\s.*$/i){ ($sota_assoc, $sota_region, $sota_number) = $comment =~ m/SOTA\s(.+)\/(.+)\-(\d+)\s*/i; } else { $sota_assoc = ""; $sota_region = ""; $sota_number = ""; }
                    if ($comment =~ m/DOK\s.*$/i){ ($dok_district, $dok_number) = $comment =~ m/DOK\s(\s{1})(\d+)\s*/i; } else { $dok_district = ""; $dok_number = 0; }
                    #($rda1, $rda2) = $comment =~ m/RDA\s(.+)\-(\d+)\s*/i;
                    $rda = $rda1 . $rda2;
                    # $iota_continent = "";
                    if($comment =~ m/.*EU-\d+\s*.*$/i){
                        ($iota_number) = $comment =~ m/.*EU\-(\d+).*$/i;
                        $iota_continent = "EU";
                    }
                    if($comment =~ m/.*AF\-\d+\s.*$/i){
                        ($iota_number) = $comment =~ m/.*AF\-(\d+).*$/i;
                        $iota_continent = "AF";
                    }
                    if($comment =~ m/.*AS\-\d+\s.*$/i){
                        ($iota_number) = $comment =~ m/.*AS\-(\d+).*$/i;
                        $iota_continent = "AS";
                    }
                    if($comment =~ m/.*OC\-\d+\s.*$/i){
                        ($iota_number) = $comment =~ m/.*OC\-(\d+).*$/i;
                        $iota_continent = "OC";
                    }
                    if($comment =~ m/.*NA\-\d+\s.*$/i){
                        ($iota_number) = $comment =~ m/.*NA\-(\d+).*$/i;
                        $iota_continent = "NA";
                    }
                    if($comment =~ m/.*SA\-\d+\s.*$/i){
                        ($iota_number) = $comment =~ m/.*SA\-(\d+).*$/i;
                        #($iota) = $comment =~ m/.*SA\-(\d+)\s*.*$/i;
                        $iota_continent = "SA";
                    }

                    if($comment =~ m/special event/i){ ($special_event)=1; } else { ($special_event)=0;}
                    if(($comment =~ m/\/p/i) or ($call =~ m/\/p$/i)){ ($suffix_p)=1; } else { ($suffix_p)=0; }
                    if(($comment =~ m/\/m/i) or ($call =~ m/\/m$/i)){ ($suffix_m)=1; } else { ($suffix_m)=0; }
                    if(($comment =~ m/\/mm/i) or ($call =~ m/\/mm$/i)){ ($suffix_mm)=1; } else { ($suffix_mm)=0; }
                    if(($comment =~ m/\/am/i) or ($call =~ m/\/am$/i)){ ($suffix_am)=1; } else { ($suffix_am)=0; }
                    if(($comment =~ m/\/lh/i) or ($call =~ m/\/lh$/i) or ($comment =~ m/LIGHTHOUSE/i)){ ($suffix_lh)=1; } else { ($suffix_lh)=0; }
                    if(($comment =~ m/\/qrp/i) or ($call =~ m/\/qrp$/i)){ ($suffix_qrp)=1; } else { ($suffix_qrp)=0; }
                    if(($comment =~ m/\/a/i) or ($call =~ m/\/a$/i)){ ($suffix_a)=1; } else { ($suffix_a)=0; }
                    if(($comment =~ m/\/b/i) or ($call =~ m/\/b$/i) or ($comment =~ m/BEACON /i)){ ($beacon)=1; } else { ($beacon)=0; }

                    if(($comment =~ m/PSK31/i) or ($comment =~ m/PSK-31/i)or ($comment =~ m/PSK 31/i)){ ($mode)="PSK31"; }
                    if(($comment =~ m/QPSK31/i) or ($comment =~ m/QPSK-31/i) or ($comment =~ m/QPSK 31/i)){ ($mode)="QPSK31"; }
                    if(($comment =~ m/BPSK31/i) or ($comment =~ m/BPSK-31/i) or ($comment =~ m/BPSK 31/i)){ ($mode)="BPSK31"; }
                    if($comment =~ m/RTTY/i){ ($mode)="RTTY"; }
                    if($comment =~ m/RTTY/i){ ($mode)="SSTV"; }

                    $sql= "INSERT INTO spot (dx_call, utc, qrg_khz, spotter_call, suffix_p, suffix_m, suffix_mm, suffix_am, suffix_qrp, suffix_a, suffix_lh, band, ";
                    $sql  .= "sota_association, sota_region, sota_number, dok_district, dok_number, iota_continent, iota_number, qsl_manager, rda, comment, ";
                    $sql  .= "mode,  ms, tropo, special_event, split, beacon, source) ";
                    $sql  .= "VALUES ('$call', '$utc', $qrg, '$spotter', $suffix_p, $suffix_m, $suffix_mm, $suffix_am, $suffix_qrp, $suffix_a, $suffix_lh, '$band', '$sota_assoc', '$sota_region', '$sota_number', ";
                    $sql  .= "'$dok_district', '$dok_number', '$iota_continent', '$iota_number', '$qsl_manager', '$rda', '$comment', '$mode', $ms, $tropo, $special_event, $split, $beacon, '$dxc_hostname');";
                    # print "SQL: $sql\n";
                    &dxcagg::logging::log_message("SQL: $sql", "info");
                    #print MYOUTFILE "$sql\n";
                    $sth = $connDB->prepare($sql);
                    $sth->execute();
                } else {  
                    # print "Dupe found, not storing: $call $utc $band\n";
                    &dxcagg::logging::log_message("Dupe found, not storing: $call $utc $band", "info");

                }
            }
        # } else {
        #     print "No data received, waiting...\n";
        #     sleep(1);  # Sleep for a while before trying again
        }
    }
}

sub connect_to_database() {
    $connDB = DBI->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password}, { RaiseError => 1, PrintError => 0 });
    # $connDB = DBI->connect("dbi:mysql:database=dxc_agg;host=localhost", "dxc_agg", "baier123", { RaiseError => 1, PrintError => 0 });
    if ($connDB) {
        # print "Connected to the database successfully.\n";
        &dxcagg::logging::log_message("Connected to the database successfully", "info");
        # $connDB = $dbh;  # Store the database handle in a global variable
    } else {
        &dxcagg::logging::log_message("Could not connect to the database: $DBI::errstr", "info");
        die "Could not connect to the database: $DBI::errstr";
    }
    # print "Connected to the database successfully.\n";
    # exit;

}

sub connect_to_dxc() {
    # my ($dxc_type, $dxc_hostname, $dxc_port, $dxc_expect_prompt, $dxc_my_call) = @_;
    # connect to DXC
    # print "$dxc_expect_prompt\n";
    # exit;
    # print ($dxc_hostname, $dxc_port, $dxc_expect_prompt, $dxc_my_call);

    $telnet = new Net::Telnet ( Timeout=>60, Telnetmode=>0, Errmode=>'die', Port=>$dxc_port, Host=>$dxc_hostname);
    $telnet->open();
    $telnet->waitfor("/$dxc_expect_prompt: \/i") or die "no login prompt: ", $telnet->lastline;
    #$telnet->waitfor("/Please enter your call:/i") or die "no login prompt: ", $telnet->lastline;
    $telnet->print($dxc_my_call);
    # # Implement connection logic to the DXC
    # # This is a stub function for now
    # print "Connecting to DXC: $dxc_hostname on port $dxc_port\n";
    # print "Expecting prompt: $dxc_expect_prompt\n";
    # print "My call sign: $dxc_my_call\n";
}

main();