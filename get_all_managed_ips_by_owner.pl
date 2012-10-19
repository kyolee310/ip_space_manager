#!/usr/bin/perl

use strict;

$ENV{'TEST_HOME'} = "/home/qa-server";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/lib/ip_space_manager";

require "$ENV{'THIS_HOME'}/reserve_ip_access_db.pl";


my $MYTABLE = "reserve_managed_ip_records";


sub print_output{
	my $str = shift @_;
	print "[GET_ALL_MANAGED_IPS_BY_OWNER]\t" . $str . "\n";
	return 0;
};

sub print_error{
	my $str = shift @_;
	print "[ERROR]\t" . $str . "\n";
	exit(1);
};


####################################  MAIN  ##########################################

if( @ARGV < 1 ){
	print_error("USAGE : ./get_all_managed_ips_by_owner.pl <OWNER>");
};

my $owner = shift @ARGV;

print_output("OWNER: $owner");

print "[IPs]\t" . get_all_ips($owner) . "\n";


exit(0);

1;

sub get_all_ips{

	my $owner = shift @_;
	
	my $ips = reserve_ip_access_db_get_all_ips_given_owner($MYTABLE, $owner);

	if( $ips == "" ){
		return "NULL";
	};
	
	return $ips;
};

1;

