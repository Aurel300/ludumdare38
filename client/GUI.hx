import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.app.Application;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.Bitmap;
import sk.thenet.bmp.Colour;
import sk.thenet.bmp.manip.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import common.*;

class GUI {
  private static var guiKarma:Bitmap;
  private static var guiDialogEvil:Vector<Bitmap>;
  private static var guiDialogGood:Vector<Bitmap>;
  
  private static function renderBubble(
    am:AssetManager, c1:Colour, c2:Colour, width:Int, height:Int, ?arrow:Int = -1
  ):Vector<Bitmap> {
    if (arrow == -1){
      arrow = width >> 1;
    }
    arrow -= 7;
    arrow = FM.clampI(arrow, 2, width - 16);
    var ret = new Vector<Bitmap>(2);
    for (i in 0...2){
      ret[i] = Platform.createBitmap(width, height, 0);
      ret[i].setFillColour(c1);
      ret[i].fillRectStyled(1, 0, width - 2, 1);
      ret[i].fillRectStyled(0, 1, 1, height - 8);
      ret[i].fillRectStyled(width - 1, 1, 1, height - 8);
      ret[i].fillRect(1, 1, width - 2, height - 8, c2);
      ret[i].setFillColour(c1);
      ret[i].fillRectStyled(width - 2, 2, 1, height - 10);
      ret[i].fillRectStyled(2, height - 8, width - 3, 1);
      ret[i].fillRectStyled(1, height - 7, width - 2, 1);
      
      var arrBmp = Platform.createBitmap(14, 8, 0);
      arrBmp.blitAlpha(am.getBitmap("game").fluent
        >> (new Cut(0, 80 + i * 8, 14, 8))
        << (new Recolour(c1)), 0, 0);
      arrBmp.blitAlpha(am.getBitmap("game").fluent
        >> (new Cut(16, 80 + i * 8, 14, 8))
        << (new Recolour(c2)), 0, 0);
      
      ret[i].blitAlpha(arrBmp, arrow, height - 8);
    }
    return ret;
  }
  
  public static function init(am:AssetManager, _):Bool {
    guiKarma = Platform.createBitmap(Main.WIDTH, 24, 0);
    guiKarma.blitAlphaRect(am.getBitmap("game"), 0, 0, 32, 32, 24, 24);
    for (i in 0...44){
      guiKarma.blitAlphaRect(am.getBitmap("game"), 24 + i * 8, 0, 80, 32, 8, 24);
    }
    guiKarma.blitAlphaRect(am.getBitmap("game"), Main.WIDTH - 24, 0, 56, 32, 24, 24);
    
    guiDialogEvil = renderBubble(am, Palette.pal[5], Palette.pal[7], Main.HWIDTH - 8, 32, 0);
    
    return false;
  }
  
  public var allowSelect(default, null):Bool;
  
  private var app:Application;
  private var ico:Geodesic;
  private var action:GUIAction;
  private var lastAction:GUIAction;
  private var hoverAction:GUIAction;
  private var camera:Quaternion;
  private var cameraRotations:Vector<Quaternion>;
  
  public function new(app:Application, ico:Geodesic){
    allowSelect = true;
    this.app = app;
    this.ico = ico;
    action = None;
    lastAction = None;
    camera = Quaternion.identity;
    cameraRotations = Vector.fromArrayCopy([ for (i in 1...5)
        Quaternion.axisRotation(
             (i >= 2 && i <= 3 ? new Point3DF(-1, 1, 0) : new Point3DF(1, 1, 0)).unit()
            ,(i % 2 == 0 ? -.06 : .06)
          )
      ]);
  }
  
  public function tick():Void {
    hoverAction = None;
    
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
        hoverAction = Rotation(i);
      }
    }
    
    action = None;
    if (Platform.mouse.held){
      action = hoverAction;
    }
    
    allowSelect = false;
    switch (action){
      case None: allowSelect = true;
      case Rotation(r):
      camera = cameraRotations[r].multiply(camera).unit;
      ico.rotate(camera);
    }
  }
  
  public function render(bmp:Bitmap):Void {
    app.bitmap.blitAlpha(guiKarma, 0, Main.HEIGHT - 24);
    var cursor:Int = (switch (hoverAction){
        case None: 0;
        case Rotation(r): 1 + r;
      });
    app.bitmap.blitAlphaRect(
         app.assetManager.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y, 32 + (cursor * 8), 24, 8, 8
      );
    
    app.bitmap.blitAlpha(guiDialogEvil[0], 4, Main.HEIGHT - 24 - 32);
  }
}

private enum GUIAction {
  None;
  Rotation(r:Int);
}
