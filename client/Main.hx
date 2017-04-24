import sk.thenet.FM;
import sk.thenet.app.*;
import sk.thenet.app.Keyboard.Key;
import sk.thenet.app.asset.Bind as AssetBind;
import sk.thenet.app.asset.Trigger as AssetTrigger;
import sk.thenet.bmp.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import common.*;

class Main extends Application {
  public static inline var WIDTH:Int = 400;
  public static inline var HEIGHT:Int = 225;
  public static inline var HWIDTH:Int = 200;
  public static inline var HHEIGHT:Int = 112;
  
  public static function main():Void Platform.boot(function() new Main());
  
  public function new(){
    super([
         Assets([
              Embed.getBitmap("game", "png/game.png")
             ,Embed.getBitmap("console_font", "png/font.png")
             ,new AssetTrigger("pal", ["game"], Palette.init)
             ,new AssetBind(["game", "pal"], Sprites.init)
             ,new AssetBind(["game", "pal", "console_font"], GUI.init)
           ])
        ,Console
        ,Framerate(60)
        ,Surface(400, 225, 1)
        ,Keyboard
        ,Mouse
      ]);
    
    GameState.init();
    
    preloader = new TNPreloader(this, "game", true);
    addState(new SGame(this));
    mainLoop();
  }
}
