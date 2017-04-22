package common;

import haxe.ds.Vector;
import sk.thenet.FM;
import sk.thenet.bmp.*;
import sk.thenet.geom.*;
import sk.thenet.plat.Platform;
import sk.thenet.stream.bmp.*;

class Geodesic {
  public static function generateIcosahedron():Geodesic {
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
    
    var tiles = [ for (t in tilesP){
        new Tile([], t);
      } ];
    
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
    
    return new Geodesic(points, lines, tiles);
  }
  
  public var points(default, null):Array<Point3DF>;
  public var lines (default, null):Array<{f:Int, t:Int}>;
  public var tiles (default, null):Array<Tile>;
  private var show:Tile;
  private var showi:Int;
  
  public function new(
    points:Array<Point3DF>, lines:Array<{f:Int, t:Int}>, tiles:Array<Tile>
  ){
    this.points = points;
    this.lines  = lines;
    this.tiles  = tiles;
    
    showi = 0;
    show = this.tiles[showi];
  }
  
  public function subdivide(n:Int):Geodesic {
    var subpoints:Array<Point3DF> = [];
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
        subpoints.push(point);
      }
      return ret;
    }
    
    for (t in tiles){
      var po = points[t.points[0]];
      var px = points[t.points[1]].subtract(po).scale(1 / n);
      var py = points[t.points[2]].subtract(po).scale(1 / n);
      
      /*
      var ll = linesUsed.length;
      
      var lxi  = lineCheck(t.points[0], t.points[1]);
      var lyi  = lineCheck(t.points[0], t.points[2]);
      var lxyi = lineCheck(t.points[1], t.points[2]);
      
      var lx  = lxi  >= ll;
      var ly  = lyi  >= ll;
      var lxy = lxyi >= ll;
      */
      
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
        var lq = new Tile([], [
             ppoints[(x - 1) + (y - 1) * (n + 1)]
            ,ppoints[(x    ) + (y - 1) * (n + 1)]
            ,ppoints[(x - 1) + (y    ) * (n + 1)]
          ]);
        subtiles.push(lq);
        if (x + y < n + 1){
          var uq = new Tile([lq], [
               ppoints[(x    ) + (y - 1) * (n + 1)]
              ,ppoints[(x    ) + (y    ) * (n + 1)]
              ,ppoints[(x - 1) + (y    ) * (n + 1)]
            ]);
          subtiles.push(uq);
          lq.adjacent.push(uq);
        }
      }
    }
    return new Geodesic(subpoints, [], subtiles);
  }
  
  public function cycleShow(i:Int):Void {
    showi += i;
    showi = (showi + tiles.length) % tiles.length;
    show = tiles[showi];
  }
  
  public function render(bmp:Bitmap, angle:Float):Void {
    /*var rm = Quaternion.axisRotation(
        (new Point3DF(1, 0, 0)).unit(), angle
      ).rotationMatrix;
      /*
    var c = Math.cos(angle);
    var s = Math.sin(angle);
    var rm = new RotationMatrix3D(Vector.fromArrayCopy([
         1, 0, 0
        ,0, c, -s
        ,0, s, c
      ]));*/
    var q = Quaternion.axisRotation(
        (new Point3DF(1, 0, 0)).unit(), Platform.mouse.x / 100
      ).multiply(Quaternion.axisRotation(
        (new Point3DF(0, 1, 0)).unit(), Platform.mouse.y / 100
      ));
    var rpoints = points.map(q.rotate);
    
    inline function project(p:Point3DF, ?ox:Int = 0, ?oy:Int = 0):Point2DI {
      return new Point2DI(
           FM.floor(p.x * 140 + Main.HWIDTH + ox)
          ,FM.floor(p.y * 130 + Main.HHEIGHT + 70 + oy)
        );
    }
    /*
    inline function projectF(p:Point3DF):Point2DF {
      return new Point2DF(
           p.x * 30 + Main.HWIDTH
          ,p.y * 30 + Main.HHEIGHT
        );
    }*/
    
    //show = (FM.prng.nextMod(10) > 8 ? FM.prng.nextElement(tiles) : show);
    for (show in tiles){
      if (   rpoints[show.points[0]].z < 0
          && rpoints[show.points[1]].z < 0
          && rpoints[show.points[2]].z < 0){
        continue;
      }
      //show = FM.prng.nextElement(tiles);
      for (n in show.adjacent){
        for (j in 0...3){
          Bresenham.getCurve(
              project(rpoints[n.points[j]], 1, 1), project(rpoints[n.points[(j + 1) % 3]], 1, 1)
            ).apply(bmp, 0xFF0000AA, false);
        }
      }
      for (i in 0...3){
        Bresenham.getCurve(
            project(rpoints[show.points[i]]), project(rpoints[show.points[(i + 1) % 3]])
          ).apply(bmp, 0xFF00AA00, false);
      }
    }
    
    /*
    for (l in lines){
      Bresenham.getCurve(
          project(rpoints[l.f]), project(rpoints[l.t])
        ).apply(bmp, 0xFF00AA00);<p></p>
      /*XiaolinWu.getCurve(
          projectF(rpoints[l.f]), projectF(rpoints[l.t])
        ).apply(bmp, 0xFF00AA00);* /
    }
    */
    
    for (p in rpoints){
      if (p.z < 0){
        continue;
      }
      var pp = project(p);
      bmp.fillRectAlpha(pp.x, pp.y, 3, 3, 0x55FF0000);
    }
  }
}
