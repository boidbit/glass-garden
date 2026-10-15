## Something round to shoot that is not a pane: a jar of marbles, the hub of a fan, a prism, a button.
class_name GTarget
extends RefCounted

var node: Node3D
var kind := "jar"
var radius := 0.45
var gate
var color_id := -1
var alive := true
var on_hit: Callable
var spin := 1.6
