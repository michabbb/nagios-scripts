#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use lib "/usr/lib/nagios/plugins";
use utils qw(%ERRORS);

use vars qw/ %opt /;
sub debug($);

getopts('c:dhH:Lp:P:S:u:w:V', \%opt);

if (exists $opt{h}) {
    usage();
    exit(0);
}

my $debug = 0;
if (exists $opt{d}) {
    print "Enabling debug mode...\n";
    $debug = 1;
}

my $warn_threshold = 5;
if (exists $opt{w}) {
    $warn_threshold = $opt{w};
}
debug("\$warn_threshold=$warn_threshold\n");

my $critical_threshold = 10;
if (exists $opt{c}) {
    $critical_threshold = $opt{c};
}
debug("\$critical_threshold=$critical_threshold\n");

my $username = "monitoring";
if (exists $opt{u}) {
    $username = $opt{u};
}

my $password = "monitoring";
if (exists $opt{p}) {
    $password = $opt{p};
}

my $host = "127.0.0.1";
if (exists $opt{H}) {
	$host = $opt{H};
}

my $port = 3306;
if (exists $opt{P}) {
	$port = $opt{P};
}

my $socket = "";
if (exists $opt{S}) {
	$socket = $opt{S};
}

my $cmdline = "/usr/bin/mysql -u $username -p$password";
if ($socket eq "") {
	$cmdline = "$cmdline -h $host -P $port";
} else {
	$cmdline = "$cmdline -S $socket";
}

debug("\$cmdline=\"$cmdline\"\n");
my $query_output_max_connections = `/bin/echo "show variables like 'max_connections'" \| $cmdline 2>/dev/null \| /bin/grep -i "max_connections"`;
debug("\$query_output_max_connections=\"$query_output_max_connections\"\n");
unless ($query_output_max_connections =~ /^max_connections\s+(\d+)\s+$/) {
    print "Unknown: Unable to read output from MySQL\n";
    exit $ERRORS{'UNKNOWN'};
}

my $max_connections = $1;

my $query_output_max_used_connections = `/bin/echo "show status like 'max_used_connections'" \| $cmdline 2>/dev/null \| /bin/grep -i "max_used_connections"`;
debug("\$query_output_max_used_connections=\"$query_output_max_used_connections\"\n");
unless ($query_output_max_used_connections =~ /^max_used_connections\s+(\d+)\s+$/i) {
    print "Unknown: Unable to read output from MySQL\n";
    exit $ERRORS{'UNKNOWN'};
}

my $max_used_connections = $1;

$critical_threshold = ($max_connections-$critical_threshold);
$warn_threshold     = ($max_connections-$warn_threshold);

my $perfdata = "max_used_connections=$max_used_connections;$warn_threshold;$critical_threshold;0;0;";

if ($max_used_connections > $critical_threshold) {
    print "Critical: $max_used_connections connections (max: $max_connections)|$perfdata\n";
    exit $ERRORS{'CRITICAL'}
} elsif ($max_used_connections > $warn_threshold) {
    print "Warning: $max_used_connections connections (max: $max_connections)|$perfdata\n";
    exit $ERRORS{'WARNING'}
} else {
    print "OK: $max_used_connections connections (max: $max_connections)|$perfdata\n";
    exit $ERRORS{'OK'}
}



###########################################################################

sub usage {
    if (@_ == 1) {
	print "$0: $_[0].\n";
    }
    print << "EOF";
Usage: $0 [options]
  -w THRESHOLD
     Warning threshold for number of active connections (default: 5)
  -c THRESHOLD
     critical threshold for number of active connections (default: 10)
  -H HOST
  	 Connect to TCP address/DNS name (default: 127.0.0.1).
  -P PORT
  	 Use this alternate TCP port (default: 3306).
  -S SOCKET
  	 Use this MySQL socket instead of the default/or TCPIP.
  -u USERNAME
     The MySQL username to use when connecting to the server.
  -p PASSWORD
     The password to use when connecting to the server.
  -d
     enable debug mode (mutually exclusive to -q)
  -h
     display usage information
EOF
}

sub debug($) {
    if ($debug) {
	print STDERR $_[0];
    }
}
