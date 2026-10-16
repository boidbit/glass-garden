## Every kind of glass in the way. Each builder puts one obstacle at distance d (some spread over a few metres).
## Easy ones first; moving ones; ones with a trick to them; and the prism.
class_name Obstacles
extends RefCounted

const EYE := 2.2
const W := 2.4      # half the width of a full pane
const Y0 := 0.5
const Y1 := 3.9

# what unlocks when (by room in the endless run)
const POOL := [
	["pane", "split", "grid", "layers", "stack", "color_row", "tempered", "frosted"],
	["slide", "doors", "rise", "hinge", "weak", "laminated", "shy", "blocks"],
	["spinner", "rotor", "pendulum", "prism", "mirror", "orbit", "blast"],
	["snake", "shield", "grille", "collapse", "halves"],
	["flyin", "shutters", "revolving", "charge"],
]
# the ones that look right floating in the open sky (nothing standing on a floor or hanging from a roof)
const SKY_OK := ["blocks", "pane", "split", "grid", "layers", "stack", "color_row", "tempered", "frosted", "slide", "rise", "hinge", "weak", "laminated", "shy", "spinner", "rotor", "prism", "mirror", "orbit", "blast", "snake", "shield", "halves", "flyin", "charge", "shutters"]
# gentler ones for the calm mode
const CALM := ["pane", "split", "grid", "layers", "stack", "color_row", "tempered", "slide", "rise", "spinner", "orbit", "prism", "blast", "collapse", "halves", "rotor"]


static func pool_for(room: int) -> Array:
	var out := []
	for i in mini(room + 1, POOL.size()):
		out.append_array(POOL[i])
	return out


static func full(x0 := -W, x1 := W) -> PackedVector2Array:
	return Glass.rect(x0, x1, Y0, Y1)


static func build(G, type: String, d: float, r: int) -> void:
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
			var w := (1.0 + randf() * 0.5) * s
			var bars := 1 if r < 4 else 2
			for i in bars:
				var p: GPane = G.pane(g, Glass.rect(-2.1, 2.1, EYE - 0.42, EYE + 0.42), d - i * 0.05, "mid", G.rng_color(0.3))
				var off := randf() * PI + i * PI * 0.5
				p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * w)
		"spinner":
			var hub := Vector2(s * 1.1, EYE + 0.55)
			var w := (1.3 + minf(r, 6) * 0.07) * (1 if randf() < 0.5 else -1)
			var a0 := randf() * TAU
			var blade := PackedVector2Array([Vector2(0.35, -0.28), Vector2(2.7, -0.16), Vector2(2.9, 0.0), Vector2(2.7, 0.16), Vector2(0.35, 0.28)])
			var blades := []
			for i in 3:
				var p: GPane = G.pane(g, Glass.moved(blade, hub), d, "thin" if r < 4 else "mid", G.rng_color(0.3))
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
			for cx in 3:
				for cy in 3:
					if cx == gap and cy == 1:
						continue
					var x0 := -W + cx * 1.6
					var y0 := Y0 + cy * 1.135
					G.pane(g, Glass.rect(x0 + 0.04, x0 + 1.56, y0 + 0.04, y0 + 1.09), d, "block" if (cx + cy) % 2 == 0 else "thick")
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


## the end of a level: a great turning wheel of glass with a golden heart
static func finale(G, d: float) -> void:
	var g: GGate = G.new_gate("finale", d)
	g.finale = true
	var core: GPane = G.pane(g, Glass.ngon(12, 0.5, Vector2(0, EYE)), d, "thick", 1)
	var rest := []
	for i in 3:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(0.12, 1.0, PI / 6.0), Vector2(0, EYE)), d - 0.4, "mid", 3, false)
		var off := TAU * i / 3.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * 1.2)
		rest.append(p)
	for i in 8:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(1.1, 1.65, PI / 8.0 - 0.03), Vector2(0, EYE)), d, "thin", [0, 4][i % 2], false)
		var off := TAU * i / 8.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off - t * 0.6)
		rest.append(p)
	for i in 12:
		var p: GPane = G.pane(g, Glass.moved(Glass.wedge(1.75, 2.85, PI / 12.0 - 0.025), Vector2(0, EYE)), d + 0.05, "mid", [1, 2, 3, 0][i % 4], false)
		var off := TAU * i / 12.0
		p.move = func(pp: GPane, t: float, _a: float): G.spin_about(pp, Vector2(0, EYE), off + t * 0.35)
		rest.append(p)
	core.on_break = func(): G.finale_break(rest, d)
