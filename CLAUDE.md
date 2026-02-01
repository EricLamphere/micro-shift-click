# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Lua plugin for the Micro editor (micro-editor.github.io) that adds VSCode-style shift-click text selection. Users click to set an anchor point, then shift-click to select from the anchor to the new position. Each buffer maintains its own independent anchor.

**Language**: Lua (Micro plugin API)
**Version**: 1.0.0
**Main file**: `shiftclick.lua` (111 lines)

## Architecture

The plugin consists of three core functions:

### 1. `setAnchor(view)` (lines 17-38)
- Bound to `MouseLeft` in user's bindings.json
- Stores cursor position (X, Y) as anchor for current buffer
- Clears any existing selection
- Uses per-buffer storage keyed by `bufPath_anchorX` and `bufPath_anchorY`

### 2. `shiftClickSelect(view)` (lines 42-92)
- Bound to `Shift-MouseLeft` in user's bindings.json
- Retrieves stored anchor for current buffer
- Creates selection from anchor to click position using `buffer.Loc`
- Handles both forward and backward selection automatically
- Falls back to setting anchor if none exists

### 3. `clearAnchor(view)` (lines 95-110)
- Optional command to manually clear anchor
- Removes stored coordinates and resets selection

**Data flow**: User clicks → Micro moves cursor → Plugin stores/retrieves anchor → Selection applied via `c.CurSelection[1]` and `c.CurSelection[2]`

## Technical Constraints

### Why Bindings Instead of Callbacks?

In Micro v2.0.14, mouse event callbacks (`preMousePress`, `onMousePress`) do not receive the event parameter, making it impossible to detect modifier keys like Shift through callbacks.

**Solution**: Use separate key bindings for `MouseLeft` and `Shift-MouseLeft`, which Micro properly detects as distinct events. Both bindings chain with `MousePress` to preserve normal cursor movement.

**Required user configuration** (`~/.config/micro/bindings.json`):
```json
{
    "MouseLeft": "MousePress,lua:shiftclick.setAnchor",
    "Shift-MouseLeft": "MousePress,lua:shiftclick.shiftClickSelect"
}
```

## Key Implementation Details

### Anchor Storage
- Anchors stored as **numbers** in a Lua table, not `buffer.Loc` objects
- **Why**: Created `buffer.Loc` objects don't allow reading `.X` and `.Y` properties
- Each buffer identified by `view.Buf.AbsPath`
- Two entries per buffer: `bufferPath_anchorX` and `bufferPath_anchorY`

### Selection Handling
- `c.CurSelection[1]` = start position (must be before end)
- `c.CurSelection[2]` = end position
- `c.OrigSelection` = stores original anchor and click for undo/redo support
- Direction determined using `anchorLoc:LessThan(clickLoc)`

### Import Requirements
- Buffer module must be imported as `import("micro/buffer")` NOT `import("buffer")`
- Standard imports: `micro`, `micro/config`, `micro/buffer`

## Testing the Plugin

Since this is a plugin, there's no build process. To test changes:

1. **Install plugin**: Copy `shiftclick.lua` and `help/` directory to `~/.config/micro/plug/shiftclick/`
2. **Configure bindings**: Add the required bindings to `~/.config/micro/bindings.json` (see above)
3. **Reload Micro**: Close and restart Micro, or reload plugins if supported
4. **Test workflow**:
   - Click to set anchor
   - Shift-click elsewhere to create selection
   - Verify selection spans from anchor to click position
   - Test in multiple open buffers to verify per-buffer anchors work independently

## Version Compatibility

- **Micro**: 2.0.14+ (tested on 2.0.14)
- **Platform**: All platforms that Micro supports
- **Terminal**: Requires terminal that forwards Shift+mouse events properly
