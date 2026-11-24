## Glass Rush: an endless flight, fast, through the glass worlds of Glass Run. Drag to steer the ship.
## Thin glass you smash straight through; thick glass you must miss, or lose a shield. Three shields, then the end.
## The worlds, the glass, the sounds and the little effects are Glass Run's own (copied by tools/sync_shared.sh).
class_name Rush
extends Node3D

enum S { MENU, PLAY, PAUSE, OVER }
var state := S.MENU

const HALF_W := 6.4
const CEIL := 7.4
const SEG := 16.0
const ZONE := 240.0        # the way keeps one shape (corridor, tunnel, hall, sky) this long
const WORLD_LEN := 1440.0  # and one world this long (six shapes)
const AHEAD := 240.0       # how far ahead the way is built
const X_LIM := 5.2         # where the ship can go, side to side
const Y_MIN := 0.9
const Y_MAX := 6.5
const SHIP_R := 0.45       # how near glass the ship may come
const SHIELDS := 3
const BOOST_AT := 5        # crystals for a boost
const BOOST_TIME := 4.0

var dist := 0.0
var speed := 0.0
var t := 0.0
var score := 0
var shields := SHIELDS
var charge := 0            # crystals towards the next boost
var boost_until := -1.0
var safe_until := -1.0     # just hit: a moment when nothing can hit again
var near_n := 0            # near misses in a row
var smashed := 0
var crashes := 0
var over_t := 0.0

var ship_pos := Vector2(0, 3.2)
var target := Vector2(0, 3.2)
var bank := 0.0
var pitch := 0.0
var shake := 0.0
var fov_kick := 0.0

var cam: Camera3D
var env: Environment
var sun: DirectionalLight3D
var root3d: Node3D
var ship: Node3D
var flame: MeshInstance3D
var backdrop: MeshInstance3D
var backdrop_im: ImmediateMesh
var streaks: MultiMeshInstance3D
var glow_tex: Texture2D
var fx: Fx
var sfx: Sfx
var hud: RushHud
var crystal_mesh: Mesh
var crystal_mats: Array = []

var segs: Array = []
var next_seg := 0
var seg_jobs := {}
var walls: Array = []      # {d, node, panes: [{node, poly, thin, alive, base}], move: Callable, passed, kind}
var crystals: Array = []   # {node, d, x, y, shield, alive}
var shards: Array = []
var next_wall := 0.0
var world := ""
var mood := -1
var look_now := {}
var look_to := {}

var save := {"best": 0, "music": true, "sound": true, "vibe": true}
const SAVE_FILE := "user://glass_rush.cfg"

# testing: --auto (a bot flies), --shots=d,d (pictures), --shot-dir=, --quit-at=d, --seed=n
var auto := false
var shots_at: Array = []
var shot_dir := "user://"
var quit_at := -1.0
var run_seed := -1
var _ending := false
var log_n := 0


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "--auto":
			auto = true
		elif a.begins_with("--shots="):
			for s in a.substr(8).split(","):
				shots_at.append(float(s))
		elif a.begins_with("--shot-dir="):
			shot_dir = a.substr(11)
		elif a.begins_with("--quit-at="):
			quit_at = float(a.substr(10))
		elif a.begins_with("--seed="):
			run_seed = int(a.substr(7))
	_load()
	Glass.mats()
	Worlds.mats()
	_make_scene()
	sfx = Sfx.new()
	add_child(sfx)
	sfx.sound_on = save.sound
	sfx.music_on = save.music
	hud = RushHud.new()
	add_child(hud)
	hud.play_pressed.connect(_start)
	hud.pause_pressed.connect(_pause)
	hud.resume_pressed.connect(_resume)
	hud.menu_pressed.connect(_to_menu)
	hud.setting_changed.connect(_on_setting)
	hud.apply_settings(save)
	_reset()
	hud.show_menu(int(save.best))
	sfx.play_music("menu")
	if auto:
		_start()


# ---------- saving ----------
func _load() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE_FILE) == OK:
		for k in save.keys():
			save[k] = c.get_value("save", k, save[k])


func _save() -> void:
	var c := ConfigFile.new()
	for k in save.keys():
		c.set_value("save", k, save[k])
	c.save(SAVE_FILE)


func _on_setting(key: String, value) -> void:
	save[key] = value
	match key:
		"sound":
			sfx.sound_on = value
		"music":
			sfx.set_music(value)
	_save()


func vibe(ms: int) -> void:
	if save.vibe:
		Input.vibrate_handheld(ms)


# ---------- the scene ----------
func _make_scene() -> void:
	root3d = Node3D.new()
	add_child(root3d)
	cam = Camera3D.new()
	cam.near = 0.05
	cam.far = 300.0
	cam.fov = 78.0
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
	env.fog_sky_affect = 0.0
	we.environment = env
	add_child(we)
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
	fx = Fx.new()
	add_child(fx)
	fx.setup(cam, glow_tex)
	_make_ship()
	_make_streaks()
	# crystals: a little glowing octahedron
	crystal_mesh = _octahedron(0.5)
	for c in [Color("bfefff"), Color("5fffb0")]:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = c
		crystal_mats.append(m)


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


func _octahedron(r: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, r * 1.4, 0)
	var bot := Vector3(0, -r * 1.4, 0)
	var ring := [Vector3(r, 0, 0), Vector3(0, 0, r), Vector3(-r, 0, 0), Vector3(0, 0, -r)]
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		for tri in [[top, b, a], [bot, a, b]]:
			var n: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			for v in tri:
				st.set_normal(n)
				st.add_vertex(v)
	return st.commit()


## the ship: a low dart of white and grey, a glowing canopy, wing tips of the world's colour and an engine of light.
## Made of a few shapes in code, so it is light to draw and nobody else's ship.
func _make_ship() -> void:
	ship = Node3D.new()
	add_child(ship)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var white := Color("e4ecf6")
	var grey := Color("8a96ac")
	var dark := Color("3a4254")
	# body: a long wedge, pointed at the front (towards -z)
	var nose := Vector3(0, 0.05, -1.6)
	var tl := Vector3(-0.32, 0.22, 0.7)
	var tr := Vector3(0.32, 0.22, 0.7)
	var bl := Vector3(-0.36, -0.12, 0.75)
	var br := Vector3(0.36, -0.12, 0.75)
	_tri(st, nose, tr, tl, white)
	_tri(st, nose, bl, br, dark)
	_tri(st, nose, tl, bl, grey)
	_tri(st, nose, br, tr, grey)
	_tri(st, tl, tr, br, dark)
	_tri(st, tl, br, bl, dark)
	# wings: swept back and flat
	for sd in [-1.0, 1.0]:
		var root_f := Vector3(sd * 0.25, 0.0, -0.4)
		var root_b := Vector3(sd * 0.3, 0.0, 0.7)
		var tip_b := Vector3(sd * 1.6, -0.08, 0.85)
		var tip_f := Vector3(sd * 1.45, -0.06, 0.45)
		_tri(st, root_f, tip_f, tip_b, white if sd > 0 else white * 0.95)
		_tri(st, root_f, tip_b, root_b, white * 0.9)
		_tri(st, root_f, tip_b, tip_f, grey)
		_tri(st, root_f, root_b, tip_b, grey)
		# a fin at the back, leaning out
		var f0 := Vector3(sd * 0.22, 0.18, 0.3)
		var f1 := Vector3(sd * 0.3, 0.18, 0.75)
		var f2 := Vector3(sd * 0.5, 0.72, 0.85)
		_tri(st, f0, f1, f2, grey)
		_tri(st, f0, f2, f1, grey)
	var body := MeshInstance3D.new()
	var lm := StandardMaterial3D.new()
	lm.vertex_color_use_as_albedo = true
	lm.roughness = 0.35
	lm.metallic = 0.3
	# a little light of its own, so the ship reads in the darkest tunnel
	lm.emission_enabled = true
	lm.emission = Color(0.25, 0.28, 0.34)
	st.set_material(lm)
	body.mesh = st.commit()
	ship.add_child(body)
	# canopy, wing tips and engine glow
	var gs := SurfaceTool.new()
	gs.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tri(gs, Vector3(0, 0.12, -1.05), Vector3(0.16, 0.24, -0.2), Vector3(-0.16, 0.24, -0.2), Color("3fe0ff"))
	_tri(gs, Vector3(-0.16, 0.24, -0.2), Vector3(0.16, 0.24, -0.2), Vector3(0, 0.3, 0.15), Color("3fe0ff") * 0.8)
	for sd in [-1.0, 1.0]:
		_tri(gs, Vector3(sd * 1.45, -0.05, 0.45), Vector3(sd * 1.6, -0.07, 0.85), Vector3(sd * 1.2, -0.04, 0.8), Color("ff3fd0"))
	var gm := StandardMaterial3D.new()
	gm.vertex_color_use_as_albedo = true
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gs.set_material(gm)
	var glow := MeshInstance3D.new()
	glow.mesh = gs.commit()
	ship.add_child(glow)
	flame = MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.11
	fm.height = 0.22
	fm.radial_segments = 10
	fm.rings = 5
	flame.mesh = fm
	var flm := StandardMaterial3D.new()
	flm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flm.albedo_color = Color(0.6, 0.95, 1.0, 0.85)
	flm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flame.material_override = flm
	flame.position = Vector3(0, 0.05, 0.85)
	ship.add_child(flame)
	for c in ship.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ship.scale = Vector3.ONE * 1.25


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, col: Color) -> void:
	var n := (b - a).cross(c - a).normalized()
	st.set_color(col)
	for v in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v)


## lines of light rushing past: thin streaks standing still in the air, drawn long, so the speed shows
const STREAKS := 70


func _make_streaks() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var bx := BoxMesh.new()
	bx.size = Vector3(0.025, 0.025, 1.0)
	mm.mesh = bx
	mm.instance_count = STREAKS
	streaks = MultiMeshInstance3D.new()
	streaks.multimesh = mm
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = Color(0.8, 0.95, 1.0, 0.35)
	streaks.material_override = m
	streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(streaks)
	_streak_pos.resize(STREAKS)
	for i in STREAKS:
		_streak_pos[i] = _new_streak(randf_range(0.0, 90.0))


var _streak_pos: Array = []


func _new_streak(ahead: float) -> Vector3:
	var a := randf() * TAU
	var r := randf_range(2.0, 9.0)
	return Vector3(cos(a) * r, 3.2 + sin(a) * r * 0.7, -dist - ahead)


func _step_streaks() -> void:
	var mm := streaks.multimesh
	var len := clampf(speed * 0.06, 0.6, 5.0) * (1.8 if _boosting() else 1.0)
	for i in STREAKS:
		var p: Vector3 = _streak_pos[i]
		if p.z > cam.position.z + 1.0:
			p = _new_streak(randf_range(60.0, 110.0))
			_streak_pos[i] = p
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1, 1, len)), p))
	var sm := streaks.material_override as StandardMaterial3D
	var sc := sm.albedo_color
	sc.a = clampf((speed - 20.0) / 50.0, 0.1, 0.5) + (0.3 if _boosting() else 0.0)
	sm.albedo_color = sc


# ---------- a run ----------
func _reset() -> void:
	_seg_jobs_clear()
	for c in root3d.get_children():
		c.queue_free()
	segs.clear()
	walls.clear()
	crystals.clear()
	shards.clear()
	if run_seed >= 0:
		seed(run_seed)
	else:
		randomize()
	dist = 0.0
	t = 0.0
	speed = 0.0
	score = 0
	shields = SHIELDS
	charge = 0
	boost_until = -1.0
	safe_until = -1.0
	near_n = 0
	smashed = 0
	crashes = 0
	ship_pos = Vector2(0, 3.2)
	target = ship_pos
	bank = 0.0
	next_seg = 0
	next_wall = 90.0
	world = ""
	mood = -1
	ship.visible = true
	_set_world(true)
	_stream()
	_place_camera(0.0)
	for i in STREAKS:
		_streak_pos[i] = _new_streak(randf_range(0.0, 90.0))


func _start() -> void:
	state = S.PLAY
	_reset()
	speed = 18.0
	hud.show_play()
	sfx.play("throw", -4.0, 0.7)


func _pause() -> void:
	if state != S.PLAY:
		return
	state = S.PAUSE
	hud.show_pause()


func _resume() -> void:
	if state != S.PAUSE:
		return
	state = S.PLAY
	hud.show_play()


func _to_menu() -> void:
	state = S.MENU
	_reset()
	hud.show_menu(int(save.best))
	sfx.play_music("menu")


func _game_over() -> void:
	state = S.OVER
	over_t = 0.0
	var nb := score > int(save.best)
	if nb:
		save.best = score
	_save()
	hud.show_over(score, int(dist), int(save.best), nb)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if not auto:
			_pause()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if hud.back():
			return
		match state:
			S.MENU:
				get_tree().quit()
			S.PLAY:
				_pause()
			S.PAUSE:
				_resume()
			S.OVER:
				_to_menu()


# ---------- steering ----------
func _unhandled_input(e: InputEvent) -> void:
	if state != S.PLAY:
		return
	if e is InputEventScreenDrag:
		# the ship follows the finger: the whole width of the screen is the whole width of the way, and a bit more
		var vs := get_viewport().get_visible_rect().size
		var k := (X_LIM * 2.0 + 3.0) / vs.x
		target += Vector2(e.relative.x, -e.relative.y) * k
		target.x = clampf(target.x, -X_LIM, X_LIM)
		target.y = clampf(target.y, Y_MIN, Y_MAX)


# ---------- each frame ----------
func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 20.0)
	if state == S.PAUSE:
		return
	if state == S.MENU:
		# the title: the ship drifts on slowly through the world
		dist += 9.0 * dt
		t += dt
		speed = 9.0
		target = Vector2(sin(t * 0.5) * 2.0, 3.2 + sin(t * 0.7) * 0.8)
		_fly(dt)
		_stream()
		_move_walls()
		_place_camera(dt)
		_look_step(dt)
		_step_streaks()
		fx.step(dt, [])
		return
	t += dt
	if state == S.PLAY:
		var want := 28.0 + 37.0 * (1.0 - exp(-dist / 5000.0))
		if _boosting():
			want *= 1.45
		speed = lerpf(speed, want, 1.0 - exp(-dt * 1.2))
		var prev := dist
		dist += speed * dt
		score += int(dist) - int(prev)
		if auto:
			_auto_steer()
		_fly(dt)
		_stream()
		_spawn_walls()
		_move_walls()
		_check_walls(prev)
		_check_crystals(prev)
		sfx.set_tension(0.0 if shields >= SHIELDS else (0.45 if shields == 2 else 0.9))
		hud.set_play(score, shields, float(charge) / BOOST_AT if not _boosting() else (boost_until - t) / BOOST_TIME, _boosting(), int(dist))
	else:
		# the end: the wreck slows to a stop
		speed = lerpf(speed, 0.0, 1.0 - exp(-dt * 2.0))
		dist += speed * dt
		over_t += dt
		_stream()
		_move_walls()
		if auto and over_t > 1.5 and not _ending:
			_end_auto()
	_update_shards(dt)
	_place_camera(dt)
	_look_step(dt)
	_step_streaks()
	fx.step(dt, [])
	_test_hooks()


func _boosting() -> bool:
	return t < boost_until


func _fly(dt: float) -> void:
	var prev := ship_pos
	ship_pos = ship_pos.lerp(target, 1.0 - exp(-dt * 11.0))
	var vel := (ship_pos - prev) / maxf(dt, 1e-4)
	bank = lerpf(bank, clampf(-vel.x * 0.09, -0.95, 0.95), 1.0 - exp(-dt * 8.0))
	pitch = lerpf(pitch, clampf(vel.y * 0.05, -0.4, 0.4), 1.0 - exp(-dt * 8.0))
	ship.position = Vector3(ship_pos.x, ship_pos.y, -dist)
	ship.rotation = Vector3(pitch - 0.06, -bank * 0.25, bank)
	# the ship blinks for a moment after a hit
	ship.visible = state != S.OVER and (t >= safe_until or fmod(t, 0.16) < 0.1)
	var f := 1.0 + randf() * 0.35 + (1.2 if _boosting() else 0.0) + clampf((speed - 28.0) / 40.0, 0.0, 0.8)
	flame.scale = Vector3(1.0, 1.0, f * 2.0) * (1.0 + (0.4 if _boosting() else 0.0))


func _place_camera(dt: float) -> void:
	shake = maxf(0.0, shake - dt * 2.2)
	fov_kick = maxf(0.0, fov_kick - dt * 10.0)
	# behind and above the ship, so you see its back and the way past it
	var want := Vector3(ship_pos.x * 0.6, ship_pos.y * 0.65 + 2.7, -dist + 6.2)
	if dt <= 0.0:
		cam.position = want
	else:
		cam.position = cam.position.lerp(want, 1.0 - exp(-dt * 9.0))
		cam.position.z = want.z
	var off := Vector3.ZERO
	if shake > 0.0:
		off = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.3
	cam.position += off
	cam.look_at(Vector3(ship_pos.x * 0.8, ship_pos.y * 0.8 + 0.9, -dist - 22.0), Vector3.UP)
	cam.rotate_object_local(Vector3(0, 0, 1), bank * 0.22)
	var vs := get_viewport().get_visible_rect().size
	var base := 78.0 if vs.y > vs.x else 64.0
	cam.fov = base + clampf((speed - 28.0) * 0.32, 0.0, 14.0) + (8.0 if _boosting() else 0.0) + fov_kick
	backdrop.position = Vector3(0, 3.0, -dist - 250.0)


# ---------- the way: worlds and their shapes ----------
func _world_at(d: float) -> String:
	return Worlds.LIST[int(floor(d / WORLD_LEN)) % Worlds.LIST.size()]


func section_at(d: float) -> String:
	if d < ZONE or state == S.MENU and d < 2000.0:
		return "corridor"
	var w := _world_at(d)
	var zi := int(floor(fmod(d, WORLD_LEN) / ZONE))
	var pairs: Array = Worlds.SECT[w]
	var order := ["corridor", pairs[0][0], "corridor", pairs[0][1], pairs[1][0], pairs[1][1]]
	return order[zi % order.size()]


func _mood_at(d: float) -> int:
	return int(posmod(hash([int(floor(d / ZONE)), "mood"]), 10))


func _stream() -> void:
	var k := next_seg
	while k * SEG < dist + AHEAD + SEG * 3:
		if not seg_jobs.has(k):
			_seg_job(k)
		k += 1
	while next_seg * SEG < dist + AHEAD:
		var seg := _seg_take(next_seg)
		root3d.add_child(seg)
		segs.append({"node": seg, "d": next_seg * SEG})
		next_seg += 1
	while segs.size() and segs[0].d + SEG < dist - 12.0:
		segs[0].node.queue_free()
		segs.pop_front()


func _seg_args(k: int) -> Array:
	var d0 := k * SEG
	var sec := section_at(d0 + 1.0)
	var prev := section_at(d0 - 1.0) if d0 >= SEG else "corridor"
	return [_world_at(d0 + 1.0), d0, k * 7919 + 13, sec, prev, _mood_at(d0 + 2.0), true]


func _seg_job(k: int) -> void:
	var a := _seg_args(k)
	var out := []
	var task := WorkerThreadPool.add_task(func(): out.append(Worlds.shapes(a[0], a[1], a[2], a[3], a[4], a[5], a[6])), true)
	seg_jobs[k] = {"task": task, "out": out}


func _seg_take(k: int) -> Node3D:
	if not seg_jobs.has(k):
		var a := _seg_args(k)
		return Worlds.build(a[0], a[1], a[2], a[3], a[4], a[5], a[6])
	var j: Dictionary = seg_jobs[k]
	seg_jobs.erase(k)
	WorkerThreadPool.wait_for_task_completion(j.task)
	return Worlds.finish(j.out[0])


func _seg_jobs_clear() -> void:
	for k in seg_jobs:
		WorkerThreadPool.wait_for_task_completion(seg_jobs[k].task)
	seg_jobs.clear()


func _exit_tree() -> void:
	_seg_jobs_clear()


# ---------- light and sky ----------
func _set_world(now := false) -> void:
	var w := _world_at(dist)
	var m := _mood_at(dist)
	if w == world and m == mood:
		return
	var new_world := w != world
	world = w
	mood = m
	var L: Dictionary = Worlds.look(w, m)
	look_to = {"bg": L.bg, "amb": L.amb, "sun": L.sun, "rim": L.rim, "sun_e": L.sun_e, "fog": L.fog, "tint": L.tint, "gtint": L.gtint, "sky": _sky_k(), "sky_top": L.sky_top, "sky_hor": L.sky_hor, "ground": L.ground}
	if now or look_now.is_empty():
		look_now = look_to.duplicate()
		_apply_look()
	if new_world:
		sfx.play_music(w if state != S.MENU else "menu")


func _sky_k() -> float:
	var sa := section_at(dist + 30.0)
	if sa == "sky":
		return 1.0
	if sa == "corridor" and _mood_at(dist + 30.0) in Worlds.OPEN:
		return 0.85
	return 0.0


func _apply_look(redraw := true) -> void:
	var k: float = look_now.sky
	var bg: Color = look_now.bg
	var hor: Color = bg.lerp(look_now.sky_hor, k)
	env.background_color = hor
	env.fog_light_color = hor
	env.ambient_light_color = look_now.amb
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = lerpf(18.0, 40.0, k)
	env.fog_depth_end = lerpf(90.0 - look_now.fog * 300.0, 170.0, k)
	env.fog_depth_curve = 1.4
	sun.light_color = look_now.sun
	sun.light_energy = look_now.sun_e
	Worlds.set_tint(look_now.tint, look_now.gtint)
	Glass.rim_mat.albedo_color = Color("eef6f4") if hor.get_luminance() < 0.4 else Color("1c4a50")
	if redraw:
		_draw_backdrop(k, bg, hor)


func _draw_backdrop(k: float, bg: Color, hor: Color) -> void:
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
				backdrop_im.surface_set_color(c_far if layer == 0 else c_near)
				for i in poly.size():
					var q0 := poly[i]
					var q1 := poly[(i + 1) % poly.size()]
					for q in [cb, q0, q1]:
						backdrop_im.surface_add_vertex(Vector3(q.x, q.y, 1.0 + layer))
		backdrop_im.surface_set_color(bg.lerp((Worlds.TUNE[world].lights[0] as Color) * 0.85, k))
		for q in sk.lights:
			for v in [Vector2(-0.5, -0.6), Vector2(0.5, -0.6), Vector2(0.5, 0.6), Vector2(-0.5, -0.6), Vector2(0.5, 0.6), Vector2(-0.5, 0.6)]:
				backdrop_im.surface_add_vertex(Vector3(q.x + v.x, q.y + v.y, 3.0))
	backdrop_im.surface_end()


var _look_n := 0


func _look_step(dt: float) -> void:
	if _world_at(dist) != world or _mood_at(dist) != mood:
		_set_world()
	look_to["sky"] = _sky_k()
	var k := 1.0 - exp(-dt * 2.0)
	var changed := false
	var moving := false
	for key in look_to.keys():
		var a = look_now[key]
		var b = look_to[key]
		if a is Color:
			if a != b:
				changed = true
				var c: Color = a.lerp(b, k)
				if absf(c.r - b.r) + absf(c.g - b.g) + absf(c.b - b.b) + absf(c.a - b.a) < 0.004:
					c = b
				else:
					moving = true
				look_now[key] = c
		elif a != b:
			changed = true
			var f := lerpf(a, b, k)
			if absf(f - b) < 0.002:
				f = b
			else:
				moving = true
			look_now[key] = f
	if changed:
		_look_n += 1
		_apply_look(not moving or _look_n % 4 == 0)


# ---------- glass across the way ----------
## the kinds of wall, in the order you first meet them; more of them, closer together, the further you fly
const WALL_KINDS := ["grid", "smash", "bars", "hole", "slide", "doors", "spinner", "cross"]


func _spawn_walls() -> void:
	while next_wall < dist + AHEAD - 20.0:
		var d := next_wall
		var k := clampf(d / 6000.0, 0.0, 1.0)
		var unlocked := clampi(3 + int(d / 700.0), 3, WALL_KINDS.size())
		var kind: String = WALL_KINDS[randi() % unlocked]
		_wall(kind, d, k)
		next_wall += lerpf(78.0, 40.0, k) + randf_range(-6.0, 10.0)
		if randf() < 0.35:
			_crystal_row(d + randf_range(18.0, 26.0))


func _new_wall(kind: String, d: float) -> Dictionary:
	var n := Node3D.new()
	n.position = Vector3(0, 0, -d)
	root3d.add_child(n)
	var w := {"d": d, "node": n, "panes": [], "move": Callable(), "passed": false, "kind": kind, "ph": randf() * TAU}
	walls.append(w)
	return w


func _pane(w: Dictionary, poly_xy: PackedVector2Array, thin: bool) -> Dictionary:
	var c := Glass.centroid(poly_xy)
	var local := Glass.ccw(Glass.moved(poly_xy, -c))
	var kind := "thin" if thin else "slab"
	var mi := MeshInstance3D.new()
	mi.mesh = Glass.slab_mesh(local, kind, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(c.x, c.y, 0)
	(w.node as Node3D).add_child(mi)
	var p := {"node": mi, "poly": local, "thin": thin, "alive": true, "base": mi.transform, "kind": kind}
	(w.panes as Array).append(p)
	return p


func _wall(kind: String, d: float, k: float) -> void:
	var w := _new_wall(kind, d)
	var thin_p := lerpf(0.5, 0.2, k)
	var x0 := -HALF_W
	var x1 := HALF_W
	match kind:
		"grid", "smash":
			# three by three: one to three open, the rest thick glass, or thin glass you can smash through
			var open := {}
			var n_open := 1 if randf() < 0.3 + k * 0.4 else (2 if randf() < 0.7 else 3)
			while open.size() < n_open:
				open[randi() % 9] = true
			for i in 9:
				if open.has(i):
					continue
				var cx := i % 3
				var cy := i / 3
				var r := Glass.rect(x0 + cx * 12.8 / 3.0 + 0.03, x0 + (cx + 1) * 12.8 / 3.0 - 0.03, cy * CEIL / 3.0 + 0.03, (cy + 1) * CEIL / 3.0 - 0.03)
				_pane(w, r, kind == "smash" or randf() < thin_p)
		"bars":
			# tall bars of thick glass, with room between them for the ship
			var x := x0 + randf_range(0.2, 1.8)
			while x < x1 - 0.6:
				_pane(w, Glass.rect(x, minf(x + 1.3, x1), 0.0, CEIL), false)
				x += 1.3 + randf_range(2.1, 2.8)
		"hole":
			# a wall of thick glass with one square hole in it
			var hx := randf_range(-X_LIM + 1.2, X_LIM - 1.2)
			var hy := randf_range(Y_MIN + 1.0, Y_MAX - 1.0)
			var r := lerpf(1.6, 1.2, k)
			_pane(w, Glass.rect(x0, hx - r, 0.0, CEIL), false)
			_pane(w, Glass.rect(hx + r, x1, 0.0, CEIL), false)
			_pane(w, Glass.rect(hx - r, hx + r, hy + r, CEIL), randf() < thin_p)
			_pane(w, Glass.rect(hx - r, hx + r, 0.0, hy - r), randf() < thin_p)
		"slide":
			# a great sheet of thick glass sliding side to side
			var p := _pane(w, Glass.rect(-4.2, 4.2, 0.0, CEIL), false)
			var sp := randf_range(0.9, 1.5) + k
			w.move = func(ww: Dictionary, tt: float) -> void:
				var pp: Dictionary = ww.panes[0]
				_set_xf(pp, (pp.base as Transform3D).translated(Vector3(sin(tt * sp + float(ww.ph)) * 4.0, 0, 0)))
		"doors":
			# glass from above and below, closing and opening
			_pane(w, Glass.rect(x0, x1, CEIL * 0.5, CEIL + 1.5), false)
			_pane(w, Glass.rect(x0, x1, -1.5, CEIL * 0.5), false)
			var sp := randf_range(1.2, 1.8) + k
			w.move = func(ww: Dictionary, tt: float) -> void:
				var open := 0.75 + 2.0 * (0.5 + 0.5 * sin(tt * sp + float(ww.ph)))
				var top: Dictionary = ww.panes[0]
				var bot: Dictionary = ww.panes[1]
				_set_xf(top, (top.base as Transform3D).translated(Vector3(0, open, 0)))
				_set_xf(bot, (bot.base as Transform3D).translated(Vector3(0, -open, 0)))
		"spinner", "cross":
			# a long blade of thick glass turning about the middle of the way (two in a cross)
			var n := 1 if kind == "spinner" else 2
			for i in n:
				_pane(w, Glass.rect(-8.0, 8.0, CEIL * 0.5 - 0.45, CEIL * 0.5 + 0.45), false)
			var sp := (randf_range(0.9, 1.4) + k * 0.6) * (1.0 if randf() < 0.5 else -1.0)
			w.move = func(ww: Dictionary, tt: float) -> void:
				var ps: Array = ww.panes
				for i in ps.size():
					var pp: Dictionary = ps[i]
					var a := tt * sp + float(ww.ph) + i * PI * 0.5
					_set_xf(pp, Transform3D(Basis(Vector3(0, 0, 1), a), Vector3(0, CEIL * 0.5, 0)))
	_frame(w)
	if (w.move as Callable).is_valid():
		(w.move as Callable).call(w, t)


## moves a pane of a moving wall, unless it is already broken
func _set_xf(p: Dictionary, xf: Transform3D) -> void:
	if p.alive and is_instance_valid(p.node):
		(p.node as Node3D).transform = xf


## a thin bright frame round the way where a wall stands, so you see it coming
func _frame(w: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var acc: Color = Worlds.def(_world_at(float(w.d))).accent
	Worlds.box(st, Vector3(0, CEIL + 0.1, 0), Vector3(HALF_W * 2 + 0.4, 0.12, 0.12), acc)
	Worlds.box(st, Vector3(-HALF_W - 0.1, CEIL * 0.5, 0), Vector3(0.12, CEIL + 0.3, 0.12), acc)
	Worlds.box(st, Vector3(HALF_W + 0.1, CEIL * 0.5, 0), Vector3(0.12, CEIL + 0.3, 0.12), acc)
	st.set_material(Worlds.glow_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	(w.node as Node3D).add_child(m)


func _crystal_row(d: float) -> void:
	# a few crystals in a line, to fly through; now and then a green one, which mends a shield
	var p := Vector2(randf_range(-X_LIM + 0.5, X_LIM - 0.5), randf_range(Y_MIN + 0.5, Y_MAX - 0.5))
	var dir := Vector2(randf_range(-1, 1), randf_range(-0.5, 0.5)).normalized()
	var green := randf() < 0.22
	for i in 4:
		var q := p + dir * (i - 1.5) * 0.9
		q.x = clampf(q.x, -X_LIM, X_LIM)
		q.y = clampf(q.y, Y_MIN, Y_MAX)
		var n := MeshInstance3D.new()
		n.mesh = crystal_mesh
		var g := green and i == 2
		n.material_override = crystal_mats[1 if g else 0]
		n.position = Vector3(q.x, q.y, -(d + i * 5.0))
		root3d.add_child(n)
		crystals.append({"node": n, "d": d + i * 5.0, "x": q.x, "y": q.y, "shield": g, "alive": true})


func _move_walls() -> void:
	for w in walls:
		var mv: Callable = w.move
		if mv.is_valid() and float(w.d) - dist < AHEAD:
			mv.call(w, t)
	while walls.size() and float(walls[0].d) < dist - 10.0:
		var w: Dictionary = walls.pop_front()
		(w.node as Node3D).queue_free()
	for c in crystals:
		if c.alive:
			(c.node as Node3D).rotate_y(0.05)
	while crystals.size() and float(crystals[0].d) < dist - 6.0:
		var c: Dictionary = crystals.pop_front()
		if is_instance_valid(c.node):
			(c.node as Node3D).queue_free()


## where the ship is, in a pane's own flat coordinates
func _in_pane(p: Dictionary, at: Vector2) -> Vector2:
	var l: Vector3 = (p.node as Node3D).transform.affine_inverse() * Vector3(at.x, at.y, 0)
	return Vector2(l.x, l.y)


func _check_walls(prev: float) -> void:
	for w in walls:
		if w.passed or not (prev < float(w.d) and dist >= float(w.d)):
			continue
		w.passed = true
		var hit := false
		var near := false
		for p in w.panes:
			if not p.alive:
				continue
			var lp := _in_pane(p, ship_pos)
			if Glass.inside(p.poly, lp, SHIP_R):
				if p.thin:
					_shatter(p, w, lp, 1.0)
					smashed += 1
					score += 10
					shake = maxf(shake, 0.15)
					sfx.play("shatter%d" % randi_range(0, 2), -3.0, randf_range(1.0, 1.25))
					vibe(10)
				elif _boosting():
					_shatter(p, w, lp, 1.4)
					score += 25
					shake = maxf(shake, 0.3)
					sfx.play("heavy", 0.0, randf_range(1.0, 1.15))
				else:
					hit = true
					_shatter(p, w, lp, 1.2)
			elif not p.thin and Glass.inside(p.poly, lp, SHIP_R + 0.8):
				near = true
		if hit:
			_crash()
		elif near:
			near_n += 1
			var pts := 25 * mini(near_n, 5)
			score += pts
			fov_kick = maxf(fov_kick, 5.0)
			hud.toast("NEAR MISS  +%d" % pts if near_n < 2 else "NEAR MISS ×%d  +%d" % [near_n, pts])
			sfx.play("throw", -2.0, 1.4)
			vibe(8)
		elif w.panes.size():
			near_n = 0


func _check_crystals(prev: float) -> void:
	for c in crystals:
		if not c.alive or not (prev < float(c.d) + 0.5 and dist >= float(c.d) - 0.5):
			continue
		if Vector2(c.x, c.y).distance_to(ship_pos) > 1.3:
			continue
		c.alive = false
		(c.node as Node3D).visible = false
		var at := Vector3(c.x, c.y, -float(c.d))
		fx.spark(at, Color("5fffb0") if c.shield else Color("bfefff"), 18, 1.4)
		sfx.play("shatter0", -10.0, 1.8)
		score += 15
		if c.shield and shields < SHIELDS:
			shields += 1
			hud.toast("SHIELD +1")
		elif not _boosting():
			charge += 1
			if charge >= BOOST_AT:
				charge = 0
				boost_until = t + BOOST_TIME
				fov_kick = 10.0
				shake = 0.4
				hud.toast("BOOST!")
				sfx.play("heavy", -2.0, 1.4)
				vibe(40)


func _crash() -> void:
	if t < safe_until:
		return
	crashes += 1
	shields -= 1
	near_n = 0
	safe_until = t + 1.2
	speed *= 0.62
	shake = 1.0
	hud.flash(Color("ff3b3b"))
	sfx.play("crash", 0.0, randf_range(0.95, 1.05))
	vibe(90)
	if shields <= 0:
		# the ship breaks up
		ship.visible = false
		var at := ship.global_position
		fx.spark(at, Color("ff9a5a"), 60, 2.4)
		fx.flash(at, Color("ffb070"), 6.0)
		sfx.play("heavy", 0.0, 0.7)
		_game_over()


# ---------- broken glass ----------
func _shatter(p: Dictionary, w: Dictionary, lp: Vector2, force: float) -> void:
	p.alive = false
	var node: MeshInstance3D = p.node
	var xf := node.global_transform
	var cells := Glass.voronoi(p.poly, Glass.seeds_for(p.poly, lp, 12 if p.thin else 9))
	var hit_w: Vector3 = xf * Vector3(lp.x, lp.y, 0)
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := MeshInstance3D.new()
		mi.mesh = Glass.slab_mesh(Glass.moved(cell, -cc), p.kind, 0.6)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3d.add_child(mi)
		mi.global_transform = xf * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		var away: Vector3 = mi.global_position - hit_w
		var near := exp(-away.length() * 0.6)
		# the pieces go on with the ship a little, and burst out from where it struck
		var v := Vector3(0, 0, -speed * (0.35 + 0.4 * near)) + away.normalized() * (2.0 + 6.0 * near) * force + Vector3(0, randf_range(0.5, 2.0), 0)
		shards.append({"node": mi, "v": v, "axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), "w": randf_range(3.0, 10.0), "life": 0.0})
	node.queue_free()
	fx.flash(hit_w, Color("dff6ff"), 2.0)
	fx.spark(hit_w, Color("dff6ff"), 20, 1.6)
	while shards.size() > 180:
		var s: Dictionary = shards.pop_front()
		(s.node as Node3D).queue_free()


func _update_shards(dt: float) -> void:
	var i := shards.size() - 1
	while i >= 0:
		var s: Dictionary = shards[i]
		var n: Node3D = s.node
		var v: Vector3 = s.v
		v.y -= 14.0 * dt
		v *= 1.0 - dt * 0.6
		n.position += v * dt
		n.rotate(s.axis, float(s.w) * dt)
		s.v = v
		s.life = float(s.life) + dt
		if float(s.life) > 2.0 or n.position.z > cam.position.z + 2.0:
			n.queue_free()
			shards.remove_at(i)
		i -= 1


# ---------- a bot that flies, for testing and pictures ----------
func _auto_steer() -> void:
	# the next wall ahead: the point of the way, near where the ship is, that no thick glass will cover then
	var nxt: Dictionary = {}
	for w in walls:
		if not w.passed and float(w.d) > dist:
			nxt = w
			break
	if nxt.is_empty() or float(nxt.d) - dist > 70.0:
		return
	var when := t + (float(nxt.d) - dist) / maxf(speed, 1.0)
	var mv: Callable = nxt.move
	if mv.is_valid():
		mv.call(nxt, when)
	var best := ship_pos
	var best_s := INF
	var y := Y_MIN
	while y <= Y_MAX + 0.01:
		var x := -X_LIM
		while x <= X_LIM + 0.01:
			var q := Vector2(x, y)
			var ok := true
			for p in nxt.panes:
				if p.alive and not p.thin and Glass.inside(p.poly, _in_pane(p, q), SHIP_R + 0.35):
					ok = false
					break
			if ok:
				var s := q.distance_to(ship_pos)
				if s < best_s:
					best_s = s
					best = q
			x += 0.4
		y += 0.4
	if mv.is_valid():
		mv.call(nxt, t)
	target = best


func _end_auto() -> void:
	_ending = true
	print("END d=%d score=%d shields=%d crashes=%d smashed=%d" % [int(dist), score, shields, crashes, smashed])
	get_tree().quit()


func _test_hooks() -> void:
	if not auto:
		return
	log_n += 1
	if log_n % 120 == 0:
		print("d=%d speed=%.1f score=%d shields=%d crashes=%d smashed=%d boost=%s fps=%d" % [int(dist), speed, score, shields, crashes, smashed, _boosting(), Engine.get_frames_per_second()])
	if shots_at.size() and dist >= float(shots_at[0]):
		var d := int(shots_at.pop_front())
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(shot_dir + "rush_%d.png" % d)
	if quit_at > 0.0 and dist >= quit_at and not _ending:
		_end_auto()
