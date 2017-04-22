package common;

import sk.thenet.bmp.Colour;
import sk.thenet.geom.Point3DF;

class Tile {
  public var adjacent(default, null):Array<Tile>;
  public var points  (default, null):Array<Int>;
  
  public var colour:Colour;
  public var visible:Bool;
  public var xsum:Int;
  
  public function new(points:Array<Int>){
    this.adjacent = [];
    this.points   = points;
  }
}
