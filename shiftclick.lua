VERSION = "0.1.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

-- Stores anchor positions for each buffer (keyed by buffer path)
-- Each buffer has two entries: bufferPath_anchorX and bufferPath_anchorY
local anchorPositions = {}

function init()
	config.AddRuntimeFile("shiftclick", config.RTHelp, "help/shiftclick.md")
end

-- Called when user clicks (bound to MouseLeft in bindings.json)
-- Sets the anchor point at the cursor location after the click
function setAnchor(view)
	if not view or not view.Cursor or not view.Cursor.Loc then
		return false
	end

	local bufPath = view.Buf.AbsPath
	local c = view.Cursor

	-- Get cursor position (micro has already moved cursor to click location)
	local x = c.Loc.X
	local y = c.Loc.Y

	-- Store anchor coordinates for this buffer
	anchorPositions[bufPath .. "_anchorX"] = x
	anchorPositions[bufPath .. "_anchorY"] = y

	-- Clear any existing selection
	c:ResetSelection()
	view:Relocate()

	return false
end

-- Called when user shift-clicks (bound to Shift-MouseLeft in bindings.json)
-- Creates a selection from the stored anchor to the click location
function shiftClickSelect(view)
	if not view or not view.Cursor or not view.Cursor.Loc then
		return false
	end

	local bufPath = view.Buf.AbsPath
	local c = view.Cursor

	-- Get click location (current cursor position after shift-click)
	local clickX = c.Loc.X
	local clickY = c.Loc.Y

	-- Retrieve stored anchor for this buffer
	local anchorX = anchorPositions[bufPath .. "_anchorX"]
	local anchorY = anchorPositions[bufPath .. "_anchorY"]

	-- If no anchor exists, set this click as the anchor
	if not anchorX or not anchorY then
		anchorPositions[bufPath .. "_anchorX"] = clickX
		anchorPositions[bufPath .. "_anchorY"] = clickY
		return false
	end

	-- Create location objects for anchor and click positions
	local anchorLoc = buffer.Loc(anchorX, anchorY)
	local clickLoc = buffer.Loc(clickX, clickY)

	-- Determine selection direction (start must be before end)
	local startLoc, endLoc
	if anchorLoc:LessThan(clickLoc) then
		startLoc = anchorLoc
		endLoc = clickLoc
	else
		startLoc = clickLoc
		endLoc = anchorLoc
	end

	-- Apply the selection to the cursor
	-- CurSelection[1] and [2] define the selection boundaries
	c.CurSelection[1] = startLoc
	c.CurSelection[2] = endLoc
	-- OrigSelection stores the original selection for undo/redo
	c.OrigSelection[1] = buffer.Loc(anchorX, anchorY)
	c.OrigSelection[2] = buffer.Loc(clickX, clickY)

	-- Position cursor at the click location (end of selection)
	c:GotoLoc(clickLoc)
	view:Relocate()

	return false
end

-- Command to manually clear the anchor for the current buffer
function clearAnchor(view)
	local bufPath = view.Buf.AbsPath

	-- Remove anchor coordinates
	anchorPositions[bufPath .. "_anchorX"] = nil
	anchorPositions[bufPath .. "_anchorY"] = nil

	-- Clear any selection
	if view.Cursor then
		view.Cursor:ResetSelection()
	end
	view:Relocate()

	micro.InfoBar():Message("Anchor cleared")
	return true
end
