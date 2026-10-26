## Glass Run: you fly through worlds of glass; tap to throw marbles and break the glass before you reach it.
## Running into glass costs ten marbles; jars give three. Coloured glass broken in a row makes a combo;
## a prism breaks all the glass of its colour ahead. Level 01 is made by hand; the endless run and the calm
## mode are made as you go.
class_name Game
extends Node3D

const EYE := 2.2
const ROOM_LEN := 200.0
const START_BALLS := 30
const SEG := Worlds.SEG
const HALF_W := Worlds.HALF_W
const CEIL := Worlds.CEIL
# a heavy steel ball: slower off the hand than before, dropping in a firmer curve
const BALL_SPEED := 38.0
const GRAV := 13.0
const BALL_R := 0.21

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
var look_fast_until := 0.0

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
var save := {"best": 0, "cp": 0, "l1_done": false, "l1_stars": 0, "l1_score": 0, "sound": true, "music": true, "vibe": true, "quality": 1, "fps60": true}

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
var roll := 0.0
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
var crystal_mesh: ArrayMesh
var jar_mat: StandardMaterial3D
var hub_mat: StandardMaterial3D
var prism_mesh: ArrayMesh
var prism_mats: Array = []
var steel_mat: StandardMaterial3D
var glow_tex: Texture2D
var crack_tex: Texture2D
var crack_mat: StandardMaterial3D
var mark_mat: StandardMaterial3D
var pow_mats: Array = []
var berg_mat: StandardMaterial3D
var chand_mat: StandardMaterial3D
var column_mesh: ArrayMesh

# crystals of power: [colour, seconds]
const POW := {"slow": [Color("ffd36b"), 5.0], "burst": [Color("63e6a0"), 8.0], "iron": [Color("ff7a3d"), 7.0]}
const POW_LIST := ["slow", "burst", "iron"]
var power := ""
var power_until := 0.0

# things that happen round you as you go: pillars rising, roofs opening, chandeliers falling, crystal mountains
var risers: Array = []
var roofs: Array = []
var chandeliers: Array = []
var floaters: Array = []

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

# making shorts (see shorts/README.md): the bot plays in a tall window while Godot's Movie Maker records it,
# and every moment worth cutting to is written down, one line each, for the editor
var shorts := false
var shorts_fps := 30.0
var bot := "perfect"
var bot_balls := -1
var pow_rate := 0.2
var run_seed := -1
var hud_balls := false
var fov_add := 17.0
var quit_on := ""
var quit_after := 3.0
var max_time := 0.0
var fail_after := 0.0
var ev_file: FileAccess
var ev_f0 := -1
var quit_frame := -1


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
		elif a == "--shorts":
			shorts = true
		elif a.begins_with("--bot="):
			bot = a.substr(6)
		elif a.begins_with("--balls="):
			bot_balls = int(a.substr(8))
		elif a.begins_with("--pow="):
			pow_rate = float(a.substr(6))
		elif a.begins_with("--seed="):
			run_seed = int(a.substr(7))
		elif a == "--hud=balls":
			hud_balls = true
		elif a.begins_with("--fov="):
			fov_add = float(a.substr(6))
		elif a.begins_with("--quit-on="):
			quit_on = a.substr(10)
		elif a.begins_with("--quit-after="):
			quit_after = float(a.substr(13))
		elif a.begins_with("--max-time="):
			max_time = float(a.substr(11))
		elif a.begins_with("--fail-after="):
			fail_after = float(a.substr(13))
		elif a.begins_with("--fps="):
			shorts_fps = float(a.substr(6))
		elif a.begins_with("--events="):
			ev_file = FileAccess.open(a.substr(9), FileAccess.WRITE)
	_load()
	cp_room = int(save.cp)
	Glass.mats()
	Worlds.mats()
	_make_scene()
	sfx = Sfx.new()
	sfx.shorts = shorts
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
	hud.start_from.connect(func(r: int): _start("endless", r))
	_apply_quality()
	_reset("menu")
	hud.show_menu(save)
	sfx.play_music("menu")
	_warm_up()
	if auto:
		if shorts:
			_shorts_start()
		else:
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
	if key == "reset":
		save.best = 0
		save.cp = 0
		save.l1_done = false
		save.l1_stars = 0
		save.l1_score = 0
		cp_room = 0
		_save()
		return
	save[key] = value
	match key:
		"sound":
			sfx.sound_on = value
		"music":
			sfx.set_music(value)
		"quality", "fps60":
			_apply_quality()
	_save()


func _apply_quality() -> void:
	var q: int = save.quality
	get_viewport().msaa_3d = Viewport.MSAA_2X if q > 0 else Viewport.MSAA_DISABLED
	# a phone draws the 3D a little under its screen's resolution (glass over glass costs a lot of pixels);
	# the words and buttons stay sharp. Smooth draws fewer still.
	if OS.has_feature("mobile"):
		get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		get_viewport().scaling_3d_scale = 0.85 if q > 0 else 0.7
	# 30 frames a second keeps a phone cooler (and so steadier) over a long run
	Engine.max_fps = 60 if save.fps60 else 30
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
	fx.setup(cam, glow_tex)
	# marbles: little balls of coloured glass
	marble_mesh = SphereMesh.new()
	marble_mesh.radius = BALL_R
	marble_mesh.height = BALL_R * 2.0
	marble_mesh.radial_segments = 20
	marble_mesh.rings = 10
	# a ball of polished iron: the bright sky and dark ground of a chrome sphere are painted on, so it shines anywhere
	var chrome := _chrome_texture()
	var im := StandardMaterial3D.new()
	im.albedo_texture = chrome
	im.metallic = 0.55
	im.roughness = 0.22
	im.metallic_specular = 1.0
	im.emission_enabled = true
	im.emission_texture = chrome
	im.emission = Color(0.55, 0.58, 0.62)
	im.emission_energy_multiplier = 0.45
	im.rim_enabled = true
	im.rim = 0.6
	im.rim_tint = 0.1
	marble_mats.append(im)
	# the ball of hot iron
	var hot := im.duplicate() as StandardMaterial3D
	hot.emission_texture = null
	hot.emission = Color("ff6a1f")
	hot.emission_energy_multiplier = 2.2
	hot.albedo_color = Color("ffb27a")
	marble_mats.append(hot)
	for k in POW_LIST:
		var pm := StandardMaterial3D.new()
		var pc: Color = POW[k][0]
		pm.albedo_color = Color(pc.r, pc.g, pc.b, 0.85)
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pm.cull_mode = BaseMaterial3D.CULL_DISABLED
		pm.roughness = 0.05
		pm.emission_enabled = true
		pm.emission = pc
		pm.emission_energy_multiplier = 1.8
		pow_mats.append(pm)
	# a jar of marbles
	crystal_mesh = _crystal_shape()
	column_mesh = _column_shape()
	berg_mat = StandardMaterial3D.new()
	berg_mat.albedo_color = Color(0.62, 0.84, 0.95, 0.55)
	berg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	berg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	berg_mat.roughness = 0.08
	berg_mat.metallic = 0.3
	berg_mat.emission_enabled = true
	berg_mat.emission = Color("7fd0ff")
	berg_mat.emission_energy_multiplier = 0.7
	berg_mat.rim_enabled = true
	berg_mat.rim = 0.8
	chand_mat = berg_mat.duplicate() as StandardMaterial3D
	chand_mat.albedo_color = Color(0.92, 0.96, 1.0, 0.75)
	chand_mat.emission = Color("fff0d8")
	chand_mat.emission_energy_multiplier = 1.1
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.26
	cyl.bottom_radius = 0.3
	cyl.height = 0.62
	cyl.radial_segments = 14
	jar_mesh = cyl
	jar_mat = StandardMaterial3D.new()
	jar_mat.albedo_color = Color(0.45, 0.78, 1.0, 0.82)
	jar_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	jar_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jar_mat.roughness = 0.05
	jar_mat.metallic = 0.2
	jar_mat.emission_enabled = true
	jar_mat.emission = Color("6fc8ff")
	jar_mat.emission_energy_multiplier = 1.4
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
	frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color("c9d1d8")
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.35


## every look in the game drawn once as it starts, far off behind the sky where it cannot be seen, with and without a
## flash of light by it: the graphics driver makes each shader now, not the first time that glass, crystal or spark
## turns up in a run (on a phone, that first time is a stutter)
func _warm_up() -> void:
	var at := Node3D.new()
	cam.add_child(at)
	at.position = Vector3(0, 0, -235.0)
	var sq := Glass.rect(-0.5, 0.5, -0.5, 0.5)
	var meshes := [Glass.slab_mesh(sq, "thin"), Glass.slab_mesh(sq, "mirror"), Glass.slab_mesh(sq, "thin", 1.0, 0),
		crystal_mesh, prism_mesh, column_mesh, jar_mesh, marble_mesh]
	var mats := [Worlds.lit_mat, Worlds.glow_mat, Worlds.shaft_mat, Worlds.tex_like("cathedral"), Worlds.tex_like("sheesh"),
		Worlds.tex_like("shoji"), shadow_mat, berg_mat, chand_mat, jar_mat, hub_mat, steel_mat, crack_mat, mark_mat, frame_mat,
		fx.line_node.material_override]
	mats.append_array(marble_mats)
	mats.append_array(pow_mats)
	mats.append_array(prism_mats)
	var box := BoxMesh.new()
	var i := 0
	for m in meshes + mats:
		var mi := MeshInstance3D.new()
		if m is Mesh:
			mi.mesh = m
		else:
			mi.mesh = box
			mi.material_override = m
		mi.position = Vector3((i % 6) * 1.2 - 3.0, floorf(i / 6.0) * 1.2 - 3.0, 0)
		at.add_child(mi)
		i += 1
	var p := at.global_position
	fx.flash(p, Color.WHITE, 0.4)
	fx.spark(p, Color.WHITE, 6, 0.1)
	fx.crumble(p, Basis(), Vector2(0.5, 0.5), Color.WHITE, Vector3(0, 0, -1))
	for k in 14:
		await get_tree().process_frame
	at.queue_free()


## the look of polished iron on a sphere: light above, a dark band at the horizon, grey below
func _chrome_texture() -> Texture2D:
	var img := Image.create(8, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		var v := float(y) / 63.0
		var c: float
		if v < 0.42:
			c = lerpf(0.98, 0.62, v / 0.42)
		elif v < 0.52:
			c = lerpf(0.62, 0.16, (v - 0.42) / 0.1)
		else:
			c = lerpf(0.3, 0.46, (v - 0.52) / 0.48)
		for x in 8:
			img.set_pixel(x, y, Color(c * 0.96, c * 0.98, c, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


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


## a crystal to shoot: two pyramids, point to point
func _crystal_shape() -> ArrayMesh:
	# a tall four-sided pyramid of blue glass, standing on its base
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.36
	var tip := Vector3(0, 0.75, 0)
	var y0 := -0.45
	var ring := []
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		ring.append(Vector3(cos(a) * r, y0, sin(a) * r))
	for i in 4:
		var p0: Vector3 = ring[i]
		var p1: Vector3 = ring[(i + 1) % 4]
		var nrm := (p1 - p0).cross(tip - p0).normalized()
		if nrm.dot(p0 + p1 + tip - Vector3(0, y0 * 3.0, 0)) < 0.0:
			nrm = -nrm
		st.set_normal(nrm)
		st.add_vertex(p0)
		st.add_vertex(tip)
		st.add_vertex(p1)
	st.set_normal(Vector3.DOWN)
	st.add_vertex(ring[0])
	st.add_vertex(ring[1])
	st.add_vertex(ring[2])
	st.add_vertex(ring[0])
	st.add_vertex(ring[2])
	st.add_vertex(ring[3])
	return st.commit()


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
	_ev("over")
	if shorts:
		# the video ends on the glass, not on a panel
		return
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
	_ev("done")
	if shorts:
		return
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
	_sec_cache.clear()
	_seg_jobs_clear()
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
	risers.clear()
	solids.clear()
	roofs.clear()
	chandeliers.clear()
	floaters.clear()
	power = ""
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
		if run_seed >= 0:
			seed(run_seed)
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
	if mode == "menu":
		# the title screen runs through a bright room open to the sky
		return 7
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
			_ev("world", {"world": w, "name": Worlds.def(w).name})


func _apply_look(backdrop := true) -> void:
	var k: float = look_now.sky
	var bg: Color = look_now.bg
	var hor: Color = bg.lerp(look_now.sky_hor, k)
	env.background_color = hor
	env.fog_light_color = hor
	env.ambient_light_color = look_now.amb
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_density = 1.0
	env.fog_depth_begin = lerpf(12.0, 30.0, k)
	env.fog_depth_end = lerpf(52.0 - look_now.fog * 300.0, 120.0, k)
	env.fog_depth_curve = 1.4
	if backdrop:
		_draw_backdrop(k, bg, hor)
	sun.light_color = look_now.sun
	sun.light_energy = look_now.sun_e
	Glass.rim_mat.albedo_color = look_now.rim
	Worlds.set_tint(look_now.tint, look_now.gtint)
	# glass edges dark against a bright room, bright against a dark one
	Glass.rim_mat.albedo_color = Color("eef6f4") if hor.get_luminance() < 0.4 else Color("1c4a50")


## the far wall of sky colour, with the world's skyline on it (many little shapes: drawn only when asked)
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


var _look_n := 0


func _look_step(dt: float) -> void:
	var k := 1.0 - exp(-dt * (4.0 if t < look_fast_until else 1.2))
	var changed := false
	var moving := false
	for key in look_to.keys():
		var a = look_now[key]
		var b = look_to[key]
		if a is Color:
			if a != b:
				changed = true
				var c: Color = a.lerp(b, k)
				# near enough is there: the look stops changing (and being redrawn) instead of creeping on for seconds
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
		# the light and fog every frame; the far backdrop a few times a second while the look moves, and when it arrives
		_look_n += 1
		_apply_look(not moving or _look_n % 4 == 0)


func _stream() -> void:
	# the walls, floor and dressing of the next few pieces of the way are shaped early on worker threads
	# (only arrays of vertices: Worlds.shapes), so a frame only has to turn a finished one into a mesh
	var k := next_seg
	while k * SEG < dist + 150.0 + SEG * SEG_AHEAD:
		if not seg_jobs.has(k):
			_seg_job(k)
		k += 1
	while next_seg * SEG < dist + 150.0:
		var d0 := next_seg * SEG
		var sec := section_at(d0 + 1.0)
		var seg := _seg_take(next_seg)
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


const SEG_AHEAD := 3
var seg_jobs := {}   # piece number -> {"task": worker task, "out": [its shapes]}


## what worlds.gd needs to build piece k of the way (worked out here, on the main thread)
func _seg_args(k: int) -> Array:
	var d0 := k * SEG
	var sec := section_at(d0 + 1.0)
	var prev := section_at(d0 - 1.0) if d0 >= SEG else "corridor"
	return [_world_at(d0 + 1.0), d0, k * 7919 + 13, sec, prev, _mood_at(d0 + 2.0), not _roof_opens(d0 + 1.0)]


func _seg_job(k: int) -> void:
	var a := _seg_args(k)
	var out := []
	var task := WorkerThreadPool.add_task(func(): out.append(Worlds.shapes(a[0], a[1], a[2], a[3], a[4], a[5], a[6])), true)
	seg_jobs[k] = {"task": task, "out": out}


## piece k, ready: shaped ahead if it was asked for in time (it nearly always is), or shaped now
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


## the same for every point of one 16 m piece (asked many times a frame, for every ball and piece of glass,
## so each piece's answer is kept until the next run)
var _sec_cache := {}


func section_at(d: float) -> String:
	var i := floori(d / SEG)
	var s = _sec_cache.get(i)
	if s == null:
		s = _sec_raw(i * SEG + SEG * 0.5)
		_sec_cache[i] = s
	return s


## glass that is only there to be broken: on islands below the sky, on racks at the sides of a hall
func _extras(d0: float, sec: String) -> void:
	if mode == "menu" or mode == "gallery" or d0 < 1.0:
		return
	if sec == "sky":
		if randf() < 0.45:
			_island(d0 + randf_range(3.0, 13.0))
	elif sec == "hall":
		if randf() < 0.45:
			_side_bonus(d0 + randf_range(2.0, 14.0), -1.0 if randf() < 0.5 else 1.0)
	_spectacle(d0, sec)


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
	# a crystal on the island, to hit from above
	var tg := target("jar", Vector3(x + randf_range(-1.0, 1.0), y + 0.9, -d), 0.7)
	tg.on_hit = func(): _jar_got(tg)


## at the side of a great hall: a crystal on a tall stand, to aim at
func _side_bonus(d: float, sd: float) -> void:
	var g := new_gate("bonus", d)
	var x := sd * randf_range(6.0, 10.5)
	var y := randf_range(1.6, 4.2)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Worlds.box(st, Vector3(0, (y - 0.5) * 0.5, 0), Vector3(0.16, y - 0.5, 0.16), Color("4a525c"))
	Worlds.box(st, Vector3(0, 0.08, 0), Vector3(0.9, 0.16, 0.9), Color("39424c"))
	st.set_material(Worlds.lit_mat)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	m.position = Vector3(x, 0, -d)
	decor(g, m)
	var tg := target("jar", Vector3(x, y, -d), 0.6)
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
	if dd >= a and dd < b and mode == "endless" and Rooms.has_door(r):
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
		if sec != "sky" and randf() < 0.35:
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
	# all glass is the one colour of glass
	color_id = -1
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
	p.pivot = pivot
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
			# a crystal: hit it for balls
			m.mesh = crystal_mesh
			m.material_override = jar_mat
		"power":
			m.mesh = crystal_mesh
			m.material_override = pow_mats[color_id]
			m.scale = Vector3(1.25, 1.35, 1.25)
			glow_col = POW[POW_LIST[color_id]][0]
			glow_col.a = 0.85
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
	if kind == "prism" or kind == "power":
		tg.spin = 0.9
	elif kind == "hub" or kind == "button":
		tg.spin = 0.0
	targets.append(tg)
	return tg


func _jars(d: float) -> void:
	# crystals stand on stands at the side of the way (in the open sky the islands carry them)
	if section_at(d) == "sky":
		return
	var g := new_gate("crystal", d)
	# two, one each side (one ball breaks one glass, so there are more crystals than there were)
	var n := 2 if randf() < 0.85 else 1
	var sd := -1.0 if randf() < 0.5 else 1.0
	for i in n:
		var side := sd if i == 0 else -sd
		var x := side * randf_range(2.6, HALF_W - 1.6)
		var h := randf_range(0.5, 1.6)
		var dz := d + i * 2.0
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Worlds.box(st, Vector3(0, h * 0.5, 0), Vector3(1.1, h, 1.1), Color("b8c0c8"))
		Worlds.box(st, Vector3(0, h + 0.03, 0), Vector3(1.2, 0.06, 1.2), Color("dfe5ea"))
		st.set_material(Worlds.lit_mat)
		var m := MeshInstance3D.new()
		m.mesh = st.commit()
		m.position = Vector3(x, 0, -dz)
		decor(g, m)
		# now and then a crystal of power instead: slow time, three balls a throw, or a ball of hot iron
		if i == 0 and mode == "endless" and _room_of(d) >= 1 and randf() < pow_rate:
			var pk: String = POW_LIST[randi() % POW_LIST.size()]
			var pt := target("power", Vector3(x, h + 0.65, -dz), 0.7, null, POW_LIST.find(pk))
			pt.on_hit = func(): _power_got(pk)
			continue
		var tg := target("jar", Vector3(x, h + 0.5, -dz), 0.6)
		jars_seen += 1
		tg.spin = 0.0
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
	add_solid(m, Vector3.ZERO, Vector3(0.09, CEIL * 0.5, 0.09))


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
	add_solid(m, Vector3(0, 2.2, 0), Vector3(2.45, 1.85, 0.06), g)
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
	if shorts:
		_shorts_step()
	var dt := minf(delta, 1.0 / 20.0)
	if _ms() < hitstop_until:
		dt *= 0.08
	if t < slow_until:
		dt *= 0.35
	elif power == "slow" and t < power_until:
		dt *= 0.55
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
		_spectacle_step(dt)
		fx.step(dt, flying)
		_look_step(dt)
		return
	t += dt
	if power != "" and t >= power_until:
		power = ""
	if power != "":
		hud.set_power(power, clampf((power_until - t) / float(POW[power][1]), 0.0, 1.0), POW[power][0])
	else:
		hud.set_power("", 0.0, Color.WHITE)
	var want := 7.0 + minf(_room_of(dist), 10) * 0.45
	if mode == "endless":
		# a wave in every room: slow just past the door, faster and faster towards the next one
		var rn := _room_of(dist + 6.0)
		var c0 := (rn / Rooms.CP_EVERY) * Rooms.CP_EVERY
		var base := 6.0 + minf(rn % Rooms.COUNT, 49) * 0.07 + minf(rn / Rooms.COUNT, 3) * 1.0
		var f := clampf((dist + 6.0 - c0 * ROOM_LEN) / (ROOM_LEN * Rooms.CP_EVERY - 30.0), 0.0, 1.0)
		want = base + 5.5 * f * f * (3.0 - 2.0 * f)
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
	_spectacle_step(dt)
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
		if Rooms.spins(room):
			small += "  ·  THE ROOM TURNS"
		_ev("room", {"room": room, "spins": Rooms.spins(room)})
		var L: Dictionary = Worlds.look(Rooms.world_of(room), k % Rooms.PER_WORLD)
		hud.show_title(L.name, small, (L.sun as Color).lerp(Color.WHITE, 0.3))
	var sn := section_at(dist + 2.0)
	if sn != sec_now:
		sec_now = sn
		_ev("section", {"sec": sn})
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
	# progress to the next ball per throw: ten crystals in a row for two, twenty-five for three
	var streak := 1.0
	if multi == 1:
		streak = jar_streak / 10.0
	elif multi == 2:
		streak = (jar_streak - 10) / 15.0
	hud.set_balls(balls, multi, mode == "calm", streak)
	sfx.set_tension(0.0 if mode == "calm" else clampf((10.0 - balls) / 10.0, 0.0, 1.0))
	var prog := 0.0
	if mode == "level1":
		prog = dist / Levels.L1_LEN
	elif mode == "endless":
		var span := ROOM_LEN * Rooms.CP_EVERY
		prog = fmod(dist + 6.0, span) / span
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
	var sa := section_at(dist + 12.0)
	look_to["sky"] = 1.0 if sa == "sky" else (0.85 if sa == "corridor" and _mood_at(dist + 12.0) in Worlds.OPEN else (0.7 if sa == "hall" and _roof_opens(dist + 12.0) else 0.0))
	if dt <= 0.0 and not look_now.is_empty():
		look_now["sky"] = look_to["sky"]
		_apply_look()
	# in some rooms the whole room turns about you: right round in a tunnel, rocking elsewhere
	if mode == "endless" and Rooms.spins(_room_of(dist)) and state == S.PLAY:
		if section_at(dist) == "tunnel":
			roll += dt * 0.5
		else:
			roll = lerp_angle(roll, sin(t * 0.55) * 0.26, 1.0 - exp(-dt * 2.0))
	else:
		roll = lerp_angle(roll, 0.0, 1.0 - exp(-dt * 1.5))
	cam.rotation = Vector3(deg_to_rad(cam_pitch), sin(dist * 0.05) * 0.015, sin(dist * 0.07) * 0.012 + off.x * 0.1 + roll)
	cam.fov = 62.0 + clampf((speed - 9.0) * 0.8, 0.0, 6.0) + fov_kick
	if shorts:
		# a tall picture (the angle is top to bottom): about 80 degrees, so the way is not squeezed at the sides
		# and nothing near the top or bottom edge is pulled long
		cam.fov += fov_add


func _move_gates() -> void:
	for g in gates:
		var ahead: float = g.d - dist
		if ahead < -6.0 or ahead > 160.0:
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
	return lp if Glass.inside(p.poly, lp, 0.12) else Vector2.INF


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
		if g.door:
			_checkpoint(g)


func _crash(hit: Array, g: GGate) -> void:
	if auto:
		for h in hit:
			print("CRASH gate=%s d=%.0f kind=%s area=%.2f lp=%s cam=%.2f" % [g.kind, g.d, h[0].kind, absf(Glass.area(h[0].poly)), str(h[1]), cam.position.x])
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
	_ev("crash")
	jar_streak = 0
	multi = 1
	combo_n = 0
	combo_color = -1
	shake = 1.0
	hud.flash_screen(Color("ff3b3b"), 0.35, 0.5)
	hud.crack_screen()
	sfx.play("crash", 0.0, randf_range(0.95, 1.05))
	vibe(90)


func _checkpoint(g: GGate) -> void:
	look_fast_until = t + 3.5
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
		# no help needed: still lift the throw for the drop, so the heavy ball lands where you tapped
		var reach := clampf(on_glass if on_glass < INF else 20.0, 3.0, 40.0)
		best_pt = o + dir * (reach / maxf(0.2, -dir.z))
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
	var n_balls := 3 if power == "burst" else multi
	_ev("throw", {"n": n_balls})
	for i in n_balls:
		var d2 := dir
		if i > 0:
			d2 = dir.rotated(Vector3.UP, (0.035 if i == 1 else -0.035))
		var mi := MeshInstance3D.new()
		mi.mesh = marble_mesh
		mi.material_override = marble_mats[1] if power == "iron" else marble_mats[0]
		mi.position = from
		root3d.add_child(mi)
		flying.append({"node": mi, "v": d2 * (BALL_SPEED + speed), "life": 0.0, "pts": [from], "col": Color(0.78, 0.82, 0.88), "shot": shot, "landed": false, "spent": false, "walls": 0})
	# you feel the weight leave your hand
	fov_kick = maxf(fov_kick, 0.6)
	shake = maxf(shake, 0.06)
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
		# one ball, one glass: the first pane this step crosses (nearest first) takes the ball.
		# A pane that breaks stops it where it struck, and it drops through the hole; a pane that holds
		# knocks it back. Either way the ball is spent and can never touch glass again, so it cannot
		# go on to break the next pane behind.
		if not b.spent:
			var best: GPane = null
			var best_s := 2.0
			var best_lp := Vector2.ZERO
			var shot: Dictionary = b.shot
			for p in panes:
				if not p.alive or p.opened:
					continue
				# the balls of one throw (two or three at once) strike one wall of glass together, never the next one behind
				if shot.has("d") and absf(p.gate.d - float(shot.d)) > 1.0:
					continue
				var xf: Transform3D = p.node.global_transform
				var pz := xf.origin.z
				if absf(pz - a.z) > 4.5 and absf(pz - nb.z) > 4.5:
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
				if not Glass.inside(p.poly, Vector2(lh.x, lh.y), BALL_R * 0.6):
					continue
				best = p
				best_s = s
				best_lp = Vector2(lh.x, lh.y)
			if best == null and shot.has("d") and -nb.z > float(shot.d) + 1.0:
				# a ball of the same throw that went through the hole its brother made: it is spent too
				b.spent = true
			if best != null:
				_count_hit(b)
				b.spent = true
				if not shot.has("d"):
					shot.d = best.gate.d
				var hit_at := a.lerp(nb, best_s)
				var nrm: Vector3 = best.node.global_transform.basis.z.normalized()
				if nrm.dot(a - hit_at) < 0.0:
					nrm = -nrm
				var vin := v.length()
				var thick: float = Glass.KINDS[best.kind].t
				var res := _hit(best, best_lp, v.normalized(), b)
				if res == "break" or res == "open":
					# it spends itself on the glass: a little way on through the hole, then it falls
					v = v.normalized() * minf(vin, 1.6) + Vector3(0, -0.5, 0)
					nb = hit_at + v.normalized() * 0.03
					shake = maxf(shake, 0.06 + minf(thick, 1.0) * 0.18)
				elif res == "reflect":
					# a mirror throws it back the way it came
					v = (v - 2.0 * v.dot(nrm) * nrm) * 0.45
					nb = hit_at + nrm * 0.06
				else:
					# it holds: a dull knock, the ball bounces back a little off it and drops
					v = nrm * minf(vin * 0.1, 3.5) + Vector3(randf_range(-0.4, 0.4), -0.5, 0)
					nb = hit_at + nrm * 0.06
					shake = maxf(shake, 0.1)
					sfx.play("thud", -6.0, randf_range(0.8, 0.95))
		# solid things that are not glass (a steel grille, posts, pillars): it strikes them and glances off
		var solid_hit := _hit_solid(a, nb, v)
		if not solid_hit.is_empty():
			nb = solid_hit.at
			v = solid_hit.v
		# round things to shoot
		for tg in targets:
			if not tg.alive or b.spent:
				continue
			if _seg_dist(a, nb, tg.node.global_position) < tg.radius + BALL_R * 0.5:
				_count_hit(b)
				tg.alive = false
				if tg.on_hit.is_valid():
					tg.on_hit.call()
				_target_burst(tg)
		var bsec := section_at(-nb.z)
		if nb.y < BALL_R and bsec != "sky":
			# iron does not bounce: it lands with a thud and rolls on
			nb.y = BALL_R
			if not b.landed and v.y < -1.0:
				b.landed = true
				sfx.play("roll", -14.0, randf_range(0.9, 1.1))
			v.y = absf(v.y) * 0.06
			v.x *= 0.92
			v.z *= 0.97
		var lim := INF if bsec == "sky" else (Worlds.HALL_W - 0.1 if bsec == "hall" else HALF_W) - BALL_R
		if absf(nb.x) > lim:
			# the side wall: a heavy glancing knock, not a bounce like rubber
			nb.x = signf(nb.x) * lim
			var vx := absf(v.x)
			v.x = -v.x * 0.3
			v.z *= 0.82
			if vx > 2.0 and b.walls < 2:
				b.walls += 1
				var wp := Vector3(signf(nb.x) * (lim + BALL_R), nb.y, nb.z)
				fx.spark(wp, Color("d8dde2"), 8, 0.6)
				if -nb.z - dist < 22.0:
					shake = maxf(shake, 0.05)
					sfx.play("thud", -12.0 + minf(vx, 8.0), randf_range(1.0, 1.2))
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


func _seg_dist2(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 1e-8:
		return a.distance_to(p)
	return (a + ab * clampf((p - a).dot(ab) / l, 0.0, 1.0)).distance_to(p)


func _seg_dist(a: Vector3, b: Vector3, p: Vector3) -> float:
	var ab := b - a
	var l := ab.length_squared()
	if l < 1e-8:
		return a.distance_to(p)
	var s := clampf((p - a).dot(ab) / l, 0.0, 1.0)
	return (a + ab * s).distance_to(p)


# ---------- glass being hit ----------
## solid things the ball can strike (not glass): each a box, kept by its node so it moves with it
var solids: Array = []
var hit_calls := 0
var jars_got := 0
var jars_seen := 0


func add_solid(n: Node3D, center: Vector3, half: Vector3, g: GGate = null) -> void:
	solids.append({"node": n, "c": center, "h": half, "gate": g})


## the ball's step from a to b against every solid box (made bigger by the ball's size): where it strikes and how it glances off
func _hit_solid(a: Vector3, b: Vector3, v: Vector3) -> Dictionary:
	var best_t := 2.0
	var best_n := Vector3.ZERO
	var i := solids.size() - 1
	while i >= 0:
		var so: Dictionary = solids[i]
		if not is_instance_valid(so.node):
			solids.remove_at(i)
			i -= 1
			continue
		i -= 1
		var g = so.gate
		if g != null and g.grille_open:
			continue
		var n: Node3D = so.node
		var c: Vector3 = n.global_position + (so.c as Vector3)
		var h: Vector3 = (so.h as Vector3) + Vector3.ONE * BALL_R
		if absf(c.z - a.z) > h.z + 6.0:
			continue
		# slab test of the segment against the box
		var t0 := 0.0
		var t1 := 1.0
		var nrm := Vector3.ZERO
		var d := b - a
		var ok := true
		for ax in 3:
			var lo := c[ax] - h[ax]
			var hi := c[ax] + h[ax]
			if absf(d[ax]) < 1e-6:
				if a[ax] < lo or a[ax] > hi:
					ok = false
					break
				continue
			var ta := (lo - a[ax]) / d[ax]
			var tb := (hi - a[ax]) / d[ax]
			var face := -1.0
			if ta > tb:
				var tmp := ta
				ta = tb
				tb = tmp
				face = 1.0
			if ta > t0:
				t0 = ta
				nrm = Vector3.ZERO
				nrm[ax] = face
			t1 = minf(t1, tb)
			if t0 > t1:
				ok = false
				break
		if not ok or nrm == Vector3.ZERO or t0 >= best_t:
			continue
		best_t = t0
		best_n = nrm
	if best_t > 1.0:
		return {}
	var at := a.lerp(b, best_t) + best_n * 0.02
	# steel on steel: most of the speed into the face is lost, some along it kept
	var vn := v.dot(best_n)
	var nv := (v - best_n * vn) * 0.5 - best_n * minf(absf(vn) * 0.15, 3.0) * signf(vn)
	fx.spark(at - best_n * BALL_R, Color("ffe2b0"), 12, 0.8)
	if -at.z - dist < 30.0:
		shake = maxf(shake, 0.08)
		sfx.play("thud", -4.0, randf_range(1.15, 1.3))
	return {"at": at, "v": nv}


## a ball hits a pane: "break", "open", "reflect" or "hold"
func _hit(p: GPane, lp: Vector2, dir: Vector3, _b: Dictionary) -> String:
	hit_calls += 1
	var hit_w: Vector3 = p.node.global_transform * Vector3(lp.x, lp.y, 0)
	fx.spark(hit_w, Glass.look(p.kind, p.color_id)[2], 16)
	# a ball of hot iron: any glass goes at one hit
	if power == "iron" and p.kind != "mirror":
		break_pane(p, lp, dir)
		return "break"
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
	_ev("break", {"kind": p.kind, "area": snappedf(absf(Glass.area(p.poly)), 0.1), "crash": crash, "door": p.gate.door, "bonus": p.bonus > 0, "quiet": quiet})
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
	if p.gate.door:
		count = 40 if save.quality > 0 else 26
	if p.kind == "tempered":
		var bb := Glass.bounds(p.poly)
		fx.crumble(xf * Vector3(bb.get_center().x, bb.get_center().y, 0), xf.basis, bb.size * 0.5, L[0], dir)
		count = 5
	# a big pane that stands still breaks only where it was hit: a hole, cracks round it, the rest stays
	var hole: bool = not crash and area > 6.0 and not p.gate.door and not p.move.is_valid() and not p.on_break.is_valid() and p.supports.is_empty() \
		and not (p.kind in ["tempered", "laminated", "blast", "mirror", "frosted"]) and p.charge < 0.0
	if hole:
		count = clampi(int(10 + area * 2.2), 12, 34)
	var cells := Glass.voronoi(p.poly, Glass.seeds_for(p.poly, lp, count))
	var keep := []
	if hole:
		var R := 1.5
		var kept_area := 0.0
		var gone := []
		for cell in cells:
			var cc := Glass.centroid(cell)
			# a piece goes if any of it is near the hit, so the hole is clear right round where the ball went
			var near_d := INF
			for k in cell.size():
				near_d = minf(near_d, _seg_dist2(cell[k], cell[(k + 1) % cell.size()], lp))
			if cc.distance_to(lp) < R or near_d < 1.05 or Glass.inside(cell, lp):
				gone.append(cell)
			else:
				keep.append(cell)
				kept_area += absf(Glass.area(cell))
		if kept_area < area * 0.25:
			keep = []
		else:
			cells = gone
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := _mesh_shard(Glass.moved(cell, -cc), p.kind, p.color_id)
		mi.global_transform = xf * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		# pieces near where the ball struck fly with it, fast; pieces further off fall away slower;
		# big heavy pieces move less than small ones
		var away: Vector3 = mi.global_transform.origin - hit_w
		var r := away.length()
		var near := exp(-r * 0.9)
		var mass := clampf(0.5 + absf(Glass.area(cell)) * 0.9 + K.t * 1.2, 0.5, 3.0)
		var v := (dir * (2.0 + 9.0 * near) + away.normalized() * (1.0 + 3.5 * near) + Vector3(0, randf_range(0.2, 1.6), 0)) / mass
		v += Vector3(randf_range(-0.5, 0.5), randf_range(-0.3, 0.3), randf_range(-0.5, 0.5))
		if crash:
			v = away.normalized() * randf_range(2.0, 5.0) / mass + Vector3(0, randf_range(1.0, 3.0), -speed * 0.6)
		elif p.gate.door:
			# the whole wall bursts away from you, wide
			v = Vector3(away.x * 1.6, away.y * 1.2 + randf_range(0.5, 2.5), 0) + dir * randf_range(6.0, 14.0)
		var axis := Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		shards.append({"node": mi, "v": v, "axis": axis, "w": randf_range(3.0, 12.0) / mass, "life": 0.0, "mass": mass, "rest": false})
	# what is left of the pane stays where it was, cracked: each piece now breaks at one hit
	for cell in keep:
		var cc: Vector2 = Glass.centroid(cell)
		var local := Glass.ccw(Glass.moved(cell, -cc))
		var mi := MeshInstance3D.new()
		mi.mesh = Glass.slab_mesh(local, p.kind, 0.15, p.color_id)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root3d.add_child(mi)
		mi.transform = p.node.transform * Transform3D(Basis(), Vector3(cc.x, cc.y, 0))
		var q := GPane.new()
		q.node = mi
		q.poly = local
		q.kind = p.kind
		q.color_id = p.color_id
		q.hp = 1
		q.blocks = p.blocks
		q.base = mi.transform
		q.gate = p.gate
		q.bonus = p.bonus
		p.gate.panes.append(q)
		panes.append(q)
		# the crack running into it from the hole
		if cc.distance_to(lp) < 1.9 and randf() < 0.45:
			var cq := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(1.1, 1.1)
			cq.mesh = qm
			cq.material_override = crack_mat
			var toward := (lp - cc)
			cq.position = Vector3(toward.x * 0.35, toward.y * 0.35, Glass.KINDS[p.kind].t * 0.5 + 0.01)
			cq.rotation.z = randf() * TAU
			mi.add_child(cq)
	p.node.queue_free()
	var cap := 260 if save.quality > 0 else 120
	while shards.size() > cap:
		var s: Dictionary = shards.pop_front()
		_free_shard(s.node)
	fx.flash(hit_w, L[2], 1.5 + minf(area, 6.0) * 0.4)
	fx.spark(hit_w, L[2], 22 + int(minf(area, 8.0) * 4), 1.2)
	if not quiet:
		if K.t >= 0.3:
			sfx.play("heavy", 0.0, randf_range(0.92, 1.05) - minf(K.t, 0.9) * 0.15)
			sfx.play("shatter2", -9.0, 0.75)
		else:
			var v := clampi(int(3.0 - area * 0.4), 0, 2)
			var pitch := randf_range(1.12, 1.3) if p.kind == "thin" else randf_range(0.92, 1.1)
			# a colour combo makes the glass ring brighter and louder each time
			var cb := minf(float(combo_n), 10.0) if p.color_id >= 0 and p.color_id == combo_color else 0.0
			sfx.play("shatter%d" % v, (-1.0 if area > 3.0 else -4.0) + cb * 0.4, pitch * (1.0 + cb * 0.025))
		if p.color_id >= 0:
			sfx.note(combo_n)
	if not crash and area > 3.0:
		hitstop_until = _ms() + 45
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
	if p.gate.door and not crash:
		_door_burst(p.gate)


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
	elif tg.kind == "power":
		col = POW[POW_LIST[tg.color_id]][0]
	elif tg.kind != "jar":
		col = Color("ffc861")
	fx.spark(pos, col, 30, 1.3)
	fx.flash(pos, col, 2.0)
	var hex := Glass.ngon(6, 0.36)
	var cells := Glass.voronoi(hex, Glass.seeds_for(hex, Vector2(0.05, 0.02), 6))
	for cell in cells:
		var cc := Glass.centroid(cell)
		var mi := _mesh_shard(Glass.moved(cell, -cc), "mid", tg.color_id if tg.kind == "prism" else -1)
		mi.global_position = pos + Vector3(cc.x, cc.y, 0)
		shards.append({"node": mi, "v": Vector3(cc.x, cc.y + 0.3, 0).normalized() * randf_range(2.0, 4.0), "axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), "w": randf_range(4.0, 12.0), "life": 0.0})
	tg.node.queue_free()


func _jar_got(_tg: GTarget) -> void:
	jars_got += 1
	# one ball breaks one glass now, so a crystal gives a little more
	balls += 4
	_ev("crystal")
	jar_streak += 1
	var at := cam.unproject_position(_tg.node.global_position) if not cam.is_position_behind(_tg.node.global_position) else Vector2(640, 300)
	hud.popup("+4", at)
	var want := 3 if jar_streak >= 25 else 2 if jar_streak >= 10 else 1
	if want > multi:
		multi = want
		hud.show_toast("×%d BALLS" % multi, Hud.ACCENT, 0.6)
		sfx.play("multi", -2.0)
	sfx.play("shatter2", -5.0, randf_range(1.25, 1.4))


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
	_ev("chain", {"n": k})
	hud.show_toast(text, Color("ffc861"), 0.5)
	sfx.play("multi", -4.0)


## glass that is all one piece: when one part breaks the rest goes with it, at once
func link(list: Array) -> void:
	for p in list:
		var pp: GPane = p
		var prev: Callable = pp.on_break
		pp.on_break = func():
			if prev.is_valid():
				prev.call()
			var k := 0
			for q in list:
				if q.alive:
					var qq: GPane = q
					var delay := 0.015 * k
					k += 1
					var tt := [0.0]
					anims.append(func(dt: float) -> bool:
						tt[0] += dt
						if tt[0] < delay:
							return true
						if qq.alive:
							break_pane(qq, Vector2.ZERO, Vector3(0, 0, -1), false, k > 1)
						return false)


# ---------- what holds the glass up ----------
var frame_mat: StandardMaterial3D


## nothing floats: every pane gets a frame, and then posts to the floor (if it stands), a rod up to a rail
## (if it slides), or an axle and a strut (if it turns); glass that falls from the sky only has its frame
func mount(n0: int, type: String) -> void:
	var falling := type in ["drop", "fall_blocks", "tile_rain"]
	for gi in range(n0, gates.size()):
		var g: GGate = gates[gi]
		var sec := section_at(g.d)
		var top := CEIL
		if sec == "hall":
			top = 14.2
		elif sec == "tunnel":
			top = Worlds.T_C.y + Worlds.T_R - 0.4
		var rail_done := false
		var ring_done := false
		for p: GPane in g.panes:
			if p.move.is_valid():
				p.move.call(p, 0.0, 300.0)
			var b := Glass.bounds(p.poly)
			var moving := p.move.is_valid() or p.charge >= 0.0
			var fm := _frame_mesh(p)
			if moving or not p.blocks:
				p.node.add_child(fm)
			else:
				fm.transform = p.node.transform
				decor(g, fm)
			if falling or not p.blocks:
				continue
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var xf: Transform3D = p.node.transform
			var z := xf.origin.z
			if p.pivot != Vector2.INF:
				var pv := p.pivot
				if absf(pv.x) < 2.0 and absf(pv.y - EYE) < 1.8:
					# turning about the middle of the way: nothing may stand where you pass, so it runs
					# in a steel ring round its edge, the ring held from the walls (once for the whole gate)
					if not ring_done:
						ring_done = true
						var rr := 0.0
						for q: GPane in g.panes:
							if q.pivot == Vector2.INF or q.pivot.distance_to(pv) > 0.01:
								continue
							for v in q.poly:
								rr = maxf(rr, (Vector2(q.base.origin.x, q.base.origin.y) + v).distance_to(pv))
						rr += 0.22
						var ring_n := 32
						for k in ring_n:
							var a0 := TAU * k / ring_n
							var cpos := Vector2(pv.x, pv.y) + Vector2(cos(a0), sin(a0)) * rr
							if cpos.y < -0.1:
								continue
							Worlds._box_xf(st, Transform3D(Basis(Vector3(0, 0, 1), a0 + PI * 0.5) * Basis.from_scale(Vector3(rr * TAU / ring_n + 0.05, 0.16, 0.2)), Vector3(cpos.x, cpos.y, z + 0.28)), Color("8a939c"))
						if sec != "sky":
							var wall := Worlds.HALL_W if sec == "hall" else (Worlds.T_R - 0.3 if sec == "tunnel" else HALF_W + 0.3)
							for sd in [-1.0, 1.0]:
								var x0: float = pv.x + sd * rr
								if absf(wall) > absf(x0):
									Worlds.box(st, Vector3((x0 + sd * wall) * 0.5, pv.y, z + 0.28), Vector3(absf(sd * wall - x0), 0.18, 0.18), Color("8a939c"))
				else:
					# an axle at the side it turns about, held from above
					Worlds._box_xf(st, Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5).scaled(Vector3(0.34, 0.3, 0.34)), Vector3(pv.x, pv.y, z + 0.18)), Color("8a939c"))
					if sec != "sky" and pv.y < top - 0.2:
						Worlds.box(st, Vector3(pv.x, (pv.y + top) * 0.5, z + 0.3), Vector3(0.12, top - pv.y, 0.12), Color("8a939c"))
			elif moving:
				# it hangs from a rail across the way, on a rod
				var hx := xf.origin.x + b.get_center().x
				var ytop := xf.origin.y + b.end.y
				if sec != "sky" and ytop < top - 0.1:
					var rod := MeshInstance3D.new()
					var rs := SurfaceTool.new()
					rs.begin(Mesh.PRIMITIVE_TRIANGLES)
					Worlds.box(rs, Vector3(b.get_center().x, b.end.y + (top - ytop) * 0.5, 0), Vector3(0.09, top - ytop, 0.09), Color("8a939c"))
					rod.mesh = rs.commit()
					rod.material_override = frame_mat
					p.node.add_child(rod)
					if not rail_done:
						rail_done = true
						Worlds.box(st, Vector3(0, top - 0.05, z), Vector3(Worlds.HALF_W * 2.0 + 0.4, 0.16, 0.24), Color("8a939c"))
			else:
				# it stands: posts down to the floor from its lowest corners, or a plate under it in the sky
				var low := xf.origin.y + b.position.y
				if sec == "sky":
					Worlds.box(st, Vector3(xf.origin.x + b.get_center().x, low - 0.2, z), Vector3(b.size.x + 0.4, 0.4, 1.2), Color("8a939c"))
				elif low > 0.15:
					for q in [b.position.x + 0.1, b.end.x - 0.1]:
						Worlds.box(st, Vector3(xf.origin.x + q, low * 0.5, z), Vector3(0.1, low, 0.1), Color("8a939c"))
				else:
					# a slot in the floor it stands in
					Worlds.box(st, Vector3(xf.origin.x + b.get_center().x, 0.04, z), Vector3(b.size.x + 0.2, 0.08, 0.3), Color("8a939c"))
			var m := MeshInstance3D.new()
			m.mesh = st.commit()
			m.material_override = frame_mat
			decor(g, m)


## a thin metal frame round a pane, along each edge
func _frame_mesh(p: GPane) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t: float = Glass.KINDS[p.kind].t + 0.05
	var w := 0.07 + minf(t, 1.0) * 0.04
	var n := p.poly.size()
	var c := Glass.centroid(p.poly)
	for i in n:
		var a: Vector2 = p.poly[i]
		var bb: Vector2 = p.poly[(i + 1) % n]
		var e := bb - a
		var l := e.length()
		if l < 0.05:
			continue
		var dir := e / l
		var nrm := Vector2(-dir.y, dir.x)
		if nrm.dot((a + bb) * 0.5 - c) < 0.0:
			nrm = -nrm
		var mid := (a + bb) * 0.5 + nrm * (w * 0.4)
		var basis := Basis(Vector3(dir.x, dir.y, 0) * (l + w), Vector3(nrm.x, nrm.y, 0) * w, Vector3(0, 0, t))
		Worlds._box_xf(st, Transform3D(basis, Vector3(mid.x, mid.y, 0)), Color("c9d1d8"))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = frame_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## a heavy block landing: the ground shakes
func thump(at: Vector3) -> void:
	if absf(-at.z - dist) > 60.0:
		return
	_ev("thump")
	shake = maxf(shake, 0.45)
	sfx.play("thud", 2.0, 0.55)
	sfx.play("heavy", -10.0, 0.6)
	fx.spark(at, Color("cfe8e4"), 18, 0.8)
	vibe(40)


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
	_ev("chain", {"n": k})
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
	_ev("prism", {"n": list.size()})
	hud.show_toast("Prism · %s ×%d" % [Glass.COLOR_NAMES[c], list.size()], Glass.COLORS[c], 0.7)
	sfx.play("prism", -1.0)
	hitstop_until = _ms() + 60
	vibe(30)


func _blast(p: GPane, at: Vector3) -> void:
	_ev("blast")
	fx.flash(at, Color("ff8a3c"), 5.0)
	fx.spark(at, Color("ffb060"), 50, 1.8)
	shake = maxf(shake, 0.5)
	sfx.play("boom", 0.0)
	hitstop_until = _ms() + 70
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
		p.hp = 2
		p.color_id = 4
		p.node.mesh = Glass.slab_mesh(p.poly, "slab", 1.0, 4)
		fx.flash(p.node.global_transform.origin, Color("b98bff"), 4.0)
		hud.show_toast("Charged: 2 hits", Color("b98bff"), 0.5)
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
	_ev("finale", {"n": list.size()})
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
		var pos := n.position
		if s.get("rest", false):
			pass
		else:
			if s.has("slide"):
				v *= exp(-dt * 1.2)
			else:
				v.y -= 14.0 * dt
				v *= exp(-dt * 0.15)
			pos += v * dt
			var sec := section_at(-pos.z)
			# the floor: glass bounces a little, skids, and comes to rest
			if pos.y < 0.05 and sec != "sky":
				pos.y = 0.05
				var m: float = s.get("mass", 1.0)
				if absf(v.y) > 1.2:
					v.y = absf(v.y) * (0.32 / m)
					s.w = s.w * 0.55
				else:
					v.y = 0.0
				v.x *= exp(-dt * 6.0)
				v.z *= exp(-dt * 6.0)
				s.w *= exp(-dt * 8.0)
				if v.length() < 0.25 and pos.y <= 0.051:
					s.rest = true
					v = Vector3.ZERO
					# lying flat on the floor
					n.basis = Basis(Vector3(1, 0, 0), PI * 0.5).rotated(Vector3.UP, randf() * TAU).scaled(n.basis.get_scale())
			# the walls
			var lim := INF if sec == "sky" else (Worlds.HALL_W - 0.2 if sec == "hall" else HALF_W - 0.1)
			if absf(pos.x) > lim:
				pos.x = signf(pos.x) * lim
				v.x = -v.x * 0.35
			n.position = pos
			if not s.get("rest", false):
				n.rotate(s.axis, s.w * dt)
		s.v = v
		s.life += dt
		if s.life > 6.0 or -pos.z < dist - 4.0 or pos.y < -40.0:
			_free_shard(n)
			shards.remove_at(i)
		i -= 1


# ---------- things that happen round you: none of them can hurt you ----------
## does the roof of the great hall open here?
func _roof_opens(d: float) -> bool:
	if section_at(d) != "hall":
		return false
	if mode == "level1":
		return true
	return mode == "endless" and posmod(_room_of(d), Rooms.CP_EVERY) != 0


func _spectacle(d0: float, sec: String) -> void:
	if mode != "endless" and mode != "level1":
		return
	if sec == "corridor" or sec == "hall":
		if posmod(next_seg, 2) == 0 and randf() < 0.6:
			_riser_pair(d0 + randf_range(3.0, 13.0), sec)
	if sec == "hall":
		if _roof_opens(d0 + 1.0):
			_roof_seg(d0)
		# one chandelier in each great hall, in its second piece
		if section_at(d0 - SEG + 1.0) == "hall" and section_at(d0 - 2.0 * SEG + 1.0) != "hall":
			_chandelier(d0 + 8.0, -1.0 if randf() < 0.5 else 1.0)
	elif sec == "sky":
		if randf() < 0.55:
			_crystal_mount(d0 + randf_range(2.0, 14.0), -1.0 if randf() < 0.5 else 1.0)


## two pillars at the sides that come up out of the floor as you come, so the room builds itself for you
func _riser_pair(d: float, sec: String) -> void:
	var g := new_gate("riser", d)
	var w := _world_at(d)
	var T: Dictionary = Worlds.TUNE[w]
	var acc: Color = Worlds.def(w).accent
	var hall := sec == "hall"
	var hw := (Worlds.HALL_W - 4.5) if hall else (HALF_W - 0.45)
	var h := 11.0 if hall else CEIL - 0.05
	var wd := 1.1 if hall else 0.62
	var stone: Color = (T.wall2 as Color).lerp(Color("d8dde2"), 0.35)
	for sd in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Worlds.box(st, Vector3(0, h * 0.5, 0), Vector3(wd, h, wd), stone)
		Worlds.box(st, Vector3(0, 0.2, 0), Vector3(wd + 0.35, 0.4, wd + 0.35), stone * 0.8)
		Worlds.box(st, Vector3(0, h - 0.25, 0), Vector3(wd + 0.3, 0.3, wd + 0.3), stone * 0.85)
		st.set_material(Worlds.lit_mat)
		var m := MeshInstance3D.new()
		m.mesh = st.commit()
		var gs := SurfaceTool.new()
		gs.begin(Mesh.PRIMITIVE_TRIANGLES)
		# bright bands, so you see them come up
		for y in [0.42, h * 0.5, h - 0.45]:
			Worlds.box(gs, Vector3(0, y, 0), Vector3(wd + 0.06, 0.07, wd + 0.06), acc)
		Worlds.box(gs, Vector3(-sd * (wd * 0.5 + 0.01), h * 0.5, 0), Vector3(0.03, h - 1.2, 0.12), acc * 0.8)
		gs.set_material(Worlds.glow_mat)
		gs.commit(m.mesh)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(sd * hw, -h - 0.4, -d)
		decor(g, m)
		add_solid(m, Vector3(0, h * 0.5, 0), Vector3(wd * 0.5, h * 0.5, wd * 0.5))
		risers.append({"node": m, "d": d, "h": h, "late": randf_range(0.0, 5.0) + (0.0 if sd < 0.0 else 2.5), "up": false, "go": false})


## a piece of the great hall's roof: two halves that swing up and open to the sky as you come
func _roof_seg(d0: float) -> void:
	var g := new_gate("roof", d0)
	var w := _world_at(d0 + 1.0)
	var T: Dictionary = Worlds.TUNE[w]
	var acc: Color = Worlds.def(w).accent
	var hw := Worlds.HALL_W + 1.0
	var pair := []
	for sd in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		Worlds.box(st, Vector3(-sd * hw * 0.5, 0, 0), Vector3(hw, 0.6, SEG + 0.02), T.wall * 0.45)
		# coffers underneath
		for k in 4:
			Worlds.box(st, Vector3(-sd * hw * (0.15 + k * 0.22), -0.4, 0), Vector3(0.3, 0.3, SEG), T.wall2 * 0.55)
		st.set_material(Worlds.lit_mat)
		var m := MeshInstance3D.new()
		m.mesh = st.commit()
		var gs := SurfaceTool.new()
		gs.begin(Mesh.PRIMITIVE_TRIANGLES)
		# a line of light along the edge where the two halves meet
		Worlds.box(gs, Vector3(-sd * (hw - 0.12), -0.32, 0), Vector3(0.2, 0.06, SEG), acc)
		gs.set_material(Worlds.glow_mat)
		gs.commit(m.mesh)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(sd * hw, 14.5, -(d0 + SEG * 0.5))
		decor(g, m)
		pair.append({"node": m, "sd": sd})
	roofs.append({"parts": pair, "d": d0 + SEG * 0.5, "k": -1.0})


## a great chandelier of glass, high up at the side of a hall: as you come it falls and smashes on the floor
func _chandelier(d: float, sd: float) -> void:
	var g := new_gate("chandelier", d)
	var x := sd * randf_range(5.5, 9.0)
	var y := randf_range(9.0, 10.5)
	var n := Node3D.new()
	n.position = Vector3(x, y, -d)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var gold := Color("c9a25a")
	for i in 18:
		var a := TAU * i / 18.0
		Worlds.box(st, Vector3(cos(a) * 1.7, 0, sin(a) * 1.7), Vector3(0.62, 0.1, 0.1), gold)
		Worlds.box(st, Vector3(cos(a) * 0.95, 0.7, sin(a) * 0.95), Vector3(0.36, 0.08, 0.08), gold)
	for i in 6:
		var a := TAU * i / 6.0
		Worlds.box(st, Vector3(cos(a) * 0.85, 0.35, sin(a) * 0.85), Vector3(0.06, 0.8, 0.06), gold * 0.9)
	Worlds.box(st, Vector3(0, 0.9, 0), Vector3(0.12, 1.8, 0.12), gold * 0.8)
	st.set_material(Worlds.lit_mat)
	var frame := MeshInstance3D.new()
	frame.mesh = st.commit()
	n.add_child(frame)
	# the chain up to a beam across the hall
	var cs := SurfaceTool.new()
	cs.begin(Mesh.PRIMITIVE_TRIANGLES)
	Worlds.box(cs, Vector3(x, (y + 1.8 + 14.0) * 0.5, -d), Vector3(0.06, 14.0 - y - 1.8, 0.06), Color("2b3138"))
	Worlds.box(cs, Vector3(0, 14.0, -d), Vector3(Worlds.HALL_W * 2.0, 0.4, 0.4), Color("39424c"))
	cs.set_material(Worlds.lit_mat)
	var chain_m := MeshInstance3D.new()
	chain_m.mesh = cs.commit()
	decor(g, chain_m)
	# drops of glass, and candle flames
	var drops := []
	for ring in [[1.7, 18, 0.9], [0.95, 10, 0.7], [0.0, 1, 1.6]]:
		var rr: float = ring[0]
		for i in int(ring[1]):
			var a := TAU * i / float(ring[1]) + 0.1
			var cm := MeshInstance3D.new()
			cm.mesh = crystal_mesh
			cm.material_override = chand_mat
			var sc: float = ring[2]
			cm.scale = Vector3(0.45, sc, 0.45)
			cm.rotation.x = PI
			cm.position = Vector3(cos(a) * rr, -0.45 * sc - 0.05, sin(a) * rr)
			n.add_child(cm)
			drops.append(cm)
	var fs := SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 9:
		var a := TAU * i / 9.0
		Worlds.box(fs, Vector3(cos(a) * 1.7, 0.2, sin(a) * 1.7), Vector3(0.1, 0.22, 0.1), Color("ffe2a6"))
	fs.set_material(Worlds.glow_mat)
	var flames := MeshInstance3D.new()
	flames.mesh = fs.commit()
	n.add_child(flames)
	decor(g, n)
	chandeliers.append({"node": n, "d": d, "drops": drops, "flames": flames, "chain": chain_m, "state": 0, "v": 0.0, "spin": randf_range(-0.6, 0.6)})


## far out in the open sky: a mountain of glass crystals floating on a rock, turning slowly
func _crystal_mount(d: float, sd: float) -> void:
	var g := new_gate("berg", d)
	var w := _world_at(d)
	var T: Dictionary = Worlds.TUNE[w]
	var n := Node3D.new()
	var far := randf_range(20.0, 46.0)
	n.position = Vector3(sd * far, randf_range(-9.0, 9.0), -d)
	var sc := randf_range(0.8, 1.5) * (0.8 + far / 60.0)
	n.scale = Vector3.ONE * sc
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock: Color = (T.wall as Color).lerp(Color("2a2a30"), 0.55)
	var widths := [7.0, 5.6, 4.2, 2.8, 1.5]
	for i in widths.size():
		var ww: float = widths[i]
		Worlds.box(st, Vector3(randf_range(-0.3, 0.3), -0.5 - i * 1.0, randf_range(-0.3, 0.3)), Vector3(ww, 1.05, ww * 0.85), rock * (1.0 - i * 0.09))
	st.set_material(Worlds.lit_mat)
	var base := MeshInstance3D.new()
	base.mesh = st.commit()
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n.add_child(base)
	var count := randi_range(5, 8)
	for i in count:
		var cm := MeshInstance3D.new()
		cm.mesh = column_mesh
		cm.material_override = berg_mat
		cm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var big := 1.0 if i == 0 else randf_range(0.35, 0.8)
		cm.scale = Vector3(3.4, 8.0, 3.4) * big
		cm.position = Vector3(randf_range(-2.4, 2.4) * (0.3 if i == 0 else 1.0), 0.0, randf_range(-2.0, 2.0) * (0.3 if i == 0 else 1.0))
		cm.rotation = Vector3(randf_range(-0.45, 0.45), randf() * TAU, randf_range(-0.45, 0.45)) * (0.3 if i == 0 else 1.0)
		n.add_child(cm)
	# and a few hanging down under the rock
	for i in 3:
		var cm := MeshInstance3D.new()
		cm.mesh = column_mesh
		cm.material_override = berg_mat
		cm.scale = Vector3(2.2, randf_range(2.5, 4.5), 2.2)
		cm.position = Vector3(randf_range(-1.5, 1.5), -2.0 - i * 0.6, randf_range(-1.2, 1.2))
		cm.rotation = Vector3(PI + randf_range(-0.3, 0.3), randf() * TAU, 0)
		n.add_child(cm)
	decor(g, n)
	floaters.append({"node": n, "y": n.position.y, "ph": randf() * TAU, "w": randf_range(0.04, 0.1) * (1.0 if randf() < 0.5 else -1.0)})


## a six-sided crystal with a pointed end, one unit tall
func _column_shape() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.18
	var top := 0.78
	var tip := Vector3(0, 1.0, 0)
	for i in 6:
		var a0 := TAU * i / 6.0
		var a1 := TAU * (i + 1) / 6.0
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var q0 := p0 + Vector3(0, top, 0)
		var q1 := p1 + Vector3(0, top, 0)
		var nrm := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		st.set_normal(nrm)
		for v in [p0, q0, q1, p0, q1, p1]:
			st.add_vertex(v)
		var n2 := (q1 - q0).cross(tip - q0).normalized()
		if n2.dot(nrm) < 0.0:
			n2 = -n2
		st.set_normal(n2)
		for v in [q0, tip, q1]:
			st.add_vertex(v)
	return st.commit()


func _spectacle_step(dt: float) -> void:
	# pillars coming up out of the floor
	var i := risers.size() - 1
	while i >= 0:
		var r: Dictionary = risers[i]
		if not is_instance_valid(r.node):
			risers.remove_at(i)
			i -= 1
			continue
		var m: MeshInstance3D = r.node
		var ahead: float = r.d - dist
		var k := clampf((46.0 + float(r.late) - ahead) / 14.0, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - k, 3.0)
		m.position.y = -(float(r.h) + 0.4) * (1.0 - e)
		if k > 0.0 and not r.go:
			r.go = true
			fx.spark(Vector3(m.position.x, 0.1, m.position.z), Color("d8dde2"), 14, 0.7)
		if k >= 1.0 and not r.up:
			r.up = true
			if absf(ahead) < 40.0:
				sfx.play("thud", -16.0, 0.5)
				fx.spark(Vector3(m.position.x, 0.1, m.position.z), Color("d8dde2"), 10, 0.5)
		if r.up:
			risers.remove_at(i)
		i -= 1
	# roofs swinging open
	for rf in roofs:
		var ahead: float = rf.d - dist
		var k := clampf((62.0 - ahead) / 26.0, 0.0, 1.0)
		if k == rf.k:
			continue
		rf.k = k
		var e := k * k * (3.0 - 2.0 * k)
		for part in rf.parts:
			if is_instance_valid(part.node):
				var pm: MeshInstance3D = part.node
				pm.rotation.z = -float(part.sd) * e * 1.85
	while roofs.size() and roofs[0].d < dist - 30.0:
		roofs.pop_front()
	# chandeliers falling
	i = chandeliers.size() - 1
	while i >= 0:
		var c: Dictionary = chandeliers[i]
		if not is_instance_valid(c.node):
			chandeliers.remove_at(i)
			i -= 1
			continue
		var n: Node3D = c.node
		var ahead: float = c.d - dist
		if c.state == 0 and ahead < 34.0:
			c.state = 1
			sfx.play("crack", -6.0, 0.7)
			if is_instance_valid(c.chain):
				c.chain.visible = false
		if c.state == 1:
			c.v = float(c.v) + 16.0 * dt
			n.position.y -= float(c.v) * dt
			n.rotate_y(float(c.spin) * dt)
			n.rotation.z += dt * 0.15 * signf(n.position.x)
			if n.position.y <= 0.15:
				n.position.y = 0.15
				c.state = 2
				_chandelier_smash(c)
		if c.state == 2:
			chandeliers.remove_at(i)
		i -= 1
	# crystal mountains turning slowly
	for f in floaters:
		if is_instance_valid(f.node):
			var fn: Node3D = f.node
			fn.rotate_y(float(f.w) * dt)
			fn.position.y = float(f.y) + sin(t * 0.4 + float(f.ph)) * 0.8
	while floaters.size() and not is_instance_valid(floaters[0].node):
		floaters.pop_front()


func _chandelier_smash(c: Dictionary) -> void:
	var n: Node3D = c.node
	var at := n.global_position
	for dm in c.drops:
		var cm: MeshInstance3D = dm
		var p := cm.global_position
		cm.visible = false
		for k in (2 if save.quality > 0 else 1):
			var poly := Glass.ngon(randi_range(3, 5), randf_range(0.12, 0.28))
			var mi := _mesh_shard(poly, "mid", -1)
			mi.global_position = Vector3(p.x, maxf(p.y, 0.3), p.z)
			var away := (p - at)
			away.y = 0.0
			var v := away.normalized() * randf_range(2.0, 6.0) + Vector3(randf_range(-1, 1), randf_range(2.0, 5.5), randf_range(-1, 1))
			shards.append({"node": mi, "v": v, "axis": Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized(), "w": randf_range(5.0, 14.0), "life": 0.0, "mass": 0.7, "rest": false})
	_ev("chandelier")
	if is_instance_valid(c.flames):
		c.flames.visible = false
	n.rotation.x = randf_range(-0.25, 0.25)
	fx.flash(at + Vector3(0, 0.6, 0), Color("fff0d0"), 4.0)
	fx.spark(at + Vector3(0, 0.4, 0), Color("ffe8c0"), 60, 1.6)
	sfx.play("heavy", -2.0, 0.8)
	sfx.play("shatter0", -3.0, 0.9)
	sfx.play("shatter1", -6.0, 1.15)
	shake = maxf(shake, 0.4)
	vibe(45)


## the checkpoint door goes: time slows, the light flares, you are pushed through into the next world
func _door_burst(g: GGate) -> void:
	if g.burst:
		return
	g.burst = true
	_ev("door", {"to": _world_at(g.d + 10.0)})
	slow_until = t + 0.6
	fov_kick = 8.0
	shake = maxf(shake, 0.5)
	look_fast_until = t + 3.5
	hud.flash_screen(Color.WHITE, 0.7, 1.0)
	if mode != "calm":
		balls += 5
	var c := Vector3(0, EYE, -g.d)
	fx.flash(c, Color("ffffff"), 6.0)
	fx.spark(c, Color("e8f6ff"), 90, 2.2)
	sfx.play("heavy", 0.0, 0.85)
	sfx.play("shatter0", 0.0, 0.8)
	sfx.play("shatter1", -3.0, 1.1)
	vibe(80)


func _power_got(kind: String) -> void:
	power = kind
	power_until = t + float(POW[kind][1])
	_ev("power", {"kind": kind})
	var col: Color = POW[kind][0]
	hud.flash_screen(col, 0.35, 0.6)
	fov_kick = maxf(fov_kick, 2.5)
	sfx.play("shatter2", -3.0, 1.45)
	sfx.play("heavy", -12.0, 1.6)
	vibe(35)


# ---------- making shorts ----------
## the clock for the little stops when big glass breaks: real time when you play, frames when a video is made
## (a frame takes far longer to draw then than it lasts in the video)
func _ms() -> int:
	if shorts:
		return int(Engine.get_frames_drawn() * 1000.0 / shorts_fps)
	return Time.get_ticks_msec()


## seconds since the run began; for a video, counted in frames
func _run_time() -> float:
	if ev_f0 < 0:
		return t
	return (Engine.get_frames_drawn() - ev_f0) / shorts_fps


## one line for the video editor: what happened, on which frame of the video, and how many balls there were
func _ev(e: String, extra := {}) -> void:
	if ev_file == null:
		return
	var f := Engine.get_frames_drawn()
	var line := {"e": e, "f": f, "balls": balls}
	line.merge(extra)
	ev_file.store_line(JSON.stringify(line))
	if e != "tick":
		ev_file.flush()
	if e == quit_on and quit_frame < 0:
		quit_frame = f + int(quit_after * shorts_fps)


func _shorts_start() -> void:
	# wait until the sounds are made, so the first glass is heard
	while not sfx._ready_sfx:
		await get_tree().process_frame
	_start(test_mode if test_mode != "" else "endless", test_from)
	if bot_balls > 0:
		balls = bot_balls
	hud.shorts(hud_balls)
	ev_f0 = Engine.get_frames_drawn()
	# the size of the window being recorded: the recorder checks it is the tall one it asked for
	var win := DisplayServer.window_get_size()
	print("shorts: window %dx%d" % [win.x, win.y])
	_ev("start", {"mode": mode, "room": _room_of(dist), "world": world, "bot": bot, "window": [win.x, win.y]})


## how the run is going, a few times a second, and the end of the recording
func _shorts_step() -> void:
	if ev_f0 < 0:
		return
	var f := Engine.get_frames_drawn()
	if state == S.PLAY and (f - ev_f0) % 6 == 0:
		_ev("tick", {"v": snappedf(speed, 0.1), "sec": sec_now, "pow": power, "multi": multi})
	if (max_time > 0.0 and f - ev_f0 >= int(max_time * shorts_fps)) or (quit_frame >= 0 and f >= quit_frame):
		_ev("end")
		ev_file = null
		set_process(false)
		get_tree().quit()


# ---------- testing ----------
## a bare stretch of corridor with only what a test puts in it
func _test_room() -> void:
	_reset("gallery")
	mode = "gallery"
	state = S.MENU
	_set_world("cathedral", true)
	for c in root3d.get_children():
		c.queue_free()
	segs.clear()
	gates.clear()
	panes.clear()
	targets.clear()
	flying.clear()
	shards.clear()
	solids.clear()
	anims.clear()
	dist = 0.0
	speed = 8.0
	next_seg = 0
	while next_seg * SEG < 60.0:
		root3d.add_child(Worlds.build("cathedral", next_seg * SEG, next_seg * 31 + 7))
		next_seg += 1
	broken = 0
	hit_calls = 0
	t = 2.0
	_place_camera(0.0)


func _fire(dir: Vector3) -> Dictionary:
	var from := cam.position + dir * 1.3 + Vector3(0, -0.3, 0)
	var mi := MeshInstance3D.new()
	mi.mesh = marble_mesh
	mi.material_override = marble_mats[0]
	mi.position = from
	root3d.add_child(mi)
	var b := {"node": mi, "v": dir * (BALL_SPEED + speed), "life": 0.0, "pts": [from], "col": Color.WHITE, "shot": {"hit": false}, "landed": false, "spent": false, "walls": 0}
	flying.append(b)
	return b


## aim at a point the way the game does (lifted for the drop)
func _fire_at(p: Vector3) -> Dictionary:
	var from := cam.position + Vector3(0, -0.3, 0)
	var tt := (p - from).length() / (BALL_SPEED + speed)
	return _fire((p + Vector3(0, 0.5 * GRAV * tt * tt, 0) - from).normalized())


func _sim(sec: float) -> void:
	var n := int(sec * 60.0)
	for k in n:
		t += 1.0 / 60.0
		_move_gates()
		_update_balls(1.0 / 60.0)
		_run_anims(1.0 / 60.0)
		_update_shards(1.0 / 60.0)


func _report(name: String, ok: bool, info: String) -> void:
	print("BALLTEST %s %s  %s" % ["PASS" if ok else "FAIL", name, info])


## makes every track and checks the loops: they are made, are not silent, and join up at the end
func _music_tests() -> void:
	var t0 := Time.get_ticks_msec()
	for k in Sfx.TRACKS.keys():
		sfx.play_music(k)
	while (sfx.tracks.size() < Sfx.TRACKS.size() or not sfx._ready_sfx) and Time.get_ticks_msec() - t0 < 180000:
		await get_tree().process_frame
	print("BALLTEST INFO all the music made in %d ms" % (Time.get_ticks_msec() - t0))
	_report("heartbeat", sfx.streams.has("pulse"), "")
	for k in Sfx.TRACKS.keys():
		var w: AudioStreamWAV = sfx.tracks.get(k)
		if w == null:
			_report("music " + k, false, "not made")
			continue
		var d := w.data
		var n := d.size() / 2
		var sq := 0.0
		var peak := 0
		for i in n:
			var s := d.decode_s16(i * 2)
			sq += float(s) * s
			peak = maxi(peak, absi(s))
		var rms := sqrt(sq / n) / 32000.0
		var seam := absf(float(d.decode_s16((n - 1) * 2) - d.decode_s16(0))) / 32000.0
		_report("music " + k, rms > 0.03 and peak > 20000 and seam < 0.15, "%.1f s, rms %.3f, peak %d, seam %.4f" % [float(n) / Sfx.MRATE, rms, peak, seam])


func _ball_tests() -> void:
	for i in 30:
		await get_tree().process_frame
	hud._hide_all()
	var eye := Vector3(0, EYE, 0)
	# 1. one pane
	_test_room()
	pane(new_gate("t", 12.0), Glass.rect(-2.4, 2.4, 0.05, 3.9), 12.0, "thin")
	var b := _fire_at(eye + Vector3(0, 0, -12.0))
	_sim(1.5)
	_report("single pane", broken == 1 and hit_calls == 1 and b.spent, "broken=%d hits=%d ball_z=%.1f" % [broken, hit_calls, -b.node.position.z])
	# 2. two panes 0.6 m apart, one behind the other
	_test_room()
	pane(new_gate("t", 12.0), Glass.rect(-2.4, 2.4, 0.05, 3.9), 12.0, "thin")
	pane(new_gate("t", 12.6), Glass.rect(-2.4, 2.4, 0.05, 3.9), 12.6, "thin")
	b = _fire_at(eye + Vector3(0, 0, -12.0))
	_sim(1.5)
	_report("two panes 0.6 m apart", broken == 1 and hit_calls == 1, "broken=%d hits=%d ball_z=%.1f" % [broken, hit_calls, -b.node.position.z])
	# 3. layers and frosted, as the game builds them
	for ty in ["layers", "frosted", "chessboard", "blocks", "collapse", "tube", "scissors"]:
		_test_room()
		Obstacles.build(self, ty, 12.0, 3)
		_move_gates()
		b = _fire_at(eye + Vector3(0, 0, -12.0))
		_sim(1.8)
		var linked: bool = ty in ["blocks", "collapse"]
		_report("built: " + ty, hit_calls <= 1 and (linked or broken <= 1), "broken=%d hits=%d" % [broken, hit_calls])
	# 4. thick glass: the first ball holds and bounces back, the second breaks it
	_test_room()
	var tp := pane(new_gate("t", 12.0), Glass.rect(-2.4, 2.4, 0.05, 3.9), 12.0, "thick")
	b = _fire_at(eye + Vector3(0, 0, -12.0))
	_sim(0.6)
	var held: bool = tp.alive and b.spent and (b.v as Vector3).z > 0.0
	var b2 := _fire_at(eye + Vector3(0.6, 0, -12.0))
	_sim(1.2)
	_report("thick: holds, then breaks", held and not tp.alive and hit_calls == 2 and broken == 1, "held=%s broken=%d hits=%d" % [held, broken, hit_calls])
	# 5. side wall
	_test_room()
	b = _fire(Vector3(0.75, 0.05, -0.66).normalized())
	var max_x := 0.0
	for k in 60:
		_sim(1.0 / 60.0)
		max_x = maxf(max_x, absf(b.node.position.x))
	_report("side wall", max_x <= HALF_W - BALL_R + 0.001 and (b.v as Vector3).x < 0.0, "max_x=%.2f vx=%.2f" % [max_x, (b.v as Vector3).x])
	# 6. a steel grille: it cannot get through
	_test_room()
	var gg := new_gate("grille", 12.0)
	grille(gg, 12.0, Vector3(2.0, 3.0, -11.8))
	pane(new_gate("t", 14.0), Glass.rect(-2.4, 2.4, 0.05, 3.9), 14.0, "thin")
	b = _fire_at(Vector3(-0.6, EYE, -12.0))
	_sim(1.5)
	_report("grille stops it", -b.node.position.z < 12.0 and broken == 0, "ball_z=%.2f broken=%d" % [-b.node.position.z, broken])
	# 7. a miss: into the empty air
	_test_room()
	pane(new_gate("t", 12.0), Glass.rect(-1.0, 1.0, 0.5, 2.5), 12.0, "thin")
	b = _fire(Vector3(-0.2, 0.5, -0.84).normalized())
	_sim(2.5)
	_report("miss", broken == 0 and hit_calls == 0, "broken=%d hits=%d" % [broken, hit_calls])
	# 8. many shots, one after another, at a grid of nine: one pane each
	_test_room()
	var cells := []
	var gg2 := new_gate("t", 14.0)
	for cx in 3:
		for cy in 3:
			cells.append(pane(gg2, Glass.rect(-2.4 + cx * 1.6 + 0.03, -2.4 + cx * 1.6 + 1.57, 0.05 + cy * 1.135 + 0.03, 0.05 + cy * 1.135 + 1.1), 14.0, "thin"))
	var aims := [Vector2(-1.6, 0.6), Vector2(0, 0.6), Vector2(1.6, 0.6), Vector2(-1.6, 1.75), Vector2(1.6, 1.75)]
	for q in aims:
		_fire_at(Vector3(q.x, q.y, -14.0))
		_sim(0.25)
	_sim(1.0)
	_report("five shots at a grid", broken == 5 and hit_calls == 5, "broken=%d hits=%d" % [broken, hit_calls])
	# 9. three balls in one throw at one pane: each ball one glass at most
	_test_room()
	pane(new_gate("t", 12.0), Glass.rect(-2.4, 2.4, 0.05, 3.9), 12.0, "thin")
	pane(new_gate("t", 15.2), Glass.rect(-2.4, 2.4, 0.05, 3.9), 15.2, "thin")
	multi = 3
	_throw((eye + Vector3(0, 0.6, -12.0) - cam.position).normalized())
	multi = 1
	_sim(1.5)
	_report("three balls, panes 3.2 m apart", hit_calls <= 3 and broken == 1, "broken=%d hits=%d" % [broken, hit_calls])
	# speed of the frame: balls and solids
	_test_room()
	for k in 40:
		_riser_pair(6.0 + k * 1.2, "corridor")
	var t0 := Time.get_ticks_usec()
	for k in 30:
		_fire(Vector3(randf_range(-0.3, 0.3), 0.05, -1).normalized())
	for k in 60:
		_update_balls(1.0 / 60.0)
	print("BALLTEST cost: 30 balls x 60 steps with 80 solids: %.2f ms per step" % ((Time.get_ticks_usec() - t0) / 1000.0 / 60.0))


var _fired := {}
var _skip := {}

## how each bot plays (the shorts pick one): how near and how far ahead it throws at the glass in its way,
## from how many balls up it goes for bonus glass, from how few down it takes crystals (and how keenly),
## how keenly it goes for a crystal of power, whether it throws at any glass it sees,
## and, once it starts losing it (--fail-after), how much glass it lets through
const BOTS := {
	"perfect": {"near": 3.0, "reach": 24.0, "bonus": 12, "jar_low": 9999, "jar_pull": 0.0, "power": 3.0},
	"sniper": {"near": 3.0, "reach": 40.0, "bonus": 8, "jar_low": 9999, "jar_pull": 0.0, "power": 3.0},
	"clutch": {"near": 2.4, "reach": 13.0, "bonus": 9999, "jar_low": 3, "jar_pull": 8.0, "power": 3.0},
	"power": {"near": 3.0, "reach": 24.0, "bonus": 6, "jar_low": 9999, "jar_pull": 0.0, "power": 12.0},
	"chaos": {"near": 3.0, "reach": 30.0, "bonus": 0, "jar_low": 9999, "jar_pull": 0.0, "power": 6.0, "any": true},
	"fail": {"near": 3.0, "reach": 24.0, "bonus": 12, "jar_low": 9999, "jar_pull": 0.0, "power": 3.0, "skip": 0.55},
}


func _auto_play() -> void:
	# a simple player: throws at glass in front of the eye, at jars, hubs, prisms and buttons
	var B: Dictionary = BOTS.get(bot, BOTS.perfect)
	var failing: bool = B.has("skip") and _run_time() >= fail_after
	var target_pos = null
	var key := 0
	var best_d := 1e9
	for p in panes:
		if not p.alive or not p.blocks or p.opened or p.falling:
			continue
		var gz: float = p.node.global_transform.origin.z
		var ahead := -gz - dist
		if ahead < B.near or ahead > B.reach:
			continue
		var xf: Transform3D = p.node.global_transform
		var l: Vector3 = xf.affine_inverse() * Vector3(cam.position.x, EYE, gz)
		if not Glass.inside(p.poly, Vector2(l.x, l.y), 0.15):
			continue
		var id: int = p.get_instance_id()
		if _fired.has(id) and t - _fired[id] < 0.55:
			continue
		# losing it: some glass it just lets come
		if failing:
			if not _skip.has(id):
				_skip[id] = randf() < B.skip
			if _skip[id]:
				continue
		var aim := Vector3(cam.position.x, EYE, gz)
		var el := Vector2(l.x, l.y)
		if not Glass.inside(p.poly, el):
			var c := Glass.centroid(p.poly)
			for i in 10:
				el = el.lerp(c, 0.25)
				if Glass.inside(p.poly, el, -0.1):
					break
			aim = xf * Vector3(el.x, el.y, 0)
		if p.weak != Vector2.INF:
			aim = xf * Vector3(p.weak.x, p.weak.y, 0)
		if ahead < best_d:
			best_d = ahead
			target_pos = aim
			key = id
	# bonus glass (below in the sky, at the sides of a hall), when nothing is in the way; a wild bot throws at any glass
	var any: bool = B.get("any", false) and balls >= 4
	for p in panes:
		if not p.alive:
			continue
		if not (p.bonus > 0 and balls >= B.bonus) and not (any and not p.opened and not p.falling):
			continue
		var xf: Transform3D = p.node.global_transform
		var ahead := -xf.origin.z - dist
		if ahead < 8.0 or ahead > maxf(26.0, B.reach):
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
		if tg.kind == "jar" and (balls > B.jar_low or failing):
			continue
		var bonus := 3.0 if tg.kind != "jar" else float(B.jar_pull)
		if tg.kind == "power":
			bonus = B.power
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
		print("d=%d balls=%d crashes=%d broken=%d shots=%d jars=%d seen=%d fps=%d" % [int(dist), balls, crashes, broken, shots, jars_got, jars_seen, Engine.get_frames_per_second()])
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
	if test_screen == "balltest":
		await _ball_tests()
		get_tree().quit()
		return
	if test_screen == "musictest":
		await _music_tests()
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
