1012 command << "xvfb-run -a --server-args='-screen 0, #{screen}x24' " 
 1015 command << "{WEBKIT2PNG} '{url}' {args}"
 1017 img = `{command} 2>&1`
    
