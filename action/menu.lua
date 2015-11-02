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
_M.shop = {}

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

_M.CHARACTER = {
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

_M.EQUIP = {
	R_HAND = 0,
	L_HAND = 1,
	HEAD = 2,
	BODY = 3,
	ARMS = 4,
}

_M.ITEM = {
	NONE = 0x00,
	TENT = 0xE2,
	DAGGER = {
		DANCING = 0x3C,
	},
	SHIELD = {
		SHADOW = 0x62,
	},
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

_M.shop.MENU = {
	BUY = 0,
	SELL = 1,
	EXIT = 2,
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

local function _get_item_index(category, key, item, number)
	local count = 0

	for i = 0, 47 do
		if memory.read(category, key, i) == item then
			count = count + 1
		end

		if count == number then
			return i
		end
	end

	return 0
end

local function _is_open()
	return memory.read("menu", "state") > 0
end

local function _is_open_custom()
	return memory.read("menu_custom", "state") > 0
end

local function _is_open_item()
	return memory.read("menu_item", "state") > 0
end

local function _is_open_save()
	return memory.read("menu_save", "state") > 0
end

local function _is_battle_opening()
	return memory.read("battle_menu", "opening") == 1 or memory.read("battle_menu", "menu") == _M.battle.MENU.NONE
end

local function _is_ready()
	return memory.read("menu", "ready") == 10
end

local function _is_sell_ready()
	return memory.read("menu_shop", "sell_state") == 129
end

local function _is_buy_ready()
	return memory.read("menu_shop", "buy_state") == 129
end

local function _is_active()
	return memory.read("menu", "active") == 0
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

local function _select_horizontal(current, target, midpoint, delay)
	if target < current then
		if current - target <= midpoint then
			input.press({"P1 Left"}, delay)
		else
			input.press({"P1 Right"}, delay)
		end
	else
		if target - current <= midpoint then
			input.press({"P1 Right"}, delay)
		else
			input.press({"P1 Left"}, delay)
		end
	end
end

local function _select_item(current, target)
	if current == target then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	elseif current > target then
		if (current - target) % 2 ~= 0 then
			input.press({"P1 Left"}, input.DELAY.NORMAL)
		else
			input.press({"P1 Up"}, input.DELAY.NORMAL)
		end
	else
		if (target - current) % 2 ~= 0 then
			input.press({"P1 Right"}, input.DELAY.NORMAL)
		else
			input.press({"P1 Down"}, input.DELAY.NORMAL)
		end
	end

	return false
end

--------------------------------------------------------------------------------
-- Battle Menu Functions
--------------------------------------------------------------------------------

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
	local index = _get_item_index("battle_menu", "item_id", item, number)

	return _select_item(subcursor, index)
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

function _M.battle.wait_text(text)
	return _get_battle_dialog_text(#text) == text
end

--------------------------------------------------------------------------------
-- Shop Menu Functions
--------------------------------------------------------------------------------

function _M.shop.select(target)
	if not _is_ready() then
		return false
	end

	local cursor = memory.read("menu_shop", "cursor")

	if cursor == target then
		return input.press({"P1 A"})
	end

	_select_horizontal(cursor, target, 1)

	return false
end

function _M.shop.select_count(target)
	if not _is_sell_ready() and not _is_buy_ready() then
		return false
	end

	local cursor = memory.read("menu_shop", "subcursor")

	if target == 1 then
		if cursor == 0 then
			return input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			_select_horizontal(cursor, 0, 1)
		end
	else
		if cursor == 1 then
			local count = memory.read("menu_shop", "count")

			if count == target then
				return input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				local delta = math.abs(count - target)

				if delta > 5 then
					input.press({"P1 X"}, input.DELAY.NORMAL)
				else
					if count < target then
						input.press({"P1 Up"}, input.DELAY.NORMAL)
					else
						input.press({"P1 Down"}, input.DELAY.NORMAL)
					end
				end
			end
		else
			_select_horizontal(cursor, 1, 1)
		end
	end

	return false
end

function _M.shop.select_buy(item)
	local index = 0
	local max = 0

	for i = 0, 7 do
		local value = memory.read("menu_shop", "buy_item", i)

		if value == item then
			index = i
		elseif value == 0 then
			max = i
			break
		end
	end

	local cursor = memory.read("menu_shop", "buy")

	if cursor == index then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	end

	_select(cursor, index, math.floor(max / 2))

	return false
end

function _M.shop.select_sell(item)
	local cursor = (memory.read("menu_shop", "sell_y") + memory.read("menu_shop", "sell_scroll")) * 2 + memory.read("menu_shop", "sell_x")
	local index = _get_item_index("menu_item", "item_id", item, 1)

	return _select_item(cursor, index)
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.get_character_id(slot)
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

function _M.open(delay)
	if not walk.is_ready() then
		return false
	end

	if not delay then
		delay = input.DELAY.MASH
	end

	return input.press({"P1 X"}, delay)
end

function _M.close()
	if emu.islagged() or not _is_ready() then
		return false
	end

	return input.press({"P1 B"}, input.DELAY.MASH)
end

function _M.close_custom()
	return input.press({"P1 B"})
end

function _M.confirm()
	if not _is_ready() then
		return false
	end

	return input.press({"P1 A"}, input.DELAY.NORMAL)
end

function _M.select(target)
	if not _is_ready() or not _is_active() then
		return false
	end

	local current = memory.read("menu", "cursor")

	if current == target then
		return input.press({"P1 A"})
	end

	_select(current, target, 4)

	return false
end

function _M.select_character(character)
	if not _is_ready() then
		return false
	end

	local index = 0

	local slots = {
		[0] = 2,
		[1] = 0,
		[2] = 4,
		[3] = 1,
		[4] = 3,
	}

	for i = 0, 4 do
		local id = _M.get_character_id(i)

		if id == character then
			index = slots[i]
		end
	end

	local character = memory.read("menu", "character")

	if character == index then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	else
		_select(memory.read("menu", "character"), index, 2)
	end

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

function _M.select_equip(target)
	local current = memory.read("menu_equip", "cursor")

	if not _is_ready() then
		return false
	elseif current == target then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	end

	_select(current, target, 2)

	return false
end

function _M.select_equip_item(item, number)
	if not _is_ready() then
		return false
	end

	local cursor = memory.read("menu_equip", "cursor")

	local subcursor = (memory.read("menu_equip", "subcursor_y", cursor) + memory.read("menu_equip", "scroll", cursor)) * 2 + memory.read("menu_equip", "subcursor_x", cursor)
	local index = _get_item_index("menu_item", "item_id", item, number)

	return _select_item(subcursor, index)
end

function _M.select_item(item, number)
	if not _is_open_item() or not _is_ready() then
		return false
	end

	local cursor = (memory.read("menu_item", "cursor_y") + memory.read("menu_item", "scroll")) * 2 + memory.read("menu_item", "cursor_x")
	local index = _get_item_index("menu_item", "item_id", item, number)

	return _select_item(cursor, index)
end

function _M.select_save(slot)
	local cursor = memory.read("menu_save", "cursor")

	if not _is_open_save() then
		return false
	elseif cursor == slot then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	end

	_select(cursor, slot, 2)

	return false
end

function _M.wait_frames(frames)
	if not input.is_clear() then
		return false
	end

	if _wait_frame then
		if emu.framecount() >= _wait_frame then
			_wait_frame = nil
			return true
		else
			return false
		end
	else
		_wait_frame = emu.framecount() + frames
		return false
	end
end

return _M
