package common;

@:enum
abstract MoveStatus(Int) from Int to Int {
  var None     = 0;
  var Ready    = 1;
  var Moved    = 2;
  var Skipped  = 3;
  var Building = 4;
}
