package common;

import sk.thenet.geom.Point3DF;

class GeoPoint extends Point3DF {
  public static function ofPoint(p:Point3DF):GeoPoint {
    return new GeoPoint(p.x, p.y, p.z);
  }
  
  public var tiles:Array<Tile>;
  public var visible:Bool;
  
  public function new(x:Float, y:Float, z:Float){
    super(x, y, z);
    var magn:Float = magnitude();
    x /= magn;
    y /= magn;
    z /= magn;
    tiles = [];
    visible = true;
  }
}
