# DrumBrute Impact Step‑Sequencer for REAPER

A lightweight **ReaScript + ReaImGui** tool that turns REAPER into a pattern‑based sequencer tailored to the **Arturia DrumBrute Impact**. Click, drag and loop your way to classic drum‑machine workflows without leaving REAPER’s timeline.

**Built on** and inspired by <https://github.com/Arthur-McArthur/Arthur-McArthur-ReaScripts/tree/master/McSequencer>

![brute-seq reaper](https://github.com/user-attachments/assets/b72a3283-256b-4210-b44a-c216b2623573)

## Features

- **Track auto-setup**  
  Detects (or creates) a track named `MIDI-Drumbrute` and maps its 10 voices to the default MIDI notes.

- **Pattern per item**  
  Allows the creation of multiple patterns that seamlessly integrates with Reaper MIDI items.

- **Multi-step grid**  
  Click to toggle notes, drag to paint multiple steps, right-click to erase.

- **Realtime play-head**  
  Coloured cursor column shows the current step while playing or when the edit cursor moves.

- **Pattern ↔ Time-selection sync**  
  Jump between patterns, or set the time-selection to a pattern’s bounds with one click.

- **Steps / Times sliders**  
  - *Steps* → stretches or shrinks the MIDI source.  
  - *Times* → loops the source and pushes following patterns so they never overlap.

- **“Jump on Pattern Change” option**  
  When enabled, switching the pattern slider also moves the cursor.

- **Spacebar passthrough**  
  Space always Play/Stops REAPER even when the mouse is over the sequencer.


## Installation

1. **Dependencies**  
   * REAPER 7+ (tested on v7.39)  
   * [ReaImGui ≥ 0.9.3.3](https://github.com/cfillion/reaimgui)


## Quick‑start

1. Add (or let the script create) a track named **`MIDI-Drumbrute`**.  
2. Arm the track and select the desired MIDI output.  
3. Run **brute-seq**.  
4. Click **Add Pattern** → an empty 16‑step MIDI item appears.  
5. Toggle hits on the grid; drag across steps to paint them.  
6. Use **Steps** and **Times** sliders to shape the pattern. Items that follow are auto‑shifted to avoid overlaps.  
7. (Optional) Tick **Jump on Pattern change** so the play‑cursor follows when you move the *Pattern* slider.


## Customising note map

Edit the `tracks` table inside the script:

```lua
{ name = "Kick", note = 36 },
{ name = "Snare 1", note = 37 },
…
```

Change `note` values to match your custom DrumBrute Impact MIDI setup or rearrange the order as needed.

## License

Released under the **GNU General Public License v3.0**.  
Original McSequencer code © Arthur McArthur, used under GPLv3.
