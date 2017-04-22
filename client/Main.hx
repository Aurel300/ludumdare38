import sk.thenet.FM;
import sk.thenet.app.*;
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
         Framerate(60)
        ,Surface(400, 225, 1)
        ,Mouse
      ]);
    
    addState(new STest(this));
    mainLoop();
  }
}

class STest extends State {
  private var ico:Geodesic;
  
  public function new(app:Application){
    super("test", app);
    ico = Geodesic.generateIcosahedron();
  }
  
  override public function to():Void {
  }
  
  override public function tick():Void {
    app.bitmap.fill(0xFF333333);
    ico.render(app.bitmap, Platform.mouse.x / 100);
  }
}