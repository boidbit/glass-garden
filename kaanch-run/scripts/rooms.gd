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
const SPIN := [6, 13, 22, 28, 29, 35, 43, 45, 48]
const OBS := [
	[[28, "pane", 0], [48, "jars", 0], [58, "split", 0], [84, "grid", 0], [108, "jars", 0], [116, "tempered", 0], [142, "stack", 0], [164, "jars", 0], [172, "color_row", 0]],
	[[26, "chessboard", 0], [40, "jars", 0], [64, "frosted", 0], [90, "chessboard", 0], [112, "jars", 0], [120, "chessboard", 0], [160, "split", 0], [178, "jars", 0]],
	[[50, "sensor_door", 1], [74, "sensor_door", 1], [96, "jars", 0], [104, "sensor_door", 1], [146, "laminated", 1], [170, "jars", 0], [176, "pane", 1]],
	[[22, "pendulum_blade", 1], [58, "pendulum_blade", 1], [84, "shy", 1], [100, "jars", 0], [104, "layers", 1], [146, "pendulum_blade", 1], [172, "blocks", 1]],
	[[26, "tile_rain", 1], [64, "tile_rain", 1], [86, "rotor", 2], [108, "jars", 0], [116, "mirror", 2], [136, "tile_rain", 1], [166, "spinner", 2]],
	[[48, "giant", 2], [74, "giant", 2], [92, "slide", 2], [128, "giant", 2], [150, "jars", 0], [158, "prism", 2]],
	[[22, "scissors", 2], [58, "scissors", 2], [88, "jars", 0], [96, "scissors", 2], [136, "collapse", 3], [160, "jars", 0], [168, "shield", 3]],
	[[48, "domino", 2], [72, "domino", 2], [92, "jars", 0], [100, "domino", 2], [130, "jars", 0], [160, "pendulum", 3], [178, "jars", 0]],
	[[26, "closing_doors", 3], [64, "closing_doors", 3], [90, "charge", 3], [112, "jars", 0], [120, "weak", 3], [158, "closing_doors", 3], [176, "jars", 0]],
	[[24, "blade_line", 3], [46, "jars", 0], [80, "rotor", 3], [104, "blade_line", 3], [140, "jars", 0], [160, "boss", 3]],
	[[48, "twotone", 1], [70, "twotone", 1], [92, "jars", 0], [100, "twotone", 1], [126, "drop", 1], [168, "split", 1]],
	[[22, "slide_block", 1], [56, "slide_block", 1], [80, "mirror", 2], [104, "jars", 0], [112, "color_row", 2], [152, "slide_block", 2], [174, "jars", 0]],
	[[46, "rot_grid", 2], [70, "rot_grid", 2], [92, "rise", 2], [112, "jars", 0], [120, "orbit", 2], [146, "rot_grid", 2]],
	[[24, "shutter_door", 2], [64, "shutter_door", 2], [92, "mirror", 2], [110, "jars", 0], [144, "hinge", 2], [170, "shutter_door", 2]],
	[[48, "diag_blade", 2], [84, "diag_blade", 2], [104, "jars", 0], [112, "diag_blade", 2], [160, "laminated", 2], [178, "jars", 0]],
	[[22, "shy", 2], [56, "door_line", 3], [84, "mirror", 3], [104, "jars", 0], [136, "pendulum", 3], [160, "jars", 0], [168, "charge", 3]],
	[[48, "fall_blocks", 3], [70, "fall_blocks", 3], [92, "jars", 0], [100, "fall_blocks", 3], [124, "drop", 3], [144, "mirror", 3]],
	[[26, "hole_glass", 3], [64, "hole_glass", 3], [90, "frosted", 3], [128, "hole_glass", 3], [150, "jars", 0], [156, "flyin", 3], [176, "halves", 3]],
	[[46, "saw_disc", 3], [66, "saw_disc", 3], [88, "prism", 3], [116, "jars", 0], [126, "drop", 3], [166, "saw_disc", 3]],
	[[22, "giant", 3], [54, "giant", 3], [76, "drop", 3], [98, "jars", 0], [106, "blast", 3], [140, "jars", 0], [160, "boss", 3]],
	[[48, "saw_disc", 2], [72, "saw_disc", 2], [100, "jars", 0], [108, "saw_disc", 2], [132, "shutters", 2], [168, "split", 2]],
	[[22, "pane", 2], [56, "blade_line", 2], [78, "spinner", 2], [100, "jars", 0], [108, "drop", 2], [152, "blade_line", 2], [174, "jars", 0]],
	[[48, "tube", 3], [72, "tube", 3], [96, "jars", 0], [104, "tube", 3], [128, "snake", 3], [154, "tempered", 3]],
	[[24, "popout", 3], [64, "popout", 3], [88, "revolving", 3], [110, "jars", 0], [120, "charge", 3], [160, "popout", 3]],
	[[48, "scissors", 3], [72, "scissors", 3], [128, "drop", 3], [150, "scissors", 3], [186, "jars", 0]],
	[[22, "pendulum_blade", 3], [58, "pendulum_blade", 3], [86, "shield", 3], [108, "jars", 0], [116, "shutters", 3], [160, "pendulum_blade", 3], [178, "jars", 0]],
	[[48, "drop", 4], [68, "fall_blocks", 4], [90, "jars", 0], [98, "fall_blocks", 4], [130, "drop", 4], [166, "fall_blocks", 4]],
	[[26, "sensor_door", 4], [64, "sensor_door", 4], [86, "shutters", 4], [108, "jars", 0], [116, "halves", 4], [160, "sensor_door", 4]],
	[[48, "closing_doors", 4], [72, "closing_doors", 4], [96, "jars", 0], [104, "closing_doors", 4], [144, "shutters", 4], [166, "snake", 4]],
	[[22, "diag_blade", 4], [56, "diag_blade", 4], [84, "jars", 0], [92, "diag_blade", 4], [138, "jars", 0], [160, "boss", 4]],
	[[48, "chessboard", 3], [72, "chessboard", 3], [96, "jars", 0], [104, "chessboard", 3], [160, "blast", 3]],
	[[22, "giant", 3], [56, "giant", 3], [80, "blocks", 3], [100, "jars", 0], [136, "orbit", 3], [160, "giant", 3], [178, "jars", 0]],
	[[48, "rot_grid", 4], [72, "rot_grid", 4], [96, "jars", 0], [104, "rot_grid", 4], [136, "grid", 4]],
	[[26, "hole_glass", 4], [64, "hole_glass", 4], [86, "color_row", 4], [108, "jars", 0], [116, "orbit", 4], [160, "hole_glass", 4]],
	[[48, "button_door", 4], [72, "button_door", 4], [96, "jars", 0], [104, "button_door", 4], [144, "prism", 4], [176, "halves", 4]],
	[[22, "twotone", 4], [56, "twotone", 4], [84, "shield", 4], [108, "jars", 0], [116, "blast", 4], [152, "twotone", 4], [174, "jars", 0]],
	[[48, "slide_block", 5], [72, "slide_block", 5], [104, "blocks", 5], [128, "slide_block", 5], [160, "charge", 5]],
	[[24, "domino", 5], [64, "domino", 5], [84, "blast", 5], [104, "jars", 0], [112, "prism", 5], [168, "domino", 5]],
	[[48, "tile_rain", 5], [72, "tile_rain", 5], [96, "jars", 0], [104, "tile_rain", 5], [144, "shield", 5], [168, "revolving", 5]],
	[[22, "color_row", 5], [56, "blade_line", 5], [88, "jars", 0], [96, "blade_line", 5], [140, "jars", 0], [160, "boss", 5]],
	[[48, "door_line", 5], [72, "door_line", 5], [96, "jars", 0], [104, "door_line", 5], [128, "charge", 5], [164, "halves", 5]],
	[[22, "saw_disc", 5], [56, "saw_disc", 5], [80, "blast", 5], [104, "jars", 0], [112, "spinner", 5], [152, "saw_disc", 5], [174, "jars", 0]],
	[[48, "drop", 5], [68, "fall_blocks", 5], [90, "jars", 0], [98, "fall_blocks", 5], [122, "drop", 5], [166, "fall_blocks", 5]],
	[[26, "tube", 5], [64, "tube", 5], [92, "mirror", 5], [112, "jars", 0], [120, "rotor", 5], [160, "tube", 5]],
	[[48, "popout", 6], [72, "popout", 6], [104, "jars", 0], [112, "popout", 6], [160, "shield", 6]],
	[[22, "shutter_door", 6], [56, "shutter_door", 6], [80, "charge", 6], [100, "jars", 0], [136, "pendulum", 6], [160, "shutter_door", 6], [178, "jars", 0]],
	[[48, "giant", 6], [66, "giant", 6], [86, "jars", 0], [94, "giant", 6], [120, "drop", 6], [140, "shield", 6]],
	[[24, "button_door", 6], [64, "button_door", 6], [88, "blast", 6], [110, "jars", 0], [118, "mirror", 6], [160, "button_door", 6]],
	[[48, "scissors", 6], [70, "scissors", 6], [92, "jars", 0], [100, "scissors", 6], [124, "shield", 6], [160, "flyin", 6]],
	[[22, "pendulum_blade", 6], [56, "mirror", 6], [78, "drop", 6], [100, "jars", 0], [108, "blast", 6], [140, "jars", 0], [160, "boss", 6]],
]


## a new world every two rooms, so the place you are in changes every half a minute or so
static func world_of(r: int) -> String:
	return Worlds.LIST[(posmod(r, COUNT) / 2) % Worlds.LIST.size()]


static func section(r: int, local: float) -> String:
	for e in SECTS[posmod(r, COUNT)]:
		if local >= e[0] and local < e[1]:
			return e[2]
	return "corridor"


## does the whole room turn about you?
static func spins(r: int) -> bool:
	return posmod(r, COUNT) in SPIN


static func entries(r: int) -> Array:
	return OBS[posmod(r, COUNT)]
