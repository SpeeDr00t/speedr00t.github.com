#!/usr/bin/python

 #just based on http://www.example.com/tutorials/general/client.html#basic-example
 from pyamf import AMF0, AMF3
 from pyamf.remoting.client import RemotingService

 client = RemotingService('http://installationurl/enetworkmanagementsystem-fds/messagebroker/amf',
amf_version=AMF3)
 service = client.getService('userService')

 print service.getAllUsers()
