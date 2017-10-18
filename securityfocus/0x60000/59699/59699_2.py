import nfqueue
import socket
import time
 
data_count = 0
delayed = None
 
def cb(dummy, payload):
        global data_count
        global delayed
        data = payload.get_data()
# DIRTY check for first data packet (not three-way-handshake)
        if len(data) > 60:
                data_count += 1
                if (data_count == 1):
                        delayed = payload
                        print data
# Just DROP the packet and the local TCP stack will send it again because won't get the ACK.
                        payload.set_verdict(nfqueue.NF_DROP)
        else:
                data_count = 0
 
 
q = nfqueue.queue()
q.open()
q.bind(socket.AF_INET)
q.set_callback(cb)
q.create_queue(0)
try:
        q.try_run()
except KeyboardInterrupt:
        print "Exiting..."
q.unbind(socket.AF_INET)
q.close()
