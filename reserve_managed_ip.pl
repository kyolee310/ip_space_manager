#!/usr/bin/perl

#    Licensed to the Apache Software Foundation (ASF) under one
#    or more contributor license agreements.  See the NOTICE file
#    distributed with this work for additional information
#    regarding copyright ownership.  The ASF licenses this file
#    to you under the Apache License, Version 2.0 (the
#    "License"); you may not use this file except in compliance
#    with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing,
#    software distributed under the License is distributed on an
#    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#    KIND, either express or implied.  See the License for the
#    specific language governing permissions and limitations
#    under the License.
#
#    Contributor: Kyo Lee kyo.lee@eucalyptus.com

use strict;

require "./reserve_ip_access_db.pl";

my $MYTABLE = "reserve_managed_ip_records";

my $THIS_HOME = "/home/qa-group/ip_space_manager";
my $LOG_HOME = $THIS_HOME . "/log";
my $LOGFILE = $LOG_HOME . "/history_reserve_managed_ip.log";

sub read_config_file{
	### READ CONFIGURATION FILE
	my $config_file = "./var/ip_space_manager.ini";
	my $line;
	open(CONFIG, "< $config_file") or die $!;
	while($line = <CONFIG>){
		chomp($line);
		if( $line =~ /^HOME_DIR:\s(\S+)/ ){
			$THIS_HOME = $1;
			$LOG_HOME = $THIS_HOME . "/log";
			$LOGFILE = $LOG_HOME . "/history_reserve_managed_ip.log";
			if( !(-e $LOG_HOME) ){
				system("mkdir -p $LOG_HOME");
			};
		};
	};
	return 0;
};

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

read_config_file();

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

