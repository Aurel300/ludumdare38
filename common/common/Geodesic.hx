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
    inline function subscribeTile(tile:Tile):Void {
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
        subscribeTile(new Tile([
             ppoints[(x - 1) + (y - 1) * (n + 1)]
            ,ppoints[(x    ) + (y - 1) * (n + 1)]
            ,ppoints[(x - 1) + (y    ) * (n + 1)]
          ]));
        if (x + y > n){
          continue;
        }
        subscribeTile(new Tile([
             ppoints[(x    ) + (y - 1) * (n + 1)]
            ,ppoints[(x    ) + (y    ) * (n + 1)]
            ,ppoints[(x - 1) + (y    ) * (n + 1)]
          ]));
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
  
  private var rpoints:Vector<GeoPoint>;
  private var rpVisible:Int = 0;
  private var rtiles:Vector<Tile>;
  private var rtVisible:Int = 0;
  
  public function new(points:Array<GeoPoint>, tiles:Array<Tile>){
    this.points = Vector.fromArrayCopy(points);
    this.tiles  = Vector.fromArrayCopy(tiles);
    this.pents  = new Vector<GeoPoint>(12);
    var pi:Int = 0;
    for (p in points){
      if (p.tiles.length == 5){
        pents[pi] = p;
      }
    }
    for (t in tiles){
      t.colour = 0xFF000000 | FM.prng.next();
    }
    rpoints = new Vector<GeoPoint>(points.length);
    rtiles = new Vector<Tile>(tiles.length);
    height = new Vector<Float>(points.length);
    for (i in 0...height.length){
      height[i] = FM.prng.nextFloat(.2);
    }
    renbuf = new Vector<Int>(Main.HEIGHT * RB_WIDTH);
    rotate(Quaternion.identity);
  }
  
  public function rotate(q:Quaternion):Void {
    rpVisible = 0;
    for (p in points){
      rpoints[rpVisible] = GeoPoint.ofPoint(q.rotate(p).scale(.8 + Math.sin((ph / 120) * Math.PI * 2) * height[rpVisible]));
      rpVisible++;
    }
    rtVisible = 0;
    for (t in tiles){
      t.visible
        = !( rpoints[t.points[0]].z < 0
          && rpoints[t.points[1]].z < 0
          && rpoints[t.points[2]].z < 0)
          && !(rpoints[t.points[0]].y >= Main.HEIGHT
          &&   rpoints[t.points[1]].y >= Main.HEIGHT
          &&   rpoints[t.points[2]].y >= Main.HEIGHT);
      if (t.visible){
        rtiles[rtVisible++] = t;
      }
    }
  }
  
  private static inline var RB_WIDTH :Int = 40;
  private static inline var RB_XMIN  :Int = 0;
  private static inline var RB_XMAX  :Int = 1;
  private static inline var RB_NUM   :Int = 2;
  private static inline var RB_TILES :Int = 3;
  
  private static inline var RB_TWIDTH:Int = 2;
  private static inline var RB_TX    :Int = 0;
  private static inline var RB_TTILE :Int = 1;
  
  private var ph:Int = 0;
  private var ran:Float = 0;
  private var renbuf:Vector<Int>;
  
  public function render(bmp:Bitmap, scale:Float):Void {
    rotate(Quaternion.axisRotation(new Point3DF(1, 0, .5), ran));
    ran += .01;
    ph++;
    ph %= 120;
    
    inline function project(p:Point3DF, ?ox:Int = 0, ?oy:Int = 0):Point2DI {
      return new Point2DI(
           FM.floor(p.x * scale + Main.HWIDTH + ox)
          ,FM.floor(p.y * scale * .93 + Main.HHEIGHT + 70 + oy)
        );
    }
    
    var xmin:Int = Main.WIDTH - 1;
    var xmax:Int = 0;
    var ymin:Int = Main.HEIGHT - 1;
    var ymax:Int = 0;
    
    for (y in 0...Main.HEIGHT){
      renbuf[y * RB_WIDTH + RB_XMIN] = Main.WIDTH - 1;
      renbuf[y * RB_WIDTH + RB_XMAX] = 0;
      renbuf[y * RB_WIDTH + RB_NUM]  = 0;
    }
    
    for (rti in 0...rtVisible){
      var tile = rtiles[rti];
      for (i in 0...3){
        for (p in (new Bresenham(
             project(rpoints[tile.points[i]])
            ,project(rpoints[tile.points[(i + 1) % 3]])
          ))){
          if (xmin > p.x) xmin = p.x;
          if (xmax < p.x) xmax = p.x;
          if (ymin > p.y) ymin = p.y;
          if (ymax < p.y) ymax = p.y;
          
          if (renbuf[p.y * RB_WIDTH + RB_XMIN] > p.x) renbuf[p.y * RB_WIDTH + RB_XMIN] = p.x;
          if (renbuf[p.y * RB_WIDTH + RB_XMAX] < p.x) renbuf[p.y * RB_WIDTH + RB_XMAX] = p.x;
          var pi:Int = 0;
          /*
          while (pi < renbuf[p.y * RB_WIDTH + RB_NUM]){
            if (p.x < renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * pi + RB_TX]){
              break;
            }
            pi++;
          }
          // maybe Vector.blit?
          var pj:Int = renbuf[p.y * RB_WIDTH + RB_NUM];
          while (pj > pi){
            renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * (pj + 1) + RB_TTILE]
              = renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * pj + RB_TTILE];
            renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * (pj + 1) + RB_TX]
              = renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * pj + RB_TX];
            pj--;
          }*/
          renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * pi + RB_TX] = p.x;
          renbuf[p.y * RB_WIDTH + RB_TILES + RB_TWIDTH * pi + RB_TTILE] = rti;
          renbuf[p.y * RB_WIDTH + RB_NUM] = 1;
        }
        /*
        Bresenham.getCurve(
            project(rpoints[tile.points[i]]), project(rpoints[tile.points[(i + 1) % 3]])
          ).applyVector(vec, Main.WIDTH, Main.HEIGHT, 0xFF00AA00, false);
        //*/
      }
    }
    
    if (xmax > xmin && ymax > ymin){
      //var vec = bmp.getVectorRect(xmin, ymin, xmax - xmin, ymax - ymin);
      //var vi = 0;
      //trace(renbuf[ymin * RB_WIDTH + RB_XMIN], renbuf[ymin * RB_WIDTH + RB_XMAX]);
      for (y in ymin...ymax){
        //vi = y * (xmax - xmin) + renbuf[y * RB_WIDTH + RB_XMIN];
        /*
        bmp.set(renbuf[y * RB_WIDTH + RB_XMIN], y, 0xFFAA0000);
        bmp.set(renbuf[y * RB_WIDTH + RB_XMAX], y, 0xFFAA0000);
        */
        bmp.fillRect(
             renbuf[y * RB_WIDTH + RB_XMIN], y
            ,renbuf[y * RB_WIDTH + RB_XMAX] - renbuf[y * RB_WIDTH + RB_XMIN], 1
            ,0xFF000000 | renbuf[y * RB_WIDTH + RB_TILES + RB_TX]
          );
        for (tx in 0...renbuf[y * RB_WIDTH + RB_NUM]){
          /*
          bmp.fillRect(
               renbuf[y * RB_WIDTH + RB_TILES + RB_TWIDTH * tx + RB_TX]
              ,y
              ,renbuf[y * RB_WIDTH + RB_TILES + RB_TWIDTH * (tx + 1) + RB_TX]
               - renbuf[y * RB_WIDTH + RB_TILES + RB_TWIDTH * tx + RB_TX]
              ,1
              ,0xFFAA0000 //rtiles[renbuf[y * RB_WIDTH + RB_TILES + RB_TWIDTH * tx + RB_TTILE]].colour
            );
          */
        }
        /*
        for (x in renbuf[p.y * RB_WIDTH + RB_XMIN]...renbuf[p.y * RB_WIDTH + RB_XMAX]){
          
          vi++;
        }*/
      }
      //bmp.setVectorRect(xmin, ymin, xmax - xmin, ymax - ymin, vec);
    }
    
    bmp.fillRect(0, ymin, 100, 1, 0x99AA0000);
    bmp.fillRect(0, ymax, 100, 1, 0x99AA0000);
    bmp.fillRect(xmin, 0, 1, 100, 0x99AA0000);
    bmp.fillRect(xmax, 0, 1, 100, 0x99AA0000);
    
    /*
    var vec = bmp.getVector();
    for (rti in 0...rtVisible){
      var tile = rtiles[rti];
      for (i in 0...3){
        Bresenham.getCurve(
            project(rpoints[tile.points[i]]), project(rpoints[tile.points[(i + 1) % 3]])
          ).applyVector(vec, Main.WIDTH, Main.HEIGHT, 0xFF00AA00, false);
      }
    }
    bmp.setVector(vec);
    */
  }
}
