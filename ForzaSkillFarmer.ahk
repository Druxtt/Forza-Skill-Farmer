#Requires AutoHotkey v2
#SingleInstance force

; ═══════════════════════════════════════════════════════════
;  ForzaSkillFarmer
;  F4  →  Start (prompts for current skill pts)
;  F3  →  Stop
;  F8  →  Pixel color helper (hover + press to read X/Y/color)
; ═══════════════════════════════════════════════════════════

; ── Resolution preset ─────────────────────────────────────
; Set to "1440p" or "1080p". Each preset hardcodes:
;   - game window outer position  (screen coords)
;   - AHK GUI position            (screen coords)
;   - pixel trigger coordinates   (client coords)
;
; 1080p pixel coordinates are NOT calibrated yet — run the
; game at 1080p, use F8 to find your pixel values, then fill
; them into the 1080p block below.
PRESET   := "1440p"   ; "1440p" or "1080p"
KEYBOARD := "azerty"  ; "azerty" or "qwerty"

; ── Preset definitions ────────────────────────────────────
;
; All positions are OUTER FRAME screen coordinates (what WinMove uses).
; Measured with WindowSpy on the author's machine (Win11, no DPI scaling).
;
; 1440p (in-game render: 2560×1440, actual client: 1655×931)
;   Game outer  : x=867,  y=195  → client lands at x=875,  y=226
;   GUI  outer  : x=565,  y=433
;
; 1080p : ⚠ positions below are ESTIMATES — run diagnostic and update
;   Game outer  : x=867,  y=195  (uncalibrated)
;   GUI  outer  : x=565,  y=433  (uncalibrated)

if (PRESET = "1440p") {
    GAME_X       := 867   ; outer frame X
    GAME_Y       := 195   ; outer frame Y
    GAME_W       := 1671  ; outer frame W  (client lands at 1655×931)
    GAME_H       := 970   ; outer frame H
    GUI_X        := 565   ; AHK GUI X
    GUI_Y        := 433   ; AHK GUI Y
    ; Pixel triggers — screen-absolute coords (valid when window is at GAME_X/Y)
    PIX_START_X  := 126   ; start screen pixel X
    PIX_START_Y  := 36    ; start screen pixel Y
    PIX_START_C  := "0x165EDB"
    PIX_SCORE_X  := 276   ; scoreboard pixel X
    PIX_SCORE_Y  := 263   ; scoreboard pixel Y
    PIX_SCORE_C  := "0xFFDE39"
} else if (PRESET = "1080p") {
    GAME_X       := 867   ; outer frame X
    GAME_Y       := 195   ; outer frame Y
    GAME_W       := 1616  ; outer frame W  (client lands at 1600×900)
    GAME_H       := 939   ; outer frame H
    GUI_X        := 565   ; AHK GUI X
    GUI_Y        := 433   ; AHK GUI Y
    ; ⚠ Pixel triggers not calibrated for 1080p — use F8 to find your values
    PIX_START_X  := 0
    PIX_START_Y  := 0
    PIX_START_C  := "0x000000"
    PIX_SCORE_X  := 0
    PIX_SCORE_Y  := 0
    PIX_SCORE_C  := "0x000000"
} else {
    MsgBox "Unknown preset '" PRESET "'. Set PRESET to `"1440p`" or `"1080p`".", "ForzaSkillFarmer"
    ExitApp
}

; ── Keyboard layout ──────────────────────────────────────
ACCEL_KEY := (KEYBOARD = "qwerty") ? "w" : "z"

; ── Window snap ───────────────────────────────────────────
SnapGameWindow() {
    global GAME_X, GAME_Y, GAME_W, GAME_H
    if !WinExist("ahk_exe forzahorizon6.exe") {
        MsgBox "Forza Horizon 6 not found. Launch the game first.", "ForzaSkillFarmer"
        return false
    }
    WinRestore "ahk_exe forzahorizon6.exe"
    Sleep 100
    WinMove GAME_X, GAME_Y, GAME_W, GAME_H, "ahk_exe forzahorizon6.exe"
    Sleep 400

    ; Verify the outer frame landed at the right position
    WinGetPos &fx, &fy, &fw, &fh, "ahk_exe forzahorizon6.exe"
    if (fx != GAME_X || fy != GAME_Y) {
        MsgBox "Window snap failed — frame landed at (" fx ", " fy ") instead of (" GAME_X ", " GAME_Y ")."
            . "`n`nCheck that the game is in windowed mode and try again.", "ForzaSkillFarmer"
        return false
    }
    return true
}

; ── Constants ─────────────────────────────────────────────
POINTS_PER_RUN  := 10
MAX_POINTS      := 999
SECS_PER_RUN    := 54.55    ; calibrated at 1440p: 90 min / 99 runs

; ── State ─────────────────────────────────────────────────
running      := false
runCount     := 0
totalPoints  := 0
startPoints  := 0
targetRuns   := 0
startTime    := 0

; ── GUI ───────────────────────────────────────────────────
g := Gui("+AlwaysOnTop -MaximizeBox -MinimizeBox", "ForzaSkillFarmer")
g.SetFont("s10", "Segoe UI")
g.BackColor := "1a1a2e"
g.MarginX := 16
g.MarginY := 14

g.SetFont("s13 w700 cE94560", "Segoe UI")
g.Add("Text", "w260 Center", "FORZA SKILL FARMER")

g.SetFont("s8 c2a2a4a")
g.Add("Text", "w260 Center y+4", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

g.SetFont("s9 w400 c888888", "Segoe UI")
g.Add("Text", "w100 y+8", "Status")
g.SetFont("s9 w700 cFF6666")
statusLabel := g.Add("Text", "w160 Right", "Stopped")

g.SetFont("s9 w400 c888888", "Segoe UI")
g.Add("Text", "w100 y+6", "Runs")
g.SetFont("s9 w700 cFFFFFF")
runsLabel := g.Add("Text", "w160 Right", "0 / —")

g.SetFont("s9 w400 c888888", "Segoe UI")
g.Add("Text", "w100 y+6", "Skill points")
g.SetFont("s9 w700 cE94560")
pointsLabel := g.Add("Text", "w160 Right", "— / 999")

g.SetFont("s9 w400 c888888", "Segoe UI")
g.Add("Text", "w100 y+6", "Elapsed")
g.SetFont("s9 w700 cFFFFFF")
elapsedLabel := g.Add("Text", "w160 Right", "—")

g.SetFont("s9 w400 c888888", "Segoe UI")
g.Add("Text", "w100 y+6", "ETA")
g.SetFont("s9 w700 cFFDD77")
etaLabel := g.Add("Text", "w160 Right", "—")

g.SetFont("s8 c2a2a4a")
g.Add("Text", "w260 Center y+10", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

g.SetFont("s8 w400 c555577", "Segoe UI")
g.Add("Text", "w260 Center y+4", "F4 start    F3 stop    F8 pixel helper")

g.Show("w292 NA x" GUI_X " y" GUI_Y)

; ── Elapsed / ETA timer ───────────────────────────────────
SetTimer UpdateElapsed, 1000

UpdateElapsed() {
    global running, startTime, elapsedLabel, etaLabel, runCount, targetRuns, SECS_PER_RUN
    if !running
        return
    elapsed := (A_TickCount - startTime) // 1000
    h := elapsed // 3600
    m := Mod(elapsed, 3600) // 60
    s := Mod(elapsed, 60)
    elapsedLabel.Value := Format("{:02}:{:02}:{:02}", h, m, s)

    remaining := targetRuns - runCount
    if (remaining > 0) {
        etaSecs := Round(remaining * SECS_PER_RUN)
        eh := etaSecs // 3600
        em := Mod(etaSecs, 3600) // 60
        es := Mod(etaSecs, 60)
        etaLabel.Value := Format("{:02}:{:02}:{:02}", eh, em, es)
    } else {
        etaLabel.Value := "—"
    }
}

; ── Helpers ───────────────────────────────────────────────
WaitForPixel(x, y, targetColor, timeoutMs := 15000) {
    global running
    deadline := A_TickCount + timeoutMs
    Loop {
        if !running          ; bail out immediately if F3 was pressed
            return false
        if (PixelGetColor(x, y, "RGB") = targetColor)
            return true
        if (A_TickCount > deadline)
            return false
        Sleep 100
    }
}

UpdateStats() {
    global running, runCount, targetRuns, totalPoints, startPoints, MAX_POINTS
    global statusLabel, runsLabel, pointsLabel
    if !running   ; don't overwrite Stopped status if F3 was pressed
        return
    statusLabel.Value := "Running"
    statusLabel.SetFont("cAAFF88")
    runsLabel.Value   := runCount " / " targetRuns
    pointsLabel.Value := (startPoints + totalPoints) " / " MAX_POINTS
}

; ── Hotkeys ───────────────────────────────────────────────
F8:: {
    MouseGetPos &mx, &my
    color := PixelGetColor(mx, my, "RGB")
    MsgBox "X: " mx " | Y: " my " | Color: " color
}

F3:: {
    global running, statusLabel, elapsedLabel, etaLabel, runsLabel, pointsLabel
    running := false
    Send "{" ACCEL_KEY " up}"
    statusLabel.Value := "Stopped"
    statusLabel.SetFont("cFF6666")
    elapsedLabel.Value := "—"
    etaLabel.Value     := "—"
}

F4:: {
    global running, runCount, totalPoints, startPoints, targetRuns
    global startTime, POINTS_PER_RUN, MAX_POINTS
    global statusLabel, runsLabel, pointsLabel, elapsedLabel, etaLabel
    global PIX_START_X, PIX_START_Y, PIX_START_C
    global PIX_SCORE_X, PIX_SCORE_Y, PIX_SCORE_C

    if running
        return

    if !SnapGameWindow()
        return

    IB := InputBox("How many skill points do you currently have? (0–998)", "ForzaSkillFarmer", "w300 h120", "0")
    if (IB.Result = "Cancel")
        return

    current := Integer(IB.Value)
    if (current < 0 || current >= MAX_POINTS) {
        MsgBox "Enter a value between 0 and 998.", "Invalid input"
        return
    }

    needed       := Ceil((MAX_POINTS - current) / POINTS_PER_RUN)
    startPoints  := current
    targetRuns   := needed
    runCount     := 0
    totalPoints  := 0
    startTime    := A_TickCount
    running      := true

    runsLabel.Value   := "0 / " targetRuns
    pointsLabel.Value := current " / " MAX_POINTS
    statusLabel.Value := "Syncing..."
    statusLabel.SetFont("cFFDD77")
    elapsedLabel.Value := "00:00:00"

    WaitForPixel(PIX_START_X, PIX_START_Y, PIX_START_C, 30000)
    Sleep 200

    Loop {
        if !running
            break

        if (runCount >= targetRuns) {
            running := false
            finalPts := startPoints + totalPoints
            statusLabel.Value := "Done!  " finalPts " / " MAX_POINTS " pts"
            statusLabel.SetFont("cAAFF88")
            etaLabel.Value := "—"
            MsgBox "AFK session complete!`n`nRuns completed  : " runCount "`nSkill pts earned: " totalPoints "`nTotal           : " finalPts " / " MAX_POINTS, "ForzaSkillFarmer"
            break
        }

        UpdateStats()

        Send "{Enter}"
        Sleep 800

        Send "{" ACCEL_KEY " down}"
        WaitForPixel(PIX_SCORE_X, PIX_SCORE_Y, PIX_SCORE_C, 30000)
        Send "{" ACCEL_KEY " up}"

        Sleep 500
        Send "x"
        Sleep 300
        Send "{Enter}"

        WaitForPixel(PIX_START_X, PIX_START_Y, PIX_START_C, 15000)
        Sleep 200

        runCount    += 1
        totalPoints += POINTS_PER_RUN
        UpdateStats()
    }
}
