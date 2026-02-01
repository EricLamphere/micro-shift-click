VERSION = "0.2.0"

local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")
local util = import("micro/util")

-- Stores anchor positions for each buffer (keyed by buffer path)
-- Each buffer has two entries: bufferPath_anchorX and bufferPath_anchorY
local anchorPositions = {}

-- Multi-click tracking
local lastClickTime = 0
local clickCount = 0
local lastClickY = -1
local MULTI_CLICK_THRESHOLD = 0.5 -- seconds

function init()
	config.AddRuntimeFile("shiftclick", config.RTHelp, "help/shiftclick.md")
end

-- Called when user clicks (bound to MouseLeft in bindings.json)
-- Handles single click (set anchor), double click (select word),
-- triple click (select line), and quadruple click (select all)
function setAnchor(view)
	if not view or not view.Cursor or not view.Cursor.Loc then
		return false
	end

	local bufPath = view.Buf.AbsPath
	local c = view.Cursor

	-- Get cursor position (micro has already moved cursor to click location)
	local x = c.Loc.X
	local y = c.Loc.Y

	-- Multi-click detection
	local currentTime = os.clock()
	local timeDiff = currentTime - lastClickTime

	if timeDiff < MULTI_CLICK_THRESHOLD and lastClickY == y then
		clickCount = clickCount + 1
	else
		clickCount = 1
	end

	lastClickTime = currentTime
	lastClickY = y

	if clickCount == 2 then
		-- Double click: select word
		local line = view.Buf:Line(y)
		local lineLen = util.CharacterCountInString(line)

		local wordStart = x
		local wordEnd = x

		-- Check if character at col is a word character (alphanumeric or underscore)
		local function isWordAt(col)
			if col < 0 or col >= lineLen then return false end
			local r = c:RuneUnder(col)
			if r > 255 then return false end
			return string.char(r):match("[%w_]") ~= nil
		end

		if isWordAt(x) then
			while wordStart > 0 and isWordAt(wordStart - 1) do
				wordStart = wordStart - 1
			end
			while wordEnd < lineLen - 1 and isWordAt(wordEnd + 1) do
				wordEnd = wordEnd + 1
			end
			c.CurSelection[1] = buffer.Loc(wordStart, y)
			c.CurSelection[2] = buffer.Loc(wordEnd + 1, y)
			c.OrigSelection[1] = buffer.Loc(wordStart, y)
			c.OrigSelection[2] = buffer.Loc(wordEnd + 1, y)
		end

		view:Relocate()
		return true
	elseif clickCount == 3 then
		-- Triple click: select line
		local lineLen = util.CharacterCountInString(view.Buf:Line(y))
		c.CurSelection[1] = buffer.Loc(0, y)
		c.CurSelection[2] = buffer.Loc(lineLen, y)
		c.OrigSelection[1] = buffer.Loc(0, y)
		c.OrigSelection[2] = buffer.Loc(lineLen, y)
		view:Relocate()
		return true
	elseif clickCount >= 4 then
		-- Quadruple click: select entire buffer
		c.CurSelection[1] = view.Buf:Start()
		c.CurSelection[2] = view.Buf:End()
		c.OrigSelection[1] = view.Buf:Start()
		c.OrigSelection[2] = view.Buf:End()
		view:Relocate()
		clickCount = 0 -- Reset cycle
		return true
	end

	-- Single click: set anchor and clear selection
	anchorPositions[bufPath .. "_anchorX"] = x
	anchorPositions[bufPath .. "_anchorY"] = y

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
