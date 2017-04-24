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
    
    for (ti in 0...subtiles.length){
      subtiles[ti].index = ti;
      var visited:Array<Tile> = [];
      var queue:Array<Tile> = [subtiles[ti]];
      while (queue.length > 0){
        var qt = queue.shift();
        visited.push(qt);
        if (qt != subtiles[ti]){
          subtiles[ti].range.push(qt);
        }
        for (a in qt.adjacent){
          if (intersect(a.points, subtiles[ti].points).length > 0 && visited.indexOf(a) == -1){
            queue.push(a);
          }
        }
      }
    }
    
    return new Geodesic(subpoints, subtiles);
  }
  
  public var points(default, null):Vector<GeoPoint>;
  public var tiles (default, null):Vector<Tile>;
  public var pents (default, null):Vector<GeoPoint>;
  
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
  }
}
