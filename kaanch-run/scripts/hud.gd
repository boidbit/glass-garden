## Everything on top of the game: the menus, the ball counter, the score and combo, pause and the end cards.
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
var top_box: VBoxContainer
var ball_label: Label
var multi_label: Label
var dist_label: Label
var score_label: Label
var combo_label: Label
var prog_fill: ColorRect
var toast: Label
var icon: TextureRect
var crack_rect: TextureRect
var _crack_tw: Tween
var _pulse := 0.0
var ring: Ring
var dots: MultiDots
var power_badge: PowerBadge
var title_big: Label
var title_small: Label
var _title_tw: Tween
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
	for y in px:
		for x in px:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := p.distance_to(c) / (px * 0.5)
			if d > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var hl := 1.0 - clampf(p.distance_to(c - Vector2(px, px) * 0.18) / (px * 0.55), 0.0, 1.0)
			# polished iron: bright above, a dark band across the middle, grey below
			var v := (p.y / px)
			var g := lerpf(0.92, 0.55, v / 0.48) if v < 0.48 else (lerpf(0.18, 0.5, (v - 0.48) / 0.52))
			var col := Color(g * 0.95, g * 0.97, g).lerp(Color.WHITE, hl * 0.6)
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
	top_box = top
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
	icon = TextureRect.new()
	icon.texture = _ball_icon(64)
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	ring = Ring.new()
	ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	ring.offset_left = -8
	ring.offset_top = -8
	ring.offset_right = 8
	ring.offset_bottom = 8
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.add_child(ring)
	ball_label = _label("25", f800, 52)
	row.add_child(ball_label)
	multi_label = _label("×2", f800, 34, ACCENT)
	multi_label.visible = false
	row.add_child(multi_label)
	dist_label = _label("0 m", f600, 22, Color(1, 1, 1, 0.8), 6)
	dist_label.visible = false
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
	score_label.visible = false
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(score_label)
	combo_label = _label("", f800, 28, ACCENT, 8)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(combo_label)
	dots = MultiDots.new()
	dots.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dots.offset_left = 30
	dots.offset_right = 110
	dots.offset_top = -300
	dots.offset_bottom = -20
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(dots)
	# a crystal of power at work: its colour, and how much of it is left
	power_badge = PowerBadge.new()
	power_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	power_badge.offset_left = -130
	power_badge.offset_right = -30
	power_badge.offset_top = -130
	power_badge.offset_bottom = -30
	power_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	power_badge.visible = false
	hud.add_child(power_badge)
	var pb := IconButton.new("pause", 70.0)
	pb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	pb.offset_left = -100
	pb.offset_right = -30
	pb.offset_top = 24
	pb.offset_bottom = 94
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
	# a room's name, large, as you come into it
	title_small = _label("", f600, 26, INK, 6)
	title_big = _label("", f800, 84, INK, 14)
	for l in [title_small, title_big]:
		l.set_anchors_preset(Control.PRESET_CENTER_TOP)
		l.grow_horizontal = Control.GROW_DIRECTION_BOTH
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.modulate.a = 0.0
		hud.add_child(l)
	title_small.offset_top = 130
	title_big.offset_top = 160


## making a short: nothing on the screen, or only the ball count, large and lower down (clear of the phone's own buttons)
func shorts(show_balls: bool) -> void:
	for c in hud.get_children():
		c.visible = show_balls and c == top_box
	ball_label.add_theme_font_size_override("font_size", 96)
	icon.custom_minimum_size = Vector2(72, 72)
	top_box.offset_top = 250


func set_balls(n: int, multi: int, infinite := false, streak := 0.0) -> void:
	if ring.frac != streak:
		ring.frac = streak
		ring.queue_redraw()
	if dots.count != multi:
		dots.count = multi
		dots.queue_redraw()
	ball_label.text = "∞" if infinite else str(n)
	# running low: the number turns red and beats, faster the fewer are left
	var low := n < 10 and not infinite
	if low:
		_pulse += get_process_delta_time() * (4.0 + (10 - n) * 0.8)
		var k := 0.5 + 0.5 * sin(_pulse)
		ball_label.add_theme_color_override("font_color", Color("ff4a4a").lerp(Color("ffb0a0"), k * 0.5))
		ball_label.pivot_offset = ball_label.size * 0.5
		ball_label.scale = Vector2.ONE * (1.0 + 0.12 * k)
	else:
		ball_label.add_theme_color_override("font_color", INK)
		ball_label.scale = Vector2.ONE
	# more than one ball a throw: the ball turns gold
	multi_label.visible = false
	icon.modulate = Color.WHITE


func set_power(kind: String, frac: float, col: Color) -> void:
	power_badge.visible = kind != ""
	if kind != power_badge.kind or absf(frac - power_badge.frac) > 0.004:
		power_badge.kind = kind
		power_badge.frac = frac
		power_badge.col = col
		power_badge.queue_redraw()


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


## a crack across the screen when you run into glass
func crack_screen() -> void:
	if crack_rect == null:
		crack_rect = TextureRect.new()
		crack_rect.texture = _crack_image()
		crack_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		crack_rect.stretch_mode = TextureRect.STRETCH_SCALE
		crack_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crack_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hud.add_child(crack_rect)
	crack_rect.flip_h = randf() < 0.5
	crack_rect.flip_v = randf() < 0.5
	crack_rect.modulate.a = 1.0
	if _crack_tw:
		_crack_tw.kill()
	_crack_tw = create_tween()
	_crack_tw.tween_interval(0.35)
	_crack_tw.tween_property(crack_rect, "modulate:a", 0.0, 0.7)


func _crack_image() -> ImageTexture:
	var W := 480
	var H := 270
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(W * 0.62, H * 0.42)
	for k in 16:
		var a := TAU * k / 16.0 + randf_range(-0.15, 0.15)
		var p := c
		var dir := Vector2(cos(a), sin(a))
		for i in 400:
			if i % 14 == 0:
				dir = dir.rotated(randf_range(-0.4, 0.4))
			p += dir
			if p.x < 0 or p.y < 0 or p.x >= W or p.y >= H:
				break
			var al := 0.95 - float(i) / 500.0
			img.set_pixelv(Vector2i(p), Color(1, 1, 1, al))
			if p.x + 1 < W:
				img.set_pixelv(Vector2i(p) + Vector2i(1, 0), Color(0.7, 0.85, 0.9, al * 0.6))
	for r: float in [18.0, 34.0, 55.0]:
		for i in 240:
			var a := TAU * i / 240.0
			var q: Vector2 = c + Vector2(cos(a), sin(a)) * (r + sin(a * 7.0) * 3.0)
			if q.x >= 0 and q.y >= 0 and q.x < W and q.y < H:
				img.set_pixelv(Vector2i(q), Color(1, 1, 1, 0.7))
	return ImageTexture.create_from_image(img)


func show_toast(text: String, col := INK, hold := 0.7) -> void:
	# nothing written on the screen while you play
	if hud.visible:
		return
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


func show_title(big: String, small: String, col: Color) -> void:
	return
	title_big.text = big.to_upper()
	title_small.text = small
	title_big.add_theme_color_override("font_color", col)
	if _title_tw:
		_title_tw.kill()
	title_big.modulate.a = 0.0
	title_small.modulate.a = 0.0
	title_big.scale = Vector2(1.15, 1.15)
	title_big.pivot_offset = Vector2(title_big.size.x * 0.5, 40)
	_title_tw = create_tween()
	_title_tw.set_parallel(true)
	_title_tw.tween_property(title_big, "modulate:a", 1.0, 0.25)
	_title_tw.tween_property(title_big, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	_title_tw.tween_property(title_small, "modulate:a", 1.0, 0.25).set_delay(0.1)
	_title_tw.chain().tween_interval(1.4)
	_title_tw.chain().set_parallel(true)
	_title_tw.tween_property(title_big, "modulate:a", 0.0, 0.5)
	_title_tw.tween_property(title_small, "modulate:a", 0.0, 0.5)


func flash_screen(col: Color, a := 0.45, dur := 0.4) -> void:
	if _flash_tw:
		_flash_tw.kill()
	flash.color = Color(col.r, col.g, col.b, a)
	_flash_tw = create_tween()
	_flash_tw.tween_property(flash, "color:a", 0.0, dur)


func popup(text: String, at: Vector2, col := ACCENT) -> void:
	return
	var l := _label(text, f800, 42, col, 8)
	hud.add_child(l)
	l.position = at - Vector2(30, 30)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 70, 0.7).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)


# ---------- the main menu ----------
# ---------- drawn icons and controls ----------
## a round button with an icon drawn on it (no icon font needed)
class IconButton extends Button:
	var icon_kind := "play"
	var big := false
	var fill := Color(1, 1, 1, 0.14)
	var ink := Color(1, 1, 1, 0.95)

	func _init(kind: String, size_px: float, primary := false) -> void:
		icon_kind = kind
		big = primary
		custom_minimum_size = Vector2(size_px, size_px)
		focus_mode = Control.FOCUS_NONE
		flat = true
		if primary:
			fill = Color(1, 1, 1, 0.96)
			ink = Color("0b1a22")
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		button_down.connect(queue_redraw)
		button_up.connect(queue_redraw)

	func _draw() -> void:
		var r := size.x * 0.5
		var c := size * 0.5
		var k := 0.92 if is_pressed() else 1.0
		draw_circle(c, r * k, fill)
		if not big:
			draw_arc(c, r * k - 1.5, 0, TAU, 64, Color(1, 1, 1, 0.35), 2.0, true)
		var s := r * 0.42 * k
		match icon_kind:
			"play":
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.8), c + Vector2(s * 0.85, 0), c + Vector2(-s * 0.55, s * 0.8)]), ink)
			"pause":
				draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.7), Vector2(s * 0.35, s * 1.4)), ink)
				draw_rect(Rect2(c + Vector2(s * 0.2, -s * 0.7), Vector2(s * 0.35, s * 1.4)), ink)
			"retry":
				draw_arc(c, s * 0.7, -PI * 0.15, PI * 1.45, 32, ink, s * 0.22, true)
				var tip := c + Vector2(cos(-PI * 0.15), sin(-PI * 0.15)) * s * 0.7
				draw_colored_polygon(PackedVector2Array([tip + Vector2(-s * 0.35, -s * 0.1), tip + Vector2(s * 0.3, -s * 0.15), tip + Vector2(0.0, s * 0.4)]), ink)
			"home":
				draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.85), c + Vector2(s * 0.85, -s * 0.05), c + Vector2(-s * 0.85, -s * 0.05)]), ink)
				draw_rect(Rect2(c + Vector2(-s * 0.55, -s * 0.1), Vector2(s * 1.1, s * 0.85)), ink)
				draw_rect(Rect2(c + Vector2(-s * 0.15, s * 0.3), Vector2(s * 0.3, s * 0.45)), fill if fill.a > 0.5 else Color(0.1, 0.12, 0.15))
			"gear":
				for i in 8:
					var a := TAU * i / 8.0
					var d := Vector2(cos(a), sin(a))
					var n := Vector2(-d.y, d.x)
					draw_colored_polygon(PackedVector2Array([c + d * s * 0.55 - n * s * 0.16, c + d * s * 0.95 - n * s * 0.12, c + d * s * 0.95 + n * s * 0.12, c + d * s * 0.55 + n * s * 0.16]), ink)
				draw_circle(c, s * 0.62, ink)
				draw_circle(c, s * 0.26, fill if fill.a > 0.5 else Color(0.12, 0.14, 0.17))
			"close":
				draw_line(c + Vector2(-s, -s) * 0.6, c + Vector2(s, s) * 0.6, ink, s * 0.2, true)
				draw_line(c + Vector2(s, -s) * 0.6, c + Vector2(-s, s) * 0.6, ink, s * 0.2, true)
			"zen":
				# a calm wave
				var pts := PackedVector2Array()
				for i in 25:
					var x := -s + 2.0 * s * i / 24.0
					pts.append(c + Vector2(x, sin(x / s * PI * 1.5) * s * 0.3))
				draw_polyline(pts, ink, s * 0.2, true)
			"flag":
				draw_line(c + Vector2(-s * 0.55, s * 0.85), c + Vector2(-s * 0.55, -s * 0.85), ink, s * 0.16, true)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.5, -s * 0.85), c + Vector2(s * 0.75, -s * 0.5), c + Vector2(-s * 0.5, -s * 0.12)]), ink)


## a ring round the ball count: how close the next extra ball per throw is
class Ring extends Control:
	var frac := 0.0

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 3.0
		draw_arc(c, r, 0, TAU, 48, Color(1, 1, 1, 0.18), 5.0, true)
		if frac > 0.001:
			draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * clampf(frac, 0.0, 1.0), 48, Color(1, 1, 1, 0.95), 5.0, true)


## down the left side: how many balls each throw sends (one, two, three...), as balls drawn in circles
class MultiDots extends Control:
	var count := 1

	func _draw() -> void:
		for i in 3:
			var on := i < count
			var c := Vector2(size.x * 0.5, size.y - 40.0 - i * 84.0)
			var r := 34.0 if i == count - 1 and count > 1 else 28.0
			draw_circle(c, r, Color("63e6a0") if on else Color(1, 1, 1, 0.12))
			draw_arc(c, r, 0, TAU, 40, Color(0, 0, 0, 0.25), 3.0, true)
			for k in i + 1:
				var a := TAU * k / float(i + 1) - PI * 0.5
				var p := c + (Vector2(cos(a), sin(a)) * r * 0.42 if i > 0 else Vector2.ZERO)
				draw_circle(p, 6.0, Color(1, 1, 1, 0.95 if on else 0.4))


## a crystal of power at work, bottom right: an hourglass (slow time), three balls, or a glowing ball of iron
class PowerBadge extends Control:
	var kind := ""
	var frac := 0.0
	var col := Color.WHITE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.5 - 6.0
		draw_circle(c, r, Color(0, 0, 0, 0.35))
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * frac, 56, col, 7.0, true)
		match kind:
			"slow":
				var w := r * 0.42
				var h := r * 0.55
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w, -h), c + Vector2(w, -h), c]), col)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-w, h), c + Vector2(w, h), c]), col)
			"burst":
				for k in 3:
					var a := TAU * k / 3.0 - PI * 0.5
					draw_circle(c + Vector2(cos(a), sin(a)) * r * 0.33, r * 0.2, col)
			"iron":
				draw_circle(c, r * 0.4, col)
				draw_arc(c, r * 0.58, 0, TAU, 40, Color(col, 0.5), 3.0, true)


## an on/off switch, drawn
class Switch extends Button:
	var on := true
	var _k := 1.0

	func _init() -> void:
		custom_minimum_size = Vector2(96, 52)
		focus_mode = Control.FOCUS_NONE
		flat = true
		pressed.connect(func():
			on = not on
			queue_redraw())

	func _process(dt: float) -> void:
		var want := 1.0 if on else 0.0
		if absf(_k - want) > 0.001:
			_k = move_toward(_k, want, dt * 6.0)
			queue_redraw()

	func _draw() -> void:
		var h := size.y
		var r := h * 0.5
		var track := Color(1, 1, 1, 0.18).lerp(Color("5ff2dc"), _k)
		draw_circle(Vector2(r, r), r, track)
		draw_circle(Vector2(size.x - r, r), r, track)
		draw_rect(Rect2(r, 0, size.x - 2.0 * r, h), track)
		var kx := lerpf(r, size.x - r, _k)
		draw_circle(Vector2(kx, r), r - 5.0, Color(1, 1, 1, 0.98))


func _caption(text: String) -> Label:
	var l := _label(text.to_upper(), f800, 17, Color(1, 1, 1, 0.75))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 0)
	return l


## a small round button with a caption under it
func _icon_with_caption(kind: String, text: String, size_px := 92.0) -> Array:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	var b := IconButton.new(kind, size_px)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(b)
	v.add_child(_caption(text))
	return [v, b]


func _wordmark(size: int) -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -int(size * 0.28))
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := _label("GLASS", title_font, size, INK, 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_constant_override("outline_size", 0)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	t.add_theme_constant_override("shadow_offset_y", 6)
	v.add_child(t)
	var r := _label("R  U  N", f800, int(size * 0.3), ACCENT, 0)
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	return v


func _fade_in(c: Control) -> void:
	c.visible = true
	c.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", 1.0, 0.22)


# ---------- the home screen ----------
var best_label: Label
var play_btn: IconButton
var start_panel: Control
var start_cp_btn: Button
var start_cp_info: Label
signal start_from(room: int)


func _build_menu() -> Control:
	var c := _screen()
	# darker at the top and bottom, so the words read over the moving room
	var shade := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.05, 0.75))
	g.set_color(1, Color(0.02, 0.03, 0.05, 0.85))
	g.add_point(0.45, Color(0.02, 0.03, 0.05, 0.12))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	shade.texture = gt
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shade.stretch_mode = TextureRect.STRETCH_SCALE
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(shade)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 40
	col.offset_bottom = -34
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(col)
	col.add_child(_wordmark(118))
	_gap(col, 26)
	play_btn = IconButton.new("play", 150.0, true)
	play_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	play_btn.pivot_offset = Vector2(75, 75)
	play_btn.pressed.connect(_on_play)
	col.add_child(play_btn)
	_gap(col, 14)
	best_label = _label("", f800, 22, Color(1, 1, 1, 0.8))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(best_label)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(spacer)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 56)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	var lv := _icon_with_caption("flag", "First Light")
	lv[1].pressed.connect(func(): play_mode.emit("level1"))
	row.add_child(lv[0])
	var zen := _icon_with_caption("zen", "Zen")
	zen[1].pressed.connect(func(): play_mode.emit("calm"))
	row.add_child(zen[0])
	var st := _icon_with_caption("gear", "Settings")
	st[1].pressed.connect(func(): show_settings(menu))
	row.add_child(st[0])
	# the play button breathes, gently
	var tw := create_tween().set_loops()
	tw.tween_property(play_btn, "scale", Vector2(1.05, 1.05), 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_property(play_btn, "scale", Vector2.ONE, 1.1).set_trans(Tween.TRANS_SINE)
	start_panel = _build_start()
	return c


func _on_play() -> void:
	if int(opts.get("cp", 0)) > 0:
		menu.visible = false
		start_cp_info.text = "ROOM %d  ·  %.1f KM" % [int(opts.cp) + 1, int(opts.cp) * 0.2]
		_fade_in(start_panel)
	else:
		start_from.emit(0)


## where to start: the beginning, or the last door you reached
func _build_start() -> Control:
	var c := _card()
	var box: VBoxContainer = c[1]
	box.custom_minimum_size = Vector2(560, 0)
	var t := _label("START FROM", f800, 26, Color(1, 1, 1, 0.7))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(t)
	_gap(box, 4)
	var b0 := _button("The beginning", false, 460)
	b0.custom_minimum_size = Vector2(460, 84)
	b0.pressed.connect(func():
		c[0].visible = false
		start_from.emit(0))
	box.add_child(b0)
	start_cp_btn = _button("Last checkpoint", true, 460)
	start_cp_btn.custom_minimum_size = Vector2(460, 84)
	start_cp_btn.pressed.connect(func():
		c[0].visible = false
		start_from.emit(int(opts.get("cp", 0))))
	box.add_child(start_cp_btn)
	start_cp_info = _label("", f800, 18, ACCENT)
	start_cp_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(start_cp_info)
	_gap(box, 4)
	var back := IconButton.new("close", 64.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func():
		c[0].visible = false
		_fade_in(menu))
	box.add_child(back)
	return c[0]


func _build_levels() -> Control:
	# (the home screen holds the modes now)
	var c := _screen()
	return c


# ---------- settings ----------
var switches := {}
var quality_btns: Array = []
var reset_btn: Button
var _reset_armed := false


func _setting_row(box: VBoxContainer, title: String, key: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var l := _label(title, f600, 30)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(l)
	var sw := Switch.new()
	sw.pressed.connect(func():
		opts[key] = sw.on
		setting_changed.emit(key, sw.on))
	row.add_child(sw)
	switches[key] = sw
	box.add_child(row)
	var line := ColorRect.new()
	line.color = Color(1, 1, 1, 0.08)
	line.custom_minimum_size = Vector2(0, 2)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(line)


func _build_settings() -> Control:
	var c := _card()
	var box: VBoxContainer = c[1]
	box.custom_minimum_size = Vector2(620, 0)
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	var head := HBoxContainer.new()
	var t := _label("Settings", f800, 46)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var x := IconButton.new("close", 58.0)
	x.pressed.connect(func():
		c[0].visible = false
		_reset_armed = false
		if _settings_from:
			_fade_in(_settings_from))
	head.add_child(x)
	box.add_child(head)
	_gap(box, 6)
	_setting_row(box, "Music", "music")
	_setting_row(box, "Sound", "sound")
	_setting_row(box, "Vibration", "vibe")
	var qrow := HBoxContainer.new()
	qrow.add_theme_constant_override("separation", 10)
	var ql := _label("Graphics", f600, 30)
	ql.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ql.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	qrow.add_child(ql)
	for q in [["Smooth", 0], ["Rich", 1]]:
		var b := _button(q[0], false, 130)
		b.custom_minimum_size = Vector2(130, 56)
		b.add_theme_font_size_override("font_size", 22)
		b.set_meta("v", q[1])
		b.pressed.connect(func():
			opts["quality"] = b.get_meta("v")
			setting_changed.emit("quality", opts.quality)
			_paint_quality())
		quality_btns.append(b)
		qrow.add_child(b)
	box.add_child(qrow)
	_gap(box, 14)
	reset_btn = _button("Reset progress", false, 300)
	reset_btn.custom_minimum_size = Vector2(300, 56)
	reset_btn.add_theme_font_size_override("font_size", 22)
	reset_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	reset_btn.pressed.connect(func():
		if not _reset_armed:
			_reset_armed = true
			reset_btn.text = "Tap again to reset"
		else:
			_reset_armed = false
			reset_btn.text = "Progress reset"
			setting_changed.emit("reset", true))
	box.add_child(reset_btn)
	var ver := _label("GLASS RUN  ·  VERSION 0.4", f800, 16, Color(1, 1, 1, 0.4))
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ver)
	c[0].set_meta("rows", [])
	return c[0]


func _paint_quality() -> void:
	for b in quality_btns:
		b.theme_type_variation = "Primary" if int(opts.get("quality", 1)) == int(b.get_meta("v")) else ""


func _card() -> Array:
	var wrap := _screen()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.03, 0.62)
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


## a bare screen with a dark veil, things set straight on it (no card)
func _veil() -> Array:
	var wrap := _screen()
	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.015, 0.03, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(dim)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(col)
	return [wrap, col]


func _icon_row(col: VBoxContainer, items: Array) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 46)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(row)
	for it in items:
		var b := IconButton.new(it[0], it[1], it[2])
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(it[3])
		row.add_child(b)


# ---------- pause ----------
func _build_pause() -> Control:
	var c := _veil()
	var col: VBoxContainer = c[1]
	pause_title = _label("PAUSED", title_font, 72)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(pause_title)
	_gap(col, 30)
	_icon_row(col, [
		["home", 96.0, false, func(): menu_pressed.emit()],
		["play", 140.0, true, func(): resume_pressed.emit()],
		["retry", 96.0, false, func(): restart_pressed.emit()],
	])
	_gap(col, 26)
	var sg := IconButton.new("gear", 64.0)
	sg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sg.pressed.connect(func(): show_settings(pause_panel))
	col.add_child(sg)
	return c[0]


# ---------- the end of a run ----------
var over_badge: Label


func _build_over() -> Control:
	var c := _veil()
	var col: VBoxContainer = c[1]
	over_title = _label("RUN OVER", f800, 28, Color(1, 1, 1, 0.7))
	over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(over_title)
	over_big = _label("0 m", title_font, 128, INK)
	over_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(over_big)
	over_badge = _label("NEW BEST", f800, 26, GOLD)
	over_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(over_badge)
	over_sub = _label("", f800, 22, Color(1, 1, 1, 0.65))
	over_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(over_sub)
	_gap(col, 26)
	_icon_row(col, [
		["home", 96.0, false, func(): menu_pressed.emit()],
		["retry", 140.0, true, func(): restart_pressed.emit()],
	])
	_gap(col, 18)
	cont_btn = _button("Continue from checkpoint", false, 460)
	cont_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cont_btn.pressed.connect(func(): continue_pressed.emit())
	col.add_child(cont_btn)
	return c[0]


func _build_done() -> Control:
	var c := _veil()
	var col: VBoxContainer = c[1]
	done_title = _label("FIRST LIGHT", f800, 28, Color(1, 1, 1, 0.7))
	done_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(done_title)
	var big := _label("COMPLETE", title_font, 96, INK)
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(big)
	var stars := HBoxContainer.new()
	stars.alignment = BoxContainer.ALIGNMENT_CENTER
	stars.add_theme_constant_override("separation", 18)
	col.add_child(stars)
	for i in 3:
		var s := _label("★", f800, 72, Color(1, 1, 1, 0.15))
		s.pivot_offset = Vector2(26, 44)
		stars.add_child(s)
		done_stars.append(s)
	done_rows = _label("", f800, 22, Color(1, 1, 1, 0.65))
	done_rows.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(done_rows)
	done_unlock = _label("", f800, 20, GOLD)
	done_unlock.visible = false
	col.add_child(done_unlock)
	_gap(col, 22)
	_icon_row(col, [
		["home", 96.0, false, func(): menu_pressed.emit()],
		["play", 140.0, true, func(): play_mode.emit("endless")],
		["retry", 96.0, false, func(): restart_pressed.emit()],
	])
	return c[0]


# ---------- switching screens ----------
func _hide_all() -> void:
	for sc in [menu, levels, settings, pause_panel, over_panel, done_panel, start_panel]:
		if sc:
			sc.visible = false
	hud.visible = false


func apply_settings(save: Dictionary) -> void:
	opts = save
	for k in switches:
		var sw: Switch = switches[k]
		sw.on = bool(save.get(k, true))
		sw._k = 1.0 if sw.on else 0.0
		sw.queue_redraw()
	_paint_quality()
	if reset_btn:
		reset_btn.text = "Reset progress"


func _km(m: int) -> String:
	return ("%.2f km" % (m / 1000.0)) if m >= 1000 else ("%d m" % m)


func show_menu(save: Dictionary) -> void:
	opts = save
	_hide_all()
	var best := int(save.get("best", 0))
	best_label.text = ("BEST  " + _km(best).to_upper()) if best > 0 else "TAP TO PLAY"
	_fade_in(menu)


func show_levels(save: Dictionary) -> void:
	show_menu(save)


func show_settings(from: Control = null) -> void:
	_settings_from = from
	if from:
		from.visible = false
	apply_settings(opts)
	_fade_in(settings)


func show_play(_mode: String) -> void:
	_hide_all()
	hud.visible = true
	toast.modulate.a = 0.0


func show_pause(mode: String) -> void:
	_fade_in(pause_panel)


func show_over_endless(d: int, best: int, cp: int, new_best: bool, score: int) -> void:
	_hide_all()
	over_title.text = "RUN OVER"
	over_big.text = _km(d)
	over_badge.visible = new_best
	over_sub.text = ("BEST  " + _km(best).to_upper()) if not new_best else ""
	cont_btn.visible = cp > 0
	cont_btn.text = "Continue from room %d" % (cp / 200 + 1)
	_fade_in(over_panel)


func show_over_level(d: int, total: int, score: int) -> void:
	_hide_all()
	over_title.text = "FIRST LIGHT"
	over_big.text = "%d%%" % int(100.0 * d / maxf(1.0, total))
	over_badge.visible = false
	over_sub.text = "OF THE WAY THROUGH"
	cont_btn.visible = false
	_fade_in(over_panel)


func show_done(s: Dictionary) -> void:
	_hide_all()
	done_rows.text = "ACCURACY %d%%   ·   GLASS %d" % [int(s.acc * 100.0), s.glass]
	_fade_in(done_panel)
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
