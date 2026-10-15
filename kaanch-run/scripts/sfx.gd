## Every sound is made here when the game starts (no sound files): breaking glass, cracks, the throw,
## crystals, the crash, checkpoints, and a looping beat with soft chords.
class_name Sfx
extends Node

const RATE := 22050
const MRATE := 16000

var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer
var sound_on := true
var music_on := true
var _next := 0
var _ready_sfx := false
var _music_stream: AudioStreamWAV


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -8.0
	add_child(music)
	WorkerThreadPool.add_task(_build_all)


func _process(_d: float) -> void:
	if _music_stream and music.stream == null:
		music.stream = _music_stream
		if music_on:
			music.play()


func set_music(on: bool) -> void:
	music_on = on
	if not music.stream:
		return
	if on and not music.playing:
		music.play()
	elif not on:
		music.stop()


func play(name: String, db := 0.0, pitch := 1.0) -> void:
	if not sound_on or not _ready_sfx or not streams.has(name):
		return
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = streams[name]
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


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


# a bright little ping added in at time t0
func _ping(b: PackedFloat32Array, t0: float, f: float, amp: float, decay: float, len := 0.18) -> void:
	var s := int(t0 * RATE)
	var e := mini(b.size(), s + int(len * RATE))
	var w := TAU * f / RATE
	for i in range(s, e):
		var k := i - s
		b[i] += sin(w * k) * amp * exp(-float(k) / RATE * decay)


func _shatter(big: float) -> PackedFloat32Array:
	var b := _buf(0.9)
	var prev := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var nz := randf() * 2.0 - 1.0
		var hp := nz - prev * 0.7
		prev = nz
		b[i] = hp * 0.55 * exp(-t * (10.0 + 6.0 * (1.0 - big))) + nz * 0.25 * exp(-t * 45.0)
	# the body of the break
	for i in int(RATE * 0.12):
		var t := float(i) / RATE
		b[i] += sin(TAU * (150.0 - 420.0 * t) * t) * 0.4 * big * exp(-t * 28.0)
	# glittering pieces
	for k in 22:
		_ping(b, pow(randf(), 1.7) * 0.5, randf_range(2300.0, 7600.0), randf_range(0.05, 0.16), randf_range(18.0, 40.0), 0.14)
	return b


func _build_all() -> void:
	streams["shatter0"] = _wav(_shatter(1.0))
	streams["shatter1"] = _wav(_shatter(0.7))
	streams["shatter2"] = _wav(_shatter(0.45))
	# a crack in thick glass: a sharp tick and a dull knock
	var c := _buf(0.3)
	for i in c.size():
		var t := float(i) / RATE
		c[i] = (randf() * 2.0 - 1.0) * 0.6 * exp(-t * 90.0) + sin(TAU * 95.0 * t) * 0.5 * exp(-t * 22.0)
	_ping(c, 0.0, 3100.0, 0.25, 30.0)
	_ping(c, 0.01, 4700.0, 0.18, 40.0)
	streams["crack"] = _wav(c)
	# the throw: a short soft rush of air
	var s := _buf(0.18)
	var lp := 0.0
	for i in s.size():
		var t := float(i) / RATE
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.18
		s[i] = lp * sin(PI * t / 0.18)
	streams["throw"] = _wav(s)
	# a crystal: a bright chord
	var cr := _buf(0.8)
	for f in [1318.5, 1661.2, 1975.5, 2637.0]:
		_ping(cr, 0.0, f, 0.22, 5.5, 0.8)
	for k in 6:
		_ping(cr, randf() * 0.25, randf_range(3500.0, 7000.0), 0.06, 25.0, 0.15)
	streams["crystal"] = _wav(cr)
	# a crash: a deep thump under breaking glass
	var cs := _shatter(1.0)
	for i in int(RATE * 0.45):
		var t := float(i) / RATE
		cs[i] += sin(TAU * (70.0 - 30.0 * t) * t) * 1.1 * exp(-t * 7.0)
	streams["crash"] = _wav(cs)
	# a checkpoint: a warm chord that swells
	var cp := _buf(1.6)
	for f in [523.25, 659.25, 783.99, 1046.5]:
		var w: float = TAU * f / RATE
		for i in cp.size():
			var t := float(i) / RATE
			cp[i] += sin(w * i) * 0.2 * minf(1.0, t / 0.12) * exp(-t * 1.8)
	streams["checkpoint"] = _wav(cp)
	# more pebbles per throw: a quick rising run
	var up := _buf(0.6)
	var notes := [880.0, 1108.7, 1318.5, 1760.0]
	for k in notes.size():
		_ping(up, k * 0.08, notes[k], 0.25, 9.0, 0.4)
	streams["multi"] = _wav(up)
	# a button
	var tk := _buf(0.08)
	_ping(tk, 0.0, 1400.0, 0.4, 60.0, 0.08)
	streams["tick"] = _wav(tk)
	_ready_sfx = true
	_music_stream = _build_music()


## a 4-bar loop at 100 beats a minute: soft chords, a bass note, a kick on the beat, ticks between
func _build_music() -> AudioStreamWAV:
	var bpm := 100.0
	var beat := 60.0 / bpm
	var n := int(beat * 16.0 * MRATE)
	var b := PackedFloat32Array()
	b.resize(n)
	var chords := [[220.0, 261.63, 329.63], [174.61, 220.0, 261.63], [196.0, 261.63, 329.63], [196.0, 246.94, 293.66]]
	var bar := beat * 4.0
	for i in n:
		var t := float(i) / MRATE
		var ci := int(t / bar) % 4
		var tb := fmod(t, bar)
		var ch: Array = chords[ci]
		var env := pow(sin(PI * tb / bar), 0.6)
		var v := 0.0
		for f in ch:
			v += sin(TAU * f * t) * 0.05 + sin(TAU * f * 1.004 * t) * 0.04
		v *= env
		# bass on the beat
		var tbeat := fmod(t, beat)
		var root: float = ch[0] * 0.5
		v += sin(TAU * root * t) * 0.16 * exp(-tbeat * 3.0)
		# kick
		var kf := 48.0 + 95.0 * exp(-tbeat * 30.0)
		v += sin(TAU * kf * tbeat) * 0.42 * exp(-tbeat * 10.0)
		# a tick halfway between beats
		var toff := fmod(t + beat * 0.5, beat)
		if toff < 0.05:
			v += (randf() * 2.0 - 1.0) * 0.07 * exp(-toff * 80.0)
		# a little pluck on the eighths, going up the chord
		var e8 := beat * 0.5
		var k8 := int(t / e8) % 3
		var t8 := fmod(t, e8)
		v += sin(TAU * float(ch[k8]) * 2.0 * t8) * 0.06 * exp(-t8 * 9.0)
		b[i] = v
	return _wav(b, MRATE, true)
