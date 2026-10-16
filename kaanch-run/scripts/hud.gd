## Everything on top of the game: the menus, the marble counter, the score and combo, pause and the end cards.
class_name Hud
extends CanvasLayer

signal play_mode(mode: String)
signal resume_pressed
signal restart_pressed
signal continue_pressed
signal menu_pressed
signal pause_pressed
signal setting_changed(key: String, value: Variant)

const ACCENT := Color("5ff2dc")
const GOLD := Color("ffd36b")
const INK := Color("eef6f8")
const DARK := Color("062227")

var f600: Font
var f800: Font
var title_font: FontVariation
var ui_theme: Theme

var root: Control
var hud: Control
var ball_label: Label
var multi_label: Label
var dist_label: Label
var score_label: Label
var combo_label: Label
var prog_fill: ColorRect
var toast: Label
var flash: ColorRect
var menu: Control
var levels: Control
var settings: Control
var pause_panel: Control
var pause_title: Label
var over_panel: Control
var over_title: Label
var over_big: Label
var over_sub: Label
var cont_btn: Button
var done_panel: Control
var done_stars: Array[Label] = []
var done_rows: Label
var done_title: Label
var done_unlock: Label
var level_cards := {}
var opts := {}
var _toast_tw: Tween
var _flash_tw: Tween
var _settings_from: Control


func _ready() -> void:
	layer = 10
	f600 = load("res://fonts/bricolage-600.woff2")
	f800 = load("res://fonts/bricolage-800.woff2")
	title_font = FontVariation.new()
	title_font.base_font = f800
	title_font.spacing_glyph = 4
	_make_theme()
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = ui_theme
	add_child(root)
	_vignette()
	_build_hud()
	menu = _build_menu()
	levels = _build_levels()
	settings = _build_settings()
	pause_panel = _build_pause()
	over_panel = _build_over()
	done_panel = _build_done()
	flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.color = Color(1, 1, 1, 0)
	root.add_child(flash)


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
	t.set_stylebox("disabled", "Button", _sb(Color(0.02, 0.03, 0.05, 0.35), 20, Color(1, 1, 1, 0.08), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(1, 1, 1, 0.35))
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
	var card := _sb(Color(0.03, 0.045, 0.07, 0.94), 32, Color(0.6, 0.95, 1.0, 0.16), 2, 48, 36)
	card.shadow_color = Color(0, 0, 0, 0.4)
	card.shadow_size = 30
	t.set_stylebox("panel", "Card", card)
	t.set_type_variation("Pill", "PanelContainer")
	t.set_stylebox("panel", "Pill", _sb(Color(0.02, 0.03, 0.05, 0.45), 40, Color(1, 1, 1, 0.12), 2, 26, 6))
	t.set_type_variation("Tile", "Button")
	for st in ["normal", "hover", "pressed", "disabled"]:
		var a: float = {"normal": 0.62, "hover": 0.75, "pressed": 0.85, "disabled": 0.4}[st]
		t.set_stylebox(st, "Tile", _sb(Color(0.03, 0.045, 0.07, a), 26, Color(0.6, 0.95, 1.0, 0.22 if st != "disabled" else 0.08), 2, 26, 22))
	t.set_stylebox("focus", "Tile", StyleBoxEmpty.new())
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


func _button(text: String, primary := false, w := 340) -> Button:
	var b := Button.new()
	b.text = text
	if primary:
		b.theme_type_variation = "Primary"
	b.custom_minimum_size = Vector2(w, 74)
	b.focus_mode = Control.FOCUS_NONE
	return b


func _ball_icon(px: int) -> ImageTexture:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := Vector2(px, px) * 0.5
	var base := Color("4d8dff")
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c) / (px * 0.5)
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var hl := 1.0 - clampf(p.distance_to(c - Vector2(px, px) * 0.18) / (px * 0.55), 0.0, 1.0)
			var swirl := 0.5 + 0.5 * sin((p.x - p.y) * 0.25 + d * 6.0)
			var col := base.lerp(Color("ff4d6d"), swirl * 0.5).lerp(Color.WHITE, hl * 0.8)
			col.a = clampf((1.0 - d) * px * 0.5, 0.0, 1.0)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _vignette() -> void:
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


func _screen() -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	c.visible = false
	root.add_child(c)
	return c


func _shade(parent: Control, left := true) -> void:
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.05, 0.88))
	g.set_color(1, Color(0.02, 0.03, 0.05, 0.1))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0.5) if left else Vector2(0.5, 1.0)
	gt.fill_to = Vector2(0.8, 0.5) if left else Vector2(0.5, 0.0)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(shade)


func _gap(parent: Control, h: int) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)


# ---------- while playing ----------
func _build_hud() -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.visible = false
	root.add_child(hud)
	var bar := ColorRect.new()
	bar.color = Color(1, 1, 1, 0.14)
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = 6
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(bar)
	prog_fill = ColorRect.new()
	prog_fill.color = ACCENT
	prog_fill.size = Vector2(0, 6)
	prog_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(prog_fill)
	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.offset_top = 22
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
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
	# the score and the colour combo, top right
	var right := VBoxContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	right.offset_right = -32
	right.offset_top = 26
	right.alignment = BoxContainer.ALIGNMENT_BEGIN
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(right)
	score_label = _label("0", title_font, 44, INK, 8)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(score_label)
	combo_label = _label("", f800, 28, ACCENT, 8)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(combo_label)
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
	toast = _label("", f800, 72, INK, 12)
	toast.set_anchors_preset(Control.PRESET_CENTER)
	toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast.grow_vertical = Control.GROW_DIRECTION_BOTH
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.offset_top = -170
	toast.modulate.a = 0.0
	hud.add_child(toast)


func set_balls(n: int, multi: int, infinite := false) -> void:
	ball_label.text = "∞" if infinite else str(n)
	ball_label.add_theme_color_override("font_color", Color("ff6b6b") if (n <= 5 and not infinite) else INK)
	multi_label.visible = multi > 1
	multi_label.text = "×%d" % multi


func set_dist(d: float, progress: float) -> void:
	dist_label.text = "%d m" % int(d)
	prog_fill.size = Vector2(prog_fill.get_parent().size.x * clampf(progress, 0.0, 1.0), 6)


func set_score(s: int) -> void:
	score_label.text = str(s)


func set_combo(color_id: int, n: int, mult: int) -> void:
	if color_id < 0 or n < 2:
		combo_label.text = ""
		return
	combo_label.text = "%s ×%d" % [Glass.COLOR_NAMES[color_id], n] + ("   x%d pts" % mult if mult > 1 else "")
	combo_label.add_theme_color_override("font_color", Glass.COLORS[color_id].lightened(0.25))


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


func popup(text: String, at: Vector2, col := ACCENT) -> void:
	var l := _label(text, f800, 42, col, 8)
	hud.add_child(l)
	l.position = at - Vector2(30, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)


# ---------- the main menu ----------
func _build_menu() -> Control:
	var c := _screen()
	_shade(c)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	box.offset_left = 96
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 8)
	c.add_child(box)
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 22)
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_row)
	name_row.add_child(_label("KAANCH", title_font, 112, INK))
	name_row.add_child(_label("RUN", title_font, 112, ACCENT))
	box.add_child(_label("Break the glass. Keep moving.", f600, 30, Color(1, 1, 1, 0.82)))
	_gap(box, 36)
	var play := _button("Play", true, 380)
	play.pressed.connect(func(): show_levels(opts))
	box.add_child(play)
	var set_b := _button("Settings", false, 380)
	set_b.pressed.connect(func(): show_settings(menu))
	box.add_child(set_b)
	var ver := _label("v0.2", f600, 20, Color(1, 1, 1, 0.4))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	ver.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ver.offset_right = -24
	ver.offset_bottom = -16
	c.add_child(ver)
	return c


func _tile(title: String, sub: String, mode: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = "Tile"
	b.custom_minimum_size = Vector2(330, 300)
	b.focus_mode = Control.FOCUS_NONE
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 26
	v.offset_top = 24
	v.offset_right = -26
	v.offset_bottom = -24
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var t := _label(title, f800, 36)
	v.add_child(t)
	var s := _label(sub, f600, 22, Color(1, 1, 1, 0.75))
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size = Vector2(270, 0)
	v.add_child(s)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(fill)
	var info := _label("", f800, 30, GOLD)
	v.add_child(info)
	b.pressed.connect(func(): play_mode.emit(mode))
	level_cards[mode] = {"button": b, "info": info, "sub": s}
	return b


func _build_levels() -> Control:
	var c := _screen()
	_shade(c, false)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.grow_horizontal = Control.GROW_DIRECTION_BOTH
	v.grow_vertical = Control.GROW_DIRECTION_BOTH
	v.add_theme_constant_override("separation", 26)
	c.add_child(v)
	var head := _label("Choose a run", title_font, 54)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(head)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	row.add_child(_tile("Level 1", "First Light. Seventy-five seconds through a cathedral of stained glass.", "level1"))
	row.add_child(_tile("Endless", "50 rooms, five worlds, none twice in a run. Checkpoints every 200 m.", "endless"))
	row.add_child(_tile("Calm", "No crashes, no counting. Just break glass to music.", "calm"))
	var back := _button("Back", false, 260)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): show_menu(opts))
	v.add_child(back)
	return c


func _seg(title: String, key: String, choices: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var l := _label(title, f600, 28)
	l.custom_minimum_size = Vector2(220, 0)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var btns := []
	for ch in choices:
		var b := _button(ch[0], false, 150)
		b.custom_minimum_size = Vector2(150, 64)
		b.set_meta("v", ch[1])
		btns.append(b)
		row.add_child(b)
	for b in btns:
		b.pressed.connect(func():
			opts[key] = b.get_meta("v")
			setting_changed.emit(key, opts[key])
			_paint_seg(btns, key)
		)
	row.set_meta("btns", btns)
	row.set_meta("key", key)
	return row


func _paint_seg(btns: Array, key: String) -> void:
	for b in btns:
		b.theme_type_variation = "Primary" if opts.get(key) == b.get_meta("v") else ""


func _build_settings() -> Control:
	var c := _screen()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.03, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = "Card"
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	card.add_child(box)
	var t := _label("Settings", f800, 52)
	box.add_child(t)
	var rows := [
		_seg("Graphics", "quality", [["Light", 0], ["Rich", 1]]),
		_seg("Sound", "sound", [["On", true], ["Off", false]]),
		_seg("Music", "music", [["On", true], ["Off", false]]),
		_seg("Vibration", "vibe", [["On", true], ["Off", false]]),
	]
	for r in rows:
		box.add_child(r)
	c.set_meta("rows", rows)
	_gap(box, 6)
	var done := _button("Done", true, 300)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(func():
		c.visible = false
		if _settings_from:
			_settings_from.visible = true
	)
	box.add_child(done)
	return c


func _card() -> Array:
	var wrap := _screen()
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


func _build_pause() -> Control:
	var c := _card()
	var box: VBoxContainer = c[1]
	pause_title = _label("Paused", f800, 56)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(pause_title)
	var r := _button("Resume", true)
	r.pressed.connect(func(): resume_pressed.emit())
	box.add_child(r)
	var rs := _button("Restart")
	rs.pressed.connect(func(): restart_pressed.emit())
	box.add_child(rs)
	var st := _button("Settings")
	st.pressed.connect(func(): show_settings(pause_panel))
	box.add_child(st)
	var m := _button("Main menu")
	m.pressed.connect(func(): menu_pressed.emit())
	box.add_child(m)
	return c[0]


func _build_over() -> Control:
	var c := _card()
	var box: VBoxContainer = c[1]
	over_title = _label("Out of marbles", f800, 44)
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_title)
	over_big = _label("0 m", title_font, 92, ACCENT)
	over_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_big)
	over_sub = _label("", f600, 26, Color(1, 1, 1, 0.7))
	over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(over_sub)
	_gap(box, 8)
	cont_btn = _button("Continue", true, 400)
	cont_btn.pressed.connect(func(): continue_pressed.emit())
	box.add_child(cont_btn)
	var rs := _button("Try again", false, 400)
	rs.pressed.connect(func(): restart_pressed.emit())
	box.add_child(rs)
	var m := _button("Main menu", false, 400)
	m.pressed.connect(func(): menu_pressed.emit())
	box.add_child(m)
	return c[0]


func _build_done() -> Control:
	var c := _card()
	var box: VBoxContainer = c[1]
	done_title = _label("Level complete", f800, 46)
	done_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(done_title)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 18)
	box.add_child(stars)
	for i in 3:
		var s := _label("★", f800, 84, Color(1, 1, 1, 0.15))
		s.pivot_offset = Vector2(30, 50)
		stars.add_child(s)
		done_stars.append(s)
	done_rows = _label("", f600, 28, INK)
	done_rows.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(done_rows)
	done_unlock = _label("Endless unlocked!", f800, 28, GOLD)
	done_unlock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(done_unlock)
	_gap(box, 6)
	var nx := _button("Endless run", true, 400)
	nx.pressed.connect(func(): play_mode.emit("endless"))
	box.add_child(nx)
	var rs := _button("Play again", false, 400)
	rs.pressed.connect(func(): restart_pressed.emit())
	box.add_child(rs)
	var m := _button("Main menu", false, 400)
	m.pressed.connect(func(): menu_pressed.emit())
	box.add_child(m)
	return c[0]


# ---------- switching screens ----------
func _hide_all() -> void:
	for s in [menu, levels, settings, pause_panel, over_panel, done_panel]:
		s.visible = false
	hud.visible = false


func apply_settings(save: Dictionary) -> void:
	opts = save
	var rows: Array = settings.get_meta("rows")
	for r in rows:
		_paint_seg(r.get_meta("btns"), r.get_meta("key"))


func show_menu(save: Dictionary) -> void:
	opts = save
	_hide_all()
	menu.visible = true


func show_levels(save: Dictionary) -> void:
	opts = save
	_hide_all()
	levels.visible = true
	var l1: Dictionary = level_cards["level1"]
	var st := int(save.get("l1_stars", 0))
	l1.info.text = ("★".repeat(st) + "☆".repeat(3 - st)) if save.get("l1_done", false) else "New"
	var en: Dictionary = level_cards["endless"]
	var unlocked: bool = save.get("l1_done", false)
	en.button.disabled = not unlocked
	en.info.text = ("Best %d m" % int(save.get("best", 0))) if unlocked else "Finish Level 1 to unlock"
	en.info.add_theme_font_size_override("font_size", 30 if unlocked else 22)
	var calm: Dictionary = level_cards["calm"]
	calm.info.text = "Relax"


func show_settings(from: Control = null) -> void:
	_settings_from = from
	if from:
		from.visible = false
	apply_settings(opts)
	settings.visible = true


func show_play(_mode: String) -> void:
	_hide_all()
	hud.visible = true
	toast.modulate.a = 0.0


func show_pause(mode: String) -> void:
	pause_panel.visible = true
	pause_title.text = "Paused"


func show_over_endless(d: int, best: int, cp: int, new_best: bool, score: int) -> void:
	_hide_all()
	over_panel.visible = true
	over_title.text = "New best!" if new_best else "Out of marbles"
	over_big.text = "%d m" % d
	over_sub.text = "Best %d m  ·  Score %d" % [best, score]
	cont_btn.visible = cp > 0
	cont_btn.text = "Continue from %d m" % cp


func show_over_level(d: int, total: int, score: int) -> void:
	_hide_all()
	over_panel.visible = true
	over_title.text = "Out of marbles"
	over_big.text = "%d%%" % int(100.0 * d / maxf(1.0, total))
	over_sub.text = "of the level  ·  Score %d" % score
	cont_btn.visible = false


func show_done(s: Dictionary) -> void:
	_hide_all()
	done_panel.visible = true
	done_title.text = "Level complete"
	done_rows.text = "Score  %d%s\nGlass broken  %d\nAccuracy  %d%%\nBest combo  ×%d" % [s.score, ("   new best!" if s.best else ""), s.glass, int(s.acc * 100.0), s.combo]
	done_unlock.visible = s.unlocked
	for i in 3:
		var st := done_stars[i]
		st.add_theme_color_override("font_color", Color(1, 1, 1, 0.15))
		st.scale = Vector2.ONE
		if i < s.stars:
			var tw := create_tween()
			tw.tween_interval(0.35 + i * 0.35)
			tw.tween_callback(func(): st.add_theme_color_override("font_color", GOLD))
			tw.tween_property(st, "scale", Vector2(1.3, 1.3), 0.12)
			tw.tween_property(st, "scale", Vector2.ONE, 0.18)
