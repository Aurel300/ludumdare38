package common;

import haxe.ds.Vector;

class Unit {
  public static var UNITS:Vector<Unit> = Vector.fromArrayCopy([
      new Unit(0, "asdf", {
           hp: 1, maxHp: 1
          ,mp: 1, maxMp: 1
          ,atk: 1, def: 1, ran: 1
        })
    ]);
  
  public var sprite:Int;
  public var name:String;
  public var stats:Stats;
  
  public function new(sprite:Int, name:String, stats:Stats){
    this.sprite = sprite;
    this.name = name;
    this.stats = stats;
  }
}
