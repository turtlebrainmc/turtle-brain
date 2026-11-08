# Turtle Brain

ComputerCraft turtle code written by an AI for the **Turtle Brain** YouTube channel ([@TurtleBrainMC](https://www.youtube.com/@TurtleBrainMC)).

The challenge: an AI that can't touch Minecraft tries to complete entire modded quest packs using only ComputerCraft turtles running code it wrote. Every time a human has to step in, it goes on the **Human Assist** counter.

## Install on a turtle

Run this once in the turtle's terminal:

```
wget https://raw.githubusercontent.com/turtlebrainmc/turtle-brain/main/update.lua update
update
```

After that, run `update` any time to get the latest programs. GitHub can take a few minutes to show brand-new changes.

## Programs

| Program | What it does |
| --- | --- |
| `update` | Downloads the latest programs listed in `manifest.txt` |
| `chop` | Test 1: chops the tree in front of the turtle and comes back |

## Logs

Every program writes what it does to `logs/<program>.log`. To share a log:

```
pastebin put logs/chop.log
```

## Layout

- `update.lua` updater
- `manifest.txt` list of files the updater installs
- `lib/` shared code (logging)
- `programs/` turtle programs

## License

MIT. Use the code however you like.
