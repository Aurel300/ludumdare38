package common;

import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.bmp.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import sk.thenet.stream.bmp.*;

class Geodesic {
  public static function generateIcosahedron(n:Int):Geodesic {
    var phi = 1.618;
    var points = [
         [phi, 1, 0]
        ,[1, 0, phi]
        ,[0, phi, 1]
        ,[-phi, 1, 0]
        ,[1, 0, -phi]
        ,[0, -phi, 1]
        ,[phi, -1, 0]
        ,[-1, 0, phi]
        ,[0, phi, -1]
        ,[-phi, -1, 0]
        ,[-1, 0, -phi]
        ,[0, -phi, -1]
      ].map(function(a) return (new Point3DF(a[0], a[1], a[2])).unit());
    var lines = [];
    for (pi in 0...points.length){
      for (pj in (pi + 1)...points.length){
        var d = points[pi].subtract(points[pj]).magnitude();
        if (d < phi){
          lines.push({f: pi, t: pj});
        }
      }
    }
    
    var tilesP = [];
    
    inline function linesOf(p:Int):Array<{f:Int, t:Int}> {
      var ret = [];
      for (l in lines){
        if (l.f == p || l.t == p){
          ret.push(l);
        }
      }
      return ret;
    }
    inline function adjacentTo(p:Int):Array<Int> {
      var ret = [];
      for (l in lines){
        if (l.f == p){
          ret.push(l.t);
        } else if (l.t == p){
          ret.push(l.f);
        }
      }
      return ret;
    }
    inline function intersect(a:Array<Int>, b:Array<Int>):Array<Int> {
      var ret = [];
      for (p in a){
        if (b.indexOf(p) != -1){
          ret.push(p);
        }
      }
      return ret;
    }
    inline function tilePush(a:Array<Int>):Void {
      a.sort(function(a, b) return a - b);
      var f:Bool = false;
      for (t in tilesP){
        if (t[0] == a[0] && t[1] == a[1] && t[2] == a[2]){
          f = true;
        }
      }
      if (!f){
        tilesP.push(a);
      }
    }
    
    for (l in lines){
      var adj1 = adjacentTo(l.f);
      var adj2 = adjacentTo(l.t);
      var tn = intersect(adj1, adj2);
      tilePush([l.f, l.t, tn[0]]);
      tilePush([l.f, l.t, tn[1]]);
    }
    
    var tiles = [ for (t in tilesP) new Tile(t) ];
    
    for (ti in 0...tilesP.length){
      for (oi in 0...tilesP.length){
        if (ti == oi){
          continue;
        }
        if (intersect(tilesP[ti], tilesP[oi]).length == 2){
          tiles[ti].adjacent.push(tiles[oi]);
        }
      }
    }
    
    var subpoints:Array<GeoPoint> = [];
    var subtiles  = [];
    
    var linesUsed:Array<{f:Int, t:Int, p:Array<Int>}> = [];
    
    inline function lineCheck(a:Int, b:Int):Int {
      var ret:Int = -1;
      for (li in 0...linesUsed.length){
        if ((linesUsed[li].f == a && linesUsed[li].t == b)
            || (linesUsed[li].t == a && linesUsed[li].f == b)){
          ret = li;
          break;
        }
      }
      if (ret == -1){
        ret = linesUsed.length;
        linesUsed.push({f: a, t: b, p: []});
      }
      return ret;
    }
    inline function closest(point:Point3DF):Int {
      var ret = -1;
      for (pi in 0...subpoints.length){
        if (subpoints[pi].distance(point) < .05){
          ret = pi;
          break;
        }
      }
      if (ret == -1){
        ret = subpoints.length;
        subpoints.push(GeoPoint.ofPoint(point));
      }
      return ret;
    }
    inline function sign(p1:GeoPoint, p2:GeoPoint, p3:GeoPoint):Bool {
      var px = p2.subtract(p1);
      var py = p3.subtract(p1);
      var cp = px.cross(py);
      return (p1.dot(cp) > 0);
    }
    inline function subscribeTile(points:Array<Int>):Void {
      var tile = sign(subpoints[points[0]], subpoints[points[1]], subpoints[points[2]])
        ? new Tile([points[0], points[1], points[2]])
        : new Tile([points[0], points[2], points[1]]);
      for (p in tile.points){
        subpoints[p].tiles.push(tile);
      }
      subtiles.push(tile);
    }
    
    for (t in tiles){
      var po = points[t.points[0]];
      var px = points[t.points[1]].subtract(po).scale(1 / n);
      var py = points[t.points[2]].subtract(po).scale(1 / n);
      
      var ppoints = [];
      var ptiles = [];
      
      for (y in 0...n + 1) for (x in 0...n + 1){
        if (x + y > n){
          ppoints.push(-1);
        } else {
          var point = po.add(px.scale(x)).add(py.scale(y)).unit();
          //.scale(.95 + FM.prng.nextFloat(.3));
          ppoints.push(closest(point));
        }
        
        if ((x == 0 || y == 0) || (x + y > n + 1)){
          continue;
        }
        subscribeTile([
             ppoints[(x - 1) + (y - 1) * (n + 1)]
            ,ppoints[(x    ) + (y - 1) * (n + 1)]
            ,ppoints[(x - 1) + (y    ) * (n + 1)]
          ]);
        if (x + y > n){
          continue;
        }
        subscribeTile([
             ppoints[(x    ) + (y - 1) * (n + 1)]
            ,ppoints[(x    ) + (y    ) * (n + 1)]
            ,ppoints[(x - 1) + (y    ) * (n + 1)]
          ]);
      }
    }
    
    for (p in subpoints){
      for (ti in 0...p.tiles.length){
        for (oi in (ti + 1)...p.tiles.length){
          if (intersect(p.tiles[ti].points, p.tiles[oi].points).length == 2){
            if (p.tiles[ti].adjacent.indexOf(p.tiles[oi]) == -1){
              p.tiles[ti].adjacent.push(p.tiles[oi]);
            }
            if (p.tiles[oi].adjacent.indexOf(p.tiles[ti]) == -1){
              p.tiles[oi].adjacent.push(p.tiles[ti]);
            }
          }
        }
      }
    }
    
    return new Geodesic(subpoints, subtiles);
  }
  
  public var points(default, null):Vector<GeoPoint>;
  public var tiles (default, null):Vector<Tile>;
  public var pents (default, null):Vector<GeoPoint>;
  public var height(default, null):Vector<Float>;
  
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
  
  private var ph:Int = 0;
  
  public function new(points:Array<GeoPoint>, tiles:Array<Tile>){
    this.points = Vector.fromArrayCopy(points);
    this.tiles  = Vector.fromArrayCopy(tiles);
    this.pents  = new Vector(12);
    var pi:Int = 0;
    for (p in points){
      if (p.tiles.length == 5){
        pents[pi] = p;
        for (t in p.tiles){
          t.pent = true;
        }
      }
    }
    for (t in tiles){
      t.colour = 0xFF101010 | FM.prng.next();
    }
    
    for (i in 0...20){
      for (f in 0...8){
        if (i == 5){
          tiles[i + f * 20].sprite = f;
        }
        tiles[i + f * 20].occupied = f;
      }
    }
    
    rpoints = new Vector(points.length);
    ppoints = new Vector(points.length);
    upoints = new Vector(points.length);
    ptiles = new Vector(tiles.length);
    stiles = new Vector(tiles.length);
    height = new Vector(points.length);
    for (i in 0...height.length){
      height[i] = FM.prng.nextFloat(.2);
    }
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
    //renbuf = new Vector<Int>(Main.HEIGHT * RB_WIDTH);
    rotate(Quaternion.identity);
  }
  
  public function rotate(q:Quaternion, ?doScale:Bool = true):Void {
    var rpVisible = 0;
    for (p in points){
      rpoints[rpVisible] = GeoPoint.ofPoint(
          q.rotate(p).scale(
              //.8 + Math.sin((ph / 120) * Math.PI * 2) * height[rpVisible]
              //.7 + (.46 + Math.sin(ph / 360 * Math.PI * 2) * .07) * height[rpVisible]
              .7 + .5 * height[rpVisible]
            )
        );
      rpVisible++;
    }
    
    if (doScale){
      scale(lastScale);
    }
  }
  
  public function scale(scale:Float):Void {
    lastScale = scale;
    
    inline function project(p:Point3DF, scale:Float):Point2DI {
      return new Point2DI(
           FM.floor(p.x * scale + Main.HWIDTH)
          ,FM.floor(p.y * scale * .93 + Main.HHEIGHT + 70)
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
    stVisible = 0;
    for (t in tiles){
      if (rpoints[t.points[0]].z < -.2){
        t.visible = false;
      } else if (ppoints[t.points[0]].y >= Main.HEIGHT
          && ppoints[t.points[1]].y >= Main.HEIGHT
          && ppoints[t.points[2]].y >= Main.HEIGHT){
        t.visible = false;
      } else {
        var area = triangleArea(
            ppoints[t.points[0]], ppoints[t.points[1]], ppoints[t.points[2]]
          );
        t.visible = area > 0;
        t.alpha = FM.maxI(0, 7 - FM.floor((area * 2.6 / scale)));
        t.colour = (if (t.occupied != -1){
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
        //trace(t.colour);
        //t.colour = (FM.minI(255, FM.floor((area * 20 / scale))) << 24) | 0x8899AA;
        //t.ucolour = (FM.minI(255, FM.floor((area * 10 / scale))) << 24) | 0xBBCCDD;
      }
      if (t.visible){
        ptiles[ptVisible++] = t;
        if (t.sprite != -1){
          var xmin = ppoints[t.points[0]].x;
          var xmax = ppoints[t.points[0]].x;
          var ymin = ppoints[t.points[0]].y;
          var ymax = ppoints[t.points[0]].y;
          for (i in 1...3){
            if (ppoints[t.points[i]].x < xmin) xmin = ppoints[t.points[i]].x;
            if (ppoints[t.points[i]].x > xmax) xmax = ppoints[t.points[i]].x;
            if (ppoints[t.points[i]].y < ymin) ymin = ppoints[t.points[i]].y;
            if (ppoints[t.points[i]].y > ymax) ymax = ppoints[t.points[i]].y;
          }
          t.spriteX = (xmin + xmax) >> 1;
          t.spriteY = (ymin + ymax) >> 1;
          var oangle = Math.atan2(
              Main.HEIGHT - 20 - t.spriteY, Main.HWIDTH - t.spriteX
            );
          t.spriteOX = (Math.cos(oangle) * 4);
          t.spriteOY = (Math.sin(oangle) * 4);
          t.spriteAngle = Math.atan2(
              Main.HEIGHT + 40 - t.spriteY, Main.HWIDTH - t.spriteX
            ) - Math.PI * .5;
          stiles[stVisible++] = t;
        }
      }
    }
  }
  
  private var select:Tile;
  
  public function render(bmp:Bitmap):Void {
    for (i in 0...8){
      facLight[i] = facLightPattern[i * 120 + ((ph * (i < 4 ? 1 : 2)) % 120)];
    }
    
    var lastSelect = select;
    select = null;
    
    for (rti in 0...ptVisible){
      var tile = ptiles[rti];
      var sel = (tile == lastSelect);
      
      var ly:Int = -1;
      var txmin:Int = Main.WIDTH - 1;
      var txmax:Int = 0;
      var c = tile.colour;
      if (sel){
        c += (tile.occupied == -1 ? 10 : 2);
      }
      if (tile.occupied != -1){
        c += facLight[tile.occupied];
      }
      
      inline function renderScan():Void {
        if (txmax >= txmin){
          /*
          if (sel){
            txmin -= 2;
            txmax += 2;
          }*/
          if (Platform.mouse.y == ly && FM.withinI(Platform.mouse.x, txmin, txmax)){
            select = tile;
          }
          bmp.setFillPattern(tile.occupied != -1 ? Palette.facPatterns[tile.occupied][c] : Palette.patterns[c]);
          bmp.fillRectPattern(txmin, ly, txmax - txmin, 1);
          /*
          if (tile.occupied != -1){
            bmp.fillRect(txmin, ly, 1, 1, Palette.factions[tile.occupied + 8]);
            bmp.fillRect(txmax - 1, ly, 1, 1, Palette.factions[tile.occupied + 8]);
          }
          */
        }
        txmin = Main.WIDTH - 1;
        txmax = 0;
      }
      
      for (p in (tile.occupied == -1 ? new TopDownBresenhams(
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
      bmp.blitAlpha(
           Sprites.factionSigns[tile.sprite].get(tile.alpha, tile.spriteAngle)
          ,tile.spriteX - 24 + FM.floor(spriteOffsetPattern[ph] * tile.spriteOX)
          ,tile.spriteY - 24 + FM.floor(spriteOffsetPattern[ph] * tile.spriteOY)
        );
    }
    
    ph++;
    ph %= 120;
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
