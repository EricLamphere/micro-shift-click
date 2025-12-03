# ShiftClick Plugin

Enables VSCode-style shift-click text selection in the Micro editor.

## Features

- **Normal Click**: Sets an anchor point at the click position
- **Shift-Click**: Selects from the stored anchor point to the new click position
- **Per-Buffer Anchors**: Each buffer maintains its own anchor position

## Installation

### Install the Plugin

**Using Plugin Manager (Recommended):**

1. Add to `~/.config/micro/settings.json`:
   ```json
   {
       "pluginrepos": [
           "https://raw.githubusercontent.com/EricLamphere/micro-shift-click/main/repo.json"
       ]
   }
   ```

2. Run: `micro -plugin install shiftclick`

**Manual Installation:**

Copy `shiftclick.lua` and `help/` to `~/.config/micro/plug/shiftclick/`

### Configure Bindings

Add these bindings to `~/.config/micro/bindings.json`:

```json
{
    "MouseLeft": "MousePress,lua:shiftclick.setAnchor",
    "Shift-MouseLeft": "MousePress,lua:shiftclick.shiftClickSelect"
}
```

## Usage

Once the bindings are configured:

1. Click normally anywhere in your document - this sets the anchor point
2. Hold Shift and click elsewhere - this creates a selection from the anchor to your new position
3. You can shift-click multiple times using the same anchor point
4. A new normal click will reset the anchor to the new position

## Commands

- `clearAnchor` - Clear the anchor for the current buffer

Example binding:
```json
"Ctrl-Shift-C": "lua:shiftclick.clearAnchor"
```

## Edge Cases

- If no anchor exists when shift-clicking, the anchor is set at the current position (no selection)
- Each buffer has its own independent anchor position
- Anchors persist until you click normally again or close the buffer
