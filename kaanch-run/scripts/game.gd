## Kaanch Run: you fly through worlds of glass; tap to throw marbles and break the glass before you reach it.
## Running into glass costs ten marbles; jars give three. Coloured glass broken in a row makes a combo;
## a prism breaks all the glass of its colour ahead. Level 01 is made by hand; the endless run and the calm
## mode are made as you go.
class_name Game
extends Node3D

const EYE := 2.2
const ROOM_LEN := 200.0
const START_BALLS := 25
const SEG := Worlds.SEG
const HALF_W := Worlds.HALF_W
const CEIL := Worlds.CEIL
const BALL_SPEED := 52.0
const GRAV := 4.0

enum S { MENU, PLAY, PAUSE, OVER, DONE }

var state := S.MENU
var mode := "level1"        # level1, endless, calm
var dist := 0.0
var speed := 0.0
var balls := START_BALLS
var jar_streak := 0
var multi := 1
var cp_room := 0
var room := -1
var world := ""
var t := 0.0
var shake := 0.0
var fov_kick := 0.0
var over_t := -1.0
var hitstop_until := 0
var slow_until := 0.0

# this run's numbers
var score := 0
var broken := 0
var shots := 0
var hits := 0
var crashes := 0
var combo_color := -1
var combo_n := 0
var best_combo := 0

# saved
var save := {"best": 0, "cp": 0, "l1_done": false, "l1_stars": 0, "l1_score": 0, "sound": true, "music": true, "vibe": true, "quality": 1}

var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var hud: Hud
var sfx: Sfx
var fx: Fx
var root3d: Node3D

var segs: Array = []
var gates: Array = []
var panes: Array = []
var targets: Array = []
var flying: Array = []
var shards: Array = []
var anims: Array = []
var shard_pool: Array = []
var next_seg := 0
var next_obs := 30.0
var level_i := 0
var last_kind := ""
var look_now := {}
var cam_pitch := -2.5
var mood := -1
var backdrop: MeshInstance3D
var shadow_mat: StandardMaterial3D
var dust: CPUParticles3D
var backdrop_im: ImmediateMesh
var sec_now := "corridor"
var look_to := {}

var marble_mats: Array = []
var marble_mesh: SphereMesh
var jar_mesh: Mesh
var jar_mat: StandardMaterial3D
var hub_mat: StandardMaterial3D
var prism_mesh: ArrayMesh
var prism_mats: Array = []
var steel_mat: StandardMaterial3D
var glow_tex: Texture2D
var crack_tex: Texture2D
var crack_mat: StandardMaterial3D
var mark_mat: StandardMaterial3D

# testing from the command line
var auto := false
var shots_at: Array = []
var quit_at := -1.0
var shot_dir := "user://"
var test_screen := ""
var test_mode := ""
var test_from := 0
var remix := 0          # 0 the first time through the 50 rooms, 1 the second, ...
var log_n := 0


func _ready() -> void:
	randomize()
	for a in OS.get_cmdline_user_args():
		if a == "--auto":
			auto = true
		elif a.begins_with("--shots="):
			for s in a.substr(8).split(","):
				shots_at.append(float(s))
		elif a.begins_with("--quit-at="):
			quit_at = float(a.substr(10))
		elif a.begins_with("--shot-dir="):
			shot_dir = a.substr(11)
		elif a.begins_with("--screen="):
			test_screen = a.substr(9)
		elif a.begins_with("--mode="):
			test_mode = a.substr(7)
		elif a.begins_with("--from="):
			test_from = int(a.substr(7))
	_load()
	cp_room = int(save.cp)
	Glass.mats()
	Worlds.mats()
	_make_scene()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.sound_on = save.sound
	sfx.music_on = save.music
	hud = Hud.new()
	add_child(hud)
	hud.apply_settings(save)
	hud.play_mode.connect(_start)
	hud.resume_pressed.connect(_resume)
	hud.restart_pressed.connect(func(): _start(mode))
	hud.continue_pressed.connect(func(): _start(mode, cp_room))
	hud.menu_pressed.connect(_to_menu)
	hud.pause_pressed.connect(_pause)
	hud.setting_changed.connect(_on_setting)
	_apply_quality()
	_reset("menu")
	hud.show_menu(save)
	sfx.play_music("menu")
	if auto:
		_start(test_mode if test_mode != "" else "level1", test_from)
	if test_screen != "":
		_screen_test()


# ---------- saving and settings ----------
func _load() -> void:
	var c := ConfigFile.new()
	if c.load("user://kaanch_run.cfg") == OK:
		for k in save.keys():
			save[k] = c.get_value("save", k, save[k])


func _save() -> void:
	var c := ConfigFile.new()
	for k in save.keys():
		c.set_value("save", k, save[k])
	c.save("user://kaanch_run.cfg")


func _on_setting(key: String, value) -> void:
	save[key] = value
	match key:
		"sound":
			sfx.sound_on = value
		"music":
			sfx.set_music(value)
		"quality":
			_apply_quality()
	_save()


func _apply_quality() -> void:
	var q: int = save.quality
	get_viewport().msaa_3d = Viewport.MSAA_2X if q > 0 else Viewport.MSAA_DISABLED
	if fx:
		fx.quality = q


func vibe(ms: int) -> void:
	if save.vibe:
		Input.vibrate_handheld(ms)


# ---------- the scene ----------
func _make_scene() -> void:
	root3d = Node3D.new()
	add_child(root3d)
	cam = Camera3D.new()
	cam.fov = 72.0
	cam.near = 0.05
	cam.far = 260.0
	add_child(cam)
	cam.current = true
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, -28, 0)
	add_child(sun)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.95
	env.fog_enabled = true
	env.fog_density = 0.015
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
	# a far wall of sky colour that follows the eye: plain in the halls, a gradient in the open sky
	backdrop_im = ImmediateMesh.new()
	backdrop = MeshInstance3D.new()
	backdrop.mesh = backdrop_im
	var bm := StandardMaterial3D.new()
	bm.vertex_color_use_as_albedo = true
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.disable_fog = true
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	backdrop.material_override = bm
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(backdrop)
	glow_tex = _glow_texture()
	crack_tex = _crack_texture()
	shadow_mat = StandardMaterial3D.new()
	shadow_mat.albedo_texture = glow_tex
	shadow_mat.albedo_color = Color(0, 0, 0, 0.55)
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# specks of dust in the air, drifting past: you feel the speed and the depth everywhere
	dust = CPUParticles3D.new()
	dust.amount = 70
	dust.lifetime = 3.0
	dust.local_coords = false
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(7.0, 3.2, 14.0)
	dust.direction = Vector3(0, 0.2, 0)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.05
	dust.initial_velocity_max = 0.3
	dust.gravity = Vector3.ZERO
	var dq := QuadMesh.new()
	dq.size = Vector2(0.07, 0.07)
	var dm := StandardMaterial3D.new()
	dm.albedo_texture = glow_tex
	dm.albedo_color = Color(1.0, 0.95, 0.85, 0.5)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dq.material = dm
	dust.mesh = dq
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.6
	add_child(dust)
	fx = Fx.new()
	add_child(fx)
	fx.setup(cam, glow_tex, crack_tex)
	# marbles: little balls of coloured glass
	marble_mesh = SphereMesh.new()
	marble_mesh.radius = 0.13
	marble_mesh.height = 0.26
	marble_mesh.radial_segments = 16
	marble_mesh.rings = 8
	var swirl := _swirl_texture()
	for c in Glass.COLORS:
		var m := StandardMaterial3D.new()
		m.albedo_texture = swirl
		m.albedo_color = Color(lerpf(c.r, 1.0, 0.2), lerpf(c.g, 1.0, 0.2), lerpf(c.b, 1.0, 0.2), 0.95)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission_texture = swirl
		m.emission = c
		m.emission_energy_multiplier = 0.35
		m.roughness = 0.02
		m.metallic = 0.25
		m.metallic_specular = 1.0
		m.rim_enabled = true
		m.rim = 0.7
		m.rim_tint = 0.2
		marble_mats.append(m)
	# a jar of marbles
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.3
	cyl.height = 0.62
	cyl.radial_segments = 14
	jar_mesh = cyl
	jar_mat = StandardMaterial3D.new()
	jar_mat.albedo_color = Color(0.8, 0.95, 1.0, 0.35)
	jar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jar_mat.roughness = 0.05
	jar_mat.metallic = 0.2
	jar_mat.emission_enabled = true
	jar_mat.emission = Color("9fe8ff")
	jar_mat.emission_energy_multiplier = 0.9
	hub_mat = StandardMaterial3D.new()
	hub_mat.albedo_color = Color(1.0, 0.86, 0.45, 0.9)
	hub_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hub_mat.emission_enabled = true
	hub_mat.emission = Color("ff9a1f")
	hub_mat.emission_energy_multiplier = 1.3
	prism_mesh = _prism_shape()
	for c in Glass.COLORS:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(lerpf(c.r, 1.0, 0.4), lerpf(c.g, 1.0, 0.4), lerpf(c.b, 1.0, 0.4), 0.85)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 1.6
		m.roughness = 0.03
		prism_mats.append(m)
	steel_mat = StandardMaterial3D.new()
	steel_mat.albedo_color = Color("2b3138")
	steel_mat.metallic = 0.8
	steel_mat.roughness = 0.35
	crack_mat = StandardMaterial3D.new()
	crack_mat.albedo_texture = crack_tex
	crack_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	crack_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mark_mat = StandardMaterial3D.new()
	mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mark_mat.albedo_color = Color("ff5a3c")
	mark_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


## the inside of a marble: clear glass with a twisted ribbon of colour
func _swirl_texture() -> Texture2D:
	var W := 64
	var H := 32
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		for x in W:
			var u := float(x) / W
			var v := float(y) / H
			var band := absf(sin((u * 2.0 + v * 1.3) * PI))
			var k := clampf((band - 0.72) / 0.28, 0.0, 1.0)
			var glassy := 0.55 + 0.45 * pow(1.0 - absf(v - 0.35) * 1.4, 4.0)
			img.set_pixel(x, y, Color(lerpf(0.75, 1.0, k) * glassy, lerpf(0.82, 1.0, k) * glassy, lerpf(0.86, 1.0, k) * glassy, lerpf(0.55, 1.0, k)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## a prism: a long triangular crystal
func _prism_shape() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.32
	var h := 0.5
	var tri := []
	for i in 3:
		var a := TAU * i / 3.0 + PI * 0.5
		tri.append(Vector2(cos(a), sin(a)) * r)
	var faces := []
	for z in [h, -h]:
		faces.append([Vector3(tri[0].x, tri[0].y, z), Vector3(tri[1].x, tri[1].y, z), Vector3(tri[2].x, tri[2].y, z)])
	for i in 3:
		var a: Vector2 = tri[i]
		var b: Vector2 = tri[(i + 1) % 3]
		faces.append([Vector3(a.x, a.y, h), Vector3(b.x, b.y, h), Vector3(b.x, b.y, -h)])
		faces.append([Vector3(a.x, a.y, h), Vector3(b.x, b.y, -h), Vector3(a.x, a.y, -h)])
	for f in faces:
		var n: Vector3 = (f[1] - f[0]).cross(f[2] - f[0]).normalized()
		st.set_normal(n)
		for v in f:
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
	gt.width = 64
	gt.height = 64
	return gt


func _crack_texture() -> Texture2D:
	var S := 256
	var img := Image.create(S, S, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Vector2(S, S) * 0.5
	for k in 13:
		var a := TAU * k / 13.0 + randf_range(-0.2, 0.2)
		var p := c
		var steps := int(randf_range(0.55, 1.0) * S * 0.48)
		var dir := Vector2(cos(a), sin(a))
		for i in steps:
			if i % 16 == 0:
				dir = dir.rotated(randf_range(-0.35, 0.35))
			p += dir
			var al := 1.0 - float(i) / steps * 0.7
			for o in [Vector2.ZERO, Vector2(1, 0), Vector2(0, 1)]:
				var q: Vector2 = p + o
				if q.x >= 0 and q.y >= 0 and q.x < S and q.y < S:
					img.set_pixelv(Vector2i(q), Color(1, 1, 1, al))
	for i in 360:
		var a := deg_to_rad(i)
		var q := c + Vector2(cos(a), sin(a)) * (S * 0.08 + sin(a * 5.0) * 3.0)
		img.set_pixelv(Vector2i(q), Color(1, 1, 1, 0.9))
	return ImageTexture.create_from_image(img)


# ---------- modes ----------
func _start(m: String, from_room := 0) -> void:
	mode = m
	_reset(m, from_room)
	remix = from_room / Rooms.COUNT
	state = S.PLAY
	balls = START_BALLS + 5
	jar_streak = 0
	multi = 1
	over_t = -1.0
	score = 0
	broken = 0
	shots = 0
	hits = 0
	crashes = 0
	combo_color = -1
	combo_n = 0
	best_combo = 0
	speed = 0.0
	hud.show_play(mode)
	_hud_all()
	var title: String = "Level 1 · First Light" if mode == "level1" else ("Calm" if mode == "calm" else Worlds.def(world).name)
	hud.show_toast(title, Hud.ACCENT, 0.8)
	sfx.play("tick")


func _pause() -> void:
	if state != S.PLAY:
		return
	state = S.PAUSE
	hud.show_pause(mode)
	sfx.play("tick")


func _resume() -> void:
	if state != S.PAUSE:
		return
	state = S.PLAY
	hud.show_play(mode)
	sfx.play("tick")


func _to_menu() -> void:
	state = S.MENU
	_reset("menu")
	hud.show_menu(save)
	sfx.play_music("menu")


func _game_over() -> void:
	state = S.OVER
	over_t = 0.0
	if mode == "endless":
		var d := int(dist)
		var nb := d > int(save.best)
		if nb:
			save.best = d
		_save()
		hud.show_over_endless(d, save.best, int(cp_room * ROOM_LEN), nb, score)
	else:
		hud.show_over_level(int(dist), int(Levels.L1_LEN), score)


func _level_done() -> void:
	state = S.DONE
	over_t = 0.0
	var acc := float(hits) / maxf(1.0, float(shots))
	var stars := 1
	if acc >= 0.6 and crashes <= 1:
		stars = 2
	if acc >= 0.75 and crashes == 0:
		stars = 3
	var first: bool = not save.l1_done
	save.l1_done = true
	save.l1_stars = maxi(save.l1_stars, stars)
	var nb: bool = score > int(save.l1_score)
	if nb:
		save.l1_score = score
	_save()
	hud.show_done({"score": score, "glass": broken, "acc": acc, "combo": best_combo, "crashes": crashes, "stars": stars, "best": nb, "unlocked": first})
	sfx.play("checkpoint")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not auto and test_screen == "":
			_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == S.PLAY:
			_pause()
		elif state == S.PAUSE:
			_resume()
		elif state != S.MENU:
			_to_menu()


# ---------- building the way ahead ----------
func _reset(m: String, from_room := 0) -> void:
	mode = m
	for c in root3d.get_children():
		c.queue_free()
	segs.clear()
	gates.clear()
	panes.clear()
	targets.clear()
	flying.clear()
	shards.clear()
	anims.clear()
	shard_pool.clear()
	room = -1
	world = ""
	last_kind = ""
	level_i = 0
	t = 0.0
	slow_until = 0.0
	Engine.time_scale = 1.0
	if m == "level1":
		seed(1701)
		dist = 0.0
	else:
		randomize()
		dist = from_room * ROOM_LEN
	next_seg = int(floor(dist / SEG))
	next_obs = dist + 30.0
	_set_world(_world_at(dist), true)
	_stream()
	_place_camera(0.0)


func _room_of(d: float) -> int:
	return int(floor(d / ROOM_LEN))


func _world_at(d: float) -> String:
	if mode == "level1" or mode == "menu":
		return Levels.L1_WORLD
	if mode == "endless":
		return Rooms.world_of(_room_of(d))
	return Worlds.world_of(_room_of(d))


func _door_d(r: int) -> float:
	return (r + 1) * ROOM_LEN - 6.0


## which of the world's ten moods: in the endless run each room has its own
func _mood_at(d: float) -> int:
	var r := _room_of(d + 6.0)
	if mode == "endless":
		return r % Rooms.PER_WORLD
	if mode == "calm":
		return (r / 5) % 10
	return 0


func _set_world(w: String, now := false) -> void:
	var m := _mood_at(dist)
	if w == world and m == mood:
		return
	var new_world := w != world
	world = w
	mood = m
	var L: Dictionary = Worlds.look(w, m)
	var sky_k: float = look_to.get("sky", 0.0)
	look_to = {"bg": L.bg, "amb": L.amb, "sun": L.sun, "rim": L.rim, "sun_e": L.sun_e, "fog": L.fog, "tint": L.tint, "gtint": L.gtint, "sky": sky_k, "sky_top": L.sky_top, "sky_hor": L.sky_hor, "ground": L.ground}
	if now or look_now.is_empty():
		look_now = look_to.duplicate()
	_apply_look()
	if mode != "menu":
		if new_world:
			sfx.play_music("calm" if mode == "calm" else w)
		# each room plays its world's music in a key of its own
		sfx.set_pitch([1.0, 0.944, 1.0595, 1.0, 1.122, 0.891, 1.0595, 1.0, 0.944, 1.0][m])


func _apply_look() -> void:
	var k: float = look_now.sky
	var bg: Color = look_now.bg
	var hor: Color = bg.lerp(look_now.sky_hor, k)
	env.background_color = hor
	env.fog_light_color = hor
	env.ambient_light_color = look_now.amb
	env.fog_density = lerpf(look_now.fog, 0.007, k)
	var top: Color = bg.lerp(look_now.sky_top, k)
	var low: Color = bg.lerp(look_now.ground.lerp(look_now.sky_hor, 0.35), k)
	backdrop_im.clear_surfaces()
	backdrop_im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows := [[150.0, top], [12.0, hor.lerp(top, 0.25)], [-4.0, hor], [-30.0, low], [-150.0, low]]
	for i in rows.size() - 1:
		var y0: float = rows[i][0]
		var y1: float = rows[i + 1][0]
		var c0: Color = rows[i][1]
		var c1: Color = rows[i + 1][1]
		for v in [[-400.0, y0, c0], [400.0, y0, c0], [400.0, y1, c1], [-400.0, y0, c0], [400.0, y1, c1], [-400.0, y1, c1]]:
			backdrop_im.surface_set_color(v[2])
			backdrop_im.surface_add_vertex(Vector3(v[0], v[1], 0))
	# the world's skyline far away, in two layers of haze, with little lit windows
	if k > 0.01 and world != "":
		var sk: Dictionary = Worlds.skyline(world)
		var c_far: Color = bg.lerp(hor.lerp(top, 0.3) * 0.82, k)
		var c_near: Color = bg.lerp(low.lerp(top, 0.15) * 0.7, k)
		for layer in 2:
			for e in sk.shapes:
				if e[1] != layer:
					continue
				var poly: PackedVector2Array = e[0]
				var cx := 0.0
				for q in poly:
					cx += q.x
				cx /= poly.size()
				var cb := Vector2(cx, poly[0].y)
				var col: Color = c_far if layer == 0 else c_near
				backdrop_im.surface_set_color(col)
				for i in poly.size():
					var q0 := poly[i]
					var q1 := poly[(i + 1) % poly.size()]
					for q in [cb, q0, q1]:
						backdrop_im.surface_add_vertex(Vector3(q.x, q.y, 1.0 + layer))
		var lc: Color = bg.lerp((Worlds.TUNE[world].lights[0] as Color) * 0.85, k)
		backdrop_im.surface_set_color(lc)
		for q in sk.lights:
			for v in [Vector2(-0.5, -0.6), Vector2(0.5, -0.6), Vector2(0.5, 0.6), Vector2(-0.5, -0.6), Vector2(0.5, 0.6), Vector2(-0.5, 0.6)]:
				backdrop_im.surface_add_vertex(Vector3(q.x + v.x, q.y + v.y, 3.0))
	backdrop_im.surface_end()
	sun.light_color = look_now.sun
	sun.light_energy = look_now.sun_e
	Glass.rim_mat.albedo_color = look_now.rim
	Worlds.set_tint(look_now.tint, look_now.gtint)
	# glass edges dark against a bright room, bright against a dark one
	Glass.rim_mat.albedo_color = Color("eef6f4") if hor.get_luminance() < 0.4 else Color("1c4a50")


func _look_step(dt: float) -> void:
	var k := 1.0 - exp(-dt * 1.2)
	var changed := false
	for key in look_to.keys():
		var a = look_now[key]
		var b = look_to[key]
		if a is Color:
			if not a.is_equal_approx(b):
				look_now[key] = a.lerp(b, k)
				changed = true
		elif absf(a - b) > 1e-4:
			look_now[key] = lerpf(a, b, k)
			changed = true
	if changed:
		_apply_look()


func _stream() -> void:
	while next_seg * SEG < dist + 150.0:
		var d0 := next_seg * SEG
		var sec := section_at(d0 + 1.0)
		var prev := section_at(d0 - 1.0) if d0 >= SEG else "corridor"
		var seg := Worlds.build(_world_at(d0 + 1.0), d0, next_seg * 7919 + 13, sec, prev, _mood_at(d0 + 2.0))
		root3d.add_child(seg)
		segs.append({"node": seg, "d": d0})
		if mode == "endless":
			seed(hash([next_seg, remix, "x"]))
		_extras(d0, sec)
		_spawn_in(d0, d0 + SEG)
		next_seg += 1
	while segs.size() and segs[0].d + SEG < dist - 6.0:
		segs[0].node.queue_free()
		segs.pop_front()


# ---------- the shape of the way: corridor, tunnel, great hall or open sky ----------
func _sec_raw(d: float) -> String:
	if mode == "menu" or mode == "gallery":
		return "corridor"
	if mode == "level1":
		for e in Levels.L1_SECT:
			if d >= e[0] and d < e[1]:
				return e[2]
		return "corridor"
	var r := _room_of(d)
	var local := d - r * ROOM_LEN
	if mode == "endless":
		return Rooms.section(r, local)
	var pair: Array = Worlds.SECT[Worlds.world_of(r)][(r / Worlds.LIST.size()) % 2]
	if local >= 32.0 and local < 96.0:
		return pair[0]
	if local >= 112.0 and local < 176.0:
		return pair[1]
	return "corridor"


## the same for every point of one 16 m piece
func section_at(d: float) -> String:
	var i := floori(d / SEG)
	return _sec_raw(i * SEG + SEG * 0.5)


## glass that is only there to be broken: on islands below the sky, on racks at the sides of a hall
func _extras(d0: float, sec: String) -> void:
	if mode == "menu" or mode == "gallery" or d0 < 1.0:
		return
	if sec == "sky":
		if randf() < 0.8:
			_island(d0 + randf_range(3.0, 13.0))
	elif sec == "hall":
		_side_bonus(d0 + randf_range(2.0, 7.0), -1.0 if randf() < 0.5 else 1.0)
		if randf() < 0.6:
			_side_bonus(d0 + randf_range(9.0, 14.0), -1.0 if randf() < 0.5 else 1.0)


func _bonus_pane(g: GGate, poly: PackedVector2Array, d: float, color_id: int, pts := 15) -> GPane:
	var p := pane(g, poly, d, "thin" if randf() < 0.6 else "mid", -1 if randf() < 0.75 else color_id, false)
	p.bonus = pts
	return p


## a little floating island below the way, with glass on it to break from above
func _island(d: float) -> void:
	var g := new_gate("bonus", d)
	var w := _world_at(d)
	var T: Dictionary = Worlds.TUNE[w]
	var acc: Color = Worlds.def(w).accent
	var sd := -1.0 if randf() < 0.5 else 1.0
	var x := randf_range(1.0, 6.0) * sd
	var y := randf_range(-7.0, -3.5)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock: Color = T.wall.lerp(Color("2a2a30"), 0.5)
	# the top, with a raised metal rim
	Worlds.box(st, Vector3(0, -0.2, 0), Vector3(4.6, 0.4, 4.0), T.floor_a)
	Worlds.box(st, Vector3(0, 0.03, 2.0), Vector3(4.8, 0.12, 0.16), Color("4a525c"))
	Worlds.box(st, Vector3(0, 0.03, -2.0), Vector3(4.8, 0.12, 0.16), Color("4a525c"))
	Worlds.box(st, Vector3(2.32, 0.03, 0), Vector3(0.16, 0.12, 4.0), Color("4a525c"))
	Worlds.box(st, Vector3(-2.32, 0.03, 0), Vector3(0.16, 0.12, 4.0), Color("4a525c"))
	Worlds.box(st, Vector3(0, -0.55, 0), Vector3(4.7, 0.3, 4.1), Color("39424c"))
	# the rock underneath, in layers getting smaller, ending in a point
	var widths := [4.2, 3.4, 2.6, 1.7, 0.9]
	for i in widths.size():
		var ww: float = widths[i]
		Worlds.box(st, Vector3(randf_range(-0.15, 0.15), -0.95 - i * 0.6, randf_range(-0.15, 0.15)), Vector3(ww, 0.62, ww * 0.9), rock * (1.0 - i * 0.1))
	# a few crystals hanging below
	for i in 3:
		var cx := randf_range(-1.2, 1.2)
		var cz := randf_range(-1.0, 1.0)
		Worlds.box(st, Vector3(cx, -1.6 - i * 0.3, cz), Vector3(0.2, 0.9, 0.2), Color("8fd8d0"))
	# something of the world standing on it
	match w:
		"venice":
			for q in [Vector2(-2.0, 1.7), Vector2(2.0, -1.7)]:
				for k in 4:
					Worlds.box(st, Vector3(q.x, 0.25 + k * 0.5, q.y), Vector3(0.16, 0.5, 0.16), Color("c8302c") if k % 2 == 0 else Color("f4f0e8"))
		"lanterns", "cathedral", "mosaic":
			Worlds.box(st, Vector3(-2.0, 0.9, 1.7), Vector3(0.1, 1.8, 0.1), Color("2b3138"))
		"sheesh":
			for q in [Vector2(-1.9, 1.6), Vector2(1.9, 1.6)]:
				Worlds.box(st, Vector3(q.x, 0.7, q.y), Vector3(0.14, 1.4, 0.14), Color("e8b64a"))
	st.set_material(Worlds.lit_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	var gs := SurfaceTool.new()
	gs.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a thin bright strip round the side, and the lamp
	Worlds.box(gs, Vector3(0, -0.28, 2.04), Vector3(4.4, 0.05, 0.04), acc * 0.8)
	Worlds.box(gs, Vector3(0, -0.28, -2.04), Vector3(4.4, 0.05, 0.04), acc * 0.8)
	Worlds.box(gs, Vector3(2.34, -0.28, 0), Vector3(0.04, 0.05, 3.8), acc * 0.8)
	Worlds.box(gs, Vector3(-2.34, -0.28, 0), Vector3(0.04, 0.05, 3.8), acc * 0.8)
	if w in ["lanterns", "cathedral", "mosaic"]:
		Worlds.box(gs, Vector3(-2.0, 1.95, 1.7), Vector3(0.3, 0.4, 0.3), T.lights[0])
	elif w == "sheesh":
		for q in [Vector2(-1.9, 1.6), Vector2(1.9, 1.6)]:
			Worlds.box(gs, Vector3(q.x, 1.5, q.y), Vector3(0.22, 0.22, 0.22), Color("ffd896"))
	gs.set_material(Worlds.glow_mat)
	gs.commit(m.mesh)
	m.position = Vector3(x, y, -d)
	decor(g, m)
	# a soft dark patch on the ground far below: its shadow
	var sh := MeshInstance3D.new()
	var sq := QuadMesh.new()
	sq.size = Vector2(6.0, 5.0)
	sh.mesh = sq
	sh.material_override = shadow_mat
	sh.rotation.x = -PI * 0.5
	sh.position = Vector3(x + 1.5, Worlds.SKY_GROUND + 0.25, -d + 1.0)
	decor(g, sh)
	var c0 := randi() % Glass.COLORS.size()
	match randi() % 6:
		0:
			# a glass house: three panes side by side
			for i in 3:
				var x0 := x - 1.8 + i * 1.2
				_bonus_pane(g, Glass.rect(x0 + 0.03, x0 + 1.17, y, y + randf_range(1.6, 2.4)), d + 0.6, (c0 + i % 2) % Glass.COLORS.size())
		1:
			# a tower of small panes
			for i in 4:
				var yy := y + 0.05 + i * 0.85
				_bonus_pane(g, Glass.rect(x - 0.6, x + 0.6, yy, yy + 0.8), d, c0 if i % 2 == 0 else -1)
		2:
			# crystals
			for i in 3:
				var r: float = [0.9, 0.65, 0.5][i]
				var cx: float = x + [0.0, -1.3, 1.3][i]
				_bonus_pane(g, Glass.ngon(6, r, Vector2(cx, y + r + 0.05), PI / 6.0), d + i * 0.4, c0)
		3:
			# a glass arch, and a smaller one behind it
			_bonus_pane(g, Glass.arch(x - 1.4, x + 1.4, y, y + 1.6, 6), d + 0.8, -1)
			_bonus_pane(g, Glass.arch(x - 0.9, x + 0.9, y, y + 1.2, 6), d - 0.6, c0)
		4:
			# a little windmill of glass, turning
			var hub := Vector2(x, y + 1.9)
			var blade := PackedVector2Array([Vector2(0.15, -0.16), Vector2(1.5, -0.1), Vector2(1.6, 0.0), Vector2(1.5, 0.1), Vector2(0.15, 0.16)])
			var wsp := randf_range(1.0, 1.6) * sd
			for i in 3:
				var p := _bonus_pane(g, Glass.moved(blade, hub), d, -1)
				var off := TAU * i / 3.0
				p.move = func(pp: GPane, tt: float, _a: float): spin_about(pp, hub, off + tt * wsp)
		_:
			# a glass roof on four posts: easiest to hit from above
			var roof := _bonus_pane(g, Glass.rect(-1.7, 1.7, 0.0, 3.0), d, -1, 20)
			roof.node.transform = Transform3D(Basis(Vector3(1, 0, 0), -PI * 0.5), Vector3(x, y + 1.9, -d))
			roof.base = roof.node.transform
			var ps := SurfaceTool.new()
			ps.begin(Mesh.PRIMITIVE_TRIANGLES)
			for q in [Vector2(-1.6, 1.4), Vector2(1.6, 1.4), Vector2(-1.6, -1.4), Vector2(1.6, -1.4)]:
				Worlds.box(ps, Vector3(q.x, 0.95, q.y), Vector3(0.1, 1.9, 0.1), Color("4a525c"))
			ps.set_material(Worlds.lit_mat)
			var pm := MeshInstance3D.new()
			pm.mesh = ps.commit()
			pm.position = Vector3(x, y, -d)
			decor(g, pm)
	if randf() < 0.4:
		var tg := target("jar", Vector3(x + randf_range(-1.4, 1.4), y + 0.35, -(d - 1.3)), 0.55)
		tg.on_hit = func(): _jar_got(tg)


## a rack of small coloured panes at the side of a great hall
func _side_bonus(d: float, sd: float) -> void:
	var g := new_gate("bonus", d)
	var x := sd * randf_range(6.0, 10.5)
	var c0 := randi() % Glass.COLORS.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Worlds.box(st, Vector3(-1.45, 1.6, 0), Vector3(0.12, 3.2, 0.12), Color("2b3138"))
	Worlds.box(st, Vector3(1.45, 1.6, 0), Vector3(0.12, 3.2, 0.12), Color("2b3138"))
	Worlds.box(st, Vector3(0, 0.05, 0), Vector3(3.2, 0.1, 0.6), Color("2b3138"))
	st.set_material(Worlds.lit_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.position = Vector3(x, 0, -d)
	decor(g, m)
	for cx in 3:
		for cy in 3:
			var x0 := x - 1.38 + cx * 0.92
			var y0 := 0.25 + cy * 0.98
			_bonus_pane(g, Glass.rect(x0 + 0.03, x0 + 0.89, y0, y0 + 0.92), d, c0 if (cx + cy) % 2 == 0 else (c0 + 1) % Glass.COLORS.size(), 10)
	if randf() < 0.35:
		var tg := target("jar", Vector3(x, 3.6, -d), 0.55)
		tg.on_hit = func(): _jar_got(tg)


func _spawn_in(a: float, b: float) -> void:
	if mode == "menu":
		# the title screen: a few panes to look at, nothing else
		while next_obs < b:
			Obstacles.build(self, ["pane", "grid", "color_row", "stack"].pick_random(), next_obs, 0)
			next_obs += 26.0
		return
	if mode == "level1":
		while level_i < Levels.L1.size() and float(Levels.L1[level_i][0]) < b:
			var e: Array = Levels.L1[level_i]
			level_i += 1
			var d := float(e[0])
			match e[1]:
				"jars":
					_jars(d)
				"finale":
					Obstacles.finale(self, d)
				"exit":
					_exit_gate(d)
				_:
					Obstacles.build(self, e[1], d, e[2])
		return
	var r := _room_of(a)
	var dd := _door_d(r)
	if dd >= a and dd < b and mode == "endless":
		_door(dd)
	if mode == "endless":
		# the rooms made by hand: each the same every run (its own seed), none twice before the fiftieth
		for rr: int in [r, r + 1]:
			var rmx: int = rr / Rooms.COUNT
			for e in Rooms.entries(rr):
				var d: float = rr * ROOM_LEN + float(e[0])
				if d < a or d >= b:
					continue
				seed(hash([rr % Rooms.COUNT, e[0], rmx]))
				remix = rmx
				var hard: int = mini(6, int(e[2]) + rmx)
				match e[1]:
					"jars":
						_jars(d)
					"boss":
						Obstacles.finale(self, d, Rooms.world_of(rr))
					_:
						Obstacles.build(self, e[1], d, hard)
		return
	while next_obs < b:
		var d := next_obs
		var rr := _room_of(d)
		var door := _door_d(rr)
		if mode == "endless" and d > door - 16.0 and d < door + 14.0:
			next_obs = door + 18.0
			continue
		# not across the place where the way changes shape
		if section_at(d - 3.0) != section_at(d + 3.0):
			next_obs += 6.0
			continue
		var sec := section_at(d)
		var pool: Array = (Obstacles.CALM if mode == "calm" else Obstacles.pool_for(rr)).duplicate()
		if sec == "sky":
			pool = pool.filter(func(k): return k in Obstacles.SKY_OK)
			pool.append_array(["drop", "drop"])
		elif sec == "hall":
			pool.append("drop")
		var kind: String = pool.pick_random()
		if kind == last_kind:
			kind = pool.pick_random()
		last_kind = kind
		Obstacles.build(self, kind, d, rr if mode == "endless" else 1)
		var gap := lerpf(30.0, 20.0, clampf(rr / 8.0, 0.0, 1.0)) + randf() * 6.0
		if mode == "calm":
			gap = 30.0 + randf() * 8.0
		if kind in ["layers", "prism", "snake", "frosted"]:
			gap += 12.0 if kind == "prism" else 6.0
		if sec != "sky" and randf() < 0.55:
			_jars(d + gap * 0.5)
		next_obs += gap


# ---------- helpers the obstacles use ----------
func new_gate(kind: String, d: float) -> GGate:
	var g := GGate.new()
	g.kind = kind
	g.d = d
	g.ph = randf() * TAU
	g.side = 1 if randf() < 0.5 else -1
	if remix % 2 == 1:
		g.side = -g.side
	gates.append(g)
	return g


func pane(g: GGate, poly_xy: PackedVector2Array, d: float, kind: String, color_id := -1, blocks := true) -> GPane:
	var c := Glass.centroid(poly_xy)
	var local := Glass.ccw(Glass.moved(poly_xy, -c))
	var mi := MeshInstance3D.new()
	mi.mesh = Glass.slab_mesh(local, kind, 1.0, color_id)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, c.y, -d)
	root3d.add_child(mi)
	var p := GPane.new()
	p.node = mi
	p.poly = local
	p.kind = kind
	p.color_id = color_id
	p.hp = Glass.KINDS[kind].hp
	p.blocks = blocks
	p.base = mi.transform
	p.gate = g
	g.panes.append(p)
	panes.append(p)
	return p


func rng_kind(r: int) -> String:
	var x := randf()
	if r >= 3 and x < 0.1:
		return "slab"
	if x < 0.42:
		return "thin"
	if x < 0.75 or r < 1:
		return "mid"
	return "thick"


## ordinary glass is plain glass; colour is kept for the prism, the colour rows and the finale
func rng_color(_p: float) -> int:
	return -1


## turn a pane about a point in the plane across the way
func spin_about(p: GPane, pivot: Vector2, ang: float) -> void:
	var b := Basis(Vector3(0, 0, 1), ang)
	var z := p.base.origin.z
	var o := p.base.origin - Vector3(pivot.x, pivot.y, z)
	p.node.transform = Transform3D(b, Vector3(pivot.x, pivot.y, z) + b * o)


## where the music's beat is (0..1), for glass that moves with it
func beat() -> float:
	return sfx.beat_phase(t)


func target(kind: String, pos: Vector3, radius: float, g = null, color_id := -1) -> GTarget:
	var n := Node3D.new()
	n.position = pos
	root3d.add_child(n)
	var m := MeshInstance3D.new()
	var glow_col := Color(0.6, 1.0, 0.95, 0.6)
	match kind:
		"jar":
			m.mesh = jar_mesh
			m.material_override = jar_mat
			# marbles inside
			for i in 5:
				var b := MeshInstance3D.new()
				b.mesh = marble_mesh
				b.material_override = marble_mats[i % marble_mats.size()]
				b.position = Vector3(randf_range(-0.12, 0.12), -0.2 + i * 0.07, randf_range(-0.12, 0.12))
				b.scale = Vector3.ONE * 0.85
				n.add_child(b)
		"hub", "button":
			var sm := SphereMesh.new()
			sm.radius = 0.3
			sm.height = 0.6
			m.mesh = sm
			m.material_override = hub_mat
			glow_col = Color(1.0, 0.75, 0.35, 0.7)
		"prism":
			m.mesh = prism_mesh
			m.material_override = prism_mats[color_id]
			glow_col = Glass.COLORS[color_id]
			glow_col.a = 0.8
	n.add_child(m)
	var sp := Sprite3D.new()
	sp.texture = glow_tex
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.modulate = glow_col
	sp.pixel_size = 0.03 if kind == "prism" else 0.022
	sp.shaded = false
	sp.transparent = true
	n.add_child(sp)
	var tg := GTarget.new()
	tg.node = n
	tg.kind = kind
	tg.radius = radius
	tg.gate = g
	tg.color_id = color_id
	if kind == "prism":
		tg.spin = 0.9
	elif kind == "hub" or kind == "button":
		tg.spin = 0.0
	targets.append(tg)
	return tg


func _jars(d: float) -> void:
	var n := 1 + (randi() % 3)
	var x0 := randf_range(-2.6, 2.6)
	var y0 := randf_range(0.9, 4.0)
	for i in n:
		var tg := target("jar", Vector3(clampf(x0 + i * 0.9 * signf(-x0 + 0.01), -3.6, 3.6), y0 + sin(i) * 0.3, -(d + i * 1.4)), 0.5)
		tg.on_hit = func(): _jar_got(tg)


func decor(g: GGate, n: Node3D) -> void:
	root3d.add_child(n)
	g.extra.append(n)


func chain(p: GPane, at: Vector3, length: float) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, length, 0.05)
	m.mesh = bm
	m.material_override = steel_mat
	m.position = at + Vector3(0, length * 0.5, 0)
	p.node.add_child(m)


func post(g: GGate, at: Vector3) -> void:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.09
	cm.bottom_radius = 0.09
	cm.height = CEIL
	m.mesh = cm
	m.material_override = steel_mat
	m.position = at + Vector3(0, CEIL * 0.5, 0)
	decor(g, m)


## hinges on one edge, a glowing handle on the other
func hinge_marks(p: GPane) -> void:
	var b := Glass.bounds(p.poly)
	var hx := b.end.x if p.hinge > 0 else b.position.x
	var fx_ := b.position.x if p.hinge > 0 else b.end.x
	for yy in [b.position.y + 0.4, b.end.y - 0.4]:
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.12, 0.3, 0.22)
		m.mesh = bm
		m.material_override = steel_mat
		m.position = Vector3(hx, yy, 0)
		p.node.add_child(m)
	var h := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	h.mesh = sm
	h.material_override = hub_mat
	h.position = Vector3(fx_ - signf(fx_ - hx) * 0.3, 0, 0.1)
	p.node.add_child(h)


## the weak spot of thick glass: a glowing ring
func weak_mark(p: GPane) -> void:
	var m := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.28
	m.mesh = tm
	m.material_override = mark_mat
	m.rotation.x = PI * 0.5
	m.position = Vector3(p.weak.x, p.weak.y, Glass.KINDS[p.kind].t * 0.5 + 0.03)
	p.node.add_child(m)


## a steel grille across the way, and the button that opens it
func grille(g: GGate, d: float, button_at: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 9:
		Worlds.box(st, Vector3(-2.4 + i * 0.6, 2.2, 0), Vector3(0.07, 3.6, 0.07), Color("39424c"))
	for j in 6:
		Worlds.box(st, Vector3(0, 0.4 + j * 0.72, 0), Vector3(4.9, 0.07, 0.07), Color("39424c"))
	st.set_material(Worlds.lit_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.position = Vector3(0, 0, -d)
	decor(g, m)
	g.grille = m
	var tg := target("button", button_at, 0.42, g)
	tg.on_hit = func(): _open_grille(g)


func prism(g: GGate, pos: Vector3, color_id: int) -> void:
	var tg := target("prism", pos, 0.5, g, color_id)
	tg.on_hit = func(): _prism_fire(tg)


func _door(d: float) -> void:
	var g := new_gate("door", d)
	g.door = true
	pane(g, Glass.rect(-HALF_W + 0.1, HALF_W - 0.1, 0.05, CEIL - 0.1), d, "thin")
	_frame(g, d, Worlds.def(_world_at(d)).accent)


func _exit_gate(d: float) -> void:
	var g := new_gate("exit", d)
	g.end_level = true
	_frame(g, d, Color("ffd36b"))


func _frame(g: GGate, d: float, acc: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Worlds.box(st, Vector3(0, CEIL - 0.05, 0), Vector3(HALF_W * 2, 0.14, 0.14), acc)
	Worlds.box(st, Vector3(-HALF_W + 0.05, CEIL * 0.5, 0), Vector3(0.14, CEIL, 0.14), acc)
	Worlds.box(st, Vector3(HALF_W - 0.05, CEIL * 0.5, 0), Vector3(0.14, CEIL, 0.14), acc)
	st.set_material(Worlds.glow_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.position = Vector3(0, 0, -d)
	decor(g, m)


# ---------- each frame ----------
func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 20.0)
	if Time.get_ticks_msec() < hitstop_until:
		dt *= 0.08
	if t < slow_until:
		dt *= 0.35
	if state == S.PAUSE:
		return
	if state == S.MENU and mode == "gallery":
		return
	if state == S.MENU:
		dist += 4.0 * dt
		t += dt
		_stream()
		_move_gates()
		_spin_targets(dt)
		_place_camera(dt)
		_look_step(dt)
		fx.step(dt, [])
		return
	if state == S.OVER or state == S.DONE:
		if auto:
			over_t += dt
			if over_t > 2.0:
				print("END state=%s d=%d balls=%d crashes=%d broken=%d score=%d shots=%d hits=%d combo=%d" % [S.keys()[state], int(dist), balls, crashes, broken, score, shots, hits, best_combo])
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(shot_dir + "end_%s.png" % mode)
				get_tree().quit()
		_update_shards(dt)
		_update_balls(dt)
		_run_anims(dt)
		fx.step(dt, flying)
		_look_step(dt)
		return
	t += dt
	var want := 7.0 + minf(_room_of(dist), 10) * 0.45
	if mode == "endless":
		var rn := _room_of(dist)
		want = 7.0 + minf(rn % Rooms.COUNT, 49) * 0.1 + minf(rn / Rooms.COUNT, 3) * 1.0
	if mode == "level1":
		want = 6.5 + clampf(dist / Levels.L1_LEN, 0.0, 1.0) * 2.5
	elif mode == "calm":
		want = 5.5
	speed = lerpf(speed, want, 1.0 - exp(-dt * 1.6))
	var prev := dist
	dist += speed * dt
	_stream()
	_move_gates()
	_spin_targets(dt)
	_check_gates(prev)
	_update_balls(dt)
	_update_shards(dt)
	_run_anims(dt)
	fx.step(dt, flying)
	_place_camera(dt)
	_look_step(dt)
	var w := _world_at(dist)
	if w != world or _mood_at(dist) != mood:
		_set_world(w)
	if mode == "endless" and _room_of(dist) != room:
		room = _room_of(dist)
		var k := room % Rooms.COUNT
		var wn: String = Worlds.def(Rooms.world_of(room)).name
		var small := "%s · ROOM %d OF 10" % [wn.to_upper(), k % Rooms.PER_WORLD + 1]
		if k % Rooms.PER_WORLD == Rooms.PER_WORLD - 1:
			small = "%s · FINAL ROOM" % wn.to_upper()
		if room >= Rooms.COUNT:
			small += "  ·  REMIX %d" % (room / Rooms.COUNT)
		var L: Dictionary = Worlds.look(Rooms.world_of(room), k % Rooms.PER_WORLD)
		hud.show_title(L.name, small, (L.sun as Color).lerp(Color.WHITE, 0.3))
		hud.flash_screen((L.sun as Color), 0.35, 0.7)
		sfx.play("room", -2.0)
		vibe(25)
	var sn := section_at(dist + 2.0)
	if sn != sec_now:
		sec_now = sn
		if sn == "sky":
			hud.show_toast("SKY · BONUS GLASS BELOW", Hud.ACCENT, 0.5)
		elif sn == "hall":
			hud.show_toast("GREAT HALL · BONUS AT THE SIDES", Hud.ACCENT, 0.5)
	_hud_all()
	if mode != "calm" and balls <= 0 and flying.is_empty():
		if over_t < 0.0:
			over_t = t
		elif t - over_t > 0.9:
			_game_over()
	else:
		over_t = -1.0
	if auto:
		_auto_play()
	_test_hooks()


func _hud_all() -> void:
	hud.set_balls(balls, multi, mode == "calm")
	var prog := 0.0
	if mode == "level1":
		prog = dist / Levels.L1_LEN
	elif mode == "endless":
		prog = fmod(dist, ROOM_LEN) / ROOM_LEN
	hud.set_dist(dist, prog)
	hud.set_score(score)
	hud.set_combo(combo_color, combo_n, _mult())


func _mult() -> int:
	return 1 + combo_n / 3


func _place_camera(dt: float) -> void:
	shake = maxf(0.0, shake - dt * 1.8)
	fov_kick = maxf(0.0, fov_kick - dt * 12.0)
	var sway := sin(dist * 0.11) * 0.06
	var bob := sin(dist * 0.9) * 0.025 if state == S.PLAY else 0.0
	var off := Vector3.ZERO
	if shake > 0.0:
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.35
	# look down a little in the open sky, to see the glass below
	var want_pitch := -10.0 if section_at(dist + 8.0) == "sky" else -2.5
	if dt <= 0.0:
		cam_pitch = want_pitch
	else:
		cam_pitch = lerpf(cam_pitch, want_pitch, 1.0 - exp(-dt * 1.4))
	cam.position = Vector3(sway, EYE + bob, -dist) + off
	backdrop.position = Vector3(0, EYE, -dist - 215.0)
	dust.position = cam.position + Vector3(0, 0, -16.0)
	look_to["sky"] = 1.0 if section_at(dist + 12.0) == "sky" else 0.0
	if dt <= 0.0 and not look_now.is_empty():
		look_now["sky"] = look_to["sky"]
		_apply_look()
	cam.rotation = Vector3(deg_to_rad(cam_pitch), sin(dist * 0.05) * 0.015, sin(dist * 0.07) * 0.012 + off.x * 0.1)
	cam.fov = 70.0 + clampf((speed - 9.0) * 0.9, 0.0, 8.0) + fov_kick


func _move_gates() -> void:
	for g in gates:
		var ahead: float = g.d - dist
		if ahead < -6.0 or ahead > 70.0:
			continue
		for p in g.panes:
			if not p.alive or p.falling or p.opened:
				continue
			if p.move.is_valid():
				p.move.call(p, t, ahead)
			if p.charge >= 0.0:
				_charge_step(p, ahead)
	while gates.size() and gates[0].d < dist - 10.0:
		var g: GGate = gates.pop_front()
		for p in g.panes:
			if p.alive and is_instance_valid(p.node):
				p.node.queue_free()
			panes.erase(p)
		for e in g.extra:
			if is_instance_valid(e):
				e.queue_free()


func _spin_targets(dt: float) -> void:
	var i := targets.size() - 1
	while i >= 0:
		var tg: GTarget = targets[i]
		if not tg.alive or -tg.node.position.z < dist - 6.0:
			if tg.alive and is_instance_valid(tg.node):
				tg.node.queue_free()
			targets.remove_at(i)
		elif tg.spin != 0.0:
			tg.node.rotate_y(dt * tg.spin)
		i -= 1


func _run_anims(dt: float) -> void:
	var i := anims.size() - 1
	while i >= 0:
		var f: Callable = anims[i]
		if not f.call(dt):
			anims.remove_at(i)
		i -= 1


## is any glass of this gate in front of your face as you reach it? (a short line straight ahead from the eye)
func _blocks(p: GPane) -> Vector2:
	var xf: Transform3D = p.node.global_transform
	var inv := xf.affine_inverse()
	var gz := xf.origin.z
	var a: Vector3 = inv * Vector3(cam.position.x, EYE, gz + 0.7)
	var b: Vector3 = inv * Vector3(cam.position.x, EYE, gz - 0.7)
	if a.z * b.z > 0.0 or absf(a.z - b.z) < 1e-5:
		return Vector2.INF
	var s := a.z / (a.z - b.z)
	var h := a.lerp(b, s)
	var lp := Vector2(h.x, h.y)
	return lp if Glass.inside(p.poly, lp, 0.22) else Vector2.INF


func _check_gates(prev: float) -> void:
	for g in gates:
		if g.passed or not (prev < g.d and dist >= g.d):
			continue
		g.passed = true
		if g.end_level:
			_level_done()
			return
		var hit := []
		for p in g.panes:
			if not p.alive or not p.blocks or p.opened or p.falling:
				continue
			var lp := _blocks(p)
			if lp != Vector2.INF:
				hit.append([p, lp])
		var grille_shut: bool = g.grille != null and not g.grille_open
		if hit.size() or grille_shut:
			_crash(hit, g)
		elif g.door:
			_checkpoint(g)


func _crash(hit: Array, g: GGate) -> void:
	if g.grille and not g.grille_open:
		_open_grille(g)
	for h in hit:
		break_pane(h[0], h[1], Vector3(0, 0, -1), true)
	if mode == "calm":
		shake = 0.25
		sfx.play("shatter0", -4.0)
		return
	crashes += 1
	balls = maxi(0, balls - 10)
	jar_streak = 0
	multi = 1
	combo_n = 0
	combo_color = -1
	shake = 1.0
	hud.flash_screen(Color("ff3b3b"), 0.5, 0.5)
	hud.show_toast("−10", Color("ff6b6b"), 0.5)
	sfx.play("crash", 0.0, randf_range(0.95, 1.05))
	vibe(90)


func _checkpoint(g: GGate) -> void:
	var r := _room_of(g.d) + 1
	if r > cp_room:
		cp_room = r
		save.cp = r
		_save()
	# in the endless run the next room's name says it (see _process)
	if mode != "endless":
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
	if balls <= 0 and mode != "calm":
		sfx.play("tick", -6.0, 0.6)
		return
	_throw(cam.project_ray_normal(screen))


## a little help with aim: a throw that only just misses glass (or a jar, a prism, a button) is bent onto it
func _assist(dir: Vector3) -> Vector3:
	var o := cam.position
	var from := o + dir * 1.3 + Vector3(0, -0.3, 0)
	var on_glass := INF
	var cands := []
	for p in panes:
		if not p.alive or p.opened or p.falling:
			continue
		var xf: Transform3D = p.node.global_transform
		var ahead := -xf.origin.z - dist
		if ahead < 2.5 or ahead > 48.0:
			continue
		var inv := xf.affine_inverse()
		var la: Vector3 = inv * o
		var lb: Vector3 = inv * (o + dir * 90.0)
		if la.z * lb.z > 0.0 or is_equal_approx(la.z, lb.z):
			continue
		var lh := la.lerp(lb, la.z / (la.z - lb.z))
		var lp := Vector2(lh.x, lh.y)
		if Glass.inside(p.poly, lp):
			on_glass = minf(on_glass, ahead)
			continue
		# the nearest point well inside the pane, towards its middle
		var c := Glass.centroid(p.poly)
		var q := lp
		for i in 8:
			q = q.lerp(c, 0.3)
			if Glass.inside(p.poly, q, 0.12):
				break
		var wpt: Vector3 = xf * Vector3(q.x, q.y, 0)
		cands.append([dir.angle_to((wpt - o).normalized()) / 0.75, wpt, ahead])
	for tg in targets:
		if not tg.alive:
			continue
		var tp: Vector3 = tg.node.global_position
		var ahead := -tp.z - dist
		if ahead < 2.5 or ahead > 48.0:
			continue
		cands.append([dir.angle_to((tp - o).normalized()), tp, ahead])
	var best_a := deg_to_rad(4.5)
	var best_pt = null
	for cd in cands:
		if cd[0] < best_a and cd[2] < on_glass:
			best_a = cd[0]
			best_pt = cd[1]
	if best_pt == null:
		return dir
	var aim: Vector3 = best_pt
	var flight := from.distance_to(aim) / (BALL_SPEED + speed)
	aim.y += 0.5 * GRAV * flight * flight
	return (aim - from).normalized()


func _throw(dir: Vector3) -> void:
	dir = _assist(dir)
	if mode != "calm":
		balls -= 1
	shots += 1
	var shot := {"hit": false}
	var from := cam.position + dir * 1.3 + Vector3(0, -0.3, 0)
	for i in multi:
		var d2 := dir
		if i > 0:
			d2 = dir.rotated(Vector3.UP, (0.035 if i == 1 else -0.035))
		var ci := randi() % marble_mats.size()
		var mi := MeshInstance3D.new()
		mi.mesh = marble_mesh
		mi.material_override = marble_mats[ci]
		mi.position = from
		root3d.add_child(mi)
		flying.append({"node": mi, "v": d2 * (BALL_SPEED + speed), "life": 0.0, "pts": [from], "col": Glass.COLORS[ci], "shot": shot})
	sfx.play("throw", -10.0, randf_range(0.9, 1.15))


func _update_balls(dt: float) -> void:
	var i := flying.size() - 1
	while i >= 0:
		var b: Dictionary = flying[i]
		var node: MeshInstance3D = b.node
		var a: Vector3 = node.position
		var v: Vector3 = b.v
		v.y -= GRAV * dt
		var nb := a + v * dt
		# the nearest glass in the way of this step
		var best: GPane = null
		var best_s := 2.0
		var best_lp := Vector2.ZERO
		for p in panes:
			if not p.alive or p.opened:
				continue
			var xf: Transform3D = p.node.global_transform
			var pz := xf.origin.z
			if absf(pz - a.z) > 4.0 and absf(pz - nb.z) > 4.0:
				continue
			var inv := xf.affine_inverse()
			var la: Vector3 = inv * a
			var lb: Vector3 = inv * nb
			if la.z * lb.z > 0.0 or la.z == lb.z:
				continue
			var s := la.z / (la.z - lb.z)
			if s >= best_s:
				continue
			var lh := la.lerp(lb, s)
			if not Glass.inside(p.poly, Vector2(lh.x, lh.y)):
				continue
			best = p
			best_s = s
			best_lp = Vector2(lh.x, lh.y)
		if best:
			_count_hit(b)
			var res := _hit(best, best_lp, v.normalized(), b)
			if res == "break" or res == "open":
				v *= 0.85
			elif res == "reflect":
				var nrm: Vector3 = best.node.global_transform.basis.z.normalized()
				v = (v - 2.0 * v.dot(nrm) * nrm) * 0.8
				nb = a
			else:
				var nrm: Vector3 = best.node.global_transform.basis.z.normalized()
				v = (v - 2.0 * v.dot(nrm) * nrm) * 0.3
				nb = a
		# round things to shoot
		for tg in targets:
			if not tg.alive:
				continue
			if _seg_dist(a, nb, tg.node.global_position) < tg.radius:
				_count_hit(b)
				tg.alive = false
				if tg.on_hit.is_valid():
					tg.on_hit.call()
				_target_burst(tg)
		var bsec := section_at(-nb.z)
		if nb.y < 0.13 and bsec != "sky":
			nb.y = 0.13
			v.y = absf(v.y) * 0.45
			v.x *= 0.8
		var lim := INF if bsec == "sky" else (Worlds.HALL_W - 0.3 if bsec == "hall" else HALF_W - 0.13)
		if absf(nb.x) > lim:
			nb.x = signf(nb.x) * lim
			v.x = -v.x * 0.5
		node.position = nb
		b.v = v
		b.life += dt
		var pts: Array = b.pts
		pts.append(nb)
		if pts.size() > 7:
			pts.pop_front()
		if b.life > 2.2 or -nb.z < dist - 3.0:
			node.queue_free()
			flying.remove_at(i)
		i -= 1


func _count_hit(b: Dictionary) -> void:
	var shot: Dictionary = b.shot
	if not shot.hit:
		shot.hit = true
		hits += 1


func _seg_dist(a: Vector3, b: Vector3, p: Vector3) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 1e-8:
		return a.distance_to(p)
	var s := clampf((p - a).dot(ab) / l, 0.0, 1.0)
	return (a + ab * s).distance_to(p)


# ---------- glass being hit ----------
## a ball hits a pane: "break", "open", "reflect" or "hold"
func _hit(p: GPane, lp: Vector2, dir: Vector3, _b: Dictionary) -> String:
	var hit_w: Vector3 = p.node.global_transform * Vector3(lp.x, lp.y, 0)
	fx.spark(hit_w, Glass.look(p.kind, p.color_id)[2], 16)
	# the weak spot breaks it at once
	if p.weak != Vector2.INF and lp.distance_to(p.weak) < 0.42:
		hud.popup("Weak spot!", cam.unproject_position(hit_w), Color("ff8a5c"))
		score += 25
		break_pane(p, lp, dir)
		return "break"
	# hinged: hit near the far edge and it swings open
	if p.hinge != 0 and not p.opened:
		var bb := Glass.bounds(p.poly)
		var far := (lp.x - bb.position.x) / bb.size.x
		if (p.hinge > 0 and far < 0.35) or (p.hinge < 0 and far > 0.65):
			_swing_open(p)
			hud.popup("Swing!", cam.unproject_position(hit_w), Hud.ACCENT)
			score += 20
			return "open"
	if p.shy and p.hp >= 2:
		p.hp -= 1
		_shy_move(p, lp)
		sfx.play("crack", -4.0, 1.3)
		return "hold"
	p.hp -= 1
	if p.hp <= 0:
		if p.kind == "laminated":
			_fall_flat(p)
			return "break"
		break_pane(p, lp, dir)
		return "break"
	_crack(p, lp)
	if p.kind == "laminated":
		_sag(p)
	if p.kind == "mirror":
		sfx.play("ring", -3.0, randf_range(0.95, 1.1))
		return "reflect"
	return "hold"


func _crack(p: GPane, lp: Vector2) -> void:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	var sz := 1.1 + p.cracks.size() * 0.35
	qm.size = Vector2(sz, sz)
	q.mesh = qm
	q.material_override = crack_mat
	q.position = Vector3(lp.x, lp.y, Glass.KINDS[p.kind].t * 0.5 + 0.01)
	q.rotation.z = randf() * TAU
	p.node.add_child(q)
	p.cracks.append(q)
	q.scale = Vector3.ONE * 0.2
	var k := [0.0]
	var wq: WeakRef = weakref(q)
	anims.append(func(dt: float) -> bool:
		var qq = wq.get_ref()
		if not qq:
			return false
		k[0] = minf(1.0, k[0] + dt / 0.12)
		qq.scale = Vector3.ONE * (0.2 + 0.8 * k[0])
		return k[0] < 1.0)
	# the thicker the glass, the deeper the knock
	var th: float = Glass.KINDS[p.kind].t
	if th >= 0.3:
		sfx.play("thud", 0.0, randf_range(0.85, 1.0) - th * 0.2)
		sfx.play("crack", -7.0, 0.7)
		vibe(30)
	else:
		sfx.play("crack", -2.0, randf_range(0.9, 1.1))
		vibe(15)


func _mesh_shard(cell: PackedVector2Array, kind: String, color_id: int) -> MeshInstance3D:
	var mi: MeshInstance3D
	if shard_pool.size():
		mi = shard_pool.pop_back()
		mi.visible = true
	else:
		mi = MeshInstance3D.new()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3d.add_child(mi)
	mi.mesh = Glass.slab_mesh(cell, kind, 0.6, color_id)
	return mi


func _free_shard(mi: MeshInstance3D) -> void:
	mi.visible = false
	mi.mesh = null
	if shard_pool.size() < 120:
		shard_pool.append(mi)
	else:
		mi.queue_free()


func break_pane(p: GPane, lp: Vector2, dir: Vector3, crash := false, quiet := false) -> void:
	if not p.alive:
		return
	p.alive = false
	if not crash:
		broken += 1
		score += 10 * _mult()
		_combo(p.color_id, p.node.global_transform * Vector3(lp.x, lp.y, 0))
		if p.bonus > 0:
			score += p.bonus * _mult()
			var bw: Vector3 = p.node.global_transform * Vector3(lp.x, lp.y, 0)
			if not cam.is_position_behind(bw):
				hud.popup("+%d" % (p.bonus * _mult()), cam.unproject_position(bw), Color("ffd36b"))
			# all the bonus glass of one island or rack: marbles back
			var left := 0
			for q in p.gate.panes:
				if q.alive and q.bonus > 0:
					left += 1
			if left == 0:
				balls += 3
				hud.show_toast("ALL BROKEN  +3", Color("ffd36b"), 0.5)
				sfx.play("multi", -3.0)
	var xf: Transform3D = p.node.global_transform
	var hit_w: Vector3 = xf * Vector3(lp.x, lp.y, 0)
	var area := absf(Glass.area(p.poly))
	var L := Glass.look(p.kind, p.color_id)
	if p.splits and not crash:
		_split_halves(p)
		return
	var K: Dictionary = Glass.KINDS[p.kind]
	var count := clampi(int(K.pieces * clampf(0.6 + area * 0.12, 0.6, 1.6)), 4, 24)
	if save.quality == 0:
		count = maxi(4, count * 2 / 3)
	if p.kind == "tempered":
		var bb := Glass.bounds(p.poly)
		fx.crumble(xf * Vector3(bb.get_center().x, bb.get_center().y, 0), xf.basis, bb.size * 0.5, L[0], dir)
		count = 5
	var cells := Glass.voronoi(p.poly, Glass.seeds_for(p.poly, lp, count))
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := _mesh_shard(Glass.moved(cell, -cc), p.kind, p.color_id)
		mi.global_transform = xf * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		var away: Vector3 = mi.global_transform.origin - hit_w
		var v := away.normalized() * randf_range(1.5, 4.5) + dir * randf_range(2.0, 6.0) + Vector3(0, randf_range(0.5, 2.5), 0)
		if crash:
			v = away.normalized() * randf_range(2.0, 5.0) + Vector3(0, randf_range(1.0, 3.0), -speed * 0.6)
		if K.t >= 0.3:
			v *= 0.55
		var axis := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		shards.append({"node": mi, "v": v, "axis": axis, "w": randf_range(3.0, 11.0) * (0.5 if K.t >= 0.3 else 1.0), "life": 0.0})
	p.node.queue_free()
	var cap := 260 if save.quality > 0 else 120
	while shards.size() > cap:
		var s: Dictionary = shards.pop_front()
		_free_shard(s.node)
	if area > 2.5:
		fx.crack_burst(Transform3D(xf.basis, hit_w + xf.basis.z * 0.05), sqrt(area) * 1.6)
	fx.flash(hit_w, L[2], 1.5 + minf(area, 6.0) * 0.4)
	fx.spark(hit_w, L[2], 22 + int(minf(area, 8.0) * 4), 1.2)
	if not quiet:
		if K.t >= 0.3:
			sfx.play("heavy", 0.0, randf_range(0.92, 1.05) - minf(K.t, 0.9) * 0.15)
			sfx.play("shatter2", -9.0, 0.75)
		else:
			var v := clampi(int(3.0 - area * 0.4), 0, 2)
			var pitch := randf_range(1.12, 1.3) if p.kind == "thin" else randf_range(0.92, 1.1)
			sfx.play("shatter%d" % v, -1.0 if area > 3.0 else -4.0, pitch)
		if p.color_id >= 0:
			sfx.note(combo_n)
	if not crash and area > 3.0:
		hitstop_until = Time.get_ticks_msec() + 45
		fov_kick = 1.6
		vibe(22)
	elif not crash:
		vibe(12)
	# what it brings down with it
	if p.kind == "blast":
		_blast(p, hit_w)
	for sp in p.supports:
		_collapse(sp)
	if p.on_break.is_valid():
		p.on_break.call()


func _combo(color_id: int, at: Vector3) -> void:
	if color_id < 0:
		return
	if color_id == combo_color:
		combo_n += 1
	else:
		combo_color = color_id
		combo_n = 1
	best_combo = maxi(best_combo, combo_n)
	if combo_n >= 3 and combo_n % 5 == 0:
		balls += 2
		hud.show_toast("%s ×%d  +2" % [Glass.COLOR_NAMES[color_id], combo_n], Glass.COLORS[color_id], 0.5)
		sfx.play("multi", -3.0)
	elif combo_n >= 3 and not cam.is_position_behind(at):
		hud.popup("×%d" % _mult(), cam.unproject_position(at), Glass.COLORS[color_id])


func _target_burst(tg: GTarget) -> void:
	var pos := tg.node.global_position
	var col := Color(0.8, 1, 1)
	if tg.kind == "prism":
		col = Glass.COLORS[tg.color_id]
	elif tg.kind != "jar":
		col = Color("ffc861")
	fx.spark(pos, col, 30, 1.3)
	fx.flash(pos, col, 2.0)
	var hex := Glass.ngon(6, 0.36)
	var cells := Glass.voronoi(hex, Glass.seeds_for(hex, Vector2(0.05, 0.02), 6))
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := _mesh_shard(Glass.moved(cell, -cc), "mid", tg.color_id)
		mi.global_position = pos + Vector3(cc.x, cc.y, 0)
		shards.append({"node": mi, "v": Vector3(cc.x, cc.y + 0.3, 0).normalized() * randf_range(2.0, 4.0), "axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), "w": randf_range(4.0, 12.0), "life": 0.0})
	tg.node.queue_free()


func _jar_got(_tg: GTarget) -> void:
	balls += 3
	jar_streak += 1
	var at := cam.unproject_position(_tg.node.global_position) if not cam.is_position_behind(_tg.node.global_position) else Vector2(640, 300)
	hud.popup("+3", at)
	var want := 3 if jar_streak >= 25 else 2 if jar_streak >= 10 else 1
	if want > multi:
		multi = want
		hud.show_toast("×%d MARBLES" % multi, Hud.ACCENT, 0.6)
		sfx.play("multi", -2.0)
	sfx.play("crystal", -3.0, randf_range(0.95, 1.08))


func break_all(list: Array, text: String, bonus: int) -> void:
	var k := 0
	for p in list:
		if p.alive:
			var pp: GPane = p
			var delay := k * 0.06
			k += 1
			var tt := [0.0]
			anims.append(func(dt: float) -> bool:
				tt[0] += dt
				if tt[0] < delay:
					return true
				break_pane(pp, Vector2.ZERO, Vector3(0, 0, -1), false, k > 2)
				return false)
	balls += bonus
	score += 30
	hud.show_toast(text, Color("ffc861"), 0.5)
	sfx.play("multi", -4.0)


## break one, and the rest follow one by one (nearest first), each ringing a note higher
func chain_break(list: Array, text: String, bonus: int) -> void:
	var k := 0
	for p in list:
		if not p.alive:
			continue
		var pp: GPane = p
		var delay := 0.05 + k * 0.055
		var n := k
		k += 1
		var tt := [0.0]
		anims.append(func(dt: float) -> bool:
			tt[0] += dt
			if tt[0] < delay:
				return true
			if pp.alive:
				break_pane(pp, Vector2.ZERO, Vector3(0, 0, -1), false, true)
				sfx.note(n)
			return false)
	balls += bonus
	hud.show_toast(text, Color("ffc861"), 0.5)


func _prism_fire(tg: GTarget) -> void:
	var c := tg.color_id
	var from := tg.node.global_position
	var list := []
	for p in panes:
		if not p.alive or p.color_id != c:
			continue
		var pz: float = -p.node.global_transform.origin.z
		if pz < dist or pz > dist + 45.0:
			continue
		list.append(p)
	list.sort_custom(func(a, b): return a.node.global_transform.origin.distance_to(from) < b.node.global_transform.origin.distance_to(from))
	var k := 0
	for p in list:
		var pp: GPane = p
		var delay := 0.08 + k * 0.07
		var n := k
		k += 1
		var tt := [0.0]
		var fired := [false]
		anims.append(func(dt: float) -> bool:
			tt[0] += dt
			if not fired[0] and tt[0] >= delay - 0.06:
				fired[0] = true
				if pp.alive:
					fx.beam(from, pp.node.global_transform.origin, Glass.COLORS[c], 0.5)
			if tt[0] < delay:
				return true
			if pp.alive:
				break_pane(pp, Vector2.ZERO, (pp.node.global_transform.origin - from).normalized(), false, true)
				sfx.note(n + 2)
				score += 15
			return false)
	score += 50
	hud.show_toast("Prism · %s ×%d" % [Glass.COLOR_NAMES[c], list.size()], Glass.COLORS[c], 0.7)
	sfx.play("prism", -1.0)
	hitstop_until = Time.get_ticks_msec() + 60
	vibe(30)


func _blast(p: GPane, at: Vector3) -> void:
	fx.flash(at, Color("ff8a3c"), 5.0)
	fx.spark(at, Color("ffb060"), 50, 1.8)
	shake = maxf(shake, 0.5)
	sfx.play("boom", 0.0)
	hitstop_until = Time.get_ticks_msec() + 70
	var k := 0
	for q in panes:
		if not q.alive or q == p:
			continue
		var qo: Vector3 = q.node.global_transform.origin
		if qo.distance_to(at) > 3.4:
			continue
		var qq: GPane = q
		var delay := 0.04 + k * 0.03
		k += 1
		var tt := [0.0]
		anims.append(func(dt: float) -> bool:
			tt[0] += dt
			if tt[0] < delay:
				return true
			if qq.alive:
				break_pane(qq, Vector2.ZERO, (qq.node.global_transform.origin - at).normalized(), false, true)
			return false)
	if k:
		hud.show_toast("Boom ×%d" % (k + 1), Color("ff8a3c"), 0.5)


func _collapse(p: GPane) -> void:
	if not p.alive or p.falling:
		return
	p.falling = true
	p.blocks = false
	var v := [Vector3(randf_range(-0.6, 0.6), 0.5, randf_range(-1.5, -0.5))]
	var axis := Vector3(randf() - 0.5, 0, randf() - 0.5).normalized()
	var w := randf_range(1.0, 2.5)
	anims.append(func(dt: float) -> bool:
		if not p.alive:
			return false
		v[0].y -= 12.0 * dt
		p.node.position += v[0] * dt
		p.node.rotate(axis, w * dt)
		if p.node.position.y > 0.6:
			return true
		break_pane(p, Vector2.ZERO, Vector3(0, -1, 0), false, false)
		return false)
	sfx.play("creak", -3.0)


func _swing_open(p: GPane) -> void:
	p.opened = true
	p.blocks = false
	var bb := Glass.bounds(p.poly)
	var hx := bb.end.x if p.hinge > 0 else bb.position.x
	var pivot: Vector3 = p.base * Vector3(hx, 0, 0)
	var k := [0.0]
	var base := p.base
	var sgn := -float(p.hinge)
	anims.append(func(dt: float) -> bool:
		if not p.alive:
			return false
		k[0] = minf(1.0, k[0] + dt / 0.35)
		var e := 1.0 - pow(1.0 - k[0], 3.0)
		var r := Basis(Vector3.UP, sgn * 1.7 * e)
		p.node.transform = Transform3D(r, pivot + r * (base.origin - pivot))
		return k[0] < 1.0)
	sfx.play("creak", -2.0, 1.2)


func _shy_move(p: GPane, lp: Vector2) -> void:
	var dx := -signf(lp.x if absf(lp.x) > 0.05 else 1.0) * 0.95
	var start := p.base
	var to := p.base.translated(Vector3(dx, 0, 0))
	p.base = to
	var k := [0.0]
	anims.append(func(dt: float) -> bool:
		if not p.alive:
			return false
		k[0] = minf(1.0, k[0] + dt / 0.18)
		p.node.transform = Transform3D(start.basis, start.origin.lerp(to.origin, 1.0 - pow(1.0 - k[0], 3.0)))
		return k[0] < 1.0)
	_crack(p, lp)
	var at: Vector3 = p.node.global_transform.origin
	if not cam.is_position_behind(at):
		hud.popup("Hey!", cam.unproject_position(at), Color("ffd36b"))


func _sag(p: GPane) -> void:
	var bb := Glass.bounds(p.poly)
	var pivot: Vector3 = p.base * Vector3(0, bb.position.y, 0)
	var base := p.base
	var r := Basis(Vector3(1, 0, 0), -0.12)
	p.base = Transform3D(r * base.basis, pivot + r * (base.origin - pivot))
	p.node.transform = p.base


func _fall_flat(p: GPane) -> void:
	p.falling = true
	p.blocks = false
	broken += 1
	score += 10 * _mult()
	var bb := Glass.bounds(p.poly)
	var pivot: Vector3 = p.base * Vector3(0, bb.position.y, 0)
	var base := p.base
	var k := [0.0]
	anims.append(func(dt: float) -> bool:
		if not p.alive:
			return false
		k[0] = minf(1.0, k[0] + dt / 0.45)
		var r := Basis(Vector3(1, 0, 0), -1.5 * k[0] * k[0])
		p.node.transform = Transform3D(r * base.basis, pivot + r * (base.origin - pivot))
		if k[0] < 1.0:
			return true
		p.falling = false
		break_pane(p, Vector2(0, bb.position.y + 0.2), Vector3(0, -1, 0), true, false)
		return false)
	sfx.play("creak", -2.0, 0.8)


func _split_halves(p: GPane) -> void:
	var xf: Transform3D = p.node.global_transform
	p.node.queue_free()
	for sd in [-1.0, 1.0]:
		var half := Glass.clip(p.poly, Vector2(-sd, 0), 0.0)
		if half.size() < 3:
			continue
		var cc := Glass.centroid(half)
		var mi := _mesh_shard(Glass.moved(half, -cc), p.kind, p.color_id)
		mi.global_transform = xf * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		shards.append({"node": mi, "v": Vector3(sd * 3.5, 0.6, 0), "axis": Vector3(0, 0, 1), "w": sd * -0.8, "life": 0.0, "slide": true})
	sfx.play("crack", 0.0, 0.8)
	sfx.play("shatter2", -8.0, 1.2)
	fx.flash(xf.origin, Color.WHITE, 1.5)


func _charge_step(p: GPane, ahead: float) -> void:
	var k := clampf((27.0 - ahead) / 15.0, 0.0, 1.0)
	if k > 0.05 and randf() < k * 0.25:
		var bb := Glass.bounds(p.poly)
		fx.spark(p.node.global_transform * Vector3(randf_range(bb.position.x, bb.end.x), randf_range(bb.position.y, bb.end.y), 0), Color("b98bff"), 6, 0.6)
		if randf() < 0.3:
			sfx.play("zap", -10.0 + k * 6.0, randf_range(0.8, 1.3))
	if k >= 1.0:
		p.charge = -1.0
		p.kind = "slab"
		p.hp = 3
		p.color_id = 4
		p.node.mesh = Glass.slab_mesh(p.poly, "slab", 1.0, 4)
		fx.flash(p.node.global_transform.origin, Color("b98bff"), 4.0)
		hud.show_toast("Charged: 3 hits", Color("b98bff"), 0.5)
		sfx.play("boom", -4.0, 1.4)


func _open_grille(g: GGate) -> void:
	if g.grille_open:
		return
	g.grille_open = true
	var y0 := g.grille.position.y
	var wm: WeakRef = weakref(g.grille)
	var k := [0.0]
	anims.append(func(dt: float) -> bool:
		var m = wm.get_ref()
		if not m:
			return false
		k[0] = minf(1.0, k[0] + dt / 0.35)
		m.position.y = y0 + (1.0 - pow(1.0 - k[0], 3.0)) * 4.2
		return k[0] < 1.0)
	sfx.play("clank", -2.0)


func finale_break(rest: Array, d: float) -> void:
	var c := Vector3(0, EYE, -d)
	var list := rest.filter(func(p): return p.alive)
	list.sort_custom(func(a, b): return a.node.global_transform.origin.distance_to(c) < b.node.global_transform.origin.distance_to(c))
	var k := 0
	for p in list:
		var pp: GPane = p
		var delay := 0.03 + k * 0.035
		var n := k
		k += 1
		var tt := [0.0]
		anims.append(func(dt: float) -> bool:
			tt[0] += dt
			if tt[0] < delay:
				return true
			if pp.alive:
				break_pane(pp, Vector2.ZERO, (pp.node.global_transform.origin - c).normalized(), false, true)
				if n % 2 == 0:
					sfx.note(n / 2)
			return false)
	slow_until = t + 1.2
	score += 200
	balls += 10
	hud.show_toast("FINALE  +10", Color("ffd36b"), 1.0)
	hud.flash_screen(Color.WHITE, 0.4, 0.8)
	sfx.play("checkpoint", 0.0)
	shake = 0.6
	vibe(60)


func _update_shards(dt: float) -> void:
	var i := shards.size() - 1
	while i >= 0:
		var s: Dictionary = shards[i]
		var n: MeshInstance3D = s.node
		var v: Vector3 = s.v
		if s.has("slide"):
			v *= exp(-dt * 1.2)
		else:
			v.y -= 14.0 * dt
		var pos := n.position + v * dt
		if pos.y < 0.06 and section_at(-pos.z) != "sky":
			pos.y = 0.06
			v.y = absf(v.y) * 0.3
			v.x *= 0.6
			v.z *= 0.6
			s.w *= 0.6
		n.position = pos
		n.rotate(s.axis, s.w * dt)
		s.v = v
		s.life += dt
		if s.life > 5.0 or -pos.z < dist - 4.0 or pos.y < -40.0:
			_free_shard(n)
			shards.remove_at(i)
		i -= 1


# ---------- testing ----------
var _fired := {}


func _auto_play() -> void:
	# a simple player: throws at glass in front of the eye, at jars, hubs, prisms and buttons
	var target_pos = null
	var key := 0
	var best_d := 1e9
	for p in panes:
		if not p.alive or not p.blocks or p.opened or p.falling:
			continue
		var gz: float = p.node.global_transform.origin.z
		var ahead := -gz - dist
		if ahead < 5.0 or ahead > 24.0:
			continue
		var xf: Transform3D = p.node.global_transform
		var l: Vector3 = xf.affine_inverse() * Vector3(cam.position.x, EYE, gz)
		if not Glass.inside(p.poly, Vector2(l.x, l.y), 0.3):
			continue
		var id: int = p.get_instance_id()
		if _fired.has(id) and t - _fired[id] < 0.55:
			continue
		var aim := Vector3(cam.position.x, EYE, gz)
		if p.weak != Vector2.INF:
			aim = xf * Vector3(p.weak.x, p.weak.y, 0)
		if ahead < best_d:
			best_d = ahead
			target_pos = aim
			key = id
	# bonus glass (below in the sky, at the sides of a hall), when nothing is in the way
	for p in panes:
		if not p.alive or p.bonus <= 0 or balls < 12:
			continue
		var xf: Transform3D = p.node.global_transform
		var ahead := -xf.origin.z - dist
		if ahead < 8.0 or ahead > 26.0:
			continue
		var id: int = p.get_instance_id()
		if _fired.has(id) and t - _fired[id] < 1.0:
			continue
		if ahead + 6.0 < best_d:
			best_d = ahead + 6.0
			var cc := Glass.centroid(p.poly)
			target_pos = xf * Vector3(cc.x, cc.y, 0)
			key = id
	for tg in targets:
		if not tg.alive:
			continue
		var pos: Vector3 = tg.node.global_position
		var ahead := -pos.z - dist
		if ahead < 6.0 or ahead > 24.0:
			continue
		var id: int = tg.get_instance_id()
		if _fired.has(id) and t - _fired[id] < 0.5:
			continue
		var bonus := 3.0 if tg.kind != "jar" else 0.0
		if ahead - bonus < best_d:
			best_d = ahead - bonus
			target_pos = pos
			key = id
	if target_pos != null and (balls > 0 or mode == "calm"):
		_fired[key] = t
		var to: Vector3 = target_pos
		var tt := (to - cam.position).length() / (BALL_SPEED + speed)
		to.y += 0.5 * GRAV * tt * tt
		_throw((to - cam.position).normalized())


func _test_hooks() -> void:
	log_n += 1
	if log_n % 120 == 0:
		print("d=%d balls=%d crashes=%d broken=%d score=%d combo=%d shards=%d panes=%d anims=%d nodes=%d fps=%d" % [int(dist), balls, crashes, broken, score, best_combo, shards.size(), panes.size(), anims.size(), root3d.get_child_count(), Engine.get_frames_per_second()])
	if shots_at.size() and dist >= shots_at[0]:
		var d := int(shots_at.pop_front())
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_dir + "shot_%d.png" % d)
	if quit_at > 0.0 and dist >= quit_at:
		print("END d=%d balls=%d crashes=%d broken=%d score=%d shots=%d hits=%d" % [int(dist), balls, crashes, broken, score, shots, hits])
		get_tree().quit()


func _screen_test() -> void:
	for i in 60:
		await get_tree().process_frame
	if test_screen.begins_with("gallery"):
		var types: Array = test_screen.substr(8).split(",") if test_screen.length() > 8 else ["pane", "split", "grid", "stack", "color_row", "layers", "tempered", "frosted", "slide", "rise", "doors", "flyin", "rotor", "spinner", "pendulum", "orbit", "snake", "shutters", "revolving", "hinge", "weak", "laminated", "shy", "halves", "mirror", "blast", "shield", "grille", "collapse", "charge", "prism", "finale"]
		var wi := 0
		hud._hide_all()
		for ty in types:
			_reset("gallery")
			mode = "gallery"
			state = S.MENU
			var w: String = Worlds.LIST[wi % Worlds.LIST.size()]
			wi += 1
			_set_world(w, true)
			for c in root3d.get_children():
				c.queue_free()
			segs.clear()
			gates.clear()
			panes.clear()
			targets.clear()
			next_seg = 0
			dist = 0.0
			while next_seg * SEG < 60.0:
				var seg := Worlds.build(w, next_seg * SEG, next_seg * 31 + 7)
				root3d.add_child(seg)
				next_seg += 1
			if ty == "finale":
				Obstacles.finale(self, 9.5)
			else:
				Obstacles.build(self, ty, 9.5, 4)
			t = 1.3
			_move_gates()
			_place_camera(0.0)
			fx.step(0.016, [])
			for i in 6:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(shot_dir + "gal_%s.png" % ty)
		get_tree().quit()
		return
	match test_screen:
		"levels":
			hud.show_levels(save)
		"settings":
			hud.show_settings()
		"pause":
			_start("endless")
			for i in 40:
				await get_tree().process_frame
			_pause()
		"over":
			_start("endless")
			for i in 40:
				await get_tree().process_frame
			dist = 347.0
			_game_over()
		"done":
			_start("level1")
			for i in 40:
				await get_tree().process_frame
			score = 2350
			broken = 64
			shots = 80
			hits = 66
			best_combo = 9
			_level_done()
	for i in 30:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shot_dir + "screen_%s.png" % test_screen)
	get_tree().quit()
