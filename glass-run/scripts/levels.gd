## Level 01, "First Light", made by hand: learn in the cathedral, through the crypt tunnel, down the great hall,
## out through the roof into the sky (with glass to break below), and back in for the finale. About 90 seconds.
class_name Levels
extends RefCounted

const L1_LEN := 712.0
const L1_WORLD := "cathedral"
# the shape of the way: [from, to, what]
const L1_SECT := [[144.0, 240.0, "tunnel"], [272.0, 384.0, "hall"], [416.0, 560.0, "sky"]]
# [distance, what, how hard]
const L1 := [
	[30, "pane", 0], [52, "jars", 0], [66, "split", 0], [92, "grid", 0], [118, "tempered", 0], [132, "jars", 0],
	[158, "color_row", 0], [184, "laminated", 1], [206, "layers", 1], [230, "jars", 1],
	[254, "doors", 1],
	[290, "weak", 1], [314, "hinge", 1], [330, "jars", 1], [342, "blocks", 1], [366, "shy", 1],
	[398, "spinner", 2],
	[432, "drop", 1], [454, "orbit", 2], [476, "mirror", 2], [490, "prism", 2], [530, "drop", 2], [548, "blast", 2],
	[574, "collapse", 3], [598, "snake", 3], [618, "jars", 3], [630, "rotor", 3], [652, "shield", 3], [672, "jars", 3],
	[690, "finale", 3], [705, "exit", 3],
]
