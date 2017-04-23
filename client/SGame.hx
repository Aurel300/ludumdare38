import sk.thenet.anim.Timing;
import sk.thenet.app.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import common.*;

class SGame extends State {
  private var ico:Geodesic;
  private var zoomIntro:Float;
  private var camera:Quaternion;
  
  public function new(app:Application){
    super("game", app);
  }
  
  override public function to():Void {
    ico = Geodesic.generateIcosahedron(4);
    zoomIntro = 0;
    camera = Quaternion.identity;
  }
  
  override public function tick():Void {
    app.bitmap.fill(Palette.pal[3]);
    ico.scale(Timing.quadInOut(zoomIntro) * 190);
    
    if (zoomIntro < 1){
      zoomIntro += .01;
    }
    
    ico.render(app.bitmap);
    var cursor = 0;
    var movecursors = [
         new Point2DI(Main.HWIDTH - 140, Main.HHEIGHT + 70)
        ,new Point2DI(Main.HWIDTH + 140, Main.HHEIGHT + 70)
        ,new Point2DI(Main.HWIDTH - 140, Main.HHEIGHT - 30)
        ,new Point2DI(Main.HWIDTH + 140, Main.HHEIGHT - 30)
      ];
    for (ri in 0...movecursors.length){
      var i = movecursors.length - ri - 1;
      var dist = (new Point2DI(Platform.mouse.x, Platform.mouse.y)).subtract(movecursors[i]).abs().componentSum();
      if (dist < 70){
        cursor = i + 1;
      }
    }
    app.bitmap.blitAlphaRect(
         am.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y, 32 + (cursor * 8), 24, 8, 8
      );
    switch (cursor){
      case i if (i >= 1 && i <= 4 && Platform.mouse.held):
      camera = Quaternion.axisRotation(
           (i >= 2 && i <= 3 ? new Point3DF(-1, 1, 0) : new Point3DF(1, 1, 0)).unit()
          ,(i % 2 == 0 ? -.02 : .02)
        ).multiply(camera).unit;
      ico.rotate(camera);
      
      case 0:
    }
  }
}
