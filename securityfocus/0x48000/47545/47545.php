<?php if (!extension_loaded("phar")) die("skip");
 
$phar = new Phar(dirname(__FILE__) . '/poc.phar.tar');
 
?>