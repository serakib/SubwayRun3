# Neon Orbit — Lua + LÖVE 2D

A different concept from the previous endless-runner projects: **Neon Orbit** is a 2D space survival game made with **Lua + LÖVE 2D**.

You control a small spaceship, avoid incoming asteroids and collect energy crystals. The longer you survive, the faster the asteroid field becomes.

## Features

- 2D space survival gameplay
- Free 4-direction movement
- Asteroid spawning
- Energy crystal collection
- 3 HP system
- Increasing difficulty
- Score and best score
- Particle effects
- Screen shake on damage
- Pause/resume
- Local save file
- No backend
- No database
- No external API

## Controls

| Key | Action |
|---|---|
| W / Up | Fly up |
| S / Down | Fly down |
| A / Left | Fly left |
| D / Right | Fly right |
| P / Esc | Pause / Resume |

Mouse can be used for menu buttons.

## Requirements

Install **LÖVE 2D** from the official LÖVE website:

https://love2d.org/

Lua itself does not need to be installed separately when using the normal LÖVE application.

## Run

### Windows

If LÖVE is installed, you can drag the project folder onto the `love.exe` application.

Or from a terminal:

```bash
love .
```

### macOS / Linux

From the project directory:

```bash
love .
```

## Save data

The game creates:

```text
neon_orbit_save.lua
```

This stores the best score locally using LÖVE's save directory.

No data is uploaded anywhere.

## Project structure

```text
neon-orbit-love2d/
├── main.lua
└── README.md
```

## Concept

Unlike the previous Runway Rush games, this one is not lane-based.

The core loop is:

```text
Move ship
   ↓
Avoid asteroids
   ↓
Collect crystals
   ↓
Survive longer
   ↓
Asteroids become faster
   ↓
Beat your best score
```

## Future upgrades

Possible next features:

- Multiple ship types
- Weapon system
- Boss asteroids
- Power-ups
- Shield
- Dash ability
- Different space zones
- Music and sound effects
- Main menu settings
- Missions
- Achievements
- Online leaderboard later

## License

Use and modify this project for learning and personal projects. Add your own license before public distribution.
