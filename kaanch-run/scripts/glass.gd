## Flat convex glass: building its mesh (with thickness and bright edges), and breaking it into pieces.
class_name Glass
extends RefCounted

# every kind of glass: how thick, how many hits, how it looks, how many pieces it breaks into
const KINDS := {
	"thin": {"t": 0.04, "hp": 1, "face": Color(0.66, 0.8, 0.86, 0.42), "side": Color(0.5, 0.66, 0.74, 0.85), "rim": Color(0.92, 1.0, 1.0, 0.5), "rim_w": 0.035, "pieces": 14},
	"mid": {"t": 0.1, "hp": 1, "face": Color(0.6, 0.76, 0.84, 0.5), "side": Color(0.44, 0.6, 0.7, 0.9), "rim": Color(0.85, 0.98, 0.97, 0.6), "rim_w": 0.045, "pieces": 11},
	"thick": {"t": 0.34, "hp": 2, "face": Color(0.52, 0.7, 0.8, 0.6), "side": Color(0.34, 0.5, 0.6, 0.95), "rim": Color(0.6, 0.9, 0.84, 0.85), "rim_w": 0.08, "pieces": 8},
	"slab": {"t": 0.6, "hp": 2, "face": Color(0.46, 0.64, 0.76, 0.68), "side": Color(0.28, 0.44, 0.55, 0.97), "rim": Color(0.5, 0.82, 0.76, 0.9), "rim_w": 0.1, "pieces": 7},
	# a brick of glass: very thick, breaks into heavy chunks
	"block": {"t": 0.9, "hp": 2, "face": Color(0.48, 0.66, 0.78, 0.64), "side": Color(0.3, 0.46, 0.57, 0.96), "rim": Color(0.55, 0.86, 0.8, 0.9), "rim_w": 0.09, "pieces": 6},
	# a giant cube of glass, as wide as the way and two metres deep
	"giant": {"t": 2.0, "hp": 2, "face": Color(0.48, 0.66, 0.78, 0.6), "side": Color(0.3, 0.46, 0.57, 0.95), "rim": Color(0.55, 0.86, 0.8, 0.9), "rim_w": 0.12, "pieces": 7},
	# a mirror: silvered, the first ball bounces off it
	"mirror": {"t": 0.08, "hp": 1, "face": Color(0.85, 0.88, 0.92, 0.94), "side": Color(0.5, 0.55, 0.6, 1.0), "rim": Color(0.9, 0.93, 0.96, 0.8), "rim_w": 0.05, "pieces": 10},
	# tempered: bursts into little cubes
	"tempered": {"t": 0.07, "hp": 1, "face": Color(0.72, 0.93, 0.88, 0.24), "side": Color(0.55, 0.85, 0.78, 0.8), "rim": Color(0.85, 0.98, 0.95, 0.55), "rim_w": 0.04, "pieces": 5},
	# laminated: cracks and sags first, then falls in one sheet
	"laminated": {"t": 0.14, "hp": 2, "face": Color(0.88, 0.93, 0.95, 0.36), "side": Color(0.72, 0.8, 0.84, 0.9), "rim": Color(0.92, 0.96, 0.98, 0.6), "rim_w": 0.05, "pieces": 7},
	# frosted: you cannot see what is behind it
	"frosted": {"t": 0.08, "hp": 1, "face": Color(0.86, 0.9, 0.92, 0.8), "side": Color(0.78, 0.85, 0.88, 0.95), "rim": Color(0.95, 0.97, 0.98, 0.6), "rim_w": 0.04, "pieces": 12},
	# blast glass: when it breaks it takes the glass round it with it (the one glass with a warning colour)
	"blast": {"t": 0.12, "hp": 1, "face": Color(0.95, 0.55, 0.3, 0.45), "side": Color(0.85, 0.38, 0.18, 0.95), "rim": Color(1.0, 0.7, 0.4, 0.9), "rim_w": 0.06, "pieces": 12},
}

# the colours of coloured glass (for the colour combo and the prism)
const COLORS := [Color("ff4d6d"), Color("ffb627"), Color("3ddc97"), Color("4d8dff"), Color("b86bff")]
const COLOR_NAMES := ["Ruby", "Amber", "Emerald", "Sapphire", "Violet"]

static var glass_mat: StandardMaterial3D
static var mirror_mat: StandardMaterial3D
static var rim_mat: StandardMaterial3D
static var glow_rim_mat: StandardMaterial3D


static func mats() -> void:
	if glass_mat:
		return
	glass_mat = StandardMaterial3D.new()
	glass_mat.vertex_color_use_as_albedo = true
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.roughness = 0.12
	glass_mat.albedo_texture = _scratch_tex()
	glass_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	glass_mat.metallic = 0.15
	glass_mat.metallic_specular = 0.9
	# glass catches the light at its edges, the way real glass does seen at an angle
	glass_mat.rim_enabled = true
	glass_mat.rim = 0.35
	glass_mat.rim_tint = 0.4
	mirror_mat = StandardMaterial3D.new()
	mirror_mat.vertex_color_use_as_albedo = true
	mirror_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mirror_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mirror_mat.metallic = 0.3
	mirror_mat.roughness = 0.1
	mirror_mat.albedo_texture = _mirror_tex()
	# a sheen of its own, so it reads as silver even with nothing to reflect
	mirror_mat.emission_enabled = true
	mirror_mat.emission_texture = mirror_mat.albedo_texture
	mirror_mat.emission = Color(0.55, 0.6, 0.66)
	mirror_mat.emission_energy_multiplier = 0.6
	rim_mat = StandardMaterial3D.new()
	rim_mat.vertex_color_use_as_albedo = true
	rim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# edges that glow in their own colour (coloured glass, blast glass)
	glow_rim_mat = rim_mat.duplicate()


## fine scratches and smudges, so glass reads as a surface even where it is clear
static func _scratch_tex() -> Texture2D:
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.94, 0.95, 0.96, 0.92))
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	# soft smudges
	for k in 22:
		var c := Vector2(rng.randf() * S, rng.randf() * S)
		var r := rng.randf_range(10.0, 34.0)
		for y in range(int(c.y - r), int(c.y + r)):
			for x in range(int(c.x - r), int(c.x + r)):
				var d := Vector2(x, y).distance_to(c) / r
				if d < 1.0:
					var px := Vector2i(posmod(x, S), posmod(y, S))
					var col := img.get_pixelv(px)
					img.set_pixelv(px, col.lerp(Color(1, 1, 1, 1.0), (1.0 - d) * 0.25))
	# thin bright scratches
	for k in 70:
		var p := Vector2(rng.randf() * S, rng.randf() * S)
		var a := rng.randf() * TAU
		var dir := Vector2(cos(a), sin(a))
		var ln := rng.randf_range(8.0, 60.0)
		for i in int(ln):
			p += dir
			dir = dir.rotated(rng.randf_range(-0.04, 0.04))
			img.set_pixelv(Vector2i(posmod(int(p.x), S), posmod(int(p.y), S)), Color(1, 1, 1, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## light streaks for the mirror, so it looks silvered rather than flat grey
static func _mirror_tex() -> Texture2D:
	var S := 128
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var u := float(x) / S
			var v := float(y) / S
			var d := fposmod(u + v * 0.6, 1.0)
			var s := 0.62 + 0.25 * v + 0.35 * exp(-pow((d - 0.3) * 9.0, 2.0)) + 0.18 * exp(-pow((d - 0.62) * 14.0, 2.0))
			img.set_pixel(x, y, Color(s, s * 1.02, s * 1.05, 1.0))
	var t := ImageTexture.create_from_image(img)
	return t


static func area(poly: PackedVector2Array) -> float:
	var a := 0.0
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## the same polygon, counter-clockwise
static func ccw(poly: PackedVector2Array) -> PackedVector2Array:
	if area(poly) < 0.0:
		var r := poly.duplicate()
		r.reverse()
		return r
	return poly


static func centroid(poly: PackedVector2Array) -> Vector2:
	var a := 0.0
	var c := Vector2.ZERO
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		var f := p.x * q.y - q.x * p.y
		a += f
		c += (p + q) * f
	if absf(a) < 1e-9:
		var s := Vector2.ZERO
		for p in poly:
			s += p
		return s / maxf(1.0, float(n))
	return c / (3.0 * a)


static func bounds(poly: PackedVector2Array) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	return Rect2(lo, hi - lo)


## is p inside a counter-clockwise convex polygon (grown by margin)?
static func inside(poly: PackedVector2Array, p: Vector2, margin := 0.0) -> bool:
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var e := poly[(i + 1) % n] - a
		var l := e.length()
		if l < 1e-6:
			continue
		if (e.x * (p.y - a.y) - e.y * (p.x - a.x)) / l < -margin:
			return false
	return true


static func moved(poly: PackedVector2Array, d: Vector2) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in poly:
		r.append(p + d)
	return r


static func turned(poly: PackedVector2Array, a: float, about := Vector2.ZERO) -> PackedVector2Array:
	var r := PackedVector2Array()
	for p in poly:
		r.append(about + (p - about).rotated(a))
	return r


static func rect(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func ngon(n: int, r: float, c := Vector2.ZERO, turn := 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := turn + TAU * i / n
		p.append(c + Vector2(cos(a), sin(a)) * r)
	return p


## a wedge of a ring, pointing along +x (turn it afterwards)
static func wedge(r0: float, r1: float, half: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	p.append(Vector2(cos(-half), sin(-half)) * r0)
	for k in 5:
		var a := -half + (2.0 * half) * k / 4.0
		p.append(Vector2(cos(a), sin(a)) * r1)
	p.append(Vector2(cos(half), sin(half)) * r0)
	return p


## a pointed (gothic) arch window: straight sides, two arcs meeting at the top
static func arch(x0: float, x1: float, y0: float, y_spring: float, steps := 5) -> PackedVector2Array:
	var w := x1 - x0
	var p := PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y_spring)])
	for k in range(1, steps + 1):
		var a := (PI / 3.0) * k / steps
		p.append(Vector2(x1 - w + w * cos(a), y_spring + w * sin(a)))
	# the arc from the top back down the left side meets the first arc at the apex; keep it convex
	var apex := Vector2((x0 + x1) * 0.5, y_spring + w * sin(PI / 3.0))
	p[p.size() - 1] = apex
	for k in range(steps - 1, 0, -1):
		var a := (PI / 3.0) * k / steps
		p.append(Vector2(x0 + w - w * cos(a), y_spring + w * sin(a)))
	p.append(Vector2(x0, y_spring))
	return p


## keep the part of a convex polygon where dot(p, nrm) <= c
static func clip(poly: PackedVector2Array, nrm: Vector2, c: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var da := a.dot(nrm) - c
		var db := b.dot(nrm) - c
		if da <= 0.0:
			out.append(a)
		if (da <= 0.0) != (db <= 0.0):
			out.append(a + (b - a) * (da / (da - db)))
	return out


## the polygon cut into pieces round seed points (each piece is the part nearer its seed than any other)
static func voronoi(poly: PackedVector2Array, seeds: PackedVector2Array) -> Array:
	var cells := []
	for i in seeds.size():
		var cell := poly
		var s := seeds[i]
		var reach := _reach2(cell, s)
		for j in seeds.size():
			if i == j:
				continue
			var o := seeds[j]
			var nrm := o - s
			var d2 := nrm.length_squared()
			if d2 < 1e-8:
				continue
			# a seed more than twice as far as the farthest corner of the piece cannot cut it: skip it
			# (the same pieces as before, only far quicker; glass breaks in the middle of a frame)
			if d2 >= 4.0 * reach:
				continue
			cell = clip(cell, nrm, nrm.dot((s + o) * 0.5))
			if cell.size() < 3:
				break
			reach = _reach2(cell, s)
		if cell.size() >= 3 and absf(area(cell)) > 0.0004:
			cells.append(cell)
	return cells


## the square of the distance from a point to the farthest corner of a polygon
static func _reach2(poly: PackedVector2Array, p: Vector2) -> float:
	var r := 0.0
	for q in poly:
		r = maxf(r, p.distance_squared_to(q))
	return r


## seed points for breaking: crowded round where it was hit, so small pieces there and big ones at the edges
static func seeds_for(poly: PackedVector2Array, hit: Vector2, count: int) -> PackedVector2Array:
	var b := bounds(poly)
	var size := b.size.length()
	var out := PackedVector2Array([hit])
	var tries := 0
	while out.size() < count and tries < count * 12:
		tries += 1
		var p: Vector2
		if randf() < 0.65:
			var a := randf() * TAU
			var r := pow(randf(), 1.6) * size * 0.55
			p = hit + Vector2(cos(a), sin(a)) * r
		else:
			p = Vector2(randf_range(b.position.x, b.end.x), randf_range(b.position.y, b.end.y))
		if inside(poly, p, -0.01):
			out.append(p)
	return out


## how a pane of a kind (and maybe a colour) looks: [face, side, rim]
static func look(kind: String, color_id := -1) -> Array:
	var K: Dictionary = KINDS[kind]
	var face: Color = K.face
	var side: Color = K.side
	var rim: Color = K.rim
	if color_id >= 0:
		# glass of a colour (for the prism and the colour combo): only a tint, it is still glass
		var c: Color = COLORS[color_id]
		face = Color(lerpf(face.r, c.r, 0.45), lerpf(face.g, c.g, 0.45), lerpf(face.b, c.b, 0.45), face.a + 0.08)
		side = Color(lerpf(side.r, c.r, 0.5), lerpf(side.g, c.g, 0.5), lerpf(side.b, c.b, 0.5), side.a)
		rim = Color(lerpf(rim.r, c.r, 0.5), lerpf(rim.g, c.g, 0.5), lerpf(rim.b, c.b, 0.5), rim.a)
	return [face, side, rim]


## a slab of glass: front and back faces, the sides, and bright edges (a second surface)
static func slab_mesh(poly: PackedVector2Array, kind: String, rim_scale := 1.0, color_id := -1) -> ArrayMesh:
	mats()
	var K: Dictionary = KINDS[kind]
	var L := look(kind, color_id)
	var t: float = K.t
	var hz := t * 0.5
	var n := poly.size()
	var mesh := ArrayMesh.new()
	if n < 3:
		return mesh
	var mirror := kind == "mirror"
	var b := bounds(poly)
	var uv_k := 1.0 / maxf(0.01, maxf(b.size.x, b.size.y))
	var face: Color = L[0]
	var side: Color = L[1]
	# written straight into arrays, not a vertex at a time: glass is broken into pieces in the middle of a frame
	var count := 6 * (n - 2) + 6 * n
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var us := PackedVector2Array()
	vs.resize(count)
	ns.resize(count)
	cs.resize(count)
	us.resize(count)
	var k := 0
	for z in [hz, -hz]:
		var nz := Vector3(0, 0, signf(z))
		for i in range(1, n - 1):
			for q in [poly[0], poly[i], poly[i + 1]]:
				vs[k] = Vector3(q.x, q.y, z)
				ns[k] = nz
				cs[k] = face
				us[k] = (q - b.position) * uv_k if mirror else q / 2.2
				k += 1
	for i in n:
		var a := poly[i]
		var c := poly[(i + 1) % n]
		var e := (c - a).normalized()
		var nn := Vector3(e.y, -e.x, 0)
		for v in [Vector3(a.x, a.y, hz), Vector3(c.x, c.y, hz), Vector3(c.x, c.y, -hz), Vector3(a.x, a.y, hz), Vector3(c.x, c.y, -hz), Vector3(a.x, a.y, -hz)]:
			vs[k] = v
			ns[k] = nn
			cs[k] = side
			us[k] = Vector2(0.5, 0.5)
			k += 1
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_NORMAL] = ns
	arr[Mesh.ARRAY_COLOR] = cs
	arr[Mesh.ARRAY_TEX_UV] = us
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	mesh.surface_set_material(0, mirror_mat if mirror else glass_mat)
	# the edges: a thin bright band just inside the outline, on both faces
	var w: float = K.rim_w * rim_scale
	var cc := centroid(poly)
	var inner := PackedVector2Array()
	for p in poly:
		var d := cc - p
		inner.append(p + d.normalized() * minf(w, d.length() * 0.45))
	var rv := PackedVector3Array()
	rv.resize(12 * n)
	var rc := PackedColorArray()
	rc.resize(12 * n)
	rc.fill(L[2])
	k = 0
	for z in [hz + 0.003, -hz - 0.003]:
		for i in n:
			var j := (i + 1) % n
			var oi := Vector3(poly[i].x, poly[i].y, z)
			var oj := Vector3(poly[j].x, poly[j].y, z)
			var ij := Vector3(inner[j].x, inner[j].y, z)
			rv[k] = oi
			rv[k + 1] = oj
			rv[k + 2] = ij
			rv[k + 3] = oi
			rv[k + 4] = ij
			rv[k + 5] = Vector3(inner[i].x, inner[i].y, z)
			k += 6
	var ra := []
	ra.resize(Mesh.ARRAY_MAX)
	ra[Mesh.ARRAY_VERTEX] = rv
	ra[Mesh.ARRAY_COLOR] = rc
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, ra)
	mesh.surface_set_material(1, glow_rim_mat if (color_id >= 0 or kind == "blast") else rim_mat)
	return mesh
