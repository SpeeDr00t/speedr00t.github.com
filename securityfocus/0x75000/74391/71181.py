#!/usr/bin/python

import requests

acs_server = "http://<server>:<port>"
acs_user = "user"
acs_pass = "pass"

# Connection request parameters. When a request is made to the following URL, using the specified user/pass combination,
# router will connect back to the ACS server.

conn_url = "/tr069"
conn_port = "7564"
conn_user = "user"
conn_pass = "pass"

#Periodic inform parameters
active = 1
interval = 2000

payload = {'CWMP_active': '1', 'CWMP_ACSURL': acs_server,'CWMP_ACSUserName': acs_user,'CWMP_ACSPassword': acs_pass, 'CWMP_ConnectionRequestPath': conn_url, 'CWMP_ConnectionRequestPort': conn_port, 'CWMP_ConnectionRequestUserName': conn_user, 'CWMP_ConnectionRequestPassword': conn_pass, 'CWMP_PeriodActive': active, 'CWMP_PeriodInterval': interval, 'CWMPLockFlag': '0' }

r = requests.post("http://www.example.com/Forms/access_cwmp_1";, data=payload)
