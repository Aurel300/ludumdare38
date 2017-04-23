package common;

import sk.thenet.bmp.Colour;
import sk.thenet.geom.Point3DF;

class Tile {
  public var adjacent(default, null):Array<Tile>;
  public var points  (default, null):Array<Int>;
  
  public var colour:Int;
  public var visible:Bool;
  public var pent:Bool;
  public var occupied:Int = -1;
  public var alpha:Int;
  public var banner:Int = -1;
  public var sprite:Int = -1;
  public var spriteX:Int = -1;
  public var spriteY:Int = -1;
  public var spriteAngle:Float = -1;
  public var spriteOX:Float = -1;
  public var spriteOY:Float = -1;
  
  public function new(points:Array<Int>){
    this.adjacent = [];
    this.points   = points;
  }
}
