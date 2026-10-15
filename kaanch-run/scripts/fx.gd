## Little effects: sparks and glitter where glass is hit, glass bursting into cubes, a flash of light,
## cracks spreading, trails behind the balls and beams of light from a prism. Made once and reused.
class_name Fx
extends Node3D

var cam: Camera3D
var sparks: Array[CPUParticles3D] = []
var crumbs: Array[CPUParticles3D] = []
var _si := 0
var _ci := 0
var light: OmniLight3D
var lines: ImmediateMesh
var line_node: MeshInstance3D
var beams: Array = []
var cracks: Array = []
var crack_mat: StandardMaterial3D
var crack_quad: QuadMesh
var quality := 1


func setup(camera: Camera3D, glow: Texture2D, crack_tex: Texture2D) -> void:
	cam = camera
	var spark_mat := StandardMaterial3D.new()
	spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	spark_mat.vertex_color_use_as_albedo = true
	spark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	spark_mat.albedo_texture = glow
	var q := QuadMesh.new()
	q.size = Vector2(0.12, 0.12)
	q.material = spark_mat
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	for i in 8:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = 28
		p.lifetime = 0.55
		p.explosiveness = 1.0
		p.direction = Vector3(0, 0, 1)
		p.spread = 180.0
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 8.0
		p.gravity = Vector3(0, -7, 0)
		p.damping_min = 2.0
		p.damping_max = 4.0
		p.scale_amount_min = 0.4
		p.scale_amount_max = 1.2
		p.color_ramp = fade
		p.mesh = q
		p.local_coords = false
		add_child(p)
		sparks.append(p)
	# little cubes of tempered glass
	var cube_mat := StandardMaterial3D.new()
	cube_mat.vertex_color_use_as_albedo = true
	cube_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube_mat.roughness = 0.05
	cube_mat.metallic = 0.3
	var bx := BoxMesh.new()
	bx.size = Vector3(0.06, 0.06, 0.06)
	bx.material = cube_mat
	var fade2 := Gradient.new()
	fade2.set_color(0, Color(1, 1, 1, 1))
	fade2.add_point(0.8, Color(1, 1, 1, 0.9))
	fade2.set_color(1, Color(1, 1, 1, 0))
	for i in 3:
		var p := CPUParticles3D.new()
		p.one_shot = true
		p.emitting = false
		p.amount = 70
		p.lifetime = 1.4
		p.explosiveness = 0.95
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(1.0, 1.0, 0.05)
		p.direction = Vector3(0, 0.3, -1)
		p.spread = 70.0
		p.initial_velocity_min = 1.5
		p.initial_velocity_max = 5.5
		p.gravity = Vector3(0, -14, 0)
		p.angular_velocity_min = -400.0
		p.angular_velocity_max = 400.0
		p.scale_amount_min = 0.5
		p.scale_amount_max = 1.3
		p.color_ramp = fade2
		p.mesh = bx
		p.local_coords = false
		add_child(p)
		crumbs.append(p)
	light = OmniLight3D.new()
	light.omni_range = 7.0
	light.light_energy = 0.0
	light.visible = false
	add_child(light)
	# trails and beams: one mesh redrawn each frame
	lines = ImmediateMesh.new()
	line_node = MeshInstance3D.new()
	line_node.mesh = lines
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.vertex_color_use_as_albedo = true
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	lm.cull_mode = BaseMaterial3D.CULL_DISABLED
	line_node.material_override = lm
	line_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(line_node)
	crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_texture = crack_tex
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crack_quad = QuadMesh.new()
	crack_quad.size = Vector2(1, 1)


func spark(pos: Vector3, col: Color, n := 28, speed := 1.0) -> void:
	var p := sparks[_si]
	_si = (_si + 1) % sparks.size()
	p.global_position = pos
	p.amount = maxi(6, int(n * (1.0 if quality > 0 else 0.5)))
	p.color = col
	p.initial_velocity_max = 8.0 * speed
	p.restart()
	p.emitting = true


func crumble(pos: Vector3, basis: Basis, half: Vector2, col: Color, dir: Vector3) -> void:
	var p := crumbs[_ci]
	_ci = (_ci + 1) % crumbs.size()
	p.global_position = pos
	p.emission_box_extents = Vector3(half.x, half.y, 0.05)
	p.global_transform = Transform3D(basis, pos)
	p.direction = (basis.inverse() * (dir + Vector3(0, 0.3, 0))).normalized()
	p.color = col
	p.amount = 70 if quality > 0 else 35
	p.restart()
	p.emitting = true


func flash(pos: Vector3, col: Color, energy := 2.5) -> void:
	light.global_position = pos
	light.light_color = col
	light.light_energy = energy
	light.visible = true


## a crack that spreads fast over a pane at the moment it goes
func crack_burst(xf: Transform3D, size: float) -> void:
	var m := MeshInstance3D.new()
	m.mesh = crack_quad
	m.material_override = crack_mat
	add_child(m)
	m.global_transform = xf
	m.rotate_object_local(Vector3(0, 0, 1), randf() * TAU)
	cracks.append({"node": m, "t": 0.0, "size": size})


func beam(a: Vector3, b: Vector3, col: Color, life := 0.6, width := 0.07) -> void:
	beams.append({"a": a, "b": b, "c": col, "t": 0.0, "life": life, "w": width})


func _quad_line(a: Vector3, b: Vector3, w0: float, w1: float, c0: Color, c1: Color) -> void:
	var view := (cam.global_position - (a + b) * 0.5).normalized()
	var d := (b - a)
	if d.length_squared() < 1e-8:
		return
	var side := d.cross(view).normalized()
	var a0 := a + side * w0
	var a1 := a - side * w0
	var b0 := b + side * w1
	var b1 := b - side * w1
	lines.surface_set_color(c0)
	lines.surface_add_vertex(a0)
	lines.surface_set_color(c1)
	lines.surface_add_vertex(b0)
	lines.surface_add_vertex(b1)
	lines.surface_set_color(c0)
	lines.surface_add_vertex(a0)
	lines.surface_set_color(c1)
	lines.surface_add_vertex(b1)
	lines.surface_set_color(c0)
	lines.surface_add_vertex(a1)


## each frame: the light fades, cracks grow and fade, trails and beams are drawn
func step(dt: float, trails: Array) -> void:
	if light.visible:
		light.light_energy *= exp(-dt * 14.0)
		if light.light_energy < 0.05:
			light.visible = false
	var i := cracks.size() - 1
	while i >= 0:
		var c: Dictionary = cracks[i]
		c.t += dt
		var k: float = c.t / 0.3
		var n: MeshInstance3D = c.node
		var s: float = c.size * (0.3 + 0.7 * minf(1.0, k * 2.5))
		n.scale = Vector3(s, s, 1)
		n.transparency = clampf((k - 0.5) * 2.0, 0.0, 1.0)
		if k >= 1.0:
			n.queue_free()
			cracks.remove_at(i)
		i -= 1
	lines.clear_surfaces()
	var any := false
	for tr in trails:
		var pts: Array = tr.pts
		if pts.size() >= 2:
			any = true
			break
	if not any and beams.is_empty():
		return
	lines.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# a triangle of nothing, so the surface is never empty
	lines.surface_set_color(Color(0, 0, 0, 0))
	for k in 3:
		lines.surface_add_vertex(cam.global_position + Vector3(0, -50, 0))
	for tr in trails:
		var pts: Array = tr.pts
		var col: Color = tr.col
		var n := pts.size()
		for k in range(n - 1):
			var f0 := float(k) / n
			var f1 := float(k + 1) / n
			_quad_line(pts[k], pts[k + 1], 0.06 * f0, 0.06 * f1, Color(col, 0.5 * f0), Color(col, 0.5 * f1))
	var j := beams.size() - 1
	while j >= 0:
		var b: Dictionary = beams[j]
		b.t += dt
		var k: float = b.t / b.life
		if k >= 1.0:
			beams.remove_at(j)
		else:
			var col: Color = b.c
			var a := 1.0 - k
			_quad_line(b.a, b.b, b.w, b.w, Color(col, a), Color(col, a * 0.8))
			_quad_line(b.a, b.b, b.w * 0.35, b.w * 0.35, Color(1, 1, 1, a), Color(1, 1, 1, a))
		j -= 1
	lines.surface_end()
