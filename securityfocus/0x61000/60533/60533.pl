#! /usr/bin/perl 
use LWP; 
use HTTP::Request::Common; 

my ($url, $file) = @ARGV; 

my $ua = LWP::UserAgent->new(); 
my $req = POST $url, 
Content_Type => 'form-data', 
Content => [. 
name => $name, 
galleryselect => 1, # Gallery ID, should exist 
Filedata => [ "$file", "file.gif", Content_Type => 
'image/gif' ] 
]; 
my $res = $ua->request( $req ); 
if( $res->is_success ) { 
print $res->content; 
} else { 
print $res->status_line, "\n"; 
} 

