--------------------------------------------------------------------------------
-- Copyright (c) 2015 Jason Lynch <jason@calindora.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--------------------------------------------------------------------------------

local _M = {}

local flags = require "util.flags"
local input = require "util.input"
local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.MENU = {
	ITEM = 0,
	MAGIC = 1,
	EQUIP = 2,
	STATUS = 3,
	FORM = 4,
	CHANGE = 5,
	CUSTOM = 6,
	SAVE = 7,
}

_M.MENU_CUSTOM = {
	SPEED = 0,
	MESSAGE = 1,
	SOUND = 2,
	R = 3,
	G = 4,
	B = 5,
}

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _is_open()
	return memory.read("menu", "open") > 0
end

local function _is_open_custom()
	return memory.read("menu_custom", "open") > 0
end

local function _is_ready()
	return memory.read("menu", "ready") == 10
end

local function _select(current, target, midpoint)
	if target < current then
		if current - target <= midpoint then
			input.press({"P1 Up"})
		else
			input.press({"P1 Down"})
		end
	else
		if target - current <= midpoint then
			input.press({"P1 Down"})
		else
			input.press({"P1 Up"})
		end
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.open()
	if not flags.is_ready() then
		return false
	end

	return input.press({"P1 X"}, input.DELAY.MASH)
end

function _M.close()
	if not _is_ready() then
		return false
	end

	return input.press({"P1 B"}, input.DELAY.MASH)
end

function _M.close_custom()
	return input.press({"P1 B"})
end

function _M.select(target)
	local current = memory.read("menu", "cursor")

	if current == target then
		return input.press({"P1 A"})
	end

	_select(current, target, 4)

	return false
end

function _M.select_custom(target)
	local current = memory.read("menu_custom", "cursor")

	if not _is_open_custom() then
		return false
	elseif current == target then
		return true
	end

	_select(current, target, 4)

	return false
end

return _M
