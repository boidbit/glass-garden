## Every sound is made here when the game starts (no sound files): breaking glass, cracks, the throw, jars,
## the crash, a prism, a blast, and a looping, slow, sad piece of music for each world (made the first time it is needed).
class_name Sfx
extends Node

const RATE := 22050
const MRATE := 16000

# each world's music is slow and sad: a minor key, the tempo, the tonic (Hz, a low note), which seven notes the key uses,
# the roots of its four chords (scale degrees, a chord to two bars), and a few soft piano notes:
# [beat in the 32-beat loop, scale degree (7 is an octave up), beats it is held, loudness]
const NATURAL := [0, 2, 3, 5, 7, 8, 10]
const PHRYGIAN := [0, 1, 3, 5, 7, 8, 10]
const HARMONIC := [0, 2, 3, 5, 7, 8, 11]
const TRACKS := {
	"menu": {"bpm": 52.0, "root": 110.0, "scale": NATURAL, "chords": [0, 5, 2, 6], "melody": [[0, 11, 3.5, 0.9], [3.5, 9, 1.5, 0.6], [5, 8, 3, 0.7], [8, 12, 3.5, 0.9], [11.5, 11, 1.5, 0.6], [13, 9, 3, 0.8], [16, 11, 3.5, 0.9], [19.5, 13, 2, 0.7], [21.5, 11, 2.5, 0.7], [24, 10, 3, 0.9], [27, 8, 2, 0.7], [29.5, 9, 2.5, 0.6]]},
	"cathedral": {"bpm": 48.0, "root": 98.0, "scale": NATURAL, "chords": [0, 6, 5, 4], "melody": [[0, 11, 4, 0.9], [4.5, 9, 2, 0.6], [6.5, 8, 1.5, 0.5], [8, 10, 4, 0.9], [12.5, 8, 3, 0.6], [16, 9, 3.5, 0.9], [20, 7, 1.5, 0.5], [21.5, 11, 2.5, 0.6], [24, 11, 3, 0.9], [27.5, 10, 2, 0.6], [29.5, 8, 2.5, 0.7]]},
	"venice": {"bpm": 54.0, "root": 82.41, "scale": NATURAL, "chords": [0, 5, 3, 4], "melody": [[0, 11, 3, 0.9], [3, 13, 2, 0.7], [5, 12, 3, 0.7], [8, 14, 3.5, 0.9], [11.5, 11, 1.5, 0.6], [13, 9, 3, 0.8], [16, 12, 3.5, 0.9], [19.5, 10, 2, 0.6], [21.5, 9, 2.5, 0.7], [24, 13, 3, 0.9], [27.5, 11, 2, 0.6], [29.5, 8, 2.5, 0.7]]},
	"lanterns": {"bpm": 50.0, "root": 123.47, "scale": NATURAL, "chords": [0, 6, 5, 6], "melody": [[0, 11, 4, 0.9], [4.5, 9, 3, 0.7], [8, 13, 3, 0.9], [11.5, 11, 2, 0.6], [13.5, 10, 2.5, 0.7], [16, 9, 4, 0.9], [20.5, 7, 2, 0.6], [22.5, 10, 1.5, 0.5], [24, 13, 3, 0.8], [27.5, 11, 2, 0.6], [29.5, 10, 2.5, 0.8]]},
	"mosaic": {"bpm": 56.0, "root": 82.41, "scale": PHRYGIAN, "chords": [0, 1, 0, 6], "melody": [[0, 11, 3.5, 0.9], [3.5, 8, 1.5, 0.7], [5, 7, 3, 0.7], [8, 10, 3, 0.9], [11, 12, 2, 0.7], [13, 10, 3, 0.6], [16, 9, 3.5, 0.9], [19.5, 8, 2, 0.7], [21.5, 11, 2.5, 0.8], [24, 10, 3, 0.9], [27, 8, 2, 0.7], [29, 13, 3, 0.7]]},
	"palace": {"bpm": 50.0, "root": 130.81, "scale": HARMONIC, "chords": [0, 3, 4, 0], "melody": [[0, 11, 3, 0.9], [3, 10, 1.5, 0.6], [4.5, 9, 3.5, 0.8], [8, 12, 3.5, 0.9], [11.5, 10, 1.5, 0.6], [13, 7, 3, 0.7], [16, 13, 3, 0.9], [19.5, 11, 2, 0.7], [21.5, 8, 2.5, 0.7], [24, 11, 3, 0.9], [27.5, 9, 2, 0.6], [29.5, 7, 2.5, 0.8]]},
	"calm": {"bpm": 44.0, "root": 110.0, "scale": NATURAL, "chords": [0, 2, 5, 6], "melody": [[0, 11, 5, 0.8], [5.5, 9, 2.5, 0.6], [8, 13, 4, 0.8], [13, 11, 3, 0.6], [16, 12, 5, 0.8], [21.5, 9, 2.5, 0.6], [24, 10, 4, 0.8], [28.5, 8, 3.5, 0.7]]},
}

var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_old: AudioStreamPlayer
var pulse: AudioStreamPlayer
var sound_on := true
var music_on := true
var _next := 0
var _ready_sfx := false
var tracks := {}
var _want := ""
var _building := {}
var _mutex := Mutex.new()
var _bpm := 88.0
var _tasks: Array[int] = []
var _tension := 0.0
var _tension_at := 0
var _tension_frame := 0
var _pulse_k := 0.0
# making a short: no music (the video brings its own), and the heartbeat keeps time by frames
var shorts := false
var _quitting := false


func _ready() -> void:
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)
	music_old = AudioStreamPlayer.new()
	add_child(music_old)
	pulse = AudioStreamPlayer.new()
	pulse.volume_db = -80.0
	add_child(pulse)
	_bus()
	_tasks.append(WorkerThreadPool.add_task(_build_all))


func _process(dt: float) -> void:
	# fade the old music out
	if music_old.playing:
		music_old.volume_db -= dt * 30.0
		if music_old.volume_db < -50.0:
			music_old.stop()
	if music.playing and music.volume_db < -9.0:
		music.volume_db = minf(-9.0, music.volume_db + dt * 25.0)
	# the heartbeat comes up while the game says the run is going badly, and dies away when it stops saying so
	var live := (Engine.get_process_frames() - _tension_frame < 10 if shorts else Time.get_ticks_msec() - _tension_at < 300) and music_on
	_pulse_k += ((_tension if live else 0.0) - _pulse_k) * minf(1.0, dt * 3.0)
	if _pulse_k > 0.02:
		if not pulse.playing and streams.has("pulse"):
			pulse.stream = streams["pulse"]
			pulse.play()
		pulse.volume_db = -26.0 + 14.0 * _pulse_k
		pulse.pitch_scale = 1.0 + 0.55 * _pulse_k
	elif pulse.playing:
		pulse.stop()
	if _want != "" and music_on:
		_mutex.lock()
		var s = tracks.get(_want)
		_mutex.unlock()
		if s and music.stream != s:
			if music.playing:
				music_old.stream = music.stream
				music_old.volume_db = music.volume_db
				music_old.play(music.get_playback_position())
			music.stream = s
			music.volume_db = -40.0
			music.play()
			_bpm = TRACKS[_want].bpm


func play_music(key: String) -> void:
	if shorts:
		return
	_want = key
	_mutex.lock()
	var have := tracks.has(key) or _building.has(key)
	if not have:
		_building[key] = true
	_mutex.unlock()
	if not have:
		_tasks.append(WorkerThreadPool.add_task(func(): _make_track(key)))


## the glass sounds go through a little reverb, so they ring in the space you are in
func _bus() -> void:
	var idx := AudioServer.get_bus_index("Fx")
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Fx")
		AudioServer.set_bus_send(idx, "Master")
		var rv := AudioEffectReverb.new()
		rv.room_size = 0.45
		rv.damping = 0.55
		rv.wet = 0.14
		rv.dry = 1.0
		AudioServer.add_bus_effect(idx, rv)
	for p in players:
		p.bus = "Fx"
	# the music rings in a big, dark room
	var mi := AudioServer.get_bus_index("Music")
	if mi < 0:
		AudioServer.add_bus()
		mi = AudioServer.bus_count - 1
		AudioServer.set_bus_name(mi, "Music")
		AudioServer.set_bus_send(mi, "Master")
		var mv := AudioEffectReverb.new()
		mv.room_size = 0.85
		mv.damping = 0.6
		mv.wet = 0.3
		mv.dry = 1.0
		AudioServer.add_bus_effect(mi, mv)
	for p in [music, music_old, pulse]:
		p.bus = "Music"


func _exit_tree() -> void:
	# let background sound building finish before the engine shuts down (the music not yet begun is left for next time)
	_quitting = true
	for t in _tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_tasks.clear()


func _make_track(key: String) -> void:
	var w := _kept_track(key)
	if w == null:
		w = _track(TRACKS[key])
		_keep_track(key, w)
	_mutex.lock()
	tracks[key] = w
	_mutex.unlock()


# a made track is kept in the game's own folder and read back next time; raise this when the music changes
const MUSIC_KEEP := 1


func _track_path(key: String) -> String:
	return "user://music_%s_%d_%d.pcm" % [key, MUSIC_KEEP, hash(TRACKS[key])]


func _kept_track(key: String) -> AudioStreamWAV:
	var f := FileAccess.open(_track_path(key), FileAccess.READ)
	if f == null:
		return null
	var n := f.get_32()
	var data := f.get_buffer(n)
	if n == 0 or data.size() != n:
		return null
	return _wav_bytes(data, MRATE, true)


func _keep_track(key: String, w: AudioStreamWAV) -> void:
	var f := FileAccess.open(_track_path(key), FileAccess.WRITE)
	if f == null:
		return
	f.store_32(w.data.size())
	f.store_buffer(w.data)


func set_music(on: bool) -> void:
	music_on = on
	if not on:
		music.stop()
		music_old.stop()
	else:
		music.stream = null


## how badly the run is going, 0..1: a slow heartbeat under the music, quicker and louder the worse it gets.
## The game says it every frame; when it stops saying it (menu, pause, the end) the heartbeat fades away.
func set_tension(k: float) -> void:
	_tension = clampf(k, 0.0, 1.0)
	_tension_at = Time.get_ticks_msec()
	_tension_frame = Engine.get_process_frames()


## where the beat is now, 0..1
func beat_phase(t: float) -> float:
	var beat := 60.0 / _bpm
	if music.playing:
		return fmod(music.get_playback_position() / beat, 1.0)
	return fmod(t / beat, 1.0)


# only the sounds of the game itself: the ball, and glass; everything else is the music
const ALLOWED := ["shatter0", "shatter1", "shatter2", "heavy", "thud", "crack", "crash", "throw", "roll"]
var _alts := {}


func play(name: String, db := 0.0, pitch := 1.0) -> void:
	if not sound_on or not _ready_sfx or not (name in ALLOWED):
		return
	if _alts.has(name):
		name = _alts[name].pick_random()
	if not streams.has(name):
		return
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


## a note of a scale, higher each time (for things breaking one after another)
func note(_n: int) -> void:
	pass


# ---------- making sounds ----------
func _wav(buf: PackedFloat32Array, rate := RATE, loop := false) -> AudioStreamWAV:
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var k := 0.92 / peak
	var b := PackedByteArray()
	b.resize(buf.size() * 2)
	for i in buf.size():
		b.encode_s16(i * 2, int(clampf(buf[i] * k, -1.0, 1.0) * 32000.0))
	return _wav_bytes(b, rate, loop)


## 16-bit mono samples as a sound
func _wav_bytes(b: PackedByteArray, rate := RATE, loop := false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = b.size() / 2
	return w


func _buf(sec: float, rate := RATE) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(sec * rate))
	return b


func _ping(b: PackedFloat32Array, t0: float, f: float, amp: float, decay: float, len := 0.18) -> void:
	var s := int(t0 * RATE)
	var e := mini(b.size(), s + int(len * RATE))
	var w := TAU * f / RATE
	for i in range(s, e):
		var k := i - s
		b[i] += sin(w * k) * amp * exp(-float(k) / RATE * decay)


func _noise(b: PackedFloat32Array, t0: float, len: float, amp: float, decay: float, lp := 1.0) -> void:
	var s := int(t0 * RATE)
	var e := mini(b.size(), s + int(len * RATE))
	var y := 0.0
	for i in range(s, e):
		y += ((randf() * 2.0 - 1.0) - y) * lp
		b[i] += y * amp * exp(-float(i - s) / RATE * decay)


## glass breaking, in layers: the first sharp crack, the fracture running through it, the glass ringing,
## and then the pieces landing, fewer and fewer. big runs from 0 (a small pane) to 1 (a big one)
func _shatter(big: float) -> PackedFloat32Array:
	var b := _buf(1.15)
	# the crack: a sharp click of bright noise
	var prev := 0.0
	for i in int(RATE * 0.006):
		var nz := randf() * 2.0 - 1.0
		b[i] += (nz - prev) * (1.0 - float(i) / (RATE * 0.006)) * 0.9
		prev = nz
	# the fracture running through: little bursts close together
	for k in 3 + int(big * 6.0):
		var t0 := randf_range(0.002, 0.03 + 0.09 * big)
		var s0 := int(t0 * RATE)
		var ln := int(randf_range(0.004, 0.014) * RATE)
		prev = 0.0
		for i in ln:
			if s0 + i >= b.size():
				break
			var nz := randf() * 2.0 - 1.0
			b[s0 + i] += (nz - prev) * 0.55 * exp(-float(i) / ln * 3.0)
			prev = nz
	# the body of it: bright noise falling away
	prev = 0.0
	for i in b.size():
		var t := float(i) / RATE
		var nz := randf() * 2.0 - 1.0
		b[i] += (nz - prev * 0.6) * 0.42 * exp(-t * (16.0 - 7.0 * big))
		prev = nz
	# the glass ringing for a moment
	for k in 5:
		var f := randf_range(1500.0, 4200.0) if big > 0.6 else randf_range(2400.0, 6800.0)
		_ping(b, randf_range(0.0, 0.01), f, randf_range(0.06, 0.13), randf_range(22.0, 45.0), 0.4)
	# a low knock for big panes
	for i in int(RATE * 0.16):
		var t := float(i) / RATE
		b[i] += sin(TAU * (90.0 + 40.0 * (1.0 - big)) * t) * 0.35 * big * exp(-t * 26.0)
	# the pieces landing: many at first, fewer later, each a tiny click and ring
	for k in 24 + int(big * 30.0):
		var t0 := 0.07 + pow(randf(), 1.8) * (0.55 + 0.4 * big)
		var amp := randf_range(0.03, 0.11) * (1.0 - t0 * 0.7)
		_noise(b, t0, 0.004, amp * 1.5, 900.0, 0.8)
		_ping(b, t0, randf_range(2600.0, 9000.0), amp, randf_range(55.0, 120.0), 0.06)
	return b


## thick glass giving way: a low crunch, a thump, heavy chunks landing
func _heavy() -> PackedFloat32Array:
	var b := _buf(1.1)
	_noise(b, 0.0, 0.5, 0.9, 11.0, 0.12)
	_noise(b, 0.0, 0.08, 0.5, 40.0, 0.5)
	for i in int(RATE * 0.35):
		var t := float(i) / RATE
		b[i] += sin(TAU * (95.0 - 50.0 * t) * t) * 0.9 * exp(-t * 11.0)
	for k in 10:
		_ping(b, pow(randf(), 1.4) * 0.35, randf_range(1100.0, 3200.0), randf_range(0.05, 0.12), randf_range(20.0, 35.0), 0.16)
	for k in 7:
		var t0 := randf_range(0.25, 0.8)
		_noise(b, t0, 0.05, randf_range(0.25, 0.45), 70.0, 0.25)
		_ping(b, t0, randf_range(380.0, 820.0), 0.18, 40.0, 0.06)
	return b


func _build_all() -> void:
	streams["heavy"] = _wav(_heavy())
	# into a new room: a rush of air and a bright chord
	var rm := _buf(1.4)
	var lpv := 0.0
	for i in rm.size():
		var t := float(i) / RATE
		lpv += ((randf() * 2.0 - 1.0) - lpv) * (0.03 + 0.25 * minf(1.0, t / 0.5))
		rm[i] = lpv * 0.5 * sin(PI * minf(1.0, t / 0.9))
	for f in [523.25, 659.25, 783.99, 1046.5, 1318.5]:
		_ping(rm, 0.45, f, 0.12, 2.5, 0.95)
	streams["room"] = _wav(rm)
	# a marble knocking on thick glass that holds
	var th := _buf(0.35)
	_noise(th, 0.0, 0.06, 0.6, 60.0, 0.2)
	for i in th.size():
		var t := float(i) / RATE
		th[i] += sin(TAU * 170.0 * t) * 0.7 * exp(-t * 26.0)
	_ping(th, 0.0, 2200.0, 0.12, 45.0)
	streams["thud"] = _wav(th)
	# three of each size, so the same pane never sounds quite the same twice
	for v in 3:
		var names := []
		for k in 3:
			var nm := "shatter%d_%d" % [v, k]
			streams[nm] = _wav(_shatter([1.0, 0.65, 0.3][v] + randf_range(-0.08, 0.08)))
			names.append(nm)
		_alts["shatter%d" % v] = names
	# an iron ball landing and rolling
	var rl := _buf(0.4)
	for i in rl.size():
		var t := float(i) / RATE
		rl[i] = sin(TAU * 140.0 * t) * 0.6 * exp(-t * 18.0) + sin(TAU * 520.0 * t) * 0.2 * exp(-t * 40.0)
	_noise(rl, 0.0, 0.3, 0.25, 12.0, 0.08)
	streams["roll"] = _wav(rl)
	var c := _buf(0.3)
	_noise(c, 0.0, 0.3, 0.6, 90.0)
	for i in c.size():
		var t := float(i) / RATE
		c[i] += sin(TAU * 95.0 * t) * 0.5 * exp(-t * 22.0)
	_ping(c, 0.0, 3100.0, 0.25, 30.0)
	_ping(c, 0.01, 4700.0, 0.18, 40.0)
	streams["crack"] = _wav(c)
	var s := _buf(0.18)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.18
		s[i] = lp * sin(PI * t / 0.18)
	streams["throw"] = _wav(s)
	var cr := _buf(0.8)
	for f in [1318.5, 1661.2, 1975.5, 2637.0]:
		_ping(cr, 0.0, f, 0.22, 5.5, 0.8)
	for k in 6:
		_ping(cr, randf() * 0.25, randf_range(3500.0, 7000.0), 0.06, 25.0, 0.15)
	streams["crystal"] = _wav(cr)
	var cs := _shatter(1.0)
	for i in int(RATE * 0.45):
		var t := float(i) / RATE
		cs[i] += sin(TAU * (70.0 - 30.0 * t) * t) * 1.1 * exp(-t * 7.0)
	streams["crash"] = _wav(cs)
	var cp := _buf(1.6)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		var w: float = TAU * f / RATE
		for i in cp.size():
			var t := float(i) / RATE
			cp[i] += sin(w * i) * 0.2 * minf(1.0, t / 0.12) * exp(-t * 1.8)
	streams["checkpoint"] = _wav(cp)
	var up := _buf(0.6)
	var notes := [880.0, 1108.7, 1318.5, 1760.0]
	for k in notes.size():
		_ping(up, k * 0.08, notes[k], 0.25, 9.0, 0.4)
	streams["multi"] = _wav(up)
	var tk := _buf(0.08)
	_ping(tk, 0.0, 1400.0, 0.4, 60.0, 0.08)
	streams["tick"] = _wav(tk)
	# a mirror ringing
	var rg := _buf(0.9)
	for f in [1760.0, 2794.0, 3520.0]:
		_ping(rg, 0.0, f, 0.2, 6.0, 0.9)
	_noise(rg, 0.0, 0.05, 0.3, 60.0)
	streams["ring"] = _wav(rg)
	# a prism: a rising shimmer
	var pr := _buf(1.0)
	for k in 10:
		_ping(pr, k * 0.04, 880.0 * pow(2.0, k / 7.0), 0.12, 7.0, 0.6)
	streams["prism"] = _wav(pr)
	# a blast: a low boom
	var bm := _buf(0.9)
	for i in bm.size():
		var t := float(i) / RATE
		bm[i] = sin(TAU * (55.0 + 60.0 * exp(-t * 8.0)) * t) * exp(-t * 4.0)
	_noise(bm, 0.0, 0.6, 0.5, 9.0, 0.3)
	streams["boom"] = _wav(bm)
	# glass creaking as it bends or swings
	var ck := _buf(0.5)
	for i in ck.size():
		var t := float(i) / RATE
		var f := 300.0 + 180.0 * sin(t * 9.0)
		ck[i] = sin(TAU * f * t) * 0.25 * sin(PI * t / 0.5) * (0.7 + 0.3 * sin(t * 140.0))
	streams["creak"] = _wav(ck)
	# a steel grille going up
	var cl := _buf(0.5)
	_noise(cl, 0.0, 0.08, 0.8, 40.0)
	for f in [420.0, 610.0, 890.0]:
		_ping(cl, 0.0, f, 0.25, 9.0, 0.5)
	streams["clank"] = _wav(cl)
	# electricity
	var zp := _buf(0.12)
	_noise(zp, 0.0, 0.12, 0.7, 20.0)
	for i in zp.size():
		zp[i] *= 0.6 + 0.4 * signf(sin(float(i) / RATE * TAU * 90.0))
	streams["zap"] = _wav(zp)
	# notes up a pentatonic scale
	var scale := [0, 2, 4, 7, 9, 12, 14, 16, 19, 21]
	for k in scale.size():
		var nb := _buf(0.45)
		var f := 784.0 * pow(2.0, scale[k] / 12.0)
		_ping(nb, 0.0, f, 0.3, 8.0, 0.45)
		_ping(nb, 0.0, f * 2.01, 0.1, 14.0, 0.3)
		streams["note%d" % k] = _wav(nb)
	# a heartbeat: two soft low thumps a second
	var hb := _buf(1.0)
	for thump in [[0.0, 1.0], [0.3, 0.6]]:
		var t0 := int(float(thump[0]) * RATE)
		for i in int(0.35 * RATE):
			var t := float(i) / RATE
			hb[t0 + i] += sin(TAU * (62.0 - 22.0 * t) * t) * float(thump[1]) * exp(-t * 11.0)
	streams["pulse"] = _wav(hb, RATE, true)
	_ready_sfx = true
	if not shorts:
		_all_music()


## every world's music, one after another, in the background as the game starts (or read back from the phone, where it
## was kept the first time), so none of it is made in the middle of a run as you come into a new world
func _all_music() -> void:
	for key in TRACKS:
		if _quitting:
			return
		_mutex.lock()
		var have: bool = tracks.has(key) or _building.has(key)
		if not have:
			_building[key] = true
		_mutex.unlock()
		if not have:
			_make_track(key)


## the pitch of a degree of a track's key (0 is the tonic, 7 the octave above it, -1 the note below it)
func _deg(P: Dictionary, d: int) -> float:
	var semis: Array = P.scale
	return float(P.root) * pow(2.0, (float(semis[posmod(d, 7)]) + 12.0 * floorf(d / 7.0)) / 12.0)


## an 8-bar loop in a minor key: a slow pad that swells on each chord, a low note under it, a deep drone and a few
## soft piano notes that ring on. Everything that rings past the end of the loop is wrapped round to its start.
func _track(P: Dictionary) -> AudioStreamWAV:
	var beat := 60.0 / float(P.bpm)
	var n := int(beat * 32.0 * MRATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var roots: Array = P.chords
	var seg := beat * 8.0
	for c in 4:
		var r: int = roots[c]
		var up := 7 if r < 3 else 0
		var w0 := TAU * _deg(P, r - 7 if r >= 3 else r)
		var w1 := TAU * _deg(P, r + up)
		var w2 := TAU * _deg(P, r + up + 2)
		var w3 := TAU * _deg(P, r + up + 4)
		var s0 := int(c * seg * MRATE)
		for i in int(seg * 1.5 * MRATE):
			var u := float(i) / MRATE
			var e := 1.0
			if u < seg * 0.35:
				e = sin(PI * 0.5 * u / (seg * 0.35))
				e *= e
			elif u > seg:
				e = cos(PI * 0.5 * (u - seg) / (seg * 0.5))
				e *= e
			var v := (sin(w1 * 0.998 * u) + sin(w1 * 1.002 * u)) * 0.045 + sin(w2 * u) * 0.05 + sin(w3 * u) * 0.05 + sin(w0 * u) * 0.15
			b[(s0 + i) % n] += v * e
	# a drone an octave under the tonic, tuned so that it joins up at the loop's end
	var wd := TAU * roundf(float(P.root) * 0.5 * n / MRATE) / n
	for i in n:
		b[i] += sin(wd * i) * 0.05
	for m in P.melody:
		var f := _deg(P, int(m[1]))
		var w := TAU * f / MRATE
		var amp := 0.2 * float(m[3])
		var dec := 0.9 + f / 880.0
		var k1 := exp(-dec / MRATE)
		var k2 := exp(-dec * 1.7 / MRATE)
		var k3 := exp(-dec * 2.6 / MRATE)
		var e1 := 1.0
		var e2 := 1.0
		var e3 := 1.0
		var s0 := int(float(m[0]) * beat * MRATE)
		for i in int(3.4 * MRATE):
			var v := sin(w * i) * e1 + 0.42 * sin(w * 2.0 * i) * e2 + 0.16 * sin(w * 3.0 * i) * e3
			b[(s0 + i) % n] += v * amp * minf(1.0, i / (0.004 * MRATE))
			e1 *= k1
			e2 *= k2
			e3 *= k3
	return _wav(b, MRATE, true)
