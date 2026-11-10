"""Generate the Turtle Brain FTB Quests book (Minecraft 1.20.1, FTB Quests 2001.x) as SNBT files.

Usage: python3 build_quests.py <output_dir>
Writes <output_dir>/data.snbt, chapter_groups.snbt and chapters/*.snbt.
"""
import hashlib
import os
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "ftbquests/quests"


def qid(*parts):
    """Stable 16-hex-digit id from a name, so re-running keeps ids (and player progress)."""
    return hashlib.sha1("|".join(parts).encode()).hexdigest()[:16].upper()


def s(text):
    return '"' + text.replace("\\", "\\\\").replace('"', '\\"') + '"'


def item(id_, nbt=None):
    if nbt is None:
        return s(id_)
    return "{ Count: 1b, id: %s, tag: %s }" % (s(id_), nbt)


def task(chapter, quest, n, kind, **kw):
    tid = qid(chapter, quest, "task", str(n))
    if kind == "checkmark":
        return "{ id: %s, type: \"checkmark\" }" % s(tid)
    return "{ id: %s, type: \"item\", item: %s, count: %dL }" % (s(tid), item(kw["item"], kw.get("nbt")), kw.get("count", 1))


def reward(chapter, quest, n, kind, **kw):
    rid = qid(chapter, quest, "reward", str(n))
    if kind == "xp":
        return "{ id: %s, type: \"xp_levels\", xp_levels: %d }" % (s(rid), kw["levels"])
    count = kw.get("count", 1)
    cnt = "" if count == 1 else ", count: %d" % count
    return "{ id: %s, type: \"item\", item: %s%s }" % (s(rid), item(kw["item"], kw.get("nbt")), cnt)


PICK_TURTLE = '{ RightUpgrade: "minecraft:diamond_pickaxe" }'

# Each chapter: (filename, title, icon, [quests]).
# Each quest: dict(key, title, subtitle, desc[list], tasks[list of (kind, kw)], rewards[list of (kind, kw)], deps[keys], x, y, shape?)
CHAPTERS = [
    ("boot_sequence", "1. Boot Sequence", "computercraft:computer_normal", [
        dict(key="hello", title="Hello, World", subtitle="Read the rules. Then hand over control.", x=0, y=0, shape="hexagon",
             desc=["&bWelcome to Turtle Brain.&r",
                   "",
                   "An AI that can't touch Minecraft is going to beat this quest book using only turtles it programs itself.",
                   "",
                   "&eThe rules:&r",
                   "&a- Turtles break and place every block in the world.",
                   "&a- The human may claim quests, craft, move items, and place or pick up turtles and computers.",
                   "&c- Anything else the human does is a Human Assist. Fewer assists is the score.",
                   "",
                   "Tick the box to receive your first turtle."],
             tasks=[("checkmark", {})],
             rewards=[("item", dict(item="computercraft:turtle_normal", nbt=PICK_TURTLE)), ("item", dict(item="minecraft:coal", count=8))]),
        dict(key="first_swing", title="First Swing", subtitle="Every empire starts with a tree.", x=1.5, y=0, deps=["hello"],
             desc=["Program the turtle to cut down a tree and bring the logs back.",
                   "",
                   "Logs are also fuel. A hungry turtle is a stuck turtle."],
             tasks=[("item", dict(item="minecraft:oak_log", count=16))],
             rewards=[("item", dict(item="minecraft:bread", count=4))]),
        dict(key="workbench", title="Workbench Buddy", subtitle="The turtle builds it. You get to use it.", x=3, y=0, deps=["first_swing"],
             desc=["Craft a crafting table and have a turtle place it at base.",
                   "",
                   "Using a crafting table a turtle placed is allowed. Placing it yourself is an assist."],
             tasks=[("item", dict(item="minecraft:crafting_table"))]),
        dict(key="stone", title="Stone Cold", subtitle="Dig down. Not straight down. Okay, straight down.", x=4.5, y=0, deps=["workbench"],
             desc=["Mine some stone. Cobblestone is the turtle's first building material."],
             tasks=[("item", dict(item="minecraft:cobblestone", count=64))],
             rewards=[("item", dict(item="minecraft:coal", count=8))]),
        dict(key="furnace", title="Hot Stuff", subtitle="A furnace the turtle can feed.", x=4.5, y=1.5, deps=["stone"],
             desc=["Craft a furnace and have a turtle place it.",
                   "",
                   "Turtles can push items into a furnace and pull results out. Automation starts here."],
             tasks=[("item", dict(item="minecraft:furnace"))]),
        dict(key="charcoal", title="Fuel Line", subtitle="Never run on empty again.", x=6, y=1.5, deps=["furnace"],
             desc=["Smelt logs into charcoal with no human hands in the furnace.",
                   "",
                   "Bonus points if a program keeps the furnace stocked by itself."],
             tasks=[("item", dict(item="minecraft:charcoal", count=32))]),
        dict(key="chests", title="Home Base", subtitle="A place to put all the stuff.", x=6, y=0, deps=["stone"],
             desc=["Craft chests and have turtles build a storage wall at base.",
                   "",
                   "Turtles can drop items into chests and suck them back out."],
             tasks=[("item", dict(item="minecraft:chest", count=4))],
             rewards=[("xp", dict(levels=5))]),
    ]),
    ("going_down", "2. Going Down", "minecraft:diamond_pickaxe", [
        dict(key="coal", title="Coal Seam", subtitle="Black gold.", x=0, y=0,
             desc=["Find and mine coal ore. Turtles can inspect blocks to know what they're looking at."],
             tasks=[("item", dict(item="minecraft:coal", count=32))],
             deps_external=[("boot_sequence", "stone")]),
        dict(key="iron", title="Iron Will", subtitle="The metal that builds turtles.", x=1.5, y=0, deps=["coal"],
             desc=["Mine iron ore. A turtle that only digs ore and skips the rest is a smart turtle."],
             tasks=[("item", dict(item="minecraft:raw_iron", count=24))]),
        dict(key="smelt", title="Smelter", subtitle="Raw in, ingots out.", x=3, y=0, deps=["iron"],
             desc=["Smelt the iron. Turtles load the furnace, turtles empty it."],
             tasks=[("item", dict(item="minecraft:iron_ingot", count=24))],
             rewards=[("item", dict(item="minecraft:coal", count=16))]),
        dict(key="sand", title="Sandy Situation", subtitle="Glass is just hot sand.", x=1.5, y=1.5, deps=["coal"],
             desc=["Find sand and smelt it into glass, then craft glass panes. Computers need them."],
             tasks=[("item", dict(item="minecraft:glass_pane", count=16))]),
        dict(key="redstone", title="Red Dust", subtitle="The blood of every computer.", x=3, y=1.5, deps=["sand"],
             desc=["Mine redstone ore. It's deep, so the turtle will need to dig deep."],
             tasks=[("item", dict(item="minecraft:redstone", count=32))]),
        dict(key="deepslate", title="Into the Dark", subtitle="Below zero.", x=4.5, y=1.5, deps=["redstone"],
             desc=["Dig into the deepslate layer. Watch for lava. Turtles don't swim."],
             tasks=[("item", dict(item="minecraft:cobbled_deepslate", count=64))]),
        dict(key="diamonds", title="Shiny", subtitle="Diamonds. Found by a robot.", x=6, y=0.75, deps=["smelt", "deepslate"], shape="diamond",
             desc=["Find diamonds. Every pickaxe turtle needs one, so they're worth more than they look."],
             tasks=[("item", dict(item="minecraft:diamond", count=3))],
             rewards=[("xp", dict(levels=10))]),
    ]),
    ("make_more_turtles", "3. Make More Turtles", "computercraft:turtle_normal", [
        dict(key="computer", title="Brain in a Box", subtitle="Stone, redstone, glass.", x=0, y=0,
             desc=["Craft a computer. Every turtle has one inside."],
             tasks=[("item", dict(item="computercraft:computer_normal"))],
             deps_external=[("going_down", "redstone")]),
        dict(key="second_turtle", title="Shell Shock", subtitle="Now there are two of them.", x=1.5, y=0, deps=["computer"],
             desc=["Build a second turtle from scratch: iron, a computer and a chest.",
                   "",
                   "Two turtles means jobs can run in parallel. Mining and chopping at the same time."],
             tasks=[("item", dict(item="computercraft:turtle_normal", count=2))]),
        dict(key="crafty", title="Crafty", subtitle="A turtle that crafts.", x=3, y=0, deps=["second_turtle"],
             desc=["Give a turtle a crafting table as an upgrade. Now it can craft its own items.",
                   "",
                   "Tick the box once a crafty turtle has crafted something on its own."],
             tasks=[("checkmark", {})]),
        dict(key="modem", title="Can You Hear Me?", subtitle="Turtles that talk.", x=1.5, y=1.5, deps=["computer"],
             desc=["Craft a wireless modem. Turtles with modems can report their position and progress."],
             tasks=[("item", dict(item="computercraft:wireless_modem_normal"))]),
        dict(key="disk", title="Floppy", subtitle="Save the programs.", x=3, y=1.5, deps=["modem"],
             desc=["Craft a disk drive and a floppy disk. New turtles can load programs from it."],
             tasks=[("item", dict(item="computercraft:disk_drive")), ("item", dict(item="computercraft:disk"))]),
        dict(key="monitor", title="Big Screen", subtitle="Mission control.", x=4.5, y=1.5, deps=["disk"],
             desc=["Build a monitor wall at base to show what every turtle is doing. Great for the camera."],
             tasks=[("item", dict(item="computercraft:monitor_normal", count=6))]),
        dict(key="gold", title="Gold Standard", subtitle="Advanced parts need gold.", x=4.5, y=0, deps=["crafty"],
             desc=["Mine gold ore and smelt it."],
             tasks=[("item", dict(item="minecraft:gold_ingot", count=16))]),
        dict(key="advanced", title="Upgrade Complete", subtitle="A turtle with color.", x=6, y=0.75, deps=["gold", "monitor"], shape="gear",
             desc=["Build an advanced turtle."],
             tasks=[("item", dict(item="computercraft:turtle_advanced"))],
             rewards=[("xp", dict(levels=10))]),
    ]),
    ("the_fleet", "4. The Fleet", "computercraft:turtle_advanced", [
        dict(key="squad", title="Squad Goals", subtitle="Four turtles, one brain.", x=0, y=0,
             desc=["Have four turtles working at once."],
             tasks=[("item", dict(item="computercraft:turtle_normal", count=4))],
             deps_external=[("make_more_turtles", "advanced")]),
        dict(key="tree_farm", title="Tree Farm", subtitle="Plant, wait, chop, repeat.", x=1.5, y=-1, deps=["squad"],
             desc=["Build an automatic tree farm run entirely by turtles."],
             tasks=[("item", dict(item="minecraft:oak_log", count=512))]),
        dict(key="quarry", title="Quarry", subtitle="Make a very big hole.", x=1.5, y=1, deps=["squad"],
             desc=["Run a quarry program that clears out a whole area, layer by layer."],
             tasks=[("item", dict(item="minecraft:cobblestone", count=2048))]),
        dict(key="iron_mountain", title="Iron Mountain", subtitle="So much iron.", x=3, y=1, deps=["quarry"],
             desc=["Stockpile iron for a turtle army."],
             tasks=[("item", dict(item="minecraft:iron_block", count=16))]),
        dict(key="diamond_hands", title="Diamond Hands", subtitle="A diamond for every pickaxe.", x=3, y=-1, deps=["tree_farm", "quarry"],
             desc=["Collect enough diamonds to give pickaxes to a whole fleet."],
             tasks=[("item", dict(item="minecraft:diamond", count=32))]),
        dict(key="admiral", title="Fleet Admiral", subtitle="Sixteen turtles.", x=4.5, y=0, deps=["iron_mountain", "diamond_hands"],
             desc=["Build a fleet of sixteen turtles."],
             tasks=[("item", dict(item="computercraft:turtle_normal", count=16))]),
        dict(key="nether", title="Hot Trip", subtitle="Turtles in the Nether.", x=6, y=0, deps=["admiral"],
             desc=["Get a turtle into the Nether and bring back blaze rods and soul sand. The turtles fight. You watch."],
             tasks=[("item", dict(item="minecraft:blaze_rod", count=8)), ("item", dict(item="minecraft:soul_sand", count=4))]),
        dict(key="finale", title="Turtle Brain", subtitle="The final boss.", x=7.5, y=0, deps=["nether"], shape="heart",
             desc=["&6The season finale.&r",
                   "",
                   "Summon the Wither and defeat it using only turtles.",
                   "",
                   "Bring back the Nether Star to prove a brain made of code can beat Minecraft."],
             tasks=[("item", dict(item="minecraft:nether_star"))],
             rewards=[("xp", dict(levels=30))]),
    ]),
]


def chapter_snbt(order, filename, title, icon, quests):
    lines = ["{",
             "\tdefault_hide_dependency_lines: false",
             "\tdefault_quest_shape: \"\"",
             "\tfilename: %s" % s(filename),
             "\tgroup: \"\"",
             "\ticon: %s" % s(icon),
             "\tid: %s" % s(qid("chapter", filename)),
             "\torder_index: %d" % order,
             "\tquest_links: [ ]",
             "\tquests: ["]
    for q in quests:
        deps = [qid(filename, d) for d in q.get("deps", [])]
        deps += [qid(c, k) for c, k in q.get("deps_external", [])]
        lines.append("\t\t{")
        if deps:
            lines.append("\t\t\tdependencies: [%s]" % ", ".join(s(d) for d in deps))
        lines.append("\t\t\tdescription: [%s]" % ", ".join(s(d) for d in q["desc"]))
        lines.append("\t\t\tid: %s" % s(qid(filename, q["key"])))
        rws = q.get("rewards", [])
        parts = [reward(filename, q["key"], i, k, **kw) for i, (k, kw) in enumerate(rws)]
        # hidden reward: bump the on-screen quest counter when the quest is claimed
        parts.append('{ id: %s, type: "command", command: "/scoreboard players add Quests turtlebrain 1", elevate_perms: true, silent: true, exclude_from_claim_all: false }'
                     % s(qid(filename, q["key"], "counter")))
        lines.append("\t\t\trewards: [%s]" % ", ".join(parts))
        if q.get("shape"):
            lines.append("\t\t\tshape: %s" % s(q["shape"]))
        lines.append("\t\t\tsubtitle: %s" % s(q["subtitle"]))
        lines.append("\t\t\ttasks: [%s]" % ", ".join(task(filename, q["key"], i, k, **kw) for i, (k, kw) in enumerate(q["tasks"])))
        lines.append("\t\t\ttitle: %s" % s(q["title"]))
        lines.append("\t\t\tx: %.1fd" % q["x"])
        lines.append("\t\t\ty: %.1fd" % q["y"])
        lines.append("\t\t}")
    lines += ["\t]", "\ttitle: %s" % s(title), "}", ""]
    return "\n".join(lines)


DATA = """{
\tdefault_autoclaim_rewards: "disabled"
\tdefault_consume_items: false
\tdefault_quest_disable_jei: false
\tdefault_quest_shape: "circle"
\tdefault_reward_team: false
\tdetection_delay: 20
\tdisable_gui: false
\tdrop_loot_crates: false
\temergency_items_cooldown: 300
\tgrid_scale: 0.5d
\ticon: "computercraft:turtle_normal"
\tlock_message: ""
\tpause_game: false
\tprogression_mode: "linear"
\ttitle: "Turtle Brain"
\tversion: 13
}
"""

os.makedirs(os.path.join(OUT, "chapters"), exist_ok=True)
with open(os.path.join(OUT, "data.snbt"), "w") as f:
    f.write(DATA)
with open(os.path.join(OUT, "chapter_groups.snbt"), "w") as f:
    f.write("{\n\tchapter_groups: [ ]\n}\n")
total = 0
for i, (fn, title, icon, quests) in enumerate(CHAPTERS):
    with open(os.path.join(OUT, "chapters", fn + ".snbt"), "w") as f:
        f.write(chapter_snbt(i, fn, title, icon, quests))
    total += len(quests)
print("chapters:", len(CHAPTERS), "quests:", total)
