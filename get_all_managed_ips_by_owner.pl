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

$ENV{'TEST_HOME'} = "/home/qa-group";
$ENV{'THIS_HOME'} = $ENV{'TEST_HOME'} . "/ip_space_manager";

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

