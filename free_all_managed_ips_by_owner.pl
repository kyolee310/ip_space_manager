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

$ENV{'TEST_HOME'} = "/home/qa-server";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/lib/ip_space_manager";
$ENV{'LOG_HOME'} = $ENV{'THIS_HOME'} . "/log";

require "$ENV{'THIS_HOME'}/reserve_ip_access_db.pl";

my $MYTABLE = "reserve_manged_ip_records";

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
	my $outstr = "$ts [FREE_ALL_MANAGED_IPS_BY_OWNER] [LOG]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	return 0;
};

sub print_error{
	my $str = shift @_;
	my $ts = print_time();
	my $outstr = "$ts [FREE_ALL_MANAGED_IPS_BY_OWNER] [ERROR]\t" . $str;
	print $outstr . "\n";
	system("echo \"$outstr\" >> $LOGFILE");
	print_log_space();
	exit(1);
};


####################################  MAIN  ##########################################

if( @ARGV < 1 ){
	print_error("USAGE : ./free_all_managed_ips_by_owner.pl <OWNER>");
};


my $owner = shift @ARGV;

print_output("OWNER: $owner");

my $ip_list = get_all_ips_by_owner($owner);

print_output("MANAGED IPS OWNED BY $owner : { $ip_list }");

if( $ip_list eq "NULL"){
	print_output("[NO-OP] NO MANAGED IPS OWNED BY $owner");
}else{
	free_all_ips($ip_list);
	print_output("FREED ALL MANAGED IPS OWNED BY $owner");
};

print_log_space();

exit(0);

1;

sub get_all_ips_by_owner{

	my $owner = shift @_;

	my $temp_list = `perl /home/qa-server/lib/ip_space_manager/get_all_managed_ips_by_owner.pl $owner`;

	my $ip_list = "NULL";
	if( $temp_list =~ /^\[IPs\]\s+(.+)/m ){
		$ip_list = $1;
	}else{
		print_error("ERROR in Retrieving IPs of OWNER $owner");
	};

	return $ip_list;
};

sub free_all_ips{

	my $ip_list = shift @_;
	chomp($ip_list);
	system("perl /home/qa-server/lib/ip_space_manager/free_managed_ip.pl $ip_list");

	return 0;
};

1;

