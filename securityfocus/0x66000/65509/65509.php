File : admin/libraries/view.functions.php

function fileRequestHandler($handler, $module = false, $file = false){
    global $amp_conf;

    switch ($handler) {
        case 'reload':
            // AJAX handler for reload event
            $response = do_reload();
            header("Content-type: application/json");
            echo json_encode($response);
        break;
        case 'file':
            /** Handler to pass-through file requests
             * Looks for "module" and "file" variables, strips .. and 
only
allows normal filename characters.
             * Accepts only files of the type listed in $allowed_exts
below, and sends the corresponding mime-type,
             * and always interprets files through the PHP interpreter.
(Most of?) the freepbx environment is available,
             * including $db and $astman, and the user is authenticated.
             */
            if (!$module || !$file) {
                die_freepbx("unknown");
            }
            //TODO: this could probably be more efficient
            $module = str_replace('..','.',
preg_replace('/[^a-zA-Z0-9-\_\.]/','',$module));
            $file = str_replace('..','.',
preg_replace('/[^a-zA-Z0-9-\_\.]/','',$file));

            $allowed_exts = array(
                '.js'        => 'text/javascript',
                '.js.php'    => 'text/javascript',
                '.css'        => 'text/css',
                '.css.php'    => 'text/css',
                '.html.php'    => 'text/html',
                '.php'        => 'text/html',
                '.jpg.php'    => 'image/jpeg',
                '.jpeg.php'    => 'image/jpeg',
                '.png.php'    => 'image/png',
                '.gif.php'    => 'image/gif',
            );
            foreach ($allowed_exts as $ext=>$mimetype) {
                if (substr($file, -1*strlen($ext)) == $ext) {
                    $fullpath = 'modules/'.$module.'/'.$file;
                    if (file_exists($fullpath)) {
                        // file exists, and is allowed extension

                        // image, css, js types - set Expires to 24hrs 
in
advance so the client does
                        // not keep checking for them. Replace from
header.php
                        if (!$amp_conf['DEVEL']) {
                            header('Expires: '.gmdate('D, d M Y H:i:s',
time() + 86400).' GMT', true);
                            header('Cache-Control: max-age=86400, 
public,
must-revalidate',true);
                        }
                        header("Content-type: ".$mimetype);
                        ob_start();
                        include($fullpath);
                        ob_end_flush();
                        exit();
                    }
                    break;
                }
            }
            die_freepbx("../view/not allowed");
        break;
    case 'api':
      if (isset($_REQUEST['function']) &&
function_exists($_REQUEST['function'])) {
        $function = $_REQUEST['function'];
        $args = isset($_REQUEST['args'])?$_REQUEST['args']:'';

        //currently works for one arg functions, eventually need to 
clean
this up to except more args
        $result = $function($args);
        $jr = json_encode($result);
      } else {
        $jr = json_encode(null);
      }
      header("Content-type: application/json");
      echo $jr;
    break;
    }
    exit();
}

Function is called at admin/config.php at line 132

if (!in_array($display, array('noauth', 'badrefer'))
    && isset($_REQUEST['handler'])
) {
    $module = isset($_REQUEST['module'])    ? $_REQUEST['module']    : 
'';
    $file     = isset($_REQUEST['file'])        ? $_REQUEST['file']
: '';
    fileRequestHandler($_REQUEST['handler'], $module, $file);
    exit();
}


