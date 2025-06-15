# Brute-Seq: DrumBrute Impact Step Sequencer for REAPER

Brute-Seq is a lightweight **ReaScript + ReaImGui** tool that brings a classic step-sequencer workflow to **REAPER**, specifically designed for the **Arturia DrumBrute Impact** drum machine.

Inspired by Arthur McArthur’s *McSequencer*, Brute-Seq adds multi-pattern support, accent hits, and improved usability.

![brute-seq](https://github.com/user-attachments/assets/06172d5b-8f90-4977-8761-9cd5ad8875ee)

## Features

### Track Auto-Setup

- Automatically creates a track named `Sequencer` mapped for DrumBrute Impact's 10 drum voices.
- Track name must end with **"Sequencer"** (e.g., "Drums Sequencer").

### Multiple Sequencer Tracks

- Supports multiple sequencer tracks in a project.
- GUI attaches to the selected track named ending in **"sequencer"**.

### Pattern-per-Item Workflow

- Each pattern is a standard REAPER MIDI item managed as separate "blocks".
- MIDI notes editable within and outside the sequencer.

### Multi-Step Grid Editor

- 16-step (or more) grid per drum voice.
- **Left-click:** toggle step on/off.
- **Shift+click:** accented hits (higher velocity).

### Real-Time Playhead

- Highlights current step during playback or cursor movement.

### Pattern Navigation & Sync

- Pattern selector slider to choose/edit patterns.
- Two looping modes:
  - **Loop Pattern:** loops current pattern.
  - **Loop Song:** loops entire sequence.

### Pattern Length & Repeats

- Adjustable with sliders:
  - **Steps:** 1 to 64 steps.
  - **Times:** repeats pattern content.

### Ripple Editing

- Automatically shifts subsequent patterns to avoid overlap.

### Pattern Management Buttons

- **"+" Add Pattern:** New blank pattern.
- **"++" Duplicate Pattern:** Copies current pattern.
- **"–" Delete Pattern:** Removes current pattern.

### Follow Mode (Jump on Pattern Change)

- Cursor jumps to the start of selected pattern when enabled.

### Spacebar Passthrough

- Spacebar starts/stops REAPER playback even when sequencer window is focused.

## Installation

### Dependencies

- **REAPER 7.0+** (tested on v7.39)
- **ReaImGui v0.9.3.3+** (required)
- **ReaPack** (recommended)

### Installation via ReaPack

1. **Install ReaPack**: Download from [ReaPack website](https://reapack.com).
2. **Install ReaImGui**: `Extensions → ReaPack → Browse Packages`, search for "ReaImGui", install, and restart REAPER.
3. **Add Brute-Seq Repository**: `Extensions → ReaPack → Import Repository`, paste:
   ```
   https://github.com/eritiro/brute-seq/raw/main/index.xml
   ```
4. **Install Brute-Seq**: `Extensions → ReaPack → Browse Packages`, search "brute-seq", install.
5. **Load Script**: Open Action List (`Actions → Show Action List`), run "Script: brute-seq.lua".

## Quick Start

- Launch Brute-Seq via Action List.
- Adds "Sequencer" track if none exists.
- **Add patterns**: Click `"+"`.
- **Edit grid**: Left-click toggles notes, Shift-click adds accents.
- **Play**: Spacebar.
- Adjust pattern length and repeats with sliders.

## Customizing Drum Lanes

Configure drum lane mapping:

- **GUI**: `Options → Configure track lanes`, edit names and MIDI notes.
- **Manual Edit**: Directly in `brute-seq.lua` (less recommended).

Default MIDI mapping:

```
Kick (36), Snare 1 (37), Snare 2 (38), Tom 1 (43), Tom 2 (47),
Cymbal (49), Cowbell (56), Closed Hat (60), Open Hat (61), FM Drum (64)
```

## Tips & Additional Info

- **Live Performance**: Useful for improvisation; toggle Follow mode for pattern auditioning.
- **Integration**: Patterns are regular MIDI items; freely editable in REAPER.
- **Accent Implementation**: Accented hits use higher MIDI velocity.
- **Undo Support**: All edits support undo (`Ctrl+Z`).

## License

Brute-Seq is open-source under **GPL v3** license. Contributions and feedback are welcome
