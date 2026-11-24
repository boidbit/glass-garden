## The worlds you fly through, five worlds of glass and light made up for the game (no real place):
## a neon city at night, glass towers over the sea, a night of aurora lights, a solar city in the dunes,
## and caves of ice. Each 16 m piece of a world is built from simple shapes in one go (a mesh or two), so it is light to draw.
class_name Worlds
extends RefCounted

const HALF_W := 6.4
const CEIL := 7.4
const SEG := 16.0

const LIST := ["neon", "ocean", "aurora", "dunes", "ice"]
const DEFS := {
	"neon": {"bg": Color("0a0614"), "amb": Color("3a2a5a"), "sun": Color("c8a0ff"), "sun_e": 0.7, "rim": Color("eef6f4"), "fog": 0.024, "accent": Color("ff3fd0"), "dim": 0.6, "gdim": 0.7},
	"ocean": {"bg": Color("0c2a40"), "amb": Color("4a6a88"), "sun": Color("bfe8ff"), "sun_e": 0.8, "rim": Color("eef6f4"), "fog": 0.016, "accent": Color("3fe0ff"), "dim": 0.62, "gdim": 0.8},
	"aurora": {"bg": Color("03080c"), "amb": Color("1e3a40"), "sun": Color("9fffd8"), "sun_e": 0.5, "rim": Color("eef6f4"), "fog": 0.026, "accent": Color("5fffb0"), "dim": 0.7, "gdim": 0.75},
	"dunes": {"bg": Color("2a1608"), "amb": Color("7a5a3a"), "sun": Color("ffc27a"), "sun_e": 0.9, "rim": Color("eef6f4"), "fog": 0.016, "accent": Color("ff9a2a"), "dim": 0.6, "gdim": 0.85},
	"ice": {"bg": Color("060a18"), "amb": Color("2a3a5a"), "sun": Color("d8f0ff"), "sun_e": 0.75, "rim": Color("eef6f4"), "fog": 0.022, "accent": Color("9fd8ff"), "dim": 0.6, "gdim": 0.65},
}
# the colours of each world's tunnels, halls and skies
const TUNE := {
	"neon": {"wall": Color("2a2440"), "wall2": Color("6a6a88"), "floor_a": Color("3a3848"), "floor_b": Color("26242f"), "ground": Color("08060f"), "lights": [Color("ff3fd0"), Color("3fe0ff")], "bits": [Color("ff3fd0"), Color("3fe0ff")], "sky_top": Color("0a0620"), "sky_hor": Color("4a1a5a")},
	"ocean": {"wall": Color("2a5a78"), "wall2": Color("c8dde8"), "floor_a": Color("b8c8d0"), "floor_b": Color("8aa0ac"), "ground": Color("0a3040"), "lights": [Color("bfefff"), Color("3fe0ff")], "bits": [], "sky_top": Color("0a2848"), "sky_hor": Color("4a7a9a")},
	"aurora": {"wall": Color("1e3038"), "wall2": Color("4a5a62"), "floor_a": Color("3a4248"), "floor_b": Color("2a3238"), "ground": Color("02060a"), "lights": [Color("5fffb0"), Color("9f7fff"), Color("3fe0ff")], "bits": [], "sky_top": Color("02060f"), "sky_hor": Color("1a3a4a")},
	"dunes": {"wall": Color("a8683a"), "wall2": Color("e8d0a8"), "floor_a": Color("d8a870"), "floor_b": Color("c09060"), "ground": Color("3a2414"), "lights": [Color("ffcf7a"), Color("ff9a2a")], "bits": [Color("ffcf7a"), Color("f2eadc")], "sky_top": Color("2a1a3c"), "sky_hor": Color("b0603a")},
	"ice": {"wall": Color("1a2a48"), "wall2": Color("c8e0f0"), "floor_a": Color("dde8f0"), "floor_b": Color("c0d0dc"), "ground": Color("060a14"), "lights": [Color("d8f0ff"), Color("9fd8ff")], "bits": [Color("9fd8ff"), Color("e8f4ff")], "sky_top": Color("060a20"), "sky_hor": Color("2a3a6a")},
}
# the two shapes of way in each 200 m room of a world (tunnel, hall or sky), two sets taken in turn
const SECT := {
	"neon": [["tunnel", "sky"], ["hall", "sky"]],
	"ocean": [["hall", "sky"], ["tunnel", "sky"]],
	"aurora": [["tunnel", "sky"], ["tunnel", "hall"]],
	"dunes": [["hall", "tunnel"], ["hall", "sky"]],
	"ice": [["tunnel", "hall"], ["hall", "sky"]],
}
const HALL_W := 18.0
# rooms with no walls or roof, open to the sky and the far skyline
const OPEN := [2, 5, 7]
const T_C := Vector2(0, 3.4)   # the middle of a tunnel
const T_R := 7.6               # and its radius
const SKY_GROUND := -26.0

# ten moods for each world, one for each of its rooms, so every room has its own light:
# [colour of the walls, colour of the lamps, sky, ambient light, sun, sun strength, haze, sky above, horizon]
const MOODS := {
	"neon": [
		["999999", "8c8c8c", "120d18", "4a3e52", "ffd9a8", 0.8, 0.024, "141a3c", "6a4460"],
		["6a7a8a", "5a6a80", "06080c", "2a3448", "9fb8ff", 0.5, 0.03, "0a1020", "2a3450"],
		["c8a070", "d8b070", "2a1808", "7a5a3a", "ffc070", 1.1, 0.02, "3a2a50", "c07848"],
		["b07888", "c890a8", "1e0a14", "6a3a50", "ffa0c0", 0.9, 0.022, "2a1030", "8a4060"],
		["a07a50", "ffc070", "0c0604", "3a2818", "ffb060", 0.7, 0.03, "1a1008", "6a4020"],
		["6a80b0", "7a9ae0", "060a1a", "2a3a6a", "a0c0ff", 0.7, 0.024, "0a1440", "3a5a9a"],
		["b06048", "ff7a50", "1a0604", "5a2418", "ff8a60", 0.9, 0.024, "2a0a10", "8a3020"],
		["c0c4c8", "b0c0d0", "2a3038", "8a929a", "ffffff", 1.1, 0.016, "4a6a90", "b8c8d8"],
		["70a088", "70d0a0", "04140c", "2a5a44", "b0ffd0", 0.8, 0.024, "082a20", "2a7a5a"],
		["c09060", "ffd070", "1a0e04", "6a4a28", "ffd890", 1.1, 0.02, "2a1a40", "b07040"],
	],
	"ocean": [
		["9a9eaa", "a0b0c0", "1d3550", "5a6e88", "ffc9a0", 0.75, 0.016, "10284a", "4a6a90"],
		["c08060", "ff9050", "2a1008", "7a4a30", "ffa070", 1.0, 0.018, "3a1a20", "c06040"],
		["c8ccd0", "c0d0e0", "5a8ab0", "a0b8c8", "ffffff", 1.3, 0.01, "3a7ab8", "a8d0e8"],
		["b070a0", "e080c0", "200a24", "6a3a6a", "ff90d0", 0.9, 0.02, "2a0a3a", "7a3a7a"],
		["a0a8a8", "b0c0c0", "4a5a60", "8a9898", "e0e8e8", 0.8, 0.03, "5a6a70", "8a9a9a"],
		["5a6a90", "8090d0", "060c1e", "2a3458", "a0b0ff", 0.55, 0.02, "040a24", "1c2a5a"],
		["c0a060", "ffd070", "281a06", "7a6030", "ffd890", 1.1, 0.016, "3a2a1a", "b08a40"],
		["c07040", "ff8030", "1a0804", "5a3018", "ff9040", 1.0, 0.02, "2a1408", "9a4a20"],
		["70a0a0", "70d0c8", "062420", "2a6060", "b0fff0", 0.8, 0.018, "0a3a3a", "3a8a80"],
		["a090b0", "ffd8a0", "120a20", "4a3a5a", "ffd8a0", 0.9, 0.018, "1a1040", "6a4a7a"],
	],
	"aurora": [
		["9a9a9a", "b0b0b0", "05070f", "2a3050", "9fb2ff", 0.45, 0.026, "03050f", "1c1c44"],
		["c06050", "ff7050", "140404", "5a2020", "ffa080", 0.7, 0.024, "1a0408", "5a1a20"],
		["8090b0", "a0b8e0", "081020", "3a4870", "d0e0ff", 0.8, 0.02, "0a1430", "3a4a80"],
		["c09050", "ffb050", "180c04", "6a4a24", "ffc070", 0.9, 0.022, "1a0c20", "7a4030"],
		["90a890", "a0c8a0", "0c1a10", "4a6a50", "d0ffd0", 0.7, 0.03, "102018", "4a6a50"],
		["9a6a9a", "d090d0", "120614", "4a2a4a", "e0a0ff", 0.6, 0.024, "140820", "4a2050"],
		["c0c8d0", "d0e0f0", "2a3040", "7a8898", "ffffff", 0.9, 0.026, "3a4a60", "9aaabb"],
		["70805a", "d0ff70", "060a04", "2a3a20", "c0ff80", 0.5, 0.026, "04080a", "1a2a20"],
		["b09080", "ffc0a0", "2a1a1a", "7a5a50", "ffc0a0", 0.9, 0.02, "2a2040", "b07a70"],
		["b04030", "ff6030", "100202", "4a1a10", "ff7040", 0.8, 0.024, "1a0404", "6a1a10"],
	],
	"dunes": [
		["8098b8", "80c0e0", "0a1830", "3a5a7a", "d0e8ff", 0.85, 0.016, "10204a", "3a6aa0"],
		["d0b090", "f0d0a0", "a07850", "d0b090", "fff0d0", 1.3, 0.01, "6a90c0", "f0c890"],
		["c09040", "ffc040", "2a1804", "7a5a20", "ffc060", 1.0, 0.016, "3a2010", "b07020"],
		["a07080", "e090a0", "3a2030", "7a5a5a", "ffb37a", 0.8, 0.016, "22163c", "7a4058"],
		["60a8a8", "60e0d8", "04201e", "2a6a68", "b0fff8", 0.85, 0.016, "083030", "2a8a80"],
		["b07850", "ffa050", "1a0a04", "5a3a20", "ffb060", 0.8, 0.02, "1a0a1a", "7a4030"],
		["5a6aa0", "8090ff", "060820", "2a3060", "a0b0ff", 0.6, 0.02, "060a30", "2a3a80"],
		["c08890", "ffa0b0", "2a1018", "7a4a50", "ffc0c8", 0.9, 0.016, "3a1a3a", "a05a70"],
		["b09878", "d0b890", "5a4430", "9a8468", "ffe0b0", 0.9, 0.035, "7a6448", "b09878"],
		["8a8aa0", "c0c0ff", "0a0a18", "3a3a58", "e0e0ff", 0.7, 0.018, "0a0a28", "3a3a6a"],
	],
	"ice": [
		["999999", "999999", "0c0306", "4a2228", "ffdca0", 0.7, 0.024, "0e0512", "4a1a2a"],
		["c0a050", "ffd060", "1a1004", "6a5020", "ffd890", 1.0, 0.02, "2a1a08", "8a6020"],
		["a8b0c0", "d0e0ff", "0a0e18", "4a5068", "e8f0ff", 0.8, 0.02, "0c1428", "4a5a80"],
		["b04050", "ff6070", "180408", "5a1a24", "ff8090", 0.8, 0.024, "200410", "6a1a2a"],
		["b08050", "ffb050", "120804", "4a3018", "ffc070", 0.8, 0.026, "1a0c08", "6a3a18"],
		["4a8a90", "50d0c0", "041414", "1a4a4a", "a0fff0", 0.8, 0.02, "041c24", "1a5a6a"],
		["d0ccc4", "e0dcd0", "6a6458", "b0aa9a", "ffffff", 1.2, 0.014, "8aa0c0", "e0d8c8"],
		["c07050", "ff9060", "2a0c06", "7a3a24", "ffa070", 1.0, 0.02, "2a0a24", "a04a30"],
		["60a070", "70e090", "041808", "2a5a30", "b0ffc0", 0.8, 0.02, "082010", "2a6a3a"],
		["b0a080", "fff0c0", "100a06", "5a4a30", "fff0c8", 1.0, 0.02, "1a1020", "8a6a50"],
	],
}


## the light of one room: the world's own, with that room's mood over it
static func look(w: String, mood: int) -> Dictionary:
	var D: Dictionary = DEFS[w]
	var T: Dictionary = TUNE[w]
	var m: Array = MOODS[w][posmod(mood, 10)]
	return {"tint": Color(m[0]), "gtint": Color(m[1]), "bg": Color(m[2]), "amb": Color(m[3]), "sun": Color(m[4]), "sun_e": m[5], "fog": m[6],
		"sky_top": Color(m[7]), "sky_hor": Color(m[8]), "ground": T.ground, "rim": D.rim}

const JEWELS := [Color("e8283c"), Color("ffb020"), Color("2fbf6a"), Color("2f6fe0"), Color("9a45d8"), Color("f06aa8"), Color("20c4c4")]

static var lit_mat: StandardMaterial3D
static var glow_mat: StandardMaterial3D
static var shaft_mat: StandardMaterial3D
static var tex_mats := {}
static var _tint := Color(0.6, 0.6, 0.6)
static var _gtint := Color(0.6, 0.6, 0.6)


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
# the picture is drawn by tex_image(), which only touches an Image, so a worker thread can draw it while the way
# ahead is built (see shapes()); the material round it is made on the main thread, the first time it is shown
static var _tex_imgs := {}
static var _tex_lock := Mutex.new()


static func tex_mat(w: String) -> StandardMaterial3D:
	if tex_mats.has(w):
		return tex_mats[w]
	var m := _tex_material(w, tex_image(w))
	tex_mats[w] = m
	return m


## the same look round a blank little picture: drawn once as the game starts, so its shader is made then (Game._warm_up)
static func tex_like(w: String) -> StandardMaterial3D:
	var img := Image.create(4, 4, true, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	return _tex_material(w, img)


static func _tex_material(w: String, img: Image) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.6 if w != "ice" else 0.2
	if w == "ice":
		m.metallic = 0.5
	if w == "panel":
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.albedo_color = _gtint if w == "panel" else _tint
	return m


## a world's picture, drawn once (on whichever thread asks first)
static func tex_image(w: String) -> Image:
	_tex_lock.lock()
	var img: Image = _tex_imgs.get(w)
	_tex_lock.unlock()
	if img != null:
		return img
	img = _draw_tex(w)
	_tex_lock.lock()
	if not _tex_imgs.has(w):
		_tex_imgs[w] = img
	img = _tex_imgs[w]
	_tex_lock.unlock()
	return img


static func _draw_tex(w: String) -> Image:
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	if w == "dunes":
		# panels of a solar city: sandstone squares, each with a dark seam round it and a bright cell in the middle
		var T := 32
		for y in S:
			for x in S:
				var tx := x % T
				var ty := y % T
				var cell := (x / T) + (y / T) * 9
				var c: Color = Color("d8b080") if cell % 2 == 0 else Color("c8a070")
				if tx < 2 or ty < 2:
					c = Color("6a4a2a")
				elif tx > 9 and tx < 22 and ty > 9 and ty < 22:
					c = Color("ffcf7a") if cell % 3 == 0 else Color("e8c898")
				elif (tx + ty) % 11 == 0:
					c = c.darkened(0.08)
				img.set_pixel(x, y, c)
	elif w == "ice":
		# ice: little bright facets of silver and pale blue, set in deep blue
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		img.fill(Color("14204a"))
		for k in 900:
			var cx := rng.randi_range(0, S - 1)
			var cy := rng.randi_range(0, S - 1)
			var r := rng.randi_range(2, 5)
			var pale := rng.randf() < 0.4
			var base := Color("9fd8ff") if pale else Color("e8f4ff")
			for dy in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) + absi(dy) > r:
						continue
					var sh := 0.75 + 0.25 * (1.0 - float(absi(dx) + absi(dy)) / r)
					img.set_pixel(posmod(cx + dx, S), posmod(cy + dy, S), base * sh)
	elif w == "panel":
		# frosted light panels: soft, with fine lines across
		for y in S:
			for x in S:
				var n := 0.93 + 0.05 * sin(y * 0.4) + 0.02 * sin(x * 0.11 + y * 0.03)
				img.set_pixel(x, y, Color("f2f6f8") * n)
	img.generate_mipmaps()
	return img


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


static func build(w: String, d0: float, seed_v: int, sec := "corridor", prev := "corridor", variant := 0, roof := true) -> Node3D:
	return finish(shapes(w, d0, seed_v, sec, prev, variant, roof))


## a piece of the way in two halves. shapes(): every vertex of it, as arrays, and its picture drawn, with no call
## to the graphics server at all, so it can run on a worker thread; finish(): the mesh made from them (quick)
static func shapes(w: String, d0: float, seed_v: int, sec := "corridor", prev := "corridor", variant := 0, roof := true) -> Dictionary:
	var P := Parts.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var z0 := -d0
	if sec != "corridor":
		match sec:
			"tunnel":
				_tunnel(P, rng, z0, w)
			"hall":
				_hall(P, rng, z0, w, roof)
			"sky":
				_sky(P, rng, z0, w)
	if sec != prev:
		_facade(P, z0, w, sec, prev)
	if sec == "corridor":
		if variant in OPEN:
			_open(P, rng, z0, w, variant)
		else:
			_corridor(P, rng, z0, w)
	if sec == "corridor" or sec == "hall":
		_dress(P, rng, z0, w, variant, sec == "hall")
	var out := {"tex_key": "panel" if w == "aurora" else w}
	if P.n_lit:
		out["lit"] = P.lit.commit_to_arrays()
	if P.n_glow:
		out["glow"] = P.glow.commit_to_arrays()
	if P.n_tex:
		out["tex"] = P.tex.commit_to_arrays()
		tex_image(out.tex_key)
	if P.n_shaft:
		out["shaft"] = P.shaft.commit_to_arrays()
	return out


## a room open to the sky: a floor on piers, a colonnade either side, beams across overhead, a low parapet
static func _open(P: Parts, rng: RandomNumberGenerator, z0: float, w: String, v: int) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var stone: Color = T.wall2.lerp(Color("e4e8ec"), 0.5)
	var fa: Color = T.floor_a.lerp(Color("e8ecef"), 0.45)
	var fb: Color = T.floor_b.lerp(Color("cfd5da"), 0.45)
	for xi in 4:
		for zi in 8:
			var x := -HALF_W + HALF_W * 0.25 + xi * HALF_W * 0.5
			box(P.lit, Vector3(x, -0.15, z0 - zi * 2.0 - 1.0), Vector3(HALF_W * 0.5 - 0.04, 0.3, 1.96), (fa if (xi + zi) % 2 == 0 else fb) * rng.randf_range(0.97, 1.03))
			P.n_lit += 1
	# the deck the floor sits on, and piers going down out of sight
	box(P.lit, Vector3(0, -0.9, z0 - SEG * 0.5), Vector3(HALF_W * 2.0 + 1.6, 1.2, SEG), stone * 0.7)
	P.n_lit += 1
	for sd in [-1.0, 1.0]:
		box(P.lit, Vector3(sd * (HALF_W - 0.8), -12.0, z0 - SEG * 0.5), Vector3(1.6, 22.0, 2.4), stone * 0.55)
		# a low parapet with a bright cap
		box(P.lit, Vector3(sd * (HALF_W + 0.5), 0.5, z0 - SEG * 0.5), Vector3(0.5, 1.0, SEG), stone * 0.9)
		box(P.glow, Vector3(sd * (HALF_W + 0.5), 1.02, z0 - SEG * 0.5), Vector3(0.52, 0.04, SEG), acc * 0.7)
		P.n_lit += 2
		P.n_glow += 1
		for k in 4:
			var zc := z0 - k * 4.0 - 2.0
			if v == 7 and k % 2 == 1:
				continue
			box(P.lit, Vector3(sd * (HALF_W + 0.5), CEIL * 0.5 + 0.5, zc), Vector3(0.6, CEIL - 1.0, 0.6), stone)
			box(P.lit, Vector3(sd * (HALF_W + 0.5), CEIL + 0.1, zc), Vector3(0.9, 0.3, 0.9), stone * 0.9)
			P.n_lit += 2
	# beams across overhead (the rails that sliding glass hangs from run along these)
	for k in 4:
		var zc := z0 - k * 4.0 - 2.0
		if v == 7 and k % 2 == 1:
			continue
		box(P.lit, Vector3(0, CEIL + 0.3, zc), Vector3(HALF_W * 2.0 + 1.8, 0.4, 0.5), stone * 0.85)
		P.n_lit += 1


## what makes each room of a world look like a place of its own
static func _dress(P: Parts, rng: RandomNumberGenerator, z0: float, w: String, v: int, hall: bool) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var hw := HALL_W - 2.0 if hall else HALF_W
	var top := 13.0 if hall else CEIL
	# the shape of the room itself
	var stone: Color = T.wall2.lerp(Color("d8dde2"), 0.4)
	match v:
		1, 6:
			# raised platforms along the walls, with steps up to them
			for sd in [-1.0, 1.0]:
				var pw := 1.4 if v == 1 else 2.0
				var ph := 0.9 if v == 1 else 1.6
				box(P.lit, Vector3(sd * (hw - pw * 0.5), ph * 0.5, z0 - SEG * 0.5), Vector3(pw, ph, SEG), stone * 0.9)
				P.n_lit += 1
				for k in 3:
					var shh := ph * (k + 1) / 4.0
					box(P.lit, Vector3(sd * (hw - pw - 0.3 - (2 - k) * 0.35), shh * 0.5, z0 - 4.0 - 8.0 * (1 if sd > 0 else 0)), Vector3(0.36, shh, 2.4), stone)
					P.n_lit += 1
		3:
			# square pillars standing in from the walls
			for sd in [-1.0, 1.0]:
				for k in 2:
					var zc := z0 - k * 8.0 - 3.0
					box(P.lit, Vector3(sd * (hw - 1.3), top * 0.5, zc), Vector3(0.8, top, 0.8), stone)
					box(P.lit, Vector3(sd * (hw - 1.3), 0.15, zc), Vector3(1.1, 0.3, 1.1), stone * 0.85)
					P.n_lit += 2
		4:
			# great blocks hanging from the roof
			for k in 2:
				var sd := -1.0 if (k + int(z0)) % 2 == 0 else 1.0
				var bz := z0 - k * 8.0 - rng.randf_range(2.0, 6.0)
				var bh := rng.randf_range(1.4, 2.6)
				box(P.lit, Vector3(sd * (hw - 1.8), top - bh * 0.5 - 0.3, bz), Vector3(2.6, bh, 2.6), stone * 0.8)
				box(P.lit, Vector3(sd * (hw - 1.8), top - 0.15, bz), Vector3(0.2, 0.3, 0.2), Color("39424c"))
				P.n_lit += 2
		8:
			# the floor drops away at the sides into dark channels
			for sd in [-1.0, 1.0]:
				box(P.lit, Vector3(sd * (hw - 0.9), 0.02, z0 - SEG * 0.5), Vector3(1.6, 0.04, SEG), Color("06080c"))
				box(P.glow, Vector3(sd * (hw - 1.72), 0.04, z0 - SEG * 0.5), Vector3(0.05, 0.04, SEG), acc * 0.8)
				P.n_lit += 1
				P.n_glow += 1
	match v:
		1:
			# low arches across the way
			for k in 4:
				arc_boxes(P.lit, Vector3(0, top - hw - 0.3, z0 - k * 4.0 - 2.0), hw - 0.2, 0.05, PI - 0.05, 12, 0.22, 0.3, T.wall2 * 0.85)
				P.n_lit += 12
		2:
			# a row of lamps hanging over the middle
			for k in 2:
				var lz := z0 - k * 8.0 - 4.0
				box(P.lit, Vector3(0, top - 0.6, lz), Vector3(0.03, 1.2, 0.03), Color("222222"))
				box(P.glow, Vector3(0, top - 1.35, lz), Vector3(0.7, 0.32, 0.7), T.lights[0])
				box(P.lit, Vector3(0, top - 1.1, lz), Vector3(0.9, 0.12, 0.9), Color("3a3028"))
				P.n_lit += 2
				P.n_glow += 1
		3:
			# lines of light along the floor
			for sd in [-1.0, 1.0]:
				box(P.glow, Vector3(sd * (hw - 0.6), 0.02, z0 - SEG * 0.5), Vector3(0.12, 0.03, SEG), acc)
				P.n_glow += 1
			for k in 8:
				box(P.glow, Vector3(0, 0.02, z0 - k * 2.0 - 1.0), Vector3(0.5, 0.03, 0.06), acc * 0.7)
				P.n_glow += 1
		4:
			# long banners on the walls
			for sd in [-1.0, 1.0]:
				for k in 2:
					var bz := z0 - k * 8.0 - 2.0
					var bc: Color = JEWELS[rng.randi_range(0, JEWELS.size() - 1)] * 0.8
					box(P.lit, Vector3(sd * (hw - 0.15), top - 2.4, bz), Vector3(0.05, 3.6, 1.2), bc)
					box(P.glow, Vector3(sd * (hw - 0.12), top - 0.5, bz), Vector3(0.06, 0.1, 1.4), acc)
					P.n_lit += 1
					P.n_glow += 1
		5:
			# crystals growing at the foot of the walls
			for i in 10:
				var sd := -1.0 if i % 2 == 0 else 1.0
				var h := rng.randf_range(0.4, 1.4)
				box(P.glow, Vector3(sd * (hw - rng.randf_range(0.2, 0.7)), h * 0.5, z0 - rng.randf_range(0.0, SEG)), Vector3(0.2, h, 0.2), Color("9fe8e0") * 0.8)
				P.n_glow += 1
		6:
			# rings of light right round the way
			for k in 2:
				var rz := z0 - k * 8.0 - 4.0
				arc_boxes(P.glow, Vector3(0, top * 0.5, rz), maxf(hw, top * 0.5) + 0.1, 0.0, TAU, 28, 0.1, 0.12, acc)
				P.n_glow += 28
		7:
			# beams of light falling from above
			for k in 2:
				var x := rng.randf_range(-hw + 1.0, hw - 1.0)
				var bz := z0 - k * 8.0 - rng.randf_range(2.0, 6.0)
				quad(P.shaft, Vector3(x - 0.6, top, bz), Vector3(x + 0.6, top, bz), Vector3(x + 1.0, 0.02, bz), Vector3(x - 1.0, 0.02, bz), Color(T.lights[0], 0.18), Color(T.lights[0], 0.02))
				P.n_shaft += 1
		8:
			# a dark pool down the middle, with the lights of the room in it
			box(P.lit, Vector3(0, 0.01, z0 - SEG * 0.5), Vector3(2.2, 0.03, SEG), Color("0a0e14"))
			P.n_lit += 1
			for k in 6:
				box(P.glow, Vector3(rng.randf_range(-0.9, 0.9), 0.03, z0 - rng.randf_range(0.0, SEG)), Vector3(rng.randf_range(0.2, 0.6), 0.01, 0.04), T.lights[0] * 0.6)
				P.n_glow += 1
		9:
			# the last room: golden frames, one after another
			for k in 2:
				var fz := z0 - k * 8.0 - 4.0
				box(P.glow, Vector3(0, top - 0.2, fz), Vector3(hw * 2.0, 0.12, 0.12), Color("ffd36b"))
				box(P.glow, Vector3(-hw + 0.1, top * 0.5, fz), Vector3(0.12, top, 0.12), Color("ffd36b"))
				box(P.glow, Vector3(hw - 0.1, top * 0.5, fz), Vector3(0.12, top, 0.12), Color("ffd36b"))
				P.n_glow += 3


static func _corridor(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	match w:
		"neon":
			_neon(P, rng, z0)
		"ocean":
			_ocean(P, rng, z0)
		"aurora":
			_aurora(P, rng, z0)
		"dunes":
			_dunes(P, rng, z0)
		"ice":
			_ice(P, rng, z0)


static func finish(s: Dictionary) -> Node3D:
	mats()
	var mesh := ArrayMesh.new()
	for part in ["lit", "glow", "tex", "shaft"]:
		if not s.has(part):
			continue
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, s[part])
		var m: Material = lit_mat
		match part:
			"glow":
				m = glow_mat
			"tex":
				m = tex_mat(s.tex_key)
			"shaft":
				m = shaft_mat
		mesh.surface_set_material(mesh.get_surface_count() - 1, m)
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


## a light panel in a wall: a grid of little squares of colour, some brighter than others, like a screen far off
static func _light_panel(P: Parts, rng: RandomNumberGenerator, x: float, zc: float, w: float, y0: float, y1: float, facing: float, pal: Array) -> void:
	var cell := 0.32
	var nx := int(w / cell)
	var ny := int((y1 - y0) / cell)
	var x0 := -nx * cell * 0.5
	for gy in ny:
		for gx in nx:
			if rng.randf() < 0.18:
				continue
			var cx := x0 + (gx + 0.5) * cell
			var cy := y0 + (gy + 0.5) * cell
			var hw := cell * 0.42
			# bands of colour that run across the panel
			var col: Color = pal[(gy / 3 + (1 if rng.randf() < 0.12 else 0)) % pal.size()]
			col = col * rng.randf_range(0.55, 1.1)
			var p := [Vector3(cx - hw, cy - hw, 0), Vector3(cx + hw, cy - hw, 0), Vector3(cx + hw, cy + hw, 0), Vector3(cx - hw, cy + hw, 0)]
			var q := []
			for v in p:
				q.append(Vector3(x, v.y, zc + v.x * facing))
			quad(P.glow, q[0], q[1], q[2], q[3], col)
			P.n_glow += 1
	# the dark glass behind the squares
	box(P.lit, Vector3(x + signf(x) * 0.06, (y0 + y1) * 0.5, zc), Vector3(0.06, y1 - y0 + 0.2, w + 0.25), Color("0c0a14"))
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


## the neon city: dark glass walls, slim steel pillars with lines of neon, panels of light, beams overhead
static func _neon(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	_floor_tiles(P, rng, z0, Color("3a3848"), Color("26242f"))
	var steel := Color("6a6a88")
	var dark := Color("1c1830")
	var pal := [Color("ff3fd0"), Color("3fe0ff"), Color("9f5fff"), Color("ff7a3f")]
	for side in [-1.0, 1.0]:
		box(P.lit, Vector3(side * (HALF_W + 1.4), CEIL * 0.5 + 0.6, z0 - SEG * 0.5), Vector3(0.4, CEIL + 1.2, SEG), dark)
		P.n_lit += 1
		for k in 4:
			var zc := z0 - k * 4.0 - 2.0
			box(P.lit, Vector3(side * (HALF_W + 0.25), CEIL * 0.5 + 0.4, zc - 2.0 + 0.2), Vector3(0.36, CEIL + 0.8, 0.36), steel * rng.randf_range(0.9, 1.05))
			# a line of neon up the face of each pillar
			box(P.glow, Vector3(side * (HALF_W + 0.05), CEIL * 0.5, zc - 2.0 + 0.2), Vector3(0.05, CEIL - 0.6, 0.08), pal[(k + (1 if side > 0 else 0)) % 2])
			P.n_lit += 1
			P.n_glow += 1
			_light_panel(P, rng, side * (HALF_W + 1.18), zc + 0.2, 3.0, 1.0, 6.0, side, pal)
			if k % 2 == 0:
				_shaft(P, side * (HALF_W + 1.1), zc + 0.2, 2.2, 5.6, pal[1], side)
	# flat beams across overhead, each with a neon line under it
	for k in 4:
		var zc := z0 - k * 4.0 - 1.6
		box(P.lit, Vector3(0, CEIL + 0.1, zc), Vector3(HALF_W * 2 + 2.0, 0.4, 0.5), steel * 0.7)
		box(P.glow, Vector3(0, CEIL - 0.12, zc), Vector3(HALF_W * 2 + 1.6, 0.05, 0.08), pal[k % 2])
		P.n_lit += 1
		P.n_glow += 1
	box(P.lit, Vector3(0, CEIL + 1.4, z0 - SEG * 0.5), Vector3(HALF_W * 2 + 3.0, 0.4, SEG), Color("140f22"))
	P.n_lit += 1


## glass towers over the sea: a channel of water, glass fronts with lit floors, light buoys, a skybridge now and then
static func _ocean(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	box(P.lit, Vector3(0, -0.6, z0 - SEG * 0.5), Vector3(40, 0.2, SEG), Color("1f6f86"))
	for k in 6:
		box(P.glow, Vector3(rng.randf_range(-6, 6), -0.48, z0 - rng.randf_range(0, SEG)), Vector3(rng.randf_range(0.8, 2.4), 0.01, 0.05), Color("7fc8d8"))
	P.n_lit += 1
	P.n_glow += 6
	var cols := [Color("3a6a8a"), Color("4a7a9a"), Color("2a5a78"), Color("6a9ab8"), Color("8ab8d0")]
	for side in [-1.0, 1.0]:
		var z := z0
		while z > z0 - SEG + 0.1:
			var wdt := minf(rng.randf_range(3.0, 5.0), z - (z0 - SEG))
			var h := rng.randf_range(7.0, 12.0)
			var col: Color = cols[rng.randi_range(0, cols.size() - 1)]
			var xf: float = side * (HALF_W + 1.6)
			box(P.lit, Vector3(xf + side * 1.0, h * 0.5 - 0.5, z - wdt * 0.5), Vector3(2.0, h, wdt - 0.05), col)
			P.n_lit += 1
			# a lit band for each floor of glass, and a thin steel line between the floors
			var floors := int((h - 1.5) / 2.2)
			for f in floors:
				var wy := 1.6 + f * 2.2
				if rng.randf() < 0.75:
					box(P.glow, Vector3(xf - side * 0.01, wy, z - wdt * 0.5), Vector3(0.05, 1.1, wdt - 0.4), Color("bfefff") * rng.randf_range(0.35, 0.75))
					P.n_glow += 1
				box(P.lit, Vector3(xf - side * 0.03, wy + 0.85, z - wdt * 0.5), Vector3(0.06, 0.12, wdt - 0.1), Color("d8e4ea"))
				P.n_lit += 1
			z -= wdt
		# buoys of light in the water
		for k in 2:
			var pz := z0 - rng.randf_range(1.0, SEG - 1.0)
			var px: float = side * rng.randf_range(HALF_W - 0.6, HALF_W + 0.6)
			box(P.lit, Vector3(px, 0.4, pz), Vector3(0.22, 2.0, 0.22), Color("c8d4dc"))
			box(P.glow, Vector3(px, 1.5, pz), Vector3(0.3, 0.3, 0.3), Color("3fe0ff"))
			P.n_lit += 1
			P.n_glow += 1
	# now and then a skybridge of glass over the channel
	if rng.randf() < 0.45:
		var bz := z0 - rng.randf_range(4.0, 12.0)
		box(P.lit, Vector3(0, 7.4, bz), Vector3(HALF_W * 2 + 4.0, 0.9, 2.4), Color("6a9ab8"))
		box(P.glow, Vector3(0, 6.92, bz - 1.15), Vector3(HALF_W * 2 + 4.0, 0.06, 0.06), Color("3fe0ff"))
		box(P.glow, Vector3(0, 6.92, bz + 1.15), Vector3(HALF_W * 2 + 4.0, 0.06, 0.06), Color("3fe0ff"))
		P.n_lit += 1
		P.n_glow += 2


## a night of aurora: a deck of steel over black water, walls of frosted light in steel frames,
## frames of light across the way with glowing orbs hanging from them
static func _aurora(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	for zi in 16:
		box(P.lit, Vector3(0, -0.12, z0 - zi - 0.5), Vector3(HALF_W * 2 + 0.6, 0.18, 0.92), Color("3a4248") * rng.randf_range(0.85, 1.1))
		P.n_lit += 1
	box(P.lit, Vector3(0, -0.6, z0 - SEG * 0.5), Vector3(40, 0.2, SEG), Color("060912"))
	P.n_lit += 1
	var glows := [Color("5fffb0"), Color("9f7fff"), Color("3fe0ff")]
	var frame := Color("2a3238")
	for side in [-1.0, 1.0]:
		for k in 8:
			var zc := z0 - k * 2.0 - 1.0
			var x: float = side * (HALF_W + 0.5)
			var tint: Color = glows[(k / 3) % glows.size()].lerp(Color.WHITE, 0.55)
			box(P.tex, Vector3(x, 2.2, zc), Vector3(0.06, 3.6, 1.9), tint * 0.85, 1.0)
			P.n_tex += 1
			box(P.lit, Vector3(x - side * 0.04, 2.2, zc - 0.95), Vector3(0.06, 3.6, 0.06), frame)
			box(P.lit, Vector3(x - side * 0.04, 0.4, zc), Vector3(0.06, 0.06, 1.9), frame)
			box(P.lit, Vector3(x - side * 0.04, 4.0, zc), Vector3(0.06, 0.06, 1.9), frame)
			P.n_lit += 3
		box(P.lit, Vector3(side * (HALF_W + 0.5), 4.1, z0 - SEG * 0.5), Vector3(0.3, 0.25, SEG), frame)
		P.n_lit += 1
	# frames of light every 8 m, with orbs of light hanging from them
	for k in 2:
		var gz := z0 - k * 8.0 - 4.0
		var lc0: Color = glows[k % glows.size()]
		for side in [-1.0, 1.0]:
			box(P.lit, Vector3(side * (HALF_W - 0.2), CEIL * 0.5, gz), Vector3(0.3, CEIL, 0.3), frame)
			box(P.glow, Vector3(side * (HALF_W - 0.36), CEIL * 0.5, gz), Vector3(0.04, CEIL - 0.4, 0.1), lc0)
			P.n_lit += 1
			P.n_glow += 1
		box(P.lit, Vector3(0, CEIL - 0.2, gz), Vector3(HALF_W * 2 - 0.1, 0.3, 0.3), frame)
		box(P.glow, Vector3(0, CEIL - 0.37, gz), Vector3(HALF_W * 2 - 0.6, 0.04, 0.1), lc0)
		P.n_lit += 1
		P.n_glow += 1
		for i in 5:
			var lx := -3.6 + i * 1.8 + rng.randf_range(-0.3, 0.3)
			var drop := rng.randf_range(0.6, 1.6)
			var ly := CEIL - 0.5 - drop
			box(P.lit, Vector3(lx, ly + drop * 0.5 + 0.2, gz), Vector3(0.02, drop, 0.02), Color("222831"))
			var lc: Color = glows[rng.randi_range(0, glows.size() - 1)]
			box(P.glow, Vector3(lx, ly, gz), Vector3(0.36, 0.36, 0.36), lc)
			P.n_glow += 1
			P.n_lit += 1


## a solar city in the dunes: floors of sandstone, walls of panels, frames of six sides, lamps of amber
static func _dunes(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	_floor_tiles(P, rng, z0, Color("d8a870"), Color("c09060"), 0.04)
	for side in [-1.0, 1.0]:
		box(P.tex, Vector3(side * (HALF_W + 0.4), 1.4, z0 - SEG * 0.5), Vector3(0.3, 2.8, SEG), Color(1, 1, 1), 1.0)
		box(P.lit, Vector3(side * (HALF_W + 0.5), 5.0, z0 - SEG * 0.5), Vector3(0.3, 4.4, SEG), Color("e8d0a8"))
		box(P.glow, Vector3(side * (HALF_W + 0.3), 2.85, z0 - SEG * 0.5), Vector3(0.2, 0.08, SEG), Color("ff9a2a"))
		P.n_tex += 1
		P.n_lit += 1
		P.n_glow += 1
		# frames of six sides standing against the walls
		for k in 2:
			var zc := z0 - k * 8.0 - 4.0
			arc_boxes(P.lit, Vector3(side * (HALF_W + 0.1), 3.6, zc), 1.7, PI / 6.0, PI / 6.0 + TAU, 6, 0.26, 0.35, Color("f2e4cc"))
			P.n_lit += 6
	# lamps of amber hanging over the way
	for i in 3:
		var lx := rng.randf_range(-3.0, 3.0)
		var lz := z0 - rng.randf_range(1.0, SEG - 1.0)
		var drop := rng.randf_range(0.8, 2.0)
		box(P.lit, Vector3(lx, CEIL + 0.6 - drop * 0.5, lz), Vector3(0.02, drop, 0.02), Color("3a2a1a"))
		box(P.glow, Vector3(lx, CEIL + 0.4 - drop, lz), Vector3(0.36, 0.36, 0.36), [Color("ffcf7a"), Color("ff9a2a")][rng.randi_range(0, 1)])
		box(P.lit, Vector3(lx, CEIL + 0.62 - drop, lz), Vector3(0.22, 0.12, 0.22), Color("6a5a48"))
		P.n_lit += 2
		P.n_glow += 1


## caves of ice: a floor of pale ice with lines of light, walls of glittering ice, frames of six sides, spikes of ice
static func _ice(P: Parts, rng: RandomNumberGenerator, z0: float) -> void:
	_floor_tiles(P, rng, z0, Color("dde8f0"), Color("c0d0dc"), 0.03)
	for k in 3:
		box(P.glow, Vector3(0, 0.005, z0 - k * 5.3 - 2.0), Vector3(HALF_W * 2 - 0.4, 0.02, 0.06), Color("9fd8ff"))
		P.n_glow += 1
	for side in [-1.0, 1.0]:
		box(P.tex, Vector3(side * (HALF_W + 0.4), CEIL * 0.5, z0 - SEG * 0.5), Vector3(0.3, CEIL, SEG), Color(1, 1, 1), 0.9)
		P.n_tex += 1
		for k in 4:
			var zc := z0 - k * 4.0 - 2.0
			arc_boxes(P.glow, Vector3(side * (HALF_W + 0.22), 2.6, zc), 1.1, PI / 6.0, PI / 6.0 + TAU, 6, 0.07, 0.07, Color("9fd8ff"))
			box(P.glow, Vector3(side * (HALF_W + 0.05), 2.6, zc), Vector3(0.18, 0.26, 0.18), Color("e8f4ff"))
			P.n_glow += 7
		# spikes of ice at the foot of the wall
		for i in 5:
			var h := rng.randf_range(0.5, 1.6)
			box(P.glow, Vector3(side * (HALF_W - rng.randf_range(0.1, 0.5)), h * 0.5, z0 - rng.randf_range(0.0, SEG)), Vector3(0.18, h, 0.18), Color("bfe8ff") * 0.8)
			P.n_glow += 1
	box(P.lit, Vector3(0, CEIL + 0.2, z0 - SEG * 0.5), Vector3(HALF_W * 2 + 1.0, 0.4, SEG), Color("1a2a48"))
	for k in 4:
		box(P.glow, Vector3(0, CEIL - 0.02, z0 - k * 4.0 - 2.0), Vector3(HALF_W * 2, 0.05, 0.08), Color("9fd8ff"))
		P.n_glow += 1
	P.n_lit += 1


# ---------- the other shapes of the way ----------
## how bright the world's own shapes are (the glass stays bright), set as you go from one world to the next
static func set_tint(tint: Color, gtint: Color) -> void:
	mats()
	_tint = tint
	_gtint = gtint
	lit_mat.albedo_color = tint
	glow_mat.albedo_color = gtint
	shaft_mat.albedo_color = gtint
	for k in tex_mats:
		var m: StandardMaterial3D = tex_mats[k]
		m.albedo_color = tint if k != "panel" else gtint


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
		if w == "aurora":
			# a tunnel of red gates, close together
			main = T.wall if k % 2 == 0 else Color("1c1414")
		arc_boxes(P.lit, c3 + Vector3(0, 0, zc), T_R, a0, a1, 16, 0.4, 1.94, main)
		P.n_lit += 16
		if k % 2 == 0:
			arc_boxes(P.glow, c3 + Vector3(0, 0, zc - 1.0), T_R - 0.22, a0 + 0.05, a1 - 0.05, 22, 0.07, 0.1, acc)
			P.n_glow += 22
	# pipes along the walls, and small lamps on them
	for sd in [-1.0, 1.0]:
		var px: float = sd * (T_R - 0.75)
		box(P.lit, Vector3(px, 1.3, z0 - SEG * 0.5), Vector3(0.14, 0.14, SEG), Color("2b3138"))
		box(P.lit, Vector3(px * 0.97, 1.6, z0 - SEG * 0.5), Vector3(0.09, 0.09, SEG), Color("39424c"))
		P.n_lit += 2
		for k in 2:
			box(P.glow, Vector3(px * 0.96, 1.95, z0 - k * 8.0 - 4.0), Vector3(0.12, 0.2, 0.3), acc)
			P.n_glow += 1
	# little bright bits set in the walls (mirror work, tiles)
	var bits: Array = T.bits
	if bits.size():
		for i in 26:
			var a := rng.randf_range(a0 + 0.1, a1 - 0.1)
			var p := c3 + Vector3(cos(a) * (T_R - 0.22), sin(a) * (T_R - 0.22), z0 - rng.randf_range(0.2, SEG - 0.2))
			box(P.glow, p, Vector3(0.14, 0.14, 0.14), bits[i % bits.size()])
			P.n_glow += 1


## a great hall: a wide floor, two rows of tall columns, tall windows far off at the sides
static func _hall(P: Parts, rng: RandomNumberGenerator, z0: float, w: String, roof := true) -> void:
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
	if roof:
		box(P.lit, Vector3(0, 14.5, z0 - SEG * 0.5), Vector3(HALL_W * 2.0 + 2.0, 0.6, SEG), T.wall * 0.4)
		P.n_lit += 1
	else:
		# the roof here opens as you come (the game moves it); beams stay across
		box(P.lit, Vector3(0, 14.2, z0 - 2.0), Vector3(HALL_W * 2.0 + 2.0, 0.5, 0.5), T.wall2 * 0.6)
		box(P.lit, Vector3(0, 14.2, z0 - 10.0), Vector3(HALL_W * 2.0 + 2.0, 0.5, 0.5), T.wall2 * 0.6)
		P.n_lit += 2
	# lamps hanging on long chains, and light slanting in from the windows
	for sd in [-1.0, 1.0]:
		var lx: float = sd * rng.randf_range(4.0, 6.5)
		var lz := z0 - rng.randf_range(2.0, SEG - 2.0)
		var drop := rng.randf_range(5.0, 7.5)
		box(P.lit, Vector3(lx, 14.2 - drop * 0.5, lz), Vector3(0.04, drop, 0.04), Color("222222"))
		box(P.glow, Vector3(lx, 14.2 - drop - 0.3, lz), Vector3(0.5, 0.6, 0.5), T.lights[0])
		P.n_lit += 1
		P.n_glow += 1
		var wz := z0 - 4.0
		quad(P.shaft, Vector3(sd * HALL_W, 10.0, wz - 0.8), Vector3(sd * HALL_W, 10.0, wz + 0.8), Vector3(sd * (HALL_W - 9.0), 0.02, wz + 2.6), Vector3(sd * (HALL_W - 9.0), 0.02, wz + 1.0), Color(T.lights[0], 0.12), Color(T.lights[0], 0.0))
		P.n_shaft += 1


## open sky: the ground far below with its lights, and tall pillars rising from it to rush past
static func _sky(P: Parts, rng: RandomNumberGenerator, z0: float, w: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var g: Color = T.ground
	# the ground far below, wide enough that its edge is lost in the haze
	box(P.lit, Vector3(0, SKY_GROUND, z0 - SEG * 0.5), Vector3(900.0, 0.4, SEG), g)
	P.n_lit += 1
	match w:
		"neon":
			# a grid of light on the ground, like streets seen from high up
			box(P.glow, Vector3(0, SKY_GROUND + 0.22, z0 - SEG * 0.5), Vector3(240.0, 0.04, 0.12), acc * 0.5)
			P.n_glow += 1
			for i in 9:
				box(P.glow, Vector3(-120.0 + i * 30.0 + rng.randf_range(-4.0, 4.0), SKY_GROUND + 0.22, z0 - SEG * 0.5), Vector3(0.12, 0.04, SEG), Color("3fe0ff") * 0.45)
				P.n_glow += 1
		"ocean":
			# the sea: long glints on the water
			for i in 10:
				box(P.glow, Vector3(rng.randf_range(-100.0, 100.0), SKY_GROUND + 0.22, z0 - rng.randf_range(0.0, SEG)), Vector3(rng.randf_range(3.0, 10.0), 0.05, 0.25), Color("7fb8d8") * 0.6)
				P.n_glow += 1
		"aurora":
			# orbs of light floating on black water
			for i in 8:
				var lc: Color = T.lights[rng.randi_range(0, T.lights.size() - 1)]
				box(P.glow, Vector3(rng.randf_range(-60.0, 60.0), SKY_GROUND + 0.6, z0 - rng.randf_range(0.0, SEG)), Vector3(0.7, 0.7, 0.7), lc)
				P.n_glow += 1
		"dunes":
			# dunes, long and low
			for i in 3:
				var x := rng.randf_range(-120.0, 120.0)
				box(P.lit, Vector3(x, SKY_GROUND + 1.0, z0 - SEG * 0.5), Vector3(rng.randf_range(30.0, 60.0), 2.0, SEG), g * 1.35)
				P.n_lit += 1
		"ice":
			# spikes of ice on the ground, glowing
			for i in 8:
				var h := rng.randf_range(1.0, 4.0)
				box(P.glow, Vector3(rng.randf_range(-70.0, 70.0), SKY_GROUND + h * 0.5, z0 - rng.randf_range(0.0, SEG)), Vector3(0.6, h, 0.6), Color("9fd8ff") * 0.6)
				P.n_glow += 1
	for i in 22:
		var lc: Color = T.lights[i % T.lights.size()]
		var x := rng.randf_range(-110.0, 110.0)
		if absf(x) < 4.0:
			x += 8.0 * signf(x + 0.01)
		box(P.glow, Vector3(x, SKY_GROUND + 0.3, z0 - rng.randf_range(0.0, SEG)), Vector3(0.45, 0.3, 0.45), lc * 0.9)
		P.n_glow += 1
	# thin layers of mist between you and the ground
	var mist: Color = T.sky_hor.lerp(Color(1, 1, 1), 0.25)
	for y in [-11.0, -18.0]:
		var a0 := rng.randf_range(0.05, 0.12)
		var a1 := rng.randf_range(0.05, 0.12)
		quad(P.shaft, Vector3(-160, y, z0), Vector3(160, y, z0), Vector3(160, y, z0 - SEG), Vector3(-160, y, z0 - SEG), Color(mist, a0), Color(mist, a1))
		P.n_shaft += 1
	# towers of glass close by on either side, rising from the ground far below: some end below you, some
	# stand higher than you, so they rush past (they stay clear of the islands below the way, which reach
	# out to 8.5 m, and of the floating mountains further out)
	for sd: float in [-1.0, 1.0]:
		if rng.randf() < 0.8:
			var bw := rng.randf_range(3.0, 5.0)
			var x := sd * rng.randf_range(10.5 + bw * 0.5, 16.5)
			var zc := z0 - rng.randf_range(bw * 0.5 + 0.5, SEG - bw * 0.5 - 0.5)
			_tower(P, rng, x, zc, bw, rng.randf_range(-6.0, 14.0), w)
		# and a taller one far out, past the floating mountains
		if rng.randf() < 0.5:
			var bw := rng.randf_range(6.0, 10.0)
			_tower(P, rng, sd * rng.randf_range(54.0, 85.0), z0 - rng.randf_range(bw * 0.5, SEG - bw * 0.5), bw, rng.randf_range(10.0, 40.0), w)


## a tower of glass standing on the ground far below: dark glass, rows of lit floors on the faces you see, a bright rim on top
static func _tower(P: Parts, rng: RandomNumberGenerator, x: float, zc: float, bw: float, top: float, w: String) -> void:
	var T: Dictionary = TUNE[w]
	var acc: Color = DEFS[w].accent
	var bot := SKY_GROUND
	var h := top - bot
	var body: Color = T.wall.lerp(Color("0e1420"), 0.35)
	box(P.lit, Vector3(x, bot + h * 0.5, zc), Vector3(bw, h, bw), body)
	box(P.lit, Vector3(x, top + 0.2, zc), Vector3(bw + 0.4, 0.4, bw + 0.4), T.wall2 * 0.6)
	box(P.glow, Vector3(x, top + 0.43, zc), Vector3(bw + 0.2, 0.06, bw + 0.2), acc)
	P.n_lit += 2
	P.n_glow += 1
	var lc: Color = T.lights[rng.randi_range(0, T.lights.size() - 1)]
	var inner := x - signf(x) * (bw * 0.5 + 0.02)
	var y := top - 1.4
	var n := 0
	while y > bot + 2.0 and n < 16:
		if rng.randf() < 0.8:
			var k := rng.randf_range(0.45, 0.9)
			box(P.glow, Vector3(inner, y, zc), Vector3(0.04, 0.55, bw * 0.82), lc * k)
			box(P.glow, Vector3(x, y, zc + bw * 0.5 + 0.02), Vector3(bw * 0.82, 0.55, 0.04), lc * k)
			P.n_glow += 2
		y -= 2.0
		n += 1
	# a mast on top now and then, with a light
	if rng.randf() < 0.35:
		var mh := rng.randf_range(2.0, 5.0)
		box(P.lit, Vector3(x, top + 0.4 + mh * 0.5, zc), Vector3(0.12, mh, 0.12), Color("3a4250"))
		box(P.glow, Vector3(x, top + 0.5 + mh, zc), Vector3(0.3, 0.3, 0.3), acc)
		P.n_lit += 1
		P.n_glow += 1


# ---------- far away: the skyline of each world, drawn on the sky behind everything ----------
static var _skylines := {}


## shapes standing on the far ground: [polygon, layer (0 far and pale, 1 nearer and darker)], and little lit windows
static func skyline(w: String) -> Dictionary:
	if _skylines.has(w):
		return _skylines[w]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(w) % 100000
	var shapes := []
	var lights := []
	var base := -32.0
	# low hills right across, far behind
	var x := -420.0
	while x < 420.0:
		var wdt := rng.randf_range(60.0, 140.0)
		var h := rng.randf_range(8.0, 22.0)
		shapes.append([PackedVector2Array([Vector2(x - 20.0, base), Vector2(x + wdt * 0.5, base + h), Vector2(x + wdt + 20.0, base)]), 0])
		x += wdt * 0.7
	x = -400.0
	while x < 400.0:
		var gap := rng.randf_range(14.0, 34.0)
		if absf(x) < 18.0:
			x += gap
			continue
		var layer := 1 if rng.randf() < 0.55 else 0
		var s := rng.randf_range(0.8, 1.4) * (1.0 if layer == 1 else 0.75)
		match w:
			"neon":
				# towers with stepped tops and masts, many windows
				var bw := rng.randf_range(6.0, 12.0) * s
				var bh := rng.randf_range(18.0, 40.0) * s
				shapes.append([_rect(x, x + bw, base, base + bh), layer])
				shapes.append([_rect(x + bw * 0.2, x + bw * 0.8, base + bh, base + bh + bw * 0.6), layer])
				if rng.randf() < 0.5:
					shapes.append([_rect(x + bw * 0.48, x + bw * 0.52 + 0.3, base + bh + bw * 0.6, base + bh + bw * 0.6 + 8.0 * s), layer])
				for k in 4:
					lights.append(Vector2(x + rng.randf_range(1.0, bw - 1.0), base + rng.randf_range(3.0, bh - 2.0)))
			"ocean":
				# slim towers with slanted roofs, and long low blocks
				if rng.randf() < 0.5:
					var tw := rng.randf_range(4.0, 7.0) * s
					var th := rng.randf_range(22.0, 44.0) * s
					shapes.append([_rect(x, x + tw, base, base + th), layer])
					shapes.append([PackedVector2Array([Vector2(x, base + th), Vector2(x + tw, base + th), Vector2(x + tw, base + th + tw * 0.8)]), layer])
					for k in 3:
						lights.append(Vector2(x + rng.randf_range(0.8, tw - 0.8), base + rng.randf_range(3.0, th - 2.0)))
				else:
					var hw := rng.randf_range(12.0, 20.0) * s
					var hh := rng.randf_range(6.0, 12.0) * s
					shapes.append([_rect(x, x + hw, base, base + hh), layer])
					for k in 3:
						lights.append(Vector2(x + rng.randf_range(1.0, hw - 1.0), base + rng.randf_range(2.0, hh - 1.5)))
			"aurora":
				if rng.randf() < 0.4:
					# a needle tower with a ring of light near the top
					var nh := rng.randf_range(30.0, 50.0) * s
					shapes.append([_rect(x, x + 1.6 * s, base, base + nh), layer])
					shapes.append([_rect(x - 2.4 * s, x + 4.0 * s, base + nh * 0.8, base + nh * 0.8 + 2.0 * s), layer])
					lights.append(Vector2(x + 0.8 * s, base + nh * 0.8 + 1.0 * s))
					lights.append(Vector2(x + 0.8 * s, base + nh))
				else:
					# mountains
					var mw := rng.randf_range(40.0, 70.0) * s
					shapes.append([PackedVector2Array([Vector2(x, base), Vector2(x + mw * 0.45, base + mw * rng.randf_range(0.35, 0.6)), Vector2(x + mw, base)]), 0])
			"dunes":
				if rng.randf() < 0.35:
					# a solar tower: a slim shaft with a bright crown
					var sh := rng.randf_range(28.0, 40.0) * s
					shapes.append([_rect(x, x + 2.4 * s, base, base + sh), layer])
					shapes.append([_rect(x - 1.2 * s, x + 3.6 * s, base + sh, base + sh + 3.0 * s), layer])
					lights.append(Vector2(x + 1.2 * s, base + sh + 1.5 * s))
				else:
					# a mesa: wide and flat on top
					var dw := rng.randf_range(18.0, 30.0) * s
					var dh := rng.randf_range(6.0, 12.0) * s
					shapes.append([PackedVector2Array([Vector2(x, base), Vector2(x + dw, base), Vector2(x + dw * 0.85, base + dh), Vector2(x + dw * 0.15, base + dh)]), layer])
					for k in 2:
						lights.append(Vector2(x + rng.randf_range(dw * 0.25, dw * 0.75), base + rng.randf_range(1.5, dh - 1.0)))
			"ice":
				# shards of ice standing up out of the ground, leaning
				var cw := rng.randf_range(5.0, 10.0) * s
				for k in rng.randi_range(2, 4):
					var sx := x + rng.randf_range(0.0, cw)
					var sw := rng.randf_range(2.0, 4.0) * s
					var ht := rng.randf_range(12.0, 34.0) * s
					var lean := rng.randf_range(-4.0, 4.0) * s
					shapes.append([PackedVector2Array([Vector2(sx, base), Vector2(sx + sw, base), Vector2(sx + sw * 0.5 + lean, base + ht)]), layer])
				lights.append(Vector2(x + cw * 0.5, base + rng.randf_range(3.0, 8.0)))
		x += gap + 10.0
	var out := {"shapes": shapes, "lights": lights}
	_skylines[w] = out
	return out


static func _rect(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])

