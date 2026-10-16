## One piece of glass in the way (or beside it).
class_name GPane
extends RefCounted

var node: MeshInstance3D
var poly: PackedVector2Array
var kind := "thin"
var color_id := -1
var hp := 1
var blocks := true
var alive := true
var base: Transform3D
var gate
var move: Callable
var cracks: Array = []
# tricks
var weak := Vector2.INF        # a marked spot: one hit there breaks it at once
var hinge := 0                 # -1 / 1: hinged on its left / right edge; hit the far edge and it swings open
var opened := false
var shy := false               # the first hit makes it slide aside instead
var splits := false            # breaks into two halves that slide apart
var supports: Array = []       # panes that fall when this one breaks
var on_break: Callable
var falling := false
var charge := -1.0             # >= 0: it charges up as you come; break it before it is full
var prism := false             # a prism node (shoot it: the panes of its colour go)
var sag := 0.0
var bonus := 0          # extra score: glass that is only there to be broken, not in your way
