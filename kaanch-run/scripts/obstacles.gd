## Every kind of glass in the way. Each builder puts one obstacle at distance d (some spread over a few metres).
## Easy ones first; moving ones; ones with a trick to them; and the prism.
class_name Obstacles
extends RefCounted

const EYE := 2.2
const W := 2.4      # half the width of a full pane
const Y0 := 0.05
const Y1 := 3.9
const HALF := 6.2   # half the width of a door

# what unlocks when (by room in the endless run)
const POOL := [
	["pane", "split", "grid", "layers", "stack", "color_row", "tempered", "frosted"],
	["slide", "doors", "rise", "hinge", "weak", "laminated", "shy", "blocks"],
	["spinner", "rotor", "pendulum", "prism", "mirror", "orbit", "blast"],
	["snake", "shield", "grille", "collapse", "halves"],
	["flyin", "shutters", "revolving", "charge"],
]
# the ones that look right floating in the open sky (nothing standing on a floor or hanging from a roof)
const SKY_OK := ["giant", "slide_block", "fall_blocks", "scissors", "saw_disc", "diag_blade", "blade_line", "chessboard", "tile_rain", "rot_grid", "hole_glass", "tube", "twotone", "domino", "blocks", "pane", "split", "grid", "layers", "stack", "color_row", "tempered", "frosted", "slide", "rise", "hinge", "weak", "laminated", "shy", "spinner", "rotor", "prism", "mirror", "orbit", "blast", "snake", "shield", "halves", "flyin", "charge", "shutters"]
# gentler ones for the calm mode
const CALM := ["pane", "split", "grid", "layers", "stack", "color_row", "tempered", "slide", "rise", "spinner", "orbit", "prism", "blast", "collapse", "halves", "rotor"]


static func pool_for(room: int) -> Array:
	var out := []
	for i in mini(room + 1, POOL.size()):
		out.append_array(POOL[i])
	return out


static func full(x0 := -W, x1 := W) -> PackedVector2Array:
	return Glass.rect(x0, x1, Y0, Y1)


## every obstacle, and then what holds its glass up (frames, rails, posts, axles)
static func build(G, type: String, d: float, r: int) -> void:
	var n0: int = G.gates.size()
	_build(G, type, d, r)
	G.mount(n0, type)


static func _build(G, type: String, d: float, r: int) -> void:
	# the prism worked by colour; with all glass one colour it is layers of glass instead
	if type == "prism":
		type = "layers"
	var g: GGate = G.new_gate(type, d)
	var s := g.side
	match type:
		"pane":
			G.pane(g, full(), d, G.rng_kind(r), G.rng_color(0.35))
		"split":
			var cut := s * randf_range(0.5, 1.2)
			var thin_left := randf() < 0.5
			G.pane(g, full(-W, cut - 0.03), d, "thin" if thin_left else "thick", G.rng_color(0.3))
			G.pane(g, full(cut + 0.03, W), d, "thick" if thin_left else "thin", G.rng_color(0.3))
		"grid":
			for cx in 3:
				for cy in 3:
					var x0 := -W + cx * 1.6
					var y0 := Y0 + cy * 1.135
					G.pane(g, Glass.rect(x0 + 0.03, x0 + 1.57, y0 + 0.03, y0 + 1.1), d, G.rng_kind(r), G.rng_color(0.4))
		"stack":
			for i in 5:
				var x0 := -W + i * 0.96
				G.pane(g, Glass.rect(x0 + 0.04, x0 + 0.92, 0.4, 4.0), d, G.rng_kind(r), G.rng_color(0.4))
		"color_row":
			# four tall panes of colour: shoot the same colour in a row for a combo
			var c0 := randi() % Glass.COLORS.size()
			for i in 3:
				var x0 := -W + i * 1.6
				G.pane(g, Glass.rect(x0 + 0.03, x0 + 1.57, Y0, Y1), d, "mid", (c0 + (i % 2)) % Glass.COLORS.size())
		"layers":
			var n := 2 if r < 2 else 3
			for i in n:
				var gi: GGate = g if i == 0 else G.new_gate("layers", d + i * 3.2)
				var w := randf_range(1.0, 1.8)
				var h := randf_range(1.0, 1.6)
				var ox := randf_range(-0.4, 0.4)
				var oy := randf_range(-0.3, 0.3)
				var poly := Glass.rect(ox - w, ox + w, EYE + oy - h, EYE + oy + h) if randf() < 0.6 else Glass.ngon(6, randf_range(1.2, 1.5), Vector2(ox, EYE + oy), PI / 6.0)
				G.pane(gi, poly, d + i * 3.2, ["thin", "mid", "thick"].pick_random(), G.rng_color(0.3))
		"tempered":
			G.pane(g, full(), d, "tempered")
		"frosted":
			# a frosted pane, and another one hiding just behind it
			G.pane(g, full(), d, "frosted")
			var g2: GGate = G.new_gate("frosted", d + 1.6)
			G.pane(g2, Glass.rect(-1.4, 1.4, 1.0, 3.4), d + 1.6, "thin", G.rng_color(0.5))
		# ---- moving ----
		"slide":
			var p: GPane = G.pane(g, Glass.rect(-1.3, 1.3, 0.6, 3.8), d, "mid" if r < 3 else "thick", G.rng_color(0.3))
			var sp := 1.2 + randf() * 0.7
			var ph := g.ph
			p.move = func(pp: GPane, t: float, _a: float): pp.node.transform = pp.base.translated(Vector3(sin(t * sp + ph) * 1.5, 0, 0))
		"rise":
			var p: GPane = G.pane(g, full(), d, "mid", G.rng_color(0.3))
			var sp := 1.0 + randf() * 0.6
			var ph := g.ph
			p.move = func(pp: GPane, t: float, _a: float): pp.node.transform = pp.base.translated(Vector3(0, (0.5 - 0.5 * cos(t * sp + ph)) * 2.2, 0))
		"doors":
			for i in 2:
				var sd := -1.0 if i == 0 else 1.0
				var p: GPane = G.pane(g, full(-W, 0.0) if i == 0 else full(0.0, W), d, "mid" if r < 3 else "thick", G.rng_color(0.3))
				p.move = func(pp: GPane, _t: float, ahead: float):
					var k := clampf((ahead - 4.0) / 10.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(sd * 2.6 * k * k * (3.0 - 2.0 * k), 0, 0))
		"flyin":
			# panes rush in from both sides at the last moment
			for i in 2:
				var sd := -1.0 if i == 0 else 1.0
				var p: GPane = G.pane(g, full(-W, 0.0) if i == 0 else full(0.0, W), d, "thin", G.rng_color(0.5))
				p.move = func(pp: GPane, _t: float, ahead: float):
					var k := clampf((ahead - 5.0) / 6.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(sd * 7.0 * k * k, 0, 0))
		"rotor":
			var w := randf_range(0.7, 2.2) * s
			var bars := 1 if r < 4 else 2
			var bk: String = ["thin", "mid", "thick", "slab"][mini(3, randi() % (2 + r / 2))]
			var bh := randf_range(0.32, 0.55)
			for i in bars:
				var p: GPane = G.pane(g, Glass.rect(-2.2, 2.2, EYE - bh, EYE + bh), d - i * 0.05, bk, G.rng_color(0.3))
				var off := randf() * PI + i * PI * 0.5
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * w)
		"spinner":
			var hub := Vector2(s * 1.1, EYE + 0.55)
			var w := randf_range(0.9, 1.9 + minf(r, 6) * 0.1) * (1 if randf() < 0.5 else -1)
			var a0 := randf() * TAU
			var blade := PackedVector2Array([Vector2(0.35, -0.28), Vector2(2.7, -0.16), Vector2(2.9, 0.0), Vector2(2.7, 0.16), Vector2(0.35, 0.28)])
			var blades := []
			for i in 3:
				var p: GPane = G.pane(g, Glass.moved(blade, hub), d, ["thin", "mid", "thick"][mini(2, randi() % (1 + r / 2))], G.rng_color(0.3))
				var off := a0 + TAU * i / 3.0
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, hub, off + t * w)
				blades.append(p)
			var tg = G.target("hub", Vector3(hub.x, hub.y, -d + 0.12), 0.42, g)
			tg.on_hit = func(): G.break_all(blades, "Fan down", 2)
		"pendulum":
			var L := 3.9
			var pivot := Vector2(0, EYE + L)
			var p: GPane = G.pane(g, Glass.ngon(8, 1.05, Vector2(0, EYE), PI / 8.0), d, "thick" if r < 5 else "slab")
			G.chain(p, Vector3(0, 1.0, 0), L - 1.0)
			var amp := 0.62
			var ws := 1.55 + minf(r, 6) * 0.05
			var ph := g.ph
			p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, pivot, sin(t * ws + ph) * amp)
		"orbit":
			# a coloured pane in the middle, small panes of colour circling it (shoot them for the combo)
			var c0 := randi() % Glass.COLORS.size()
			G.pane(g, Glass.ngon(6, 0.95, Vector2(0, EYE), PI / 6.0), d, "mid", c0)
			var n := 6
			var w := (0.9 + randf() * 0.4) * s
			for i in n:
				var p: GPane = G.pane(g, Glass.ngon(4, 0.38, Vector2(1.75, EYE), PI / 4.0), d + 0.1, "thin", (c0 + (i % 2)) % Glass.COLORS.size(), false)
				var off := TAU * i / n
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * w)
		"snake":
			var list := []
			var c0 := randi() % Glass.COLORS.size()
			for i in 10:
				var head := i == 0
				var sc := 1.0 if head else 0.88 * (1.0 - i / 14.0)
				var bx := 0.0 if head else s * (0.95 + 0.34 * i)
				var by := EYE + (0.0 if head else 0.12 * i)
				var w := 0.95 if head else 0.6 * sc
				var h := 0.8 if head else 0.5 * sc
				var poly := PackedVector2Array([Vector2(bx - w, by), Vector2(bx - w * 0.5, by - h), Vector2(bx + w * 0.5, by - h), Vector2(bx + w, by), Vector2(bx + w * 0.5, by + h), Vector2(bx - w * 0.5, by + h)])
				var p: GPane = G.pane(g, poly, d + i * 1.15, "mid" if head else "thin", c0 if i % 2 == 0 else (c0 + 2) % Glass.COLORS.size(), head)
				var amp := 0.3 if head else 0.42
				var lag := i * 0.34
				p.move = func(pp: GPane, t: float, _a: float):
					var ph := t * 2.1 - lag
					pp.node.transform = Transform3D(Basis(Vector3(0, 0, 1), cos(ph) * 0.2), pp.base.origin + Vector3(sin(ph) * amp, cos(ph * 0.8) * 0.16, 0))
				list.append(p)
			list[0].on_break = func(): G.chain_break(list.slice(1), "Serpent down", 3)
		"shutters":
			# slats that open and shut on the beat of the music
			for i in 4:
				var y0 := Y0 + i * 0.86
				var p: GPane = G.pane(g, Glass.rect(-W, W, y0 + 0.02, y0 + 0.84), d, "thin", G.rng_color(0.3))
				var cy := y0 + 0.43
				p.move = func(pp: GPane, _t: float, _a: float):
					var b: float = G.beat()
					var open := clampf(sin(b * TAU) * 1.6, 0.0, 1.0)
					var a := open * PI * 0.5
					var bs := Basis(Vector3(1, 0, 0), a)
					var o := pp.base.origin - Vector3(0, cy, pp.base.origin.z)
					pp.node.transform = Transform3D(bs, Vector3(0, cy, pp.base.origin.z) + bs * o)
		"revolving":
			# a revolving door of glass, its post off to one side
			var ax := s * 1.2
			var w := 1.1 * -s
			for i in 4:
				var p: GPane = G.pane(g, Glass.rect(0.15, 2.3, Y0, Y1), d, "thin", G.rng_color(0.3))
				var off := TAU * i / 4.0 + randf() * 0.3
				p.move = func(pp: GPane, t: float, _a: float):
					var bs := Basis(Vector3(0, 1, 0), off + t * w)
					pp.node.transform = Transform3D(bs, Vector3(ax, 0, pp.base.origin.z)) * Transform3D(Basis(), Vector3(pp.base.origin.x, pp.base.origin.y, 0))
			G.post(g, Vector3(ax, 0, -d))
		"drop":
			# glass falling from the sky into the way as you come
			var n := 1 if r < 2 else 2
			for i in n:
				var poly := full() if n == 1 else (full(-W, 0.0) if i == 0 else full(0.0, W))
				var p: GPane = G.pane(g, poly, d, "mid" if r < 3 else ["mid", "thick"].pick_random(), -1)
				var late := 2.5 * i
				p.move = func(pp: GPane, _t: float, ahead: float):
					var k := clampf((ahead - 13.0 - late) / 14.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(0, 16.0 * k * k, 0))
		"blocks":
			# a wall of glass bricks with one gap: break your way through, or find the gap
			var gap := randi() % 3
			var wall := []
			for cx in 3:
				for cy in 3:
					if cx == gap and cy == 1:
						continue
					var x0 := -W + cx * 1.6
					var y0 := Y0 + cy * 1.135
					wall.append(G.pane(g, Glass.rect(x0 + 0.04, x0 + 1.56, y0 + 0.04, y0 + 1.09), d, "block" if (cx + cy) % 2 == 0 else "thick"))
			# one wall: a hit anywhere brings all of it down
			for q in wall:
				q.hp = 1
			G.link(wall)
		# ---- big glass ----
		"giant":
			# a cube of glass as wide as the way, two metres deep: two hits
			G.pane(g, Glass.rect(-HALF, HALF, 0.05, Worlds.CEIL - 0.3), d, "giant")
		"slide_block":
			# a block sliding from side to side: slip past it, or break it
			var p: GPane = G.pane(g, Glass.rect(-1.5, 1.5, 0.2, 4.4), d, "block")
			var sp := randf_range(0.9, 1.5)
			var ph := g.ph
			p.move = func(pp: GPane, t: float, _a: float): pp.node.transform = pp.base.translated(Vector3(sin(t * sp + ph) * 2.6, 0, 0))
		"fall_blocks":
			# tall blocks dropping one after another, landing three or four seconds before you get there
			for i in 3:
				var bx: float = [-0.9, 0.9, 0.0][i] * s
				var dz := d + i * 5.0
				var gi: GGate = g if i == 0 else G.new_gate("fall_blocks", dz)
				var p: GPane = G.pane(gi, Glass.rect(bx - 1.4, bx + 1.4, 0.05, 5.2), dz, "block")
				var landed := [false]
				var secs := 3.6 - i * 0.25
				p.move = func(pp: GPane, _t: float, ahead: float):
					var land: float = maxf(G.speed, 6.0) * secs
					var k := clampf((ahead - land) / 7.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(0, 15.0 * k * k, 0))
					if k <= 0.0 and not landed[0]:
						landed[0] = true
						G.thump(pp.node.global_transform.origin)
		# ---- blades ----
		"pendulum_blade":
			# a long blade hanging from above, swinging across
			var top := 7.2
			var blade := PackedVector2Array([Vector2(-0.25, top), Vector2(0.25, top), Vector2(0.55, EYE - 0.4), Vector2(0.0, EYE - 1.3), Vector2(-0.55, EYE - 0.4)])
			var p: GPane = G.pane(g, blade, d, "thick" if r >= 3 else "mid")
			var amp := randf_range(0.45, 0.6)
			var ws := randf_range(1.3, 2.0)
			var ph := g.ph
			p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, top), sin(t * ws + ph) * amp)
		"scissors":
			# two long blades that open and close like scissors
			var c := Vector2(0, EYE)
			var ws := randf_range(1.4, 2.2)
			var ph := g.ph
			for i in 2:
				var sd := -1.0 if i == 0 else 1.0
				var p: GPane = G.pane(g, Glass.rect(-3.4, 3.4, EYE - 0.22, EYE + 0.22), d + i * 0.12, "thick" if r >= 4 else "mid")
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, c, sd * (0.12 + 0.55 * (0.5 + 0.5 * sin(t * ws + ph))))
		"saw_disc":
			# a round blade of glass running along the way, turning
			var p: GPane = G.pane(g, Glass.ngon(16, 1.35, Vector2(0, EYE - 0.3)), d, "thick")
			var sp := randf_range(0.8, 1.4)
			var ph := g.ph
			var cy := EYE - 0.3
			p.move = func(pp: GPane, t: float, _a: float):
				var b := Basis(Vector3(0, 0, 1), t * 5.0)
				pp.node.transform = Transform3D(b, Vector3(sin(t * sp + ph) * 2.9, cy, pp.base.origin.z))
		"diag_blade":
			# blades cutting across from corner to corner
			for i in 2:
				var dir := Vector2(0.75, 0.66) if i == 0 else Vector2(-0.75, 0.66)
				var poly := Glass.turned(Glass.rect(-2.0, 2.0, -0.2, 0.2), (PI * 0.25) * (1.0 if i == 0 else -1.0))
				var p: GPane = G.pane(g, Glass.moved(poly, Vector2(0, EYE)), d + i * 2.5, "mid" if r < 4 else "thick")
				var sp := randf_range(1.0, 1.6)
				var ph := g.ph + i * 1.7
				p.move = func(pp: GPane, t: float, _a: float):
					var o := dir * sin(t * sp + ph) * 2.2
					pp.node.transform = pp.base.translated(Vector3(o.x, o.y, 0))
		"blade_line":
			# four turning blades in a row, each at its own speed: find the gaps
			for i in 4:
				var dz := d + i * 3.0
				var gi: GGate = g if i == 0 else G.new_gate("blade_line", dz)
				var w := randf_range(0.8, 2.4) * (1.0 if i % 2 == 0 else -1.0)
				var off := randf() * PI
				var p: GPane = G.pane(gi, Glass.rect(-2.3, 2.3, EYE - 0.3, EYE + 0.3), dz, ["mid", "thick"][i % 2] if r >= 3 else "mid")
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * w)
		# ---- doors that move by themselves ----
		"sensor_door":
			# opens as you come; now and then it sticks shut
			_doors(G, g, d, "stick" if randf() < 0.45 else "open", r)
		"closing_doors":
			# open, but they slide shut as you come
			_doors(G, g, d, "close", r)
		"door_line":
			# three doors in a row, each with its own mind
			var modes := ["open", "close", "stick"]
			modes.shuffle()
			for i in 3:
				var dz := d + i * 6.0
				var gi: GGate = g if i == 0 else G.new_gate("door_line", dz)
				_doors(G, gi, dz, modes[i], r)
		"shutter_door":
			# a shutter of glass coming down from above
			var p: GPane = G.pane(g, Glass.rect(-HALF, HALF, 0.05, Worlds.CEIL - 0.2), d, "mid" if r < 4 else "thick")
			p.move = func(pp: GPane, _t: float, ahead: float):
				var k := clampf((ahead - 9.0) / 12.0, 0.0, 1.0)
				pp.node.transform = pp.base.translated(Vector3(0, 6.3 * k, 0))
			G._frame(g, d, Color("9fe8e0"))
		"button_door":
			# a heavy door: hit the button and it opens; or break it, which costs
			var parts := []
			for i in 2:
				parts.append(G.pane(g, Glass.rect(-HALF, 0.0, 0.05, Worlds.CEIL - 0.2) if i == 0 else Glass.rect(0.0, HALF, 0.05, Worlds.CEIL - 0.2), d, "slab"))
			var open := [-1.0]
			for i in 2:
				var sd := -1.0 if i == 0 else 1.0
				var p: GPane = parts[i]
				p.move = func(pp: GPane, t: float, _a: float):
					if open[0] < 0.0:
						return
					var k := clampf((t - open[0]) / 0.6, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(sd * 4.6 * k * k * (3.0 - 2.0 * k), 0, 0))
					if k >= 1.0:
						pp.opened = true
			var tg = G.target("button", Vector3(s * randf_range(1.2, 3.2), randf_range(1.0, 4.6), -d + 0.4), 0.45, g)
			tg.on_hit = func(): open[0] = G.t
			G._frame(g, d, Color("ffc861"))
		# ---- squares ----
		"chessboard":
			# thick and thin squares, one after the other: break the thin ones
			for cx in 4:
				for cy in 3:
					var x0 := -2.4 + cx * 1.2
					var y0 := 0.5 + cy * 1.2
					G.pane(g, Glass.rect(x0 + 0.03, x0 + 1.17, y0 + 0.03, y0 + 1.17), d, "slab" if (cx + cy) % 2 == 0 else "thin")
		"tile_rain":
			# small squares falling from above into the way
			var spots := []
			for cx in 4:
				for cy in 3:
					spots.append(Vector2(-1.8 + cx * 1.2, 1.1 + cy * 1.2))
			spots.shuffle()
			for i in 7:
				var c: Vector2 = spots[i]
				if i == 0:
					c = Vector2(0.0, EYE)
				var p: GPane = G.pane(g, Glass.rect(c.x - 0.55, c.x + 0.55, c.y - 0.55, c.y + 0.55), d + randf_range(-0.6, 0.6), "mid")
				var late := randf_range(0.0, 8.0)
				p.move = func(pp: GPane, _t: float, ahead: float):
					var k := clampf((ahead - 10.0 - late) / 8.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(0, 12.0 * k * k, 0))
		"rot_grid":
			# a whole grid of squares turning slowly
			var w := randf_range(0.35, 0.7) * s
			for cx in 3:
				for cy in 3:
					var x0 := -1.8 + cx * 1.2
					var y0 := EYE - 1.8 + cy * 1.2
					var p: GPane = G.pane(g, Glass.rect(x0 + 0.03, x0 + 1.17, y0 + 0.03, y0 + 1.17), d, "thick" if (cx + cy) % 2 == 0 else "mid")
					p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), t * w)
		"popout":
			# squares sliding out of the walls into the way
			var spots := [Vector2(-1.2, 1.1), Vector2(1.2, 1.1), Vector2(0.0, EYE), Vector2(-1.2, 3.3), Vector2(1.2, 3.3), Vector2(0.0, 4.4)]
			for c in spots:
				var from := -6.0 if c.x < 0.0 or (c.x == 0.0 and randf() < 0.5) else 6.0
				var p: GPane = G.pane(g, Glass.rect(c.x - 0.58, c.x + 0.58, c.y - 0.55, c.y + 0.55), d, "thick" if r >= 3 else "mid")
				var late := randf_range(0.0, 4.0)
				p.move = func(pp: GPane, _t: float, ahead: float):
					var k := clampf((ahead - 8.0 - late) / 9.0, 0.0, 1.0)
					pp.node.transform = pp.base.translated(Vector3(from * k, 0, 0))
		"hole_glass":
			# a big pane with a square hole in it: a marble through the hole is wasted
			var hx := randf_range(-1.2, 1.2)
			var hy := 3.6 if randf() < 0.5 else 1.2
			var parts := [
				G.pane(g, Glass.rect(-2.4, hx - 0.6, 0.4, 4.4), d, "mid"),
				G.pane(g, Glass.rect(hx + 0.6, 2.4, 0.4, 4.4), d, "mid"),
				G.pane(g, Glass.rect(hx - 0.6, hx + 0.6, 0.4, hy - 0.6), d, "mid"),
				G.pane(g, Glass.rect(hx - 0.6, hx + 0.6, hy + 0.6, 4.4), d, "mid"),
			]
			parts = parts.filter(func(q): return Glass.area(q.poly) > 0.05)
			G.link(parts)
		# ---- other glass ----
		"tube":
			# rings of glass to fly through, and a pane at the far end
			var c := Vector2(0, 3.0)
			for k in 4:
				var dz := d + k * 2.2
				var gi: GGate = g if k == 0 else G.new_gate("tube", dz)
				for i in 10:
					var poly := Glass.moved(Glass.turned(Glass.wedge(2.45, 2.85, PI / 10.0 - 0.025), TAU * i / 10.0), c)
					var p: GPane = G.pane(gi, poly, dz, "mid", -1, false)
					p.bonus = 5
			var gc: GGate = G.new_gate("tube", d + 9.0)
			G.pane(gc, Glass.ngon(10, 1.5, Vector2(0, EYE)), d + 9.0, "thin")
		"twotone":
			# half thin, half very thick, one pane: hit the thin side and it all goes
			var cut := randf_range(-0.6, 0.6)
			var thin_left := randf() < 0.5
			var a: GPane = G.pane(g, full(-W, cut), d, "thin" if thin_left else "slab")
			var b: GPane = G.pane(g, full(cut, W), d, "slab" if thin_left else "thin")
			G.link([a, b])
		"domino":
			# tall panes joined by a bar: break one and the rest follow
			var list := []
			for i in 5:
				var x0 := -W + i * 0.96
				list.append(G.pane(g, Glass.rect(x0 + 0.04, x0 + 0.92, 0.3, 4.2), d, "mid" if r < 3 else "thick"))
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			Worlds.box(st, Vector3(0, 4.35, 0), Vector3(W * 2.0, 0.1, 0.1), Color("4a525c"))
			st.set_material(Worlds.lit_mat)
			var m := MeshInstance3D.new()
			m.mesh = st.commit()
			m.position = Vector3(0, 0, -d)
			G.decor(g, m)
			var fired := [false]
			for p in list:
				var pp: GPane = p
				pp.on_break = func():
					if fired[0]:
						return
					fired[0] = true
					G.chain_break(list, "Domino!", 1)
		# ---- tricks ----
		"hinge":
			# thick glass on a hinge: hit it near the far edge and it swings open
			var p: GPane = G.pane(g, full(), d, "thick", G.rng_color(0.3))
			p.hinge = s
			G.hinge_marks(p)
		"weak":
			var p: GPane = G.pane(g, Glass.rect(-2.0, 2.0, 0.7, 3.7), d, "slab")
			p.weak = Vector2(randf_range(-1.2, 1.2), randf_range(-0.9, 0.9))
			G.weak_mark(p)
		"laminated":
			G.pane(g, full(), d, "laminated")
		"shy":
			var p: GPane = G.pane(g, Glass.rect(-1.5, 1.5, 0.7, 3.7), d, "mid", G.rng_color(0.4))
			p.shy = true
			p.hp = 2
		"halves":
			var p: GPane = G.pane(g, full(), d, "mid", G.rng_color(0.5))
			p.splits = true
		"mirror":
			G.pane(g, Glass.rect(-1.9, 1.9, 0.6, 3.8), d, "mirror")
		"blast":
			# a grid of glass with blast glass in the middle: hit that and the lot goes
			for cx in 3:
				for cy in 3:
					var x0 := -W + cx * 1.6
					var y0 := Y0 + cy * 1.135
					var mid := cx == 1 and cy == 1
					G.pane(g, Glass.rect(x0 + 0.03, x0 + 1.57, y0 + 0.03, y0 + 1.1), d, "blast" if mid else "mid", -1 if mid else G.rng_color(0.3))
		"shield":
			# a golden heart behind shields that turn in front of it
			G.pane(g, Glass.ngon(12, 0.6, Vector2(0, EYE)), d, "thick", 1)
			var w := (1.2 + minf(r, 6) * 0.08) * s
			for i in 3:
				var p: GPane = G.pane(g, Glass.moved(Glass.wedge(0.1, 1.15, PI / 6.0), Vector2(0, EYE)), d - 0.35, "mid", -1, false)
				var off := TAU * i / 3.0
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * w)
		"grille":
			# a steel grille: only the glowing button opens it
			G.grille(g, d, Vector3(s * randf_range(1.0, 2.2), randf_range(1.2, 3.4), -d + 0.2))
		"collapse":
			# a glass gallery held up by two glass pillars: break a pillar and it all comes down
			var curtain: GPane = G.pane(g, full(), d, "thick", G.rng_color(0.3))
			var roof := []
			for i in 3:
				var rp: GPane = G.pane(g, Glass.rect(-W, W, 0, 1.4), d + 0.2 + i * 1.4, "thin", G.rng_color(0.3), false)
				rp.node.transform = Transform3D(Basis(Vector3(1, 0, 0), -PI * 0.5), Vector3(0, Y1 + 0.05, -(d + 0.2 + i * 1.4)))
				rp.base = rp.node.transform
				roof.append(rp)
			for sd in [-1.0, 1.0]:
				var pil: GPane = G.pane(g, Glass.rect(sd * 3.0 - 0.32, sd * 3.0 + 0.32, 0.0, Y1), d - 0.1, "thin", 3, false)
				pil.supports = [curtain] + roof
		"charge":
			var p: GPane = G.pane(g, full(), d, "mid")
			p.charge = 0.0
		"prism":
			# a prism, and three rows of coloured glass after it: shoot the prism and its colour goes
			var c0 := randi() % Glass.COLORS.size()
			var c1 := (c0 + 2) % Glass.COLORS.size()
			G.prism(g, Vector3(s * 1.4, EYE + 1.2, -d), c0)
			for row in 3:
				var dz := d + 7.0 + row * 6.0
				var gi: GGate = G.new_gate("prism_row", dz)
				var n := 4
				for i in n:
					var x0 := -W + i * 1.2
					var col := c0 if (i == 1 or i == 2 or randf() < 0.4) else c1
					G.pane(gi, Glass.rect(x0 + 0.03, x0 + 1.17, Y0, Y1), dz, "mid", col)


## two door leaves that move as you come: "open" slide apart, "close" slide together, "stick" start to open and stop
static func _doors(G, g: GGate, d: float, how: String, r: int) -> void:
	for i in 2:
		var sd := -1.0 if i == 0 else 1.0
		var p: GPane = G.pane(g, Glass.rect(-HALF, 0.0, 0.05, Worlds.CEIL - 0.2) if i == 0 else Glass.rect(0.0, HALF, 0.05, Worlds.CEIL - 0.2), d, "mid" if r < 4 else "thick")
		p.move = func(pp: GPane, t: float, ahead: float):
			var k := clampf((24.0 - ahead) / 12.0, 0.0, 1.0)
			var open := 0.0
			match how:
				"open":
					open = k
				"close":
					open = 1.0 - k
				"stick":
					open = minf(k, 0.05) + (absf(sin(t * 40.0)) * 0.01 if k > 0.05 else 0.0)
			open = open * open * (3.0 - 2.0 * open)
			pp.node.transform = pp.base.translated(Vector3(sd * 4.6 * open, 0, 0))
	G._frame(g, d, Color("9fe8e0"))


## the end of a level: a great turning wheel of glass with a golden heart
# each world's great wheel: [inner ring, outer ring] colours, and the glass of the middle blades
const BOSS := {
	"cathedral": [[0, 4], [1, 2, 3, 0], "mid"],
	"venice": [[3, 2], [3, 2, 3, 2], "mid"],
	"lanterns": [[1, 0], [0, 1, 1, 0], "mid"],
	"mosaic": [[3, 2], [3, 2, 1, 3], "thick"],
	"sheesh": [[1, 4], [1, 1, 4, 1], "mirror"],
}


static func finale(G, d: float, style := "cathedral") -> void:
	var n0: int = G.gates.size()
	_finale(G, d, style)
	G.mount(n0, "finale")


static func _finale(G, d: float, style := "cathedral") -> void:
	var B: Array = BOSS.get(style, BOSS.cathedral)
	var g: GGate = G.new_gate("finale", d)
	g.finale = true
	var core: GPane = G.pane(g, Glass.ngon(12, 0.5, Vector2(0, EYE)), d, "thick", 1)
	var rest := []
	for i in 3:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(0.12, 1.0, PI / 6.0), Vector2(0, EYE)), d - 0.4, B[2], 3 if B[2] != "mirror" else -1, false)
		var off := TAU * i / 3.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * 1.2)
		rest.append(p)
	for i in 8:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(1.1, 1.65, PI / 8.0 - 0.03), Vector2(0, EYE)), d, "thin", B[0][i % 2], false)
		var off := TAU * i / 8.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off - t * 0.6)
		rest.append(p)
	for i in 12:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(1.75, 2.85, PI / 12.0 - 0.025), Vector2(0, EYE)), d + 0.05, "mid", B[1][i % 4], false)
		var off := TAU * i / 12.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * 0.35)
		rest.append(p)
	core.on_break = func(): G.finale_break(rest, d)
