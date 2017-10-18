# Standard imports
import logging
from optparse import OptionParser, OptionGroup
# External imports
import fau_timer
from scapy.config import conf
from scapy.supersocket import socket
# Custom imports
from pysap.SAPNI import SAPNI, SAPNIStreamSocket
from pysap.SAPRouter import SAPRouter, router_is_control
 
 
# Set the verbosity to 0
conf.verb = 0
 
 
# Command line options parser
def parse_options():
 
    description = \
    """This example script connects with a SAP Router service and makes an
    information request using a provided password. It then records the
    time the remote service takes to respond to the request. Further analysis
    of the time records could be performed in order to identify whether the
    server is vulnerable to a timing attack on the password check.
 
    """
 
    epilog = \
    """pysap - <a href="http://corelabs.coresecurity.com/index.php?module=Wiki&action=view&type=tool&name=pysap">http://corelabs.coresecurity.com/index.php?module=Wiki&action=view&type=...</a>"""
 
    usage = "Usage: %prog [options] -d <remote host>"
 
    parser = OptionParser(usage=usage, description=description, epilog=epilog)
 
    target = OptionGroup(parser, "Target")
    target.add_option("-d", "--remote-host", dest="remote_host", help="Remote host [%default]", default="127.0.0.1")
    target.add_option("-p", "--remote-port", dest="remote_port", type="int", help="Remote port [%default]", default=3299)
    target.add_option("--router-version", dest="router_version", type="int", help="SAP Router version to use [retrieve from the remote SAP Router]")
    parser.add_option_group(target)
 
    misc = OptionGroup(parser, "Misc options")
    misc.add_option("-t", "--tries", dest="tries", default=10, type="int", help="Amount of tries to make for each length [%default]")
    misc.add_option("--password", dest="password", default="password", help="Correct password to test")
    misc.add_option("-o", "--output", dest="output", default="output.csv", help="Output file [%default]")
    misc.add_option("-v", "--verbose", dest="verbose", action="store_true", default=False, help="Verbose output [%default]")
    parser.add_option_group(misc)
 
    (options, _) = parser.parse_args()
 
    if not options.remote_host:
        parser.error("Remote host is required")
 
    return options
 
 
# Retrieve the version of the remote SAP Router
def get_router_version(connection):
    r = connection.sr(SAPRouter(type=SAPRouter.SAPROUTER_CONTROL, version=40, opcode=1))
    if router_is_control(r) and r.opcode == 2:
        return r.version
    else:
        return None
 
 
def try_password(options, password, output=None, k=0):
 
    p = SAPRouter(type=SAPRouter.SAPROUTER_ADMIN, version=options.router_version)
    p.adm_command = 2
    p.adm_password = password
    p = str(SAPNI() / p)
 
    fau_timer.init()
    fau_timer.send_request(options.remote_host, options.remote_port, p, len(p))
    fau_timer.calculate_time()
    cpuSpeed = fau_timer.get_speed()
    cpuTicks = fau_timer.get_cpu_ticks()
    time = fau_timer.get_time()
 
    if options.verbose:
        print "Request time: CPU Speed: %s Hz CPU Ticks: %s Time: %s nanosec" % (cpuSpeed, cpuTicks, time)
 
    # Write the time to the output file
    if output:
        output.write("%i,%s,%s\n" % (k, password, time))
 
    return time
 
 
# Main function
def main():
    options = parse_options()
 
    if options.verbose:
        logging.basicConfig(level=logging.DEBUG)
 
    # Initiate the connection
    sock = socket.socket()
    sock.connect((options.remote_host, options.remote_port))
    conn = SAPNIStreamSocket(sock)
    print "[*] Connected to the SAP Router %s:%d" % (options.remote_host, options.remote_port)
 
    # Retrieve the router version used by the server if not specified
    if options.router_version is None:
        options.router_version = get_router_version(conn)
 
    print "[*] Using SAP Router version %d" % options.router_version
 
    print "[*] Checking if the server is vulnerable to a timing attack ..."
 
    with open(options.output, "w") as f:
 
        c = 0
        for i in range(0, len(options.password) + 1):
            password = options.password[:i] + "X" * (len(options.password) - i)
            print "[*] Trying with password (%s) len %d" % (password, len(password))
            for _ in range(0, options.tries):
                try_password(options, password, f, c)
                c += 1
 
 
if __name__ == "__main__":
    main()

