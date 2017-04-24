package common;

class Move {
  public var from(default, null):Int;
  public var to  (default, null):Int;
  public var type(default, null):MoveType;
  
  public function new(from:Int, to:Int, type:MoveType){
    this.from = from;
    this.to   = to;
    this.type = type;
  }
}

@:enum
abstract MoveType(Int) from Int to Int {
  var Movement = 0;
  var Attack   = 1;
  var Capture  = 2;
  var Skip     = 3;
}
