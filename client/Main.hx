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
             ,Embed.getSound("dagger_attack", "wav/Dagger_Attack.wav")
             ,Embed.getSound("dagger_select", "wav/Dagger_Select.wav")
             ,Embed.getSound("dynamite_attack", "wav/Dynamite_Attack.wav")
             ,Embed.getSound("dynamite_select", "wav/Dynamite_Select.wav")
             ,Embed.getSound("generator_select", "wav/Generator_Select.wav")
             ,Embed.getSound("gui_drawer", "wav/GUI_Drawer_Open.wav")
             ,Embed.getSound("invalid_move", "wav/Invalid_Move.wav")
             ,Embed.getSound("move", "wav/Move.wav")
             ,Embed.getSound("player_connect", "wav/Player_Connect.wav")
             ,Embed.getSound("sl_catcher_attack", "wav/Starlight_Catcher_Attack.wav")
             ,Embed.getSound("sl_catcher_select", "wav/Starlight_Catcher_Select.wav")
             ,Embed.getSound("trebuchet_select", "wav/Trebuchet_Select_Final.wav")
             ,Embed.getSound("turn_almost_over", "wav/Turn_Almost_Over.wav")
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
    
    preloader = new TNPreloader(this, "login", true);
    addState(new SLogin(this));
    addState(new SGame(this));
    mainLoop();
  }
}
