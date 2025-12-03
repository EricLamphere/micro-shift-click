# ShiftClick Selection Plugin for Micro

Enables VSCode-style shift-click text selection in the Micro editor.

## Features

- **Click** to set an anchor point
- **Shift-click** to select from anchor to the new position
- **Multiple shift-clicks** extend selection from the original anchor
- **Per-buffer anchors** - each open file maintains its own anchor independently

## Installation

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

## Version

1.0.0
