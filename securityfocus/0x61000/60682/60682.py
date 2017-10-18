import telnetlib
import sys
host = sys.argv[1]
tn = telnetlib.Telnet(host)
tn.read_until("Password:")
tn.write("\r\n")
tn.read_until("choice")
tn.write("1\r\n")
tn.read_until("choice")
tn.write("1\r\n")
data = tn.read_until("choice")
for i in data.split("\r\n"):
    if "Device Name" in i:
        print i.strip()
    if "Node ID" in i:
        print i.strip()
tn.write("0\r\n")
tn.read_until("choice")
tn.write("2\r\n")
data = tn.read_until("choice")
for i in data.split("\r\n"):
    if "Manufacture:" in i:
        print i.strip()
    if "Model:" in i:
        print i.strip()
tn.write("0\r\n")
tn.read_until("choice")
tn.write("5\r\n")
data = tn.read_until("choice")
for i in data.split("\r\n"):
    if "Community" in i:
        print i.strip()
