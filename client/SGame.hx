import haxe.Json;
import haxe.io.Bytes;
import sk.thenet.FM;
import sk.thenet.anim.Timing;
import sk.thenet.app.*;
import sk.thenet.event.*;
import sk.thenet.geom.*;
import sk.thenet.net.ws.Websocket;
import sk.thenet.plat.Platform;
import common.*;

class SGame extends State {
  private var ico:Geodesic;
  private var ren:GeodesicRender;
  private var zoomIntro:Float;
  private var gui:GUI;
  private var ws:Websocket;
  private var wsStatus:ServerStatus = None;
  
  public function new(app:Application){
    super("game", app);
  }
  
  private function sendOp(op:Int, data:String):Void {
    var b = Bytes.alloc(data.length + 1);
    b.set(0, op);
    b.blit(1, Bytes.ofString(data), 0, data.length);
    ws.send(b);
  }
  
  override public function to():Void {
    ico = Geodesic.generateIcosahedron(4);
    GameState.initEmpty(ico);
    ws = Platform.createWebsocket();
    ws.listen("data", handleData);
    ws.connect("localhost", "/", 7738);
    var fid = FM.round(Date.now().getTime() * 1327) ^ 0x7FFFFFFF;
    GameState.selectFaction(fid);
    sendOp(0x7, Json.stringify({
         i: fid
        ,n: "foo"
        ,p: "bar"
        ,c: GameState.currentColour
      }));
    GameState.encodeTurnSend = function(){
      sendOp(0x01, GameState.encodeTurn());
    };
  }
  
  private function handleData(ev:EData):Bool {
    //trace("got data: " + ev.data);
    switch (ev.data.get(0)){
      case 0x01:
      GameState.decodeMaster(ev.data.getString(1, ev.data.length - 1));
      if (wsStatus != MasterRecv){
        ren = new GeodesicRender(ico);
        zoomIntro = 0;
        gui = new GUI(app, ico, ren, ws);
        wsStatus = MasterRecv;
      } else {
        ren.rotate(gui.camera);
      }
      
      case 0x02:
      GameState.decodeTicker(ev.data.getString(1, ev.data.length - 1));
      
      case 0x03:
      
      
      case _:
      trace("unknown packet");
    }
    return true;
  }
  
  override public function tick():Void { 
    app.bitmap.fill(Palette.pal[3]);
    
    if (wsStatus != MasterRecv){
      GUI.fontText.render(
           app.bitmap, 10, 10
          ,ws.connected ? "Downloading data ..." : "Connecting ..."
        );
      return;
    }
    
    if (zoomIntro < 1){
      ren.scale(Timing.quadInOut(zoomIntro) * 190);
      zoomIntro += .01;
    }
    
    ren.render(app.bitmap, gui.allowSelect);
    gui.render(app.bitmap);
  }
  
  override public function mouseClick(_, _):Void {
    if (!gui.click()){
      gui.clickTile(ren.click());
    }
  }
}

enum ServerStatus {
  None;
  Connected;
  MasterRecv;
}
