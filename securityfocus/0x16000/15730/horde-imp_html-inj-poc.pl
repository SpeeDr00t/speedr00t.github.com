#
# MIME::Liet SMTP client by C3PO
#
   use strict;
   use MIME::Base64;
   use MIME::Lite;
#----------------------------------------------------
#                    load_file
#----------------------------------------------------
   sub load_file{
      my($file) = shift;
      my($Body);
      open(IN, $file) || die("Can't open $file $!");
      binmode IN;
      read(IN, $Body, -s $file);
      close(IN);
      return $Body;
  }
#----------------------------------------------------
#                      main
#----------------------------------------------------
   my $c = load_file('\Xploits\horder\passed.htm'); #content
   my $m = MIME::Lite->new(
                 From    =>'mail@domain.zone',
                 To      =>'mail@domain.zone',
                 Subject =>'Horde',
                 Date    =>"Tue, 17 Dec 2002 22:00:02 +0300",
                 Type    =>"text/html",
                 Data    => $c,
                 Filename=>"horde.html",
                 Encoding =>'base64'
                 );
  $m->attr('content-type.charset' => 'windows-1251'); #not necessary
  $m->send("smtp","smtp.domain.zone");
