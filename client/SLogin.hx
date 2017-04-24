import haxe.io.Bytes;
import sk.thenet.FM;
import sk.thenet.anim.Timing;
import sk.thenet.app.*;
import sk.thenet.event.*;
import sk.thenet.geom.*;
import sk.thenet.net.ws.Websocket;
import sk.thenet.plat.Platform;
import common.*;

class SLogin extends State {
  private var ph:Int;
  private var rph:Int;
  private var sel:Int;
  
  public function new(app:Application){
    super("login", app);
  }
  
  override public function to():Void {
    ph = 0;
    rph = 0;
  }
  
  override public function tick():Void { 
    app.bitmap.fill(Palette.pal[3]);
    GUI.fontText.render(
         app.bitmap, 10, 10
        ,"Please select a faction:"
      );
    
    sel = -1;
    
    for (i in 0...8){
      var oy = Math.cos(((ph + i * 40) / 240) * 2 * Math.PI) * 5;
      if (FM.withinI(Platform.mouse.x, 1 + i * 50, 1 + i * 50 + 48)
          && FM.withinI(Platform.mouse.y, 60, 120)){
        app.bitmap.fillRect(1 + i * 50, 60, 48, 60, Palette.factions[i]);
        sel = i;
      }
      app.bitmap.blitAlpha(
          Sprites.factionSigns[i].get(0, 0), 1 + i * 50, 64 + FM.floor(oy)
        );
    }
    ph++;
    ph %= 240;
    
    app.bitmap.blitAlphaRect(
         am.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y
        ,32, 24, 8, 8
      );
  }
  
  override public function mouseClick(_, _):Void {
    if (sel != -1){
      GameState.selectNative(sel);
      app.applyState(app.getStateById("game"));
    }
  }
}
