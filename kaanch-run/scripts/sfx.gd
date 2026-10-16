## Every sound is made here when the game starts (no sound files): breaking glass, cracks, the throw, jars,
## the crash, a prism, a blast, and a looping piece of music for each world (made the first time it is needed).
class_name Sfx
extends Node

const RATE := 22050
const MRATE := 16000

# each world's music: tempo, four chords, the colour of the pads, the plucked instrument, drums
const TRACKS := {
	"menu": {"bpm": 88.0, "chords": [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [196.0, 261.63, 329.63], [196.0, 246.94, 293.66]], "harm": [[1.0, 0.05], [2.0, 0.015]], "pluck": "bell", "arp": [0, 1, 2, 1], "kick": 0.25, "tak": 0.0, "drone": 0.0},
	"cathedral": {"bpm": 84.0, "chords": [[146.83, 174.61, 220.0], [116.54, 146.83, 174.61], [174.61, 220.0, 261.63], [130.81, 164.81, 196.0]], "harm": [[1.0, 0.05], [2.0, 0.03], [3.0, 0.018]], "pluck": "bell", "arp": [0, 2, 1, 2], "kick": 0.35, "tak": 0.0, "drone": 0.0},
	"venice": {"bpm": 104.0, "chords": [[261.63, 329.63, 392.0], [220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [196.0, 246.94, 293.66]], "harm": [[1.0, 0.04], [2.0, 0.012]], "pluck": "mandolin", "arp": [0, 1, 2, 1, 2, 1], "kick": 0.4, "tak": 0.06, "drone": 0.0},
	"lanterns": {"bpm": 92.0, "chords": [[220.0, 261.63, 329.63], [196.0, 246.94, 293.66], [164.81, 196.0, 246.94], [220.0, 293.66, 329.63]], "harm": [[1.0, 0.04], [0.5, 0.03]], "pluck": "koto", "arp": [0, 2, 1, 2, 0, 1], "kick": 0.3, "tak": 0.05, "drone": 0.0},
	"mosaic": {"bpm": 98.0, "chords": [[164.81, 196.0, 246.94], [174.61, 220.0, 261.63], [196.0, 246.94, 293.66], [174.61, 220.0, 261.63]], "harm": [[1.0, 0.04], [2.0, 0.02]], "pluck": "oud", "arp": [0, 1, 0, 2, 1, 0], "kick": 0.45, "tak": 0.12, "drone": 82.41},
	"sheesh": {"bpm": 96.0, "chords": [[130.81, 164.81, 196.0], [138.59, 174.61, 207.65], [130.81, 164.81, 196.0], [123.47, 155.56, 196.0]], "harm": [[1.0, 0.035], [2.0, 0.02]], "pluck": "sitar", "arp": [0, 1, 2, 1, 0, 2], "kick": 0.38, "tak": 0.1, "drone": 65.41},
	"calm": {"bpm": 66.0, "chords": [[220.0, 277.18, 329.63], [185.0, 246.94, 293.66], [196.0, 246.94, 329.63], [174.61, 220.0, 277.18]], "harm": [[1.0, 0.06], [2.0, 0.015]], "pluck": "bell", "arp": [0, 2], "kick": 0.0, "tak": 0.0, "drone": 0.0},
}

var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var music_old: AudioStreamPlayer
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
	_tasks.append(WorkerThreadPool.add_task(_build_all))


func _process(dt: float) -> void:
	# fade the old music out
	if music_old.playing:
		music_old.volume_db -= dt * 30.0
		if music_old.volume_db < -50.0:
			music_old.stop()
	if music.playing and music.volume_db < -9.0:
		music.volume_db = minf(-9.0, music.volume_db + dt * 25.0)
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
	_want = key
	_mutex.lock()
	var have := tracks.has(key) or _building.has(key)
	if not have:
		_building[key] = true
	_mutex.unlock()
	if not have:
		_tasks.append(WorkerThreadPool.add_task(func(): _make_track(key)))


func _exit_tree() -> void:
	# let background sound building finish before the engine shuts down
	for t in _tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_tasks.clear()


func _make_track(key: String) -> void:
	var w := _track(TRACKS[key])
	_mutex.lock()
	tracks[key] = w
	_mutex.unlock()


func set_music(on: bool) -> void:
	music_on = on
	if not on:
		music.stop()
		music_old.stop()
	else:
		music.stream = null


## where the beat is now, 0..1
func set_pitch(p: float) -> void:
	music.pitch_scale = p
	music_old.pitch_scale = p


func beat_phase(t: float) -> float:
	var beat := 60.0 / _bpm
	if music.playing:
		return fmod(music.get_playback_position() / beat, 1.0)
	return fmod(t / beat, 1.0)


func play(name: String, db := 0.0, pitch := 1.0) -> void:
	if not sound_on or not _ready_sfx or not streams.has(name):
		return
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


## a note of a scale, higher each time (for things breaking one after another)
func note(n: int) -> void:
	play("note%d" % (n % 10), -6.0)


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
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = b
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = buf.size()
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


func _shatter(big: float) -> PackedFloat32Array:
	var b := _buf(0.95)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var nz := randf() * 2.0 - 1.0
		var hp := nz - prev * 0.7
		prev = nz
		b[i] = hp * 0.55 * exp(-t * (10.0 + 6.0 * (1.0 - big))) + nz * 0.25 * exp(-t * 45.0)
	for i in int(RATE * 0.12):
		var t := float(i) / RATE
		b[i] += sin(TAU * (150.0 - 420.0 * t) * t) * 0.45 * big * exp(-t * 28.0)
	# glittering pieces landing, and a few later ones bouncing
	for k in 22:
		_ping(b, pow(randf(), 1.7) * 0.5, randf_range(2300.0, 7600.0), randf_range(0.05, 0.16), randf_range(18.0, 40.0), 0.14)
	for k in 8:
		_ping(b, randf_range(0.35, 0.8), randf_range(3000.0, 6500.0), randf_range(0.02, 0.06), 35.0, 0.1)
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
	streams["shatter0"] = _wav(_shatter(1.0))
	streams["shatter1"] = _wav(_shatter(0.7))
	streams["shatter2"] = _wav(_shatter(0.45))
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
	_ready_sfx = true


## a 4-bar loop: soft chords, a bass note, an instrument plucking up the chord, drums
func _track(P: Dictionary) -> AudioStreamWAV:
	var bpm: float = P.bpm
	var beat := 60.0 / bpm
	var n := int(beat * 16.0 * MRATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var chords: Array = P.chords
	var harm: Array = P.harm
	var arp: Array = P.arp
	var kick: float = P.kick
	var tak: float = P.tak
	var drone: float = P.drone
	var pl: String = P.pluck
	var bar := beat * 4.0
	var step := beat * 0.5
	for i in n:
		var t := float(i) / MRATE
		var ci := int(t / bar) % 4
		var tb := fmod(t, bar)
		var ch: Array = chords[ci]
		var env := pow(sin(PI * tb / bar), 0.6)
		var v := 0.0
		for f in ch:
			for h in harm:
				v += sin(TAU * f * h[0] * t) * h[1]
		v *= env
		var tbeat := fmod(t, beat)
		var root: float = ch[0] * 0.5
		v += sin(TAU * root * t) * 0.14 * exp(-tbeat * 3.0)
		if drone > 0.0:
			v += (sin(TAU * drone * t) * 0.05 + sin(TAU * drone * 1.5 * t) * 0.025)
		if kick > 0.0:
			var kf := 48.0 + 95.0 * exp(-tbeat * 30.0)
			v += sin(TAU * kf * tbeat) * kick * exp(-tbeat * 10.0)
		if tak > 0.0:
			var toff := fmod(t + beat * 0.5, beat)
			if toff < 0.08:
				v += sin(TAU * 420.0 * toff) * tak * exp(-toff * 50.0) + (randf() * 2.0 - 1.0) * tak * 0.5 * exp(-toff * 90.0)
		# the plucked instrument on the eighths
		var k8 := int(t / step)
		var t8 := fmod(t, step)
		var nf: float = ch[int(arp[k8 % arp.size()]) % ch.size()] * 2.0
		match pl:
			"bell":
				v += (sin(TAU * nf * t8) + 0.3 * sin(TAU * nf * 2.76 * t8)) * 0.06 * exp(-t8 * 6.0)
			"mandolin":
				v += (sin(TAU * nf * t8) + 0.4 * sin(TAU * nf * 2.0 * t8)) * 0.06 * exp(-t8 * 10.0) * (0.7 + 0.3 * sin(t8 * 140.0))
			"koto":
				v += (sin(TAU * nf * t8) + 0.5 * sin(TAU * nf * 3.0 * t8)) * 0.065 * exp(-t8 * 7.0)
			"oud":
				v += (sin(TAU * nf * 0.5 * t8) + 0.6 * sin(TAU * nf * t8) + 0.3 * sin(TAU * nf * 1.5 * t8)) * 0.055 * exp(-t8 * 8.0)
			"sitar":
				var bz := sin(TAU * nf * t8 + 0.8 * sin(TAU * nf * 2.0 * t8))
				v += (bz + 0.4 * sin(TAU * nf * 3.01 * t8)) * 0.05 * exp(-t8 * 5.0)
		b[i] = v
	return _wav(b, MRATE, true)
