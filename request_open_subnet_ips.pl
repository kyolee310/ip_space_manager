#!/usr/bin/perl

use strict;

$ENV{'TEST_HOME'} = "/home/qa-server";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/lib/ip_space_manager";
$ENV{'RANGE_HOME'} = $ENV{'THIS_HOME'} . "/etc";

require "$ENV{'THIS_HOME'}/reserve_ip_access_db.pl";

my $MYTABLE = "reserve_subnet_ip_records";
my $RANGEFILE = $ENV{'RANGE_HOME'} . "/range_subnet_ip.lst";


sub print_output{
	my $str = shift @_;
	print "[GET_ALL_OPEN_SUBNET_IPS]\t" . $str . "\n";
	return 0;
};

sub print_error{
	my $str = shift @_;
	print "[ERROR]\t" . $str . "\n";
	exit(1);
};


####################################  MAIN  ##########################################

if( @ARGV < 2 ){
	print_error("USAGE : ./request_open_subnet_ips.pl <owner> <count>");
};

my $owner = shift @ARGV;
my $count = shift @ARGV;
my $group = "default";

if( @ARGV >= 1 ){
	$group = shift @ARGV;
};

print_output("OWNER: $owner");
print_output("REQUEST COUNT: $count");
print_output("REQUEST GROUP: $group");

my @ip_array;
my %ip_hash;

read_range_and_populate();

my $lastfreedip = get_most_recently_freed_ip();
print_output("MOST RECENTLY FREED IP: $lastfreedip");

$lastfreedip = "10.29.240.0";		### FOR UNIT TESTING

my $is_conflict = 1;
my $trial = 0;

while( $is_conflict == 1 && $trial < 3 ){

	my $candids = grab_open_ips($owner, $count, $lastfreedip);

	print_output("CANDIDATE IPs: $candids");

	if( $candids ne "FAILED" ){
		$is_conflict = reserve_open_ips($candids, $owner);
	};

	if( $is_conflict == 1 ){
		$trial++;
		print_output("SLEEP 2 SEC BEFORE NEXT TRIAL");
		sleep(2);
	}else{
		print_output("RESERVED $count IPs: $candids");
	}
};



exit(0);

1;

sub read_range_and_populate{

	my $start_ip;
	my $end_ip;

	open(RANGE, "< $RANGEFILE") || die $!;
	my $line;
	while($line=<RANGE>){
		if( $line =~ /^$group\s+(\d+\.\d+\.\d+\.\d+)\s+(\d+\.\d+\.\d+\.\d+)/ ){
			$start_ip = $1;
			$end_ip = $2;
		};
	};
	close(RANGE);

	print_output("START IP: [$start_ip, $end_ip]");

	if( $start_ip eq "" || $end_ip eq "" ){
		print_error("FAILED TO DETECT IP RANGE");
	};

	populate_subnet_ip_data($start_ip, $end_ip);

	return 0;
};


sub populate_subnet_ip_data{
	my ($start, $end) = @_;

	my $this_ip = $start;
	my $inc = 16;

	my $first_byte;
	my $second_byte;

	if( $this_ip =~ /^(\d+)\.(\d+)\.\d+\.\d+/ ){
		$first_byte = $1;
		$second_byte = $2;
	};

	my $is_done = 0;
	my $count = 0;

	while( $is_done == 0 ){
		if( $count > 99999 ){
			print_error("INFINITE LOOP!");
		};
		if( $this_ip eq $end ){
			$is_done = 1;
		};
		for(my $i=0; $i<256; $i=$i+$inc){
			$this_ip = sprintf("%d", $first_byte) . "." . sprintf("%d", $second_byte) . "." . sprintf("%d", $i) . ".0";			
			push(@ip_array, $this_ip);
			$ip_hash{$this_ip} = $count;
			$count++;
		};
		$second_byte++;
		$this_ip = sprintf("%d", $first_byte) . "." . sprintf("%d", $second_byte) . "." . "0.0";
	};

	return 0;
};


sub get_most_recently_freed_ip{
	
	my $ip = reserve_ip_access_db_get_most_recently_freed_ip($MYTABLE);

	if( $ip == "" ){
		return "NULL";
	};
	
	return $ip;
};


sub grab_open_ips{
	my ($owner, $count, $lastip) = @_;

	my $index = $ip_hash{$lastip};

	if( $index eq "" ){
		$index = 0;
	};

	print_output("START INDEX: $index");

	my $open_count = 0;
	my $ip_str = "";
	
	for(my $i = 0 ; $i < @ip_array; $i++){
		my $adj_index = ($i + $index) % @ip_array;
		my $this_ip = $ip_array[$adj_index];
		my $this_owner = reserve_ip_access_db_get_owner_given_ip($MYTABLE, $this_ip);
		if( $this_owner eq "0" || $this_owner eq "FREED" ){
#			print "OWNER IS $this_owner\n";
			$ip_str .= $this_ip . " ";
			$open_count++;
		};
		if( $open_count == $count ){
			chop($ip_str);
			return $ip_str;
		};
	};

	return "FAILED";
};

sub reserve_open_ips{
	my ($ip_str, $this_owner) = @_;

	my @ip_list = split(" ", $ip_str);
	my $is_conflict = 0;
	my $reserved_ip_str = "";

	foreach my $this_ip (@ip_list){
		print_output("ATTEMPT TO RESERVE IP: $this_ip");
		if( reserve_ip_access_db_update_owner_given_ip_with_lock($MYTABLE, $this_ip, $this_owner) ){
			print_output("WARNING:: POSSIBLE CONFLICT IN IP $this_ip");
			$is_conflict = 1;
		}else{
			$reserved_ip_str .= $this_ip . " ";
			print_output("SUCCESSFULLY RESERVED IP: $this_ip");
		};
	};

	if( $is_conflict == 1 ){
		chop($reserved_ip_str);
		system("perl $ENV{'THIS_HOME'}/free_subnet_ip.pl $reserved_ip_str");
	};

	return $is_conflict;
};

1;
