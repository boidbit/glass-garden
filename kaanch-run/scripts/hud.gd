## Everything on top of the game: the ball counter, the title screen, pause and the end card.
class_name Hud
extends CanvasLayer

signal start_pressed
signal resume_pressed
signal restart_pressed
signal continue_pressed
signal menu_pressed
signal pause_pressed
signal sound_toggled(on: bool)
signal music_toggled(on: bool)

const ACCENT := Color("5ff2dc")
const INK := Color("eef6f8")
const DARK := Color("062227")

var f600: Font
var f800: Font
var title_font: FontVariation
var ui_theme: Theme

var hud: Control
var ball_label: Label
var multi_label: Label
var dist_label: Label
var prog_fill: ColorRect
var toast: Label
var flash: ColorRect
var title: Control
var best_label: Label
var tap_label: Label
var pause_panel: Control
var over_panel: Control
var over_title: Label
var over_dist: Label
var over_best: Label
var cont_btn: Button
var snd_btns: Array[Button] = []
var mus_btns: Array[Button] = []
var sound_on := true
var music_on := true
var _toast_tw: Tween
var _flash_tw: Tween


func _ready() -> void:
	layer = 10
	f600 = load("res://fonts/bricolage-600.woff2")
	f800 = load("res://fonts/bricolage-800.woff2")
	title_font = FontVariation.new()
	title_font.base_font = f800
	title_font.spacing_glyph = 4
	_make_theme()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	_build_hud(root)
	_build_title(root)
	pause_panel = _build_pause(root)
	over_panel = _build_over(root)
	# darker corners, so the middle of the picture stands out
	var vg := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0, 0, 0, 0.38))
	g.add_point(0.55, Color(0, 0, 0, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.05, 1.05)
	vg.texture = gt
	vg.set_anchors_preset(Control.PRESET_FULL_RECT)
	vg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vg.stretch_mode = TextureRect.STRETCH_SCALE
	vg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(vg)
	root.move_child(vg, 0)
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1, 1, 1, 0)
	root.add_child(flash)
	show_title(0)


# ---------- look ----------
func _sb(bg: Color, r := 22, border := Color(0, 0, 0, 0), bw := 0, mx := 28, my := 14) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(r)
	if bw > 0:
		s.border_color = border
		s.set_border_width_all(bw)
	s.content_margin_left = mx
	s.content_margin_right = mx
	s.content_margin_top = my
	s.content_margin_bottom = my
	s.anti_aliasing = true
	return s


func _make_theme() -> void:
	var t := Theme.new()
	t.default_font = f600
	t.default_font_size = 28
	t.set_color("font_color", "Label", INK)
	t.set_stylebox("normal", "Button", _sb(Color(0.02, 0.03, 0.05, 0.55), 20, Color(1, 1, 1, 0.2), 2))
	t.set_stylebox("hover", "Button", _sb(Color(0.06, 0.08, 0.11, 0.7), 20, Color(1, 1, 1, 0.32), 2))
	t.set_stylebox("pressed", "Button", _sb(Color(0.1, 0.13, 0.17, 0.8), 20, Color(1, 1, 1, 0.38), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_font("font", "Button", f600)
	t.set_font_size("font_size", "Button", 28)
	t.set_type_variation("Primary", "Button")
	t.set_stylebox("normal", "Primary", _sb(ACCENT, 20))
	t.set_stylebox("hover", "Primary", _sb(ACCENT.lightened(0.15), 20))
	t.set_stylebox("pressed", "Primary", _sb(ACCENT.darkened(0.15), 20))
	t.set_stylebox("focus", "Primary", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Primary", DARK)
	t.set_font("font", "Primary", f800)
	t.set_type_variation("Card", "PanelContainer")
	var card := _sb(Color(0.03, 0.045, 0.07, 0.94), 32, Color(0.6, 0.95, 1.0, 0.16), 2, 48, 40)
	card.shadow_color = Color(0, 0, 0, 0.4)
	card.shadow_size = 30
	t.set_stylebox("panel", "Card", card)
	t.set_type_variation("Pill", "PanelContainer")
	t.set_stylebox("panel", "Pill", _sb(Color(0.02, 0.03, 0.05, 0.42), 40, Color(1, 1, 1, 0.12), 2, 26, 6))
	ui_theme = t


func _label(text: String, font: Font, size: int, col := INK, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if outline > 0:
		l.add_theme_constant_override("outline_size", outline)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _button(text: String, primary := false) -> Button:
	var b := Button.new()
	b.text = text
	if primary:
		b.theme_type_variation = "Primary"
	b.custom_minimum_size = Vector2(320, 76)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _ball_icon(px: int) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) * 0.5
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c) / (px * 0.5)
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var hl := 1.0 - clampf(p.distance_to(c - Vector2(px, px) * 0.18) / (px * 0.6), 0.0, 1.0)
			var v := 0.55 + 0.45 * hl
			img.set_pixel(x, y, Color(v, v * 1.02, v * 1.05, clampf((1.0 - d) * px * 0.5, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


# ---------- while playing ----------
func _build_hud(root: Control) -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	# progress to the next checkpoint, a thin line along the top
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.14)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 6
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bar)
	prog_fill = ColorRect.new()
	prog_fill.color = ACCENT
	prog_fill.position = Vector2.ZERO
	prog_fill.size = Vector2(0, 6)
	prog_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(prog_fill)
	# the balls left, top middle
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.offset_top = 22
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	var pill := PanelContainer.new()
	pill.theme_type_variation = "Pill"
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	top.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	var icon := TextureRect.new()
	icon.texture = _ball_icon(64)
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	ball_label = _label("25", f800, 52)
	row.add_child(ball_label)
	multi_label = _label("×2", f800, 34, ACCENT)
	multi_label.visible = false
	row.add_child(multi_label)
	dist_label = _label("0 m", f600, 22, Color(1, 1, 1, 0.8), 6)
	dist_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(dist_label)
	# pause
	var pb := Button.new()
	pb.text = "II"
	pb.focus_mode = Control.FOCUS_NONE
	pb.add_theme_font_override("font", f800)
	pb.add_theme_font_size_override("font_size", 26)
	for st in ["normal", "hover", "pressed"]:
		pb.add_theme_stylebox_override(st, _sb(Color(0.02, 0.03, 0.05, 0.42 if st == "normal" else 0.6), 40, Color(1, 1, 1, 0.12), 2, 0, 0))
	pb.custom_minimum_size = Vector2(76, 76)
	pb.position = Vector2(28, 26)
	pb.pressed.connect(func(): pause_pressed.emit())
	hud.add_child(pb)
	# a word in the middle (checkpoint, -10 ...)
	toast = _label("", f800, 76, INK, 12)
	toast.set_anchors_preset(Control.PRESET_CENTER)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BOTH
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.offset_top = -160
	toast.modulate.a = 0.0
	hud.add_child(toast)


func set_balls(n: int, multi: int) -> void:
	ball_label.text = str(n)
	ball_label.add_theme_color_override("font_color", Color("ff6b6b") if n <= 5 else INK)
	multi_label.visible = multi > 1
	multi_label.text = "×%d" % multi


func set_dist(d: float, progress: float) -> void:
	dist_label.text = "%d m" % int(d)
	prog_fill.size = Vector2(prog_fill.get_parent().size.x * clampf(progress, 0.0, 1.0), 6)


func show_toast(text: String, col := INK, hold := 0.7) -> void:
	toast.text = text
	toast.add_theme_color_override("font_color", col)
	toast.pivot_offset = toast.size * 0.5
	if _toast_tw:
		_toast_tw.kill()
	toast.modulate.a = 1.0
	toast.scale = Vector2(1.25, 1.25)
	_toast_tw = create_tween()
	_toast_tw.tween_property(toast, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tw.tween_interval(hold)
	_toast_tw.tween_property(toast, "modulate:a", 0.0, 0.35)


func flash_screen(col: Color, a := 0.45, dur := 0.4) -> void:
	if _flash_tw:
		_flash_tw.kill()
	flash.color = Color(col.r, col.g, col.b, a)
	_flash_tw = create_tween()
	_flash_tw.tween_property(flash, "color:a", 0.0, dur)


## a number floating up from a point on the screen (+3 for a crystal)
func popup(text: String, at: Vector2, col := ACCENT) -> void:
	var l := _label(text, f800, 44, col, 8)
	hud.add_child(l)
	l.position = at - Vector2(30, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)


# ---------- the title screen ----------
func _build_title(root: Control) -> void:
	title = Control.new()
	title.set_anchors_preset(Control.PRESET_FULL_RECT)
	title.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(title)
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.05, 0.85))
	g.set_color(1, Color(0.02, 0.03, 0.05, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.5)
	gt.fill_to = Vector2(0.75, 0.5)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 96
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_child(box)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 22)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_row)
	name_row.add_child(_label("KAANCH", title_font, 118, INK, 0))
	name_row.add_child(_label("RUN", title_font, 118, ACCENT, 0))
	box.add_child(_label("Break the glass. Keep moving.", f600, 32, Color(1, 1, 1, 0.82)))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 46)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(gap)
	tap_label = _label("TAP TO PLAY", title_font, 38, ACCENT)
	box.add_child(tap_label)
	best_label = _label("", f600, 26, Color(1, 1, 1, 0.7))
	box.add_child(best_label)
	var tw := create_tween().set_loops()
	tw.tween_property(tap_label, "modulate:a", 0.35, 0.8).set_trans(Tween.TRANS_SINE)
	tw.tween_property(tap_label, "modulate:a", 1.0, 0.8).set_trans(Tween.TRANS_SINE)
	# sound and music, bottom right
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.offset_right = -36
	row.offset_bottom = -32
	row.add_theme_constant_override("separation", 14)
	title.add_child(row)
	row.add_child(_toggle(true))
	row.add_child(_toggle(false))
	title.gui_input.connect(_title_input)


func _title_input(e: InputEvent) -> void:
	if (e is InputEventScreenTouch and e.pressed) or (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT):
		start_pressed.emit()


func _flip_sound() -> void:
	sound_on = not sound_on
	sound_toggled.emit(sound_on)
	_paint_toggles()


func _flip_music() -> void:
	music_on = not music_on
	music_toggled.emit(music_on)
	_paint_toggles()


func _toggle(is_sound: bool) -> Button:
	var b := _button("", false)
	b.custom_minimum_size = Vector2(190, 66)
	b.add_theme_font_size_override("font_size", 24)
	if is_sound:
		snd_btns.append(b)
		b.pressed.connect(_flip_sound)
	else:
		mus_btns.append(b)
		b.pressed.connect(_flip_music)
	_paint_toggles()
	return b


func _paint_toggles() -> void:
	for b in snd_btns:
		b.text = "Sound: " + ("On" if sound_on else "Off")
	for b in mus_btns:
		b.text = "Music: " + ("On" if music_on else "Off")


func set_toggles(snd: bool, mus: bool) -> void:
	sound_on = snd
	music_on = mus
	_paint_toggles()


# ---------- cards ----------
func _card(root: Control) -> Array:
	var wrap := Control.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.mouse_filter = Control.MOUSE_FILTER_STOP
	wrap.visible = false
	root.add_child(wrap)
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.03, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(box)
	return [wrap, box]


func _build_pause(root: Control) -> Control:
	var c := _card(root)
	var box: VBoxContainer = c[1]
	var t := _label("Paused", f800, 56)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	var r := _button("Resume", true)
	r.pressed.connect(func(): resume_pressed.emit())
	box.add_child(r)
	var rs := _button("Restart")
	rs.pressed.connect(func(): restart_pressed.emit())
	box.add_child(rs)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var a := _toggle(true)
	a.custom_minimum_size = Vector2(154, 66)
	row.add_child(a)
	var b := _toggle(false)
	b.custom_minimum_size = Vector2(154, 66)
	row.add_child(b)
	var m := _button("Main menu")
	m.pressed.connect(func(): menu_pressed.emit())
	box.add_child(m)
	return c[0]


func _build_over(root: Control) -> Control:
	var c := _card(root)
	var box: VBoxContainer = c[1]
	over_title = _label("Out of balls", f800, 46)
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_title)
	over_dist = _label("0 m", title_font, 96, ACCENT)
	over_dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_dist)
	over_best = _label("", f600, 26, Color(1, 1, 1, 0.7))
	over_best.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_best)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)
	cont_btn = _button("Continue", true)
	cont_btn.custom_minimum_size = Vector2(380, 76)
	cont_btn.pressed.connect(func(): continue_pressed.emit())
	box.add_child(cont_btn)
	var rs := _button("Start again")
	rs.custom_minimum_size = Vector2(380, 76)
	rs.pressed.connect(func(): restart_pressed.emit())
	box.add_child(rs)
	var m := _button("Main menu")
	m.custom_minimum_size = Vector2(380, 76)
	m.pressed.connect(func(): menu_pressed.emit())
	box.add_child(m)
	return c[0]


# ---------- switching screens ----------
func show_title(best: int) -> void:
	title.visible = true
	hud.visible = false
	pause_panel.visible = false
	over_panel.visible = false
	best_label.text = "Best: %d m" % best if best > 0 else ""


func show_play() -> void:
	title.visible = false
	hud.visible = true
	pause_panel.visible = false
	over_panel.visible = false


func show_pause() -> void:
	pause_panel.visible = true


func show_over(dist: int, best: int, cp: int, new_best: bool) -> void:
	hud.visible = false
	over_panel.visible = true
	over_title.text = "New best!" if new_best else "Out of balls"
	over_dist.text = "%d m" % dist
	over_best.text = "Best: %d m" % best
	cont_btn.visible = cp > 0
	cont_btn.text = "Continue from %d m" % cp
