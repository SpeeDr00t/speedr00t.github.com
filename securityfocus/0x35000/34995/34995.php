#Start info: {
#
#Script Name:   Rama Zaitan Cms
# Script Project: http://sourceforge.net/project/showfiles.php?group_id=212495&package_id=255590
# Download:       http://sourceforge.net/project/downloading.php?group_id=212495&filename=cms975.zip&a=5782381
#
#  0.9.5 <= Versions <=0.9.8  
#
# by Br0ly.
# br0ly.Code@gmail.com
#
# Brasil.
#
# Gretz: str0ke , Osirys,  xscholler , 6_Bl4ck9_f0x6  and all my friends.
#
# Sorry for my bad english. ;/
#
#End info }


Php code :
<?php
$dir  = 'uploads/';
$file = $_GET['file']; <-----------------------------------------------------------------> Vul

header('Content-Disposition: attachment; filename='.$file);

switch ($_GET['type']) {
    case 'Doc':
        header ('Content-type: application/msword');
        break;
    case 'Excel':
        header ('Content-type: application/vnd.ms-excel');
        break;
    case 'ZIP':
        header ('Content-type: application/zip');
        break;
    case 'PPT':
        header ('Content-type: application/vnd.ms-powerpoint');
        break;
    case 'PDF':
        header ('Content-type: application/pdf');
        break;

    default: header ('application/force-download');
}

readfile("$dir$file");  <-------------------------------------------------------> Vul
?>
