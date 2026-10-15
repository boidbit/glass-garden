## Flat convex glass: building its mesh (with thickness and bright edges), and breaking it into pieces.
class_name Glass
extends RefCounted

# what each thickness looks like and how many hits it takes
const KINDS := {
	"thin": {"t": 0.03, "hp": 1, "face": Color(0.74, 0.94, 1.0, 0.3), "side": Color(0.70, 0.95, 1.0, 0.6), "rim": 0.055, "pieces": 14},
	"mid": {"t": 0.06, "hp": 1, "face": Color(0.56, 0.88, 1.0, 0.4), "side": Color(0.50, 0.88, 0.95, 0.8), "rim": 0.065, "pieces": 11},
	"thick": {"t": 0.16, "hp": 2, "face": Color(0.42, 0.86, 0.80, 0.46), "side": Color(0.25, 0.75, 0.66, 0.9), "rim": 0.07, "pieces": 9},
	"slab": {"t": 0.3, "hp": 3, "face": Color(0.26, 0.70, 0.62, 0.6), "side": Color(0.14, 0.55, 0.48, 0.95), "rim": 0.08, "pieces": 8},
}

static var glass_mat: StandardMaterial3D
static var rim_mat: StandardMaterial3D


static func mats() -> void:
	if glass_mat:
		return
	glass_mat = StandardMaterial3D.new()
	glass_mat.vertex_color_use_as_albedo = true
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.roughness = 0.06
	glass_mat.metallic = 0.15
	glass_mat.metallic_specular = 0.9
	rim_mat = StandardMaterial3D.new()
	rim_mat.vertex_color_use_as_albedo = true
	rim_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rim_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rim_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


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


static func rect(x0: float, x1: float, y0: float, y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)])


static func ngon(n: int, r: float, c := Vector2.ZERO, turn := 0.0) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := turn + TAU * i / n
		p.append(c + Vector2(cos(a), sin(a)) * r)
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
		for j in seeds.size():
			if i == j:
				continue
			var o := seeds[j]
			var nrm := o - s
			if nrm.length_squared() < 1e-8:
				continue
			cell = clip(cell, nrm, nrm.dot((s + o) * 0.5))
			if cell.size() < 3:
				break
		if cell.size() >= 3 and absf(area(cell)) > 0.0004:
			cells.append(cell)
	return cells


## seed points for breaking: crowded round where it was hit, so small pieces there and big ones at the edges
static func seeds_for(poly: PackedVector2Array, hit: Vector2, count: int) -> PackedVector2Array:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in poly:
		lo = lo.min(p)
		hi = hi.max(p)
	var size := (hi - lo).length()
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
			p = Vector2(randf_range(lo.x, hi.x), randf_range(lo.y, hi.y))
		if inside(poly, p, -0.01):
			out.append(p)
	return out


## a slab of glass: front and back faces, the sides, and bright edges (a second surface)
static func slab_mesh(poly: PackedVector2Array, kind: String, rim_scale := 1.0) -> ArrayMesh:
	mats()
	var K: Dictionary = KINDS[kind]
	var t: float = K.t
	var hz := t * 0.5
	var n := poly.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var face: Color = K.face
	var side: Color = K.side
	for z in [hz, -hz]:
		st.set_color(face)
		st.set_normal(Vector3(0, 0, signf(z)))
		for i in range(1, n - 1):
			st.add_vertex(Vector3(poly[0].x, poly[0].y, z))
			st.add_vertex(Vector3(poly[i].x, poly[i].y, z))
			st.add_vertex(Vector3(poly[i + 1].x, poly[i + 1].y, z))
	st.set_color(side)
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var e := (b - a).normalized()
		st.set_normal(Vector3(e.y, -e.x, 0))
		st.add_vertex(Vector3(a.x, a.y, hz))
		st.add_vertex(Vector3(b.x, b.y, hz))
		st.add_vertex(Vector3(b.x, b.y, -hz))
		st.add_vertex(Vector3(a.x, a.y, hz))
		st.add_vertex(Vector3(b.x, b.y, -hz))
		st.add_vertex(Vector3(a.x, a.y, -hz))
	st.set_material(glass_mat)
	var mesh := st.commit()
	# the edges: a thin bright band just inside the outline, on both faces
	var w: float = K.rim * rim_scale
	var c := centroid(poly)
	var inner := PackedVector2Array()
	for p in poly:
		var d := c - p
		inner.append(p + d.normalized() * minf(w, d.length() * 0.45))
	var rs := SurfaceTool.new()
	rs.begin(Mesh.PRIMITIVE_TRIANGLES)
	rs.set_color(Color(0.92, 1.0, 1.0, 0.95))
	for z in [hz + 0.003, -hz - 0.003]:
		for i in n:
			var j := (i + 1) % n
			rs.add_vertex(Vector3(poly[i].x, poly[i].y, z))
			rs.add_vertex(Vector3(poly[j].x, poly[j].y, z))
			rs.add_vertex(Vector3(inner[j].x, inner[j].y, z))
			rs.add_vertex(Vector3(poly[i].x, poly[i].y, z))
			rs.add_vertex(Vector3(inner[j].x, inner[j].y, z))
			rs.add_vertex(Vector3(inner[i].x, inner[i].y, z))
	rs.set_material(rim_mat)
	rs.commit(mesh)
	return mesh
