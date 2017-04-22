import sk.thenet.FM;
import sk.thenet.app.*;
import sk.thenet.app.Keyboard.Key;
import sk.thenet.app.asset.Bind as AssetBind;
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
             ,new AssetBind(["game"], Palette.init)
           ])
        ,Framerate(60)
        ,Surface(400, 225, 1)
        ,Keyboard
        ,Mouse
      ]);
    
    preloader = new TNPreloader(this, "test", true);
    addState(new STest(this));
    mainLoop();
  }
}

class STest extends State {
  private var ico:Geodesic;
  
  public function new(app:Application){
    super("test", app);
  }
  
  override public function to():Void {
    ico = Geodesic.generateIcosahedron(4);
  }
  
  override public function tick():Void {
    app.bitmap.fill(Palette.pal[3]);
    ico.rotate(Quaternion.axisRotation(new Point3DF(1, 0, .5), Platform.mouse.x / 100), Platform.mouse.y);
    ico.render(app.bitmap);
  }
}
