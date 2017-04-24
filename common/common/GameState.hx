package common;

import haxe.Json;
import haxe.ds.Vector;
import sk.thenet.FM;

class GameState {
  public static inline var TILES:Int = 320;
  
  public static var currentFaction(default, null):Int;
  public static var currentMoves  (default, null):Array<Move>;
  public static var currentClicks (default, null):Vector<Move>;
  public static var currentSL     (default, null):Int;
  public static var currentNRG    (default, null):Int;
  public static var maxNRG        (default, null):Int;
  
  public static var height (default, null):Vector<Float>;
  public static var faction(default, null):Vector<Int>;
  public static var name   (default, null):Array<String>;
  public static var unit   (default, null):Vector<Int>;
  public static var unitFac(default, null):Vector<Int>;
  public static var stats  (default, null):Vector<Stats>;
  public static var star   (default, null):Vector<Int>;
  public static var turned (default, null):Vector<MoveStatus>;
  public static var shield (default, null):Vector<Unit>;
  
  private static var ico:Geodesic;
  
  public static function encodeMaster():String {
    return Json.stringify({
         h: height.toArray()
        ,f: faction.toArray()
        //,n: name.toArray()
        ,u: unit.toArray()
        ,uf: unitFac.toArray()
        ,s: stats.toArray()
        //,sr: star.toArray()
        //,t:
        //,sh:
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
  
  public static function decodeMaster(s:String):Void {
    var obj = Json.parse(s);
    height  = Vector.fromArrayCopy(obj.h);
    faction = Vector.fromArrayCopy(obj.f);
    //name    = obj.n
    unit    = Vector.fromArrayCopy(obj.u);
    unitFac = Vector.fromArrayCopy(obj.uf);
    stats   = Vector.fromArrayCopy(obj.s);
    //star    = Vector.fromArrayCopy(obj.sr);
    //turned  = Vector.fromArrayCopy(obj.t);
    //shield  = Vector.fromArrayCopy(obj.sh);
  }
  
  public static function decodeTurn(s:String):Void {
    var obj = Json.parse(s);
    currentMoves = currentMoves.concat(obj.m.map(function(a:Array<Int>):Move {
        return new Move(a[0], a[1], a[2]);
      }));
    var objt = (cast obj.t:Array<Int>);
    for (t in 0...objt.length){
      if (unitFac[t] == obj.f){
        turned[t] = objt[t];
      }
    }
  }
  
  public static function init(ico:Geodesic):Void {
    GameState.ico = ico;
    
    currentFaction = 0;
    currentMoves   = [];
    currentClicks  = new Vector(TILES);
    currentSL      = 5;
    currentNRG     = 11;
    maxNRG         = 15;
    
    height  = new Vector(TILES);
    faction = new Vector(TILES);
    name    = [];
    unit    = new Vector(TILES);
    unitFac = new Vector(TILES);
    stats   = new Vector(TILES);
    star    = new Vector(TILES);
    turned  = new Vector(TILES);
    shield  = new Vector(TILES);
    for (i in 0...TILES){
      height[i]  = FM.prng.nextFloat(.2);
      faction[i] = -1;
      unit[i]    = -1;
      unitFac[i] = -1;
      turned[i]  = MoveStatus.None;
      shield[i]  = null;
      currentClicks[i] = null;
    }
    
    for (i in 0...1){
      //spawnPlayer("asdf", i, FM.prng.nextMod(TILES));
      spawnPlayer("foo", 0, FM.prng.nextMod(TILES));
      spawnPlayer("bar", 1, FM.prng.nextMod(TILES));
    }
    
    /*
    for (i in 0...40){
      var fi = FM.prng.nextMod(TILES);
      faction[fi] = FM.prng.nextMod(8);
      unit[fi]    = FM.prng.nextMod(Unit.UNITS.length);
      unitFac[fi] = FM.prng.nextMod(8);
      turned[fi]  = MoveStatus.Ready;
    }
    */
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
  
  public static function resolveTurns():Void {
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
  }
  
  public static function turn():Void {
    resolveTurns();
    for (i in 0...TILES){
      if (turned[i] == MoveStatus.Building){
        stats[i] = Unit.UNITS[unit[i]].cloneStats();
      }
      currentClicks[i] = null;
      turned[i] = MoveStatus.None;
      if (unit[i] != -1 && unitFac[i] == currentFaction){
        turned[i] = MoveStatus.Ready;
      }
    }
  }
  
  public static function connect():Void {
    
  }
  
  public static function serve():Void {
    
  }
}
