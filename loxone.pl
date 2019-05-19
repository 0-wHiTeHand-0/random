#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use LWP::Protocol::socks;

########## Modify from here ##########

use constant tor => 1;
use constant tor_params => "127.0.0.1:9050";
use constant chars_to_chop => 2;
my $serial = "XXXXXXXXXXXX"; #Set serial number

########## To here ##########

if (chars_to_chop >= length($serial)){
   print "Are you kidding?\n";
   exit(1);
}else{
   print "I will make " . (16**chars_to_chop) . " requests\n";
   $serial = substr($serial, 0, -1 * chars_to_chop);
}

my $num = 0;
my $count = 0;
my $str_num = sprintf("%0" . chars_to_chop . "X", $num);
my $ua = LWP::UserAgent->new(timeout => 6, agent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.14; rv:66.0) Gecko/20100101 Firefox/66.0");
if (tor){
   $ua->proxy(['http'],'socks://'.tor_params);
   print "Tor is ON\n";
}else{
   print "Tor is OFF\n";
}

print "\nLoxone servers found:\n";

while (chars_to_chop == length($str_num)){
   my $tmp_req = "http://".$serial.$str_num.".dns.loxonecloud.com";
   my $resp = $ua->get($tmp_req."/jdev/sys/getPublicKey");
   if ($resp->code == 200) {
      print $tmp_req." - Real URI: ".substr($resp->request->uri, 0, -22)."\n";
      $count++;
   }
   $num++;
   $str_num = sprintf("%0" . chars_to_chop . "X", $num);
}

print "\n".$count." hosts were found. Don't be evil.\n";
