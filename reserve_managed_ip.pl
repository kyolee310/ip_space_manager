#!/usr/bin/perl

use strict;

$ENV{'TEST_HOME'} = "/home/qa-server";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/lib/ip_space_manager";
$ENV{'LOG_HOME'} = $ENV{'THIS_HOME'} . "/log";

require "$ENV{'THIS_HOME'}/reserve_ip_access_db.pl";

my $MYTABLE = "reserve_managed_ip_records";

my $LOGFILE = $ENV{'LOG_HOME'} . "/history_reserve_managed_ip.log";


sub print_time{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday,$isdst)=localtime(time);
	my $this_time = sprintf "[%4d-%02d-%02d %02d:%02d:%02d]", $year+1900,$mon+1,$mday,$hour,$min,$sec;
	return $this_time;
};

sub print_log_space{
	system("echo \"\" >> $LOGFILE");
	return 0;
};

sub print_output{
	my $str = shift @_;
	my $ts = print_time();
	my $outstr = "$ts [RESERVE_MANAGED_IP] [LOG]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	return 0;
};

sub print_error{
	my $str = shift @_;
	my $ts = print_time();
	my $outstr = "$ts [RESERVE_MANAGED_IP] [ERROR]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	print_log_space();
	exit(1);
};


####################################  MAIN  ##########################################

if( @ARGV < 2 ){
	print_error("USAGE : ./reserve_managed_ip.pl <OWNER> <MANAGED IPs>");
};

my $owner = "";
my $input_str = "";

$owner = shift @ARGV;
while( @ARGV > 0 ){
	my $input = shift @ARGV;
	$input_str .= $input . " ";
};
chop($input_str);

print_output("OWNER: $owner");
print_output("RESERVING MANAGED IPs: { $input_str }");

validate_input($input_str);

reserve_ips($owner, $input_str);

print_output("RESERVED MANAGED IPs: { $input_str }");

print_log_space();

exit(0);

1;

sub validate_input{

	my $ip_str = shift @_;

	my @ip_lst = split(" ", $ip_str);;

	foreach my $ip (@ip_lst ){
		if( !($ip =~ /\d+\.\d+\.\d+\.\d+/) ){
			print_error("INVALID IP $ip !!");
		}elsif( is_ip_already_reserved($ip) ){
			print_error("IP $ip ALREADY RESERVED !!");
		};
	};

	return 0;
};

sub is_ip_already_reserved{

	my $ip = shift @_;

	if( reserve_ip_access_db_get_id_given_ip($MYTABLE, $ip) == 0 ){
		return 0;
	};

        my $curr_owner = reserve_ip_access_db_get_owner_given_ip($MYTABLE, $ip);

        if( $curr_owner eq "FREED" ){
                return 0;
        };

	return 1;
};

sub reserve_ips{

	my $owner = shift @_;
	my $ip_str = shift @_;
	
	my @ip_lst = split(" ", $ip_str);

	foreach my $ip ( @ip_lst ){
		if( reserve_ip_access_db_get_id_given_ip($MYTABLE, $ip) == 0 ){
			reserve_ip_access_db_insert_new_ip_record($MYTABLE, $ip, $owner, "");
		}else{
			reserve_ip_access_db_update_owner_given_ip($MYTABLE, $ip, $owner);
		};
	};

	return 0;
};

1;

