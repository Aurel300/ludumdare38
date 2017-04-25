import haxe.io.Bytes;
import sk.thenet.FM;
import sk.thenet.anim.Timing;
import sk.thenet.app.*;
import sk.thenet.app.Keyboard.Key;
import sk.thenet.bmp.*;
import sk.thenet.event.*;
import sk.thenet.geom.*;
import sk.thenet.net.ws.Websocket;
import sk.thenet.plat.Platform;
import common.*;

class SLogin extends State {
  private var ph:Int;
  private var rph:Int;
  private var sel:Int;
  private var msel:Int;
  private var nick:String;
  private var button:Bitmap;
  
  private var bd:Bool = false;
  
  public function new(app:Application){
    super("login", app);
  }
  
  override public function to():Void {
    ph = 0;
    rph = 0;
    msel = -1;
    nick = "";
    
    button = GUI.renderButton(am, "Enter", 1);
  }
  
  override public function tick():Void { 
    app.bitmap.fill(Palette.pal[3]);
    GUI.fontText.render(
         app.bitmap, 10, 10
        ,"Please select a faction:"
      );
    
    GUI.fontText.render(
         app.bitmap, 10, 100
        ,"And type a nick (a-z, 0-9 only):"
      );
    
    GUI.fontText.render(
         app.bitmap, 20, 120
        ,nick + "_"
      );
    
    sel = -1;
    
    var ofy:Int = -30;
    for (i in 0...8){
      if (msel == i){
        app.bitmap.fillRect(1 + i * 50, 60 + ofy, 48, 60, Palette.factions[i]);
        app.bitmap.fillRect(3 + i * 50, 62 + ofy, 44, 56, Palette.pal[3]);
      }
      var oy = Math.cos(((ph + i * 40) / 240) * 2 * Math.PI) * 5;
      if (FM.withinI(Platform.mouse.x, 1 + i * 50, 1 + i * 50 + 48)
          && FM.withinI(Platform.mouse.y, 60 + ofy, 120 + ofy)){
        app.bitmap.fillRect(1 + i * 50, 60 + ofy, 48, 60, Palette.factions[i]);
        sel = i;
      }
      app.bitmap.blitAlpha(
          Sprites.factionSigns[i].get(0, 0), 1 + i * 50, 64 + FM.floor(oy) + ofy
        );
    }
    ph++;
    ph %= 240;
    
    bd = false;
    if (nick.length > 0 && msel != -1){
      app.bitmap.blitAlpha(button, Main.WIDTH - 64 - 10, Main.HEIGHT - 16 - 10);
      bd = true;
    }
    
    app.bitmap.blitAlphaRect(
         am.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y
        ,32, 24, 8, 8
      );
  }
  
  override public function keyUp(key:Key):Void {
    if (key == Backspace){
      nick = nick.substr(0, nick.length - 1);
    }
    if (nick.length >= 30){
      return;
    }
    var ch = Keyboard.getCharacter(key);
    if (ch != " " && ch != "\n"){
      nick += ch;
    }
  }
  
  override public function mouseClick(_, _):Void {
    if (sel != -1){
      GameState.selectNative(sel);
      GameState.currentNick = nick;
      msel = sel;
    }
    if (bd
        && Platform.mouse.x >= Main.WIDTH - 64 - 10
        && Platform.mouse.x < Main.WIDTH - 10
        && Platform.mouse.y >= Main.HEIGHT - 16 - 10
        && Platform.mouse.y < Main.HEIGHT - 10){
      app.applyState(app.getStateById("game"));
    }
  }
}
