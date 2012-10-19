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
use DBI;

sub init_db{
	my $connect_ref = shift;

	# MYSQL CONFIG VARIABLES
	my $host = "";
	my $user = "";
	my $pw = "";

	# READ IP SPACE MANAGER CONFIGURATION FILE
	my $config_file = "/home/qa-server/lib/ip_space_manager/var/ip_space_manager.ini";
	my $line;
	open(CONFIG, "< $config_file") or die $!;
	while($line = <CONFIG>){
		chomp($line);
		if( $line =~ /^DATABASE:\s(\S+)/ ){
			$host = $1;
		}elsif( $line =~ /^USERNAME:\s(\S+)/ ){
			$user = $1;
		}elsif( $line =~ /^PASSWORD:\s(\S+)/ ){
			$pw = $1;
		};
	};
	close(CONFIG);

	# PERL MYSQL CONNECT()
	$$connect_ref = DBI->connect($host, $user, $pw);
	return 0;
};


sub reserve_ip_access_db_get_id_given_ip{

	my ($this_table, $this_ip) = @_;

	my $my_db;
        init_db(\$my_db);

	my $myquery = "SELECT id from $this_table where ip='$this_ip'";
        my $execute = $my_db->prepare($myquery);
        $execute->execute();
        my @results = $execute->fetchrow_array();
	$execute->finish();
	$my_db->disconnect();

	if( @results != 0 ){
		return $results[0];
	};
		
	return 0;
};

sub reserve_ip_access_db_get_owner_given_ip{

	my ($this_table, $this_ip) = @_;

	my $my_db;
        init_db(\$my_db);

	my $myquery = "SELECT owner from $this_table where ip='$this_ip'";
        my $execute = $my_db->prepare($myquery);
        $execute->execute();
        my @results = $execute->fetchrow_array();
	$execute->finish();
	$my_db->disconnect();

	if( @results != 0 ){
		return $results[0];
	};
		
	return 0;
};

sub reserve_ip_access_db_get_most_recently_freed_ip{

	my ($this_table) = @_;

	my $my_db;
        init_db(\$my_db);

	my $myquery = "SELECT ip from $this_table where owner='FREED' order by id desc limit 0,1";
        my $execute = $my_db->prepare($myquery);
        $execute->execute();
        my @results = $execute->fetchrow_array();
	$execute->finish();
	$my_db->disconnect();

	if( @results != 0 ){
		return $results[0];
	};
		
	return 0;
};


sub reserve_ip_access_db_get_all_ips_given_owner{

        my ($this_table, $this_owner) = @_;

        my $my_db;
        init_db(\$my_db);

        my $myquery = "SELECT ip from $this_table where owner='$this_owner'";
        my $execute = $my_db->prepare($myquery);
        $execute->execute();

        my @results;
	my $count = 0;
	my $string = "";
	while( @results = $execute->fetchrow_array() ){
		if( @results != 0 ){
			foreach my $item (@results){
				$string .= $item . " ";
			};
			$count++;
		};
	};
	chop($string);
	$execute->finish();
	$my_db->disconnect();

	return $string;
};


sub reserve_ip_access_db_insert_new_ip_record{

        my ($this_table, $this_ip, $this_owner, $this_extra) = @_;

	my $my_db;
        init_db(\$my_db);

        my $myquery = "INSERT INTO
                $this_table (ip, owner, extra)
                VALUES ('$this_ip', '$this_owner', '$this_extra')";

        my $execute = $my_db->do($myquery);
        chomp($execute);
	$my_db->disconnect();

        if( $execute != 1 ){
                print "[DB-ERROR]\tERROR in INSERT :: TABLE $this_table ($this_ip, $this_owner, $this_extra)\n";
		return 1;
        };

        return 0;
};


sub reserve_ip_access_db_update_owner_given_ip{

        my ($this_table, $this_ip, $this_owner) = @_;

	my $my_db;
        init_db(\$my_db);

        my $myquery = "UPDATE $this_table set owner='$this_owner' where ip='$this_ip'";
	my $execute = $my_db->do($myquery);
	chomp($execute);
	$my_db->disconnect();

	if( $execute != 1 ){
		print "[DB-ERROR]\tERROR in UPDATE :: TABLE $this_table ($this_ip, $this_owner)\n";
		return 1;
	};
	
	return 0;
};


sub reserve_ip_access_db_update_owner_given_ip_with_lock{

        my ($this_table, $this_ip, $this_owner) = @_;

	my $my_db;
        init_db(\$my_db);

        my $myquery = "SELECT owner from $this_table where ip='$this_ip' FOR UPDATE";
	my $execute = $my_db->prepare($myquery);
	$execute->execute();

	my @results = $execute->fetchrow_array();

	if( @results == 0 ){					### SPECIAL CASE: NO IP RECORD EXISTS; CREATE ONE.
		$execute->finish();
		$my_db->disconnect();
		return reserve_ip_access_db_insert_new_ip_record($this_table, $this_ip, $this_owner, "");

	}elsif( $results[0] ne "FREED" ){
		print "[DB-WARNING] IP $this_ip OWNED BY $results[0]\n";
		$execute->finish();
		$my_db->disconnect();
		return 1;
	};

	$execute->finish();

        my $myquery2 = "UPDATE $this_table set owner='$this_owner' where ip='$this_ip'";
	my $execute2 = $my_db->prepare($myquery2);
	$execute2->execute();
	$execute2->finish();
	$my_db->disconnect();
	
	return 0;
};




sub reserve_ip_access_db_update_extra_given_ip{

        my ($this_table, $this_ip, $this_extra) = @_;

	my $my_db;
        init_db(\$my_db);

        my $myquery = "UPDATE $this_table set extra='$this_extra' where ip='$this_ip'";
	my $execute = $my_db->do($myquery);
	chomp($execute);
	$my_db->disconnect();

	if( $execute != 1 ){
		print "[DB-ERROR]\tERROR in UPDATE :: TABLE $this_table ($this_ip, $this_extra)\n";
		return 1;
	};
	
	return 0;
};

sub reserve_ip_access_db_delete_record_given_id{

	my ($this_table, $this_id) = @_;

	my $my_db;
	init_db(\$my_db);

	my $myquery = "DELETE FROM $this_table WHERE id='$this_id' ";
	my $execute = $my_db->do($myquery);
	chomp($execute);
	$my_db->disconnect();

	if( $execute != 1 ){
		print "[DB-ERROR] Error in DELETE :: TABLE $this_table ($this_id)\n";
		return 1;
	};

	return 0;
};




1;

