import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.anim.Timing;
import sk.thenet.app.Application;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.*;
import sk.thenet.bmp.manip.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import common.*;

class GUI {
  private static inline var ORDER_MAX:Int = 50;
  
  private static var guiDrawer:Vector<Bitmap>;
  private static var guiDrawerHandle:Vector<Int>;
  private static var guiCounter:Bitmap;
  private static var guiTimer:Vector<Bitmap>;
  private static var guiKarma:Bitmap;
  private static var guiDialogEvil:Vector<Bitmap>;
  private static var guiDialogGood:Vector<Bitmap>;
  private static var guiOrders:Vector<Bitmap>;
  private static var fontCounters:Font;
  private static var fontText:Font;
  private static var cameraRotations:Vector<Quaternion>;
  
  private static function renderBubble(
    am:AssetManager, c1:Colour, c2:Colour, width:Int, height:Int, ?arrow:Int = -1
  ):Vector<Bitmap> {
    if (arrow == -1){
      arrow = width >> 1;
    }
    arrow -= 7;
    arrow = FM.clampI(arrow, 2, width - 16);
    var ret = new Vector<Bitmap>(2);
    for (i in 0...2){
      ret[i] = Platform.createBitmap(width, height, 0);
      ret[i].setFillColour(c1);
      ret[i].fillRectStyled(1, 0, width - 2, 1);
      ret[i].fillRectStyled(0, 1, 1, height - 8);
      ret[i].fillRectStyled(width - 1, 1, 1, height - 8);
      ret[i].fillRect(1, 1, width - 2, height - 8, c2);
      ret[i].setFillColour(c1);
      ret[i].fillRectStyled(width - 2, 2, 1, height - 10);
      ret[i].fillRectStyled(2, height - 8, width - 3, 1);
      ret[i].fillRectStyled(1, height - 7, width - 2, 1);
      
      var arrBmp = Platform.createBitmap(14, 8, 0);
      arrBmp.blitAlpha(am.getBitmap("game").fluent
        >> (new Cut(0, 80 + i * 8, 14, 8))
        << (new Recolour(c1)), 0, 0);
      arrBmp.blitAlpha(am.getBitmap("game").fluent
        >> (new Cut(16, 80 + i * 8, 14, 8))
        << (new Recolour(c2)), 0, 0);
      
      ret[i].blitAlpha(arrBmp, arrow, height - 8);
    }
    return ret;
  }
  
  private static function renderOrder(
    am:AssetManager, text:String
  ):Bitmap {
    var game = am.getBitmap("game");
    var w = 64;
    var ret = Platform.createBitmap(w, 16, 0);
    ret.blitAlphaRect(game, 0, 0, 240, 32, 8, 16);
    ret.setFillPattern((game.fluent >> new Cut(244, 32, 8, 16)).bitmap.toFillPattern());
    ret.fillRectStyled(8, 0, w - 8, 16);
    ret.blitAlphaRect(game, w - 8, 0, 248, 32, 8, 16);
    fontText.render(ret, 1, 3, text);
    return ret;
  }
  
  public static function init(am:AssetManager, _):Bool {
    var game = am.getBitmap("game");
    
    {
      // camera rotations
      cameraRotations = Vector.fromArrayCopy([ for (i in 1...5)
          Quaternion.axisRotation(
               (i >= 2 && i <= 3 ? new Point3DF(-1, 1, 0) : new Point3DF(1, 1, 0)).unit()
              ,(i % 2 == 0 ? -.06 : .06)
            )
        ]);
    };
      
    {
      // font
      var fontRaw = am.getBitmap("console_font").fluent;
      fontRaw = Font.spreadGrid(
           fontRaw
          ,8, 16
          ,1, 1, 1, 1
        );
      fontCounters = Font.makeMonospaced(
           fontRaw >> (new Cut(0, 0, fontRaw.bitmap.width, fontRaw.bitmap.height))
            << (new Recolour(Palette.pal[7]))
            << (new Shadow(Palette.pal[5], 1, 0))
            << (new Glow(Palette.pal[3]))
          ,32, 160
          ,10, 18
          ,32
          ,-4, 0
        );
      fontText = Font.makeMonospaced(
           fontRaw >> (new Cut(0, 0, fontRaw.bitmap.width, fontRaw.bitmap.height))
            << (new Recolour(Palette.pal[6]))
            << (new Shadow(Palette.pal[5], 1, 0))
            << (new Glow(Palette.pal[10]))
          ,32, 160
          ,10, 18
          ,32
          ,-4, -5
        );
    };
    
    {
      // karma
      guiKarma = Platform.createBitmap(Main.WIDTH, 24, 0);
      guiKarma.blitAlphaRect(game, 0, 0, 32, 32, 24, 24);
      for (i in 0...44){
        guiKarma.blitAlphaRect(game, 24 + i * 8, 0, 80, 32, 8, 24);
      }
      guiKarma.blitAlphaRect(game, Main.WIDTH - 24, 0, 56, 32, 24, 24);
    };
    
    {
      // dialogs
      guiDialogEvil = renderBubble(am, Palette.pal[5], Palette.pal[7], Main.HWIDTH - 8, 32, 0);
      guiDialogGood = renderBubble(am, Palette.pal[5], Palette.pal[7], Main.HWIDTH - 8, 32, 1000);
    };
    
    {
      // drawer
      guiDrawer = new Vector(16);
      guiDrawerHandle = new Vector(16);
      var counterBg = (game.fluent >> (new Cut(152, 32, 8, 24))).bitmap.toFillPattern();
      for (i in 0...16){
        guiDrawer[i] = Platform.createBitmap(188, 24, 0);
        guiDrawer[i].blitAlphaRect(game, 0, 0, 128, 32, 24, 24);
        guiDrawer[i].setFillPattern(counterBg);
        var width:Int = Timing.cubicInOut.getI(i / 16, 180 - 32);
        guiDrawer[i].fillRectStyled(24, 0, width, 24);
        guiDrawer[i].blitAlphaRect(game, 24 + width, 0, 160 + (i < 8 ? 8 : 0), 32, 8, 24);
        guiDrawerHandle[i] = 24 + width;
      }
    };
    
    {
      // counter
      guiCounter = Platform.createBitmap(16, 48, 0);
      guiCounter.blitAlphaRect(game, 0, 0, 96, 32, 16, 24);
      guiCounter.blitAlphaRect(game, 0, 24, 96 + 16, 32, 16, 24);
    };
    
    {
      // timer
      var sun  = Platform.createBitmap(32, 24, 0);
      var moon = Platform.createBitmap(32, 24, 0);
      sun.blitAlphaRect(game, 0, 0, 176, 32, 32, 24);
      moon.blitAlphaRect(game, 0, 0, 176 + 32, 32, 32, 24);
    
      guiTimer = new Vector(16);
      for (i in 0...16){
        guiTimer[i] = Platform.createBitmap(32, 24, 0);
        if (i != 15){
          guiTimer[i].blitAlpha(sun, 0, 0);
        }
        if (i == 0){
          continue;
        } else if (i == 15){
          guiTimer[i].blitAlpha(moon, 0, 0);
          continue;
        }
        for (y in 2...22){
          guiTimer[i].blitAlphaRect(
               moon, 6, y, 6, y
              ,10 - FM.round(Math.cos((i / 16) * Math.PI) * Math.sin((y / 22) * Math.PI) * 10), 1
            );
        }
      }
    };
    
    {
      // orders
      guiOrders = new Vector(Unit.ORDERS.length);
      for (i in 0...guiOrders.length){
        guiOrders[i] = renderOrder(am, Unit.ORDERS[i].name);
      }
    };
    
    return false;
  }
  
  public var allowSelect(default, null):Bool;
  
  private var app:Application;
  private var ico:Geodesic;
  private var ren:GeodesicRender;
  private var action:GUIAction;
  private var lastAction:GUIAction;
  private var hoverAction:GUIAction;
  private var camera:Quaternion;
  private var cameraTransFrom:Quaternion;
  private var cameraTransTo:Quaternion;
  private var cameraTransProgress:Float;
  private var introTime:Int;
  private var drawerTarget:Int;
  private var drawerPhase:Int;
  private var cacheDrawer:Bitmap;
  private var cacheTooltip:Bitmap;
  private var tooltipLast:Int;
  private var tooltipTime:Int;
  private var tilesSelected:Array<Int> = [];
  private var ph:Int = 0;
  private var ordersTarget:Int;
  private var ordersPhase:Int;
  private var ordersList:Array<Int>;
  
  public function new(app:Application, ico:Geodesic, ren:GeodesicRender){
    allowSelect = true;
    this.app = app;
    this.ico = ico;
    this.ren = ren;
    
    action = None;
    lastAction = None;
    camera = Quaternion.identity;
    
    introTime = 0; // 120;
    drawerTarget = drawerPhase = 15;
    ordersTarget = ordersPhase = 0;
    ordersList = [];
    setStatus();
    
    tooltipLast = -1;
    tooltipTime = 0;
  }
  
  private function cameraTrans(q:Quaternion):Void {
    cameraTransFrom = camera;
    cameraTransTo = q;
    cameraTransProgress = 0.0;
  }
  
  public function render(bmp:Bitmap):Void {
    var tooltips:Array<Tooltip> = [];
    
    hoverAction = None;
    
    {
      // camera transitions
      if (cameraTransTo == null){
        var movecursors = [
             new Point2DI(Main.HWIDTH - 140, Main.HHEIGHT + 70)
            ,new Point2DI(Main.HWIDTH + 140, Main.HHEIGHT + 70)
            ,new Point2DI(Main.HWIDTH - 140, Main.HHEIGHT - 30)
            ,new Point2DI(Main.HWIDTH + 140, Main.HHEIGHT - 30)
          ];
        for (ri in 0...movecursors.length){
          var i = movecursors.length - ri - 1;
          var dist = (new Point2DI(Platform.mouse.x, Platform.mouse.y)).subtract(movecursors[i]).abs().componentSum();
          if (dist < 70){
            hoverAction = Rotation(i);
          }
        }
      } else {
        if (cameraTransProgress >= 1){
          camera = cameraTransTo;
          cameraTransFrom = null;
          cameraTransTo = null;
        } else {
          camera = cameraTransFrom.interpolate(
              cameraTransTo, Timing.quadInOut(cameraTransProgress)
            );
        }
        ren.rotate(camera);
        cameraTransProgress += .02;
      }
    };
    
    {
      // karma
      var y:Int = Main.HEIGHT - 24 + 74 - Timing.quadOut.getI(1 - introTime / 60, 74);
      bmp.blitAlpha(guiKarma, 0, y);
      tooltips.push({
           x: 0
          ,y: y
          ,w: Main.WIDTH
          ,h: 24
          ,text: "Your karma is: neutral\nTo improve your karma ..."
        });
    };
    
    {
      // timer
      var y:Int = 0 - 24 + Timing.quadOut.getI(1 - introTime / 60, 24);
      bmp.blitAlpha(guiTimer[ph >> 3], Main.HWIDTH - 16, y);
      tooltips.push({
           x: Main.HWIDTH - 16
          ,y: y
          ,w: 32
          ,h: 24
          ,text: "Time until next turn: 0:12"
        });
    };
    
    {
      // counters
      var x:Int = -100 + Timing.quadOut.getI(1 - introTime / 60, 100);
      bmp.blitAlpha(guiCounter, x, 24);
      fontCounters.render(bmp, x + 13, 24 + 6, "1234");
      fontCounters.render(bmp, x + 13, 48 + 6, "567/890");
      tooltips.push({
           x: x
          ,y: 24
          ,w: 32
          ,h: 24
          ,text: "Starlight: 200\nStarlight is ..."
        });
      tooltips.push({
           x: x
          ,y: 48
          ,w: 32
          ,h: 24
          ,text: "Energy: 5 / 10\nEnergy is ..."
        });
    };
    
    {
      // orders
      var x:Int = -64 + Timing.quadOut.getI(ordersPhase / ORDER_MAX, 64);
      for (i in 0...ordersList.length){
        var order = ordersList[i];
        var tt = {
             x: x
            ,y: Main.HEIGHT - 24 - 24 - i * 20
            ,w: 64
            ,h: 16
            ,text: Unit.ORDERS[order].tooltip
          };
        tooltips.push(tt);
        var ox:Int = 0;
        if (FM.withinI(Platform.mouse.x, x, x + 64)
            && FM.withinI(Platform.mouse.y, tt.y, tt.y + 16)){
          ox = -2;
          hoverAction = Order(order);
        }
        bmp.blitAlpha(guiOrders[order], x + ox, Main.HEIGHT - 24 - 24 - i * 20);
      }
    };
    ordersPhase += FM.signI(ordersTarget - ordersPhase);
    
    {
      // drawer
      var p:Int = drawerPhase;
      var y:Int = 0 - 74 + Timing.quadOut.getI(1 - introTime / 60, 74);
      bmp.blitAlpha(guiDrawer[p], 0, y);
      bmp.blitAlphaRect(cacheDrawer, 0, 0, 0, 0, guiDrawerHandle[p], 24);
      if (   Platform.mouse.y < y + 24
          && Platform.mouse.x >= guiDrawerHandle[p]
          && Platform.mouse.x < guiDrawerHandle[p] + 8){
        hoverAction = ToggleDrawer;
      }
    };
    drawerPhase += FM.signI(drawerTarget - drawerPhase);
    
    allowSelect = (hoverAction == None);
    
    action = None;
    if (Platform.mouse.held){
      action = hoverAction;
    }
    
    switch (action){
      case Rotation(r):
      camera = cameraRotations[r].multiply(camera).unit;
      ren.rotate(camera);
      case _:
    }
    
    // tooltips
    {
      var tooltipNow = -1;
      for (ti in 0...tooltips.length){
        var tooltip = tooltips[ti];
        if (FM.withinI(Platform.mouse.x, tooltip.x, tooltip.x + tooltip.w)
            && FM.withinI(Platform.mouse.y, tooltip.y, tooltip.y + tooltip.h)){
          tooltipNow = ti;
          break;
        }
      }
      if (tooltipNow == tooltipLast){
        if (tooltipNow != -1){
          tooltipTime++;
        } else {
          tooltipTime = 0;
        }
      } else {
        tooltipTime = 0;
      }
      tooltipLast = tooltipNow;
      if (tooltipTime == 70){
        cacheTooltip = renderTooltip(tooltips[tooltipNow].text);
      }
      if (tooltipTime >= 70){
        var ttx = FM.clampI(Platform.mouse.x + 4, 0, Main.WIDTH - cacheTooltip.width);
        var tty = FM.clampI(Platform.mouse.y + 4, 0, Main.HEIGHT - cacheTooltip.height);
        bmp.blitAlpha(cacheTooltip, ttx, tty);
      }
    };
    
    if (introTime > 0){
      introTime--;
    }
    
    /*
    bmp.blitAlpha(guiDialogEvil[ph >> 6], 4, Main.HEIGHT - 24 - 32);
    bmp.blitAlpha(guiDialogGood[ph >> 6], Main.HWIDTH + 4, Main.HEIGHT - 24 - 32);
    */
    
    var cursor:Int = (switch (hoverAction){
        case Rotation(r): 1 + r;
        case _: 0;
      });
    bmp.blitAlphaRect(
         app.assetManager.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y, 32 + (cursor * 8), 24, 8, 8
      );
    
    ph++;
    ph %= 128;
  }
  
  public function setStatus(
    ?unit:Unit, ?stats:Stats, ?unitFac:Int, ?faction:Int
  ):Void {
    cacheDrawer = Platform.createBitmap(256, 24, 0);
    if (unit == null){
      return;
    }
    cacheDrawer.fillRect(3, 3, 17, 17, Palette.factions[(unitFac == faction ? 0 : 8) + faction]);
    cacheDrawer.blitAlpha(Sprites.units[unitFac][unit.sprite].get(0, 0), -12, -12);
    fontText.render(cacheDrawer, 24, 2, unit.name);
    if (stats == null){
      stats = unit.stats;
    }
    var statsIdx = [stats.hp, stats.mp, stats.atk, stats.def];
    var maxStats = [stats.maxHp, stats.maxMp, stats.atk, stats.def];
    var cx = 24 + 2;
    for (i in 0...4){
      cacheDrawer.blitAlphaRect(app.assetManager.getBitmap("game"), cx, 12, 88 + i * 16, 21, 10, 11);
      cx += 11;
      for (j in 0...statsIdx[i]){
        cacheDrawer.blitAlphaRect(app.assetManager.getBitmap("game"), cx, 12, 160 + (i > 1 ? 8 : 0) + (j == 0 ? 0 : 1), 21, 5, 11);
        cx += 4 - (j == 0 ? 0 : 1);
      }
      for (j in statsIdx[i]...maxStats[i]){
        cacheDrawer.blitAlphaRect(app.assetManager.getBitmap("game"), cx, 12, 152 + (j == 0 ? 0 : 1), 21, 5, 11);
        cx += 4 - (j == 0 ? 0 : 1);
      }
      cx += 4;
    }
  }
  
  public function renderTooltip(text:String):Bitmap {
    var buffer = Platform.createBitmap(400, 200, 0);
    var max = fontText.render(buffer, 0, 2, text);
    var res = Platform.createBitmap(max.x, max.y - 1, Palette.pal[7]);
    res.setFillColour(Palette.pal[4]);
    res.fillRectStyled(0, 0, res.width, 1);
    res.fillRectStyled(0, 0, 1, res.height);
    res.fillRectStyled(0, res.height - 1, res.width, 1);
    res.fillRectStyled(res.width - 1, 0, 1, res.height);
    res.blitAlphaRect(buffer, 0, 0, 0, 0, max.x, max.y);
    return res;
  }
  
  public function click():Bool {
    return (switch (hoverAction){
        case ToggleDrawer: drawerTarget = 15 - drawerTarget; true;
        case Order(o):
        if (o == 0){
          deselectTile();
          ordersTarget = 0;
        }
        true;
        case _: (tooltipTime != 0);
      });
  }
  
  public function deselectTile():Void {
    for (t in tilesSelected){
      ico.tiles[t].selected = false;
    }
    setStatus();
  }
  
  public function clickTile(t:Int):Void {
    if (t == -1){
      return;
    }
    deselectTile();
    cameraTrans(ren.lookAt(t).multiply(camera).unit);
    ico.tiles[t].selected = true;
    var unit    = GameState.unit[t];
    var unitFac = GameState.unitFac[t];
    var faction = GameState.faction[t];
    if (unit != -1){
      setStatus(Unit.UNITS[unit], null, unitFac, faction);
    }
    if (   faction == GameState.currentFaction
        || unitFac == GameState.currentFaction){
      ordersTarget = ORDER_MAX;
      ordersList = [];
      if (unit != -1 && unitFac == GameState.currentFaction){
        ordersList = Unit.UNITS[unit].orders;
        if (faction != GameState.currentFaction){
          ordersList = ordersList.concat(Unit.AWAY_LAND_ORDERS);
        }
      }
      if (faction == GameState.currentFaction){
        ordersList = ordersList.concat(Unit.HOME_LAND_ORDERS);
      }
    } else {
      ordersTarget = 0;
    }
    tilesSelected = [t];
  }
}

private enum GUIAction {
  None;
  ToggleDrawer;
  Rotation(r:Int);
  Order(o:Int);
}

typedef Tooltip = {
     x:Int
    ,y:Int
    ,w:Int
    ,h:Int
    ,text:String
  };
