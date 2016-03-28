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

_M.battle = {
	command = {},
	dialog = {},
	equip = {},
	item = {},
	magic = {},
}

_M.dialog = {}

_M.field = {
	custom = {},
	equip = {},
	form = {},
	item = {},
	magic = {},
	save = {},
}

_M.shop = {
	buy = {},
	sell = {},
}

local dialog = require "util.dialog"
local game = require "util.game"
local input = require "util.input"
local memory = require "util.memory"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.battle.COMMAND = {
	FIGHT  = 0x00,
	ITEM   = 0x01,
	WHITE  = 0x02,
	BLACK  = 0x03,
	CALL   = 0x04,
	JUMP   = 0x06,
	SING   = 0x08,
	AIM    = 0x0C,
	KICK   = 0x0E,
	TWIN   = 0x10,
	COVER  = 0x13,
	PEEP   = 0x14,
	DART   = 0x16,
	SNEAK  = 0x17,
	NINJA  = 0x18,
	CHANGE = 0x1A,
	PARRY  = 0x1B,
	SHOW   = 0x1C,
	OFF    = 0x1D,
	NONE   = 0xFF,
}

_M.battle.MENU = {
	NONE              = 0x00,
	COMMAND           = 0x01,
	PARRY             = 0x02,
	CHANGE            = 0x03,
	TARGET_FIGHT      = 0x04,
	ITEM              = 0x05,
	MAGIC             = 0x06,
	TARGET_SKILL      = 0x07,
	CLOSING           = 0x08,
	OPENING_MAGIC     = 0x09,
	CLOSING_MAGIC     = 0x0A,
	EQUIP             = 0x0B,
	TARGET_ITEM_MAGIC = 0x0C,
	CLOSING_ITEM      = 0x0F,
}

_M.battle.TARGET = {
	ENEMY     = 0x00,
	PARTY     = 0x08,
	PARTY_ALL = 0x0D,
	NONE      = 0x0F,
	CHARACTER = 0xFE,
	ENEMY_ALL = 0xFF,
}

_M.field.CHOICE = {
	ITEM    = 0x00,
	MAGIC   = 0x01,
	EQUIP   = 0x02,
	STATUS  = 0x03,
	FORM    = 0x04,
	CHANGE  = 0x05,
	CUSTOM  = 0x06,
	SAVE    = 0x07,
}

_M.field.custom.CHOICE = {
	SPEED   = 0x00,
	MESSAGE = 0x01,
	SOUND   = 0x02,
	R       = 0x03,
	G       = 0x04,
	B       = 0x05,
}

_M.shop.CHOICE = {
	BUY  = 0x00,
	SELL = 0x01,
	EXIT = 0x02,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _state

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _is_cursor_visible()
	return memory.read("menu", "cursor_state") == 10
end

local function _is_subcursor_visible()
	return memory.read("menu", "subcursor_state") == 10
end

local function _is_cursor3_visible()
	return memory.read("menu", "cursor3_state") == 10
end

local function _get_battle_magic_index(slot, spell)
	for i = 0, 71 do
		if memory.read("battle_menu", "spell_id", slot, i) == spell then
			return i % 24
		end
	end

	return 0
end

local function _get_field_magic_index(spell)
	for i = 0, 2 do
		local list = memory.read("menu_magic", "list", i)

		if list ~= 0xFF then
			for j = 0, 23 do
				if memory.read("menu_magic", "spell", list, j) == spell then
					return i, j
				end
			end
		end
	end

	return nil, nil
end

local function _select_single_column(current, target, midpoint, buttons)
	if target < current then
		if current - target <= midpoint then
			input.press({buttons[1]}, input.DELAY.MASH)
		else
			input.press({buttons[2]}, input.DELAY.MASH)
		end
	elseif target > current then
		if target - current <= midpoint then
			input.press({buttons[2]}, input.DELAY.MASH)
		else
			input.press({buttons[1]}, input.DELAY.MASH)
		end
	end
end

local function _select_horizontal(current, target, midpoint)
	_select_single_column(current, target, midpoint, {"P1 Left", "P1 Right"})
end

local function _select_vertical(current, target, midpoint)
	_select_single_column(current, target, midpoint, {"P1 Up", "P1 Down"})
end

local function _select_multi_column(current, target, columns)
	if target < current then
		if (current - target) % columns ~= 0 then
			input.press({"P1 Left"}, input.DELAY.MASH)
		else
			input.press({"P1 Up"}, input.DELAY.MASH)
		end
	elseif target > current then
		if (target - current) % columns ~= 0 then
			input.press({"P1 Right"}, input.DELAY.MASH)
		else
			input.press({"P1 Down"}, input.DELAY.MASH)
		end
	end
end

local function _select_magic(current, target)
	local dx = (target - current) % 3
	local dy = math.floor(target / 3) - math.floor(current / 3)

	if dx > 1 or dx < -1 then
		dx = dx * -1
	end

	if dy > 4 or dy < -4 then
		dy = dy * -1
	end

	if dx > 0 then
		input.press({"P1 Right"}, input.DELAY.MASH)
	elseif dx < 0 then
		input.press({"P1 Left"}, input.DELAY.MASH)
	elseif dy > 0 then
		input.press({"P1 Down"}, input.DELAY.MASH)
	elseif dy < 0 then
		input.press({"P1 Up"}, input.DELAY.MASH)
	end
end

--------------------------------------------------------------------------------
-- Field Menu State Functions
--------------------------------------------------------------------------------

function _M.field.is_open()
	return memory.read("menu", "state") == 170 and not dialog.is_dialog()
end

function _M.field.custom.is_open()
	return memory.read("menu_custom", "state") > 0
end

function _M.field.equip.is_open()
	return memory.read("menu_equip", "state") > 0
end

function _M.field.equip.is_selecting_character()
	return memory.read("menu_equip", "phase") == 0
end

function _M.field.form.is_open()
	return memory.read("menu_form", "state") > 0
end

function _M.field.form.is_selected()
	return memory.read("menu_form", "selected") == 0
end

function _M.field.item.is_open()
	return memory.read("menu_item", "state") > 0
end

function _M.field.magic.is_open()
	return memory.read("menu", "selected") == _M.field.CHOICE.MAGIC and memory.read("menu", "submenu_open") == 118
end

function _M.field.magic.is_not_closed()
	return memory.read("menu_magic", "unknown") > 0
end

function _M.field.magic.is_selecting_character()
	return memory.read("menu_magic", "state") == 0
end

function _M.field.save.is_open()
	return memory.read("menu_save", "state") > 0
end

--------------------------------------------------------------------------------
-- Field Menu Internal Functions
--------------------------------------------------------------------------------

function _M.field.open_submenu(menu, is_open)
	if is_open then
		return true
	else
		_M.field.select(menu)
	end

	return false
end

function _M.field.open_submenu_with_character(menu, character, is_open, is_selecting_character)
	if is_open then
		if is_selecting_character then
			local cursor = memory.read("menu", "character")
			local index = game.character.get_index(game.character.get_slot(character))

			if cursor == index then
				input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				_select_vertical(cursor, index, 2)
			end
		else
			_state.frame = nil
			return true
		end
	elseif not _state.frame or emu.framecount() - _state.frame > 15 then
		_M.field.select(menu)
		_state.frame = emu.framecount()
	end

	return false
end

function _M.field.close_submenu(is_open)
	if not is_open then
		return true
	else
		input.press({"P1 B"}, input.DELAY.NORMAL)
	end

	return false
end

function _M.field.select(choice)
	local cursor = _M.field.get_cursor()

	if cursor then
		if cursor == choice then
			return input.press({"P1 A"})
		else
			_select_vertical(cursor, choice, 4)
		end
	end

	return false
end

function _M.field.get_cursor()
	if _is_cursor_visible() then
		return memory.read("menu", "cursor")
	else
		return nil
	end
end

function _M.field.item.get_cursor()
	if _is_cursor_visible() then
		return (memory.read("menu_item", "cursor_y") + memory.read("menu_item", "scroll")) * 2 + memory.read("menu_item", "cursor_x")
	else
		return nil
	end
end

--------------------------------------------------------------------------------
-- Field Menu External Functions
--------------------------------------------------------------------------------

function _M.field.open(delay)
	if _M.field.is_open() then
		return true
	else
		if not delay then
			delay = input.DELAY.MASH
		end

		input.press({"P1 X"}, delay)
	end

	return false
end

function _M.field.close()
	if not _M.field.is_open() then
		return true
	else
		input.press({"P1 B"}, input.DELAY.MASH)
	end

	return false
end

function _M.field.change()
	if not _state.formation then
		_state.formation = memory.read("party", "formation")
	end

	if memory.read("party", "formation") ~= _state.formation then
		_state.formation = nil
		return true
	else
		_M.field.select(_M.field.CHOICE.CHANGE)
	end

	return false
end

function _M.field.custom.open()
	return _M.field.open_submenu(_M.field.CHOICE.CUSTOM, _M.field.custom.is_open())
end

function _M.field.custom.close()
	return _M.field.close_submenu(_M.field.custom.is_open())
end

function _M.field.custom.select(target)
	local cursor = memory.read("menu_custom", "cursor")

	if _is_subcursor_visible() then
		if cursor == target then
			return true
		else
			_select_vertical(cursor, target, 4)
		end
	end

	return false
end

function _M.field.equip.open(character)
	return _M.field.open_submenu_with_character(_M.field.CHOICE.EQUIP, character, _M.field.equip.is_open(), _M.field.equip.is_selecting_character())
end

function _M.field.equip.close()
	return _M.field.close_submenu(_M.field.equip.is_open())
end

function _M.field.equip.equip(location, item)
	if _is_cursor_visible() and game.character.get_equipment(memory.read("menu_equip", "slot"), location) == item then
		_state.frame = nil
		return true
	elseif _state.frame and _is_subcursor_visible() then
		local cursor = memory.read("menu_equip", "cursor")
		local subcursor = (memory.read("menu_equip", "subcursor_y", cursor) + memory.read("menu_equip", "scroll", cursor)) * 2 + memory.read("menu_equip", "subcursor_x", cursor)
		local index = game.item.get_index(item, 0)

		if subcursor == index then
			input.press({"P1 A"}, input.DELAY.NORMAL)
			_state.frame = emu.framecount()
		else
			_select_multi_column(subcursor, index, 2)
		end
	elseif not _state.frame or emu.framecount() - _state.frame > 15 then
		local cursor = memory.read("menu_equip", "cursor")

		if cursor == location then
			input.press({"P1 A"}, input.DELAY.NORMAL)
			_state.frame = emu.framecount()
		else
			_select_vertical(cursor, location, 2)
		end
	end

	return false
end

function _M.field.form.move(character, index, formation)
	local cursor = memory.read("menu", "character")

	if _M.field.form.is_open() then
		if formation and formation ~= memory.read("party", "formation") then
			input.press({"P1 Left"}, input.DELAY.NORMAL)
		elseif _M.field.form.is_selected() then
			if cursor == index then
				return input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				_select_vertical(cursor, index, 2)
			end
		else
			local index = game.character.get_index(game.character.get_slot(character))

			if cursor == index then
				input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				_select_vertical(cursor, index, 2)
			end
		end
	elseif not _state.frame or emu.framecount() - _state.frame > 15 then
		_M.field.select(_M.field.CHOICE.FORM)
		_state.frame = emu.framecount()
	end

	return false
end

function _M.field.form.swap(character1, character2, change)
	return _M.field.form.move(character1, game.character.get_index(game.character.get_slot(character2)), change)
end

function _M.field.item.open()
	return _M.field.open_submenu(_M.field.CHOICE.ITEM, _M.field.item.is_open())
end

function _M.field.item.close()
	return _M.field.close_submenu(_M.field.item.is_open())
end

function _M.field.item.select(item, index)
	local cursor = _M.field.item.get_cursor()

	if item then
		index = game.item.get_index(item, index)
	end

	if cursor then
		if cursor == index then
			if memory.read("menu_item", "selectable") == 159 then
				return input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				return false
			end
		else
			_select_multi_column(cursor, index, 2)
		end
	end

	return false
end

function _M.field.item.select_character(character)
	if memory.read("menu_item", "selected") == 0 then
		return input.press({"P1 A"}, input.DELAY.NORMAL)
	else
		local cursor = memory.read("menu_item", "character")
		local index = game.character.get_index(game.character.get_slot(character))

		if cursor == index then
			input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			_select_vertical(cursor, index, 2)
		end
	end

	return false
end

function _M.field.magic.open(character)
	return _M.field.open_submenu_with_character(_M.field.CHOICE.MAGIC, character, _M.field.magic.is_open(), _M.field.magic.is_selecting_character())
end

function _M.field.magic.close()
	return _M.field.close_submenu(_M.field.magic.is_not_closed())
end

function _M.field.magic.select(spell, extra_button)
	local list, index = _get_field_magic_index(spell)

	if not list then
		return true
	elseif memory.read("menu_magic", "selecting") > 0 then
		local cursor = memory.read("menu_magic", "subcursor")

		if cursor == index then
			return input.press({"P1 A", extra_button}, input.DELAY.NORMAL)
		else
			_select_magic(cursor, index)
		end
	else
		local cursor = memory.read("menu_magic", "cursor")

		if cursor == list then
			input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			_select_vertical(cursor, list, 1)
		end
	end

	return false
end

function _M.field.magic.select_character(character, all)
	if not _is_cursor_visible() then
		if _state.cast_frame then
			if input.press({"P1 A"}, input.DELAY.NORMAL) then
				_state.cast_frame = nil
				return true
			end
		elseif all then
			input.press({"P1 A"}, input.DELAY.NORMAL)
			_state.cast_frame = emu.framecount()
		else
			return false
		end
	elseif not _state.cast_frame or emu.framecount() - _state.cast_frame > 30 then
		if all then
			input.press({"P1 Left"}, input.DELAY.NORMAL)
		else
			local cursor = memory.read("menu_magic", "character")
			local index = game.character.get_index(game.character.get_slot(character))

			if cursor == index then
				if input.press({"P1 A"}, input.DELAY.NORMAL) then
					_state.cast_frame = emu.framecount()
				end
			else
				_select_vertical(cursor, index, 2)
			end
		end
	end

	return false
end

function _M.field.save.open()
	return _M.field.open_submenu(_M.field.CHOICE.SAVE, _M.field.save.is_open())
end

function _M.field.save.save(slot)
	if _M.field.save.is_open() then
		if _is_cursor_visible() then
			return input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			local cursor = memory.read("menu_save", "cursor")

			if cursor == slot then
				input.press({"P1 A"}, input.DELAY.NORMAL)
			else
				_select_vertical(cursor, slot, 2)
			end
		end
	else
		_M.field.select(_M.field.CHOICE.SAVE)
	end

	return false
end

--------------------------------------------------------------------------------
-- Shop Menu State Functions
--------------------------------------------------------------------------------

function _M.shop.is_open()
	return memory.read("menu", "state") > 0
end

--------------------------------------------------------------------------------
-- Shop Menu Internal Functions
--------------------------------------------------------------------------------

function _M.shop.is_buy()
	return memory.read("menu_shop", "buy_state") >= 128
end

function _M.shop.is_sell()
	return memory.read("menu_shop", "sell_state") >= 128
end

--------------------------------------------------------------------------------
-- Shop Menu Internal Functions
--------------------------------------------------------------------------------

function _M.shop.shop(target, target_quantity)
	if _is_cursor_visible() or _is_subcursor_visible() then
		if _M.shop.is_buy() or _M.shop.is_sell() then
			local cursor = memory.read("menu_shop", "subcursor")

			if target_quantity == 1 then
				if cursor == 0 then
					return input.press({"P1 A"}, input.DELAY.NORMAL)
				else
					_select_horizontal(cursor, 0, 1)
				end
			else
				if cursor == 1 then
					local current_quantity = memory.read("menu_shop", "quantity")

					if current_quantity == target_quantity then
						return input.press({"P1 A"}, input.DELAY.NORMAL)
					else
						local delta = math.abs(current_quantity - target_quantity)

						if delta > 5 then
							input.press({"P1 X"}, input.DELAY.NORMAL)
						else
							if current_quantity < target_quantity then
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
		else
			local cursor = memory.read("menu_shop", "cursor")

			if cursor == target then
				input.press({"P1 A"})
			else
				_select_horizontal(cursor, target, 1)
			end
		end
	end

	return false
end

--------------------------------------------------------------------------------
-- Shop Menu External Functions
--------------------------------------------------------------------------------

function _M.shop.close()
	if not _M.shop.is_open() then
		return true
	else
		input.press({"P1 B"}, input.DELAY.MASH)
	end

	return false
end

function _M.shop.switch_quantity()
	local cursor = memory.read("menu_shop", "subcursor")

	if not _state.cursor then
		_state.cursor = cursor
	end

	if cursor ~= _state.cursor then
		_state.cursor = nil
		return true
	elseif cursor == 0 then
		input.press({"P1 Right"})
	else
		input.press({"P1 Left"})
	end
end

function _M.shop.buy.open(quantity)
	return _M.shop.shop(_M.shop.CHOICE.BUY, quantity)
end

function _M.shop.buy.close()
	if not _M.shop.is_buy() then
		return true
	else
		input.press({"P1 B"}, input.DELAY.MASH)
	end

	return false
end

function _M.shop.buy.buy(item)
	local cursor = memory.read("menu_shop", "buy")
	local index, entries

	for i = 0, 7 do
		local value = memory.read("menu_shop", "buy_item", i)

		if value == item then
			index = i
		elseif value == game.ITEM.NONE then
			entries = i
			break
		end
	end

	if not _state.gp then
		_state.gp = memory.read("party", "gp")
	end

	if _is_cursor3_visible() then
		input.press({"P1 A"}, input.DELAY.NORMAL)
	elseif memory.read("party", "gp") < _state.gp then
		_state.gp = nil
		return true
	elseif cursor == index then
		input.press({"P1 A"}, input.DELAY.NORMAL)
	else
		_select_vertical(cursor, index, math.floor(entries / 2))
	end

	return false
end

function _M.shop.sell.open(quantity)
	return _M.shop.shop(_M.shop.CHOICE.SELL, quantity)
end

function _M.shop.sell.close()
	if not _M.shop.is_sell() then
		return true
	else
		input.press({"P1 B"}, input.DELAY.MASH)
	end

	return false
end

function _M.shop.sell.sell(item)
	local cursor = (memory.read("menu_shop", "sell_y") + memory.read("menu_shop", "sell_scroll")) * 2 + memory.read("menu_shop", "sell_x")
	local index = game.item.get_index(item, 0)

	if not index then
		return true
	elseif _is_cursor3_visible() then
		input.press({"P1 A"}, input.DELAY.NORMAL)
	elseif cursor == index then
		input.press({"P1 A"}, input.DELAY.NORMAL)
	else
		_select_multi_column(cursor, index, 2)
	end

	return false
end

--------------------------------------------------------------------------------
-- Battle Menu State Functions
--------------------------------------------------------------------------------

function _M.battle.is_open()
	return memory.read("battle_menu", "open") > 0 and memory.read("battle_menu", "opening") ~= 1 and memory.read("battle_menu", "menu") ~= _M.battle.MENU.NONE
end

function _M.battle.is_target()
	local menu = memory.read("battle_menu", "menu")
	return menu == _M.battle.MENU.TARGET_FIGHT or menu == _M.battle.MENU.TARGET_SKILL or menu == _M.battle.MENU.TARGET_ITEM_MAGIC
end

function _M.battle.command.get_cursor()
	local menu = memory.read("battle_menu", "menu")

	if menu == _M.battle.MENU.CHANGE then
		return 5
	elseif menu == _M.battle.MENU.PARRY then
		return 6
	else
		return memory.read("battle_menu", "cursor")
	end
end

function _M.battle.command.is_open()
	local menu = memory.read("battle_menu", "menu")
	return menu == _M.battle.MENU.COMMAND or menu == _M.battle.MENU.CHANGE or menu == _M.battle.MENU.PARRY
end

function _M.battle.magic.is_open()
	local menu = memory.read("battle_menu", "menu")
	return menu == _M.battle.MENU.MAGIC or menu == _M.battle.MENU.OPENING_MAGIC or menu == _M.battle.MENU.CLOSING_MAGIC
end

--------------------------------------------------------------------------------
-- Battle Menu Internal Functions
--------------------------------------------------------------------------------

function _M.battle.is_target_valid(index)
	return memory.read("battle_menu", "target_valid", index) ~= 0xFF
end

function _M.battle.get_default_target(direction, index)
	if direction == walk.DIRECTION.UP then
		return memory.read("battle_menu", "target_default_up", index)
	elseif direction == walk.DIRECTION.DOWN then
		return memory.read("battle_menu", "target_default_down", index)
	else
		return nil
	end
end

function _M.battle.get_next_target(index, direction)
	if direction == walk.DIRECTION.UP then
		return math.floor(memory.read("battle_menu", "target_up_down", index) / 16)
	elseif direction == walk.DIRECTION.DOWN then
		return memory.read("battle_menu", "target_up_down", index) % 16
	elseif direction == walk.DIRECTION.LEFT then
		return math.floor(memory.read("battle_menu", "target_left_right", index) / 16)
	elseif direction == walk.DIRECTION.RIGHT then
		return memory.read("battle_menu", "target_left_right", index) % 16
	end
end

function _M.battle.get_target(index, direction)
	index = _M.battle.get_next_target(index, direction)

	while index ~= _M.battle.TARGET.NONE and not _M.battle.is_target_valid(index) do
		index = _M.battle.get_next_target(index, direction)
	end

	if index == _M.battle.TARGET.NONE then
		if direction == walk.DIRECTION.LEFT or direction == walk.DIRECTION.RIGHT then
			index = nil
		else
			for i = 0, 7 do
				index = _M.battle.get_default_target(direction, i)

				if _M.battle.is_target_valid(index) then
					break
				elseif i == 7 then
					index = nil
				end
			end
		end
	end

	return index
end

function _M.battle.get_target_direction(cursor, index)
	local q = {cursor}
	local parents = {}

	while #q > 0 and not parents[index] do
		local node = table.remove(q, 1)

		for _, direction in pairs(walk.DIRECTION) do
			local next = _M.battle.get_target(node, direction)

			if next and not parents[next] then
				parents[next] = {node, direction}
			end

			q[#q + 1] = next
		end
	end

	if not parents[index] then
		return nil
	end

	local direction

	while index ~= cursor do
		index, direction = unpack(parents[index])
	end

	return direction
end

--------------------------------------------------------------------------------
-- Battle Menu External Functions
--------------------------------------------------------------------------------

function _M.battle.target(target, index, wait, delay)
	if _M.battle.is_open() and _M.battle.is_target() then
		local cursor = memory.read("battle_menu", "target")

		local left = {"P1 Left"}
		local right = {"P1 Right"}

		if game.battle.get_type() == game.battle.TYPE.BACK_ATTACK then
			left = {"P1 Right"}
			right = {"P1 Left"}
		end

		if not delay then
			delay = input.DELAY.MASH
		end

		if wait and not _M.battle.is_target_valid(index) then
			return false
		end

		if target == _M.battle.TARGET.CHARACTER then
			index = game.character.get_slot(index) + _M.battle.TARGET.PARTY
		elseif target == _M.battle.TARGET.PARTY then
			index = index + _M.battle.TARGET.PARTY
		elseif target == _M.battle.TARGET.ENEMY then
			if not index or not _M.battle.is_target_valid(index) then
				for i = 0, 7 do
					if _M.battle.is_target_valid(i) then
						index = i
						break
					end
				end
			end
		elseif target == _M.battle.TARGET.ENEMY_ALL or target == _M.battle.TARGET.PARTY_ALL then
			index = target
		end

		if not index or cursor == index then
			input.press({"P1 A"}, delay)

			_state.pressed = true
		else
			if index == _M.battle.TARGET.PARTY_ALL or (cursor < _M.battle.TARGET.PARTY and index >= _M.battle.TARGET.PARTY and index < _M.battle.TARGET.PARTY_ALL) then
				input.press(right, delay)
			elseif index == _M.battle.TARGET.ENEMY_ALL or (cursor >= _M.battle.TARGET.PARTY and index < _M.battle.TARGET.PARTY) then
				input.press(left, delay)
			else
				if index >= _M.battle.TARGET.PARTY then
					local index_map = {
						[8] = 2,
						[9] = 0,
						[10] = 4,
						[11] = 1,
						[12] = 3,
					}

					_select_vertical(index_map[cursor], index_map[index], 2)
				else
					local direction = _M.battle.get_target_direction(cursor, index)

					if direction == walk.DIRECTION.UP then
						input.press({"P1 Up"}, delay)
					elseif direction == walk.DIRECTION.LEFT then
						input.press(left, delay)
					elseif direction == walk.DIRECTION.DOWN then
						input.press({"P1 Down"}, delay)
					elseif direction == walk.DIRECTION.RIGHT then
						input.press(right, delay)
					end
				end
			end
		end
	elseif _state.pressed then
		_state.pressed = nil
		return true
	end

	return false
end

function _M.battle.command.has_command(target_command)
	local slot = memory.read("battle_menu", "slot")

	for i = 0, 6 do
		local command = memory.read("battle_menu", "command", slot, i)

		if command == target_command then
			return true
		end
	end

	return false
end

function _M.battle.command.select(target_command, delay)
	if _M.battle.is_open() then
		if not delay then
			delay = input.DELAY.MASH
		end

		if not _M.battle.command.is_open() then
			return true
		else
			local slot = memory.read("battle_menu", "slot")
			local cursor = _M.battle.command.get_cursor()

			local index, entries

			for i = 0, 6 do
				local command = memory.read("battle_menu", "command", slot, i)

				if command == target_command then
					index = i
				end

				if i < 5 and command ~= _M.battle.COMMAND.NONE then
					entries = i + 1
				end
			end

			if cursor == index then
				input.press({"P1 A"}, delay)
			elseif index == 5 then
				input.press({"P1 Left"}, delay)
			elseif index == 6 then
				input.press({"P1 Right"}, delay)
			else
				_select_vertical(cursor, index, math.floor(entries / 2), delay)
			end
		end
	end

	return false
end

function _M.battle.equip.select(index, delay)
	local cursor = memory.read("battle_menu", "subcursor")
	local menu = memory.read("battle_menu", "menu")

	if not delay then
		delay = input.DELAY.NORMAL
	end

	if _M.battle.is_open() then
		if _state.item_selected and memory.read("battle_menu", "item_selected") ~= _state.item_selected then
			_state.item_selected = nil
			return true
		elseif menu == _M.battle.MENU.ITEM then
			input.press({"P1 Up"}, delay)
		elseif menu == _M.battle.MENU.EQUIP then
			if cursor == index then
				input.press({"P1 A"}, delay)

				if not _state.item_selected then
					_state.item_selected = memory.read("battle_menu", "item_selected")
				end
			elseif cursor > index then
				input.press({"P1 Left"}, delay)
			else
				input.press({"P1 Right"}, delay)
			end
		end
	end

	return false
end

function _M.battle.item.close()
	if memory.read("battle_menu", "menu") == _M.battle.MENU.COMMAND then
		return true
	else
		input.press({"P1 B"}, input.DELAY.MASH)
	end
end

function _M.battle.item.select(item, index)
	local menu = memory.read("battle_menu", "menu")
	local cursor = memory.read("battle_menu", "subcursor")

	local index = index

	if item then
		index = game.item.get_index(item, index, game.INVENTORY.BATTLE)
	end

	if _M.battle.is_open() then
		if _M.battle.is_target() or (_state.item_selected ~= nil and memory.read("battle_menu", "item_selected") ~= _state.item_selected) then
			_state.item_selected = nil
			return true
		elseif menu == _M.battle.MENU.EQUIP then
			input.press({"P1 Down"}, input.DELAY.NORMAL)
		elseif menu == _M.battle.MENU.ITEM then
			if cursor == index then
				input.press({"P1 A"}, input.DELAY.NORMAL)

				if _state.item_selected == nil then
					_state.item_selected = memory.read("battle_menu", "item_selected")
				end
			else
				_select_multi_column(cursor, index, 2)
			end
		end
	end

	return false
end

function _M.battle.magic.select(spell)
	local menu = memory.read("battle_menu", "menu")
	local cursor = memory.read("battle_menu", "subcursor")
	local index = _get_battle_magic_index(memory.read("battle_menu", "slot"), spell)

	if _M.battle.is_open() then
		if not _M.battle.magic.is_open() then
			return true
		elseif cursor == index then
			input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			_select_multi_column(cursor, index, 3)
		end
	end

	return false
end

function _M.battle.dialog.wait(text, limit)
	if limit and _M.wait(limit) then
		return true
	else
		local result = dialog.get_battle_text(#text) == text or dialog.get_battle_spell() == text

		if result then
			_wait_frame = nil
			return result
		end
	end

	return false
end

function _M.battle.run_buffer()
	if _M.battle.dialog.wait("Ca") then
		return true
	else
		input.press({"P1 L", "P1 R"}, input.DELAY.NONE)
	end

	return false
end

--------------------------------------------------------------------------------
-- Dialog Menu Functions
--------------------------------------------------------------------------------

function _M.dialog.open()
	if memory.read("dialog", "height_lower") == 8 then
		return true
	end

	if walk.is_mid_tile() or not walk.is_ready() then
		return false
	end

	input.press({"P1 A"}, input.DELAY.MASH)

	return false
end


function _M.dialog.select(item)
	local cursor = (memory.read("dialog", "cursor_y") + memory.read("dialog", "cursor_scroll")) * 2 + memory.read("dialog", "cursor_x")
	local index = game.item.get_index(item, 0, game.INVENTORY.DIALOG)

	if memory.read("dialog", "height_lower") == 8 and memory.read("dialog", "cursor_wait") == 0 then
		if cursor == index then
			return input.press({"P1 A"}, input.DELAY.NORMAL)
		else
			_select_multi_column(cursor, index, 2)
		end
	end

	return false
end

--------------------------------------------------------------------------------
-- Global Menu Functions
--------------------------------------------------------------------------------

function _M.confirm()
	if _is_cursor_visible() then
		return input.press({"P1 A"}, input.DELAY.MASH)
	end

	return false
end

function _M.wait(frames)
	if input.is_clear() then
		if _wait_frame then
			if emu.framecount() >= _wait_frame then
				_wait_frame = nil
				return true
			end
		else
			_wait_frame = emu.framecount() + frames
		end
	end

	return false
end

function _M.wait_clear()
	_wait_frame = nil
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.reset()
	_state = {
		flag = nil,
		wait_frame = nil,
	}
end

return _M
