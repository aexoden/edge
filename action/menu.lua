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
_M.battle = {}

local input = require "util.input"
local memory = require "util.memory"
local walk = require "action.walk"

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

_M.battle.CHARACTER = {
	CECIL = 1,
	KAIN = 2,
	RYDIA = 3,
	TELLAH = 4,
	EDWARD = 5,
	ROSA = 6,
	YANG = 7,
	PALOM = 8,
	POROM = 9,
	CID = 14,
	EDGE = 18,
	FUSOYA = 19,
}

_M.battle.MENU = {
	NONE = 0,
	BASE = 1,
	PARRY = 2,
	CHANGE = 3,
	TARGET_FIGHT = 4,
	ITEM = 5,
	MAGIC = 6,
	TARGET_SKILL = 7,
	CLOSING = 8,
	OPENING_MAGIC = 9,
	CLOSING_MAGIC = 10,
	EQUIPMENT = 11,
	TARGET_ITEM_MAGIC = 12,
	CLOSING_ITEM = 15,
}

_M.battle.COMMAND = {
	FIGHT = 0,
	ITEM = 1,
	WHITE = 2,
	BLACK = 3,
	CALL = 4,
	JUMP = 6,
	SING = 8,
	AIM = 12,
	KICK = 14,
	TWIN = 16,
	COVER = 19,
	PEEP = 20,
	DART = 22,
	SNEAK = 23,
	NINJA = 24,
	CHANGE = 26,
	PARRY = 27,
	SHOW = 28,
	OFF = 29,
	NONE = 0xFF,
}

_M.battle.ITEM = {
	NONE = 0,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _wait_frame = nil

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _get_battle_dialog_text(characters)
	local text = ""

	for i = 0, characters - 1 do
		local character = memory.read("battle_dialog", "text", i)

		if character then
			text = text .. character
		end
	end

	return text
end

local function _is_open()
	return memory.read("menu", "state") > 0
end

local function _is_open_custom()
	return memory.read("menu_custom", "state") > 0
end

local function _is_battle_opening()
	return memory.read("battle_menu", "opening") == 1 or memory.read("battle_menu", "menu") == _M.battle.MENU.NONE
end

local function _is_ready()
	return memory.read("menu", "ready") == 10
end

local function _select(current, target, midpoint, delay)
	if target < current then
		if current - target <= midpoint then
			input.press({"P1 Up"}, delay)
		else
			input.press({"P1 Down"}, delay)
		end
	else
		if target - current <= midpoint then
			input.press({"P1 Down"}, delay)
		else
			input.press({"P1 Up"}, delay)
		end
	end
end

--------------------------------------------------------------------------------
-- Battle Menu Functions
--------------------------------------------------------------------------------

function _M.battle.get_character_id(slot)
	local character_id = bit.band(memory.read("character", "id", slot), 0x0F)

	if character_id == 10 or character_id == 12 then
		character_id = _M.CHARACTER.TELLAH
	elseif character_id == 11 then
		character_id = _M.CHARACTER.CECIL
	elseif character_id == 13 then
		character_id = _M.CHARACTER.YANG
	elseif character_id == 15 or character_id == 20 then
		character_id = _M.CHARACTER.KAIN
	elseif character_id == 16 then
		character_id = _M.CHARACTER.ROSA
	elseif character_id == 17 then
		character_id = _M.CHARACTER.RYDIA
	end

	return character_id
end

function _M.battle.base_select(target_command)
	if _is_battle_opening() then
		return false
	end

	local slot = memory.read("battle_menu", "slot")
	local cursor = memory.read("battle_menu", "cursor")
	local menu = memory.read("battle_menu", "menu")

	if menu == _M.battle.MENU.CHANGE then
		cursor = 5
	elseif menu == _M.battle.MENU.PARRY then
		cursor = 6
	end

	local index = 0
	local max_index = 0

	for i = 0, 6 do
		local command = memory.read("battle_menu", "command", slot, i)

		if command == target_command then
			index = i
		end

		if i < 5 and command ~= _M.battle.COMMAND.NONE then
			max_index = i
		end
	end

	if cursor == index then
		return input.press({"P1 A"}, input.DELAY.MASH)
	elseif index == 5 then
		input.press({"P1 Left"}, input.DELAY.MASH)
	elseif index == 6 then
		input.press({"P1 Right"}, input.DELAY.MASH)
	else
		_select(cursor, index, math.floor(max_index / 2), input.DELAY.MASH)
	end

	return false
end

function _M.battle.item_close()
	return input.press({"P1 B"}, input.DELAY.NORMAL)
end

function _M.battle.item_select(item, number)
	local menu = memory.read("battle_menu", "menu")

	if _is_battle_opening() or (menu ~= _M.battle.MENU.ITEM and menu ~= _M.battle.MENU.EQUIPMENT) then
		return false
	end

	if menu == _M.battle.MENU.EQUIPMENT then
		input.press({"P1 Down"}, input.DELAY.NORMAL)
		return false
	end

	local subcursor = memory.read("battle_menu", "subcursor")

	local count = 0
	local index = 0

	for i = 0, 47 do
		if memory.read("battle_menu", "item_id", index) == item then
			count = count + 1
		end

		if count == number then
			break
		end

		index = i
	end

	if subcursor == index then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	elseif subcursor > index then
		if (subcursor - index) % 2 ~= 0 then
			input.press({"P1 Left"}, input.DELAY.NORMAL)
		else
			input.press({"P1 Up"}, input.DELAY.NORMAL)
		end
	else
		if (index - subcursor) % 2 ~= 0 then
			input.press({"P1 Right"}, input.DELAY.NORMAL)
		else
			input.press({"P1 Down"}, input.DELAY.NORMAL)
		end
	end

	return false
end

function _M.battle.item_equipment_select(index)
	local menu = memory.read("battle_menu", "menu")

	if _is_battle_opening() or (menu ~= _M.battle.MENU.ITEM and menu ~= _M.battle.MENU.EQUIPMENT) then
		return false
	end

	if menu ~= _M.battle.MENU.EQUIPMENT then
		input.press({"P1 Up"}, input.DELAY.NORMAL)
		return false
	end

	local subcursor = memory.read("battle_menu", "subcursor")

	if subcursor == index then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	elseif subcursor > index then
		input.press({"P1 Left"}, input.DELAY.NORMAL)
	else
		input.press({"P1 Right"}, input.DELAY.NORMAL)
	end

	return false
end

function _M.battle.target(target)
	if _is_battle_opening() then
		return false
	end

	-- TODO: Actually target the given target.

	local menu = memory.read("battle_menu", "menu")

	if menu ~= _M.battle.MENU.TARGET_FIGHT and menu ~= _M.battle.MENU.TARGET_SKILL and menu ~= _M.battle.MENU.TARGET_ITEM_MAGIC then
		return false
	else
		return input.press({"P1 A"}, input.DELAY.MASH)
	end
end

function _M.battle.wait_frames(frames)
	if _wait_frame then
		if emu.framecount() >= _wait_frame then
			return true
		else
			return false
		end
	else
		_wait_frame = emu.framecount() + frames
		return false
	end
end

function _M.battle.wait_text(text)
	return _get_battle_dialog_text(#text) == text
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.open()
	if not walk.is_ready() then
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
