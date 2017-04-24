import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.anim.Timing;
import sk.thenet.app.Application;
import sk.thenet.app.AssetManager;
import sk.thenet.bmp.*;
import sk.thenet.bmp.manip.*;
import sk.thenet.geom.*;
import sk.thenet.net.ws.Websocket;
import sk.thenet.plat.Platform;
import common.*;

class GUI {
  private static inline var ORDER_MAX:Int = 50;
  private static inline var DRAWER_MAX:Int = 15;
  private static inline var BUILD_MAX:Int = 60;
  private static inline var NEXT_MAX:Int = 50;
  
  private static var guiDrawer:Vector<Bitmap>;
  private static var guiDrawerHandle:Vector<Int>;
  private static var guiCounter:Bitmap;
  private static var guiTimer:Vector<Bitmap>;
  private static var guiKarma:Bitmap;
  private static var guiDialogEvil:Vector<Bitmap>;
  private static var guiDialogGood:Vector<Bitmap>;
  private static var guiOrders:Vector<Bitmap>;
  private static var guiBuild:Vector<Bitmap>;
  private static var guiBuildAreas:Vector<Tooltip>;
  private static var guiNext:Bitmap;
  
  public static var fontCounters:Font;
  public static var fontText:Font;
  public static var fontRed:Font;
  private static var fontSymbol:Font;
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
  
  private static function renderButton(
    am:AssetManager, text:String, ?type:Int = 0
  ):Bitmap {
    var game = am.getBitmap("game");
    var w = 64;
    var ret = Platform.createBitmap(w, 16, 0);
    ret.blitAlphaRect(game, 0, 0, 240, 32 + type * 16, 8, 16);
    ret.setFillPattern((game.fluent >> new Cut(244, 32 + type * 16, 8, 16)).bitmap.toFillPattern());
    ret.fillRectStyled(8, 0, w - 8, 16);
    ret.blitAlphaRect(game, w - 8, 0, 248, 32 + type * 16, 8, 16);
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
      fontRed = Font.makeMonospaced(
           fontRaw >> (new Cut(0, 0, fontRaw.bitmap.width, fontRaw.bitmap.height))
            << (new Recolour(Palette.pal[18]))
            << (new Shadow(Palette.pal[5], 1, 0))
            << (new Glow(Palette.pal[10]))
          ,32, 160
          ,10, 18
          ,32
          ,-4, -5
        );
      fontSymbol = Font.makeMonospaced(
           am.getBitmap("game").fluent
            >> (new Cut(0, 0, 192, 32))
          ,32, 48
          ,8, 16
          ,24
          ,0, 0
        );
      fontSymbol.rects[36 * 6 + 4] -= 5;
      fontSymbol.rects[38 * 6 + 4] -= 5;
      fontSymbol.rects[40 * 6 + 4] -= 5;
      fontSymbol.rects[42 * 6 + 4] -= 5;
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
        guiOrders[i] = renderButton(am, Unit.ORDERS[i].name);
      }
    };
    
    {
      // build
      guiBuild = new Vector(1 + 1 + 8);
      guiBuildAreas = new Vector(guiBuild.length);
      guiBuild[0] = renderButton(am, "Cancel");
      var bg = Platform.createBitmap(Main.HWIDTH, Main.HHEIGHT - 24, 0);
      bg.blitAlphaRect(game, 0, 0, 192, 56, 8, 8);
      bg.blitAlphaRect(game, bg.width - 8, 0, 192 + 16, 56, 8, 8);
      bg.blitAlphaRect(game, 0, bg.height - 8, 192, 56 + 16, 8, 8);
      bg.blitAlphaRect(game, bg.width - 8, bg.height - 8, 192 + 16, 56 + 16, 8, 8);
      bg.setFillPattern((game.fluent >> (new Cut(192, 56 + 8, 8, 8))).bitmap.toFillPattern());
      bg.fillRectStyled(0, 8, 8, bg.height - 16);
      bg.setFillPattern((game.fluent >> (new Cut(192 + 16, 56 + 8, 8, 8))).bitmap.toFillPattern());
      bg.fillRectStyled(bg.width - 8, 8, 8, bg.height - 16);
      bg.setFillPattern((game.fluent >> (new Cut(192 + 8, 56, 8, 8))).bitmap.toFillPattern());
      bg.fillRectStyled(8, 0, bg.width - 16, 8);
      bg.setFillPattern((game.fluent >> (new Cut(192 + 8, 56 + 16, 8, 8))).bitmap.toFillPattern());
      bg.fillRectStyled(8, bg.height - 8, bg.width - 16, 8);
      bg.fillRect(8, 8, bg.width - 16, bg.height - 16, Palette.pal[7]);
      var texts:Array<String> = [
           ""
          ,"Build units\n(mouse over the units above for\ndetails, click to purchase)"
          ,"Tower Block ($C2SL 4NRG$A)\nContribute to the greatest\nproject on this planet!\n$DCDNEF$C_$DGH$C_$DIJ$C_$D"
          ,"Generator ($C10SL 0NRG$A)\nGenerates $C15NRG$A when not\nmoving.\n$DCDNNNNNNNNNNEFNGH$C_$DIJOO"
          ,"Starlight Catcher ($C15SL 1+1NRG$A)\nCaught $CSL$A is worth\nthree times as much.\n$DCDNNEFNGHOIJO"
          ,"Boot ($C2SL 1NRG$A)\nBasic footman for melee attacks.\n$DCDNNNNNEFNNGHOOOIJO"
          ,"Bow and Arrow ($C3SL 1NRG$A)\nRanged, mobile attacker.\n$DCDNNNNEFNNGHOOIJ$C_$D"
          ,"Trebuchet ($C5SL 2NRG$A)\nArtillery for taking\ndown shields.\n$DCDNEFNGHOOIJO"
          ,"Stick of Dynamite ($C7SL 5+5NRG$A)\nCannot attack. Deals damage\nto surroundings when attacked.\n$DCDNEFNNGHOOOOOOOOOOIJ$C_$D"
          ,"Cloak and Dagger ($C10SL 5NRG$A)\nStealthy, nimble backstabber.\nBecomes temporarily invisible\nwhen not moving in owned tiles.\n$DCDNEFNNNGHOOOOOIJ$C_$D"
        ];
      guiBuildAreas[1] = {
           x: (Main.HWIDTH >> 1)
          ,y: (Main.HHEIGHT >> 1)
          ,w: Main.HWIDTH
          ,h: Main.HHEIGHT
          ,text: ""
        };
      for (i in 1...10){
        if (i > 1){
          guiBuildAreas[i] = {
               x: (Main.HWIDTH >> 1) + (i == 2 ? 0 : 32 + (i - 3) * 24)
              ,y: (Main.HHEIGHT >> 1)
              ,w: (i == 2 ? 32 : 24)
              ,h: 32
              ,text: ""
            };
        }
        guiBuild[i] = Platform.createBitmap(Main.HWIDTH, Main.HHEIGHT, 0);
        guiBuild[i].blitAlpha(bg, 0, 24);
        for (j in 0...8){
          if (j == 0){
            guiBuild[i].blitAlphaRect(game, 0, (i - 2 == j ? 0 : 2), 0, 96, 32, 32);
          } else {
            guiBuild[i].blitAlphaRect(game, 32 + 24 * (j - 1), (i - 2 == j ? 8 : 10), 48 + 24 * (j - 1), 80, 24, 24);
          }
        }
        fontText.render(guiBuild[i], 4, 36, texts[i], 4, 36, [fontText, fontRed, fontCounters, fontSymbol]);
      }
    };
    
    {
      // next
      guiNext = renderButton(am, "Next unit", 1);
    };
    
    return false;
  }
  
  public var allowSelect(default, null):Bool;
  
  private var app:Application;
  private var ico:Geodesic;
  private var ren:GeodesicRender;
  private var ws:Websocket;
  private var action:GUIAction;
  private var lastAction:GUIAction;
  private var hoverAction:GUIAction;
  public  var camera:Quaternion;
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
  private var ph:Int = 0;
  private var ordersTarget:Int;
  private var ordersPhase:Int;
  private var ordersList:Array<Int>;
  private var tileSelected:Int;
  private var buildTarget:Int;
  private var buildPhase:Int;
  private var nextTarget:Int;
  private var nextPhase:Int;
  private var nextTile:Int;
  
  public function new(
    app:Application, ico:Geodesic, ren:GeodesicRender, ws:Websocket
  ){
    allowSelect = true;
    this.app = app;
    this.ico = ico;
    this.ren = ren;
    this.ws  = ws;
    
    action = None;
    lastAction = None;
    camera = Quaternion.identity;
    
    introTime = 120; // 120;
    drawerTarget = drawerPhase = 0;
    ordersTarget = ordersPhase = 0;
    buildTarget = buildPhase = 0;
    nextTarget = nextPhase = 0;
    ordersList = [];
    setStatus();
    
    tooltipLast = -1;
    tooltipTime = 0;
    
    tileSelected = -1;
    nextTile = -1;
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
      var until = GameState.untilTicker();
      var timeSec = until % 60;
      var timeStr:String = FM.floor(until / 60) + ":" + (timeSec < 10 ? "0" : "") + timeSec;
      var ph:Int = FM.floor(16 - ((until * 1000) / GameState.period) * 16);
      ph = FM.clampI(ph, 0, 15);
      bmp.blitAlpha(guiTimer[ph], Main.HWIDTH - 16, y);
      var tt = {
           x: Main.HWIDTH - 16
          ,y: y
          ,w: 32
          ,h: 24
          ,text: "Time until next turn: " + timeStr
        };
      tooltips.push(tt);
      if (tooltipHover(tt)){
        hoverAction = NextTurn;
      }
    };
    
    {
      // counters
      var x:Int = -100 + Timing.quadOut.getI(1 - introTime / 60, 100);
      bmp.blitAlpha(guiCounter, x, 24);
      fontCounters.render(bmp, x + 13, 24 + 6, "" + GameState.currentSL);
      fontCounters.render(bmp, x + 13, 48 + 6, GameState.currentNRG + "/" + GameState.maxNRG);
      tooltips.push({
           x: x
          ,y: 24
          ,w: 32
          ,h: 24
          ,text: "Starlight: " + GameState.currentSL + "\nStarlight is the main resource.\nIt falls from the sky, having more\nland makes it more likely\nthat you will get it."
        });
      tooltips.push({
           x: x
          ,y: 48
          ,w: 32
          ,h: 24
          ,text: "Energy: " + GameState.currentNRG + "/" + GameState.maxNRG + "\nEnergy is generated by Generators.\nIt is needed to maintain your\nland and some of your units."
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
        if (tooltipHover(tt) && ordersPhase == ORDER_MAX){
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
    
    {
      // next
      var x:Int = Main.WIDTH - Timing.quadOut.getI(nextPhase / NEXT_MAX, 64);
      var tt = {
           x: x
          ,y: Main.HEIGHT - 24 - 24
          ,w: 64
          ,h: 16
          ,text: "Select the next readied unit."
        };
      tooltips.push(tt);
      var ox:Int = 0;
      if (tooltipHover(tt) && nextPhase == NEXT_MAX){
        ox = 2;
        hoverAction = Next;
      }
      bmp.blitAlpha(guiNext, x + ox, Main.HEIGHT - 24 - 24);
    };
    nextPhase += FM.signI(nextTarget - nextPhase);
    
    if (buildPhase != 0){
      hoverAction = None;
    }
    
    {
      // build
      var y:Int = (Main.HHEIGHT >> 1) + (Main.HEIGHT << 1) - Timing.quadOut.getI(buildPhase / BUILD_MAX, (Main.HEIGHT << 1));
      var disp:Int = 1;
      if (buildPhase == BUILD_MAX){
        if (!tooltipHover(guiBuildAreas[1])){
          hoverAction = BuildExit;
        } else {
          for (i in 2...10){
            if (tooltipHover(guiBuildAreas[i])){
              disp = i;
              hoverAction = Build(i - 2);
              break;
            }
          }
        }
      }
      bmp.blitAlpha(guiBuild[disp], Main.WIDTH >> 2, y);
    };
    buildPhase += FM.signI(buildTarget - buildPhase);
    
    allowSelect = (buildPhase == 0 && hoverAction == None);
    
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
        if (tooltipHover(tooltips[ti])){
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
        case BuildExit: 5;
        case _: 0;
      });
    bmp.blitAlphaRect(
         app.assetManager.getBitmap("game")
        ,Platform.mouse.x, Platform.mouse.y, 32 + (cursor * 8), 24, 8, 8
      );
    
    ph++;
    ph %= 128;
  }
  
  private function tooltipHover(tt:Tooltip):Bool {
    return FM.withinI(Platform.mouse.x, tt.x, tt.x + tt.w)
        && FM.withinI(Platform.mouse.y, tt.y, tt.y + tt.h);
  }
  
  public function setStatus(
    ?unit:Unit, ?stats:Stats, ?unitFac:Int, ?faction:Int
  ):Void {
    cacheDrawer = Platform.createBitmap(256, 24, 0);
    if (unit == null){
      drawerTarget = 0;
      return;
    }
    drawerTarget = DRAWER_MAX;
    if (faction != -1){
      cacheDrawer.fillRect(3, 3, 17, 17, Palette.factions[(unitFac == faction ? 0 : 8) + GameState.colourOf(faction)]);
    }
    cacheDrawer.blitAlpha(Sprites.units[GameState.colourOf(unitFac)][unit.sprite].get(0, 0), -12, -12);
    fontText.render(cacheDrawer, 24, 2, unit.name);
    if (stats == null){
      stats = unit.stats;
    }
    var statsIdx = [stats.hp, stats.mp, stats.atk, stats.def];
    var maxStats = [stats.maxHp, stats.mp, stats.atk, stats.def];
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
  
  private function renderTooltip(text:String):Bitmap {
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
  
  private function nextCheck():Void {
    var j = (tileSelected == -1 ? 0 : tileSelected + 1);
    for (i in 0...GameState.TILES){
      if (   GameState.unit[(i + j) % GameState.TILES] != -1
          && GameState.unitFac[(i + j) % GameState.TILES] == GameState.currentFaction
          && GameState.turned[(i + j) % GameState.TILES] == MoveStatus.Ready){
        nextTile = (i + j) % GameState.TILES;
        if (nextTile != tileSelected){
          nextTarget = NEXT_MAX;
          return;
        }
      }
    }
    nextTile = -1;
    nextTarget = 0;
  }
  
  public function click():Bool {
    var ret = (switch (hoverAction){
        case ToggleDrawer:
        app.assetManager.getSound("gui_drawer").play();
        drawerTarget = DRAWER_MAX - drawerTarget;
        true;
        
        case Order(o):
        switch (Unit.ORDERS[o].type){
          case Cancel:
          
          case Skip:
          GameState.currentMoves.push(new Move(tileSelected, -1, Skip));
          GameState.turned[tileSelected] = MoveStatus.Skipped;
          GameState.encodeTurnSend();
          
          case Capture:
          GameState.currentMoves.push(new Move(tileSelected, -1, Capture));
          GameState.turned[tileSelected] = MoveStatus.Moved;
          GameState.encodeTurnSend();
          
          case Shield:
          
          case Abandon:
          
          case Undo:
          for (mi in 0...GameState.currentMoves.length){
            if (GameState.currentMoves[mi].from == tileSelected){
              GameState.currentMoves.splice(mi, 1);
              GameState.turned[tileSelected] = MoveStatus.Ready;
              GameState.encodeTurnSend();
              break;
            }
          }
          
          case Build:
          buildTarget = BUILD_MAX;
          
          case BuildCancel:
          GameState.unit[tileSelected] = -1;
          GameState.unitFac[tileSelected] = -1;
          GameState.turned[tileSelected] = MoveStatus.None;
          GameState.encodeTurnSend();
          deselectTile();
          deselectAll();
          ren.rotate(camera);
        }
        if (Unit.ORDERS[o].type != Build){
          deselectTile();
          deselectAll();
          ordersTarget = 0;
        }
        true;
        
        case BuildExit:
        buildTarget = 0;
        true;
        
        case Build(o):
        GameState.currentMoves.push(new Move(tileSelected, o - 1, Build));
        GameState.unit[tileSelected] = o - 1;
        GameState.unitFac[tileSelected] = GameState.faction[tileSelected];
        GameState.turned[tileSelected] = MoveStatus.Building;
        GameState.encodeTurnSend();
        deselectTile();
        deselectAll();
        ren.rotate(camera);
        ordersTarget = 0;
        buildTarget = 0;
        true;
        
        case Next:
        clickTile(nextTile);
        true;
        
        case NextTurn:
        GameState.turn();
        ren.rotate(camera);
        true;
        
        case _: (tooltipTime != 0);
      });
    nextCheck();
    return ret;
  }
  
  public function deselectTile():Void {
    if (tileSelected != -1){
      ico.tiles[tileSelected].selected = false;
      GameState.currentClicks[tileSelected] = null;
    }
    tileSelected = -1;
    setStatus();
  }
  
  public function deselectAll():Void {
    for (ti in 0...ico.tiles.length){
      ico.tiles[ti].selected = false;
      GameState.currentClicks[ti] = null;
    }
    setStatus();
  }
  
  public function clickTile(t:Int):Void {
    if (t == -1){
      return;
    }
    var cmd = GameState.currentClicks[t];
    if (cmd != null){
      GameState.currentMoves.push(cmd);
      GameState.turned[cmd.from] = MoveStatus.Moved;
      GameState.encodeTurnSend();
      deselectTile();
      deselectAll();
      ren.scale();
      ordersTarget = 0;
      return;
    }
    deselectTile();
    deselectAll();
    cameraTrans(ren.lookAt(t).multiply(camera).unit);
    tileSelected = t;
    ico.tiles[t].selected = true;
    var tile    = ico.tiles[t];
    var unit    = GameState.unit[t];
    var unitFac = GameState.unitFac[t];
    var faction = GameState.faction[t];
    var turned  = GameState.turned[t];
    if (unit != -1){
      setStatus(Unit.UNITS[unit], GameState.stats[t], unitFac, faction);
    }
    if (   faction == GameState.currentFaction
        || unitFac == GameState.currentFaction){
      ordersTarget = ORDER_MAX;
      ordersList = [0];
      if (unit != -1 && unitFac == GameState.currentFaction){
        var soundId = (switch (unit){
            case 0: "generator_select";
            case 1: "";
            case 2: "boot_select";
            case 3: "bow_select";
            case 4: "trebuchet_select";
            case 5: "dynamite_select";
            case 6: "dagger_select";
            case _: "";
          });
        if (soundId != ""){
          app.assetManager.getSound(soundId).play();
        }
        switch (turned){
          case Ready:
          ordersList.push(1);
          //ordersList = ordersList.concat(Unit.UNITS[unit].orders);
          for (t in Geodesic.getRange(tile, Unit.UNITS[unit].stats.mp, false)){
            t.selected = true;
            GameState.currentClicks[t.index] = new Move(
                 tile.index
                ,t.index
                ,Movement
              );
          }
          for (t in Geodesic.getRange(tile, Unit.UNITS[unit].stats.ran, true)){
            if (GameState.unit[t.index] != -1 && GameState.unitFac[t.index] != GameState.currentFaction){
              t.selected = true;
              GameState.currentClicks[t.index] = new Move(
                   tile.index
                  ,t.index
                  ,Attack
                );
            }
          }
          if (faction != GameState.currentFaction){
            ordersList = ordersList.concat(Unit.AWAY_LAND_ORDERS);
          }
          
          case Building:
          ordersList.push(7);
          
          case Moved | Skipped:
          ordersList.push(5);
          
          case _:
        }
      }
      if (faction == GameState.currentFaction){
        ordersList = ordersList.concat(Unit.HOME_LAND_ORDERS);
        if (unit == -1){
          ordersList.push(6);
        }
      }
    } else {
      ordersTarget = 0;
    }
  }
}

private enum GUIAction {
  None;
  ToggleDrawer;
  Rotation(r:Int);
  Order(o:Int);
  NextTurn;
  Next;
  BuildExit;
  Build(o:Int);
}

typedef Tooltip = {
     x:Int
    ,y:Int
    ,w:Int
    ,h:Int
    ,text:String
  };
