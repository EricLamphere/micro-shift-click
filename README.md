# ShiftClick Selection Plugin for Micro

Enables VSCode-style shift-click text selection in the Micro editor.

## Features

- **Click** to set an anchor point
- **Shift-click** to select from anchor to the new position
- **Multiple shift-clicks** extend selection from the original anchor
- **Per-buffer anchors** - each open file maintains its own anchor independently

## Installation

### 1. Install the Plugin

**Option A: Using Micro's Plugin Manager (Recommended)**

1. Add this plugin repository to your Micro settings (`~/.config/micro/settings.json`):
   ```json
   {
       "pluginrepos": [
           "https://raw.githubusercontent.com/EricLamphere/micro-shift-click/main/repo.json"
       ]
   }
   ```

2. Install the plugin:
   ```bash
   micro -plugin install shiftclick
   ```

**Option B: Manual Installation**

1. Create the plugin directory:
   ```bash
   mkdir -p ~/.config/micro/plug/shiftclick
   ```

2. Copy the plugin files:
   ```bash
   cp shiftclick.lua ~/.config/micro/plug/shiftclick/
   cp -r help ~/.config/micro/plug/shiftclick/
   ```

**Option C: Git Clone**

```bash
cd ~/.config/micro/plug
git clone https://github.com/EricLamphere/micro-shift-click.git shiftclick
```

### 2. Configure Bindings

This plugin requires bindings configuration to work.

Add these lines to your `~/.config/micro/bindings.json`:

```json
{
    "MouseLeft": "MousePress,lua:shiftclick.setAnchor",
    "Shift-MouseLeft": "MousePress,lua:shiftclick.shiftClickSelect"
}
```

**Important:** These bindings chain with `MousePress` to ensure normal cursor movement still works.

## Usage

1. **Set anchor**: Click anywhere in your file
2. **Create selection**: Hold Shift and click elsewhere
3. **Extend selection**: Continue shift-clicking to select different ranges from the same anchor
4. **Reset anchor**: Click normally (without Shift) to set a new anchor point

## Commands

- `clearAnchor` - Manually clear the anchor for the current buffer

You can bind it to a key if desired:
```json
"Ctrl-Shift-C": "lua:shiftclick.clearAnchor"
```

## How It Works

The plugin uses mouse bindings to detect normal clicks and shift-clicks:

1. **Normal click** (`MouseLeft` binding):
   - Micro moves the cursor to the click location
   - Plugin stores that position as the anchor for this buffer
   - Any existing selection is cleared

2. **Shift-click** (`Shift-MouseLeft` binding):
   - Micro moves the cursor to the click location
   - Plugin retrieves the stored anchor
   - Creates a selection from anchor to click position
   - Handles selection direction automatically (forward or backward)

Each buffer maintains its own independent anchor, so you can work with multiple files simultaneously without interference.

## Technical Details

### Why Bindings Instead of Callbacks?

In Micro v2.0.14, mouse event callbacks (`preMousePress`, `onMousePress`) do not receive the event parameter, making it impossible to detect shift-clicks through callbacks alone.

The solution is to use bindings that distinguish `MouseLeft` from `Shift-MouseLeft`, which Micro properly detects as separate events.

### Key Implementation Points

- Anchor coordinates are stored as numbers (not `buffer.Loc` objects) because created Loc objects don't allow reading `.X` and `.Y` properties
- Selection uses `c.CurSelection[1]` and `c.CurSelection[2]` for the selection boundaries
- `c.OrigSelection` is set for undo/redo support
- The `buffer` module must be imported as `import("micro/buffer")` not `import("buffer")`

## Compatibility

- **Micro version**: 2.0.14+ (tested on 2.0.14)
- **Platform**: All platforms supported by Micro
- **Terminal**: Works in any terminal that properly forwards Shift+mouse events

## Creating a New Release

Follow these steps when releasing a new version of the plugin:

### 1. Update Version Numbers

Update the version in `shiftclick.lua`:
```lua
VERSION = "0.2.0"  // Change to your new version
```

### 2. Update repo.json

Add a new version entry to the `Versions` array in `repo.json`:
```json
{
  "Name": "shiftclick",
  "Description": "VSCode-style shift-click text selection for Micro editor",
  "Website": "https://github.com/EricLamphere/micro-shift-click",
  "Tags": ["selection", "mouse", "ui"],
  "Versions": [
    {
      "Version": "0.2.0",
      "Url": "https://github.com/EricLamphere/micro-shift-click/archive/refs/tags/v0.2.0.zip",
      "Require": {
        "micro": ">=2.0.14"
      }
    },
    {
      "Version": "0.1.0",
      "Url": "https://github.com/EricLamphere/micro-shift-click/archive/refs/tags/v0.1.0.zip",
      "Require": {
        "micro": ">=2.0.14"
      }
    }
  ]
}
```

**Note**: Add new versions at the top of the array. The plugin manager uses the first entry as the latest version. Use `.zip` URLs instead of `.tar.gz` for compatibility with Micro's plugin manager.

### 3. Commit Changes

```bash
git add shiftclick.lua repo.json
git commit -m "Bump version to 0.2.0"
```

### 4. Create and Push Git Tag

```bash
# Create annotated tag
git tag -a v0.2.0 -m "Release v0.2.0 - [brief description of changes]"

# Push commit and tag
git push origin main
git push origin v0.2.0
```

### 5. Create Release Zip File (Optional)

GitHub automatically creates zip and tarball archives for each tag. However, if you need to create a custom zip file:

```bash
# Create a zip file of the plugin directory
zip -r micro-shift-click-0.2.0.zip shiftclick.lua help/ repo.json README.md -x "*.git*"

# Or create from the git repository
git archive -o micro-shift-click-0.2.0.zip --prefix=shiftclick/ v0.2.0
```

**Note**: The Micro plugin manager works with GitHub's automatic archive URLs (as shown in repo.json), so creating a custom zip is typically not necessary.

### 6. Verify Release

Check that these URLs are accessible:
- Tag: `https://github.com/EricLamphere/micro-shift-click/releases/tag/v0.2.0`
- Zip archive: `https://github.com/EricLamphere/micro-shift-click/archive/refs/tags/v0.2.0.zip`
- Repo file: `https://raw.githubusercontent.com/EricLamphere/micro-shift-click/main/repo.json`

Users can now update by running: `micro -plugin update shiftclick`

## Version

0.1.0
