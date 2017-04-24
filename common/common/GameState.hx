package common;

import haxe.Json;
import haxe.ds.Vector;
import sk.thenet.FM;

class GameState {
  public static inline var TILES:Int = 320;
  
  // clients
  public static var currentFaction(default, null):Int;
  public static var currentMoves  (default, null):Array<Move>;
  public static var currentClicks (default, null):Vector<Move>;
  public static var currentSL     (default, null):Int;
  public static var currentNRG    (default, null):Int;
  public static var maxNRG        (default, null):Int;
  public static var turned        (default, null):Vector<MoveStatus>;
  
  // server
  public static var height (default, null):Vector<Float>;
  public static var faction(default, null):Vector<Int>;
  public static var name   (default, null):Array<String>;
  public static var unit   (default, null):Vector<Int>;
  public static var unitFac(default, null):Vector<Int>;
  public static var stats  (default, null):Vector<Stats>;
  public static var star   (default, null):Vector<Int>;
  public static var shield (default, null):Vector<Unit>;
  public static var ticker (default, null):Date;
  public static var period (default, null):Float;
  
  private static var ico:Geodesic;
  private static var latestCurrentMoves:Map<Int, Array<Move>>;
  private static var latestTurned      :Map<Int, Array<Int>>;
  
  public static function untilTicker():Int {
    var diff:Float = Date.now().getTime() - ticker.getTime();
    if (diff > period){
      return 0;
    }
    return FM.floor((period - diff) / 1000);
  }
  
  public static function tick():Void {
    ticker = Date.now();
    for (ms in latestCurrentMoves){
      for (m in ms){
        currentMoves.push(m);
      }
    }
    latestCurrentMoves = new Map();
    for (f in latestTurned.keys()){
      var ft = latestTurned.get(f);
      for (ti in 0...ft.length){
        if (unitFac[ti] == f){
          turned[ti] = ft[ti];
        }
      }
    }
    latestTurned = new Map();
    turn();
  }
  
  public static function encodeTicker():String {
    return Json.stringify({t: ticker.getTime()});
  }
  
  public static function encodeMaster():String {
    return Json.stringify({
         h: height.toArray()
        ,f: faction.toArray()
        //,n: name.toArray()
        ,u: unit.toArray()
        ,uf: unitFac.toArray()
        ,s: stats.toArray()
        //,sr: star.toArray()
        //,sh:
        ,t: ticker.getTime()
        ,p: period
      });
  }
  
  public static function encodeTurn():String {
    return Json.stringify({
         f: currentFaction
        ,m: currentMoves.map(function(m:Move):Array<Int> {
            return [m.from, m.to, m.type];
          })
        ,t: turned.toArray()
      });
  }
  
  public static dynamic function encodeTurnSend():Void {}
  
  public static function decodeTicker(s:String):Void {
    var obj = Json.parse(s);
    ticker  = Date.fromTime(obj.t);
  }
  
  public static function decodeMaster(s:String):Void {
    var obj = Json.parse(s);
    height  = Vector.fromArrayCopy(obj.h);
    faction = Vector.fromArrayCopy(obj.f);
    //name    = obj.n
    unit    = Vector.fromArrayCopy(obj.u);
    unitFac = Vector.fromArrayCopy(obj.uf);
    stats   = Vector.fromArrayCopy(obj.s);
    //star    = Vector.fromArrayCopy(obj.sr);
    //shield  = Vector.fromArrayCopy(obj.sh);
    ticker  = Date.fromTime(obj.t);
    period  = obj.p;
    for (i in 0...TILES){
      turned[i] = MoveStatus.None;
      if (unit[i] != -1){
        turned[i] = MoveStatus.Ready;
      }
    }
  }
  
  public static function decodeTurn(s:String):Void {
    var obj = Json.parse(s);
    latestCurrentMoves.set(obj.f, currentMoves.concat(obj.m.map(function(a:Array<Int>):Move {
        return new Move(a[0], a[1], a[2]);
      })));
    latestTurned.set(obj.f, obj.t);
  }
  
  public static function initEmpty(ico:Geodesic):Void {
    GameState.ico = ico;
    currentFaction = 0;
    currentMoves   = [];
    currentClicks  = new Vector(TILES);
    currentSL      = 5;
    currentNRG     = 11;
    maxNRG         = 15;
    turned         = new Vector(TILES);
    for (i in 0...TILES){
      currentClicks[i] = null;
      turned[i]        = MoveStatus.None;
    }
  }
  
  public static function init(ico:Geodesic):Void {
    initEmpty(ico);
    
    latestCurrentMoves = new Map();
    latestTurned = new Map();
    
    height  = new Vector(TILES);
    faction = new Vector(TILES);
    name    = [];
    unit    = new Vector(TILES);
    unitFac = new Vector(TILES);
    stats   = new Vector(TILES);
    star    = new Vector(TILES);
    shield  = new Vector(TILES);
    ticker  = Date.now();
    period  = 5 * 2 * 1000;
    for (i in 0...TILES){
      height[i]  = FM.prng.nextFloat(.2);
      faction[i] = -1;
      unit[i]    = -1;
      unitFac[i] = -1;
      shield[i]  = null;
    }
    
    for (i in 0...1){
      spawnPlayer("foo", 0, FM.prng.nextMod(TILES));
      spawnPlayer("bar", 1, FM.prng.nextMod(TILES));
    }
  }
  
  public static function spawnPlayer(name:String, player:Int, t:Int):Void {
    faction[t] = player;
    unit   [t] = 0;
    unitFac[t] = player;
    turned [t] = MoveStatus.Ready;
    stats  [t] = Unit.UNITS[unit[t]].cloneStats();
    var i:Int = 1;
    for (a in ico.tiles[t].adjacent){
      faction[a.index] = player;
      unit[a.index] = i;
      unitFac[a.index] = player;
      turned[a.index] = (player == currentFaction ? MoveStatus.Ready : MoveStatus.None);
      stats[a.index] = Unit.UNITS[unit[a.index]].cloneStats();
      i++;
    }
  }
  
  public static function killUnit(t:Int):Void {
    unit   [t] = -1;
    unitFac[t] = -1;
    stats  [t] = null;
    turned [t] = MoveStatus.None;
  }
  public static function moveUnit(f:Int, t:Int):Void {
    unit   [t] = unit   [f];
    unitFac[t] = unitFac[f];
    stats  [t] = stats  [f];
    unit   [f] = -1;
    unitFac[f] = -1;
    stats  [f] = null;
  }
  public static function captureLand(t:Int):Void {
    faction[t] = unitFac[t];
  }
  
  public static function turnInit():Void {
    
  }
  
  private static var DAMAGE_TABLE:Vector<Int> = Vector.fromArrayCopy([
       0 , 0 , 1 , 0 , 0 , 8  , 3 , 0 , 0 , 5
      ,0 , 0 , 2 , 1 , 1 , 9  , 4 , 0 , 0 , 5
      ,0 , 0 , 1 , 1 , 1 , 9  , 4 , 0 , 0 , 5
      ,0 , 1 , 3 , 2 , 2 , 10 , 5 , 0 , 0 , 5
      ,0 , 0 , 1 , 1 , 1 , 9  , 4 , 0 , 0 , 5
      ,0 , 1 , 3 , 2 , 2 , 10 , 5 , 0 , 0 , 5
      ,0 , 1 , 3 , 2 , 2 , 10 , 5 , 0 , 0 , 5
      ,0 , 1 , 3 , 2 , 2 , 10 , 5 , 0 , 0 , 5
      ,0 , 1 , 3 , 2 , 6 , 10 , 5 , 0 , 0 , 5
    ]);
  
  public static function turn():Void {
    var tilesAttacked = [];
    var attacks = currentMoves.filter(function(m) return m.type == Attack);
    while (attacks.length > 0){
      var at = attacks.splice(FM.prng.nextMod(attacks.length), 1)[0];
      if (unit[at.from] == -1 || unit[at.to] == -1){
        continue;
      }
      tilesAttacked.push(at.to);
      if (turned[at.to] == MoveStatus.Building){
        killUnit(at.to);
        continue;
      }
      var attacker = unit[at.from];
      var defender = unit[at.to];
      var dmg = DAMAGE_TABLE[attacker + defender * 10];
      var counter = 0;
      if (defender == 5){
        counter = DAMAGE_TABLE[defender + attacker * 10];
        killUnit(at.to);
        // explode others ?
      } else if (dmg >= stats[at.to].hp){
        killUnit(at.to);
      } else {
        stats[at.to].hp -= dmg;
        counter = DAMAGE_TABLE[defender + attacker * 10];
      }
      if (counter > 0){
        if (counter >= stats[at.from].hp){
          killUnit(at.from);
        } else {
          stats[at.from].hp -= counter;
        }
      }
    }
    var moves = currentMoves.filter(function(m) return m.type == Movement);
    while (moves.length > 0){
      var mv = moves.splice(FM.prng.nextMod(moves.length), 1)[0];
      if (unit[mv.from] == -1 || unit[mv.to] != -1){
        continue;
      }
      moveUnit(mv.from, mv.to);
    }
    var captures = currentMoves.filter(function(m) return m.type == Capture);
    while (captures.length > 0){
      var cp = captures.splice(FM.prng.nextMod(captures.length), 1)[0];
      if (unit[cp.from] == -1 || tilesAttacked.indexOf(cp.from) != -1){
        continue;
      }
      captureLand(cp.from);
    }
    currentMoves = [];
    
    for (i in 0...TILES){
      if (turned[i] == MoveStatus.Building){
        stats[i] = Unit.UNITS[unit[i]].cloneStats();
      }
      currentClicks[i] = null;
      turned[i] = MoveStatus.None;
      if (unit[i] != -1){
        turned[i] = MoveStatus.Ready;
      }
    }
  }
  
  public static function connect():Void {
    
  }
  
  public static function serve():Void {
    
  }
}
