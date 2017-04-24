package common;

import haxe.ds.Vector;
import sk.thenet.FM;

class GameState {
  public static inline var TILES:Int = 320;
  
  public static var height (default, null):Vector<Float>;
  public static var faction(default, null):Vector<Int>;
  public static var name   (default, null):Array<String>;
  public static var unit   (default, null):Vector<Int>;
  public static var unitFac(default, null):Vector<Int>;
  public static var stats  (default, null):Vector<Stats>;
  public static var star   (default, null):Vector<Int>;
  
  public static function init():Void {
    height = new Vector(TILES);
    for (i in 0...TILES){
      height[i] = FM.prng.nextFloat(.2);
    }
    faction = new Vector(TILES);
    name = [];
    unit = new Vector(TILES);
    unitFac = new Vector(TILES);
    stats = new Vector(TILES);
    star = new Vector(TILES);
  }
}
