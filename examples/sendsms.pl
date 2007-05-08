#!/usr/bin/perl

use strict;
use Net::SMS::TMobile::UK;

my $username=shift;
my $password=shift;
my $target=shift;
my $message=shift;

unless ($message) {
	print "\nUsage: $0 <username> <password> <mobilenumber> <message>\n\n";
	exit(1);
}

my $sms = Net::SMS::TMobile::UK->new (username=>$username, password=>$password);
$sms->sendsms(to=>$target, message=>$message);

