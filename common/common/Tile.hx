package common;

import sk.thenet.bmp.Colour;
import sk.thenet.geom.Point3DF;

class Tile {
  public var points  (default, null):Array<Int>;
  public var adjacent(default, null):Array<Tile>;
  public var range   (default, null):Array<Tile>;
  
  public var index:Int;
  public var colour:Int;
  public var visible:Bool;
  public var pent:Bool;
  public var alpha:Int;
  public var dist:Int = -1;
  public var sprite:Int = -1;
  public var spriteFaction:Int = -1;
  public var spriteX:Int = -1;
  public var spriteY:Int = -1;
  public var spriteAngle:Float = -1;
  public var spriteOX:Float = -1;
  public var spriteOY:Float = -1;
  public var selected:Bool = false;
  public var hover:Bool = false;
  public var starlight:Array<Starlight> = [];
  
  public function new(points:Array<Int>){
    this.points   = points;
    this.adjacent = [];
    this.range    = [];
  }
}

typedef Starlight = {
     h:Float
    ,v:Float
    ,t:Int
  };
