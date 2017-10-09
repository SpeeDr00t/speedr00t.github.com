#!/bin/bash

cd /tmp || exit 1

echo '[*] Compiling mangler...'

cat >mangle.c <<_EOF_
char buf[10240];
main() {
  int i,x;
  srand(time(0) ^ getpid());
  while ( (i = read(0,buf,sizeof(buf))) > 0) {
    x = rand() % (i/20);
    while (x--) buf[rand() % i] = rand();
    write(1,buf,i);
  }
}
_EOF_

gcc -O3 mangle.c -o mangle || exit 1
rm -f mangle.c

echo '[*] Preparing ISO master (feel free to alter this code)...'

mkdir cd_dir || exit 1
cd cd_dir

CNT=0
while [ "$CNT" -lt "200" ]; do
  mkdir A; cd A
  CNT=$[CNT+1]
done

cd /tmp/cd_dir

A=`perl -e '{print "A"x255}' 2>/dev/null`
CNT=0
while [ "$CNT" -lt "3" ]; do
  mkdir "$A"; cd "$A"
  CNT=$[CNT+1]
done

cd /tmp

echo '[*] Creating image (alter filesystem or parameters as needed)...'

mkisofs -U -R -J -o cd.iso cd_dir 2>/dev/null || exit 1
rm -rf cd_dir

echo '[*] STRESS TEST PHASE...'

while :; do
  DIR="/tmp/cdtest-$$-$RANDOM"
  mkdir "$DIR"
  dmesg -c 2>/dev/null
  cat cd.iso | ./mangle >cd_mod.iso
  mount -t iso9660 -o loop,ro /tmp/cd_mod.iso "$DIR" 2>/dev/null
  # ls -lAR "$DIR" - Uncomment if you like when it HURTS...
  umount "$DIR" 2>/dev/null
  rm -rf "$DIR" 2>/dev/null
  FAULT=`dmesg | grep -Ei 'oops|unable to handle'`
  test "$FAULT" = "" || break
done

dmesg | tail -30

echo '[+] Something found (/tmp/cd-mod.iso)...'

rm -f cd.iso mangle
exit 0
