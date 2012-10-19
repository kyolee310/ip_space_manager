#!/usr/bin/perl

use strict;

$ENV{'TEST_HOME'} = "/home/qa-server";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/lib/ip_space_manager";
$ENV{'LOG_HOME'} = $ENV{'THIS_HOME'} . "/log";

require "$ENV{'THIS_HOME'}/reserve_ip_access_db.pl";

my $MYTABLE = "reserve_subnet_ip_records";

my $LOGFILE = $ENV{'LOG_HOME'} . "/history_reserve_subnet_ip.log";


sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub print_output{
	my $str = shift @_;
	my $ts = print_time();
	my $outstr = "$ts [FREE_SUBNET_IP] [LOG]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	return 0;
};

sub print_error{
	my $str = shift @_;
	my $ts = print_time();
	my $outstr = "$ts [FREE_SUBNET_IP] [ERROR]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	exit(1);
};


####################################  MAIN  ##########################################

if( @ARGV < 1 ){
	print_error("USAGE : ./free_subnet_ip.pl <SUBNET IPs>");
};

my $input_str = "";

while( @ARGV > 0 ){
	my $input = shift @ARGV;
	$input_str .= $input . " ";
};
chop($input_str);


print_output("FREEING SUBNET IPs: { $input_str }");

validate_input($input_str);

free_ips($input_str);

print_output("FREED SUBNET IPs: { $input_str }");

exit(0);

1;

sub validate_input{

	my $ip_str = shift @_;

	my @ip_lst = split(" ", $ip_str);;

	foreach my $ip (@ip_lst ){
		if( !($ip =~ /\d+\.\d+\.\d+\.\d+/) ){
			print_error("INVALID IP $ip !!");
		}elsif( is_ip_already_reserved($ip) == 0 ){
			print_error("IP $ip DOES NOT EXIST IN RECORD !!");
		};
	};

	return 0;
};

sub is_ip_already_reserved{

	my $ip = shift @_;

	if( reserve_ip_access_db_get_id_given_ip($MYTABLE, $ip) == 0 ){
		return 0;
	};

	return 1;
};

sub free_ips{

	my $ip_str = shift @_;
	
	my @ip_lst = split(" ", $ip_str);

	foreach my $ip ( @ip_lst ){
		
		###	use EXTRA column to keep track of its previous OWNER
		my $owner = reserve_ip_access_db_get_owner_given_ip($MYTABLE, $ip);		
		reserve_ip_access_db_update_extra_given_ip($MYTABLE, $ip, $owner);

		###	FREE IP
		reserve_ip_access_db_update_owner_given_ip($MYTABLE, $ip, "FREED");
	};

	return 0;
};

1;
