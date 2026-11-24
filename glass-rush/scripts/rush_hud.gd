## The screens of Glass Rush, all made in code: the title, the score while you fly (shields, boost), pause, the end.
class_name RushHud
extends CanvasLayer

signal play_pressed
signal pause_pressed
signal resume_pressed
signal menu_pressed
signal setting_changed(key: String, value: bool)

const INK := Color(0.96, 0.98, 1.0)
const ACCENT := Color("3fe0ff")
const HOT := Color("ff3fd0")
const GOLD := Color("ffd36b")

var f600: Font
var f800: Font
var root: Control
var play_ui: Control
var menu: Control
var pause_panel: Control
var over_panel: Control
var score_label: Label
var dist_label: Label
var toast_label: Label
var flash_rect: ColorRect
var pips: Pips
var bar: BoostBar
var best_label: Label
var tap_label: Label
var over_score: Label
var over_sub: Label
var over_badge: Label
var music_btn: Button
var sound_btn: Button
var opts := {}
var _toast_tw: Tween
var _flash_tw: Tween


func _ready() -> void:
	f600 = load("res://fonts/bricolage-600.woff2")
	f800 = load("res://fonts/bricolage-800.woff2")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1, 1, 1, 0)
	root.add_child(flash_rect)
	_build_play()
	_build_menu()
	_build_pause()
	_build_over()


func _label(text: String, font: Font, size: int, col := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, primary: bool, w := 420) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, 92)
	b.add_theme_font_override("font", f800)
	b.add_theme_font_size_override("font_size", 34)
	var col := ACCENT if primary else Color(0.05, 0.06, 0.1, 0.75)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col if st != "pressed" else col.darkened(0.2)
		sb.set_corner_radius_all(46)
		if not primary:
			sb.border_color = Color(1, 1, 1, 0.3)
			sb.set_border_width_all(3)
		b.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, Color("0a0614") if primary else INK)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return b


func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	root.add_child(c)
	return c


func _column(parent: Control, dim := 0.0) -> VBoxContainer:
	if dim > 0.0:
		var shade := ColorRect.new()
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.color = Color(0.02, 0.01, 0.05, dim)
		parent.add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 22)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(col)
	return col


# ---------- while you fly ----------
func _build_play() -> void:
	play_ui = _screen()
	play_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	score_label = _label("0", f800, 76)
	score_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	score_label.offset_top = 70
	play_ui.add_child(score_label)
	dist_label = _label("0 m", f600, 26, Color(1, 1, 1, 0.7))
	dist_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	dist_label.offset_top = 166
	play_ui.add_child(dist_label)
	pips = Pips.new()
	pips.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pips.position = Vector2(34, 70)
	pips.size = Vector2(150, 50)
	play_ui.add_child(pips)
	var pb := Button.new()
	pb.text = "II"
	pb.add_theme_font_override("font", f800)
	pb.add_theme_font_size_override("font_size", 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.1, 0.5)
	sb.set_corner_radius_all(40)
	sb.border_color = Color(1, 1, 1, 0.3)
	sb.set_border_width_all(3)
	for st in ["normal", "hover", "pressed", "focus"]:
		pb.add_theme_stylebox_override(st, sb)
	pb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pb.offset_left = -114
	pb.offset_right = -34
	pb.offset_top = 64
	pb.offset_bottom = 144
	pb.pressed.connect(func(): pause_pressed.emit())
	play_ui.add_child(pb)
	bar = BoostBar.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -170
	bar.offset_right = 170
	bar.offset_top = -90
	bar.offset_bottom = -66
	play_ui.add_child(bar)
	toast_label = _label("", f800, 44, GOLD)
	toast_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 230
	toast_label.modulate.a = 0.0
	play_ui.add_child(toast_label)


func set_play(score: int, shields: int, boost: float, boosting: bool, d: int) -> void:
	score_label.text = str(score)
	dist_label.text = ("%.2f km" % (d / 1000.0)) if d >= 1000 else ("%d m" % d)
	if pips.n != shields:
		pips.n = shields
		pips.queue_redraw()
	if absf(bar.k - boost) > 0.005 or bar.on != boosting:
		bar.k = clampf(boost, 0.0, 1.0)
		bar.on = boosting
		bar.queue_redraw()


func toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.pivot_offset = toast_label.size * 0.5
	toast_label.scale = Vector2(1.25, 1.25)
	if _toast_tw:
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(toast_label, "scale", Vector2.ONE, 0.12)
	_toast_tw.tween_interval(0.6)
	_toast_tw.tween_property(toast_label, "modulate:a", 0.0, 0.3)


func flash(col: Color) -> void:
	flash_rect.color = Color(col, 0.4)
	if _flash_tw:
		_flash_tw.kill()
	_flash_tw = create_tween()
	_flash_tw.tween_property(flash_rect, "color:a", 0.0, 0.45)


# ---------- the title ----------
func _build_menu() -> void:
	menu = _screen()
	var col := _column(menu)
	var title := _label("GLASS", f800, 140)
	title.add_theme_constant_override("outline_size", 0)
	col.add_child(title)
	var sub := _label("R  U  S  H", f800, 48, HOT)
	sub.add_theme_constant_override("outline_size", 0)
	col.add_child(sub)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 120)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(gap)
	tap_label = _label("TAP TO FLY", f800, 44, ACCENT)
	col.add_child(tap_label)
	best_label = _label("", f600, 28, Color(1, 1, 1, 0.75))
	col.add_child(best_label)
	var hint := _label("drag to steer · smash the thin glass · miss the thick", f600, 22, Color(1, 1, 1, 0.55))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)
	# tap anywhere (but the buttons) to fly
	var hit := Button.new()
	hit.flat = true
	hit.set_anchors_preset(Control.PRESET_FULL_RECT)
	hit.focus_mode = Control.FOCUS_NONE
	hit.pressed.connect(func(): play_pressed.emit())
	menu.add_child(hit)
	menu.move_child(hit, 0)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -150
	row.offset_bottom = -60
	row.offset_left = -300
	row.offset_right = 300
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	menu.add_child(row)
	music_btn = _button("", false, 260)
	music_btn.pressed.connect(func(): _toggle("music"))
	row.add_child(music_btn)
	sound_btn = _button("", false, 260)
	sound_btn.pressed.connect(func(): _toggle("sound"))
	row.add_child(sound_btn)
	var tw := create_tween().set_loops()
	tw.tween_property(tap_label, "modulate:a", 0.45, 0.7)
	tw.tween_property(tap_label, "modulate:a", 1.0, 0.7)


func _toggle(key: String) -> void:
	opts[key] = not bool(opts.get(key, true))
	setting_changed.emit(key, opts[key])
	_paint_settings()


func apply_settings(save: Dictionary) -> void:
	opts = save
	_paint_settings()


func _paint_settings() -> void:
	music_btn.text = "MUSIC " + ("ON" if opts.get("music", true) else "OFF")
	sound_btn.text = "SOUND " + ("ON" if opts.get("sound", true) else "OFF")
	music_btn.add_theme_font_size_override("font_size", 24)
	sound_btn.add_theme_font_size_override("font_size", 24)


# ---------- pause and the end ----------
func _build_pause() -> void:
	pause_panel = _screen()
	var col := _column(pause_panel, 0.55)
	col.add_child(_label("PAUSED", f800, 72))
	var r := _button("RESUME", true)
	r.pressed.connect(func(): resume_pressed.emit())
	col.add_child(r)
	var m := _button("MENU", false)
	m.pressed.connect(func(): menu_pressed.emit())
	col.add_child(m)


func _build_over() -> void:
	over_panel = _screen()
	var col := _column(over_panel, 0.5)
	col.add_child(_label("CRASHED", f800, 40, Color(1, 1, 1, 0.75)))
	over_score = _label("0", f800, 120)
	col.add_child(over_score)
	over_badge = _label("NEW BEST", f800, 36, GOLD)
	col.add_child(over_badge)
	over_sub = _label("", f600, 28, Color(1, 1, 1, 0.75))
	col.add_child(over_sub)
	var a := _button("FLY AGAIN", true)
	a.pressed.connect(func(): play_pressed.emit())
	col.add_child(a)
	var m := _button("MENU", false)
	m.pressed.connect(func(): menu_pressed.emit())
	col.add_child(m)


# ---------- switching ----------
func _hide_all() -> void:
	for c in [play_ui, menu, pause_panel, over_panel]:
		c.visible = false


func show_menu(best: int) -> void:
	_hide_all()
	best_label.text = ("BEST  %d" % best) if best > 0 else ""
	menu.visible = true


func show_play() -> void:
	_hide_all()
	play_ui.visible = true
	toast_label.modulate.a = 0.0


func show_pause() -> void:
	pause_panel.visible = true


func show_over(score: int, d: int, best: int, new_best: bool) -> void:
	await get_tree().create_timer(1.1).timeout
	_hide_all()
	over_score.text = str(score)
	over_badge.visible = new_best
	var km := ("%.2f km" % (d / 1000.0)) if d >= 1000 else ("%d m" % d)
	over_sub.text = km + ("" if new_best else "   ·   BEST %d" % best)
	over_panel.visible = true


## the phone's back button: nothing here sits on top of another screen
func back() -> bool:
	return false


## the shields: three little diamonds, lit for each one left
class Pips extends Control:
	var n := 3

	func _draw() -> void:
		for i in 3:
			var c := Vector2(22 + i * 44, 22)
			var pts := PackedVector2Array([c + Vector2(0, -18), c + Vector2(16, 0), c + Vector2(0, 18), c + Vector2(-16, 0)])
			draw_colored_polygon(pts, Color("5fffb0") if i < n else Color(1, 1, 1, 0.15))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color(1, 1, 1, 0.6), 2.0)


## crystals towards the next boost; while boosting, how much is left
class BoostBar extends Control:
	var k := 0.0
	var on := false

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(1, 1, 1, 0.12))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * k, size.y)), Color("ff3fd0") if on else Color("3fe0ff"))
		draw_rect(r, Color(1, 1, 1, 0.4), false, 2.0)
