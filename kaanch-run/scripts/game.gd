## Kaanch Run: you fly down a hall of rooms; tap to throw balls and break the glass before you reach it.
## Running into glass costs ten balls; crystals give three. Each room ends at a checkpoint door.
extends Node3D

const EYE := 2.2
const ROOM_LEN := 200.0
const START_BALLS := 25
const SEG := Corridor.SEG
const HALF_W := Corridor.HALF_W
const CEIL := Corridor.CEIL
const BALL_SPEED := 52.0
const GRAV := 4.0

enum S { TITLE, PLAY, PAUSE, OVER }


class Pane:
	var node: MeshInstance3D
	var poly: PackedVector2Array
	var kind := "thin"
	var hp := 1
	var blocks := true
	var alive := true
	var base: Transform3D
	var gate
	var move: Callable
	var cracks: Array = []


class Gate:
	var d := 0.0
	var kind := ""
	var panes: Array = []
	var passed := false
	var ph := 0.0
	var side := 1
	var extra: Array = []
	var hub = null
	var door := false


class Crystal:
	var node: Node3D
	var pos: Vector3
	var alive := true
	var hub_of = null


var state := S.TITLE
var dist := 0.0
var speed := 0.0
var balls := START_BALLS
var streak := 0
var multi := 1
var cp_room := 0
var room := -1
var t := 0.0
var shake := 0.0
var over_t := -1.0
var best := 0
var broken := 0

var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var hud: Hud
var sfx: Sfx
var world: Node3D

var segs: Array = []
var gates: Array = []
var panes: Array = []
var crystals: Array = []
var flying: Array = []
var shards: Array = []
var next_seg := 0
var next_obs := 30.0
var last_kind := ""
var pal_now := {}
var pal_to := {}

var ball_mesh: SphereMesh
var ball_mat: StandardMaterial3D
var crystal_mesh: ArrayMesh
var crystal_mat: StandardMaterial3D
var hub_mat: StandardMaterial3D
var glow_tex: Texture2D
var crack_tex: Texture2D
var crack_mat: StandardMaterial3D
var chain_mat: StandardMaterial3D

# testing from the command line: --auto plays by itself, --shots=d1,d2 saves pictures, --quit-at=d stops
var auto := false
var shots: Array = []
var quit_at := -1.0
var shot_dir := "user://"
var log_t := 0.0
var crashes := 0
var test_screen := ""
var _frames := 0


func _ready() -> void:
	randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--auto":
			auto = true
		elif a.begins_with("--shots="):
			for s in a.substr(8).split(","):
				shots.append(float(s))
		elif a.begins_with("--quit-at="):
			quit_at = float(a.substr(10))
		elif a.begins_with("--shot-dir="):
			shot_dir = a.substr(11)
		elif a.begins_with("--screen="):
			test_screen = a.substr(9)
	_load()
	Glass.mats()
	_make_world()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.sound_on = _cfg_sound
	sfx.music_on = _cfg_music
	hud = Hud.new()
	add_child(hud)
	hud.set_toggles(_cfg_sound, _cfg_music)
	hud.start_pressed.connect(_on_start)
	hud.resume_pressed.connect(_resume)
	hud.restart_pressed.connect(func(): _begin(0))
	hud.continue_pressed.connect(func(): _begin(cp_room))
	hud.menu_pressed.connect(_to_title)
	hud.pause_pressed.connect(_pause)
	hud.sound_toggled.connect(_on_sound)
	hud.music_toggled.connect(_on_music)
	_reset_world(0)
	hud.show_title(best)
	if auto:
		_begin(0)
	if test_screen != "":
		_screen_test()


func _on_sound(on: bool) -> void:
	sfx.sound_on = on
	_cfg_sound = on
	_save()


func _on_music(on: bool) -> void:
	sfx.set_music(on)
	_cfg_music = on
	_save()


# ---------- saving ----------
var _cfg_sound := true
var _cfg_music := true


func _load() -> void:
	var c := ConfigFile.new()
	if c.load("user://kaanch_run.cfg") == OK:
		best = c.get_value("run", "best", 0)
		cp_room = c.get_value("run", "cp", 0)
		_cfg_sound = c.get_value("opt", "sound", true)
		_cfg_music = c.get_value("opt", "music", true)


func _save() -> void:
	var c := ConfigFile.new()
	c.set_value("run", "best", best)
	c.set_value("run", "cp", cp_room)
	c.set_value("opt", "sound", _cfg_sound)
	c.set_value("opt", "music", _cfg_music)
	c.save("user://kaanch_run.cfg")


# ---------- the scene ----------
func _make_world() -> void:
	world = Node3D.new()
	add_child(world)
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.05
	cam.far = 220.0
	add_child(cam)
	cam.current = true
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	sun.light_energy = 1.25
	add_child(sun)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_density = 0.011
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
	ball_mesh = SphereMesh.new()
	ball_mesh.radius = 0.13
	ball_mesh.height = 0.26
	ball_mesh.radial_segments = 16
	ball_mesh.rings = 8
	ball_mat = StandardMaterial3D.new()
	ball_mat.albedo_color = Color("c9d3da")
	ball_mat.metallic = 0.9
	ball_mat.roughness = 0.2
	crystal_mesh = _octa(0.32, 0.5)
	crystal_mat = StandardMaterial3D.new()
	crystal_mat.albedo_color = Color(0.55, 1.0, 0.95, 0.85)
	crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_mat.emission_enabled = true
	crystal_mat.emission = Color("19c9b2")
	crystal_mat.emission_energy_multiplier = 1.3
	crystal_mat.metallic = 0.3
	crystal_mat.roughness = 0.05
	hub_mat = crystal_mat.duplicate()
	hub_mat.albedo_color = Color(1.0, 0.86, 0.45, 0.9)
	hub_mat.emission = Color("ff9a1f")
	chain_mat = StandardMaterial3D.new()
	chain_mat.albedo_color = Color("2b3138")
	chain_mat.metallic = 0.8
	chain_mat.roughness = 0.35
	glow_tex = _glow_texture()
	crack_tex = _crack_texture()
	crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_texture = crack_tex
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _octa(r: float, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, h, 0)
	var bot := Vector3(0, -h, 0)
	var ring := []
	for i in 4:
		var a := TAU * i / 4.0
		ring.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		for tri in [[top, b, a], [bot, a, b]]:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			st.set_normal(-n)
			for v in tri:
				st.add_vertex(v)
	return st.commit()


func _glow_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.9))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	return gt


## white cracks spreading from a point, drawn once
func _crack_texture() -> Texture2D:
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Vector2(S, S) * 0.5
	for k in 11:
		var a := TAU * k / 11.0 + randf_range(-0.2, 0.2)
		var p := c
		var len := randf_range(0.55, 1.0) * S * 0.48
		var steps := int(len)
		var dir := Vector2(cos(a), sin(a))
		for i in steps:
			if i % 18 == 0:
				dir = dir.rotated(randf_range(-0.35, 0.35))
			p += dir
			var al := 1.0 - float(i) / steps * 0.7
			for o in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)]:
				var q: Vector2 = p + o
				if q.x >= 0 and q.y >= 0 and q.x < S and q.y < S:
					img.set_pixelv(Vector2i(q), Color(1, 1, 1, al))
	# a ring round the middle
	for i in 360:
		var a := deg_to_rad(i)
		var q := c + Vector2(cos(a), sin(a)) * (S * 0.08 + sin(a * 5.0) * 3.0)
		img.set_pixelv(Vector2i(q), Color(1, 1, 1, 0.9))
	return ImageTexture.create_from_image(img)


# ---------- starting, pausing, ending ----------
func _on_start() -> void:
	if state != S.TITLE:
		return
	_begin(0)


func _begin(from_room: int) -> void:
	_reset_world(from_room)
	state = S.PLAY
	balls = START_BALLS
	streak = 0
	multi = 1
	over_t = -1.0
	broken = 0
	speed = 0.0
	hud.show_play()
	hud.set_balls(balls, multi)
	hud.show_toast("Room %d" % (from_room + 1) if from_room > 0 else "Go!", Hud.ACCENT, 0.5)
	sfx.play("tick")


func _pause() -> void:
	if state != S.PLAY:
		return
	state = S.PAUSE
	hud.show_pause()
	sfx.play("tick")


func _resume() -> void:
	if state != S.PAUSE:
		return
	state = S.PLAY
	hud.show_play()
	sfx.play("tick")


func _to_title() -> void:
	state = S.TITLE
	_reset_world(0)
	hud.show_title(best)


func _game_over() -> void:
	state = S.OVER
	var d := int(dist)
	var nb := d > best
	if nb:
		best = d
	_save()
	hud.show_over(d, best, int(cp_room * ROOM_LEN), nb)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not auto:
			_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == S.PLAY:
			_pause()
		elif state == S.PAUSE:
			_resume()


# ---------- building the way ahead ----------
func _clear(list: Array) -> void:
	for o in list:
		if o is Node:
			o.queue_free()
	list.clear()


func _reset_world(from_room: int) -> void:
	for c in world.get_children():
		c.queue_free()
	segs.clear()
	gates.clear()
	panes.clear()
	crystals.clear()
	flying.clear()
	shards.clear()
	dist = from_room * ROOM_LEN
	room = -1
	next_seg = int(floor(dist / SEG))
	next_obs = dist + 30.0
	last_kind = ""
	t = 0.0
	_set_room(from_room, true)
	_stream()
	_place_camera(0.0)


func _room_of(d: float) -> int:
	return int(floor(d / ROOM_LEN))


func _door_d(r: int) -> float:
	return (r + 1) * ROOM_LEN - 6.0


func _set_room(r: int, now := false) -> void:
	if r == room:
		return
	room = r
	pal_to = Corridor.palette(r)
	if now or pal_now.is_empty():
		pal_now = pal_to.duplicate()
	_apply_palette()


func _apply_palette() -> void:
	env.background_color = pal_now.bg
	env.fog_light_color = pal_now.bg
	env.ambient_light_color = pal_now.amb
	sun.light_color = pal_now.sun
	Glass.rim_mat.albedo_color = pal_now.rim


func _stream() -> void:
	while next_seg * SEG < dist + 150.0:
		var d0 := next_seg * SEG
		var r := _room_of(d0)
		var seg := Corridor.build(d0, r, next_seg * 7919 + 13)
		world.add_child(seg)
		segs.append({"node": seg, "d": d0})
		_spawn_in(d0, d0 + SEG)
		next_seg += 1
	while segs.size() and segs[0].d + SEG < dist - 6.0:
		segs[0].node.queue_free()
		segs.pop_front()


func _spawn_in(a: float, b: float) -> void:
	# the checkpoint door at the end of each room
	var r := _room_of(a)
	var dd := _door_d(r)
	if dd >= a and dd < b:
		_door(dd)
	while next_obs < b:
		var d := next_obs
		var rr := _room_of(d)
		var door := _door_d(rr)
		if d > door - 16.0 and d < door + 14.0:
			next_obs = door + 18.0
			continue
		var kind := _pick_kind(rr)
		_gate(kind, d, rr)
		var gap := lerpf(22.0, 15.0, clampf(rr / 6.0, 0.0, 1.0)) + randf() * 5.0
		if kind == "layers":
			gap += 6.0
		if randf() < 0.65:
			_crystals(d + gap * 0.5, rr)
		next_obs += gap


func _pick_kind(r: int) -> String:
	var pool := ["pane", "split", "grid", "layers"]
	if r >= 1:
		pool += ["doors", "thick", "stack"]
	if r >= 2:
		pool += ["spinner", "rotor"]
	if r >= 3:
		pool += ["pendulum", "slab"]
	var k: String = pool.pick_random()
	if k == last_kind:
		k = pool.pick_random()
	last_kind = k
	return k


func _kind(r: int) -> String:
	var x := randf()
	if r >= 3 and x < 0.1:
		return "slab"
	if x < 0.45:
		return "thin"
	if x < 0.8 or r < 1:
		return "mid"
	return "thick"


# ---------- glass ----------
func _pane(g: Gate, poly_xy: PackedVector2Array, d: float, kind: String, blocks := true) -> Pane:
	var c := Glass.centroid(poly_xy)
	var local := Glass.ccw(Glass.moved(poly_xy, -c))
	var mi := MeshInstance3D.new()
	mi.mesh = Glass.slab_mesh(local, kind)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, c.y, -d)
	world.add_child(mi)
	var p := Pane.new()
	p.node = mi
	p.poly = local
	p.kind = kind
	p.hp = Glass.KINDS[kind].hp
	p.blocks = blocks
	p.base = mi.transform
	p.gate = g
	g.panes.append(p)
	panes.append(p)
	return p


func _new_gate(kind: String, d: float) -> Gate:
	var g := Gate.new()
	g.kind = kind
	g.d = d
	g.ph = randf() * TAU
	g.side = 1 if randf() < 0.5 else -1
	gates.append(g)
	return g


## turn a pane about a point in the plane of the hall (z axis)
func _spin_about(p: Pane, pivot: Vector2, ang: float) -> void:
	var b := Basis(Vector3(0, 0, 1), ang)
	var o := p.base.origin - Vector3(pivot.x, pivot.y, p.base.origin.z)
	p.node.transform = Transform3D(b, Vector3(pivot.x, pivot.y, p.base.origin.z) + b * o)


func _gate(kind: String, d: float, r: int) -> void:
	var g := _new_gate(kind, d)
	var s := g.side
	match kind:
		"pane":
			_pane(g, Glass.rect(-2.4, 2.4, 0.5, 3.9), d, _kind(r))
		"split":
			var cut := s * randf_range(0.5, 1.2)
			var thin_left := randf() < 0.5
			_pane(g, Glass.rect(-2.4, cut - 0.03, 0.5, 3.9), d, "thin" if thin_left else "thick")
			_pane(g, Glass.rect(cut + 0.03, 2.4, 0.5, 3.9), d, "thick" if thin_left else "thin")
		"thick":
			_pane(g, Glass.rect(-2.0, 2.0, 0.7, 3.7), d, "thick")
		"slab":
			_pane(g, Glass.rect(-1.7, 1.7, 0.85, 3.55), d, "slab")
		"grid":
			for cx in 3:
				for cy in 3:
					var x0 := -2.4 + cx * 1.6
					var y0 := 0.5 + cy * 1.15
					_pane(g, Glass.rect(x0 + 0.03, x0 + 1.57, y0 + 0.03, y0 + 1.12), d, _kind(r))
		"stack":
			for i in 5:
				var x0 := -2.4 + i * 0.96
				_pane(g, Glass.rect(x0 + 0.04, x0 + 0.92, 0.4, 4.0), d, _kind(r))
		"layers":
			var n := 2 if r < 2 else 3
			for i in n:
				var gi := g if i == 0 else _new_gate("layers", d + i * 3.2)
				var w := randf_range(1.0, 1.8)
				var h := randf_range(1.0, 1.6)
				var ox := randf_range(-0.4, 0.4)
				var oy := randf_range(-0.3, 0.3)
				var poly := Glass.rect(ox - w, ox + w, EYE + oy - h, EYE + oy + h) if randf() < 0.6 else Glass.ngon(6, randf_range(1.2, 1.5), Vector2(ox, EYE + oy), PI / 6.0)
				_pane(gi, poly, d + i * 3.2, ["thin", "mid", "thick"].pick_random())
		"doors":
			for i in 2:
				var sd := -1 if i == 0 else 1
				var p := _pane(g, Glass.rect(-2.4, 0.0, 0.5, 3.9) if i == 0 else Glass.rect(0.0, 2.4, 0.5, 3.9), d, "mid" if r < 3 else "thick")
				p.move = func(pp: Pane, _gt: float, ahead: float):
					var k := clampf((ahead - 4.0) / 10.0, 0.0, 1.0)
					var e := k * k * (3.0 - 2.0 * k)
					pp.node.transform = pp.base.translated(Vector3(sd * 2.6 * e, 0, 0))
				p.move.call(p, 0.0, 99.0)
		"spinner":
			var hub := Vector2(s * 1.1, EYE + 0.55)
			var w := (1.3 + minf(r, 6) * 0.07) * (1 if randf() < 0.5 else -1)
			var a0 := randf() * TAU
			var blade := PackedVector2Array([Vector2(0.35, -0.28), Vector2(2.7, -0.16), Vector2(2.9, 0.0), Vector2(2.7, 0.16), Vector2(0.35, 0.28)])
			for i in 3:
				var p := _pane(g, Glass.moved(blade, hub), d, "thin" if r < 4 else "mid")
				var off := a0 + TAU * i / 3.0
				p.move = func(pp: Pane, gt: float, _ahead: float):
					_spin_about(pp, hub, off + gt * w)
				p.move.call(p, 0.0, 99.0)
			var c := _crystal(Vector3(hub.x, hub.y, -d + 0.1), true)
			c.hub_of = g
			g.hub = c
		"rotor":
			var w := (1.0 + randf() * 0.5) * s
			var bars := 1 if r < 4 else 2
			for i in bars:
				var p := _pane(g, Glass.rect(-2.1, 2.1, EYE - 0.42, EYE + 0.42), d - i * 0.05, "mid")
				var off := randf() * PI + i * PI * 0.5
				p.move = func(pp: Pane, gt: float, _ahead: float):
					_spin_about(pp, Vector2(0, EYE), off + gt * w)
				p.move.call(p, 0.0, 99.0)
		"pendulum":
			var L := 3.9
			var pivot := Vector2(0, EYE + L)
			var p := _pane(g, Glass.ngon(8, 1.05, Vector2(0, EYE), PI / 8.0), d, "thick" if r < 5 else "slab")
			var chain := MeshInstance3D.new()
			var cm := BoxMesh.new()
			cm.size = Vector3(0.05, L - 1.0, 0.05)
			chain.mesh = cm
			chain.material_override = chain_mat
			chain.position = Vector3(0, 1.0 + (L - 1.0) * 0.5, 0)
			p.node.add_child(chain)
			var amp := 0.62
			var ws := 1.55 + minf(r, 6) * 0.05
			var ph := g.ph
			p.move = func(pp: Pane, gt: float, _ahead: float):
				_spin_about(pp, pivot, sin(gt * ws + ph) * amp)
			p.move.call(p, 0.0, 99.0)


func _door(d: float) -> void:
	var g := _new_gate("door", d)
	g.door = true
	_pane(g, Glass.rect(-HALF_W + 0.1, HALF_W - 0.1, 0.05, CEIL - 0.1), d, "thin")
	# a glowing frame round the door
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acc: Color = Corridor.palette(_room_of(d)).accent
	Corridor.box(st, Vector3(0, CEIL - 0.05, -d), Vector3(HALF_W * 2, 0.12, 0.12), acc)
	Corridor.box(st, Vector3(-HALF_W + 0.05, CEIL * 0.5, -d), Vector3(0.12, CEIL, 0.12), acc)
	Corridor.box(st, Vector3(HALF_W - 0.05, CEIL * 0.5, -d), Vector3(0.12, CEIL, 0.12), acc)
	st.set_material(Corridor.glow_mat)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	world.add_child(mi)
	g.extra.append(mi)


func _crystal(pos: Vector3, is_hub := false) -> Crystal:
	var n := Node3D.new()
	n.position = pos
	world.add_child(n)
	var m := MeshInstance3D.new()
	m.mesh = crystal_mesh
	m.material_override = hub_mat if is_hub else crystal_mat
	if is_hub:
		m.scale = Vector3.ONE * 0.85
	n.add_child(m)
	var sp := Sprite3D.new()
	sp.texture = glow_tex
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.modulate = Color(1.0, 0.75, 0.35, 0.7) if is_hub else Color(0.45, 1.0, 0.92, 0.6)
	sp.pixel_size = 0.012
	sp.shaded = false
	sp.no_depth_test = false
	sp.transparent = true
	n.add_child(sp)
	var c := Crystal.new()
	c.node = n
	c.pos = pos
	crystals.append(c)
	return c


func _crystals(d: float, _r: int) -> void:
	var n := 1 + (randi() % 3)
	var x0 := randf_range(-2.6, 2.6)
	var y0 := randf_range(0.9, 4.2)
	for i in n:
		_crystal(Vector3(clampf(x0 + i * 0.9 * signf(-x0 + 0.01), -3.6, 3.6), y0 + sin(i) * 0.3, -(d + i * 1.4)))


# ---------- each frame ----------
func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 20.0)
	if state == S.PAUSE:
		return
	if state == S.TITLE:
		# the hall drifts past behind the title
		dist += 4.0 * dt
		t += dt
		_stream()
		_move_gates()
		_spin_crystals(dt)
		_place_camera(dt)
		_palette_step(dt)
		return
	if state == S.OVER:
		_update_shards(dt)
		_update_balls(dt)
		_palette_step(dt)
		return
	t += dt
	var want := 10.0 + minf(room, 8) * 0.6
	speed = lerpf(speed, want, 1.0 - exp(-dt * 1.6))
	var prev := dist
	dist += speed * dt
	_stream()
	_move_gates()
	_spin_crystals(dt)
	_check_gates(prev)
	_update_balls(dt)
	_update_shards(dt)
	_place_camera(dt)
	_palette_step(dt)
	# a new room
	var r := _room_of(dist)
	if r != room:
		_set_room(r)
	hud.set_balls(balls, multi)
	var into := fmod(dist, ROOM_LEN) / ROOM_LEN
	hud.set_dist(dist, into)
	# out of balls (and none still flying that might hit a crystal)
	if balls <= 0 and flying.is_empty():
		if over_t < 0.0:
			over_t = t
		elif t - over_t > 0.9:
			_game_over()
	else:
		over_t = -1.0
	if auto:
		_auto_play(dt)
	_test_hooks()


func _palette_step(dt: float) -> void:
	if pal_to.is_empty():
		return
	var k := 1.0 - exp(-dt * 1.5)
	var changed := false
	for key in ["bg", "amb", "sun", "rim"]:
		var a: Color = pal_now[key]
		var b: Color = pal_to[key]
		if not a.is_equal_approx(b):
			pal_now[key] = a.lerp(b, k)
			changed = true
	if changed:
		_apply_palette()


func _place_camera(dt: float) -> void:
	shake = maxf(0.0, shake - dt * 1.8)
	var sway := sin(dist * 0.11) * 0.06
	var bob := sin(dist * 0.9) * 0.025 if state == S.PLAY else 0.0
	var off := Vector3.ZERO
	if shake > 0.0:
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.35
	cam.position = Vector3(sway, EYE + bob, -dist) + off
	cam.rotation = Vector3(deg_to_rad(-2.5), sin(dist * 0.05) * 0.015, sin(dist * 0.07) * 0.012 + off.x * 0.1)
	# a wider view the faster you go
	cam.fov = 70.0 + clampf((speed - 9.0) * 0.9, 0.0, 8.0)


func _move_gates() -> void:
	for g in gates:
		var ahead: float = g.d - dist
		if ahead < -4.0 or ahead > 60.0:
			continue
		for p in g.panes:
			if p.alive and p.move.is_valid():
				p.move.call(p, t + g.ph * 0.0, ahead)
	# the ones far behind are taken away
	while gates.size() and gates[0].d < dist - 8.0:
		var g: Gate = gates.pop_front()
		for p in g.panes:
			if p.alive:
				p.node.queue_free()
			panes.erase(p)
		for e in g.extra:
			e.queue_free()


func _spin_crystals(dt: float) -> void:
	var i := crystals.size() - 1
	while i >= 0:
		var c: Crystal = crystals[i]
		if not c.alive or -c.pos.z < dist - 6.0:
			if c.alive:
				c.node.queue_free()
			crystals.remove_at(i)
		else:
			c.node.rotate_y(dt * 1.8)
		i -= 1


## did you reach a gate with glass still in front of your face?
func _check_gates(prev: float) -> void:
	for g in gates:
		if g.passed or not (prev < g.d and dist >= g.d):
			continue
		g.passed = true
		var hit := []
		var eye := Vector3(cam.position.x, EYE, 0)
		for p in g.panes:
			if not p.alive or not p.blocks:
				continue
			var gp: Vector3 = p.node.global_transform.origin
			var l: Vector3 = p.node.global_transform.affine_inverse() * Vector3(eye.x, eye.y, gp.z)
			if Glass.inside(p.poly, Vector2(l.x, l.y), 0.25):
				hit.append([p, Vector2(l.x, l.y)])
		if hit.size():
			_crash(hit)
		elif g.door:
			_checkpoint(g)


func _crash(hit: Array) -> void:
	crashes += 1
	for h in hit:
		_break(h[0], h[1], Vector3(0, 0, -1), true)
	balls = maxi(0, balls - 10)
	streak = 0
	multi = 1
	shake = 1.0
	hud.flash_screen(Color("ff3b3b"), 0.5, 0.5)
	hud.show_toast("−10", Color("ff6b6b"), 0.5)
	sfx.play("crash", 0.0, randf_range(0.95, 1.05))
	Input.vibrate_handheld(90)


func _checkpoint(g: Gate) -> void:
	var r := _room_of(g.d) + 1
	if r > cp_room:
		cp_room = r
		_save()
	hud.show_toast("CHECKPOINT", Hud.ACCENT, 0.8)
	hud.flash_screen(Color.WHITE, 0.35, 0.6)
	sfx.play("checkpoint", -2.0)


# ---------- throwing ----------
func _unhandled_input(e: InputEvent) -> void:
	if state != S.PLAY:
		return
	if e is InputEventScreenTouch and e.pressed:
		_throw_at(e.position)


func _throw_at(screen: Vector2) -> void:
	if balls <= 0:
		sfx.play("tick", -6.0, 0.6)
		return
	var dir := cam.project_ray_normal(screen)
	_throw(dir)


func _throw(dir: Vector3) -> void:
	balls -= 1
	var from := cam.position + dir * 0.6 + Vector3(0, -0.12, 0)
	var n := multi
	for i in n:
		var d2 := dir
		if i > 0:
			d2 = dir.rotated(Vector3.UP, (0.035 if i == 1 else -0.035))
		var mi := MeshInstance3D.new()
		mi.mesh = ball_mesh
		mi.material_override = ball_mat
		mi.position = from
		world.add_child(mi)
		flying.append({"node": mi, "v": d2 * (BALL_SPEED + speed), "life": 0.0})
	sfx.play("throw", -10.0, randf_range(0.9, 1.15))
	hud.set_balls(balls, multi)


func _update_balls(dt: float) -> void:
	var i := flying.size() - 1
	while i >= 0:
		var b: Dictionary = flying[i]
		var node: MeshInstance3D = b.node
		var a: Vector3 = node.position
		var v: Vector3 = b.v
		v.y -= GRAV * dt
		var nb := a + v * dt
		var done := false
		# glass in the way of this step?
		for p in panes:
			if not p.alive:
				continue
			var pz: float = p.node.global_transform.origin.z
			if absf(pz - a.z) > 4.0 and absf(pz - nb.z) > 4.0:
				continue
			var inv: Transform3D = p.node.global_transform.affine_inverse()
			var la: Vector3 = inv * a
			var lb: Vector3 = inv * nb
			if la.z * lb.z > 0.0 or la.z == lb.z:
				continue
			var s := la.z / (la.z - lb.z)
			var lh := la.lerp(lb, s)
			if not Glass.inside(p.poly, Vector2(lh.x, lh.y)):
				continue
			if _hit(p, Vector2(lh.x, lh.y), v.normalized()):
				v *= 0.85
			else:
				# it holds: the ball bounces back off it
				var nrm: Vector3 = p.node.global_transform.basis.z.normalized()
				v = (v - 2.0 * v.dot(nrm) * nrm) * 0.3
				nb = a
			break
		# crystals
		for c in crystals:
			if not c.alive:
				continue
			if _seg_dist(a, nb, c.node.position) < 0.6:
				_collect(c)
		# the floor, the walls
		if nb.y < 0.13:
			nb.y = 0.13
			v.y = absf(v.y) * 0.45
			v.x *= 0.8
		if absf(nb.x) > HALF_W - 0.13:
			nb.x = signf(nb.x) * (HALF_W - 0.13)
			v.x = -v.x * 0.5
		node.position = nb
		b.v = v
		b.life += dt
		if b.life > 2.2 or -nb.z < dist - 3.0:
			done = true
		if done:
			node.queue_free()
			flying.remove_at(i)
		i -= 1


func _seg_dist(a: Vector3, b: Vector3, p: Vector3) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 1e-8:
		return a.distance_to(p)
	var s := clampf((p - a).dot(ab) / l, 0.0, 1.0)
	return (a + ab * s).distance_to(p)


## a ball hits a pane: true if it breaks
func _hit(p: Pane, lp: Vector2, dir: Vector3) -> bool:
	p.hp -= 1
	if p.hp <= 0:
		_break(p, lp, dir)
		return true
	_crack(p, lp)
	return false


func _crack(p: Pane, lp: Vector2) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	var sz := 1.1 + p.cracks.size() * 0.35
	qm.size = Vector2(sz, sz)
	q.mesh = qm
	q.material_override = crack_mat
	var hz: float = Glass.KINDS[p.kind].t * 0.5 + 0.01
	q.position = Vector3(lp.x, lp.y, hz)
	q.rotation.z = randf() * TAU
	p.node.add_child(q)
	p.cracks.append(q)
	sfx.play("crack", -2.0, randf_range(0.9, 1.1))
	Input.vibrate_handheld(15)


func _break(p: Pane, lp: Vector2, dir: Vector3, crash := false) -> void:
	if not p.alive:
		return
	p.alive = false
	broken += 1
	var xf: Transform3D = p.node.global_transform
	var K: Dictionary = Glass.KINDS[p.kind]
	var count: int = K.pieces
	var cells := Glass.voronoi(p.poly, Glass.seeds_for(p.poly, lp, count))
	var hit_w: Vector3 = xf * Vector3(lp.x, lp.y, 0)
	for cell in cells:
		var cc := Glass.centroid(cell)
		var local := Glass.moved(cell, -cc)
		var mi := MeshInstance3D.new()
		mi.mesh = Glass.slab_mesh(local, p.kind, 0.6)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(mi)
		mi.global_transform = xf * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		var away: Vector3 = mi.global_transform.origin - hit_w
		var v := away.normalized() * randf_range(1.5, 4.5) + dir * randf_range(2.0, 6.0) + Vector3(0, randf_range(0.5, 2.5), 0)
		if crash:
			v = away.normalized() * randf_range(2.0, 5.0) + Vector3(0, randf_range(1.0, 3.0), -speed * 0.6)
		var axis := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		shards.append({"node": mi, "v": v, "axis": axis, "w": randf_range(3.0, 11.0), "life": 0.0})
	p.node.queue_free()
	# not too many pieces at once
	while shards.size() > 260:
		var s: Dictionary = shards.pop_front()
		s.node.queue_free()
	var area := absf(Glass.area(p.poly))
	var v := clampi(int(3.0 - area * 0.4), 0, 2)
	sfx.play("shatter%d" % v, -1.0 if area > 3.0 else -4.0, randf_range(0.92, 1.12))
	if not crash:
		Input.vibrate_handheld(20)


func _update_shards(dt: float) -> void:
	var i := shards.size() - 1
	while i >= 0:
		var s: Dictionary = shards[i]
		var n: MeshInstance3D = s.node
		var v: Vector3 = s.v
		v.y -= 14.0 * dt
		var pos := n.position + v * dt
		if pos.y < 0.06:
			pos.y = 0.06
			v.y = absf(v.y) * 0.3
			v.x *= 0.6
			v.z *= 0.6
			s.w *= 0.6
		n.position = pos
		n.rotate(s.axis, s.w * dt)
		s.v = v
		s.life += dt
		if s.life > 5.0 or -pos.z < dist - 4.0:
			n.queue_free()
			shards.remove_at(i)
		i -= 1


func _collect(c: Crystal) -> void:
	c.alive = false
	var at := cam.unproject_position(c.node.position) if not cam.is_position_behind(c.node.position) else Vector2(640, 300)
	if c.hub_of:
		# the hub of a spinning fan: the whole fan comes apart
		var g: Gate = c.hub_of
		for p in g.panes:
			if p.alive:
				_break(p, Vector2.ZERO, Vector3(0, 0, -1))
		balls += 2
		hud.popup("+2", at, Color("ffc861"))
	else:
		balls += 3
		streak += 1
		hud.popup("+3", at)
		var want := 3 if streak >= 25 else 2 if streak >= 10 else 1
		if want > multi:
			multi = want
			hud.show_toast("×%d BALLS" % multi, Hud.ACCENT, 0.6)
			sfx.play("multi", -2.0)
	sfx.play("crystal", -3.0, randf_range(0.95, 1.08))
	# a little burst of crystal pieces
	var hex := Glass.ngon(6, 0.38)
	var cells := Glass.voronoi(hex, Glass.seeds_for(hex, Vector2(0.05, 0.02), 6))
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := MeshInstance3D.new()
		mi.mesh = Glass.slab_mesh(Glass.moved(cell, -cc), "mid", 0.5)
		world.add_child(mi)
		mi.global_position = c.node.position + Vector3(cc.x, cc.y, 0)
		shards.append({"node": mi, "v": Vector3(cc.x, cc.y + 0.3, 0).normalized() * randf_range(2.0, 4.0), "axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), "w": randf_range(4.0, 12.0), "life": 0.0})
	c.node.queue_free()
	hud.set_balls(balls, multi)


# ---------- testing ----------
func _screen_test() -> void:
	await get_tree().create_timer(0.1).timeout
	for i in 50:
		await get_tree().process_frame
	if test_screen == "pause":
		_begin(1)
		for i in 40:
			await get_tree().process_frame
		_pause()
	elif test_screen == "over":
		_begin(0)
		for i in 40:
			await get_tree().process_frame
		dist = 347.0
		_game_over()
	for i in 20:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir + "screen_%s.png" % test_screen)
	get_tree().quit()



var _fired := {}


func _auto_play(_dt: float) -> void:
	# a simple player: throws at glass in front of the eye, at crystals and at fan hubs
	var best_target = null
	var best_d := 1e9
	var eye := Vector3(cam.position.x, EYE, 0)
	for p in panes:
		if not p.alive or not p.blocks:
			continue
		var gz: float = p.node.global_transform.origin.z
		var ahead := -gz - dist
		if ahead < 5.0 or ahead > 24.0:
			continue
		var l: Vector3 = p.node.global_transform.affine_inverse() * Vector3(eye.x, eye.y, gz)
		if not Glass.inside(p.poly, Vector2(l.x, l.y), 0.3):
			continue
		var key: int = p.get_instance_id()
		if _fired.has(key) and t - _fired[key] < 0.28:
			continue
		if ahead < best_d:
			best_d = ahead
			best_target = [key, Vector3(eye.x, eye.y, gz)]
	for c in crystals:
		if not c.alive:
			continue
		var ahead: float = -c.node.position.z - dist
		if ahead < 6.0 or ahead > 22.0:
			continue
		var key: int = c.get_instance_id()
		if _fired.has(key) and t - _fired[key] < 0.5:
			continue
		if ahead < best_d:
			best_d = ahead
			best_target = [key, c.node.position]
	if best_target and balls > 0:
		_fired[best_target[0]] = t
		var to: Vector3 = best_target[1]
		var tt := (to - cam.position).length() / (BALL_SPEED + speed)
		to.y += 0.5 * GRAV * tt * tt
		_throw((to - cam.position).normalized())


func _test_hooks() -> void:
	log_t += 1.0
	if int(log_t) % 120 == 0:
		print("d=%d balls=%d crashes=%d broken=%d shards=%d panes=%d fps=%d" % [int(dist), balls, crashes, broken, shards.size(), panes.size(), Engine.get_frames_per_second()])
	if shots.size() and dist >= shots[0]:
		var d := int(shots.pop_front())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_dir + "shot_%d.png" % d)
	if quit_at > 0.0 and dist >= quit_at:
		print("END d=%d balls=%d crashes=%d broken=%d" % [int(dist), balls, crashes, broken])
		get_tree().quit()
