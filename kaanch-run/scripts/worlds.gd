## The worlds you fly through, each from a real tradition of glass: a cathedral of stained glass, the canals
## of Venice, a night of paper lanterns, a Moroccan courtyard of mosaic and lamps, and a palace of mirrors.
## Each 16 m piece of a world is built from simple shapes in one go (a mesh or two), so it is light to draw.
class_name Worlds
extends RefCounted

const HALF_W := 4.6
const CEIL := 6.4
const SEG := 16.0

const LIST := ["cathedral", "venice", "lanterns", "mosaic", "sheesh"]
const DEFS := {
	"cathedral": {"name": "Cathedral", "bg": Color("120d18"), "amb": Color("4a3e52"), "sun": Color("ffd9a8"), "sun_e": 0.8, "rim": Color("eef6f4"), "fog": 0.024, "accent": Color("ffcf6b"), "dim": 0.6, "gdim": 0.55},
	"venice": {"name": "Venice", "bg": Color("1d3550"), "amb": Color("5a6e88"), "sun": Color("ffc9a0"), "sun_e": 0.75, "rim": Color("eef6f4"), "fog": 0.016, "accent": Color("ff8a5c"), "dim": 0.62, "gdim": 0.8},
	"lanterns": {"name": "Lantern Night", "bg": Color("05070f"), "amb": Color("2a3050"), "sun": Color("9fb2ff"), "sun_e": 0.45, "rim": Color("eef6f4"), "fog": 0.026, "accent": Color("ff9f45"), "dim": 0.7, "gdim": 0.75},
	"mosaic": {"name": "Mosaic Court", "bg": Color("3a2030"), "amb": Color("7a5a5a"), "sun": Color("ffb37a"), "sun_e": 0.8, "rim": Color("eef6f4"), "fog": 0.016, "accent": Color("1fb5b5"), "dim": 0.6, "gdim": 0.9},
	"sheesh": {"name": "Mirror Palace", "bg": Color("0c0306"), "amb": Color("4a2228"), "sun": Color("ffdca0"), "sun_e": 0.7, "rim": Color("eef6f4"), "fog": 0.024, "accent": Color("ffcc66"), "dim": 0.6, "gdim": 0.6},
}
# the colours of each world's tunnels, halls and skies
const TUNE := {
	"cathedral": {"wall": Color("3e352f"), "wall2": Color("cbbda4"), "floor_a": Color("bdb09a"), "floor_b": Color("8a7d6c"), "ground": Color("1a1420"), "lights": [Color("ffd27a"), Color("ffb05a")], "bits": [], "sky_top": Color("141a3c"), "sky_hor": Color("6a4460")},
	"venice": {"wall": Color("c9583f"), "wall2": Color("e9dcc4"), "floor_a": Color("e9dcc4"), "floor_b": Color("b9a88c"), "ground": Color("123a48"), "lights": [Color("ffe2a6"), Color("7fd8ff")], "bits": [], "sky_top": Color("10284a"), "sky_hor": Color("4a6a90")},
	"lanterns": {"wall": Color("c8302c"), "wall2": Color("1c1414"), "floor_a": Color("5a3f2c"), "floor_b": Color("4a3324"), "ground": Color("04060c"), "lights": [Color("ff9f45"), Color("ff6a4d"), Color("ffd27a")], "bits": [], "sky_top": Color("03050f"), "sky_hor": Color("1c1c44")},
	"mosaic": {"wall": Color("1d6fa3"), "wall2": Color("f0e2c8"), "floor_a": Color("c9744c"), "floor_b": Color("e2c9a6"), "ground": Color("3a2418"), "lights": [Color("ffcf7a"), Color("1fb5b5")], "bits": [Color("1fa58a"), Color("f2eadc")], "sky_top": Color("22163c"), "sky_hor": Color("7a4058")},
	"sheesh": {"wall": Color("3a0c14"), "wall2": Color("e8b64a"), "floor_a": Color("ece6dc"), "floor_b": Color("d9d2c6"), "ground": Color("12040a"), "lights": [Color("ffd896"), Color("fff0c8")], "bits": [Color("f4d27a"), Color("e8eef6")], "sky_top": Color("0e0512"), "sky_hor": Color("4a1a2a")},
}
# the two shapes of way in each 200 m room of a world (tunnel, hall or sky), two sets taken in turn
const SECT := {
	"cathedral": [["tunnel", "sky"], ["hall", "sky"]],
	"venice": [["hall", "sky"], ["tunnel", "sky"]],
	"lanterns": [["tunnel", "sky"], ["tunnel", "hall"]],
	"mosaic": [["hall", "tunnel"], ["hall", "sky"]],
	"sheesh": [["tunnel", "hall"], ["hall", "sky"]],
}
const HALL_W := 15.0
const T_C := Vector2(0, 3.0)   # the middle of a tunnel
const T_R := 5.9               # and its radius
const SKY_GROUND := -26.0

const JEWELS := [Color("e8283c"), Color("ffb020"), Color("2fbf6a"), Color("2f6fe0"), Color("9a45d8"), Color("f06aa8"), Color("20c4c4")]

static var lit_mat: StandardMaterial3D
static var glow_mat: StandardMaterial3D
static var shaft_mat: StandardMaterial3D
static var tex_mats := {}
static var _dim := 1.0
static var _gdim := 1.0


static func mats() -> void:
	if lit_mat:
		return
	lit_mat = StandardMaterial3D.new()
	lit_mat.vertex_color_use_as_albedo = true
	lit_mat.roughness = 0.85
	glow_mat = StandardMaterial3D.new()
	glow_mat.vertex_color_use_as_albedo = true
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft_mat = StandardMaterial3D.new()
	shaft_mat.vertex_color_use_as_albedo = true
	shaft_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shaft_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	shaft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	shaft_mat.no_depth_test = false


static func world_of(i: int) -> String:
	return LIST[posmod(i, LIST.size())]


static func def(w: String) -> Dictionary:
	return DEFS[w]


# ---------- textures, made once ----------
static func tex_mat(w: String) -> StandardMaterial3D:
	if tex_mats.has(w):
		return tex_mats[w]
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	if w == "mosaic":
		# zellige: an eight-pointed star in each tile, in blue, green, white and terracotta
		var cols := [Color("1d6fa3"), Color("1fa58a"), Color("f2eadc"), Color("c8643c"), Color("143c5e")]
		var T := 64
		for y in S:
			for x in S:
				var tx := x % T
				var ty := y % T
				var cell := (x / T) + (y / T) * 7
				var u := (tx - T * 0.5) / (T * 0.5)
				var v := (ty - T * 0.5) / (T * 0.5)
				var sq := maxf(absf(u), absf(v))
				var dia := (absf(u) + absf(v)) / 1.4142
				var star := minf(sq, dia)
				var c: Color
				if star < 0.42:
					c = cols[cell % 3]
				elif star < 0.5:
					c = Color("f6efe0")
				elif sq > 0.94:
					c = Color("d9cfbf")
				else:
					c = cols[3 + (cell % 2)]
				img.set_pixel(x, y, c)
	elif w == "sheesh":
		# mirror work: little silver and gold pieces set in deep red
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		img.fill(Color("5a1220"))
		for k in 900:
			var cx := rng.randi_range(0, S - 1)
			var cy := rng.randi_range(0, S - 1)
			var r := rng.randi_range(2, 5)
			var gold := rng.randf() < 0.35
			var base := Color("f4d27a") if gold else Color("e8eef6")
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) + absi(dy) > r:
						continue
					var sh := 0.75 + 0.25 * (1.0 - float(absi(dx) + absi(dy)) / r)
					img.set_pixel(posmod(cx + dx, S), posmod(cy + dy, S), base * sh)
	elif w == "shoji":
		img.fill(Color("efe4cc"))
		for y in S:
			for x in S:
				var n := 0.96 + 0.04 * sin(x * 0.7 + sin(y * 0.13) * 3.0)
				img.set_pixel(x, y, Color("efe4cc") * n)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.6 if w != "sheesh" else 0.25
	if w == "sheesh":
		m.metallic = 0.5
	if w == "shoji":
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.albedo_color = Color(_gdim, _gdim, _gdim) if w == "shoji" else Color(_dim, _dim, _dim)
	tex_mats[w] = m
	return m


# ---------- shapes ----------
const _FACES := [
	[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
	[Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
	[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)],
	[Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
	[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
]


## a box with its six faces; uv > 0 also gives it picture coordinates (uv metres per repeat)
static func box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color, uv := 0.0) -> void:
	var h := s * 0.5
	st.set_color(col)
	for f in _FACES:
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
		var verts := [a, cc, b, a, d, cc]
		for p in verts:
			if uv > 0.0:
				# picture coordinates from the face's own directions, in metres
				st.set_uv(Vector2(p.dot(u), -p.dot(v)) / uv)
			st.add_vertex(p)


## a flat four-sided shape (both sides drawn by the material)
static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, col2 = null) -> void:
	var n := (b - a).cross(c - a).normalized()
	st.set_normal(n)
	var c2: Color = col if col2 == null else col2
	st.set_color(col)
	st.add_vertex(a)
	st.set_color(c2)
	st.add_vertex(c)
	st.set_color(col)
	st.add_vertex(b)
	st.add_vertex(a)
	st.set_color(c2)
	st.add_vertex(d)
	st.add_vertex(c)


## a ring of small boxes along an arc (arches, frames)
static func arc_boxes(st: SurfaceTool, c: Vector3, r: float, a0: float, a1: float, n: int, thick: float, depth: float, col: Color) -> void:
	for i in n:
		var a := lerpf(a0, a1, (i + 0.5) / n)
		var p := c + Vector3(cos(a) * r, sin(a) * r, 0)
		var seg := r * absf(a1 - a0) / n * 1.15
		var b := Basis(Vector3(0, 0, 1), a + PI * 0.5)
		var bs := Basis().scaled(Vector3(seg, thick, depth))
		_box_xf(st, Transform3D(b * bs, p), col)


static func _box_xf(st: SurfaceTool, xf: Transform3D, col: Color) -> void:
	st.set_color(col)
	var nb := xf.basis.inverse().transposed()
	for f in _FACES:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var o := n * 0.5
		var pts := [o - u * 0.5 - v * 0.5, o + u * 0.5 + v * 0.5, o + u * 0.5 - v * 0.5, o - u * 0.5 - v * 0.5, o - u * 0.5 + v * 0.5, o + u * 0.5 + v * 0.5]
		st.set_normal((nb * n).normalized())
		for p in pts:
			st.add_vertex(xf * p)


# ---------- building a piece ----------
class Parts:
	var lit := SurfaceTool.new()
	var glow := SurfaceTool.new()
	var tex := SurfaceTool.new()
	var shaft := SurfaceTool.new()
	var n_lit := 0
	var n_glow := 0
	var n_tex := 0
	var n_shaft := 0

	func _init() -> void:
		lit.begin(Mesh.PRIMITIVE_TRIANGLES)
		glow.begin(Mesh.PRIMITIVE_TRIANGLES)
		tex.begin(Mesh.PRIMITIVE_TRIANGLES)
		shaft.begin(Mesh.PRIMITIVE_TRIANGLES)


static func build(w: String, d0: float, seed_v: int, sec := "corridor", prev := "corridor") -> Node3D:
	mats()
	var P := Parts.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var z0 := -d0
	if sec != "corridor":
		match sec:
			"tunnel":
				_tunnel(P, rng, z0, w)
			"hall":
				_hall(P, rng, z0, w)
			"sky":
				_sky(P, rng, z0, w)
	if sec != prev:
		_facade(P, z0, w, sec, prev)
	if sec == "corridor":
		_corridor(P, rng, z0, w)
	return _finish(P, w)


static func _corridor(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	match w:
		"cathedral":
			_cathedral(P, rng, z0)
		"venice":
			_venice(P, rng, z0)
		"lanterns":
			_lanterns(P, rng, z0)
		"mosaic":
			_mosaic(P, rng, z0)
		"sheesh":
			_sheesh(P, rng, z0)


static func _finish(P: Parts, w: String) -> Node3D:
	var mesh := ArrayMesh.new()
	if P.n_lit:
		P.lit.set_material(lit_mat)
		P.lit.commit(mesh)
	if P.n_glow:
		P.glow.set_material(glow_mat)
		P.glow.commit(mesh)
	if P.n_tex:
		P.tex.set_material(tex_mat("shoji" if w == "lanterns" else w))
		P.tex.commit(mesh)
	if P.n_shaft:
		P.shaft.set_material(shaft_mat)
		P.shaft.commit(mesh)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _floor_tiles(P: Parts, rng: RandomNumberGenerator, z0: float, a: Color, b: Color, var_k := 0.05) -> void:
	for xi in 4:
		for zi in 8:
			var x := -HALF_W + 1.15 + xi * 2.3
			var col := a if (xi + zi) % 2 == 0 else b
			box(P.lit, Vector3(x, -0.15, z0 - zi * 2.0 - 1.0), Vector3(2.26, 0.3, 1.96), col * rng.randf_range(1.0 - var_k, 1.0 + var_k))
			P.n_lit += 1


## a stained-glass window: little panes of colour inside a pointed arch, dark lead between them, lit from behind
static func _stained(P: Parts, rng: RandomNumberGenerator, x: float, zc: float, w: float, y0: float, y1: float, facing: float) -> void:
	var spring := y1 - w * 0.9
	var poly := Glass.arch(-w * 0.5, w * 0.5, y0, spring, 6)
	var cell := 0.3
	var pal := []
	for k in 4:
		pal.append(JEWELS[rng.randi_range(0, JEWELS.size() - 1)])
	# the dark lead behind
	var b := Glass.bounds(poly)
	for gy in int(b.size.y / cell) + 1:
		for gx in int(b.size.x / cell) + 1:
			var cx := b.position.x + (gx + 0.5) * cell
			var cy := b.position.y + (gy + 0.5) * cell
			if not Glass.inside(poly, Vector2(cx, cy), -0.05):
				continue
			var hw := cell * 0.42
			# a pattern: rings of colour round the middle of the window
			var ring := int(Vector2(cx, cy - (y0 + y1) * 0.5).length() / 0.55)
			var col: Color = pal[(ring + (1 if rng.randf() < 0.15 else 0)) % pal.size()]
			col = col * rng.randf_range(0.85, 1.15)
			var p := [Vector3(cx - hw, cy - hw, 0), Vector3(cx + hw, cy - hw, 0), Vector3(cx + hw, cy + hw, 0), Vector3(cx - hw, cy + hw, 0)]
			var q := []
			for v in p:
				q.append(Vector3(x, v.y, zc + v.x * facing))
			quad(P.glow, q[0], q[1], q[2], q[3], col)
			P.n_glow += 1
	# the dark lead behind the little panes
	box(P.lit, Vector3(x + signf(x) * 0.06, (y0 + y1) * 0.5, zc), Vector3(0.06, y1 - y0 + 0.2, w + 0.25), Color("1a1418"))
	P.n_lit += 1


## a soft beam of light slanting down from a window onto the floor
static func _shaft(P: Parts, x: float, zc: float, w: float, top: float, col: Color, side: float) -> void:
	var foot := x - side * 3.2
	var a := Vector3(x, top, zc - w * 0.5)
	var b := Vector3(x, top, zc + w * 0.5)
	var c := Vector3(foot, 0.02, zc + w * 0.5 + 0.8)
	var d := Vector3(foot, 0.02, zc - w * 0.5 + 0.8)
	quad(P.shaft, a, b, c, d, Color(col, 0.16), Color(col, 0.0))
	P.n_shaft += 1


static func _cathedral(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	_floor_tiles(P, rng, z0, Color("bdb09a"), Color("8a7d6c"))
	var stone := Color("cbbda4")
	var dark := Color("3e352f")
	for side in [-1.0, 1.0]:
		# the back wall, the columns in front of it, a window in each bay
		box(P.lit, Vector3(side * (HALF_W + 1.4), CEIL * 0.5 + 0.6, z0 - SEG * 0.5), Vector3(0.4, CEIL + 1.2, SEG), dark)
		P.n_lit += 1
		for k in 4:
			var zc := z0 - k * 4.0 - 2.0
			box(P.lit, Vector3(side * (HALF_W + 0.25), CEIL * 0.5 + 0.4, zc - 2.0 + 0.2), Vector3(0.42, CEIL + 0.8, 0.42), stone * rng.randf_range(0.92, 1.04))
			box(P.lit, Vector3(side * (HALF_W + 0.25), 0.25, zc - 2.0 + 0.2), Vector3(0.65, 0.5, 0.65), stone * 0.85)
			P.n_lit += 2
			_stained(P, rng, side * (HALF_W + 1.18), zc + 0.2, 3.0, 0.9, 6.3, side)
			if k % 2 == 0:
				_shaft(P, side * (HALF_W + 1.1), zc + 0.2, 2.2, 5.6, Color("ffd9a0"), side)
			# a candle glow at the foot of each column
			box(P.glow, Vector3(side * (HALF_W - 0.25), 0.62, zc - 2.0 + 0.4), Vector3(0.08, 0.22, 0.08), Color("ffe2a6"))
			P.n_glow += 1
	# ribs of the vault above
	for k in 4:
		var zc := z0 - k * 4.0 - 1.6
		arc_boxes(P.lit, Vector3(0, CEIL - 0.3, zc), HALF_W + 0.4, 0.15, PI - 0.15, 9, 0.35, 0.5, stone * 0.9)
		P.n_lit += 9
	box(P.lit, Vector3(0, CEIL + HALF_W + 0.4, z0 - SEG * 0.5), Vector3(HALF_W * 2 + 3.0, 0.4, SEG), Color("2b2430"))
	P.n_lit += 1


static func _venice(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	# the canal below
	box(P.lit, Vector3(0, -0.6, z0 - SEG * 0.5), Vector3(40, 0.2, SEG), Color("2f7f86"))
	for k in 6:
		box(P.glow, Vector3(rng.randf_range(-6, 6), -0.48, z0 - rng.randf_range(0, SEG)), Vector3(rng.randf_range(0.8, 2.4), 0.01, 0.05), Color("7fc8c4"))
	P.n_lit += 1
	P.n_glow += 6
	var cols := [Color("d9774f"), Color("e8b25c"), Color("e9a3a0"), Color("efe2c8"), Color("c9583f"), Color("f0c987")]
	for side in [-1.0, 1.0]:
		var z := z0
		while z > z0 - SEG + 0.1:
			var wdt := minf(rng.randf_range(3.0, 5.0), z - (z0 - SEG))
			var h := rng.randf_range(7.0, 12.0)
			var col: Color = cols[rng.randi_range(0, cols.size() - 1)]
			var xf: float = side * (HALF_W + 1.6)
			box(P.lit, Vector3(xf + side * 1.0, h * 0.5 - 0.5, z - wdt * 0.5), Vector3(2.0, h, wdt - 0.05), col)
			P.n_lit += 1
			# windows with white frames, floor by floor
			var floors := int((h - 1.5) / 2.2)
			for f in floors:
				var wy := 1.6 + f * 2.2
				var nwin := maxi(1, int(wdt / 1.4))
				for i in nwin:
					var wz := z - (i + 0.5) * wdt / nwin
					box(P.lit, Vector3(xf - side * 0.01, wy, wz), Vector3(0.05, 1.3, 0.75), Color("f4efe6"))
					box(P.lit, Vector3(xf - side * 0.04, wy - 0.05, wz), Vector3(0.05, 1.05, 0.55), Color("2c2a33"))
					P.n_lit += 2
			z -= wdt
		# striped mooring poles in the water
		for k in 2:
			var pz := z0 - rng.randf_range(1.0, SEG - 1.0)
			var px: float = side * rng.randf_range(HALF_W - 0.6, HALF_W + 0.6)
			var pc: Color = [Color("c8302c"), Color("1f4fa0")][rng.randi_range(0, 1)]
			for s in 6:
				box(P.lit, Vector3(px, -0.4 + s * 0.6 + 0.3, pz), Vector3(0.18, 0.6, 0.18), pc if s % 2 == 0 else Color("f4f0e8"))
				P.n_lit += 1
	# now and then a little bridge over the canal
	if rng.randf() < 0.45:
		var bz := z0 - rng.randf_range(4.0, 12.0)
		arc_boxes(P.lit, Vector3(0, 4.6, bz), HALF_W + 1.2, 0.35, PI - 0.35, 11, 0.5, 2.2, Color("e9dcc4"))
		box(P.lit, Vector3(0, 7.2, bz), Vector3(HALF_W * 2 + 4.0, 0.4, 2.4), Color("d8c8ae"))
		P.n_lit += 12


static func _lanterns(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	# a boardwalk of dark planks over black water
	for zi in 16:
		box(P.lit, Vector3(0, -0.12, z0 - zi - 0.5), Vector3(HALF_W * 2 + 0.6, 0.18, 0.92), Color("5a3f2c") * rng.randf_range(0.8, 1.1))
		P.n_lit += 1
	box(P.lit, Vector3(0, -0.6, z0 - SEG * 0.5), Vector3(40, 0.2, SEG), Color("060912"))
	P.n_lit += 1
	for side in [-1.0, 1.0]:
		# paper walls, glowing softly, in dark wooden frames
		for k in 8:
			var zc := z0 - k * 2.0 - 1.0
			var x: float = side * (HALF_W + 0.5)
			box(P.tex, Vector3(x, 2.2, zc), Vector3(0.06, 3.6, 1.9), Color("ffe6bf") * 0.9, 1.0)
			P.n_tex += 1
			for g in 3:
				box(P.lit, Vector3(x - side * 0.04, 2.2, zc - 0.95 + (g + 1) * 0.475), Vector3(0.05, 3.6, 0.05), Color("2a1c14"))
			for g in 4:
				box(P.lit, Vector3(x - side * 0.04, 0.4 + g * 1.2, zc), Vector3(0.05, 0.05, 1.9), Color("2a1c14"))
			P.n_lit += 7
		box(P.lit, Vector3(side * (HALF_W + 0.5), 4.1, z0 - SEG * 0.5), Vector3(0.3, 0.25, SEG), Color("2a1c14"))
		P.n_lit += 1
	# red gates every 8 m, with lanterns hanging from them
	for k in 2:
		var gz := z0 - k * 8.0 - 4.0
		for side in [-1.0, 1.0]:
			box(P.lit, Vector3(side * (HALF_W - 0.2), CEIL * 0.5, gz), Vector3(0.45, CEIL, 0.45), Color("c8302c"))
			P.n_lit += 1
		box(P.lit, Vector3(0, CEIL - 0.3, gz), Vector3(HALF_W * 2 + 1.4, 0.4, 0.5), Color("c8302c"))
		box(P.lit, Vector3(0, CEIL + 0.15, gz), Vector3(HALF_W * 2 + 2.4, 0.35, 0.7), Color("1c1414"))
		P.n_lit += 2
		for i in 5:
			var lx := -3.6 + i * 1.8 + rng.randf_range(-0.3, 0.3)
			var drop := rng.randf_range(0.6, 1.6)
			var ly := CEIL - 0.5 - drop
			box(P.lit, Vector3(lx, ly + drop * 0.5 + 0.35, gz), Vector3(0.02, drop, 0.02), Color("222222"))
			var lc: Color = [Color("ff9f45"), Color("ff6a4d"), Color("ffd27a")][rng.randi_range(0, 2)]
			box(P.glow, Vector3(lx, ly, gz), Vector3(0.42, 0.62, 0.42), lc)
			box(P.lit, Vector3(lx, ly + 0.34, gz), Vector3(0.3, 0.06, 0.3), Color("1c1414"))
			box(P.lit, Vector3(lx, ly - 0.34, gz), Vector3(0.3, 0.06, 0.3), Color("1c1414"))
			P.n_glow += 1
			P.n_lit += 3


static func _mosaic(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	_floor_tiles(P, rng, z0, Color("c9744c"), Color("e2c9a6"), 0.04)
	for side in [-1.0, 1.0]:
		# tiled walls up to the shoulder, plain plaster above
		box(P.tex, Vector3(side * (HALF_W + 0.4), 1.4, z0 - SEG * 0.5), Vector3(0.3, 2.8, SEG), Color(1, 1, 1), 1.0)
		box(P.lit, Vector3(side * (HALF_W + 0.5), 5.0, z0 - SEG * 0.5), Vector3(0.3, 4.4, SEG), Color("f0e2c8"))
		box(P.lit, Vector3(side * (HALF_W + 0.3), 2.85, z0 - SEG * 0.5), Vector3(0.2, 0.12, SEG), Color("1d6fa3"))
		P.n_tex += 1
		P.n_lit += 2
		# horseshoe arches on slim columns
		for k in 2:
			var zc := z0 - k * 8.0 - 4.0
			arc_boxes(P.lit, Vector3(side * (HALF_W + 0.1), 3.6, zc), 1.6, -0.6, PI + 0.6, 11, 0.28, 0.35, Color("f6ecda"))
			P.n_lit += 11
	# lamps of coloured glass hanging over the way
	for i in 3:
		var lx := rng.randf_range(-3.0, 3.0)
		var lz := z0 - rng.randf_range(1.0, SEG - 1.0)
		var drop := rng.randf_range(0.8, 2.0)
		box(P.lit, Vector3(lx, CEIL + 0.6 - drop * 0.5, lz), Vector3(0.02, drop, 0.02), Color("3a2a1a"))
		var lc: Color = JEWELS[rng.randi_range(0, JEWELS.size() - 1)]
		box(P.glow, Vector3(lx, CEIL + 0.4 - drop, lz), Vector3(0.36, 0.36, 0.36), lc)
		box(P.lit, Vector3(lx, CEIL + 0.62 - drop, lz), Vector3(0.22, 0.12, 0.22), Color("b8893a"))
		P.n_lit += 2
		P.n_glow += 1


static func _sheesh(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	# white marble with gold lines
	_floor_tiles(P, rng, z0, Color("ece6dc"), Color("d9d2c6"), 0.03)
	for k in 3:
		box(P.glow, Vector3(0, 0.005, z0 - k * 5.3 - 2.0), Vector3(HALF_W * 2 - 0.4, 0.02, 0.06), Color("e8b64a"))
		P.n_glow += 1
	for side in [-1.0, 1.0]:
		# walls of mirror work
		box(P.tex, Vector3(side * (HALF_W + 0.4), CEIL * 0.5, z0 - SEG * 0.5), Vector3(0.3, CEIL, SEG), Color(1, 1, 1), 0.9)
		P.n_tex += 1
		for k in 4:
			var zc := z0 - k * 4.0 - 2.0
			# gold-edged niches with a cusped arch
			arc_boxes(P.glow, Vector3(side * (HALF_W + 0.22), 3.2, zc), 1.1, 0.0, PI, 9, 0.07, 0.07, Color("ffcc66"))
			box(P.glow, Vector3(side * (HALF_W + 0.22), 1.6, zc - 1.1), Vector3(0.07, 3.2, 0.07), Color("ffcc66"))
			box(P.glow, Vector3(side * (HALF_W + 0.22), 1.6, zc + 1.1), Vector3(0.07, 3.2, 0.07), Color("ffcc66"))
			P.n_glow += 11
			# a small lamp in each niche
			box(P.glow, Vector3(side * (HALF_W + 0.05), 2.2, zc), Vector3(0.18, 0.26, 0.18), Color("ffd896"))
			P.n_glow += 1
	box(P.lit, Vector3(0, CEIL + 0.2, z0 - SEG * 0.5), Vector3(HALF_W * 2 + 1.0, 0.4, SEG), Color("3a0c14"))
	for k in 4:
		box(P.glow, Vector3(0, CEIL - 0.02, z0 - k * 4.0 - 2.0), Vector3(HALF_W * 2, 0.05, 0.08), Color("e8b64a"))
		P.n_glow += 1
	P.n_lit += 1


# ---------- the other shapes of the way ----------
## how bright the world's own shapes are (the glass stays bright), set as you go from one world to the next
static func set_dim(dim: float, gdim: float) -> void:
	mats()
	_dim = dim
	_gdim = gdim
	lit_mat.albedo_color = Color(dim, dim, dim)
	glow_mat.albedo_color = Color(gdim, gdim, gdim)
	shaft_mat.albedo_color = Color(gdim, gdim, gdim)
	for k in tex_mats:
		var m: StandardMaterial3D = tex_mats[k]
		m.albedo_color = Color(dim, dim, dim) if k != "shoji" else Color(gdim, gdim, gdim)


## where one shape of the way meets another: a wall across it, with an opening the size of the corridor
static func _facade(P: Parts, z: float, w: String, a: String, b: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var ow := HALF_W + 0.3
	var oh := CEIL + 0.3
	var wall: Color = T.wall * 0.8
	var big := 18.0 if (a == "hall" or b == "hall") else 9.0
	var low := -1.0
	var top := 8.0
	if a == "sky" or b == "sky":
		# the end of a building floating in the sky: just a thick edge round the opening
		big = 2.2
		low = -2.4
		top = 1.8
	box(P.lit, Vector3(-ow - big * 0.5, (oh + top + low) * 0.5, z), Vector3(big, oh + top - low, 0.8), wall)
	box(P.lit, Vector3(ow + big * 0.5, (oh + top + low) * 0.5, z), Vector3(big, oh + top - low, 0.8), wall)
	box(P.lit, Vector3(0, oh + top * 0.5, z), Vector3(ow * 2.0 + 0.2, top, 0.8), wall)
	if low < -1.0:
		box(P.lit, Vector3(0, (low - 0.4) * 0.5, z), Vector3(ow * 2.0 + 0.2, -low - 0.4, 0.8), wall * 0.8)
		P.n_lit += 1
	P.n_lit += 3
	# a bright frame round the opening, so you see the change coming
	box(P.glow, Vector3(0, oh, z + 0.45), Vector3(ow * 2.0 + 0.3, 0.16, 0.1), acc)
	box(P.glow, Vector3(-ow, oh * 0.5 - 0.1, z + 0.45), Vector3(0.16, oh + 0.2, 0.1), acc)
	box(P.glow, Vector3(ow, oh * 0.5 - 0.1, z + 0.45), Vector3(0.16, oh + 0.2, 0.1), acc)
	P.n_glow += 3


## a round tunnel: rings of the world's colour, thin bright rings between them
static func _tunnel(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var a0 := -asin(T_C.y / T_R) - 0.02
	var a1 := PI - a0
	var c3 := Vector3(T_C.x, T_C.y, 0)
	# the floor
	for zi in 8:
		var col: Color = T.floor_a if zi % 2 == 0 else T.floor_b
		box(P.lit, Vector3(0, -0.15, z0 - zi * 2.0 - 1.0), Vector3(T_R * 2.0, 0.3, 1.96), col * rng.randf_range(0.95, 1.05))
		P.n_lit += 1
	# glowing strips along the foot of the walls
	for sd in [-1.0, 1.0]:
		box(P.glow, Vector3(sd * (T_R - 0.9), 0.04, z0 - SEG * 0.5), Vector3(0.1, 0.05, SEG), acc)
		P.n_glow += 1
	for k in 8:
		var zc := z0 - k * 2.0 - 1.0
		var main: Color = T.wall if k % 2 == 0 else T.wall * 0.8
		if w == "lanterns":
			# a tunnel of red gates, close together
			main = T.wall if k % 2 == 0 else Color("1c1414")
		arc_boxes(P.lit, c3 + Vector3(0, 0, zc), T_R, a0, a1, 16, 0.4, 1.94, main)
		P.n_lit += 16
		if k % 2 == 0:
			arc_boxes(P.glow, c3 + Vector3(0, 0, zc - 1.0), T_R - 0.22, a0 + 0.05, a1 - 0.05, 22, 0.07, 0.1, acc)
			P.n_glow += 22
	# little bright bits set in the walls (mirror work, tiles)
	var bits: Array = T.bits
	if bits.size():
		for i in 26:
			var a := rng.randf_range(a0 + 0.1, a1 - 0.1)
			var p := c3 + Vector3(cos(a) * (T_R - 0.22), sin(a) * (T_R - 0.22), z0 - rng.randf_range(0.2, SEG - 0.2))
			box(P.glow, p, Vector3(0.14, 0.14, 0.14), bits[i % bits.size()])
			P.n_glow += 1


## a great hall: a wide floor, two rows of tall columns, tall windows far off at the sides
static func _hall(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	for xi in 8:
		for zi in 4:
			var x := -HALL_W + 1.875 + xi * 3.75
			var col: Color = T.floor_a if (xi + zi) % 2 == 0 else T.floor_b
			box(P.lit, Vector3(x, -0.15, z0 - zi * 4.0 - 2.0), Vector3(3.72, 0.3, 3.96), col * rng.randf_range(0.95, 1.05))
			P.n_lit += 1
	for sd in [-1.0, 1.0]:
		box(P.lit, Vector3(sd * (HALL_W + 0.5), 7.0, z0 - SEG * 0.5), Vector3(0.6, 16.0, SEG), T.wall * 0.7)
		P.n_lit += 1
		for k in 2:
			var zc := z0 - k * 8.0 - 4.0
			# a tall column with a bright band at its head
			box(P.lit, Vector3(sd * 8.0, 6.0, zc), Vector3(0.9, 12.0, 0.9), T.wall2 * rng.randf_range(0.9, 1.0))
			box(P.lit, Vector3(sd * 8.0, 0.3, zc), Vector3(1.3, 0.6, 1.3), T.wall2 * 0.8)
			box(P.glow, Vector3(sd * 8.0, 11.6, zc), Vector3(1.0, 0.12, 1.0), acc)
			P.n_lit += 2
			P.n_glow += 1
			# a tall window far off in the side wall
			var lc: Color = T.lights[rng.randi_range(0, T.lights.size() - 1)]
			box(P.glow, Vector3(sd * (HALL_W + 0.15), 6.5, zc - 4.0), Vector3(0.08, 7.0, 1.6), lc * 0.8)
			P.n_glow += 1
	box(P.lit, Vector3(0, 14.5, z0 - SEG * 0.5), Vector3(HALL_W * 2.0 + 2.0, 0.6, SEG), T.wall * 0.4)
	P.n_lit += 1


## open sky: the ground far below with its lights, and tall pillars rising from it to rush past
static func _sky(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	box(P.lit, Vector3(0, SKY_GROUND, z0 - SEG * 0.5), Vector3(160.0, 0.4, SEG), T.ground)
	P.n_lit += 1
	for i in 26:
		var lc: Color = T.lights[i % T.lights.size()]
		var x := rng.randf_range(-70.0, 70.0)
		if absf(x) < 3.0:
			x += 6.0 * signf(x + 0.01)
		box(P.glow, Vector3(x, SKY_GROUND + 0.3, z0 - rng.randf_range(0.0, SEG)), Vector3(0.5, 0.3, 0.5), lc)
		P.n_glow += 1
	for k in 2:
		if rng.randf() < 0.6:
			var sd := -1.0 if rng.randf() < 0.5 else 1.0
			var x := sd * rng.randf_range(16.0, 40.0)
			var top := rng.randf_range(-10.0, 6.0)
			var zc := z0 - rng.randf_range(1.0, SEG - 1.0)
			var wdt := rng.randf_range(1.2, 2.4)
			box(P.lit, Vector3(x, (SKY_GROUND + top) * 0.5, zc), Vector3(wdt, top - SKY_GROUND, wdt), T.wall * rng.randf_range(0.8, 1.0))
			box(P.glow, Vector3(x, top + 0.1, zc), Vector3(wdt + 0.2, 0.2, wdt + 0.2), acc)
			P.n_lit += 1
			P.n_glow += 1
