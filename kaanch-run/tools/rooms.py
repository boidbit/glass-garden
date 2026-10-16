# The 50 rooms of the endless run, written by hand; this checks them and writes scripts/rooms.gd
import sys
WORLDS=["cathedral","venice","lanterns","mosaic","sheesh"]
SKY_OK=set("giant slide_block fall_blocks scissors saw_disc diag_blade blade_line chessboard tile_rain rot_grid hole_glass tube twotone domino blocks pane split grid layers stack color_row tempered frosted slide rise hinge weak laminated shy spinner rotor prism mirror orbit blast snake shield halves flyin charge shutters drop".split())
EXT={"layers":6.4,"frosted":1.6,"snake":10.4,"prism":19,"collapse":4.4,"boss":1,"fall_blocks":10,"blade_line":9,"door_line":12,"tube":9,"diag_blade":2.5}
SKY_NO={"pendulum_blade","sensor_door","closing_doors","door_line","shutter_door","button_door","popout","pendulum","revolving","grille","collapse","doors"}
# the star of each room: the glass it is about (put in two or three times, where it fits)
STAR=["", "chessboard", "sensor_door", "pendulum_blade", "tile_rain", "giant", "scissors", "domino", "closing_doors", "blade_line",
 "twotone", "slide_block", "rot_grid", "shutter_door", "diag_blade", "door_line", "fall_blocks", "hole_glass", "saw_disc", "giant",
 "saw_disc", "blade_line", "tube", "popout", "scissors", "pendulum_blade", "fall_blocks", "sensor_door", "closing_doors", "diag_blade",
 "chessboard", "giant", "rot_grid", "hole_glass", "button_door", "twotone", "slide_block", "domino", "tile_rain", "blade_line",
 "door_line", "saw_disc", "fall_blocks", "tube", "popout", "shutter_door", "giant", "button_door", "scissors", "pendulum_blade"]
# rooms where the whole room turns about you
SPIN=[6, 13, 22, 28, 29, 35, 43, 45, 48]
R=[
# ---- Cathedral: learn the glass, then the prism; the rose window at the end
("c200","28 pane/0, 48 J, 58 split/0, 84 grid/0, 108 J, 116 tempered/0, 142 stack/0, 164 J, 172 color_row/0"),
("c48 t96 c56","26 layers/0, 40 J, 64 frosted/0, 90 color_row/0, 112 J, 120 tempered/0, 160 split/0, 178 J"),
("c32 h96 c72","50 slide/1, 74 rise/1, 96 J, 104 hinge/1, 146 laminated/1, 170 J, 176 pane/1"),
("c40 t88 c72","22 doors/1, 58 weak/1, 84 shy/1, 100 J, 104 layers/1, 146 hinge/1, 172 blocks/1"),
("c48 s104 c48","26 split/1, 64 drop/1, 86 rotor/2, 108 J, 116 mirror/2, 136 drop/1, 166 spinner/2"),
("c32 h80 c88","48 orbit/2, 74 blast/2, 92 slide/2, 128 pendulum/2, 150 J, 158 prism/2"),
("c40 t80 c80","22 grid/2, 58 snake/2, 88 J, 96 halves/2, 136 collapse/3, 160 J, 168 shield/3"),
("c32 s112 c56","48 layers/2, 72 drop/2, 92 J, 100 prism/2, 130 J, 160 pendulum/3, 178 J"),
("c48 h96 c56","26 shutters/3, 64 revolving/3, 90 charge/3, 112 J, 120 weak/3, 158 flyin/3, 176 J"),
("c64 t64 c72","24 halves/3, 46 J, 80 rotor/3, 104 shield/3, 140 J, 160 boss/3"),
# ---- Venice: out over the lagoon, Murano mirrors, glass falling from the sky
("c32 s120 c48","48 pane/1, 70 drop/1, 92 J, 100 mirror/1, 126 drop/1, 168 split/1"),
("c40 h96 c64","22 grid/1, 56 slide/1, 80 mirror/2, 104 J, 112 color_row/2, 152 doors/2, 174 J"),
("c32 s136 c32","46 layers/2, 70 drop/2, 92 rise/2, 112 J, 120 orbit/2, 146 drop/2"),
("c48 t80 c72","24 tempered/2, 64 shutters/2, 92 mirror/2, 110 J, 144 hinge/2, 170 blocks/2"),
("c32 s112 c56","48 prism/2, 84 drop/2, 104 J, 112 snake/2, 160 laminated/2, 178 J"),
("c40 h80 c80","22 shy/2, 56 spinner/3, 84 mirror/3, 104 J, 136 pendulum/3, 160 J, 168 charge/3"),
("c32 s128 c40","48 drop/3, 70 halves/3, 92 J, 100 shield/3, 124 drop/3, 144 mirror/3"),
("c48 t64 c88","26 blocks/3, 64 rotor/3, 90 frosted/3, 128 weak/3, 150 J, 156 flyin/3, 176 halves/3"),
("c32 s120 c48","46 drop/3, 66 orbit/3, 88 prism/3, 116 J, 126 drop/3, 166 shutters/3"),
("c40 s96 c64","22 split/3, 54 mirror/3, 76 drop/3, 98 J, 106 blast/3, 140 J, 160 boss/3"),
# ---- Lanterns: night tunnels of red gates, glass that moves to the music, the dragon
("c32 t120 c48","48 shutters/2, 72 snake/2, 100 J, 108 grid/2, 132 shutters/2, 168 split/2"),
("c40 s96 c64","22 pane/2, 56 drop/2, 78 spinner/2, 100 J, 108 drop/2, 152 revolving/2, 174 J"),
("c32 t136 c32","48 frosted/3, 72 rotor/3, 96 J, 104 shutters/3, 128 snake/3, 154 tempered/3"),
("c48 h96 c56","24 hinge/3, 64 color_row/3, 88 revolving/3, 110 J, 120 charge/3, 160 pendulum/3"),
("c32 t64 c16 s64 c24","48 shutters/3, 72 halves/3, 128 drop/3, 150 rise/3, 186 J"),
("c40 t104 c56","22 weak/3, 58 snake/3, 86 shield/3, 108 J, 116 shutters/3, 160 flyin/3, 178 J"),
("c32 s120 c48","48 drop/4, 68 orbit/4, 90 J, 98 prism/4, 130 drop/4, 166 collapse/4"),
("c48 t96 c56","26 blocks/4, 64 rotor/4, 86 shutters/4, 108 J, 116 halves/4, 160 revolving/4"),
("c32 h96 c72","48 spinner/4, 72 blast/4, 96 J, 104 charge/4, 144 shutters/4, 166 snake/4"),
("c40 t80 c80","22 shutters/4, 56 snake/4, 84 J, 92 rotor/4, 138 J, 160 boss/4"),
# ---- Mosaic: great courts of tile, rows of colour, the prism chain, blast glass
("c32 h112 c56","48 color_row/3, 72 grid/3, 96 J, 104 prism/3, 160 blast/3"),
("c40 t80 c80","22 stack/3, 56 tempered/3, 80 blocks/3, 100 J, 136 orbit/3, 160 color_row/3, 178 J"),
("c32 h128 c40","48 blast/4, 72 slide/4, 96 J, 104 prism/4, 136 grid/4"),
("c48 s96 c56","26 weak/4, 64 drop/4, 86 color_row/4, 108 J, 116 orbit/4, 160 collapse/4"),
("c32 h96 c72","48 revolving/4, 72 charge/4, 96 J, 104 blocks/4, 144 prism/4, 176 halves/4"),
("c40 t96 c64","22 grid/4, 56 snake/4, 84 shield/4, 108 J, 116 blast/4, 152 pendulum/4, 174 J"),
("c32 h112 c56","48 orbit/5, 72 prism/5, 104 blocks/5, 128 color_row/5, 160 charge/5"),
("c48 s104 c48","24 hinge/5, 64 drop/5, 84 blast/5, 104 J, 112 prism/5, 168 flyin/5"),
("c32 h96 c72","48 spinner/5, 72 halves/5, 96 J, 104 blocks/5, 144 shield/5, 168 revolving/5"),
("c40 h96 c64","22 color_row/5, 56 prism/5, 88 J, 96 blocks/5, 140 J, 160 boss/5"),
# ---- Sheesh Mahal: halls of mirrors, revolving doors, shields; the hardest
("c32 t112 c56","48 mirror/5, 72 revolving/5, 96 J, 104 shield/5, 128 charge/5, 164 halves/5"),
("c40 h96 c64","22 weak/5, 56 mirror/5, 80 blast/5, 104 J, 112 spinner/5, 152 pendulum/5, 174 J"),
("c32 s120 c48","48 drop/5, 68 mirror/5, 90 J, 98 shield/5, 122 drop/5, 166 flyin/5"),
("c48 t96 c56","26 blocks/5, 64 snake/5, 92 mirror/5, 112 J, 120 rotor/5, 160 charge/5"),
("c32 h112 c56","48 revolving/6, 72 prism/6, 104 J, 112 mirror/6, 160 shield/6"),
("c40 t80 c80","22 halves/6, 56 shutters/6, 80 charge/6, 100 J, 136 pendulum/6, 160 blocks/6, 178 J"),
("c32 s128 c40","48 drop/6, 66 mirror/6, 86 J, 94 snake/6, 120 drop/6, 140 shield/6"),
("c48 h96 c56","24 weak/6, 64 spinner/6, 88 blast/6, 110 J, 118 mirror/6, 160 revolving/6"),
("c32 t112 c56","48 rotor/6, 70 mirror/6, 92 J, 100 charge/6, 124 shield/6, 160 flyin/6"),
("c40 s96 c64","22 shield/6, 56 mirror/6, 78 drop/6, 100 J, 108 blast/6, 140 J, 160 boss/6"),
]
NAMES={"c":"corridor","t":"tunnel","h":"hall","s":"sky"}
SEG=16.0
errs=[]
out=[]

def parse(secs):
    parts=[(NAMES[p[0]],float(p[1:])) for p in secs.split()]
    spans=[];a=0.0
    for n,l in parts: spans.append((a,a+l,n)); a+=l
    return spans

def check(i, spans, ents):
    e=[]
    def raw(x):
        for a,b,n in spans:
            if a<=x<b: return n
        return "corridor"
    prev_end=-99
    for d,t,h in ents:
        if t=="jars": continue
        ext=EXT.get(t,0)
        if d<prev_end+12: e.append(f"room {i}: {t}@{d} too close to the one before")
        prev_end=d+ext
        if d+ext>182: e.append(f"room {i}: {t}@{d} runs into the door")
        if d<18: e.append(f"room {i}: {t}@{d} too near the start")
        for par in (0,8):
            def sec_at(x):
                k=(x+par)//SEG
                return raw(k*SEG+SEG/2-par)
            for x in (d-4,d,d+ext+4):
                if sec_at(x)=="sky" and (t not in SKY_OK or t in SKY_NO): e.append(f"room {i}: {t}@{d} in the sky (par {par})")
            if sec_at(d-4)!=sec_at(d+ext+4): e.append(f"room {i}: {t}@{d} across a change of shape (par {par})")
    return e

for i,(secs,obs) in enumerate(R):
    spans=parse(secs)
    if spans[-1][1]!=200: errs.append(f"room {i}: sections sum {spans[-1][1]}")
    ents=[]
    for e in obs.split(","):
        d,what=e.split()
        d=float(d)
        if what=="J": ents.append((d,"jars",0)); continue
        t,h=what.split("/"); ents.append((d,t,int(h)))
    errs+=check(i,spans,ents)
    star=STAR[i]
    if star:
        put=0
        for k in range(len(ents)):
            if put>=3: break
            d,t,h=ents[k]
            if t in ("jars","boss"): continue
            trial=ents[:k]+[(d,star,h)]+ents[k+1:]
            if not check(i,spans,trial) and (k%2==1 or put==0):
                ents=trial; put+=1
        if put<2: print(f"room {i}: star {star} only {put} times")
    out.append((spans,ents))
if len(R)!=50: errs.append(f"{len(R)} rooms")
if errs:
    print("\n".join(errs)); sys.exit(1)
lines=['## The 50 rooms of the endless run, made by hand: ten in each world, the tenth with a great wheel of glass.',
'## In one run no room comes twice; after the fiftieth they come again as a remix (faster, the other way round).',
'## Written out by a checker (sections in metres from the start of the room; obstacles as [metres, what, how hard]).',
'class_name Rooms','extends RefCounted','','const COUNT := 50','const PER_WORLD := 10','const SECTS := [']
for spans,ents in out:
    lines.append('\t['+', '.join(f'[{a:.0f}.0, {b:.0f}.0, "{n}"]' for a,b,n in spans if n!="corridor")+'],')
lines.append(']')
lines.append('const SPIN := '+str(SPIN))
lines.append('const OBS := [')
for spans,ents in out:
    lines.append('\t['+', '.join(f'[{d:.0f}, "{t}", {h}]' for d,t,h in ents)+'],')
lines.append(']')
lines.append('''

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
''')
open(sys.argv[1],'w').write("\n".join(lines))
print("ok", len(out))
