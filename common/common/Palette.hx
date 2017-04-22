package common;

import haxe.ds.Vector;
import js.html.CanvasPattern;
import sk.thenet.FM;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.Bitmap;
import sk.thenet.bmp.Colour;
import sk.thenet.bmp.OrderedDither;
import sk.thenet.plat.Platform;

class Palette {
  private static inline var MEZZO:Int = 6;
  public static inline var ALPHA:Int = 8 + MEZZO * 7;
  
  public static var pal:Vector<Colour>;
  public static var patterns:Vector<CanvasPattern>;
  
  public static function init(am:AssetManager, _):Bool {
    var raw = am.getBitmap("game");
    pal = Vector.fromArrayCopy([ for (i in 0...8) raw.get(i * 8, 0) ]);
    patterns = Vector.fromArrayCopy([
      for (a in 1...5) for (i in 0...(8 + 7 * MEZZO)){
        var p = Platform.createBitmap(
            4, 4, pal[FM.floor(i / (MEZZO + 1))]
          );
        var di:Int = 0;
        for (y in 0...4) for (x in 0...4){
          if (i % (MEZZO + 1) != 0
              && OrderedDither.BAYER_4[di++] < (i % (MEZZO + 1)) * 2){
            p.set(x, y, pal[FM.floor(i / (MEZZO + 1)) + 1]);
          }
          if ((x + y) % a != 0){
            p.set(x, y, 0);
          }
        }
        p.toFillPattern();
      } ]);
    return false;
  }
}
