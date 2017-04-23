import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.Bitmap;
import sk.thenet.bmp.Colour;
import sk.thenet.bmp.OrderedDither;
import sk.thenet.bmp.manip.AlphaMask;
import sk.thenet.bmp.manip.Cut;
import sk.thenet.bmp.manip.Rotate;
import sk.thenet.plat.Platform;

class Sprites {
  public static var factionSigns:Vector<RotatedSprite>;
  
  public static function init(am:AssetManager, _):Bool {
    factionSigns = Vector.fromArrayCopy([
        for (i in 0...8){
          new RotatedSprite(
               am.getBitmap("game").fluent >> (new Cut(i * 24, 56, 24, 24))
              ,24
            );
        }
      ]);
    return false;
  }
}

abstract RotatedSprite(Vector<Bitmap>) from Vector<Bitmap> {
  public inline function new(orig:Bitmap, angles:Int){
    var vec = new Vector<Bitmap>(8 * angles);
    for (a in 0...8){
      var amask = Platform.createBitmap(orig.width << 1, orig.height << 1, 0);
      var vi = 0;
      var avec = amask.getVector();
      for (y in 0...amask.height) for (x in 0...amask.width){
        avec[vi] = (OrderedDither.BAYER_4[(x % 4) + ((y % 4) << 2)] < a * 2 ? 0 : 0xFF000000);
        vi++;
      }
      amask.setVector(avec);
      for (i in 0...angles){
        vec[a * angles + i] = orig.fluent
          >> (new Rotate((i / angles) * Math.PI * 2))
          << (new AlphaMask(amask, true));
      }
    }
    this = vec;
  }
  
  public inline function get(alpha:Int, angle:Float):Bitmap {
    while (angle < 0){
      angle += Math.PI * 2;
    }
    var angles:Int = FM.floor(this.length >> 3);
    var di:Float = ((angle) / (Math.PI * 2)) * angles;
    var df:Float = di - FM.floor(di);
    var dc:Float = FM.ceil(di) - di;
    return this[alpha * angles + ((df <= dc ? FM.floor(di) : FM.ceil(di)) % angles)];
  }
}
