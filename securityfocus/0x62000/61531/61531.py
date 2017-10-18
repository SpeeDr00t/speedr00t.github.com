import requests
 
fileName = "lala.tmp"
f = open(fileName, "w")
f.write("lala")
f.close()
requests.post("<a href="http://www.example.com/cgi-bin/uploadfile">http://www.example.com/cgi-bin/uploadfile</a>", files={fileName: open(fileName, "rb")})
