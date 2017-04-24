package common;

import haxe.ds.Vector;

class Unit {
  public static var ORDERS:Vector<Order> = Vector.fromArrayCopy([
       {name: "Cancel",  tooltip: "Deselect the unit."}
      ,{name: "Move",    tooltip: "Move the unit to the specified location."}
      ,{name: "Attack",  tooltip: "Attack another unit."}
      ,{name: "Capture", tooltip: "Attempt to capture the land this unit is on."}
      ,{name: "Shield",  tooltip: "Raise shields on this land."}
      ,{name: "Abandon", tooltip: "Abandon this land."}
    ]);
  
  public static var HOME_LAND_ORDERS:Array<Int> = [4, 5];
  public static var AWAY_LAND_ORDERS:Array<Int> = [3];
  
  public static var UNITS:Vector<Unit> = Vector.fromArrayCopy([
      new Unit(0, "Generator", {
           hp: 10, maxHp: 10
          ,mp: 1, maxMp: 1
          ,atk: 0, def: 2, ran: 0
        }, [0, 1])
      ,new Unit(1, "Starlight catcher", {
           hp: 2, maxHp: 2
          ,mp: 1, maxMp: 1
          ,atk: 1, def: 1, ran: 0
        }, [0, 1, 2])
      ,new Unit(2, "Boot", {
           hp: 5, maxHp: 5
          ,mp: 4, maxMp: 4
          ,atk: 3, def: 1, ran: 0
        }, [0, 1, 2])
      ,new Unit(3, "Bow and arrow", {
           hp: 4, maxHp: 4
          ,mp: 4, maxMp: 4
          ,atk: 2, def: 0, ran: 1
        }, [0, 1, 2])
      ,new Unit(4, "Trebuchet", {
           hp: 1, maxHp: 1
          ,mp: 2, maxMp: 2
          ,atk: 2, def: 1, ran: 2
        }, [0, 1, 2])
      ,new Unit(5, "Stick of dynamite", {
           hp: 1, maxHp: 1
          ,mp: 3, maxMp: 2
          ,atk: 10, def: 0, ran: 0
        }, [0, 1])
      ,new Unit(6, "Cloak and dagger", {
           hp: 1, maxHp: 1
          ,mp: 6, maxMp: 6
          ,atk: 5, def: 0, ran: 0
        }, [0, 1, 2])
    ]);
  
  public var sprite:Int;
  public var name:String;
  public var stats:Stats;
  public var orders:Array<Int>;
  
  public function new(sprite:Int, name:String, stats:Stats, orders:Array<Int>){
    this.sprite = sprite;
    this.name = name;
    this.stats = stats;
    this.orders = orders;
  }
}

typedef Order = {
     name:String
    ,tooltip:String
  };
