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
              Embed.getSound("boot_attack", "wav/Boot_Attack.wav")
             ,Embed.getSound("boot_select", "wav/Boot_Select.wav")
             ,Embed.getSound("bow_attack", "wav/Bow_Attack.wav")
             ,Embed.getSound("bow_select", "wav/Bow_Select.wav")
             ,Embed.getSound("dagger_attack", "wav/Dagger_Attack.wav")
             ,Embed.getSound("dagger_select", "wav/Dagger_Select.wav")
             ,Embed.getSound("dynamite_attack", "wav/Dynamite_Attack.wav")
             ,Embed.getSound("dynamite_select", "wav/Dynamite_Select.wav")
             ,Embed.getSound("generator_select", "wav/Generator_Select.wav")
             ,Embed.getSound("gui_click", "wav/GUI_Click.wav")
             ,Embed.getSound("gui_drawer_close", "wav/GUI_Drawer_Close.wav")
             ,Embed.getSound("gui_drawer_open", "wav/GUI_Drawer_Open.wav")
             ,Embed.getSound("land_capture", "wav/Land_Capture.wav")
             ,Embed.getSound("invalid_move", "wav/Move_Invalid.wav")
             ,Embed.getSound("move", "wav/Move_Valid.wav")
             ,Embed.getSound("player_connect", "wav/Player_Connect_Meteor.wav")
             ,Embed.getSound("sl_catcher_attack", "wav/Starlight_Catcher_Attack.wav")
             ,Embed.getSound("sl_catcher_select", "wav/Starlight_Catcher_Select.wav")
             ,Embed.getSound("starlight_from_sky", "wav/Starlight_From_Sky.wav")
             ,Embed.getSound("starlight_gather", "wav/Starlight_Gather.wav")
             ,Embed.getSound("trebuchet_attack", "wav/Trebuchet_Attack.wav")
             ,Embed.getSound("trebuchet_select", "wav/Trebuchet_Select.wav")
             ,Embed.getBitmap("game", "png/game.png")
             ,Embed.getBitmap("console_font", "png/font.png")
             ,Embed.getSound("turn_alert", "wav/Turn_Alert.wav")
             ,new AssetTrigger("pal", ["game"], Palette.init)
             ,new AssetTrigger("sprites", ["game", "pal"], Sprites.init)
             ,new AssetBind(["game", "pal", "console_font", "sprites"], GUI.init)
           ])
        //,Console
        ,Framerate(60)
        ,Surface(400, 225, 1)
        ,Keyboard
        ,Mouse
      ]);
    
    preloader = new TNPreloader(this, "login", false);
    addState(new SLogin(this));
    addState(new SGame(this));
    mainLoop();
  }
}
