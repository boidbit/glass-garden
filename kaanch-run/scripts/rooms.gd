## The 50 rooms of the endless run, made by hand: ten in each world, the tenth with a great wheel of glass.
## In one run no room comes twice; after the fiftieth they come again as a remix (faster, the other way round).
## Written out by a checker (sections in metres from the start of the room; obstacles as [metres, what, how hard]).
class_name Rooms
extends RefCounted

const COUNT := 50
const PER_WORLD := 10
const SECTS := [
	[],
	[[48.0, 144.0, "tunnel"]],
	[[32.0, 128.0, "hall"]],
	[[40.0, 128.0, "tunnel"]],
	[[48.0, 152.0, "sky"]],
	[[32.0, 112.0, "hall"]],
	[[40.0, 120.0, "tunnel"]],
	[[32.0, 144.0, "sky"]],
	[[48.0, 144.0, "hall"]],
	[[64.0, 128.0, "tunnel"]],
	[[32.0, 152.0, "sky"]],
	[[40.0, 136.0, "hall"]],
	[[32.0, 168.0, "sky"]],
	[[48.0, 128.0, "tunnel"]],
	[[32.0, 144.0, "sky"]],
	[[40.0, 120.0, "hall"]],
	[[32.0, 160.0, "sky"]],
	[[48.0, 112.0, "tunnel"]],
	[[32.0, 152.0, "sky"]],
	[[40.0, 136.0, "sky"]],
	[[32.0, 152.0, "tunnel"]],
	[[40.0, 136.0, "sky"]],
	[[32.0, 168.0, "tunnel"]],
	[[48.0, 144.0, "hall"]],
	[[32.0, 96.0, "tunnel"], [112.0, 176.0, "sky"]],
	[[40.0, 144.0, "tunnel"]],
	[[32.0, 152.0, "sky"]],
	[[48.0, 144.0, "tunnel"]],
	[[32.0, 128.0, "hall"]],
	[[40.0, 120.0, "tunnel"]],
	[[32.0, 144.0, "hall"]],
	[[40.0, 120.0, "tunnel"]],
	[[32.0, 160.0, "hall"]],
	[[48.0, 144.0, "sky"]],
	[[32.0, 128.0, "hall"]],
	[[40.0, 136.0, "tunnel"]],
	[[32.0, 144.0, "hall"]],
	[[48.0, 152.0, "sky"]],
	[[32.0, 128.0, "hall"]],
	[[40.0, 136.0, "hall"]],
	[[32.0, 144.0, "tunnel"]],
	[[40.0, 136.0, "hall"]],
	[[32.0, 152.0, "sky"]],
	[[48.0, 144.0, "tunnel"]],
	[[32.0, 144.0, "hall"]],
	[[40.0, 120.0, "tunnel"]],
	[[32.0, 160.0, "sky"]],
	[[48.0, 144.0, "hall"]],
	[[32.0, 144.0, "tunnel"]],
	[[40.0, 136.0, "sky"]],
]
const OBS := [
	[[28, "pane", 0], [48, "jars", 0], [58, "split", 0], [84, "grid", 0], [108, "jars", 0], [116, "tempered", 0], [142, "stack", 0], [164, "jars", 0], [172, "color_row", 0]],
	[[26, "layers", 0], [40, "jars", 0], [64, "frosted", 0], [90, "color_row", 0], [112, "jars", 0], [120, "tempered", 0], [160, "split", 0], [178, "jars", 0]],
	[[50, "slide", 1], [74, "rise", 1], [96, "jars", 0], [104, "hinge", 1], [146, "laminated", 1], [170, "jars", 0], [176, "pane", 1]],
	[[22, "doors", 1], [58, "weak", 1], [84, "shy", 1], [100, "jars", 0], [104, "layers", 1], [146, "hinge", 1], [172, "blocks", 1]],
	[[26, "split", 1], [64, "drop", 1], [86, "rotor", 2], [108, "jars", 0], [116, "mirror", 2], [136, "drop", 1], [166, "spinner", 2]],
	[[48, "orbit", 2], [74, "blast", 2], [92, "slide", 2], [128, "pendulum", 2], [150, "jars", 0], [158, "prism", 2]],
	[[22, "grid", 2], [58, "snake", 2], [88, "jars", 0], [96, "halves", 2], [136, "collapse", 3], [160, "jars", 0], [168, "shield", 3]],
	[[48, "layers", 2], [72, "drop", 2], [92, "jars", 0], [100, "prism", 2], [130, "jars", 0], [160, "pendulum", 3], [178, "jars", 0]],
	[[26, "shutters", 3], [64, "revolving", 3], [90, "charge", 3], [112, "jars", 0], [120, "weak", 3], [158, "flyin", 3], [176, "jars", 0]],
	[[24, "halves", 3], [46, "jars", 0], [80, "rotor", 3], [104, "shield", 3], [140, "jars", 0], [160, "boss", 3]],
	[[48, "pane", 1], [70, "drop", 1], [92, "jars", 0], [100, "mirror", 1], [126, "drop", 1], [168, "split", 1]],
	[[22, "grid", 1], [56, "slide", 1], [80, "mirror", 2], [104, "jars", 0], [112, "color_row", 2], [152, "doors", 2], [174, "jars", 0]],
	[[46, "layers", 2], [70, "drop", 2], [92, "rise", 2], [112, "jars", 0], [120, "orbit", 2], [146, "drop", 2]],
	[[24, "tempered", 2], [64, "shutters", 2], [92, "mirror", 2], [110, "jars", 0], [144, "hinge", 2], [170, "blocks", 2]],
	[[48, "prism", 2], [84, "drop", 2], [104, "jars", 0], [112, "snake", 2], [160, "laminated", 2], [178, "jars", 0]],
	[[22, "shy", 2], [56, "spinner", 3], [84, "mirror", 3], [104, "jars", 0], [136, "pendulum", 3], [160, "jars", 0], [168, "charge", 3]],
	[[48, "drop", 3], [70, "halves", 3], [92, "jars", 0], [100, "shield", 3], [124, "drop", 3], [144, "mirror", 3]],
	[[26, "blocks", 3], [64, "rotor", 3], [90, "frosted", 3], [128, "weak", 3], [150, "jars", 0], [156, "flyin", 3], [176, "halves", 3]],
	[[46, "drop", 3], [66, "orbit", 3], [88, "prism", 3], [116, "jars", 0], [126, "drop", 3], [166, "shutters", 3]],
	[[22, "split", 3], [54, "mirror", 3], [76, "drop", 3], [98, "jars", 0], [106, "blast", 3], [140, "jars", 0], [160, "boss", 3]],
	[[48, "shutters", 2], [72, "snake", 2], [100, "jars", 0], [108, "grid", 2], [132, "shutters", 2], [168, "split", 2]],
	[[22, "pane", 2], [56, "drop", 2], [78, "spinner", 2], [100, "jars", 0], [108, "drop", 2], [152, "revolving", 2], [174, "jars", 0]],
	[[48, "frosted", 3], [72, "rotor", 3], [96, "jars", 0], [104, "shutters", 3], [128, "snake", 3], [154, "tempered", 3]],
	[[24, "hinge", 3], [64, "color_row", 3], [88, "revolving", 3], [110, "jars", 0], [120, "charge", 3], [160, "pendulum", 3]],
	[[48, "shutters", 3], [72, "halves", 3], [128, "drop", 3], [150, "rise", 3], [186, "jars", 0]],
	[[22, "weak", 3], [58, "snake", 3], [86, "shield", 3], [108, "jars", 0], [116, "shutters", 3], [160, "flyin", 3], [178, "jars", 0]],
	[[48, "drop", 4], [68, "orbit", 4], [90, "jars", 0], [98, "prism", 4], [130, "drop", 4], [166, "collapse", 4]],
	[[26, "blocks", 4], [64, "rotor", 4], [86, "shutters", 4], [108, "jars", 0], [116, "halves", 4], [160, "revolving", 4]],
	[[48, "spinner", 4], [72, "blast", 4], [96, "jars", 0], [104, "charge", 4], [144, "shutters", 4], [166, "snake", 4]],
	[[22, "shutters", 4], [56, "snake", 4], [84, "jars", 0], [92, "rotor", 4], [138, "jars", 0], [160, "boss", 4]],
	[[48, "color_row", 3], [72, "grid", 3], [96, "jars", 0], [104, "prism", 3], [160, "blast", 3]],
	[[22, "stack", 3], [56, "tempered", 3], [80, "blocks", 3], [100, "jars", 0], [136, "orbit", 3], [160, "color_row", 3], [178, "jars", 0]],
	[[48, "blast", 4], [72, "slide", 4], [96, "jars", 0], [104, "prism", 4], [136, "grid", 4]],
	[[26, "weak", 4], [64, "drop", 4], [86, "color_row", 4], [108, "jars", 0], [116, "orbit", 4], [160, "collapse", 4]],
	[[48, "revolving", 4], [72, "charge", 4], [96, "jars", 0], [104, "blocks", 4], [144, "prism", 4], [176, "halves", 4]],
	[[22, "grid", 4], [56, "snake", 4], [84, "shield", 4], [108, "jars", 0], [116, "blast", 4], [152, "pendulum", 4], [174, "jars", 0]],
	[[48, "orbit", 5], [72, "prism", 5], [104, "blocks", 5], [128, "color_row", 5], [160, "charge", 5]],
	[[24, "hinge", 5], [64, "drop", 5], [84, "blast", 5], [104, "jars", 0], [112, "prism", 5], [168, "flyin", 5]],
	[[48, "spinner", 5], [72, "halves", 5], [96, "jars", 0], [104, "blocks", 5], [144, "shield", 5], [168, "revolving", 5]],
	[[22, "color_row", 5], [56, "prism", 5], [88, "jars", 0], [96, "blocks", 5], [140, "jars", 0], [160, "boss", 5]],
	[[48, "mirror", 5], [72, "revolving", 5], [96, "jars", 0], [104, "shield", 5], [128, "charge", 5], [164, "halves", 5]],
	[[22, "weak", 5], [56, "mirror", 5], [80, "blast", 5], [104, "jars", 0], [112, "spinner", 5], [152, "pendulum", 5], [174, "jars", 0]],
	[[48, "drop", 5], [68, "mirror", 5], [90, "jars", 0], [98, "shield", 5], [122, "drop", 5], [166, "flyin", 5]],
	[[26, "blocks", 5], [64, "snake", 5], [92, "mirror", 5], [112, "jars", 0], [120, "rotor", 5], [160, "charge", 5]],
	[[48, "revolving", 6], [72, "prism", 6], [104, "jars", 0], [112, "mirror", 6], [160, "shield", 6]],
	[[22, "halves", 6], [56, "shutters", 6], [80, "charge", 6], [100, "jars", 0], [136, "pendulum", 6], [160, "blocks", 6], [178, "jars", 0]],
	[[48, "drop", 6], [66, "mirror", 6], [86, "jars", 0], [94, "snake", 6], [120, "drop", 6], [140, "shield", 6]],
	[[24, "weak", 6], [64, "spinner", 6], [88, "blast", 6], [110, "jars", 0], [118, "mirror", 6], [160, "revolving", 6]],
	[[48, "rotor", 6], [70, "mirror", 6], [92, "jars", 0], [100, "charge", 6], [124, "shield", 6], [160, "flyin", 6]],
	[[22, "shield", 6], [56, "mirror", 6], [78, "drop", 6], [100, "jars", 0], [108, "blast", 6], [140, "jars", 0], [160, "boss", 6]],
]


static func world_of(r: int) -> String:
	return Worlds.LIST[(posmod(r, COUNT) / PER_WORLD) % Worlds.LIST.size()]


static func section(r: int, local: float) -> String:
	for e in SECTS[posmod(r, COUNT)]:
		if local >= e[0] and local < e[1]:
			return e[2]
	return "corridor"


static func entries(r: int) -> Array:
	return OBS[posmod(r, COUNT)]
