package common;

import sk.thenet.geom.Point3DF;

class Tile {
  public var adjacent(default, null):Array<Tile>;
  public var points  (default, null):Array<Int>;
  
  public function new(adjacent:Array<Tile>, points:Array<Int>){
    this.adjacent = adjacent;
    this.points   = points;
  }
}
