import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.bmp.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import sk.thenet.stream.bmp.*;
import common.*;

class GeodesicRender {
  public static var Y_OFFSET:Int = 70;
  public static var Y_SCALE:Float = .93;
  public static var CENTER:Point2DI
    = new Point2DI(Main.HWIDTH, Main.HHEIGHT + Y_OFFSET);
  public static var VIEW:Point3DF = (new Point3DF(0, -.5, 1)).unit();
  
  private var points:Vector<GeoPoint>;
  private var tiles:Vector<Tile>;
  private var rpoints:Vector<GeoPoint>; // rotated points
  private var ppoints:Vector<Point2DI>; // projected points
  private var upoints:Vector<Point2DI>; // projected points, underground
  private var ptiles:Vector<Tile>; // rotated and projected tiles
  private var ptVisible:Int = 0;
  private var stiles:Vector<Tile>; // tiles with sprites
  private var stVisible:Int = 0;
  private var lastScale:Float = 1;
  private var facLight:Vector<Int>;
  private var facLightPattern:Vector<Int>;
  private var spriteOffsetPattern:Vector<Float>;
  private var buildAlphaPattern:Vector<Int>;
  
  private var ph:Int = 0;
  
  public function new(ico:Geodesic){
    points = ico.points;
    tiles = ico.tiles;
    
    rpoints = new Vector(points.length);
    ppoints = new Vector(points.length);
    upoints = new Vector(points.length);
    ptiles = new Vector(tiles.length);
    stiles = new Vector(tiles.length);
    select = tiles[35];
    facLight = new Vector(Palette.facPatterns.length);
    facLightPattern = Vector.fromArrayCopy([
        for (i in 0...8) for (j in 0...120){
          FM.floor(4 * Math.sin(((j + i * 45) / 120) * Math.PI * 2));
        }
      ]);
    
    spriteOffsetPattern = Vector.fromArrayCopy([
        for (i in 0...120){
          Math.cos((i / 120) * Math.PI * 2);
        }
      ]);
    
    buildAlphaPattern = Vector.fromArrayCopy([
        for (i in 0...120){
          FM.floor((Math.cos((i / 120) * Math.PI * 2) + 1) * 4);
        }
      ]);
    
    rotate(Quaternion.identity);
  }
  
  public function rotate(q:Quaternion, ?doScale:Bool = true):Void {
    var rpVisible = 0;
    for (p in points){
      rpoints[rpVisible] = GeoPoint.ofPoint(
          q.rotate(p).scale(
              .7 + .5 * GameState.height[rpVisible]
            )
        );
      rpVisible++;
    }
    
    if (doScale){
      scale(lastScale);
    }
  }
  
  public function scale(?scale:Float):Void {
    if (scale != null){
      lastScale = scale;
    } else {
      scale = lastScale;
    }
    
    inline function project(p:Point3DF, scale:Float):Point2DI {
      return new Point2DI(
           FM.floor(p.x * scale + Main.HWIDTH)
          ,FM.floor(p.y * scale * Y_SCALE + Main.HHEIGHT + Y_OFFSET)
        );
    }
    
    var ppVisible = 0;
    for (p in rpoints){
      ppoints[ppVisible] = project(p, scale);
      upoints[ppVisible] = project(p, scale * 1.03);
      ppVisible++;
    }
    
    inline function triangleArea(p1:Point2DI, p2:Point2DI, p3:Point2DI):Int {
      return (p1.x * p2.y + p2.x * p3.y + p3.x * p1.y
            - p2.x * p1.y - p3.x * p2.y - p1.x * p3.y);
    }
    
    ptVisible = 0;
    var stilesP = [];
    for (t in tiles){
      var area = 0;
      var visible = false;
      if (rpoints[t.points[0]].z >= -.2
          && (   ppoints[t.points[0]].y < Main.HEIGHT
              || ppoints[t.points[1]].y < Main.HEIGHT
              || ppoints[t.points[2]].y < Main.HEIGHT)
          && (   ppoints[t.points[0]].x < Main.WIDTH
              || ppoints[t.points[1]].x < Main.WIDTH
              || ppoints[t.points[2]].x < Main.WIDTH)
          && (   ppoints[t.points[0]].x >= 0
              || ppoints[t.points[1]].x >= 0
              || ppoints[t.points[2]].x >= 0)){
        area = triangleArea(
            ppoints[t.points[0]], ppoints[t.points[1]], ppoints[t.points[2]]
          );
        visible = area > 0;
      }
      if (visible){
        ptiles[ptVisible++] = t;
        t.alpha = FM.maxI(0, 7 - FM.floor((area * 2.6 / scale)));
        var ti = t.index;
        var faction = GameState.faction[ti];
        t.colour = (if (faction != -1){
            FM.minI(
                 Palette.FACTION
                ,FM.floor(area * 1.3 / scale)
              );
          } else {
            FM.minI(
                 Palette.patterns.length - 1
                ,FM.minI(Palette.ALPHA - 1, FM.floor((area * 4 / scale)) + (t.pent ? 5 : 0))
                + (t.alpha >> 1) * Palette.ALPHA
              );
          });
        if (GameState.unit[ti] != -1){
          t.spriteX = FM.floor((ppoints[t.points[0]].x + ppoints[t.points[1]].x + ppoints[t.points[2]].x) / 3);
          t.spriteY = FM.floor((ppoints[t.points[0]].y + ppoints[t.points[1]].y + ppoints[t.points[2]].y) / 3);
          var oangle = Math.atan2(
              Main.HEIGHT - 20 - t.spriteY, Main.HWIDTH - t.spriteX
            );
          t.spriteOX = (Math.cos(oangle) * 4);
          t.spriteOY = (Math.sin(oangle) * 4);
          t.spriteAngle = Math.atan2(
              Main.HEIGHT + 40 - t.spriteY, Main.HWIDTH - t.spriteX
            ) - Math.PI * .5;
          stilesP.push(t);
        }
      }
    }
    
    stilesP.sort(zSortTile);
    stVisible = 0;
    for (t in stilesP){
      stiles[stVisible++] = t;
    }
  }
  
  public function getTileCenter(ti:Int):Point3DF {
    return (new Point3DF(
         (rpoints[tiles[ti].points[0]].x + rpoints[tiles[ti].points[1]].x + rpoints[tiles[ti].points[2]].x) / 3
        ,(rpoints[tiles[ti].points[0]].y + rpoints[tiles[ti].points[1]].y + rpoints[tiles[ti].points[2]].y) / 3
        ,(rpoints[tiles[ti].points[0]].z + rpoints[tiles[ti].points[1]].z + rpoints[tiles[ti].points[2]].z) / 3
      )).unit();
  }
  
  public function lookAt(ti:Int):Quaternion {
    var tc = getTileCenter(ti);
    return Quaternion.axisRotation(
         VIEW.cross(tc)
        ,-Math.acos(tc.dot(VIEW)) * tc.distance(VIEW) / 1.5
      );
  }
  
  private inline function zSortTile(a:Tile, b:Tile):Int {
    return (new Point2DI(b.spriteX, b.spriteY)).distanceManhattan(CENTER)
         - (new Point2DI(a.spriteX, a.spriteY)).distanceManhattan(CENTER);
  }
  
  private var select:Tile;
  
  public function render(bmp:Bitmap, allowSelect:Bool):Void {
    for (i in 0...8){
      facLight[i] = facLightPattern[i * 120 + (ph % 120)];
    }
    
    var lastSelect = select;
    select = null;
    
    for (rti in 0...ptVisible){
      var tile = ptiles[rti];
      var ti = tile.index;
      var sel = tile.selected || tile.hover;
      var faction = GameState.faction[ti];
      
      var ly:Int = -1;
      var txmin:Int = Main.WIDTH - 1;
      var txmax:Int = 0;
      var c = tile.colour;
      if (tile.hover){
        c += (faction == -1 ? 5 : 1);
      }
      if (tile.selected){
        if (faction == -1){
          c += 10 + facLight[0];
          if (c >= Palette.ALPHA){
            c = Palette.ALPHA - 1;
          }
        } else {
          c += 1 + facLight[faction];
          if (c >= Palette.FACTION){
            c = Palette.FACTION - 1;
          }
        }
      }
      bmp.setFillPattern(faction != -1 ? Palette.facPatterns[faction][c] : Palette.patterns[c]);
      
      inline function renderScan():Void {
        if (txmax >= txmin){
          if (   allowSelect
              && Platform.mouse.y == ly
              && FM.withinI(Platform.mouse.x, txmin, txmax)){
            select = tile;
          }
          bmp.fillRectStyled(txmin, ly, txmax - txmin, 1);
          /*
          if (tile.faction != -1){
            bmp.fillRect(txmin, ly, 1, 1, Palette.factions[tile.faction + 8]);
            bmp.fillRect(txmax - 1, ly, 1, 1, Palette.factions[tile.faction + 8]);
          }
          */
        }
        txmin = Main.WIDTH - 1;
        txmax = 0;
      }
      
      for (p in (faction == -1 ? new TopDownBresenhams(
           ppoints[tile.points[0]]
          ,ppoints[tile.points[1]]
          ,ppoints[tile.points[2]]
        ) : new TopDownBresenhams(
           upoints[tile.points[0]]
          ,upoints[tile.points[1]]
          ,upoints[tile.points[2]]
        ))){
        if (p.y != ly && ly != -1){
          renderScan();
        }
        if (txmin > p.x){
          txmin = p.x;
        }
        if (txmax < p.x){
          txmax = p.x;
        }
        ly = p.y;
      }
      if (ly != -1){
        renderScan();
      }
    }
    
    for (rti in 0...stVisible){
      var tile = stiles[rti];
      var ti = tile.index;
      var sel = tile.selected;
      var unitFac = GameState.unitFac[ti];
      var pin = new Bresenham(
           new Point2DI(tile.spriteX, tile.spriteY)
          ,new Point2DI(
               tile.spriteX - FM.floor(tile.spriteOX * (sel ? 5 : 2))
              ,tile.spriteY - FM.floor(tile.spriteOY * (sel ? 5 : 2))
            )
        );
      bmp.setFillColour(Palette.factions[8 + unitFac]);
      if (pin.yLong){
        for (p in pin){
          bmp.fillRectStyled(p.x, p.y, 2, 1);
        }
      } else {
        for (p in pin){
          bmp.fillRectStyled(p.x, p.y, 1, 2);
        }
      }
      var alpha = tile.alpha;
      var moved = (switch (GameState.turned[ti]){
          case Moved: Sprites.moveds[0];
          case Skipped: Sprites.moveds[1];
          case Building: alpha = FM.minI(alpha + buildAlphaPattern[ph], 7); Sprites.moveds[2];
          case Ready: Sprites.moveds[3];
          case _: null;
        });
      bmp.blitAlpha(
           Sprites.units[unitFac][GameState.unit[ti]].get(alpha, tile.spriteAngle)
          ,tile.spriteX - 24 - FM.floor(tile.spriteOX * (sel ? 5.5 : 2.5))
          ,tile.spriteY - 24 - FM.floor(tile.spriteOY * (sel ? 5.5 : 2.5))
        );
      if (moved != null && GameState.unitFac[ti] == GameState.currentFaction){
        bmp.blitAlpha(
             moved
            ,tile.spriteX - 12 - FM.floor(tile.spriteOX * (sel ? 5.5 : 2.5))
            ,tile.spriteY - 12 - FM.floor(tile.spriteOY * (sel ? 5.5 : 2.5))
          );
      }
    }
    
    ph++;
    ph %= 120;
    
    if (lastSelect != select){
      if (lastSelect != null){
        lastSelect.hover = false;
      }
      if (select != null){
        select.hover = true;
      }
    }
  }
  
  public function click():Int {
    if (select != null){
      ph = 0;
      return select.index;
    }
    return -1;
  }
}

class TopDownBresenhams {
  private var b1:Bresenham;
  private var b2:Bresenham;
  private var b3:Bresenham;
  private var f1:Point2DI;
  private var f2:Point2DI;
  private var f3:Point2DI;
  
  public function new(p1:Point2DI, p2:Point2DI, p3:Point2DI){
    b1 = Bresenham.getTopDown(p1, p2);
    b2 = Bresenham.getTopDown(p2, p3);
    b3 = Bresenham.getTopDown(p3, p1);
  }
  
  public function hasNext():Bool {
    return (f1 != null || b1.hasNext())
        || (f2 != null || b2.hasNext())
        || (f3 != null || b3.hasNext());
  }
  
  public function next():Point2DI {
    if (f1 == null && b1.hasNext()){
      f1 = b1.next();
    }
    if (f2 == null && b2.hasNext()){
      f2 = b2.next();
    }
    if (f3 == null && b3.hasNext()){
      f3 = b3.next();
    }
    var ret:Point2DI = null;
    if (f1 == null){
      if (f2 == null){ ret = f3; f3 = null; return ret; }
      if (f3 == null){ ret = f2; f2 = null; return ret; }
    }
    if (f2 == null){
      if (f1 == null){ ret = f3; f3 = null; return ret; }
      if (f3 == null){ ret = f1; f1 = null; return ret; }
    }
    if (f3 == null){
      if (f2 == null){ ret = f1; f1 = null; return ret; }
      if (f1 == null){ ret = f2; f2 = null; return ret; }
    }
    if (f1 != null
        && ((f2 == null || f1.y <= f2.y)
            && (f3 == null || f1.y <= f3.y))){
      ret = f1;
      f1 = null;
    } else if (f2 != null
        && (f3 == null || f2.y <= f3.y)){
      ret = f2;
      f2 = null;
    } else {
      ret = f3;
      f3 = null;
    }
    return ret;
  }
}
