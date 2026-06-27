# ForzaSkillFarmer

<img src="banner.jpg" alt="banner" width="500">


*An AutoHotkey v2 macro that automatically farms skill points in **Forza Horizon 6** by looping a straight-line race on repeat. Enter your current skill point count and it auto-calculates exactly how many runs are needed to reach the 999 cap — then stops on its own.*

---

## The race

Share code: **100 405 213**

Based on this video: https://www.youtube.com/watch?v=MNCP2xFXDTs

watch carefully before using the script, only working with same cars, preset, and difficulty settings

A straight-line sprint that takes roughly 30–35 seconds to complete. No turns, no obstacles — just hold the accelerator. From 0 skill points, running this race non-stop fills the cap in approximately **1h30**.

---

## Features

- Pixel-based sync — no fixed sleep timers, drift-free across long sessions
- Adaptive run cap — enter your current points, it calculates exactly how many runs remain
- Live GUI — status, run counter, skill point total, elapsed time, and ETA
- Auto-snap — locks the game window to a fixed position and size on every start
- Auto-stop — exits cleanly when 999 is reached and shows a session summary

---

## Requirements

- [AutoHotkey v2](https://www.autohotkey.com/) — v1 will not work
- Forza Horizon 6 running in **windowed mode** (not fullscreen)
- In-game render resolution set to **2560×1440**

---

## Setup

### 1. Game settings

Configure Forza before running the script:

- **Display mode**: Windowed (not Borderless, not Fullscreen)
- **Resolution**: 2560×1440 for 1440p, or 1920×1080 for 1080p

### 2. Configure the script

Open `ForzaSkillFarmer.ahk` in a text editor and set the two constants at the top:

```ahk
PRESET   := "1440p"   ; "1440p" or "1080p"
KEYBOARD := "azerty"  ; "azerty" or "qwerty"
```

`PRESET` controls window placement and pixel trigger coordinates. `KEYBOARD` controls which key is held to accelerate — `z` for AZERTY, `w` for QWERTY.

On launch, the script will snap both the game window and its own GUI panel to fixed hardcoded positions. This keeps pixel coordinates consistent across every session — no manual positioning needed.

> **Note:** The 1080p preset has window position and size calibrated, but pixel triggers are not set yet. If you run at 1080p, see the [Pixel calibration](#pixel-calibration) section to find your two pixel values and fill them into the `1080p` block.

### 3. Load the race

In Forza, go to **Creative Hub → Event Lab → Play Event** and enter share code **100 405 213**. Load the race and get to the pre-race ready screen (the one where you press Enter to begin). That is your starting position.

### 4. Run the script

Double-click `ForzaSkillFarmer.ahk` — the GUI panel will appear at its preset position.

---

## Usage

| Key | Action |
|-----|--------|
| `F4` | Start the AFK loop |
| `F3` | Stop at any time |
| `F8` | Pixel color helper (hover anywhere, press F8 to read X/Y/color) |

**Before pressing F4**, make sure:
- The game is in **windowed mode** (not fullscreen or borderless)
- You are on the **pre-race ready screen** — the one where you press Enter to begin
- The selected button is **"Start Race"**, not "Free Roam" or any other option — the script sends Enter blindly and will confirm whatever is highlighted

**Press F4.** The script will:
1. Snap the Forza window to its preset position
2. Ask how many skill points you currently have
3. Calculate the number of runs needed to reach 999
4. Wait for the ready screen pixel, then begin the loop automatically

You can leave your PC unattended. When the target is reached, the loop stops and a summary popup appears.

**To stop mid-session**, press F3. The script will release the accelerator and halt cleanly at the end of the current step — it will not start another run.

**If the game crashes**, the script detects it automatically — both between runs and mid-race inside any waiting step. It stops the loop, sets the status to "Game crashed!", and shows a popup. It will not keep counting phantom laps against a dead process.

---

## Pixel calibration

The script uses two pixel triggers instead of sleep timers. This makes the loop drift-free — each phase only advances when the game is actually in the right state.

**How pixel triggers work**: `PixelGetColor` reads the color of a single screen pixel 10 times per second. When it sees the expected color, it moves to the next step. The coordinates must match exactly where those pixels appear on your screen.

### Default calibrated values (2560×1440, window at 0,0)

| Trigger | X | Y | Color | Meaning |
|---------|---|---|-------|---------|
| Start screen | 126 | 36 | `0x165EDB` | Blue accent in the top UI bar (the background color of the S2 car level badge) — only visible on the pre-race ready screen |
| Scoreboard | 276 | 263 | `0xFFDE39` | Yellow element in the results overlay (the golden trophy next to your username) — appears when the race ends |

### Recalibrating for a different resolution or window position

If your resolution or window position differs, the default pixel coordinates will not match and the script will hang waiting for a color it never sees.

To find the correct values:

1. Get into the state you want to detect (e.g. the pre-race ready screen)
2. Hover your mouse over a UI element that is **unique to that screen** and has a solid, consistent color — avoid animated elements, text, or anything near the edge of the screen
3. Press **F8** — a popup shows the exact X, Y, and hex color under your cursor
4. Open `ForzaSkillFarmer.ahk` in a text editor and update the two `WaitForPixel` calls in the `F4` block, and the one before the main loop

**Good pixels to target:**
- *Start screen*: the background color of the S2 car level badge — only visible on the pre-race ready screen
- *Scoreboard*: any bold-colored element in the results overlay — the golden trophy next to your username works well

**Tips:**
- Avoid pixels on text — anti-aliasing makes the color inconsistent
- Avoid pixels near the edges of UI panels — they can appear during transitions
- If in doubt, pick a pixel closer to the center of a solid-color element

### Changing the window snap target

If you want to run at a different size, update these two lines near the top of the script:

```ahk
GAME_W := 2560
GAME_H := 1440
```

Then recalibrate both pixel triggers as described above.

### Window positioning and sizing

On F4, the script calls `WinMove` to snap the game window to a fixed outer-frame position and size (`GAME_X`, `GAME_Y`, `GAME_W`, `GAME_H`). Both the position and dimensions are hardcoded per preset, measured with WindowSpy's `Active Window Position → Screen` values (the outer frame line, not the client line).

If you want to move the windows to different spots on your screen, update `GAME_X`/`GAME_Y` and `GUI_X`/`GUI_Y` in the preset block. If you change position, remember that pixel trigger coordinates are screen-absolute — you'll need to recalibrate them too.

---

## Timing calibration

The ETA displayed in the GUI is based on a measured average of **~54.5 seconds per run** (90 minutes ÷ 99 runs from 0 to 999). If your machine loads faster or slower, you can adjust this constant:

```ahk
SECS_PER_RUN := 54.55
```

To measure your own value: run 5–10 laps manually and divide total elapsed seconds by the number of runs.

---

## Notes

- The script only sends keyboard input (`Z`, `X`, `Enter`) — it does not click or move the mouse
- Anti-cheat: this interacts with the game the same way a keyboard macro would. Use at your own discretion
- The 999 skill point cap is a Forza Horizon 6 mechanic — the script stops automatically at that threshold and will not over-farm

---

## License

MIT
