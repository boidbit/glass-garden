## Glass at one distance along the way: you crash if any of it is still in front of your face when you get there.
class_name GGate
extends RefCounted

var d := 0.0
var kind := ""
var panes: Array = []
var passed := false
var ph := 0.0
var side := 1
var extra: Array = []
var door := false
var finale := false
var grille: Node3D = null
var grille_open := false
var end_level := false
