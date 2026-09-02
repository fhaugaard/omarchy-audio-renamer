# Audio Device Renamer (`skye.audio-renamer`)

A first-class plugin and CLI tool for **Omarchy** and **WirePlumber / PipeWire** that allows you to easily rename audio output (sinks) and input (sources) devices and have those custom names persist across the entire system.

---

## Features

- **Omarchy Shell Panel UI**: Centered interactive modal overlay built with native Omarchy styling (`Color.menu`, `Style`, `qs.Ui`).
- **WirePlumber 0.5 Integration**: Automatically generates and manages `~/.config/wireplumber/wireplumber.conf.d/50-device-rename.conf`.
- **System-Wide Aliases**: Renamed devices appear everywhere in Omarchy (bar audio widget, volume OSD, PipeWire mixer, PulseAudio apps, browser selectors).
- **CLI Utility**: `omarchy-audio-rename` command-line tool with JSON support, device discovery, and alias management.
- **Launcher Menu Shortcut**: Integrated into Omarchy's launcher menu (`Super` -> Setup -> Rename Audio Devices).

---

## Usage

### 1. Graphical Interface
To open the renamer UI:
- Press `Super` to open the Omarchy menu and select **Rename Audio Devices** (under Setup).
- Or run:
  ```bash
  omarchy-audio-rename gui
  ```
- Or summon via shell IPC:
  ```bash
  omarchy-shell shell summon skye.audio-renamer '{}'
  ```

In the UI:
1. Type a new name into the field for any output or input device.
2. Click **Save** or press **Enter**.
3. To restore the original hardware description, click **Reset**.

---

### 2. Command-Line (CLI)

```bash
# List all detected audio devices and their current aliases
omarchy-audio-rename list

# List all devices including microphones/inputs
omarchy-audio-rename list --all

# Set a custom name by device ID, node name, or search keyword
omarchy-audio-rename set 32 "Studio Monitors"
omarchy-audio-rename set "pro-output-1" "Desk Speakers"
omarchy-audio-rename set "CU34G4" "Monitor Audio"

# Reset a device back to its default name
omarchy-audio-rename reset 32

# Reset all devices back to system defaults
omarchy-audio-rename reset-all
```

---

## Files and Architecture

- `manifest.json`: Shell plugin declaration.
- `Panel.qml`: Native Quickshell overlay panel.
- `Model.js`: Device icon mapping and utilities.
- `bin/omarchy-audio-rename`: Backend Python manager (symlinked to `~/.local/bin/omarchy-audio-rename`).
- `~/.config/omarchy/audio-renames.json`: Persistent alias configuration.
- `~/.config/wireplumber/wireplumber.conf.d/50-device-rename.conf`: Generated WirePlumber SPA-JSON rules.
