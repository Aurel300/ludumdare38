package common;

import haxe.Json;
import haxe.ds.Vector;
import sk.thenet.FM;

class GameState {
  public static inline var SINGLE:Bool = true;
  public static inline var TILES:Int = 320;
  
  // clients
  public static var currentNick   (default, default):String;
  public static var currentColour (default, null):Int;
  public static var currentFaction(default, null):Int;
  public static var currentMoves  (default, null):Array<Move>;
  public static var currentClicks (default, null):Vector<Move>;
  public static var currentSL     (default, default):Int;
  public static var currentNRG    (default, default):Int;
  public static var currentIncome (default, default):Int;
  public static var currentIngest (default, default):Int;
  public static var maxNRG        (default, default):Int;
  public static var turned        (default, null):Vector<MoveStatus>;
  
  // server
  public static var fid    (default, null):Array<Int>;
  public static var name   (default, null):Array<String>;
  public static var colour (default, null):Array<Int>;
  public static var sl     (default, null):Array<Int>;
  public static var nrg    (default, null):Array<Int>;
  public static var maxnrg (default, null):Array<Int>;
  public static var income (default, null):Array<Int>;
  public static var ingest (default, null):Array<Int>;
  
  public static var height (default, null):Vector<Float>;
  public static var faction(default, null):Vector<Int>;
  public static var unit   (default, null):Vector<Int>;
  public static var unitFac(default, null):Vector<Int>;
  public static var stats  (default, null):Vector<Stats>;
  public static var star   (default, null):Vector<Int>;
  public static var shield (default, null):Vector<Unit>;
  public static var ticker (default, null):Date;
  public static var period (default, null):Float;
  
  private static var ico:Geodesic;
  private static var latestCurrentMoves:Map<Int, Array<Move>>;
  
  public static var leaders:Array<String> = [];
  
  public static function selectNative(native:Int):Void {
    currentColour = native;
  }
  
  public static function selectFaction(faction:Int):Void {
    currentFaction = faction;
  }
  
  public static function getLeaders():Array<String> {
    var scores:Array<{name:String, score:Int}> = [];
    for (i in 0...fid.length){
      scores.push({name: name[i], score: sl[i] + maxnrg[i]});
    }
    trace(name);
    scores.sort(function(a, b):Int {
        return b.score - a.score;
      });
    return [ for (i in 0...FM.minI(10, scores.length)) Std.string(i + 1) + ". " + scores[i].name + " (" + scores[i].score + ")" ];
  }
  
  public static function colourOf(faction:Int):Int {
    if (faction == -1){
      return -1;
    }
    for (fi in 0...fid.length){
      if (fid[fi] == faction){
        return colour[fi];
      }
    }
    return -1;
  }
  
  public static function initEmpty(ico:Geodesic):Void {
    GameState.ico = ico;
    currentFaction = 0;
    currentMoves   = [];
    currentClicks  = new Vector(TILES);
    currentSL      = 5;
    currentNRG     = 11;
    currentIncome  = 0;
    currentIngest  = 0;
    maxNRG         = 15;
    turned         = new Vector(TILES);
    for (i in 0...TILES){
      currentClicks[i] = null;
      turned[i]        = MoveStatus.None;
    }
    fid     = [];
    name    = [];
    colour  = [];
    sl      = [];
    nrg     = [];
    maxnrg  = [];
    income  = [];
    ingest  = [];
  }
  
  public static function init(ico:Geodesic):Void {
    initEmpty(ico);
    
    latestCurrentMoves = new Map();
    
    height  = new Vector(TILES);
    faction = new Vector(TILES);
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
      star[i]    = (FM.prng.nextMod(100) > 95 ? FM.prng.nextMod(50) + 1 : -1);
      shield[i]  = null;
    }
  }
  
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
    /*
    for (f in latestTurned.keys()){
      var ft = latestTurned.get(f);
      for (ti in 0...ft.length){
        if (unitFac[ti] == f || ft[ti] == MoveStatus.Building){
          turned[ti] = ft[ti];
        }
      }
    }
    latestTurned = new Map();
    */
    turn();
  }
  
  public static function encodeTicker():String {
    return Json.stringify({t: ticker.getTime()});
  }
  
  public static function encodeMaster():String {
    return Json.stringify({
         h: height.toArray()
        ,f: faction.toArray()
        ,u: unit.toArray()
        ,uf: unitFac.toArray()
        ,s: stats.toArray()
        ,sr: star.toArray()
        //,sh:
        ,t: ticker.getTime()
        ,p: period
        ,ff: fid
        ,fn: name
        ,fc: colour
        ,fs: sl
        ,fg: nrg
        ,fm: maxnrg
        ,fin: income
        ,fig: ingest
      });
  }
  
  public static function encodeTurn():String {
    return Json.stringify({
         f: currentFaction
        ,m: currentMoves.map(function(m:Move):Array<Int> {
            return [m.from, m.to, m.type];
          })
        //,t: turned.toArray()
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
    unit    = Vector.fromArrayCopy(obj.u);
    unitFac = Vector.fromArrayCopy(obj.uf);
    stats   = Vector.fromArrayCopy(obj.s);
    star    = Vector.fromArrayCopy(obj.sr);
    //shield  = Vector.fromArrayCopy(obj.sh);
    ticker  = Date.fromTime(obj.t);
    period  = obj.p;
    
    fid     = obj.ff;
    name    = obj.fn;
    colour  = obj.fc;
    sl      = obj.fs;
    nrg     = obj.fg;
    maxnrg  = obj.fm;
    income  = obj.fin;
    ingest  = obj.fig;
    
    for (i in 0...fid.length){
      if (currentFaction == fid[i]){
        currentSL = sl[i];
        currentNRG = nrg[i];
        maxNRG = maxnrg[i];
        currentIncome = income[i];
        currentIngest = ingest[i];
        break;
      }
    }
    
    for (i in 0...TILES){
      turned[i] = MoveStatus.None;
      if (unit[i] != -1){
        turned[i] = MoveStatus.Ready;
      }
    }
    
    currentMoves = [];
    leaders = getLeaders();
  }
  
  public static function decodeTurn(s:String):Void {
    var obj = Json.parse(s);
    latestCurrentMoves.set(obj.f, currentMoves.concat(obj.m.map(function(a:Array<Int>):Move {
        return new Move(a[0], a[1], a[2]);
      })));
    //latestTurned.set(obj.f, obj.t);
  }
  
  public static function spawnPlayer(id:Int, pn:String, c:Int):Int {
    var t:Int = FM.prng.nextMod(TILES);
    
    fid.push   (id);
    name.push  (pn);
    colour.push(c);
    sl.push    (5);
    nrg.push   (11);
    maxnrg.push(15);
    income.push(0);
    ingest.push(0);
    
    faction[t] = id;
    unit   [t] = 0;
    unitFac[t] = id;
    turned [t] = MoveStatus.Ready;
    stats  [t] = Unit.UNITS[0].cloneStats();
    var i:Int = 1;
    for (a in ico.tiles[t].adjacent){
      faction[a.index] = id;
      unit   [a.index] = i;
      unitFac[a.index] = id;
      turned [a.index] = MoveStatus.Ready;
      stats  [a.index] = Unit.UNITS[unit[a.index]].cloneStats();
      i++;
    }
    
    return t;
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
  
  public static function buildUnit(f:Int, t:Int):Void {
    unit   [f] = t;
    unitFac[f] = faction[f];
    stats  [f] = Unit.UNITS[t].cloneStats();
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
    for (i in 0...fid.length){
      income[i] = 0;
      ingest[i] = 0;
    }
    
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
        for (t in ico.tiles[at.to].range){
          tilesAttacked.push(t.index);
          killUnit(t.index);
        }
      } else if (dmg >= stats[at.to].hp){
        killUnit(at.to);
      } else {
        stats[at.to].hp -= dmg;
        if (Unit.UNITS[attacker].stats.ran <= Unit.UNITS[defender].stats.ran){
          counter = DAMAGE_TABLE[defender + attacker * 10];
        }
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
      for (f in 0...fid.length){
        if (fid[f] == faction[cp.from]){
          sl[f] -= 1;
          break;
        }
      }
    }
    var builds = currentMoves.filter(function(m) return m.type == Build);
    while (builds.length > 0){
      var bd = builds.splice(FM.prng.nextMod(builds.length), 1)[0];
      buildUnit(bd.from, bd.to);
      for (f in 0...fid.length){
        if (fid[f] == faction[bd.from]){
          sl[f] -= Unit.UNITS[bd.to].costSL;
          break;
        }
      }
    }
    currentMoves = [];
    
    for (f in 0...fid.length){
      maxnrg[f] = 0;
      nrg[f] = 0;
    }

    for (i in 0...TILES){
      star[i] = (FM.prng.nextMod(100) > 95 ? FM.prng.nextMod(30) + 20 : -1);
      
      currentClicks[i] = null;
      turned[i] = MoveStatus.None;
      
      if (faction[i] != -1){
        var facid = -1;
        for (f in 0...fid.length){
          if (faction[i] == fid[f]){
            facid = f;
            break;
          }
        }
        if (star[i] != -1){
          sl[facid]++;
          income[facid]++;
        }
        nrg[facid]--;
      }
      if (unit[i] != -1){
        turned[i] = MoveStatus.Ready;
        var facid = -1;
        for (f in 0...fid.length){
          if (unitFac[i] == fid[f]){
            facid = f;
            break;
          }
        }
        switch (unit[i]){
          case 0:
          maxnrg[facid] += 15;
          nrg[facid] += 15;
          case 1:
          if (star[i] != -1){
            sl[facid] += 2;
            ingest[facid] += 2;
          }
          nrg[facid] -= Unit.UNITS[unit[i]].costUNRG;
          case _:
          nrg[facid] -= Unit.UNITS[unit[i]].costUNRG;
        }
      }
    }
    
    if (SINGLE){
      currentSL = sl[0];
      currentNRG = nrg[0];
      maxNRG = maxnrg[0];
    }
  }
}
