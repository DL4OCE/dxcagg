#!/usr/bin/perl

use DBI;
use strict;
use warnings;
use JSON;

use lib '/var/www/html/dxcagg/lib/';
use dxcagg::logging; 

my $config_file = "../config/main.json";
open my $fh, "<", $config_file or die "Kann '$config_file' nicht öffnen: $!";
local $/;
my $json_text = <$fh>;
close $fh;

my $config = decode_json($json_text);

if (exists $config->{database_dsn} && exists $config->{database_user} && exists $config->{database_password}) {
    my $connDB = DBI->connect($config->{database_dsn}, $config->{database_user}, $config->{database_password}, { RaiseError => 1, PrintError => 0 });
    if ($connDB) {
        &dxcagg::logging::log_message("Connected to the database successfully", "info");
        while (1) {
            my $timeout_seconds = $config->{spot_timeout_secs};
            my $sql= "DELETE FROM spot WHERE timestamp_created < NOW() - INTERVAL $timeout_seconds SECOND";
            my $sth = $connDB->prepare($sql);
            $sth->execute();
            &dxcagg::logging::log_message("Housekeeping job in database succesfully run", "info");
            sleep(60);
        }
    } else {
        &dxcagg::logging::log_message("Failed to connect to the database: " . DBI->errstr, "info");
        die "Failed to connect to the database: " . DBI->errstr;
    }
} else {
    &dxcagg::logging::log_message("Database configuration is missing in the JSON file.", "info");
    die "Database configuration is missing in the JSON file.";
}
