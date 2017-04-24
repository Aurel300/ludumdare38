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
             ,Embed.getSound("boot_select", "wav/Boot_Select.wav")
             ,Embed.getSound("bow_attack", "wav/Bow_Attack.wav")
             ,Embed.getSound("bow_select", "wav/Bow_Select.wav")
             //,Embed.getSound("", "wav/Coin.wav")
             //,Embed.getSound("", "wav/CoinSmall.wav")
             ,Embed.getSound("dagger_select", "wav/Dagger_Select.wav")
             ,Embed.getSound("generator_select", "wav/Generator_Select.wav")
             ,Embed.getSound("gui_drawer", "wav/GUI_Drawer_Open.wav")
             ,Embed.getSound("trebuchet_select", "wav/Trebuchet_Select_Final.wav")
             ,new AssetTrigger("pal", ["game"], Palette.init)
             ,new AssetTrigger("sprites", ["game", "pal"], Sprites.init)
             ,new AssetBind(["game", "pal", "console_font", "sprites"], GUI.init)
           ])
        ,Console
        ,Framerate(60)
        ,Surface(400, 225, 1)
        ,Keyboard
        ,Mouse
      ]);
    
    preloader = new TNPreloader(this, "game", true);
    addState(new SGame(this));
    mainLoop();
  }
}
