package common;

import haxe.ds.Vector;

enum OrderType {
  Cancel;
  Skip;
  Capture;
  Shield;
  Abandon;
  Undo;
  Build;
  BuildCancel;
}

class Unit {
  public static var ORDERS:Vector<Order> = Vector.fromArrayCopy([
       {name: "Cancel",  tooltip: "Deselect the tile.", type: Cancel}
      ,{name: "Skip",    tooltip: "Do nothing with this unit.", type: Skip}
      ,{name: "Capture", tooltip: "Attempt to capture the tile this unit is on.\nThis costs 1 SL, 1 NRG upkeep.\nTaking land owned by someone else\ntakes 1 additional NRG.", type: Capture}
      ,{name: "Shield",  tooltip: "Raise shields on this tile.", type: Shield}
      ,{name: "Abandon", tooltip: "Abandon this tile.", type: Abandon}
      ,{name: "Undo",    tooltip: "Undoes the turn of this unit.", type: Undo}
      ,{name: "Build",   tooltip: "Build a unit here.", type: Build}
      ,{name: "Stop build", tooltip: "Cancels the unit being built.\nResources are returned.", type: BuildCancel}
    ]);
  
  public static var HOME_LAND_ORDERS:Array<Int> = [];
  public static var AWAY_LAND_ORDERS:Array<Int> = [2];
  
  public static var UNITS:Vector<Unit> = Vector.fromArrayCopy([
      new Unit(0, "Generator", {
           hp: 10, maxHp: 10
          ,mp: 1
          ,atk: 0, def: 2, ran: 0
        }, [1], 10, 0, 0)
      ,new Unit(1, "Starlight Catcher", {
           hp: 2, maxHp: 2
          ,mp: 1
          ,atk: 1, def: 1, ran: 1
        }, [1, 2], 15, 1, 1)
      ,new Unit(2, "Boot", {
           hp: 5, maxHp: 5
          ,mp: 2
          ,atk: 3, def: 1, ran: 1
        }, [1, 2], 2, 0, 1)
      ,new Unit(3, "Bow and Arrow", {
           hp: 4, maxHp: 4
          ,mp: 2
          ,atk: 2, def: 0, ran: 2
        }, [1, 2], 3, 0, 1)
      ,new Unit(4, "Trebuchet", {
           hp: 1, maxHp: 1
          ,mp: 1
          ,atk: 2, def: 1, ran: 2
        }, [1, 2], 5, 0, 2)
      ,new Unit(5, "Stick of Dynamite", {
           hp: 1, maxHp: 1
          ,mp: 2
          ,atk: 10, def: 0, ran: 0
        }, [1], 7, 5, 5)
      ,new Unit(6, "Cloak and Dagger", {
           hp: 1, maxHp: 1
          ,mp: 3
          ,atk: 5, def: 0, ran: 1
        }, [1, 2], 10, 0, 5)
    ]);
  
  public var sprite:Int;
  public var name:String;
  public var stats:Stats;
  public var orders:Array<Int>;
  public var costSL:Int;
  public var costONRG:Int;
  public var costUNRG:Int;
  
  public function new(
     sprite:Int, name:String, stats:Stats, orders:Array<Int>
    ,costSL:Int, costONRG:Int, costUNRG:Int
  ){
    this.sprite = sprite;
    this.name = name;
    this.stats = stats;
    this.orders = orders;
    this.costSL = costSL;
    this.costONRG = costONRG;
    this.costUNRG = costUNRG;
  }
  
  public function cloneStats():Stats {
    return {
         hp: stats.hp
        ,maxHp: stats.maxHp
        ,mp: stats.mp
        ,atk: stats.atk
        ,def: stats.def
        ,ran: stats.ran
      };
  }
}

typedef Order = {
     name:String
    ,tooltip:String
    ,type:OrderType
  };
