import haxe.Json;
import haxe.io.Bytes;
import neko.vm.Mutex;
import sk.thenet.FM;
import sk.thenet.app.*;
import sk.thenet.event.*;
import sk.thenet.net.ws.Websocket;
import sk.thenet.plat.Platform;
import common.*;

class Main {
  public static var mutex:Mutex;
  public static var players:Array<Player>;
  
  public static function main():Void {
    mutex = new Mutex();
    players = [];
    var ico = Geodesic.generateIcosahedron(4);
    GameState.init(ico);
    
    var ws = Platform.createWebsocket();
    ws.serve("localhost", "/", 7738, Player.spawn);
    while (true){
      if (GameState.untilTicker() <= 0){
        trace("tick");
        GameState.tick();
        mutex.acquire();
        for (p in players){
          p.tick();
        }
        mutex.release();
      }
      Sys.sleep(1);
    }
  }
}

class Player {
  public static function spawn(ch:Websocket):Void {
    var p = new Player(ch);
    Main.mutex.acquire();
    Main.players.push(p);
    Main.mutex.release();
  }
  
  private var ch:Websocket;
  private var logged:Bool = false;
  private var logId:Int;
  private var logName:String;
  private var logColour:Int;
  private var spawned:Bool = false;
  
  private function new(ch:Websocket){
    this.ch = ch;
    ch.listen("data", handleData);
  }
  
  private function sendOp(op:Int, data:String):Void {
    var b = Bytes.alloc(data.length + 1);
    b.set(0, op);
    b.blit(1, Bytes.ofString(data), 0, data.length);
    ch.send(b);
  }
  
  private function sendMaster():Void {
    sendOp(1, GameState.encodeMaster());
  }
  
  private function handleData(ev:EData):Bool {
    switch (ev.data.get(0)){
      case 0x01:
      Main.mutex.acquire();
      GameState.decodeTurn(ev.data.getString(1, ev.data.length - 1));
      Main.mutex.release();
      
      case 0x07:
      var obj = Json.parse(ev.data.getString(1, ev.data.length - 1));
      logged  = true;
      logId   = obj.i;
      logName = obj.n;
      logColour = obj.c;
      sendMaster();
    }
    return true;
  }
  
  public function tick():Void {
    //sendOp(2, GameState.encodeTicker());
    if (logged){
      if (!spawned){
        var t = GameState.spawnPlayer(logId, logName, logColour);
        sendOp(0x03, "{t:" + t + "}");
        spawned = true;
      }
      sendMaster();
    }
  }
}
