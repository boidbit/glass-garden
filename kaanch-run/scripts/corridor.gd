## The rooms you fly through: clean geometric halls, one colour scheme per room, glowing strips along the edges.
class_name Corridor
extends RefCounted

const HALF_W := 4.6
const CEIL := 6.4
const SEG := 16.0

# each room: background and mist, walls, floor, the glowing accent, the light, and the colour of the glass edges
const PALETTES := [
	{"name": "Frost", "bg": Color("bfe0ea"), "wall": Color("f4f8f9"), "floor": Color("d9e6ea"), "accent": Color("27c4ff"), "amb": Color("b4d4e2"), "sun": Color("ffffff"), "rim": Color("1d6f93"), "open": true},
	{"name": "Ember", "bg": Color("e99a78"), "wall": Color("f6e3d4"), "floor": Color("e6c2aa"), "accent": Color("ff4f6e"), "amb": Color("eab49c"), "sun": Color("ffe2c6"), "rim": Color("8a2f3c"), "open": true},
	{"name": "Abyss", "bg": Color("0f3540"), "wall": Color("2b5b66"), "floor": Color("1d4650"), "accent": Color("5ff2dc"), "amb": Color("3d7d8c"), "sun": Color("c8f8ff"), "rim": Color("e8ffff"), "open": false},
	{"name": "Neon", "bg": Color("1a1033"), "wall": Color("3b2b62"), "floor": Color("291d47"), "accent": Color("ff4fd8"), "amb": Color("5c4b94"), "sun": Color("eadcff"), "rim": Color("ffe6ff"), "open": false},
	{"name": "Moss", "bg": Color("97b7a0"), "wall": Color("e6eee4"), "floor": Color("c3d4c3"), "accent": Color("ffcc4a"), "amb": Color("a5c6ae"), "sun": Color("fff4d6"), "rim": Color("2f5a3a"), "open": true},
	{"name": "Dune", "bg": Color("e3c792"), "wall": Color("f8eedb"), "floor": Color("e1cca4"), "accent": Color("ff7433"), "amb": Color("e6cfa4"), "sun": Color("fff0d2"), "rim": Color("7a4a1c"), "open": true},
	{"name": "Night", "bg": Color("0b1424"), "wall": Color("223552"), "floor": Color("17253d"), "accent": Color("6fb6ff"), "amb": Color("34507a"), "sun": Color("d6e6ff"), "rim": Color("eaf4ff"), "open": false},
]

static var wall_mat: StandardMaterial3D
static var glow_mat: StandardMaterial3D


static func mats() -> void:
	if wall_mat:
		return
	wall_mat = StandardMaterial3D.new()
	wall_mat.vertex_color_use_as_albedo = true
	wall_mat.roughness = 0.85
	glow_mat = StandardMaterial3D.new()
	glow_mat.vertex_color_use_as_albedo = true
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


static func palette(room: int) -> Dictionary:
	return PALETTES[room % PALETTES.size()]


## a box with its six faces, into a surface tool
static func box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var h := s * 0.5
	st.set_color(col)
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
		[Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var o := c + n * h
		var uu := u * h
		var vv := v * h
		var a := o - uu - vv
		var b := o + uu - vv
		var cc := o + uu + vv
		var d := o - uu + vv
		st.set_normal(n)
		# clockwise as seen from outside (Godot's front faces)
		st.add_vertex(a)
		st.add_vertex(cc)
		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(d)
		st.add_vertex(cc)


## one 16 m piece of hall starting at distance d0 (it runs from z = -d0 to z = -d0 - 16)
static func build(d0: float, room: int, seed_v: int) -> Node3D:
	mats()
	var P: Dictionary = palette(room)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var em := SurfaceTool.new()
	em.begin(Mesh.PRIMITIVE_TRIANGLES)
	var z0 := -d0
	var wall: Color = P.wall
	var floor_c: Color = P.floor
	var acc: Color = P.accent
	# floor tiles with a little variation, and thin gaps between them
	for xi in 4:
		for zi in 8:
			var x := -HALF_W + 1.15 + xi * 2.3
			var shade := rng.randf_range(0.93, 1.04)
			box(st, Vector3(x, -0.15, z0 - zi * 2.0 - 1.0), Vector3(2.26, 0.3, 1.96), floor_c * shade)
	# the walls: slabs of different depths, now and then a block standing out
	for side in [-1, 1]:
		for k in 8:
			var depth := rng.randf_range(0.3, 1.4)
			var zc := z0 - k * 2.0 - 1.0
			var shade := rng.randf_range(0.9, 1.03)
			box(st, Vector3(side * (HALF_W + depth * 0.5), CEIL * 0.5, zc), Vector3(depth, CEIL, 1.98), wall * shade)
			if rng.randf() < 0.35:
				var h := rng.randf_range(0.6, 2.4)
				box(st, Vector3(side * (HALF_W - 0.2), rng.randf_range(0.4, CEIL - 1.0), zc), Vector3(0.4, h, 1.8), wall * (shade * 0.94))
		# a glowing line along the foot of the wall, and one up the wall every 8 m
		box(em, Vector3(side * (HALF_W - 0.04), 0.05, z0 - 8.0), Vector3(0.07, 0.07, 16.0), acc)
		for k in 2:
			if rng.randf() < 0.7:
				box(em, Vector3(side * (HALF_W - 0.02), CEIL * 0.5, z0 - 4.0 - k * 8.0), Vector3(0.05, CEIL, 0.07), acc)
	# beams across the top (closed rooms have a roof of them, open ones just a few)
	var beams := 4 if not P.open else 2
	for k in beams:
		var zc := z0 - (k + 0.5) * (SEG / beams)
		box(st, Vector3(0, CEIL + 0.3, zc), Vector3(HALF_W * 2 + 2.8, 0.6, 0.7), wall * 0.82)
		if not P.open:
			box(em, Vector3(0, CEIL - 0.02, zc), Vector3(HALF_W * 2, 0.05, 0.08), acc)
	if not P.open:
		box(st, Vector3(0, CEIL + 0.9, z0 - SEG * 0.5), Vector3(HALF_W * 2 + 2.8, 0.3, SEG), wall * 0.7)
	st.set_material(wall_mat)
	var mesh := st.commit()
	em.set_material(glow_mat)
	em.commit(mesh)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
