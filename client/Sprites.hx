import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.Bitmap;
import sk.thenet.bmp.Colour;
import sk.thenet.bmp.OrderedDither;
import sk.thenet.bmp.manip.*;
import sk.thenet.plat.Platform;

class Sprites {
  public static var factionSigns:Vector<RotatedSprite>;
  public static var units:Vector<Vector<RotatedSprite>>;
  public static var amasks:Vector<Bitmap>;
  public static var amasksManip:Vector<AlphaMask>;
  public static var moveds:Vector<Bitmap>;
  public static var starlight:Vector<Bitmap>;
  
  public static function init(am:AssetManager, _):Bool {
    amasks = new Vector<Bitmap>(8);
    amasksManip = new Vector<AlphaMask>(8);
    
    for (a in 0...8){
        amasks[a] = Platform.createBitmap(48, 48, 0);
        var vi = 0;
        var avec = new Vector<Colour>(48 * 48);
        for (y in 0...48) for (x in 0...48){
          avec[vi] = (OrderedDither.BAYER_4[(x % 4) + ((y % 4) << 2)] < a * 2 ? 0 : 0xFF000000);
          vi++;
        }
        amasks[a].setVector(avec);
        amasksManip[a] = new AlphaMask(amasks[a], true);
    }
    factionSigns = Vector.fromArrayCopy([ for (i in 0...8)
        new RotatedSprite(
             am.getBitmap("game").fluent >> (new Cut(i * 24, 56, 24, 24))
            ,2//4
          )
      ]);
    
    units = new Vector(8);
    for (f in 0...8){
      units[f] = new Vector(7);
    }
    for (u in 0...7){
      var base = am.getBitmap("game").fluent
          >> (new Cut(48 + u * 24, 80, 24, 24));
      var outline = am.getBitmap("game").fluent
          >> (new Cut(48 + u * 24, 80 + 24, 24, 24));
      for (f in 0...8){
        if (f > 0){
          units[f][u] = units[0][u];
        }
        outline << (new Recolour(Palette.factions[8 + f]));
        base.bitmap.blitAlpha(outline, 0, 0);
        units[f][u] = new RotatedSprite(base, 2/*4*/);
      }
    }
    
    moveds = new Vector<Bitmap>(4);
    for (i in 0...moveds.length){
      moveds[i] = am.getBitmap("game").fluent >> (new Cut(216 + i * 24, 80, 24, 24));
    }
    
    starlight = new Vector(8);
    for (i in 0...8){
      starlight[i] = am.getBitmap("game").fluent >> (new Cut(216 + i * 8, 104, 8, 8));
    }
    
    return false;
  }
}

abstract RotatedSprite(Vector<Bitmap>) from Vector<Bitmap> {
  public inline function new(orig:Bitmap, angles:Int){
    var vec = new Vector<Bitmap>(8 * angles);
    for (a in 0...8){
      for (i in 0...angles){
        vec[a * angles + i] = orig.fluent
          >> (new Rotate((i / angles) * Math.PI * 2))
          << Sprites.amasksManip[a];
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
