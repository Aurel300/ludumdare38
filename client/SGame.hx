import sk.thenet.anim.Timing;
import sk.thenet.app.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import common.*;

class SGame extends State {
  private var ico:Geodesic;
  private var ren:GeodesicRender;
  private var zoomIntro:Float;
  private var gui:GUI;
  
  public function new(app:Application){
    super("game", app);
  }
  
  override public function to():Void {
    ico = Geodesic.generateIcosahedron(4);
    ren = new GeodesicRender(ico);
    zoomIntro = 0;
    gui = new GUI(app, ico, ren);
  }
  
  override public function tick():Void {
    app.bitmap.fill(Palette.pal[3]);
    
    if (zoomIntro < 1){
      ren.scale(Timing.quadInOut(zoomIntro) * 190);
      zoomIntro += .01;
    }
    
    ren.render(app.bitmap, gui.allowSelect);
    gui.render(app.bitmap);
  }
  
  override public function mouseClick(_, _):Void {
    gui.click();
  }
}
