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

local bridge = require "util.bridge"
local dialog = require "util.dialog"
local game = require "util.game"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"
local route = require "util.route"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_RESTORE = {
	LIFE   = 0x1,
	HP     = 0x3,
	MP     = 0x5,
	ALL    = 0x7,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_M.state = {
	multi_change = false,
}

local _q = nil
local _route = {}
local _state = {}

for i = 0, 56 do
	_route[i] = 0
end

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _count_entries(table)
	local count = 0

	for key, value in pairs(table) do
		count = count + 1
	end

	return count
end

local function _log_prologue()
	if not _state.count then
		_state.count = 0
	end

	if memory.read("walk", "transition") == 127 then
		_state.count = _state.count + 1

		if _state.count == 5 then
			bridge.split("Prologue")
			_state.count = nil
			return true
		end
	end

	return false
end

local function _log_seed()
	local seed = memory.read("walk", "seed")

	if seed >= 74 and seed <= 81 then
		table.insert(_q, 2, {menu.wait, {120}})
		table.insert(_q, 3, {input.press, {{"Reset"}, input.DELAY.NORMAL}})
		table.insert(_q, 4, {menu.wait, {math.random(132, 387)}})
		table.insert(_q, 5, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	end

	_route = route.routes.no64.excalbur[seed]

	for i = 0, 56 do
		if not _route[i] then
			_route[i] = 0
		end
	end

	return log.log(string.format("New Seed: %d", seed))
end

local function _hummingway_start()
	_state.target_index = (memory.read("walk", "index") + 16 + _route[42]) % 256

	return true
end

local function _hummingway_finish()
	local stack = {}
	local index = memory.read("walk", "index")

	while index ~= _state.target_index and index ~= _state.target_index - 1 do
		table.insert(stack, {walk.walk, {357, 11, 16}})
		table.insert(stack, {walk.walk, {357, 10, 16}})
		index = (index + 2) % 256
	end

	_state.target_index = nil

	-- Add the queued commands to the primary command queue.
	while #stack > 0 do
		if immediate then
			table.insert(_q, 1, table.remove(stack))
		else
			table.insert(_q, 2, table.remove(stack))
		end
	end

	return true
end

local function _restore_party(characters, underflow_target, open_menu, immediate)
	if walk.is_mid_tile() or not walk.is_ready() then
		return false
	end

	local stack = {}
	local cure_count = 0
	local max_count = 0
	local life = {}
	local heal = {}
	local target_hp = {}
	local target_mp = {}
	local close_menu = false

	-- Determine which characters need which healing.
	for slot = 0, 4 do
		local character = game.character.get_character(slot)
		local hp = memory.read_stat(slot, "hp")
		local mp = memory.read_stat(slot, "mp")

		if character then
			max_count = max_count + 1

			if characters[character] then
				if bit.band(characters[character], _RESTORE.HP) == _RESTORE.HP then
					cure_count = cure_count + 1
					target_hp[character] = memory.read_stat(slot, "hp_max") - hp

					if target_hp[character] <= 0 then
						target_hp[character] = nil
					end

					if hp == 0 then
						life[character] = true
					end
				elseif bit.band(characters[character], _RESTORE.LIFE) == _RESTORE.LIFE and hp == 0 then
					target_hp[character] = memory.read_stat(slot, "stamina") * 5
					life[character] = true
				end

				if bit.band(characters[character], _RESTORE.MP) == _RESTORE.MP then
					target_mp[character] = memory.read_stat(slot, "mp_max") - mp

					if target_mp[character] <= 0 then
						target_mp[character] = nil
					end
				end

				if game.character.is_status(character, game.STATUS.POISON) then
					heal[character] = true
				end
			end
		end
	end

	-- Open the menu if necessary.
	if open_menu and _count_entries(life) + _count_entries(target_hp) + _count_entries(target_mp) > 0 then
		table.insert(stack, {menu.field.open, {}})
		close_menu = true
	end

	-- Handle the underflow.
	if underflow_target then
		local underflow_target_hp = game.character.get_stat(underflow_target, "hp")
		local underflow_target_mp = game.character.get_stat(underflow_target, "mp")

		if underflow_target_mp < 1000 then
			-- Ensure the underflow target has at least 3 MP.
		 	if underflow_target_hp == 0 or underflow_target_mp < 3 then
				table.insert(stack, {menu.field.item.open, {}})

				if underflow_target_hp == 0 then
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.LIFE}})
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.LIFE}})
					table.insert(stack, {menu.field.item.select_character, {underflow_target}})

					life[underflow_target] = nil

					if target_hp[underflow_target] then
						target_hp[underflow_target] = target_hp[underflow_target] - game.character.get_stat(underflow_target, "stamina") * 5

						if target_hp[underflow_target] <= 0 then
							target_hp[underflow_target] = nil
						end
					end
				end

				if underflow_target_mp < 3 then
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
					table.insert(stack, {menu.field.item.select_character, {underflow_target}})

					underflow_target_mp = math.min(underflow_target_mp + 48, game.character.get_stat(underflow_target, "mp_max"))
				end

				table.insert(stack, {menu.field.item.close, {}})
			end

			table.insert(stack, {menu.field.magic.open, {underflow_target}})

			if underflow_target == game.CHARACTER.FUSOYA or underflow_target == game.CHARACTER.TELLAH then
				for character, hp in pairs(target_hp) do
					if underflow_target_mp > 55 and life[character] and hp > game.character.get_stat(character, "stamina") * 5 then
						table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.LIFE2}})
						table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.LIFE2}})
						table.insert(stack, {menu.field.magic.select_character, {character}})

						life[character] = nil
						target_hp[character] = nil
						underflow_target_mp = underflow_target_mp - 52
					end
				end
			end

			local will = game.character.get_stat(underflow_target, "will")
			local healing = (math.floor(will / 8) + 2) * (math.floor(will / 2) + 288)

			while underflow_target_mp > 0 do
				table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.CURE4}})

				if underflow_target_mp >= 40 then
					table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.CURE4}})
				elseif underflow_target == game.CHARACTER.TELLAH then
					table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.SIGHT, "P1 Up"}})
				elseif underflow_target == game.CHARACTER.FUSOYA then
					table.insert(stack, {menu.field.magic.select, {game.MAGIC.WHITE.CURE1, "P1 Down"}})
				end

				local target = {nil, true}

				if cure_count < max_count then
					local highest = {underflow_target, -1}

					for character, hp in pairs(target_hp) do
						if hp > highest[2] then
							highest = {character, hp}
						end
					end

					target = {highest[1]}
				end

				table.insert(stack, {menu.field.magic.select_character, target})

				if cure_count < max_count then
					if target_hp[target[1]] then
						target_hp[target[1]] = target_hp[target[1]] - healing

						if target_hp[target[1]] and target_hp[target[1]] <= 0 then
							target_hp[target[1]] = nil
						end
					end
				else
					for character, hp in pairs(target_hp) do
						target_hp[character] = target_hp[character] - math.floor(healing / max_count)

						if target_hp[character] <= 0 then
							target_hp[character] = nil
						end
					end
				end

				underflow_target_mp = underflow_target_mp - 40
			end

			table.insert(stack, {menu.field.magic.close, {}})
		end
	end

	-- If anyone still needs any healing, heal with items.
	if _count_entries(life) + _count_entries(target_hp) + _count_entries(target_mp) > 0 then
		table.insert(stack, {menu.field.item.open, {}})

		-- Use Life items on anyone dead.
		for character, hp in pairs(target_hp) do
			if life[character] then
				table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.LIFE}})
				table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.LIFE}})
				table.insert(stack, {menu.field.item.select_character, {character}})

				life[character] = nil
				target_hp[character] = target_hp[character] - game.character.get_stat(character, "stamina") * 5

				if target_hp[character] <= 0 then
					target_hp[character] = nil
				end
			end
		end

		-- Use Heal items on anyone selected for healing.
		for character, hp in pairs(target_hp) do
			if heal[character] then
				table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.HEAL}})
				table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.HEAL}})
				table.insert(stack, {menu.field.item.select_character, {character}})

				heal[character] = nil
			end
		end

		-- Use Elixirs (if available) to restore designated characters.
		if game.item.get_index(game.ITEM.ITEM.ELIXIR, 0, game.INVENTORY.FIELD) then
			for character, hp in pairs(target_hp) do
				if character ~= underflow_target then
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(stack, {menu.field.item.select_character, {character}})

					target_hp[character] = nil
					target_mp[character] = nil
				end
			end
		end

		-- Use Cure2 items on anyone else who needs HP.
		if game.item.get_index(game.ITEM.ITEM.CURE2, 0, game.INVENTORY.FIELD) then
			for character, hp in pairs(target_hp) do
				while target_hp[character] do
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(stack, {menu.field.item.select_character, {character}})

					target_hp[character] = target_hp[character] - 480

					if target_hp[character] <= 0 then
						target_hp[character] = nil
					end
				end
			end
		end

		-- Use Ether1 items on anyone who needs MP.
		if game.item.get_index(game.ITEM.ITEM.ETHER1, 0, game.INVENTORY.FIELD) then
			for character, mp in pairs(target_mp) do
				if character ~= underflow_target then
					while target_mp[character] do
						table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
						table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
						table.insert(stack, {menu.field.item.select_character, {character}})

						target_mp[character] = target_mp[character] - 48

						if target_mp[character] <= 0 then
							target_mp[character] = nil
						end
					end
				end
			end
		end

		table.insert(stack, {menu.field.item.close, {}})
	end

	-- Close the menu if we opened it.
	if close_menu then
		table.insert(stack, {menu.field.close, {}})
	end

	-- Add the queued commands to the primary command queue.
	while #stack > 0 do
		if immediate then
			table.insert(_q, 1, table.remove(stack))
		else
			table.insert(_q, 2, table.remove(stack))
		end
	end

	return true
end

local function _post_grind_menu()
	local stack = {}
	local heal = false
	local duplicate = false

	if game.character.get_stat(game.CHARACTER.EDGE, "hp") < 500 then
		heal = true
	end

	if game.item.get_count(game.ITEM.WEAPON.EXCALBUR) <= 1 then
		duplicate = true
	end

	if heal or duplicate then
		table.insert(stack, {menu.field.open, {}})

		if duplicate then
			table.insert(stack, {menu.field.equip.open, {game.CHARACTER.CECIL}})
			table.insert(stack, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.EXCALBUR}})
			table.insert(stack, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.NONE}})
			table.insert(stack, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.EXCALBUR}})
			table.insert(stack, {menu.field.equip.close, {}})
		end

		table.insert(stack, {menu.field.item.open, {}})

		local empty = 0

		for i = 0, 47 do
			if memory.read("menu_item", "item_id", i) == game.ITEM.NONE then
				empty = empty + 1
			end
		end

		if empty < 3 then
			table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.CURE2}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.TRASHCAN}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.HEAL}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.TRASHCAN}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.WEAPON.DANCING}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.TRASHCAN}})
		end

		if duplicate then
			if memory.read("menu_item", "item_id", 0) ~= game.ITEM.WEAPON.EXCALBUR then
				table.insert(stack, {menu.field.item.select, {game.ITEM.WEAPON.EXCALBUR}})
				table.insert(stack, {menu.field.item.select, {nil, 0}})
			end

			if memory.read("menu_item", "item_id", 1) ~= game.ITEM.ITEM.ELIXIR then
				table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ELIXIR}})
				table.insert(stack, {menu.field.item.select, {nil, 1}})
			end
		end

		if heal then
			table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ELIXIR}})
			table.insert(stack, {menu.field.item.select, {game.ITEM.ITEM.ELIXIR}})
			table.insert(stack, {menu.field.item.select_character, {game.CHARACTER.EDGE}})
		end

		table.insert(stack, {menu.field.item.close, {}})
		table.insert(stack, {menu.field.close, {}})
	end

	-- Add the queued commands to the primary command queue.
	while #stack > 0 do
		table.insert(_q, 1, table.remove(stack))
	end
end

local function _state_set(key, value)
	_state[key] = value

	return true
end

local function _set_healing(f)
	_state.check_healing = true
	return _state_set("healing", f)
end

local function _set_initial_seed()
	local seed = memory.read("game", "counter")

	if seed == 59 then
		log.log("Setting Initial Seed to 92")
		log.start()
		return input.press({"P1 A"}, input.DELAY.NONE)
	end

	return false
end

--------------------------------------------------------------------------------
-- Healing Strategies
--------------------------------------------------------------------------------

local function _healing_baigan()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp")

	if cecil_hp == 0 or cecil_hp + tellah_hp < 400 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.TELLAH] = _RESTORE.HP,
		}, game.CHARACTER.TELLAH, true, true)
	end

	return true
end

local function _healing_calbrena()
	for i = 0, 4 do
		local hp = memory.read_stat(i, "hp")

		if game.character.get_character(i) ~= game.CHARACTER.CID and memory.read_stat(i, "hp") < memory.read_stat(i, "hp_max") * 0.8 then
			_restore_party({
				[game.CHARACTER.CECIL] = _RESTORE.HP,
				[game.CHARACTER.KAIN] = _RESTORE.HP,
				[game.CHARACTER.ROSA] = _RESTORE.HP,
				[game.CHARACTER.YANG] = _RESTORE.HP,
			}, nil, true, true)

			return true
		end
	end

	return true
end

local function _healing_dark_elf()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local cid_hp = game.character.get_stat(game.CHARACTER.CID, "hp")
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp")

	if cid_hp < 300 or cecil_hp + yang_hp + cid_hp < 1000 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.CID] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_dr_lugae()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp")

	if cecil_hp == 0 or cecil_hp + yang_hp < 800 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.KAIN] = _RESTORE.HP,
			[game.CHARACTER.ROSA] = _RESTORE.HP,
			[game.CHARACTER.RYDIA] = _RESTORE.ALL,
			[game.CHARACTER.YANG] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_edge()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp")

	if cecil_hp == 0 or cecil_hp + kain_hp < 800 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.KAIN] = _RESTORE.HP,
			[game.CHARACTER.ROSA] = _RESTORE.HP,
			[game.CHARACTER.RYDIA] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_flamedog()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp")

	if cecil_hp == 0 or cecil_hp + yang_hp < 800 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.TELLAH] = _RESTORE.HP,
		}, game.CHARACTER.TELLAH, true, true)
	end

	return true
end

local function _healing_fusoya()
	for i = 0, 4 do
		local character = game.character.get_character(i)
		local hp = memory.read_stat(i, "hp")

		if character and hp < memory.read_stat(i, "hp_max") * 0.8 then
			_restore_party({
				[game.CHARACTER.CECIL] = _RESTORE.HP,
				[game.CHARACTER.EDGE] = _RESTORE.HP,
				[game.CHARACTER.ROSA] = _RESTORE.HP,
				[game.CHARACTER.YANG] = _RESTORE.HP,
			}, nil, true, true)

			return true
		end
	end

	return true
end

local function _healing_grind_start_1()
	for i = 0, 4 do
		local hp = memory.read_stat(i, "hp")

		if hp < memory.read_stat(i, "hp_max") * 0.5 then
			_restore_party({
				[game.CHARACTER.CECIL] = _RESTORE.HP,
				[game.CHARACTER.EDGE] = _RESTORE.ALL,
				[game.CHARACTER.FUSOYA] = _RESTORE.HP,
				[game.CHARACTER.ROSA] = _RESTORE.HP,
				[game.CHARACTER.YANG] = _RESTORE.HP,
			}, game.CHARACTER.FUSOYA, true, true)

			return true
		end
	end

	return true
end

local function _healing_grind_start_2()
	if game.character.get_stat(game.CHARACTER.EDGE, "level") >= 45 then
		_post_grind_menu()
	else
		for i = 0, 4 do
			local hp = memory.read_stat(i, "hp")

			if hp < memory.read_stat(i, "hp_max") * 0.9 then
				_restore_party({
					[game.CHARACTER.CECIL] = _RESTORE.HP,
					[game.CHARACTER.EDGE] = _RESTORE.ALL,
					[game.CHARACTER.FUSOYA] = _RESTORE.HP,
					[game.CHARACTER.ROSA] = _RESTORE.HP,
					[game.CHARACTER.RYDIA] = _RESTORE.HP,
				}, game.CHARACTER.FUSOYA, true, true)

				return true
			end
		end
	end

	return true
end

local function _healing_karate()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp")

	if cecil_hp < 500 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.PALOM] = _RESTORE.HP,
			[game.CHARACTER.POROM] = _RESTORE.HP,
			[game.CHARACTER.TELLAH] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_milon_1()
	if game.character.get_stat(game.CHARACTER.CECIL, "hp") < 150 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.PALOM] = _RESTORE.ALL,
			[game.CHARACTER.POROM] = _RESTORE.LIFE,
		}, nil, true, true)
	end

	return true
end

local function _healing_milon_2()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp")

	if cecil_hp == 0 or cecil_hp + tellah_hp < 300 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.PALOM] = _RESTORE.ALL,
			[game.CHARACTER.POROM] = _RESTORE.LIFE,
			[game.CHARACTER.TELLAH] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_monsters()
	for i = 0, 4 do
		local hp = memory.read_stat(i, "hp")

		if hp == 0 then
			_restore_party({
				[game.CHARACTER.CECIL] = _RESTORE.LIFE,
				[game.CHARACTER.EDGE] = _RESTORE.HP,
				[game.CHARACTER.KAIN] = _RESTORE.LIFE,
				[game.CHARACTER.ROSA] = _RESTORE.LIFE,
				[game.CHARACTER.RYDIA] = _RESTORE.LIFE,
			}, nil, true, true)

			return true
		end
	end

	return true
end

local function _healing_rubicant()
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp")
	local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp")

	if edge_hp == 0 or cecil_hp < 400 then
		_restore_party({
			[game.CHARACTER.CECIL] = _RESTORE.HP,
			[game.CHARACTER.EDGE] = _RESTORE.HP,
			[game.CHARACTER.KAIN] = _RESTORE.HP,
			[game.CHARACTER.ROSA] = _RESTORE.HP,
			[game.CHARACTER.RYDIA] = _RESTORE.HP,
		}, nil, true, true)
	end

	return true
end

local function _healing_subterrane()
	for i = 0, 4 do
		local character = game.character.get_character(i)
		local hp = memory.read_stat(i, "hp")

		if character == game.CHARACTER.EDGE and hp < 2000 or hp == 0 then
			_restore_party({
				[game.CHARACTER.CECIL] = _RESTORE.HP,
				[game.CHARACTER.EDGE] = _RESTORE.HP,
				[game.CHARACTER.KAIN] = _RESTORE.HP,
				[game.CHARACTER.ROSA] = _RESTORE.HP,
				[game.CHARACTER.RYDIA] = _RESTORE.HP,
			}, nil, true, true)

			return true
		end
	end

	return true
end

--------------------------------------------------------------------------------
-- Sequences
--------------------------------------------------------------------------------

local function _sequence_new_game()
	table.insert(_q, {_set_initial_seed, {}})
	table.insert(_q, {bridge.split, {"Start"}})
end

local function _sequence_prologue()
	-- Change Battle Speed/Battle Message
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.custom.open, {}})
	table.insert(_q, {menu.field.custom.select, {menu.field.custom.CHOICE.SPEED}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.field.custom.select, {menu.field.custom.CHOICE.MESSAGE}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {input.press, {{"P1 Left"}, input.DELAY.MASH}})
	table.insert(_q, {menu.field.custom.close, {}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to and pick up tent
	table.insert(_q, {walk.walk, {43, 14, 9}})
	table.insert(_q, {walk.walk, {42, 8, 10}})
	table.insert(_q, {walk.walk, {42, 14, 10}})
	table.insert(_q, {walk.walk, {42, 14, 8}})
	table.insert(_q, {walk.walk, {42, 13, 8}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {42, 14, 8}})
	table.insert(_q, {walk.walk, {42, 14, 4}})
	table.insert(_q, {walk.walk, {42, 15, 4}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to Cecil's room
	table.insert(_q, {walk.walk, {42, 14, 4}})
	table.insert(_q, {walk.walk, {42, 14, 10}})
	table.insert(_q, {walk.walk, {42, 1, 10}})
	table.insert(_q, {walk.walk, {42, 1, 5}})
	table.insert(_q, {walk.walk, {36, 8, 13}})
	table.insert(_q, {walk.walk, {45, 2, 12}})
	table.insert(_q, {walk.walk, {36, 6, 18}})
	table.insert(_q, {walk.walk, {36, 6, 9}})
	table.insert(_q, {walk.walk, {50, 5, 4}})
	table.insert(_q, {walk.walk, {51, 6, 4}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {51, 9, 4}})
	table.insert(_q, {walk.walk, {52, 7, 4}})
	table.insert(_q, {walk.walk, {52, 7, 5}})
	table.insert(_q, {walk.walk, {52, 7, 4}})
	table.insert(_q, {walk.walk, {52, 3, 4}})
	table.insert(_q, {_log_prologue, {}})
end

local function _sequence_d_mist()
	-- Walk to Chocobo's Forest and get chocobo
	table.insert(_q, {walk.walk, {nil, 102, 160}})
	table.insert(_q, {walk.walk, {nil, 89, 160}})
	table.insert(_q, {walk.walk, {nil, 89, 163}})
	table.insert(_q, {walk.walk, {210, 8, 8}})
	table.insert(_q, {walk.walk, {210, 9, 8}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {"Found"}})
	table.insert(_q, {walk.step, {walk.DIRECTION.RIGHT}})
	table.insert(_q, {walk.chase, {210, {6, 7, 8}}})

	-- Walk to the Misty Cave
	table.insert(_q, {walk.walk, {nil, 89, 147}})
	table.insert(_q, {walk.walk, {nil, 77, 147}})
	table.insert(_q, {walk.walk, {nil, 77, 145}})
	table.insert(_q, {walk.walk, {nil, 72, 145}})
	table.insert(_q, {walk.walk, {nil, 72, 137}})
	table.insert(_q, {walk.walk, {nil, 75, 137}})
	table.insert(_q, {walk.walk, {nil, 75, 133}})
	table.insert(_q, {walk.walk, {nil, 76, 133}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {walk.walk, {nil, 76, 132}})

	-- Walk through the Misty Cave
	table.insert(_q, {walk.walk, {108, 2, 27}})
	table.insert(_q, {walk.walk, {108, 11, 27}})
	table.insert(_q, {walk.walk, {108, 11, 28}})
	table.insert(_q, {walk.walk, {108, 12, 28}})
	table.insert(_q, {walk.walk, {108, 12, 29}})
	table.insert(_q, {walk.walk, {108, 13, 29}})
	table.insert(_q, {walk.walk, {108, 13, 30}})
	table.insert(_q, {walk.walk, {108, 20, 30}})
	table.insert(_q, {walk.walk, {108, 20, 25}})
	table.insert(_q, {walk.walk, {108, 13, 25}})
	table.insert(_q, {walk.walk, {108, 13, 21}})
	table.insert(_q, {walk.walk, {108, 6, 21}})
	table.insert(_q, {walk.walk, {108, 6, 18}})
	table.insert(_q, {walk.walk, {108, 4, 18}})
	table.insert(_q, {walk.walk, {108, 4, 7}})
	table.insert(_q, {walk.walk, {108, 16, 7}})
	table.insert(_q, {walk.walk, {108, 16, 11}})
	table.insert(_q, {walk.walk, {108, 19, 11}})
	table.insert(_q, {walk.walk, {108, 19, 16}})
	table.insert(_q, {walk.walk, {108, 23, 16}})
	table.insert(_q, {walk.walk, {108, 23, 19}})
	table.insert(_q, {walk.walk, {108, 24, 19}})
	table.insert(_q, {walk.walk, {108, 24, 20}})
	table.insert(_q, {walk.walk, {108, 27, 20}})
	table.insert(_q, {walk.walk, {108, 27, 2}})
end

local function _sequence_clip()
	-- Walk toward mist and begin the Mist Clip.
	table.insert(_q, {walk.walk, {nil, 86, 120}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 86, 119}})
	table.insert(_q, {walk.walk, {nil, 95, 119}})
	table.insert(_q, {walk.step, {walk.DIRECTION.LEFT}})
	table.insert(_q, {menu.field.open, {input.DELAY.NONE}})
	table.insert(_q, {menu.field.item.open, {}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.TENT}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.TENT}})
	table.insert(_q, {walk.walk, {nil, 95, 119}})
	table.insert(_q, {walk.step, {walk.DIRECTION.RIGHT}})
	table.insert(_q, {menu.field.open, {input.DELAY.NONE}})

	-- Remove Kain's Iron arms.
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Equip and unequip the Shadow shield.
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.SHIELD.SHADOW}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Save and reset.
	table.insert(_q, {_state_set, {"check_autoreload", false}})
	table.insert(_q, {menu.field.save.save, {1}})
	table.insert(_q, {input.press, {{"Reset"}, input.DELAY.NORMAL}})
	table.insert(_q, {menu.wait, {math.random(132, 387)}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.wait, {132}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {menu.confirm, {}})
	table.insert(_q, {_state_set, {"check_autoreload", true}})
end

local function _sequence_girl()
	-- Walk to the shop and open the shopping menu.
	table.insert(_q, {_state_set, {"auto_reload", true}})
	table.insert(_q, {walk.walk, {nil, 98, 119}})
	table.insert(_q, {_log_seed, {}})
	table.insert(_q, {walk.walk, {nil, 97, 119}})
	table.insert(_q, {walk.walk, {1, 19, 16}})
	table.insert(_q, {walk.walk, {1, 19, 24}})
	table.insert(_q, {walk.walk, {1, 18, 24}})
	table.insert(_q, {walk.walk, {1, 18, 26}})
	table.insert(_q, {walk.walk, {1, 14, 26}})
	table.insert(_q, {walk.walk, {1, 14, 25}})
	table.insert(_q, {walk.walk, {225, 4, 5}})
	table.insert(_q, {_state_set, {"auto_reload", false}})
	table.insert(_q, {walk.interact, {}})

	-- Sell the Shadow shield.
	table.insert(_q, {menu.shop.sell.open, {1}})
	table.insert(_q, {menu.shop.sell.sell, {game.ITEM.SHIELD.SHADOW}})
	table.insert(_q, {menu.shop.sell.close, {}})

	-- Buy 10 Dancing daggers.
	table.insert(_q, {menu.shop.buy.open, {10}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.WEAPON.DANCING}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Collect the Tiara and Change rod.
	table.insert(_q, {walk.walk, {225, 4, 10}})
	table.insert(_q, {walk.walk, {1, 14, 26}})
	table.insert(_q, {walk.walk, {1, 12, 26}})
	table.insert(_q, {walk.walk, {1, 12, 8}})
	table.insert(_q, {walk.walk, {1, 11, 8}})
	table.insert(_q, {walk.walk, {1, 11, 7}})
	table.insert(_q, {walk.walk, {15, 3, 13}})
	table.insert(_q, {walk.walk, {15, 3, 10}})
	table.insert(_q, {walk.walk, {15, 4, 10}})
	table.insert(_q, {walk.walk, {15, 4, 6}})
	table.insert(_q, {walk.walk, {15, 22, 6}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {15, 26, 6}})
	table.insert(_q, {walk.walk, {15, 26, 10}})
	table.insert(_q, {walk.walk, {15, 22, 10}})
	table.insert(_q, {walk.walk, {15, 22, 24}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {15, 22, 10}})
	table.insert(_q, {walk.walk, {15, 26, 10}})
	table.insert(_q, {walk.walk, {15, 26, 6}})
	table.insert(_q, {walk.walk, {15, 4, 6}})
	table.insert(_q, {walk.walk, {15, 4, 10}})
	table.insert(_q, {walk.walk, {15, 3, 10}})
	table.insert(_q, {walk.walk, {15, 3, 13}})
	table.insert(_q, {walk.walk, {15, 4, 13}})
	table.insert(_q, {walk.walk, {15, 4, 16}})
	table.insert(_q, {walk.walk, {1, 11, 10}})
	table.insert(_q, {walk.walk, {1, 12, 10}})
	table.insert(_q, {walk.walk, {1, 12, 16}})
	table.insert(_q, {walk.walk, {1, 8, 16}})
end

local function _sequence_officer()
	table.insert(_q, {walk.walk, {nil, 103, 117}})
	table.insert(_q, {walk.walk, {nil, 104, 117}})
	table.insert(_q, {walk.walk, {nil, 104, 109}})
	table.insert(_q, {walk.walk, {nil, 125, 109}})
	table.insert(_q, {walk.walk, {nil, 125, 104}})
	table.insert(_q, {walk.walk, {2, 15, 26}})
end

local function _sequence_tellah()
	-- Equip the Tiara on Rydia.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.TIARA}})
	table.insert(_q, {menu.field.equip.close, {}})

	-- Change formation.
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.RYDIA, 1}})
	table.insert(_q, {menu.field.close, {}})

	-- Visit Rosa.
	table.insert(_q, {walk.walk, {16, 18, 12}})
	table.insert(_q, {walk.walk, {16, 18, 14}})
	table.insert(_q, {walk.walk, {16, 20, 14}})
	table.insert(_q, {walk.walk, {16, 20, 17}})
	table.insert(_q, {walk.walk, {2, 14, 18, true}})
	table.insert(_q, {walk.walk, {2, 18, 17, true}})
	table.insert(_q, {walk.walk, {2, 21, 17, true}})
	table.insert(_q, {walk.walk, {2, 21, 16, true}})
	table.insert(_q, {walk.walk, {2, 24, 16, true}})
	table.insert(_q, {walk.walk, {2, 24, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 13, true}})
	table.insert(_q, {dialog.set_mash_button, {"P1 B"}})
	table.insert(_q, {walk.walk, {18, 4, 6}})

	-- Leave Kaipo and head to Tellah.
	table.insert(_q, {walk.walk, {18, 6, 5}})
	table.insert(_q, {dialog.set_mash_button, {"P1 A"}})
	table.insert(_q, {walk.walk, {18, 4, 5}})
	table.insert(_q, {walk.walk, {18, 4, 18}})
	table.insert(_q, {walk.walk, {2, 23, 14, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 30, true}})
	table.insert(_q, {walk.walk, {2, 16, 30}})
	table.insert(_q, {walk.walk, {2, 16, 31}})
	table.insert(_q, {walk.walk, {nil, 135, 104}})
	table.insert(_q, {walk.walk, {nil, 135, 84}})
	table.insert(_q, {walk.walk, {nil, 138, 84}})
	table.insert(_q, {walk.walk, {nil, 138, 83}})
	table.insert(_q, {walk.walk, {111, 26, 28}})
	table.insert(_q, {walk.walk, {111, 21, 28}})
	table.insert(_q, {walk.walk, {111, 21, 25}})
	table.insert(_q, {walk.walk, {111, 15, 25}})
	table.insert(_q, {walk.walk, {111, 15, 22}})
	table.insert(_q, {walk.walk, {111, 7, 22}})
	table.insert(_q, {walk.walk, {111, 7, 16}})
	table.insert(_q, {walk.interact, {"Old man:"}})
	table.insert(_q, {walk.walk, {111, 7, 13}})
end

local function _sequence_octomamm()
	-- Walk to the Watery Pass Save Room.
	table.insert(_q, {walk.walk, {111, 6, 13}})
	table.insert(_q, {walk.walk, {111, 6, 10}})
	table.insert(_q, {walk.walk, {111, 7, 10}})
	table.insert(_q, {walk.walk, {111, 7, 7}})
	table.insert(_q, {walk.walk, {111, 4, 7}})
	table.insert(_q, {walk.walk, {111, 4, 6}})
	table.insert(_q, {walk.walk, {111, 2, 6}})
	table.insert(_q, {walk.walk, {111, 2, 2}})
	table.insert(_q, {walk.walk, {112, 26, 21}})
	table.insert(_q, {walk.walk, {112, 29, 21}})
	table.insert(_q, {walk.walk, {112, 29, 13}})
	table.insert(_q, {walk.walk, {112, 28, 13}})
	table.insert(_q, {walk.walk, {112, 28, 9}})
	table.insert(_q, {walk.walk, {112, 26, 9}})
	table.insert(_q, {walk.walk, {112, 26, 12}})
	table.insert(_q, {walk.walk, {112, 23, 12}})
	table.insert(_q, {walk.walk, {112, 23, 19}})
	table.insert(_q, {walk.walk, {112, 24, 19}})
	table.insert(_q, {walk.walk, {112, 24, 25}})
	table.insert(_q, {walk.walk, {112, 22, 25}})
	table.insert(_q, {walk.walk, {112, 22, 20}})
	table.insert(_q, {walk.walk, {112, 18, 20}})
	table.insert(_q, {walk.walk, {112, 18, 25}})
	table.insert(_q, {walk.walk, {112, 12, 25}})
	table.insert(_q, {walk.walk, {112, 12, 27}})
	table.insert(_q, {walk.walk, {112, 10, 27}})
	table.insert(_q, {walk.walk, {112, 10, 28}})
	table.insert(_q, {walk.walk, {112, 5, 28}})
	table.insert(_q, {walk.walk, {112, 5, 19}})
	table.insert(_q, {walk.walk, {112, 2, 19}})
	table.insert(_q, {walk.walk, {112, 2, 17}})
	table.insert(_q, {walk.walk, {84, 4, 10}})

	-- Step Route: Watery Pass-South Save Room
	if _route[0] % 2 == 1 then
		table.insert(_q, {walk.walk, {84, 4, 6}})
		table.insert(_q, {walk.walk, {84, 4, 7}})
	end

	table.insert(_q, {walk.walk, {84, 4, 4}})

	for i = 1, _route[0] / 2 do
		table.insert(_q, {walk.walk, {84, 5, 4}})
		table.insert(_q, {walk.walk, {84, 4, 4}})
	end

	-- Walk to the Darkness sword chest.
	table.insert(_q, {walk.walk, {84, 4, 2}})
	table.insert(_q, {walk.walk, {112, 2, 8}})
	table.insert(_q, {walk.walk, {112, 10, 8}})
	table.insert(_q, {walk.walk, {112, 10, 12}})
	table.insert(_q, {walk.walk, {112, 8, 12}})
	table.insert(_q, {walk.walk, {112, 8, 15}})
	table.insert(_q, {walk.walk, {112, 12, 15}})
	table.insert(_q, {walk.walk, {112, 12, 16}})
	table.insert(_q, {walk.walk, {112, 13, 16}})
	table.insert(_q, {walk.walk, {112, 13, 17}})
	table.insert(_q, {walk.walk, {112, 16, 17}})
	table.insert(_q, {walk.walk, {112, 16, 7}})
	table.insert(_q, {walk.walk, {113, 22, 9}})
	table.insert(_q, {walk.walk, {113, 22, 13}})
	table.insert(_q, {walk.walk, {113, 15, 13}})
	table.insert(_q, {walk.walk, {113, 15, 18}})
	table.insert(_q, {walk.walk, {113, 7, 18}})
	table.insert(_q, {walk.walk, {113, 7, 17}})
	table.insert(_q, {walk.walk, {113, 6, 17}})

	-- Step Route: Watery Pass-South B3F
	for i = 1, _route[1] / 2 do
		table.insert(_q, {walk.walk, {113, 5, 17}})
		table.insert(_q, {walk.walk, {113, 6, 17}})
	end

	table.insert(_q, {walk.walk, {113, 6, 9}})
	table.insert(_q, {walk.walk, {114, 13, 17}})
	table.insert(_q, {walk.walk, {114, 11, 17}})
	table.insert(_q, {walk.walk, {114, 11, 14}})
	table.insert(_q, {walk.walk, {114, 7, 14}})
	table.insert(_q, {walk.walk, {114, 7, 10}})
	table.insert(_q, {walk.walk, {115, 10, 16}})
	table.insert(_q, {walk.walk, {115, 13, 16}})
	table.insert(_q, {walk.walk, {115, 13, 9}})
	table.insert(_q, {walk.walk, {115, 21, 9}})
	table.insert(_q, {walk.walk, {115, 21, 11}})
	table.insert(_q, {walk.walk, {115, 23, 11}})
	table.insert(_q, {walk.walk, {115, 23, 19}})
	table.insert(_q, {walk.walk, {115, 21, 19}})
	table.insert(_q, {walk.walk, {115, 21, 17}})
	table.insert(_q, {walk.walk, {115, 18, 17}})
	table.insert(_q, {walk.interact, {"Found"}})

	-- Walk to Octomamm.
	table.insert(_q, {walk.walk, {115, 21, 17}})
	table.insert(_q, {walk.walk, {115, 21, 19}})
	table.insert(_q, {walk.walk, {115, 23, 19}})
	table.insert(_q, {walk.walk, {115, 23, 11}})
	table.insert(_q, {walk.walk, {115, 24, 11}})
	table.insert(_q, {walk.walk, {115, 24, 8}})
	table.insert(_q, {walk.walk, {nil, 135, 78}})
	table.insert(_q, {walk.walk, {nil, 135, 73}})
	table.insert(_q, {walk.walk, {nil, 134, 73}})
	table.insert(_q, {walk.walk, {nil, 134, 72}})

	-- Step Route: Waterfalls B1F
	for i = 1, _route[2] / 2 do
		table.insert(_q, {walk.walk, {116, 17, 9}})
		table.insert(_q, {walk.walk, {116, 16, 9}})
	end

	table.insert(_q, {walk.walk, {116, 16, 11}})
	table.insert(_q, {walk.walk, {117, 18, 7}})
	table.insert(_q, {walk.walk, {117, 18, 5}})
	table.insert(_q, {walk.walk, {117, 21, 5}})
	table.insert(_q, {walk.walk, {117, 21, 8}})
	table.insert(_q, {walk.walk, {117, 22, 8}})
	table.insert(_q, {walk.walk, {117, 22, 10}})
	table.insert(_q, {walk.walk, {117, 20, 10}})
	table.insert(_q, {walk.walk, {117, 20, 21}})
	table.insert(_q, {walk.walk, {117, 11, 21}})
	table.insert(_q, {walk.walk, {117, 11, 12}})
	table.insert(_q, {walk.walk, {117, 10, 12}})
	table.insert(_q, {walk.walk, {117, 10, 11}})
	table.insert(_q, {walk.walk, {118, 13, 23}})
	table.insert(_q, {walk.walk, {118, 13, 22}})
	table.insert(_q, {walk.walk, {118, 21, 22}})
	table.insert(_q, {walk.walk, {118, 21, 17}})
	table.insert(_q, {walk.walk, {118, 19, 17}})
	table.insert(_q, {walk.walk, {118, 19, 20}})
	table.insert(_q, {walk.walk, {118, 16, 20}})
	table.insert(_q, {walk.walk, {118, 16, 10}})
end

local function _sequence_edward()
	-- Open the menu.
	table.insert(_q, {menu.field.open, {}})

	-- Deal with the Change rod.
	local weapon, quantity = game.character.get_equipment(game.character.get_slot(game.CHARACTER.TELLAH), game.EQUIP.R_HAND)

	if quantity == 255 then
		_M.state.multi_change = true
		table.insert(_q, {menu.field.equip.open, {game.CHARACTER.TELLAH}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.NONE}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
		table.insert(_q, {menu.field.equip.close, {}})
	elseif weapon == game.ITEM.WEAPON.CHANGE then
		table.insert(_q, {menu.field.equip.open, {game.CHARACTER.TELLAH}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.STAFF}})
		table.insert(_q, {menu.field.equip.close, {}})
	end

	-- Change formation.
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.TELLAH, game.CHARACTER.RYDIA, game.FORMATION.TWO_FRONT}})
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.CECIL, 3}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to Damcyan.
	table.insert(_q, {walk.walk, {nil, 123, 67}})
	table.insert(_q, {walk.walk, {nil, 123, 68}})
	table.insert(_q, {walk.walk, {nil, 120, 68}})
	table.insert(_q, {walk.walk, {nil, 120, 64}})
	table.insert(_q, {walk.walk, {nil, 119, 64}})
	table.insert(_q, {walk.walk, {nil, 119, 58}})
	table.insert(_q, {walk.walk, {37, 16, 11}})
	table.insert(_q, {walk.walk, {63, 8, 13}})

	-- Step Route: Damcyan
	for i = 1, _route[3] / 2 do
		table.insert(_q, {walk.walk, {63, 9, 13}})
		table.insert(_q, {walk.walk, {63, 8, 13}})
	end

	table.insert(_q, {walk.walk, {63, 8, 7}})
	table.insert(_q, {walk.walk, {64, 8, 10}})

	if _route[3] % 2 == 1 then
		table.insert(_q, {walk.walk, {64, 9, 10}})
		table.insert(_q, {walk.walk, {64, 9, 13}})
	else
		table.insert(_q, {walk.walk, {64, 7, 10}})
		table.insert(_q, {walk.walk, {64, 7, 13}})
	end

	table.insert(_q, {walk.walk, {64, 8, 13}})
	table.insert(_q, {walk.walk, {65, 13, 11}})
end

local function _sequence_antlion()
	-- Travel to the Antlion cave.
	table.insert(_q, {walk.walk, {nil, 117, 50}})
	table.insert(_q, {walk.walk, {nil, 124, 50}})
	table.insert(_q, {walk.walk, {nil, 124, 48}})
	table.insert(_q, {walk.walk, {nil, 127, 48}})
	table.insert(_q, {walk.walk, {nil, 127, 46}})
	table.insert(_q, {walk.walk, {nil, 131, 46}})
	table.insert(_q, {walk.walk, {nil, 131, 49}})
	table.insert(_q, {walk.walk, {nil, 132, 49}})
	table.insert(_q, {walk.walk, {nil, 132, 57}})
	table.insert(_q, {walk.walk, {nil, 136, 57}})
	table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
	table.insert(_q, {walk.walk, {nil, 136, 56}})

	-- Walk to the Life chest.
	table.insert(_q, {walk.walk, {119, 15, 8}})
	table.insert(_q, {walk.walk, {119, 14, 8}})
	table.insert(_q, {walk.walk, {119, 14, 13}})
	table.insert(_q, {walk.walk, {119, 17, 13}})
	table.insert(_q, {walk.walk, {119, 17, 15}})
	table.insert(_q, {walk.walk, {119, 19, 15}})
	table.insert(_q, {walk.walk, {119, 19, 12}})
	table.insert(_q, {walk.walk, {119, 25, 12}})
	table.insert(_q, {walk.walk, {119, 25, 14}})
	table.insert(_q, {walk.walk, {119, 27, 14}})
	table.insert(_q, {walk.walk, {119, 27, 23}})
	table.insert(_q, {walk.walk, {120, 27, 4}})
	table.insert(_q, {walk.walk, {120, 28, 4}})
	table.insert(_q, {walk.walk, {120, 28, 13}})
	table.insert(_q, {walk.walk, {120, 29, 13}})
	table.insert(_q, {walk.walk, {120, 29, 18}})
	table.insert(_q, {walk.walk, {120, 28, 18}})
	table.insert(_q, {walk.walk, {120, 28, 24}})
	table.insert(_q, {walk.walk, {120, 29, 24}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to Antlion.
	table.insert(_q, {walk.walk, {120, 29, 26}})
	table.insert(_q, {walk.walk, {120, 25, 26}})

	-- Step Route: Antlion B2F Inward
	if _route[4] == 1 then
		table.insert(_q, {walk.walk, {120, 25, 23}})

		for i = 1, _route[5] / 2 do
			table.insert(_q, {walk.walk, {123, 4, 11}})
			table.insert(_q, {walk.walk, {123, 4, 12}})
		end

		table.insert(_q, {walk.walk, {123, 4, 13}})
		table.insert(_q, {walk.walk, {120, 25, 26}})
	end

	table.insert(_q, {walk.walk, {120, 25, 28}})
	table.insert(_q, {walk.walk, {120, 22, 28}})
	table.insert(_q, {walk.walk, {120, 22, 31}})
	table.insert(_q, {walk.walk, {120, 3, 31}})
	table.insert(_q, {walk.walk, {120, 3, 23}})
	table.insert(_q, {walk.walk, {120, 14, 23}})
	table.insert(_q, {walk.walk, {120, 14, 29}})
	table.insert(_q, {walk.walk, {121, 14, 19}})
end

local function _sequence_waterhag()
	-- Leave the Antlion cave.
	table.insert(_q, {walk.walk, {121, 14, 3}})
	table.insert(_q, {walk.walk, {120, 14, 23}})
	table.insert(_q, {walk.walk, {120, 3, 23}})
	table.insert(_q, {walk.walk, {120, 3, 31}})
	table.insert(_q, {walk.walk, {120, 22, 31}})
	table.insert(_q, {walk.walk, {120, 22, 28}})
	table.insert(_q, {walk.walk, {120, 25, 28}})
	table.insert(_q, {walk.walk, {120, 25, 26}})

	-- Step Route: Antlion B2F Outward
	if _route[6] == 1 then
		table.insert(_q, {walk.walk, {120, 25, 23}})

		for i = 1, _route[7] / 2 do
			table.insert(_q, {walk.walk, {123, 4, 11}})
			table.insert(_q, {walk.walk, {123, 4, 12}})
		end

		table.insert(_q, {walk.walk, {123, 4, 13}})
		table.insert(_q, {walk.walk, {120, 25, 26}})
	end

	table.insert(_q, {walk.walk, {120, 29, 26}})
	table.insert(_q, {walk.walk, {120, 29, 24}})
	table.insert(_q, {walk.walk, {120, 28, 24}})
	table.insert(_q, {walk.walk, {120, 28, 16}})
	table.insert(_q, {walk.walk, {120, 29, 16}})
	table.insert(_q, {walk.walk, {120, 29, 5}})
	table.insert(_q, {walk.walk, {120, 28, 5}})
	table.insert(_q, {walk.walk, {120, 28, 4}})
	table.insert(_q, {walk.walk, {120, 27, 4}})
	table.insert(_q, {walk.walk, {120, 27, 2}})
	table.insert(_q, {walk.walk, {119, 27, 14}})
	table.insert(_q, {walk.walk, {119, 25, 14}})
	table.insert(_q, {walk.walk, {119, 25, 12}})
	table.insert(_q, {walk.walk, {119, 19, 12}})
	table.insert(_q, {walk.walk, {119, 19, 15}})
	table.insert(_q, {walk.walk, {119, 17, 15}})
	table.insert(_q, {walk.walk, {119, 17, 10}})
	table.insert(_q, {walk.walk, {119, 14, 10}})
	table.insert(_q, {walk.walk, {119, 14, 5}})
	table.insert(_q, {walk.walk, {119, 15, 5}})
	table.insert(_q, {walk.walk, {119, 15, 3}})

	-- Board the hovercraft and travel to Kaipo.
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 132, 57}})
	table.insert(_q, {walk.walk, {nil, 132, 49}})
	table.insert(_q, {walk.walk, {nil, 131, 49}})
	table.insert(_q, {walk.walk, {nil, 131, 46}})
	table.insert(_q, {walk.walk, {nil, 126, 46}})
	table.insert(_q, {walk.walk, {nil, 126, 49}})
	table.insert(_q, {walk.walk, {nil, 122, 49}})
	table.insert(_q, {walk.walk, {nil, 122, 62}})
	table.insert(_q, {walk.walk, {nil, 115, 62}})
	table.insert(_q, {walk.walk, {nil, 115, 68}})
	table.insert(_q, {walk.walk, {nil, 99, 68}})
	table.insert(_q, {walk.walk, {nil, 99, 77}})
	table.insert(_q, {walk.walk, {nil, 98, 77}})
	table.insert(_q, {walk.walk, {nil, 98, 80}})
	table.insert(_q, {walk.walk, {nil, 100, 80}})
	table.insert(_q, {walk.walk, {nil, 100, 83}})
	table.insert(_q, {walk.walk, {nil, 118, 83}})
	table.insert(_q, {walk.walk, {nil, 118, 104}})
	table.insert(_q, {walk.walk, {nil, 124, 104}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 125, 104}})

	-- Walk to Rosa and use the SandRuby.
	table.insert(_q, {walk.walk, {2, 15, 25, true}})
	table.insert(_q, {walk.walk, {2, 20, 25, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 23, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 15, true}})
	table.insert(_q, {walk.walk, {2, 28, 13, true}})
	table.insert(_q, {walk.walk, {18, 4, 5}})
	table.insert(_q, {walk.walk, {18, 6, 5}})
	table.insert(_q, {walk.walk, {18, 6, 3}})
	table.insert(_q, {walk.step, {walk.DIRECTION.RIGHT}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.SANDRUBY}})
end

local function _sequence_mombomb()
	-- Leave Kaipo.
	table.insert(_q, {walk.walk, {18, 4, 18}})
	table.insert(_q, {walk.walk, {2, 23, 14, true}})
	table.insert(_q, {walk.walk, {2, 23, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 19, true}})
	table.insert(_q, {walk.walk, {2, 20, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 26, true}})
	table.insert(_q, {walk.walk, {2, 15, 30, true}})
	table.insert(_q, {walk.walk, {2, 14, 30}})
	table.insert(_q, {walk.walk, {2, 14, 31}})

	-- Head to Mt.Hobs.
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 107, 104}})
	table.insert(_q, {walk.walk, {nil, 107, 83}})
	table.insert(_q, {walk.walk, {nil, 99, 83}})
	table.insert(_q, {walk.walk, {nil, 99, 79}})
	table.insert(_q, {walk.walk, {nil, 98, 79}})
	table.insert(_q, {walk.walk, {nil, 98, 76}})
	table.insert(_q, {walk.walk, {nil, 99, 76}})
	table.insert(_q, {walk.walk, {nil, 99, 68}})
	table.insert(_q, {walk.walk, {nil, 115, 68}})
	table.insert(_q, {walk.walk, {nil, 115, 62}})
	table.insert(_q, {walk.walk, {nil, 124, 62}})
	table.insert(_q, {walk.walk, {nil, 124, 62}})
	table.insert(_q, {walk.walk, {nil, 124, 48}})
	table.insert(_q, {walk.walk, {nil, 127, 48}})
	table.insert(_q, {walk.walk, {nil, 127, 46}})
	table.insert(_q, {walk.walk, {nil, 131, 46}})
	table.insert(_q, {walk.walk, {nil, 131, 49}})
	table.insert(_q, {walk.walk, {nil, 143, 49}})
	table.insert(_q, {walk.walk, {nil, 143, 48}})
	table.insert(_q, {walk.walk, {nil, 150, 48}})
	table.insert(_q, {walk.walk, {nil, 150, 49}})
	table.insert(_q, {walk.walk, {nil, 151, 49}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 152, 49}})

	-- Head up the mountain to MomBomb.
	table.insert(_q, {walk.walk, {126, 15, 26}})
	table.insert(_q, {walk.walk, {126, 15, 17}})
	table.insert(_q, {walk.walk, {126, 8, 17}})
	table.insert(_q, {walk.walk, {126, 8, 11}})
	table.insert(_q, {walk.walk, {126, 22, 11}})
	table.insert(_q, {walk.walk, {126, 22, 7}})
	table.insert(_q, {walk.walk, {127, 8, 23}})
	table.insert(_q, {walk.walk, {127, 16, 23}})
	table.insert(_q, {walk.walk, {127, 16, 20}})
	table.insert(_q, {walk.walk, {127, 20, 20}})
end

local function _sequence_dragoon()
	-- Leave Mt.Hobs.
	table.insert(_q, {walk.walk, {127, 19, 14}})
	table.insert(_q, {walk.walk, {127, 19, 9}})

	-- Step Route: Mt.Hobs-East
	for i = 1, _route[8] / 2 do
		table.insert(_q, {walk.walk, {128, 7, 11}})
		table.insert(_q, {walk.walk, {128, 7, 10}})
	end

	table.insert(_q, {walk.walk, {128, 11, 10}})

	if _route[8] % 2 == 1 then
		table.insert(_q, {walk.walk, {128, 10, 10}})
		table.insert(_q, {walk.walk, {128, 11, 10}})
	end

	table.insert(_q, {walk.walk, {128, 20, 10}})
	table.insert(_q, {walk.walk, {128, 20, 14}})
	table.insert(_q, {walk.walk, {128, 14, 14}})
	table.insert(_q, {walk.walk, {128, 14, 15}})
	table.insert(_q, {walk.walk, {128, 11, 15}})
	table.insert(_q, {walk.walk, {128, 11, 17}})
	table.insert(_q, {walk.walk, {128, 10, 17}})
	table.insert(_q, {walk.walk, {128, 10, 21}})
	table.insert(_q, {walk.walk, {128, 18, 21}})
	table.insert(_q, {walk.walk, {128, 18, 27}})
	table.insert(_q, {walk.walk, {128, 21, 27}})
	table.insert(_q, {walk.walk, {128, 21, 31}})

	-- Walk to Fabul.
	table.insert(_q, {walk.walk, {nil, 162, 50}})
	table.insert(_q, {walk.walk, {nil, 162, 49}})
	table.insert(_q, {walk.walk, {nil, 171, 49}})
	table.insert(_q, {walk.walk, {nil, 171, 38}})
	table.insert(_q, {walk.walk, {nil, 185, 38}})
	table.insert(_q, {walk.walk, {nil, 185, 45}})
	table.insert(_q, {walk.walk, {nil, 200, 45}})
	table.insert(_q, {walk.walk, {nil, 200, 48}})
	table.insert(_q, {walk.walk, {nil, 207, 48}})
	table.insert(_q, {walk.walk, {nil, 207, 58}})
	table.insert(_q, {walk.walk, {nil, 214, 58}})

	-- Walk to the King.
	table.insert(_q, {walk.walk, {38, 15, 14}})
	table.insert(_q, {walk.walk, {71, 11, 3}})
	table.insert(_q, {walk.walk, {72, 4, 0}})
	table.insert(_q, {walk.walk, {73, 8, 12}})
end

local function _sequence_twins()
	-- Head to the Fabul Inn.
	table.insert(_q, {walk.walk, {74, 11, 15}})
	table.insert(_q, {walk.walk, {74, 11, 26}})
	table.insert(_q, {walk.walk, {73, 4, 7}})

	-- Step Route: Fabul
	if _route[9] >= 6 then
		table.insert(_q, {walk.walk, {73, 4, 11}})
		_route[9] = _route[9] - 6
	else
		if _route[9] == 5 then
			table.insert(_q, {walk.walk, {73, 4, 9}})
			table.insert(_q, {walk.walk, {73, 5, 9}})
			table.insert(_q, {walk.walk, {73, 5, 11}})
		elseif _route[9] == 4 then
			table.insert(_q, {walk.walk, {73, 4, 9}})
			table.insert(_q, {walk.walk, {73, 6, 9}})
			table.insert(_q, {walk.walk, {73, 6, 11}})
		elseif _route[9] == 3 then
			table.insert(_q, {walk.walk, {73, 4, 8}})
			table.insert(_q, {walk.walk, {73, 6, 8}})
			table.insert(_q, {walk.walk, {73, 6, 11}})
		elseif _route[9] == 2 then
			table.insert(_q, {walk.walk, {73, 4, 8}})
			table.insert(_q, {walk.walk, {73, 7, 8}})
			table.insert(_q, {walk.walk, {73, 7, 11}})
		elseif _route[9] == 1 then
			table.insert(_q, {walk.walk, {73, 4, 8}})
			table.insert(_q, {walk.walk, {73, 8, 8}})
		else
			table.insert(_q, {walk.walk, {73, 8, 7}})
		end

		_route[9] = 0
	end

	table.insert(_q, {walk.walk, {73, 8, 11}})
	table.insert(_q, {walk.walk, {73, 8, 14}})
	table.insert(_q, {walk.walk, {72, 4, 9}})
	table.insert(_q, {walk.walk, {71, 11, 11}})
	table.insert(_q, {walk.walk, {71, 6, 11}})

	-- Step Route: Fabul
	if _route[9] > 0 then
		table.insert(_q, {walk.walk, {71, 5, 11}})
		_route[9] = _route[9] - 1
	else
		table.insert(_q, {walk.walk, {71, 6, 10}})
	end

	table.insert(_q, {walk.walk, {71, 5, 10}})
	table.insert(_q, {walk.walk, {71, 5, 7}})

	-- Step Route: Fabul
	if _route[9] >= 2 then
		table.insert(_q, {walk.walk, {76, 18, 7}})
		table.insert(_q, {walk.walk, {76, 18, 5}})
		_route[9] = _route[9] - 2
	elseif _route[9] == 1 then
		table.insert(_q, {walk.walk, {76, 20, 6}})
		table.insert(_q, {walk.walk, {76, 19, 6}})
		table.insert(_q, {walk.walk, {76, 19, 5}})
		_route[9] = _route[9] - 1
	else
		table.insert(_q, {walk.walk, {76, 20, 5}})
	end

	table.insert(_q, {walk.walk, {76, 17, 5}})

	-- Remove the Tiara and equip the Black sword.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.CAP}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.BLACK}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.close, {}})

	-- Head to the boat.
	if _route[9] % 2 == 1 then
		table.insert(_q, {walk.walk, {79, 3, 4}})
		table.insert(_q, {walk.walk, {79, 3, 5}})
	else
		table.insert(_q, {walk.walk, {79, 5, 5}})
	end

	table.insert(_q, {walk.walk, {79, 1, 5}})

	for i = 1, _route[9] / 2 do
		table.insert(_q, {walk.walk, {79, 1, 4}})
		table.insert(_q, {walk.walk, {79, 1, 5}})
	end

	table.insert(_q, {walk.walk, {79, 1, 6}})
	table.insert(_q, {walk.walk, {78, 1, 6}})
	table.insert(_q, {walk.walk, {77, 1, 6}})
	table.insert(_q, {walk.walk, {77, 2, 6}})
	table.insert(_q, {walk.walk, {77, 2, 10}})
	table.insert(_q, {walk.walk, {38, 17, 11}})
	table.insert(_q, {walk.walk, {38, 15, 11}})
	table.insert(_q, {walk.walk, {38, 15, 10}})
	table.insert(_q, {walk.walk, {72, 6, 13}})
	table.insert(_q, {walk.walk, {72, 6, 6}})
	table.insert(_q, {walk.walk, {72, 4, 6}})
	table.insert(_q, {walk.walk, {72, 4, 9}})
	table.insert(_q, {walk.walk, {71, 11, 15}})
	table.insert(_q, {walk.walk, {38, 15, 31}})
	table.insert(_q, {walk.walk, {nil, 216, 59}})
	table.insert(_q, {walk.walk, {nil, 216, 58}})
	table.insert(_q, {walk.walk, {nil, 220, 58}})
	table.insert(_q, {walk.walk, {nil, 220, 56}})
	table.insert(_q, {walk.walk, {nil, 221, 56}})

	-- Go to the Mysidian item shop.
	table.insert(_q, {walk.walk, {nil, 145, 199}})
	table.insert(_q, {walk.walk, {nil, 154, 199}})
	table.insert(_q, {walk.walk, {3, 16, 27, true}})
	table.insert(_q, {walk.walk, {3, 27, 27, true}})
	table.insert(_q, {walk.walk, {3, 27, 26, true}})
	table.insert(_q, {walk.walk, {231, 5, 5}})
	table.insert(_q, {walk.interact, {}})

	-- Purchase items from the shop.
	table.insert(_q, {menu.shop.buy.open, {90}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ITEM.CURE2}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ITEM.LIFE}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ITEM.HEAL}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ITEM.ETHER1}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Head to the armor shop.
	table.insert(_q, {walk.walk, {231, 5, 10}})
	table.insert(_q, {walk.walk, {3, 27, 27}})
	table.insert(_q, {walk.walk, {3, 15, 27, true}})
	table.insert(_q, {walk.walk, {3, 15, 26, true}})
	table.insert(_q, {walk.walk, {3, 8, 26, true}})
	table.insert(_q, {walk.walk, {3, 8, 24, true}})
	table.insert(_q, {walk.walk, {3, 9, 24, true}})
	table.insert(_q, {walk.walk, {3, 9, 23, true}})
	table.insert(_q, {walk.walk, {230, 4, 5, true}})
	table.insert(_q, {walk.interact, {}})

	-- Buy various needed armor items.
	table.insert(_q, {menu.shop.buy.open, {10}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.HELM.GAEA}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ARMOR.GAEA}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.RING.SILVER}})
	table.insert(_q, {menu.shop.switch_quantity, {}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.SHIELD.PALADIN}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ARMS.PALADIN}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Head to the Elder.
	table.insert(_q, {walk.walk, {230, 4, 10, true}})
	table.insert(_q, {walk.walk, {3, 9, 24, true}})
	table.insert(_q, {walk.walk, {3, 8, 24, true}})
	table.insert(_q, {walk.walk, {3, 8, 26, true}})
	table.insert(_q, {walk.walk, {3, 16, 26, true}})
	table.insert(_q, {walk.walk, {3, 16, 8, true}})
	table.insert(_q, {walk.walk, {22, 14, 6, true}})
	table.insert(_q, {walk.interact, {}})
end

local function _sequence_milon()
	-- Walk to Mt.Ordeals.
	table.insert(_q, {_set_healing, {_healing_milon_1}})
	table.insert(_q, {walk.walk, {22, 14, 12, true}})
	table.insert(_q, {walk.walk, {3, 16, 31, true}})
	table.insert(_q, {walk.walk, {nil, 157, 200}})
	table.insert(_q, {walk.walk, {nil, 157, 205}})

	-- Step Route: World Map (Mysidia)
	for i = 1, _route[10] / 2 do
		table.insert(_q, {walk.walk, {nil, 157, 204}})
		table.insert(_q, {walk.walk, {nil, 157, 205}})
	end

	table.insert(_q, {walk.walk, {nil, 175, 205}})
	table.insert(_q, {walk.walk, {nil, 175, 211}})
	table.insert(_q, {walk.walk, {nil, 182, 211}})
	table.insert(_q, {walk.walk, {nil, 182, 192}})
	table.insert(_q, {walk.walk, {nil, 211, 192}})
	table.insert(_q, {walk.walk, {nil, 211, 201}})
	table.insert(_q, {walk.walk, {nil, 218, 201}})
	table.insert(_q, {walk.walk, {nil, 218, 199}})

	-- Walk up the mountain.
	table.insert(_q, {walk.walk, {132, 20, 29}})
	table.insert(_q, {walk.walk, {132, 12, 29}})
	table.insert(_q, {walk.walk, {132, 12, 28}})
	table.insert(_q, {walk.walk, {132, 11, 28}})
	table.insert(_q, {walk.walk, {132, 9, 24}})
	table.insert(_q, {walk.walk, {132, 11, 24}})
	table.insert(_q, {walk.walk, {132, 11, 23}})
	table.insert(_q, {walk.walk, {132, 17, 23}})
	table.insert(_q, {walk.walk, {132, 17, 18}})
	table.insert(_q, {walk.walk, {132, 14, 18}})
	table.insert(_q, {walk.walk, {132, 14, 12}})
	table.insert(_q, {walk.walk, {132, 19, 12}})
	table.insert(_q, {walk.walk, {132, 19, 9}})
	table.insert(_q, {walk.walk, {133, 8, 24}})
	table.insert(_q, {walk.walk, {133, 8, 17}})
	table.insert(_q, {walk.walk, {133, 18, 17}})
	table.insert(_q, {walk.walk, {133, 18, 8}})
	table.insert(_q, {walk.walk, {133, 21, 8}})
	table.insert(_q, {walk.walk, {133, 21, 7}})
	table.insert(_q, {_set_healing, {_healing_milon_2}})
	table.insert(_q, {walk.walk, {134, 23, 25}})
	table.insert(_q, {walk.walk, {134, 19, 25}})
	table.insert(_q, {walk.walk, {134, 19, 23}})
	table.insert(_q, {walk.walk, {134, 18, 23}})
	table.insert(_q, {walk.walk, {134, 18, 17}})
	table.insert(_q, {walk.walk, {134, 24, 17}})
	table.insert(_q, {walk.walk, {134, 24, 8}})
	table.insert(_q, {walk.walk, {134, 11, 8}})
	table.insert(_q, {walk.walk, {134, 11, 7}})
	table.insert(_q, {walk.walk, {135, 15, 23}})
	table.insert(_q, {walk.walk, {135, 18, 23}})
	table.insert(_q, {walk.walk, {135, 18, 16}})
	table.insert(_q, {walk.walk, {135, 17, 16}})

	-- Step Route: Mt.Ordeals Summit
	if _route[11] > 0 then
		table.insert(_q, {walk.walk, {135, 17, 15}})
	else
		table.insert(_q, {walk.walk, {135, 16, 16}})
	end

	table.insert(_q, {walk.walk, {135, 16, 15}})
	table.insert(_q, {walk.walk, {135, 16, 10}})
	table.insert(_q, {walk.walk, {135, 15, 10}})

	-- Heal and equip.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.PALOM] = _RESTORE.ALL, [game.CHARACTER.POROM] = _RESTORE.LIFE, [game.CHARACTER.TELLAH] = _RESTORE.HP}}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.PALOM}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.WEAPON.CHANGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.GAEA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.GAEA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.SILVER}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.TELLAH}})

	if _M.state.multi_change then
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
	end

	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.GAEA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.SILVER}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.close, {}})

	-- Begin the battle.
	table.insert(_q, {walk.walk, {135, 14, 10}})
end

local function _sequence_milon_z()
	-- Heal and prepare the party.
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.PALOM] = _RESTORE.ALL, [game.CHARACTER.POROM] = _RESTORE.HP, [game.CHARACTER.TELLAH] = _RESTORE.HP}}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.POROM, game.CHARACTER.TELLAH, game.FORMATION.THREE_FRONT}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to Milon Z.
	table.insert(_q, {walk.walk, {135, 9, 10}})
end

local function _sequence_paladin()
	-- Walk to the Paladin scene.
	table.insert(_q, {walk.walk, {135, 9, 11}})
	table.insert(_q, {walk.walk, {135, 6, 11}})
	table.insert(_q, {walk.walk, {135, 6, 10}})
end

local function _sequence_karate()
	-- Leave Mt.Ordeals.
	table.insert(_q, {walk.walk, {135, 6, 11}})
	table.insert(_q, {_set_healing, {_healing_karate}})
	table.insert(_q, {walk.walk, {135, 9, 11}})
	table.insert(_q, {walk.walk, {135, 9, 10}})
	table.insert(_q, {walk.walk, {135, 16, 10}})
	table.insert(_q, {walk.walk, {135, 16, 15}})

	-- Step Route: Mt.Ordeals Summit
	if _route[12] > 0 then
		table.insert(_q, {walk.walk, {135, 17, 15}})
	else
		table.insert(_q, {walk.walk, {135, 16, 16}})
	end

	table.insert(_q, {walk.walk, {135, 17, 16}})
	table.insert(_q, {walk.walk, {135, 18, 16}})
	table.insert(_q, {walk.walk, {135, 18, 23}})
	table.insert(_q, {walk.walk, {135, 15, 23}})
	table.insert(_q, {walk.walk, {135, 15, 21}})
	table.insert(_q, {walk.walk, {134, 24, 8}})
	table.insert(_q, {walk.walk, {134, 24, 17}})
	table.insert(_q, {walk.walk, {134, 18, 17}})
	table.insert(_q, {walk.walk, {134, 18, 23}})
	table.insert(_q, {walk.walk, {134, 19, 23}})
	table.insert(_q, {walk.walk, {134, 19, 25}})
	table.insert(_q, {walk.walk, {134, 23, 25}})
	table.insert(_q, {walk.walk, {134, 23, 22}})
	table.insert(_q, {walk.walk, {133, 18, 8}})
	table.insert(_q, {walk.walk, {133, 18, 17}})
	table.insert(_q, {walk.walk, {133, 8, 17}})
	table.insert(_q, {walk.walk, {133, 8, 24}})
	table.insert(_q, {walk.walk, {133, 10, 24}})
	table.insert(_q, {walk.walk, {133, 10, 23}})
	table.insert(_q, {walk.walk, {132, 19, 12}})
	table.insert(_q, {walk.walk, {132, 14, 12}})
	table.insert(_q, {walk.walk, {132, 14, 18}})
	table.insert(_q, {walk.walk, {132, 17, 18}})
	table.insert(_q, {walk.walk, {132, 17, 23}})
	table.insert(_q, {walk.walk, {132, 11, 23}})
	table.insert(_q, {walk.walk, {132, 11, 24}})
	table.insert(_q, {walk.walk, {132, 10, 24}})
	table.insert(_q, {walk.walk, {132, 10, 28}})

	-- Step Route: Mt.Ordeals
	for i = 1, _route[13] / 2 do
		table.insert(_q, {walk.walk, {132, 9, 28}})
		table.insert(_q, {walk.walk, {132, 10, 28}})
	end

	if _route[13] % 2 == 1 then
		table.insert(_q, {walk.walk, {132, 11, 28}})
		table.insert(_q, {walk.walk, {132, 10, 28}})
	end

	table.insert(_q, {walk.walk, {132, 17, 28}})
	table.insert(_q, {walk.walk, {132, 17, 30}})
	table.insert(_q, {walk.walk, {132, 20, 30}})
	table.insert(_q, {walk.walk, {132, 20, 31}})

	-- Walk to the Chocobo forest and get a chocobo.
	table.insert(_q, {walk.walk, {nil, 218, 209}})
	table.insert(_q, {walk.walk, {nil, 213, 209}})
	table.insert(_q, {walk.chase, {209, {6, 7, 8}}})

	-- Ride the chocobo to Mysidia.
	table.insert(_q, {walk.walk, {nil, 213, 200}})
	table.insert(_q, {walk.walk, {nil, 201, 200}})
	table.insert(_q, {walk.walk, {nil, 201, 192}})
	table.insert(_q, {walk.walk, {nil, 182, 192}})
	table.insert(_q, {walk.walk, {nil, 182, 211}})
	table.insert(_q, {walk.walk, {nil, 175, 211}})
	table.insert(_q, {walk.walk, {nil, 175, 203}})
	table.insert(_q, {walk.walk, {nil, 157, 203}})
	table.insert(_q, {walk.walk, {nil, 157, 199}})
	table.insert(_q, {walk.walk, {nil, 156, 199}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 155, 199}})

	-- Walk to the Elder.
	table.insert(_q, {walk.walk, {3, 16, 8, true}})
	table.insert(_q, {walk.walk, {22, 14, 6, true}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to the Serpent Road.
	table.insert(_q, {walk.walk, {22, 14, 12, true}})
	table.insert(_q, {walk.walk, {3, 16, 20, true}})
	table.insert(_q, {walk.walk, {3, 19, 20, true}})
	table.insert(_q, {walk.walk, {3, 19, 19, true}})
	table.insert(_q, {walk.walk, {3, 25, 19, true}})
	table.insert(_q, {walk.walk, {3, 25, 17, true}})
	table.insert(_q, {walk.walk, {137, 4, 5}})

	-- Walk to Yang.
	-- TODO: Fix the second and third to last steps. They currently go one step
	--       too far to the left to avoid a potential trap.
	table.insert(_q, {walk.walk, {151, 5, 10}})

	-- Step Route: Serpent Road
	for i = 1, _route[14] / 2 do
		table.insert(_q, {walk.walk, {151, 6, 10}})
		table.insert(_q, {walk.walk, {151, 5, 10}})
	end

	if _route[14] % 2 == 1 then
		table.insert(_q, {walk.walk, {151, 5, 9}})
		table.insert(_q, {walk.walk, {151, 5, 10}})
	end

	table.insert(_q, {walk.walk, {151, 5, 14}})
	table.insert(_q, {walk.walk, {0, 20, 26, true}})
	table.insert(_q, {walk.walk, {11, 18, 17, true}})
	table.insert(_q, {walk.walk, {11, 18, 8, true}})
	table.insert(_q, {walk.walk, {11, 11, 8, true}})
	table.insert(_q, {walk.walk, {11, 11, 4, true}})
	table.insert(_q, {walk.walk, {11, 13, 4, true}})
	table.insert(_q, {walk.interact, {}})

end

local function _sequence_baigan()
	-- Walk to the Weapon/Armor shop and begin shopping.
	table.insert(_q, {_set_healing, {_healing_baigan}})
	table.insert(_q, {walk.walk, {11, 14, 21, true}})
	table.insert(_q, {walk.walk, {0, 20, 27, true}})
	table.insert(_q, {walk.walk, {0, 17, 27, true}})
	table.insert(_q, {walk.walk, {0, 17, 19, true}})
	table.insert(_q, {walk.walk, {0, 14, 19, true}})
	table.insert(_q, {walk.walk, {0, 14, 17, true}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.BARON}})
	table.insert(_q, {walk.walk, {0, 14, 16, true}})
	table.insert(_q, {walk.chase, {12, {0}, true}})

	-- Buy armor.
	table.insert(_q, {menu.shop.buy.open, {1}})

	if not _M.state.multi_change then
		table.insert(_q, {menu.shop.buy.buy, {game.ITEM.WEAPON.THUNDER}})
	end

	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.CLAW.ICECLAW}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.CLAW.THUNDER}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Buy weapons.
	table.insert(_q, {walk.walk, {12, 6, 8}})
	table.insert(_q, {walk.walk, {12, 10, 8}})
	table.insert(_q, {walk.walk, {12, 10, 7}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.shop.buy.open, {10}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Walk to the Baigan battle room.
	table.insert(_q, {walk.walk, {12, 10, 9}})
	table.insert(_q, {walk.walk, {12, 7, 9}})
	table.insert(_q, {walk.walk, {12, 7, 12}})
	table.insert(_q, {walk.walk, {0, 14, 20}})
	table.insert(_q, {walk.walk, {0, 7, 20}})
	table.insert(_q, {walk.walk, {0, 7, 21}})
	table.insert(_q, {walk.walk, {0, 3, 21}})
	table.insert(_q, {walk.walk, {0, 3, 20}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.BARON}})
	table.insert(_q, {walk.walk, {0, 3, 19}})
	table.insert(_q, {walk.walk, {68, 2, 4}})
	table.insert(_q, {walk.walk, {58, 3, 15}})
	table.insert(_q, {walk.walk, {58, 7, 15}})
	table.insert(_q, {walk.walk, {58, 7, 24}})
	table.insert(_q, {walk.walk, {58, 16, 24}})
	table.insert(_q, {walk.walk, {58, 16, 17}})
	table.insert(_q, {walk.walk, {58, 12, 17}})
	table.insert(_q, {walk.walk, {58, 12, 7}})
	table.insert(_q, {walk.walk, {58, 14, 7}})
	table.insert(_q, {walk.walk, {58, 14, 5}})
	table.insert(_q, {walk.walk, {58, 18, 5}})
	table.insert(_q, {walk.walk, {58, 18, 7}})
	table.insert(_q, {walk.walk, {58, 20, 7}})
	table.insert(_q, {walk.walk, {58, 20, 16}})
	table.insert(_q, {walk.walk, {58, 27, 16}})
	table.insert(_q, {walk.walk, {58, 27, 7}})
	table.insert(_q, {walk.walk, {59, 1, 3}})
	table.insert(_q, {walk.walk, {59, 4, 3}})
	table.insert(_q, {walk.walk, {59, 4, 8}})
	table.insert(_q, {walk.walk, {59, 13, 8}})
	table.insert(_q, {walk.walk, {59, 13, 6}})
	table.insert(_q, {walk.walk, {59, 16, 6}})
	table.insert(_q, {walk.walk, {59, 16, 10}})
	table.insert(_q, {walk.walk, {59, 25, 10}})
	table.insert(_q, {walk.walk, {59, 25, 12}})
	table.insert(_q, {walk.walk, {59, 26, 12}})
	table.insert(_q, {walk.walk, {59, 26, 13}})
	table.insert(_q, {walk.walk, {59, 30, 13}})
	table.insert(_q, {walk.walk, {59, 30, 3}})
	table.insert(_q, {walk.walk, {62, 2, 23}})
	table.insert(_q, {walk.walk, {62, 8, 23}})
	table.insert(_q, {walk.walk, {62, 8, 5}})
	table.insert(_q, {walk.walk, {60, 6, 12}})

	-- Step Route: Castle Baron B1F
	if _route[15] == 1 then
		table.insert(_q, {walk.walk, {60, 6, 11}})
		table.insert(_q, {walk.walk, {60, 2, 11}})
		table.insert(_q, {walk.walk, {60, 2, 9}})

		for i = 1, _route[16] / 2 do
			table.insert(_q, {walk.walk, {61, 4, 10}})
			table.insert(_q, {walk.walk, {61, 4, 11}})
		end

		table.insert(_q, {walk.walk, {61, 4, 12}})
		table.insert(_q, {walk.walk, {60, 2, 11}})
		table.insert(_q, {walk.walk, {60, 6, 11}})
		table.insert(_q, {walk.walk, {60, 6, 12}})
	end

	table.insert(_q, {walk.walk, {60, 12, 12}})
	table.insert(_q, {walk.walk, {60, 12, 10}})
	table.insert(_q, {walk.walk, {60, 14, 10}})
	table.insert(_q, {walk.walk, {60, 14, 2}})
	table.insert(_q, {walk.walk, {36, 10, 2}})
	table.insert(_q, {walk.walk, {36, 0, 2}})
	table.insert(_q, {walk.walk, {36, 0, 30}})
	table.insert(_q, {walk.walk, {36, 3, 30}})
	table.insert(_q, {walk.walk, {36, 3, 19}})
	table.insert(_q, {walk.walk, {36, 8, 19}})
	table.insert(_q, {walk.walk, {36, 8, 17}})
	table.insert(_q, {walk.walk, {45, 2, 2}})
	table.insert(_q, {walk.walk, {36, 12, 13}})
	table.insert(_q, {walk.walk, {42, 1, 10}})
	table.insert(_q, {walk.walk, {42, 5, 10}})

	-- Do the pre-Baigan menu.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.TELLAH] = _RESTORE.HP}, game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.ARMS.PALADIN}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.YANG}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.CLAW.THUNDER}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.CLAW.ICECLAW}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.SILVER}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.close, {}})

	-- Engage Baigan.
	table.insert(_q, {walk.walk, {42, 6, 10}})
end

local function _sequence_kainazzo()
	-- Heal the party as needed.
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.TELLAH] = _RESTORE.HP, [game.CHARACTER.YANG] = _RESTORE.LIFE}}})
	table.insert(_q, {menu.field.change, {}})

	if not _M.state.multi_change then
		local hand, weapon = game.character.get_weapon(game.CHARACTER.PALOM)

		if weapon == game.ITEM.WEAPON.CHANGE then
			table.insert(_q, {menu.field.equip.open, {game.CHARACTER.PALOM}})
			table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.WEAPON.DANCING}})
			table.insert(_q, {menu.field.equip.close, {}})
		end
	end

	local hand, weapon = game.character.get_weapon(game.CHARACTER.CECIL)

	if weapon ~= game.ITEM.WEAPON.LEGEND then
		table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
		table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.LEGEND}})
		table.insert(_q, {menu.field.equip.close, {}})
	end

	table.insert(_q, {menu.field.close, {}})

	-- Step Route: Castle Baron
	for i = 1, _route[17] / 2 do
		table.insert(_q, {walk.walk, {42, 9, 4}})
		table.insert(_q, {walk.walk, {42, 8, 4}})
	end

	table.insert(_q, {walk.walk, {42, 8, 3}})

	if _route[17] % 2 == 1 then
		table.insert(_q, {walk.walk, {42, 9, 3}})
		table.insert(_q, {walk.walk, {42, 8, 3}})
	end

	-- Walk to Kainazzo.
	table.insert(_q, {walk.walk, {42, 8, 0}})
	table.insert(_q, {walk.walk, {43, 14, 2}})
	table.insert(_q, {walk.walk, {138, 7, 2}})
	table.insert(_q, {walk.walk, {44, 8, 4}})
	table.insert(_q, {walk.interact, {}})
end

local function _sequence_dark_elf()
	-- Fly to Toroia and visit Edward.
	table.insert(_q, {_set_healing, {_healing_dark_elf}})
	table.insert(_q, {walk.walk, {nil, 36, 83}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 36, 82}})
	table.insert(_q, {walk.walk, {nil, 35, 82}})
	table.insert(_q, {walk.walk, {39, 16, 10}})
	table.insert(_q, {walk.walk, {85, 9, 10}})

	-- Step Route: Toroian Castle
	if _route[18] >= 3 and _route[18] % 2 == 1 then
		table.insert(_q, {walk.walk, {85, 7, 10}})
		_route[18] = _route[18] - 3
	elseif _route[18] >= 2 then
		table.insert(_q, {walk.walk, {85, 9, 9}})
		table.insert(_q, {walk.walk, {85, 7, 9}})
		_route[18] = _route[18] - 2
	elseif _route[18] == 1 then
		table.insert(_q, {walk.walk, {85, 9, 8}})
		table.insert(_q, {walk.walk, {85, 7, 8}})
		_route[18] = _route[18] - 1
	else
		table.insert(_q, {walk.walk, {85, 9, 7}})
	end

	table.insert(_q, {walk.walk, {85, 7, 7}})

	for i = 1, _route[18] / 2 do
		table.insert(_q, {walk.walk, {85, 7, 8}})
		table.insert(_q, {walk.walk, {85, 7, 7}})
	end

	table.insert(_q, {walk.walk, {85, 2, 7}})
	table.insert(_q, {walk.walk, {85, 2, 10}})
	table.insert(_q, {walk.walk, {39, 6, 5}})
	table.insert(_q, {walk.walk, {39, 6, 12}})
	table.insert(_q, {walk.walk, {39, 9, 12}})
	table.insert(_q, {walk.walk, {39, 9, 11}})
	table.insert(_q, {walk.walk, {88, 3, 5}})
	table.insert(_q, {walk.walk, {88, 3, 3}})
	table.insert(_q, {walk.walk, {88, 8, 3}})
	table.insert(_q, {walk.walk, {88, 8, 4}})

	-- Cast Exit, get a black chocobo, and fly to Cave Magnes.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.item.open, {}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
	table.insert(_q, {menu.field.item.select, {game.ITEM.ITEM.ETHER1}})
	table.insert(_q, {menu.field.item.select_character, {game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.item.close, {}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})

	-- Step Route: World Map (Toroia)
	if _route[19] > 0 then
		table.insert(_q, {walk.walk, {nil, 36, 82}})
	else
		table.insert(_q, {walk.walk, {nil, 35, 70}})
	end

	table.insert(_q, {walk.walk, {nil, 36, 70}})
	table.insert(_q, {walk.walk, {nil, 43, 70}})
	table.insert(_q, {walk.walk, {nil, 43, 54}})
	table.insert(_q, {walk.walk, {nil, 41, 54}})
	table.insert(_q, {walk.walk, {nil, 41, 53}})
	table.insert(_q, {walk.walk, {33, 8, 28}})
	table.insert(_q, {walk.walk, {33, 9, 28}})
	table.insert(_q, {walk.walk, {33, 9, 27}})
	table.insert(_q, {walk.walk, {33, 10, 27}})
	table.insert(_q, {walk.walk, {33, 10, 23}})
	table.insert(_q, {walk.chase, {33, {10, 11}}})
	table.insert(_q, {walk.walk, {nil, 41, 61}})
	table.insert(_q, {walk.walk, {nil, 68, 61}})
	table.insert(_q, {walk.walk, {nil, 68, 56}})
	table.insert(_q, {walk.walk, {nil, 74, 56}})
	table.insert(_q, {walk.walk, {nil, 74, 55}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 74, 53}})

	-- Walk to the crystal room.
	table.insert(_q, {walk.walk, {140, 5, 8}})
	table.insert(_q, {walk.walk, {140, 9, 8}})
	table.insert(_q, {walk.walk, {140, 9, 5}})
	table.insert(_q, {walk.walk, {140, 16, 5}})
	table.insert(_q, {walk.walk, {140, 16, 14}})
	table.insert(_q, {walk.walk, {140, 24, 14}})
	table.insert(_q, {walk.walk, {140, 24, 26}})
	table.insert(_q, {walk.walk, {140, 10, 26}})
	table.insert(_q, {walk.walk, {140, 10, 18}})
	table.insert(_q, {walk.walk, {140, 6, 18}})
	table.insert(_q, {walk.walk, {140, 6, 19}})
	table.insert(_q, {walk.walk, {141, 27, 27}})
	table.insert(_q, {walk.walk, {141, 18, 27}})
	table.insert(_q, {walk.walk, {141, 18, 18}})
	table.insert(_q, {walk.walk, {141, 13, 18}})
	table.insert(_q, {walk.walk, {141, 13, 9}})
	table.insert(_q, {walk.walk, {141, 5, 9}})
	table.insert(_q, {walk.walk, {141, 5, 10}})
	table.insert(_q, {walk.walk, {143, 27, 9}})
	table.insert(_q, {walk.walk, {143, 22, 9}})

	-- Step Route: Cave Magnes B3F
	if _route[20] == 1 then
		table.insert(_q, {walk.walk, {143, 21, 9}})

		for i = 1, _route[21] / 2 do
			table.insert(_q, {walk.walk, {146, 6, 11}})
			table.insert(_q, {walk.walk, {146, 6, 12}})
		end

		table.insert(_q, {walk.walk, {146, 6, 13}})
		table.insert(_q, {walk.walk, {143, 22, 9}})
	end

	table.insert(_q, {walk.walk, {143, 22, 16}})
	table.insert(_q, {walk.walk, {143, 29, 16}})
	table.insert(_q, {walk.walk, {143, 29, 20}})
	table.insert(_q, {walk.walk, {143, 21, 20}})
	table.insert(_q, {walk.walk, {143, 21, 25}})
	table.insert(_q, {walk.walk, {143, 8, 25}})
	table.insert(_q, {walk.walk, {143, 8, 5}})
	table.insert(_q, {walk.walk, {145, 14, 12}})
	table.insert(_q, {walk.walk, {145, 5, 12}})
	table.insert(_q, {walk.walk, {145, 5, 14}})
	table.insert(_q, {walk.walk, {147, 22, 28}})
	table.insert(_q, {walk.walk, {147, 20, 28}})
	table.insert(_q, {walk.walk, {147, 20, 27}})
	table.insert(_q, {walk.walk, {147, 19, 27}})
	table.insert(_q, {walk.walk, {147, 19, 25}})
	table.insert(_q, {walk.walk, {147, 13, 25}})
	table.insert(_q, {walk.walk, {147, 13, 15}})

	-- Step Route: Cave Magnes B4F
	if _route[22] == 1 then
		table.insert(_q, {walk.walk, {147, 24, 15}})
		table.insert(_q, {walk.walk, {147, 24, 16}})
		table.insert(_q, {walk.walk, {147, 27, 16}})
		table.insert(_q, {walk.walk, {147, 27, 15}})

		for i = 1, _route[23] / 2 do
			table.insert(_q, {walk.walk, {161, 6, 11}})
			table.insert(_q, {walk.walk, {161, 6, 12}})
		end

		table.insert(_q, {walk.walk, {161, 6, 13}})
		table.insert(_q, {walk.walk, {147, 27, 16}})
		table.insert(_q, {walk.walk, {147, 24, 16}})
		table.insert(_q, {walk.walk, {147, 24, 15}})
		table.insert(_q, {walk.walk, {147, 13, 15}})
	end

	for i = 1, _route[24] / 2 do
		table.insert(_q, {walk.walk, {147, 12, 15}})
		table.insert(_q, {walk.walk, {147, 13, 15}})
	end

	table.insert(_q, {walk.walk, {147, 13, 7}})
	table.insert(_q, {walk.walk, {148, 11, 12}})

	-- Equip Cid and engage the Dark Elf.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CID}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.ARMS.IRON}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.CID, 0, game.FORMATION.THREE_FRONT}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.CECIL, game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.CECIL, 2}})
	table.insert(_q, {menu.field.form.move, {game.CHARACTER.YANG, 4}})
	table.insert(_q, {menu.field.close, {}})
	table.insert(_q, {menu.wait, {16}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.wait, {16}})
	table.insert(_q, {walk.walk, {148, 11, 13}})
	table.insert(_q, {walk.walk, {148, 11, 12}})
	table.insert(_q, {walk.interact, {}})
end

local function _sequence_flamedog()
	-- Collect the crystal and return to the Clerics.
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {walk.walk, {148, 11, 9}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {148, 11, 26}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.TELLAH] = _RESTORE.LIFE}}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})
	table.insert(_q, {walk.walk, {nil, 74, 55}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {33, 8, 28}})
	table.insert(_q, {walk.walk, {33, 9, 28}})
	table.insert(_q, {walk.walk, {33, 9, 27}})
	table.insert(_q, {walk.walk, {33, 10, 27}})
	table.insert(_q, {walk.walk, {33, 10, 23}})
	table.insert(_q, {walk.chase, {33, {6, 7, 8, 10, 11}}})
	table.insert(_q, {walk.walk, {nil, 41, 61}})
	table.insert(_q, {walk.walk, {nil, 43, 61}})
	table.insert(_q, {walk.walk, {nil, 43, 81}})
	table.insert(_q, {walk.walk, {nil, 36, 81}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 35, 81}})
	table.insert(_q, {walk.walk, {39, 16, 10}})
	table.insert(_q, {walk.walk, {85, 9, 10, true}})

	-- Step Route: Toroian Castle 1F
	if _route[25] == 1 then
		if _route[26] >= 3 and _route[26] % 2 == 1 then
			table.insert(_q, {walk.walk, {85, 7, 10, true}})
			_route[26] = _route[26] - 3
		elseif _route[26] >= 2 then
			table.insert(_q, {walk.walk, {85, 9, 9, true}})
			table.insert(_q, {walk.walk, {85, 7, 9, true}})
			_route[26] = _route[26] - 2
		elseif _route[26] == 1 then
			table.insert(_q, {walk.walk, {85, 9, 8, true}})
			table.insert(_q, {walk.walk, {85, 7, 8, true}})
			_route[26] = _route[26] - 1
		else
			table.insert(_q, {walk.walk, {85, 9, 7, true}})
		end

		table.insert(_q, {walk.walk, {85, 7, 7, true}})

		for i = 1, _route[26] / 2 do
			table.insert(_q, {walk.walk, {85, 6, 7}})
			table.insert(_q, {walk.walk, {85, 7, 7}})
		end

		table.insert(_q, {walk.walk, {85, 9, 7, true}})
	end

	table.insert(_q, {walk.walk, {85, 9, 0, true}})
	table.insert(_q, {walk.walk, {86, 5, 15}})

	-- Leave the castle and walk to the Fire sword chest.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.TELLAH}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})

	-- Step Route: World Map (Toroia)
	if _route[27] == 2 then
		table.insert(_q, {walk.walk, {nil, 36, 81}})
	elseif _route[27] == 1 then
		table.insert(_q, {walk.walk, {nil, 35, 82}})
		table.insert(_q, {walk.walk, {nil, 36, 82}})
	else
		table.insert(_q, {walk.walk, {nil, 35, 83}})
	end

	table.insert(_q, {_set_healing, {_healing_flamedog}})
	table.insert(_q, {walk.walk, {nil, 36, 83}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {152, 17, 24}})
	table.insert(_q, {walk.walk, {152, 17, 26}})
	table.insert(_q, {walk.walk, {152, 28, 26}})
	table.insert(_q, {walk.walk, {152, 28, 5}})
	table.insert(_q, {walk.walk, {152, 26, 5}})
	table.insert(_q, {walk.walk, {152, 26, 4}})
	table.insert(_q, {walk.walk, {153, 26, 14}})
	table.insert(_q, {walk.walk, {153, 19, 14}})
	table.insert(_q, {walk.walk, {153, 19, 21}})
	table.insert(_q, {walk.walk, {153, 17, 21}})
	table.insert(_q, {walk.walk, {153, 17, 27}})
	table.insert(_q, {walk.walk, {153, 8, 27}})
	table.insert(_q, {walk.walk, {153, 8, 15}})

	-- Heal, turn to the chest, and engage FlameDog.
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.TELLAH] = _RESTORE.ALL}, nil, true}})
	table.insert(_q, {walk.step, {walk.DIRECTION.LEFT}})
	table.insert(_q, {walk.interact, {}})
end

local function _sequence_magus_sisters()
	-- Walk to the top floor of the tower.
	table.insert(_q, {walk.walk, {153, 8, 20}})
	table.insert(_q, {walk.walk, {153, 2, 20}})
	table.insert(_q, {walk.walk, {153, 2, 13}})
	table.insert(_q, {walk.walk, {154, 1, 14}})
	table.insert(_q, {walk.walk, {154, 1, 22}})
	table.insert(_q, {walk.walk, {154, 5, 22}})
	table.insert(_q, {walk.walk, {154, 5, 26}})
	table.insert(_q, {walk.walk, {154, 12, 26}})
	table.insert(_q, {walk.walk, {154, 12, 24}})
	table.insert(_q, {walk.walk, {154, 18, 24}})
	table.insert(_q, {walk.walk, {154, 18, 25}})
	table.insert(_q, {walk.walk, {154, 22, 25}})
	table.insert(_q, {walk.walk, {154, 22, 24}})
	table.insert(_q, {walk.walk, {154, 23, 24}})
	table.insert(_q, {walk.walk, {154, 23, 22}})
	table.insert(_q, {walk.walk, {154, 24, 22}})
	table.insert(_q, {walk.walk, {154, 24, 9}})
	table.insert(_q, {walk.walk, {154, 22, 9}})
	table.insert(_q, {walk.walk, {154, 22, 7}})
	table.insert(_q, {walk.walk, {154, 21, 7}})
	table.insert(_q, {walk.walk, {154, 21, 5}})
	table.insert(_q, {walk.walk, {154, 20, 5}})
	table.insert(_q, {walk.walk, {154, 20, 4}})
	table.insert(_q, {walk.walk, {154, 5, 4}})
	table.insert(_q, {walk.walk, {154, 5, 8}})
	table.insert(_q, {walk.walk, {154, 2, 8}})
	table.insert(_q, {walk.walk, {154, 2, 7}})
	table.insert(_q, {walk.walk, {156, 4, 5}})
	table.insert(_q, {walk.walk, {156, 4, 8}})
	table.insert(_q, {walk.walk, {156, 1, 8}})
	table.insert(_q, {walk.walk, {156, 1, 21}})
	table.insert(_q, {walk.walk, {156, 2, 21}})
	table.insert(_q, {walk.walk, {156, 2, 22}})
	table.insert(_q, {walk.walk, {156, 3, 22}})
	table.insert(_q, {walk.walk, {156, 3, 23}})
	table.insert(_q, {walk.walk, {156, 4, 23}})
	table.insert(_q, {walk.walk, {156, 4, 24}})
	table.insert(_q, {walk.walk, {156, 5, 24}})
	table.insert(_q, {walk.walk, {156, 5, 25}})
	table.insert(_q, {walk.walk, {156, 12, 25}})
	table.insert(_q, {walk.walk, {156, 12, 23}})
	table.insert(_q, {walk.walk, {156, 20, 23}})
	table.insert(_q, {walk.walk, {156, 20, 25}})
	table.insert(_q, {walk.walk, {156, 24, 25}})
	table.insert(_q, {walk.walk, {156, 24, 15}})
	table.insert(_q, {walk.walk, {157, 25, 14}})
	table.insert(_q, {walk.walk, {157, 25, 22}})
	table.insert(_q, {walk.walk, {157, 19, 22}})
	table.insert(_q, {walk.walk, {157, 19, 19}})
	table.insert(_q, {walk.walk, {157, 15, 19}})

	-- Prepare the party for battle.
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.TELLAH] = _RESTORE.HP, [game.CHARACTER.YANG] = _RESTORE.LIFE}, game.CHARACTER.TELLAH, true}})

	-- Engage the sisters.
	table.insert(_q, {walk.walk, {157, 15, 17}})
end

local function _sequence_valvalis()
	-- Walk to the Golbez cut scene.
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {walk.walk, {157, 15, 15}})
	table.insert(_q, {walk.walk, {158, 10, 16}})
	table.insert(_q, {walk.walk, {158, 10, 10}})
	table.insert(_q, {walk.walk, {158, 7, 10}})
	table.insert(_q, {walk.walk, {158, 7, 9}})

	-- Talk to Kain
	table.insert(_q, {walk.walk, {158, 5, 6}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})

	-- Complete the pre-Valvalis menu.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.FIRE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.DANCING}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.ROSA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.GAEA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.GAEA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.SILVER}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.WEAPON.FIRE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.KAIN, game.CHARACTER.CECIL, game.FORMATION.THREE_FRONT}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.CECIL, game.CHARACTER.ROSA}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.LIFE, [game.CHARACTER.YANG] = _RESTORE.LIFE, [game.CHARACTER.CID] = _RESTORE.LIFE}}})
	table.insert(_q, {menu.field.close, {}})

	-- Engage Valvalis
	table.insert(_q, {walk.walk, {159, 7, 10}})
end

local function _sequence_calbrena()
	-- Leave the castle and board the airship.
	table.insert(_q, {_set_healing, {_healing_calbrena}})

	-- Step Route: Castle Baron (after Valvalis)
	while _route[28] > 0 do
		if _route[28] == 3 then
			table.insert(_q, {walk.walk, {52, 6, 5}})
			table.insert(_q, {walk.walk, {52, 8, 5}})
			table.insert(_q, {walk.walk, {52, 8, 4}})
			_route[28] = 0
		elseif _route[28] >= 2 then
			table.insert(_q, {walk.walk, {52, 5, 4}})
			table.insert(_q, {walk.walk, {52, 6, 4}})
			_route[28] = _route[28] - 2
		elseif _route[28] == 1 then
			table.insert(_q, {walk.walk, {52, 7, 4}})
			table.insert(_q, {walk.walk, {52, 7, 5}})
			table.insert(_q, {walk.walk, {52, 7, 4}})
			_route[28] = 0
		end
	end

	table.insert(_q, {walk.walk, {52, 9, 4}})
	table.insert(_q, {walk.walk, {51, 5, 4}})
	table.insert(_q, {walk.walk, {50, 5, 9}})
	table.insert(_q, {walk.walk, {36, 6, 18}})
	table.insert(_q, {walk.walk, {36, 8, 18}})
	table.insert(_q, {walk.walk, {36, 8, 17}})
	table.insert(_q, {walk.walk, {45, 2, 2}})
	table.insert(_q, {walk.walk, {36, 12, 13}})
	table.insert(_q, {walk.walk, {42, 1, 10}})
	table.insert(_q, {walk.walk, {42, 8, 10}})
	table.insert(_q, {walk.walk, {42, 8, 15}})
	table.insert(_q, {walk.walk, {36, 15, 31}})
	table.insert(_q, {walk.board, {}})

	-- Fly to Agart and use the Magma stone.
	table.insert(_q, {walk.walk, {nil, 105, 215}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 104, 215}})
	table.insert(_q, {walk.walk, {6, 16, 22}})
	table.insert(_q, {walk.walk, {6, 15, 22}})
	table.insert(_q, {walk.walk, {6, 15, 21}})
	table.insert(_q, {walk.walk, {139, 9, 10}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.MAGMA}})

	-- Leave Agart and fly to the underground.
	table.insert(_q, {walk.walk, {139, 9, 14}})
	table.insert(_q, {walk.walk, {6, 15, 31}})
	table.insert(_q, {walk.walk, {nil, 105, 215}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 105, 212}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 100, 82}})
	table.insert(_q, {walk.walk, {263, 15, 19}})
	table.insert(_q, {walk.walk, {264, 11, 1, true}})

	-- Swap party formation.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.CID, game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.ROSA, game.CHARACTER.CID}})
	table.insert(_q, {menu.field.close, {}})

	-- Talk to King Giott.
	table.insert(_q, {walk.walk, {265, 10, 11}})
end

local function _sequence_dr_lugae()
	-- Cast Warp and get the crystal.
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.RYDIA] = _RESTORE.LIFE}}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.BLACK.WARP}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.BLACK.WARP}})
	table.insert(_q, {menu.field.close, {}})
	table.insert(_q, {walk.walk, {269, 9, 8}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to the right tower and collect the Strength ring.
	table.insert(_q, {walk.walk, {269, 9, 20}})
	table.insert(_q, {walk.walk, {265, 8, 1}})
	table.insert(_q, {walk.walk, {265, 8, 6}})

	-- Step Route: Castle of Dwarves A
	if _route[29] >= 2 then
		table.insert(_q, {walk.walk, {265, 8, 10}})
		_route[29] = _route[29] - 2
	elseif _route[29] == 1 then
		table.insert(_q, {walk.walk, {265, 9, 6}})
		table.insert(_q, {walk.walk, {265, 9, 10}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {265, 10, 6}})
	end

	table.insert(_q, {walk.walk, {265, 10, 10}})
	table.insert(_q, {walk.walk, {265, 10, 15}})
	table.insert(_q, {walk.walk, {264, 11, 7}})

	-- Step Route: Castle of Dwarves B
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {264, 16, 7, true}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {264, 11, 8, true}})
	end

	table.insert(_q, {walk.walk, {264, 16, 8, true}})
	table.insert(_q, {walk.walk, {264, 21, 6, true}})
	table.insert(_q, {walk.walk, {270, 1, 9, true}})
	table.insert(_q, {walk.walk, {270, 3, 9, true}})

	-- Step Route: Castle of Dwarves C
	if _route[29] >= 10 then
		table.insert(_q, {walk.walk, {270, 11, 9, true}})
		table.insert(_q, {walk.walk, {270, 11, 7, true}})
		_route[29] = _route[29] - 10
	else
		if _route[29] == 9 then
			-- 9 steps is the default if we don't reposition.
		elseif _route[29] == 8 then
			table.insert(_q, {walk.walk, {270, 12, 9, true}})
			table.insert(_q, {walk.walk, {270, 12, 8, true}})
		elseif _route[29] == 7 then
			table.insert(_q, {walk.walk, {270, 10, 9, true}})
			table.insert(_q, {walk.walk, {270, 10, 6, true}})
		elseif _route[29] == 6 then
			table.insert(_q, {walk.walk, {270, 9, 9, true}})
			table.insert(_q, {walk.walk, {270, 9, 6, true}})
		elseif _route[29] == 5 then
			table.insert(_q, {walk.walk, {270, 3, 7, true}})
			table.insert(_q, {walk.walk, {270, 7, 7, true}})
			table.insert(_q, {walk.walk, {270, 7, 6, true}})
		elseif _route[29] == 4 then
			table.insert(_q, {walk.walk, {270, 7, 9, true}})
			table.insert(_q, {walk.walk, {270, 7, 6, true}})
		elseif _route[29] == 3 then
			table.insert(_q, {walk.walk, {270, 6, 9, true}})
			table.insert(_q, {walk.walk, {270, 6, 6, true}})
		elseif _route[29] == 2 then
			table.insert(_q, {walk.walk, {270, 5, 9, true}})
			table.insert(_q, {walk.walk, {270, 5, 6, true}})
		elseif _route[29] == 1 then
			table.insert(_q, {walk.walk, {270, 3, 8, true}})
			table.insert(_q, {walk.walk, {270, 4, 8, true}})
			table.insert(_q, {walk.walk, {270, 4, 6, true}})
		else
			table.insert(_q, {walk.walk, {270, 4, 9, true}})
			table.insert(_q, {walk.walk, {270, 4, 6, true}})
		end

		_route[29] = 0
	end

	table.insert(_q, {walk.walk, {270, 13, 4, true}})
	table.insert(_q, {walk.walk, {272, 10, 8}})
	table.insert(_q, {walk.walk, {272, 8, 8}})

	-- Step Route: Castle of Dwarves D
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {272, 8, 7}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {272, 6, 8}})
	end

	table.insert(_q, {walk.walk, {272, 6, 7}})
	table.insert(_q, {walk.walk, {272, 6, 5}})
	table.insert(_q, {walk.walk, {283, 24, 23}})
	table.insert(_q, {walk.walk, {281, 6, 4}})
	table.insert(_q, {walk.interact, {}})

	-- Walk back to the shop and purchase Rune rings.
	table.insert(_q, {walk.walk, {281, 6, 7}})
	table.insert(_q, {walk.walk, {283, 24, 21}})
	table.insert(_q, {walk.walk, {272, 6, 7}})

	-- Step Route: Castle of Dwarves E
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {272, 8, 7}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {272, 6, 8}})
	end

	table.insert(_q, {walk.walk, {272, 8, 8}})
	table.insert(_q, {walk.walk, {272, 10, 8}})
	table.insert(_q, {walk.walk, {272, 10, 10}})
	table.insert(_q, {walk.walk, {270, 13, 6}})
	table.insert(_q, {walk.walk, {270, 10, 6}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.shop.buy.open, {1}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.RING.RUNE}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Exit the dwarf castle.
	table.insert(_q, {walk.walk, {270, 2, 6, true}})

	-- Step Route: Castle of Dwarves F
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {270, 2, 5, true}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {270, 1, 6, true}})
	end

	table.insert(_q, {walk.walk, {270, 1, 4, true}})
	table.insert(_q, {walk.walk, {266, 15, 8}})
	table.insert(_q, {walk.walk, {266, 15, 4}})
	table.insert(_q, {walk.walk, {266, 14, 4}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {266, 14, 0}})
	table.insert(_q, {walk.walk, {266, 11, 0}})
	table.insert(_q, {walk.walk, {267, 28, 9}})
	table.insert(_q, {walk.walk, {267, 28, 8}})
	table.insert(_q, {walk.walk, {267, 25, 8}})
	table.insert(_q, {walk.walk, {267, 25, 9}})
	table.insert(_q, {walk.walk, {267, 23, 9}})
	table.insert(_q, {walk.walk, {267, 23, 10}})
	table.insert(_q, {walk.walk, {267, 22, 10}})
	table.insert(_q, {walk.walk, {267, 22, 11}})
	table.insert(_q, {walk.walk, {267, 11, 11}})

	-- Step Route: Castle of Dwarves G
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {267, 11, 12}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {267, 10, 11}})
	end

	table.insert(_q, {walk.walk, {267, 10, 12}})
	table.insert(_q, {walk.walk, {267, 10, 14}})

	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {267, 11, 14}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {267, 10, 17}})
	end

	table.insert(_q, {walk.walk, {267, 11, 17}})
	table.insert(_q, {walk.walk, {267, 11, 26}})
	table.insert(_q, {walk.walk, {267, 5, 26}})
	table.insert(_q, {walk.walk, {267, 5, 27}})
	table.insert(_q, {walk.walk, {267, 2, 27}})

	-- Step Route: Castle of Dwarves H
	if _route[29] >= 1 then
		table.insert(_q, {walk.walk, {271, 29, 6}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {271, 28, 5}})
	end

	table.insert(_q, {walk.walk, {271, 28, 6}})

	if _route[29] % 2 == 1 then
		table.insert(_q, {walk.walk, {271, 27, 6}})
		table.insert(_q, {walk.walk, {271, 27, 8}})
		_route[29] = _route[29] - 1
	else
		table.insert(_q, {walk.walk, {271, 28, 8}})
	end

	table.insert(_q, {walk.walk, {271, 26, 8}})
	table.insert(_q, {walk.walk, {271, 10, 8}})
	table.insert(_q, {walk.walk, {271, 10, 12}})
	table.insert(_q, {walk.walk, {271, 3, 12}})
	table.insert(_q, {walk.walk, {271, 3, 7}})
	table.insert(_q, {walk.step, {walk.DIRECTION.LEFT}})
	table.insert(_q, {walk.interact, {}})

	for i = 1, _route[29] / 2 do
		table.insert(_q, {walk.walk, {271, 3, 6}})
		table.insert(_q, {walk.walk, {271, 3, 7}})
	end

	table.insert(_q, {walk.walk, {271, 3, 14, true}})
	table.insert(_q, {_set_healing, {_healing_dr_lugae}})

	-- Walk to the Tower of Bab-il
	table.insert(_q, {walk.walk, {nil, 91, 85}})
	table.insert(_q, {walk.walk, {nil, 82, 85}})
	table.insert(_q, {walk.walk, {nil, 82, 83}})
	table.insert(_q, {walk.walk, {nil, 80, 83}})
	table.insert(_q, {walk.walk, {nil, 80, 79}})
	table.insert(_q, {walk.walk, {nil, 71, 79}})
	table.insert(_q, {walk.walk, {nil, 71, 78}})
	table.insert(_q, {walk.walk, {nil, 70, 78}})
	table.insert(_q, {walk.walk, {nil, 70, 76}})
	table.insert(_q, {walk.walk, {nil, 54, 76}})
	table.insert(_q, {walk.walk, {nil, 54, 53}})
	table.insert(_q, {walk.walk, {nil, 48, 53}})
	table.insert(_q, {walk.walk, {nil, 48, 24}})
	table.insert(_q, {walk.walk, {nil, 54, 24}})
	table.insert(_q, {walk.walk, {nil, 54, 21}})
	table.insert(_q, {walk.walk, {nil, 55, 21}})
	table.insert(_q, {walk.walk, {nil, 55, 18}})
	table.insert(_q, {walk.walk, {nil, 54, 18}})
	table.insert(_q, {walk.walk, {nil, 54, 16}})
	table.insert(_q, {walk.walk, {nil, 49, 16}})
	table.insert(_q, {walk.walk, {nil, 49, 15}})

	-- Walk to the CatClaw.
	table.insert(_q, {walk.walk, {289, 15, 4}})
	table.insert(_q, {walk.walk, {290, 15, 6}})
	table.insert(_q, {walk.walk, {290, 12, 6}})
	table.insert(_q, {walk.walk, {290, 12, 23}})
	table.insert(_q, {walk.walk, {290, 18, 23}})
	table.insert(_q, {walk.walk, {290, 18, 17}})
	table.insert(_q, {walk.walk, {290, 17, 17}})
	table.insert(_q, {walk.walk, {290, 17, 16}})
	table.insert(_q, {walk.walk, {290, 16, 16}})
	table.insert(_q, {walk.walk, {290, 16, 13}})
	table.insert(_q, {walk.walk, {291, 21, 14}})
	table.insert(_q, {walk.walk, {291, 21, 6}})
	table.insert(_q, {walk.walk, {291, 19, 6}})
	table.insert(_q, {walk.walk, {291, 19, 5}})
	table.insert(_q, {walk.walk, {291, 13, 5}})
	table.insert(_q, {walk.walk, {291, 13, 10}})
	table.insert(_q, {walk.interact, {"Found"}})

	-- Walk to the top floor, just before Dr.Lugae.
	table.insert(_q, {walk.walk, {291, 13, 6}})
	table.insert(_q, {walk.walk, {291, 9, 6}})
	table.insert(_q, {walk.walk, {291, 9, 7}})
	table.insert(_q, {walk.walk, {291, 8, 7}})
	table.insert(_q, {walk.walk, {291, 8, 10}})
	table.insert(_q, {walk.walk, {291, 6, 10}})
	table.insert(_q, {walk.walk, {291, 6, 19}})
	table.insert(_q, {walk.walk, {291, 7, 19}})
	table.insert(_q, {walk.walk, {291, 7, 20}})
	table.insert(_q, {walk.walk, {291, 12, 20}})
	table.insert(_q, {walk.walk, {291, 12, 19}})
	table.insert(_q, {walk.walk, {292, 8, 20}})
	table.insert(_q, {walk.walk, {292, 8, 10}})
	table.insert(_q, {walk.walk, {292, 24, 10}})
	table.insert(_q, {walk.walk, {292, 24, 4}})
	table.insert(_q, {walk.walk, {292, 21, 4}})
	table.insert(_q, {walk.walk, {292, 21, 6}})
	table.insert(_q, {walk.walk, {292, 7, 6}})
	table.insert(_q, {walk.walk, {292, 7, 7}})
	table.insert(_q, {walk.walk, {292, 6, 7}})
	table.insert(_q, {walk.walk, {292, 6, 9}})
	table.insert(_q, {walk.walk, {292, 3, 9}})
	table.insert(_q, {walk.walk, {292, 3, 8}})
	table.insert(_q, {walk.walk, {293, 2, 9}})
	table.insert(_q, {walk.walk, {293, 2, 22}})
	table.insert(_q, {walk.walk, {293, 9, 22}})
	table.insert(_q, {walk.walk, {293, 9, 24}})
	table.insert(_q, {walk.walk, {293, 23, 24}})
	table.insert(_q, {walk.walk, {293, 23, 19}})
	table.insert(_q, {walk.walk, {293, 25, 19}})
	table.insert(_q, {walk.walk, {293, 25, 5}})
	table.insert(_q, {walk.walk, {294, 14, 6}})
	table.insert(_q, {walk.walk, {294, 14, 4}})
	table.insert(_q, {walk.walk, {295, 18, 5}})
	table.insert(_q, {walk.walk, {295, 18, 15}})
	table.insert(_q, {walk.walk, {295, 21, 15}})
	table.insert(_q, {walk.walk, {295, 21, 25}})
	table.insert(_q, {walk.walk, {295, 27, 25}})
	table.insert(_q, {walk.walk, {295, 27, 18}})
	table.insert(_q, {walk.walk, {295, 29, 18}})
	table.insert(_q, {walk.walk, {295, 29, 16}})
	table.insert(_q, {walk.walk, {296, 25, 17}})
	table.insert(_q, {walk.walk, {296, 25, 25}})
	table.insert(_q, {walk.walk, {296, 16, 25}})
	table.insert(_q, {walk.walk, {296, 16, 21}})

	-- Do the pre-Dr.Lugae menu.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.YANG}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.CLAW.CATCLAW}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.CLAW.CATCLAW}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.STRENGTH}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.TIARA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.PRISONER}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.RUNE}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.KAIN, game.CHARACTER.YANG}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.KAIN] = _RESTORE.HP, [game.CHARACTER.ROSA] = _RESTORE.HP, [game.CHARACTER.RYDIA] = _RESTORE.ALL, [game.CHARACTER.YANG] = _RESTORE.HP}}})
	table.insert(_q, {menu.field.close, {}})

	-- Advance on Dr.Lugae.
	table.insert(_q, {walk.walk, {296, 16, 20}})
end

local function _sequence_dark_imps()
	-- Walk to the Dark Imps.
	table.insert(_q, {walk.walk, {296, 16, 25}})
	table.insert(_q, {walk.walk, {296, 28, 25}})
	table.insert(_q, {walk.walk, {296, 28, 17}})
	table.insert(_q, {walk.walk, {296, 29, 17}})
	table.insert(_q, {walk.walk, {296, 29, 16}})
	table.insert(_q, {walk.walk, {295, 29, 19}})
	table.insert(_q, {walk.walk, {295, 26, 19}})
	table.insert(_q, {walk.walk, {295, 26, 25}})
	table.insert(_q, {walk.walk, {295, 21, 25}})
	table.insert(_q, {walk.walk, {295, 21, 14}})
	table.insert(_q, {walk.walk, {295, 17, 14}})
	table.insert(_q, {walk.walk, {295, 17, 5}})
	table.insert(_q, {walk.walk, {295, 14, 5}})
	table.insert(_q, {walk.walk, {295, 14, 4}})
	table.insert(_q, {walk.walk, {294, 14, 6}})
	table.insert(_q, {walk.walk, {294, 25, 6}})
	table.insert(_q, {walk.walk, {294, 25, 5}})
	table.insert(_q, {walk.walk, {293, 25, 22}})
	table.insert(_q, {walk.walk, {293, 23, 22}})
	table.insert(_q, {walk.walk, {293, 23, 24}})
	table.insert(_q, {walk.walk, {293, 16, 24}})
	table.insert(_q, {walk.walk, {293, 16, 10}})
	table.insert(_q, {menu.dialog.open, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.TOWER}})
	table.insert(_q, {walk.walk, {293, 16, 9}})

	if game.character.get_stat(game.CHARACTER.ROSA, "level") < 20 then
		table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.LIFE, [game.CHARACTER.KAIN] = _RESTORE.LIFE, [game.CHARACTER.ROSA] = _RESTORE.LIFE, [game.CHARACTER.YANG] = _RESTORE.LIFE}, nil, true}})
	else
		table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.LIFE, [game.CHARACTER.KAIN] = _RESTORE.LIFE, [game.CHARACTER.YANG] = _RESTORE.LIFE}, nil, true}})
	end

	table.insert(_q, {walk.walk, {301, 5, 10}})
end

local function _sequence_edge()
	-- Leave the Tower of Bab-il.
	table.insert(_q, {_set_healing, {_healing_edge}})
	table.insert(_q, {walk.walk, {293, 16, 24}})
	table.insert(_q, {walk.walk, {293, 7, 24}})
	table.insert(_q, {walk.walk, {293, 7, 22}})
	table.insert(_q, {walk.walk, {293, 2, 22}})
	table.insert(_q, {walk.walk, {293, 2, 9}})
	table.insert(_q, {walk.walk, {293, 3, 9}})
	table.insert(_q, {walk.walk, {293, 3, 8}})
	table.insert(_q, {walk.walk, {292, 6, 9}})
	table.insert(_q, {walk.walk, {292, 6, 7}})
	table.insert(_q, {walk.walk, {292, 10, 7}})
	table.insert(_q, {walk.walk, {292, 10, 6}})
	table.insert(_q, {walk.walk, {292, 21, 6}})
	table.insert(_q, {walk.walk, {292, 21, 4}})
	table.insert(_q, {walk.walk, {292, 24, 4}})
	table.insert(_q, {walk.walk, {292, 24, 10}})
	table.insert(_q, {walk.walk, {292, 8, 10}})
	table.insert(_q, {walk.walk, {292, 8, 20}})
	table.insert(_q, {walk.walk, {292, 12, 20}})
	table.insert(_q, {walk.walk, {292, 12, 19}})
	table.insert(_q, {walk.walk, {291, 7, 20}})
	table.insert(_q, {walk.walk, {291, 7, 17}})
	table.insert(_q, {walk.walk, {291, 6, 17}})
	table.insert(_q, {walk.walk, {291, 6, 10}})
	table.insert(_q, {walk.walk, {291, 8, 10}})
	table.insert(_q, {walk.walk, {291, 8, 7}})
	table.insert(_q, {walk.walk, {291, 9, 7}})
	table.insert(_q, {walk.walk, {291, 9, 6}})
	table.insert(_q, {walk.walk, {291, 13, 6}})
	table.insert(_q, {walk.walk, {291, 13, 5}})
	table.insert(_q, {walk.walk, {291, 19, 5}})
	table.insert(_q, {walk.walk, {291, 19, 6}})
	table.insert(_q, {walk.walk, {291, 21, 6}})
	table.insert(_q, {walk.walk, {291, 21, 14}})
	table.insert(_q, {walk.walk, {291, 16, 14}})
	table.insert(_q, {walk.walk, {291, 16, 13}})
	table.insert(_q, {walk.walk, {290, 17, 14}})
	table.insert(_q, {walk.walk, {290, 17, 17}})
	table.insert(_q, {walk.walk, {290, 18, 17}})
	table.insert(_q, {walk.walk, {290, 18, 23}})
	table.insert(_q, {walk.walk, {290, 12, 23}})
	table.insert(_q, {walk.walk, {290, 12, 6}})
	table.insert(_q, {walk.walk, {290, 15, 6}})
	table.insert(_q, {walk.walk, {290, 15, 4}})
	table.insert(_q, {walk.walk, {289, 15, 21}})

	-- Fly to Castle Baron and get the hook installed.
	table.insert(_q, {walk.walk, {nil, 102, 158}})
	table.insert(_q, {walk.interact, {}})
	-- TODO: See if there's a better way to do this.
	table.insert(_q, {menu.wait, {240}})
	table.insert(_q, {walk.walk, {nil, 102, 157}})
	table.insert(_q, {walk.walk, {36, 16, 29}})
	table.insert(_q, {walk.walk, {36, 14, 29}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {36, 15, 29}})
	table.insert(_q, {walk.walk, {36, 15, 18}})
	table.insert(_q, {walk.walk, {36, 14, 18}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {36, 15, 18}})
	table.insert(_q, {walk.walk, {36, 15, 15}})

	-- Step Route: Castle of Baron (airship hook)
	for i = 1, _route[30] / 2 do
		table.insert(_q, {walk.walk, {42, 9, 12}})
		table.insert(_q, {walk.walk, {42, 8, 12}})
	end

	if _route[30] % 2 == 1 then
		table.insert(_q, {walk.walk, {42, 8, 13}})
	end

	table.insert(_q, {walk.walk, {42, 8, 10}})
	table.insert(_q, {walk.walk, {42, 16, 10}})
	table.insert(_q, {walk.walk, {36, 23, 13}})
	table.insert(_q, {walk.walk, {36, 23, 14}})
	table.insert(_q, {walk.walk, {36, 28, 14}})
	table.insert(_q, {walk.walk, {46, 18, 12}})
	table.insert(_q, {walk.walk, {36, 24, 19}})
	table.insert(_q, {walk.interact, {}})

	-- Get the hovercraft and head to the shop in Cave Eblana.
	table.insert(_q, {walk.walk, {nil, 151, 49}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 34, 237}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 35, 237}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 34, 237}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 34, 239}})
	table.insert(_q, {walk.walk, {nil, 28, 239}})
	table.insert(_q, {walk.walk, {nil, 28, 237}})
	table.insert(_q, {walk.walk, {nil, 24, 237}})
	table.insert(_q, {walk.walk, {nil, 24, 232}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 24, 231}})
	table.insert(_q, {walk.walk, {199, 10, 10}})
	table.insert(_q, {walk.walk, {199, 12, 10}})
	table.insert(_q, {walk.walk, {199, 12, 12}})
	table.insert(_q, {walk.walk, {199, 8, 12}})
	table.insert(_q, {walk.walk, {199, 8, 15}})
	table.insert(_q, {walk.walk, {199, 11, 15}})
	table.insert(_q, {walk.walk, {199, 11, 23}})
	table.insert(_q, {walk.walk, {199, 10, 23}})
	table.insert(_q, {walk.walk, {199, 10, 24}})
	table.insert(_q, {walk.walk, {199, 9, 24}})
	table.insert(_q, {walk.walk, {199, 9, 28}})
	table.insert(_q, {walk.walk, {199, 3, 28}})
	table.insert(_q, {walk.walk, {199, 3, 30}})
	table.insert(_q, {walk.walk, {200, 27, 9}})
	table.insert(_q, {walk.walk, {200, 25, 9}})
	table.insert(_q, {walk.walk, {200, 25, 10}})
	table.insert(_q, {walk.walk, {200, 17, 10}})
	table.insert(_q, {walk.walk, {200, 17, 7}})

	-- Buy weapons and armor.
	table.insert(_q, {walk.walk, {204, 9, 5}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.shop.buy.open, {1}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.SHIELD.ICE}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})
	table.insert(_q, {walk.walk, {204, 5, 5}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.shop.buy.open, {1}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.WEAPON.ICEBRAND}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.WEAPON.BLIZZARD}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Step Route: Cave Eblana B2F
	if _route[31] % 2 == 1 then
		table.insert(_q, {walk.walk, {204, 8, 5}})
		table.insert(_q, {walk.walk, {204, 8, 9}})
		_route[31] = _route[31] - 1
	elseif _route[31] >= 2 then
		table.insert(_q, {walk.walk, {204, 7, 9}})
		_route[31] = _route[31] - 2
	else
		table.insert(_q, {walk.walk, {204, 9, 5}})
	end

	table.insert(_q, {walk.walk, {204, 9, 9}})

	for i = 1, _route[31] / 2 do
		table.insert(_q, {walk.walk, {204, 8, 9}})
		table.insert(_q, {walk.walk, {204, 9, 9}})
	end

	-- Continue walking to the meeting with Edge.
	table.insert(_q, {walk.walk, {204, 9, 14}})
	table.insert(_q, {walk.walk, {200, 17, 13}})
	table.insert(_q, {walk.walk, {200, 13, 13}})
	table.insert(_q, {walk.walk, {200, 13, 9}})
	table.insert(_q, {walk.walk, {200, 9, 9}})
	table.insert(_q, {walk.walk, {200, 9, 3}})
	table.insert(_q, {walk.walk, {201, 7, 28}})
	table.insert(_q, {walk.walk, {201, 4, 28}})
	table.insert(_q, {walk.walk, {201, 4, 25}})
	table.insert(_q, {walk.walk, {201, 2, 25}})
	table.insert(_q, {walk.walk, {201, 2, 22}})
	table.insert(_q, {walk.walk, {201, 1, 22}})
	table.insert(_q, {walk.walk, {201, 1, 18}})
	table.insert(_q, {walk.walk, {201, 2, 18}})
	table.insert(_q, {walk.walk, {201, 2, 11}})
	table.insert(_q, {walk.walk, {201, 6, 11}})
	table.insert(_q, {walk.walk, {201, 6, 8}})
	table.insert(_q, {walk.walk, {202, 3, 25}})
	table.insert(_q, {walk.walk, {202, 2, 25}})
	table.insert(_q, {walk.walk, {202, 2, 20}})
	table.insert(_q, {walk.walk, {202, 6, 20}})
	table.insert(_q, {walk.walk, {202, 6, 17}})
	table.insert(_q, {walk.walk, {202, 12, 17}})
	table.insert(_q, {walk.walk, {202, 12, 18}})
	table.insert(_q, {walk.walk, {202, 13, 18}})
	table.insert(_q, {walk.walk, {202, 13, 24}})
	table.insert(_q, {walk.walk, {202, 11, 24}})
	table.insert(_q, {walk.walk, {202, 11, 27}})
	table.insert(_q, {walk.walk, {201, 15, 20}})
	table.insert(_q, {walk.walk, {201, 22, 20}})
	table.insert(_q, {walk.walk, {201, 22, 28}})
	table.insert(_q, {walk.walk, {201, 24, 28}})
	table.insert(_q, {walk.walk, {201, 24, 29}})
	table.insert(_q, {walk.walk, {201, 26, 29}})
	table.insert(_q, {walk.walk, {201, 26, 17}})
	table.insert(_q, {walk.walk, {201, 25, 17}})
	table.insert(_q, {walk.walk, {201, 25, 15}})
	table.insert(_q, {walk.walk, {201, 23, 15}})
	table.insert(_q, {walk.walk, {201, 23, 7}})
	table.insert(_q, {walk.walk, {201, 22, 7}})
	table.insert(_q, {walk.walk, {201, 22, 5}})
	table.insert(_q, {walk.walk, {201, 25, 5}})
	table.insert(_q, {walk.walk, {201, 25, 3}})
	table.insert(_q, {walk.walk, {202, 26, 24}})
	table.insert(_q, {walk.walk, {202, 27, 24}})

	-- Step Route: Pass to Bab-il 2
	if _route[32] == 1 then
		table.insert(_q, {walk.walk, {202, 29, 24}})
		table.insert(_q, {walk.walk, {202, 29, 23}})

		for i = 1, _route[33] / 2 do
			table.insert(_q, {walk.walk, {205, 4, 10}})
			table.insert(_q, {walk.walk, {205, 4, 11}})
		end

		table.insert(_q, {walk.walk, {205, 4, 12}})
		table.insert(_q, {walk.walk, {202, 29, 24}})
		table.insert(_q, {walk.walk, {202, 27, 24}})
	end

	table.insert(_q, {walk.walk, {202, 27, 18}})
	table.insert(_q, {walk.walk, {202, 26, 18}})
	table.insert(_q, {walk.walk, {202, 26, 12}})
	table.insert(_q, {walk.walk, {202, 27, 12}})
	table.insert(_q, {walk.walk, {202, 27, 8}})
	table.insert(_q, {walk.walk, {202, 24, 8}})
end

local function _sequence_rubicant()
	-- Equip the CatClaws on Edge and change party formation.
	table.insert(_q, {_set_healing, {_healing_rubicant}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.EDGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.CLAW.CATCLAW}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.L_HAND, game.ITEM.CLAW.CATCLAW}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.RYDIA, game.CHARACTER.EDGE}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.EDGE, game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.KAIN, game.CHARACTER.ROSA}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to the top of the tower.
	table.insert(_q, {walk.walk, {202, 22, 2}})
	table.insert(_q, {walk.walk, {167, 28, 6}})
	table.insert(_q, {walk.walk, {167, 22, 6}})
	table.insert(_q, {walk.walk, {167, 22, 10}})
	table.insert(_q, {walk.walk, {167, 14, 10}})
	table.insert(_q, {walk.walk, {167, 14, 6}})
	table.insert(_q, {walk.walk, {167, 12, 6}})
	table.insert(_q, {walk.walk, {167, 12, 4}})
	table.insert(_q, {walk.walk, {167, 6, 4}})
	table.insert(_q, {walk.walk, {167, 6, 5}})
	table.insert(_q, {walk.walk, {167, 4, 5}})
	table.insert(_q, {walk.walk, {167, 4, 6}})
	table.insert(_q, {walk.walk, {167, 3, 6}})
	table.insert(_q, {walk.walk, {167, 3, 10}})
	table.insert(_q, {walk.walk, {167, 7, 10}})
	table.insert(_q, {walk.walk, {167, 7, 13}})
	table.insert(_q, {walk.walk, {167, 5, 13}})
	table.insert(_q, {walk.walk, {167, 5, 21}})
	table.insert(_q, {walk.walk, {167, 12, 21}})
	table.insert(_q, {walk.walk, {167, 12, 20}})
	table.insert(_q, {walk.walk, {167, 21, 20}})
	table.insert(_q, {walk.walk, {167, 21, 19}})
	table.insert(_q, {walk.walk, {168, 27, 20}})
	table.insert(_q, {walk.walk, {168, 27, 8}})
	table.insert(_q, {walk.walk, {168, 25, 8}})
	table.insert(_q, {walk.walk, {168, 25, 6}})
	table.insert(_q, {walk.walk, {168, 24, 6}})
	table.insert(_q, {walk.walk, {168, 24, 5}})
	table.insert(_q, {walk.walk, {168, 22, 5}})
	table.insert(_q, {walk.walk, {168, 22, 4}})
	table.insert(_q, {walk.walk, {168, 16, 4}})
	table.insert(_q, {walk.walk, {168, 16, 6}})
	table.insert(_q, {walk.walk, {168, 12, 6}})
	table.insert(_q, {walk.walk, {168, 12, 4}})
	table.insert(_q, {walk.walk, {168, 6, 4}})
	table.insert(_q, {walk.walk, {168, 6, 5}})
	table.insert(_q, {walk.walk, {168, 4, 5}})
	table.insert(_q, {walk.walk, {168, 4, 6}})
	table.insert(_q, {walk.walk, {168, 3, 6}})
	table.insert(_q, {walk.walk, {168, 3, 8}})
	table.insert(_q, {walk.walk, {168, 1, 8}})
	table.insert(_q, {walk.walk, {168, 1, 20}})
	table.insert(_q, {walk.walk, {168, 7, 20}})
	table.insert(_q, {walk.walk, {168, 7, 19}})
	table.insert(_q, {walk.walk, {169, 6, 26}})
	table.insert(_q, {walk.walk, {169, 13, 26}})
	table.insert(_q, {walk.walk, {169, 13, 25}})
	table.insert(_q, {walk.walk, {170, 20, 26}})
	table.insert(_q, {walk.walk, {170, 20, 24}})
	table.insert(_q, {walk.walk, {170, 23, 24}})
	table.insert(_q, {walk.walk, {170, 23, 14}})
	table.insert(_q, {walk.walk, {170, 16, 14}})
	table.insert(_q, {walk.walk, {170, 16, 6}})
	table.insert(_q, {walk.walk, {170, 11, 6}})
	table.insert(_q, {walk.walk, {170, 11, 11}})
	table.insert(_q, {walk.walk, {170, 10, 11}})
	table.insert(_q, {walk.walk, {170, 10, 16}})
	table.insert(_q, {walk.walk, {170, 3, 16}})
	table.insert(_q, {walk.walk, {170, 3, 7}})
	table.insert(_q, {walk.walk, {169, 5, 8}})
	table.insert(_q, {walk.walk, {169, 5, 4}})
	table.insert(_q, {walk.walk, {169, 8, 4}})
	table.insert(_q, {walk.walk, {169, 8, 10}})
	table.insert(_q, {walk.walk, {169, 10, 10}})
	table.insert(_q, {walk.walk, {169, 10, 6}})
	table.insert(_q, {walk.walk, {169, 17, 6}})
	table.insert(_q, {walk.walk, {169, 17, 10}})
	table.insert(_q, {walk.walk, {169, 24, 10}})
	table.insert(_q, {walk.walk, {169, 24, 7}})
	table.insert(_q, {walk.walk, {170, 20, 8}})
	table.insert(_q, {walk.walk, {170, 20, 7}})
	table.insert(_q, {walk.walk, {172, 21, 8}})
	table.insert(_q, {walk.walk, {172, 21, 24}})
	table.insert(_q, {walk.walk, {172, 14, 24}})
	table.insert(_q, {walk.walk, {172, 14, 20}})

	-- After the Eblan battle, talk to Rubicant.
	table.insert(_q, {walk.interact, {"Rubicant:Now"}})
end

local function _sequence_monsters()
	-- Exit the Tower of Bab-il.
	table.insert(_q, {walk.walk, {172, 14, 15}})
	table.insert(_q, {walk.walk, {171, 16, 20}})
	table.insert(_q, {walk.walk, {171, 16, 20}})
	table.insert(_q, {walk.walk, {285, 6, 21}})
	table.insert(_q, {walk.walk, {285, 2, 21}})
	table.insert(_q, {walk.walk, {285, 2, 20}})
	table.insert(_q, {walk.walk, {286, 7, 21}})
	table.insert(_q, {walk.walk, {286, 7, 12}})
	table.insert(_q, {walk.walk, {286, 10, 12}})
	table.insert(_q, {walk.walk, {286, 10, 4}})
	table.insert(_q, {walk.walk, {287, 10, 10}})
	table.insert(_q, {walk.walk, {287, 12, 10}})
	table.insert(_q, {walk.walk, {287, 12, 11}})
	table.insert(_q, {walk.walk, {287, 16, 11}})
	table.insert(_q, {walk.walk, {287, 16, 12}})
	table.insert(_q, {walk.walk, {287, 19, 12}})
	table.insert(_q, {walk.walk, {287, 19, 13}})
	table.insert(_q, {walk.walk, {287, 21, 13}})
	table.insert(_q, {walk.walk, {287, 21, 27}})
	table.insert(_q, {walk.walk, {287, 9, 27}})
	table.insert(_q, {walk.walk, {287, 9, 21}})

	-- Fly to the Castle of Dwarves and get the airship upgraded.
	table.insert(_q, {walk.walk, {nil, 48, 62}})
	table.insert(_q, {walk.walk, {nil, 55, 76}})
	table.insert(_q, {walk.walk, {nil, 86, 82}})
	table.insert(_q, {walk.walk, {nil, 98, 82}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 99, 82}})
	table.insert(_q, {walk.walk, {263, 15, 19}})

	-- Step Route: Castle of Dwarves (visiting Cid)
	if _route[34] >= 4 and _route[34] % 2 == 0 then
		table.insert(_q, {walk.walk, {264, 6, 11, true}})
		_route[34] = _route[34] - 4
	elseif _route[34] >= 3 and _route[34] % 2 == 1 then
		table.insert(_q, {walk.walk, {264, 8, 11, true}})
		table.insert(_q, {walk.walk, {264, 8, 8, true}})
		_route[34] = _route[34] - 3
	elseif _route[34] == 2 then
		table.insert(_q, {walk.walk, {264, 11, 10, true}})
		table.insert(_q, {walk.walk, {264, 8, 10, true}})
		table.insert(_q, {walk.walk, {264, 8, 8, true}})
		_route[34] = _route[34] - 2
	elseif _route[34] == 1 then
		table.insert(_q, {walk.walk, {264, 11, 9, true}})
		table.insert(_q, {walk.walk, {264, 8, 9, true}})
		table.insert(_q, {walk.walk, {264, 8, 8, true}})
		_route[34] = _route[34] - 1
	else
		table.insert(_q, {walk.walk, {264, 11, 8, true}})
	end

	table.insert(_q, {walk.walk, {264, 6, 8, true}})

	for i = 1, _route[34] / 2 do
		table.insert(_q, {walk.walk, {264, 6, 7, true}})
		table.insert(_q, {walk.walk, {264, 6, 8, true}})
	end

	table.insert(_q, {walk.walk, {264, 1, 6, true}})
	table.insert(_q, {walk.walk, {273, 16, 3, true}})
	table.insert(_q, {walk.walk, {266, 6, 8}})
	table.insert(_q, {walk.walk, {266, 6, 7}})
	table.insert(_q, {walk.walk, {274, 9, 5}})
	table.insert(_q, {walk.walk, {274, 5, 5}})

	-- Remove the Strength ring from Kain and cast Exit.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})

	-- Board the airship and fly to just outside the Land of Monsters.
	table.insert(_q, {walk.walk, {nil, 98, 82}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 27, 87}})
	table.insert(_q, {walk.interact, {}})

	-- Step Route: Underworld Map
	for i = 1, _route[35] / 2 do
		table.insert(_q, {walk.walk, {nil, 28, 87}})
		table.insert(_q, {walk.walk, {nil, 27, 87}})
	end

	-- Make a safety save.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.save.save, {1}})
	table.insert(_q, {menu.field.close, {}})
end

local function _sequence_dark_crystal()
	-- Attempt to walk through the Land of Monsters.
	table.insert(_q, {_set_healing, {_healing_monsters}})
	table.insert(_q, {walk.walk, {nil, 27, 86}})
	table.insert(_q, {_state_set, {"auto_reload", true}})
	table.insert(_q, {walk.walk, {310, 17, 22}})
	table.insert(_q, {walk.walk, {310, 11, 22}})
	table.insert(_q, {walk.walk, {310, 11, 21}})
	table.insert(_q, {walk.walk, {310, 10, 21}})
	table.insert(_q, {walk.walk, {310, 10, 14}})
	table.insert(_q, {walk.walk, {310, 3, 14}})
	table.insert(_q, {walk.walk, {310, 3, 17}})
	table.insert(_q, {walk.walk, {311, 4, 23}})
	table.insert(_q, {walk.walk, {311, 8, 23}})
	table.insert(_q, {walk.walk, {311, 8, 22}})
	table.insert(_q, {walk.walk, {311, 9, 22}})
	table.insert(_q, {walk.walk, {311, 9, 20}})
	table.insert(_q, {walk.walk, {311, 13, 20}})
	table.insert(_q, {walk.walk, {311, 13, 19}})
	table.insert(_q, {walk.walk, {311, 14, 19}})
	table.insert(_q, {walk.walk, {311, 14, 11}})
	table.insert(_q, {walk.walk, {311, 20, 11}})
	table.insert(_q, {walk.walk, {311, 20, 12}})
	table.insert(_q, {walk.walk, {311, 24, 12}})
	table.insert(_q, {walk.walk, {311, 24, 13}})
	table.insert(_q, {walk.walk, {311, 27, 13}})
	table.insert(_q, {walk.walk, {311, 27, 14}})
	table.insert(_q, {walk.walk, {311, 28, 14}})
	table.insert(_q, {walk.walk, {311, 28, 16}})
	table.insert(_q, {walk.walk, {312, 11, 6}})
	table.insert(_q, {walk.walk, {312, 4, 6}})
	table.insert(_q, {walk.walk, {312, 4, 14}})

	-- Step Route: Land of Monsters B3F
	if _route[36] == 2 then
		table.insert(_q, {walk.walk, {312, 0, 14}})
		table.insert(_q, {walk.walk, {312, 0, 26}})
		table.insert(_q, {walk.walk, {312, 29, 26}})
		table.insert(_q, {walk.walk, {312, 29, 14}})
	elseif _route[36] == 1 then
		table.insert(_q, {walk.walk, {312, 0, 14}})
		table.insert(_q, {walk.walk, {312, 0, 26}})
		table.insert(_q, {walk.walk, {312, 29, 26}})
		table.insert(_q, {walk.walk, {312, 29, 22}})
		table.insert(_q, {walk.walk, {312, 18, 22}})
	else
		table.insert(_q, {walk.walk, {312, 11, 14}})
		table.insert(_q, {walk.walk, {312, 11, 22}})
		table.insert(_q, {walk.walk, {312, 18, 22}})
	end

	table.insert(_q, {walk.walk, {312, 18, 14}})
	table.insert(_q, {_state_set, {"auto_reload", nil}})

	-- Walk to the Rat tail chest.
	table.insert(_q, {walk.walk, {314, 9, 14, true}})
	table.insert(_q, {walk.walk, {314, 9, 11, true}})
	table.insert(_q, {walk.walk, {314, 4, 5, true}})
	table.insert(_q, {walk.walk, {314, 6, 4, true}})
	table.insert(_q, {walk.walk, {314, 7, 3, true}})
	table.insert(_q, {walk.walk, {314, 14, 4, true}})
	table.insert(_q, {walk.walk, {316, 28, 12}})
	table.insert(_q, {walk.walk, {316, 28, 11}})
	table.insert(_q, {walk.walk, {314, 14, 6}})
	table.insert(_q, {walk.walk, {314, 20, 6}})
	table.insert(_q, {walk.walk, {314, 20, 7}})
	table.insert(_q, {walk.interact, {}})

	-- Cast Exit and head to the Sealed Cave.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.EDGE] = _RESTORE.HP, [game.CHARACTER.ROSA] = _RESTORE.HP, [game.CHARACTER.RYDIA] = _RESTORE.HP}}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})
	table.insert(_q, {walk.walk, {nil, 27, 87}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 46, 110}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 46, 109}})

	-- Step Route: Sealed Cave
	for i = 1, _route[37] / 2 do
		table.insert(_q, {walk.walk, {324, 4, 9}})
		table.insert(_q, {walk.walk, {324, 4, 10}})
	end

	table.insert(_q, {walk.walk, {324, 4, 4}})
end

local function _sequence_big_whale()
	-- Visit King Giott.
	table.insert(_q, {walk.walk, {324, 4, 11}})
	table.insert(_q, {walk.walk, {nil, 46, 110}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 75, 94}})
	table.insert(_q, {walk.walk, {nil, 100, 83}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 100, 82}})
	table.insert(_q, {walk.walk, {263, 15, 19}})
	table.insert(_q, {walk.walk, {264, 11, 1}})

	-- Step Route: Castle of Dwarves (King's Room)
	for i = 1, _route[38] / 2 do
		table.insert(_q, {walk.walk, {265, 10, 12}})
		table.insert(_q, {walk.walk, {265, 10, 13}})
	end

	if _route[38] % 2 == 1 then
		table.insert(_q, {walk.walk, {265, 10, 14}})
	end

	table.insert(_q, {walk.walk, {265, 10, 11}})

	-- Cast Exit, fly to the overworld and go to the Grotto Adamant.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.magic.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.magic.select, {game.MAGIC.WHITE.EXIT}})
	table.insert(_q, {menu.field.close, {}})
	table.insert(_q, {walk.walk, {nil, 100, 83}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 112, 17}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 36, 237}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 35, 237}})

	-- Step Route: World Map (Eblan)
	for i = 1, _route[39] / 2 do
		table.insert(_q, {walk.walk, {nil, 35, 236}})
		table.insert(_q, {walk.walk, {nil, 35, 237}})
	end

	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 24, 232}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 211, 132}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 210, 132}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 211, 132}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 211, 134}})
	table.insert(_q, {walk.walk, {nil, 215, 134}})
	table.insert(_q, {walk.walk, {nil, 215, 136}})
	table.insert(_q, {walk.walk, {nil, 218, 136}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 219, 136}})

	-- Step Route: Grotto Adamant
	table.insert(_q, {walk.walk, {160, 7, 19}})

	for i = 1, _route[40] / 2 do
		table.insert(_q, {walk.walk, {160, 8, 19}})
		table.insert(_q, {walk.walk, {160, 7, 19}})
	end

	-- Collect the Adamant and head to Mysidia.
	table.insert(_q, {walk.walk, {160, 7, 13}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.RAT}})
	table.insert(_q, {walk.walk, {160, 7, 21}})
	table.insert(_q, {walk.walk, {nil, 218, 136}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 214, 136}})
	table.insert(_q, {walk.walk, {nil, 214, 134}})
	table.insert(_q, {walk.walk, {nil, 211, 134}})
	table.insert(_q, {walk.walk, {nil, 211, 132}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 210, 132}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 153, 199}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 154, 199}})
	table.insert(_q, {walk.walk, {3, 16, 28}})
end

local function _sequence_fusoya_hummingway()
	-- Fly to the Hummingway Cave
	table.insert(_q, {walk.walk, {nil, 33, 40}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {303, 5, 7}})
	table.insert(_q, {walk.walk, {303, 5, 13}})
	table.insert(_q, {walk.walk, {303, 2, 13}})
	table.insert(_q, {walk.walk, {nil, 33, 39}})

	-- Catch the shop NPC and purchase Elixirs.
	table.insert(_q, {_hummingway_start, {}})
	table.insert(_q, {walk.chase, {357, {8}}})
	table.insert(_q, {menu.shop.buy.open, {50}})
	table.insert(_q, {menu.shop.buy.buy, {game.ITEM.ITEM.ELIXIR}})
	table.insert(_q, {menu.shop.buy.close, {}})
	table.insert(_q, {menu.shop.close, {}})

	-- Leave the cave and board the Big Whale.
	table.insert(_q, {walk.walk, {357, 10, 16}})
	table.insert(_q, {_hummingway_finish, {}})
	table.insert(_q, {walk.walk, {357, 10, 17}})
	table.insert(_q, {walk.walk, {nil, 33, 40}})
	table.insert(_q, {walk.board, {}})
end

local function _sequence_fusoya_fusoya()
	table.insert(_q, {walk.walk, {nil, 21, 19}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {303, 5, 7}})
	table.insert(_q, {walk.walk, {303, 5, 13}})
	table.insert(_q, {walk.walk, {303, 2, 13}})

	-- Walk to the Crystal Palace.
	table.insert(_q, {walk.walk, {nil, 21, 21}})
	table.insert(_q, {walk.walk, {nil, 18, 21}})
	table.insert(_q, {walk.walk, {nil, 18, 20}})
	table.insert(_q, {walk.walk, {355, 12, 29}})
	table.insert(_q, {walk.walk, {355, 14, 29}})
	table.insert(_q, {walk.walk, {355, 14, 23}})
	table.insert(_q, {walk.walk, {355, 11, 23}})
	table.insert(_q, {walk.walk, {355, 11, 15}})
	table.insert(_q, {walk.walk, {355, 14, 15}})
	table.insert(_q, {walk.walk, {355, 14, 10}})
	table.insert(_q, {walk.walk, {355, 19, 10}})
	table.insert(_q, {walk.walk, {355, 19, 4}})
	table.insert(_q, {walk.walk, {nil, 23, 15}})
	table.insert(_q, {walk.walk, {nil, 23, 14}})
	table.insert(_q, {walk.walk, {nil, 33, 14}})
	table.insert(_q, {walk.walk, {nil, 33, 16}})
	table.insert(_q, {walk.walk, {nil, 37, 16}})
	table.insert(_q, {walk.walk, {nil, 37, 25}})
	table.insert(_q, {walk.walk, {nil, 41, 25}})
	table.insert(_q, {walk.walk, {nil, 41, 24}})
	table.insert(_q, {walk.walk, {356, 14, 6}})
	table.insert(_q, {walk.walk, {356, 14, 19}})
	table.insert(_q, {walk.walk, {356, 9, 19}})
	table.insert(_q, {walk.walk, {356, 9, 26}})
	table.insert(_q, {walk.walk, {nil, 37, 29}})
	table.insert(_q, {walk.walk, {nil, 37, 30}})
	table.insert(_q, {walk.walk, {nil, 33, 30}})
	table.insert(_q, {walk.walk, {nil, 33, 28}})
	table.insert(_q, {walk.walk, {nil, 28, 28}})
	table.insert(_q, {walk.walk, {nil, 28, 25}})
	table.insert(_q, {walk.walk, {352, 16, 21}})

	-- Walk back to the Big Whale.
	table.insert(_q, {walk.walk, {352, 16, 29}})
	table.insert(_q, {_set_healing, {_healing_grind_start_1}})
	table.insert(_q, {walk.walk, {nil, 28, 29}})
	table.insert(_q, {walk.walk, {nil, 34, 29}})
	table.insert(_q, {walk.walk, {nil, 34, 30}})
	table.insert(_q, {walk.walk, {nil, 37, 30}})
	table.insert(_q, {walk.walk, {nil, 37, 29}})
	table.insert(_q, {walk.walk, {nil, 40, 29}})
	table.insert(_q, {walk.walk, {nil, 40, 28}})
	table.insert(_q, {walk.walk, {356, 9, 18}})
	table.insert(_q, {walk.walk, {356, 14, 18}})
	table.insert(_q, {walk.walk, {356, 14, 6}})
	table.insert(_q, {walk.walk, {356, 21, 6}})
	table.insert(_q, {walk.walk, {356, 21, 5}})
	table.insert(_q, {walk.walk, {nil, 37, 25}})
	table.insert(_q, {walk.walk, {nil, 37, 16}})
	table.insert(_q, {walk.walk, {nil, 33, 16}})
	table.insert(_q, {walk.walk, {nil, 33, 14}})
	table.insert(_q, {walk.walk, {nil, 22, 14}})
	table.insert(_q, {walk.walk, {nil, 22, 15}})
	table.insert(_q, {walk.walk, {nil, 18, 15}})
	table.insert(_q, {walk.walk, {nil, 18, 14}})
	table.insert(_q, {walk.walk, {355, 19, 10}})
	table.insert(_q, {walk.walk, {355, 12, 10}})
	table.insert(_q, {walk.walk, {355, 12, 15}})
	table.insert(_q, {walk.walk, {355, 11, 15}})
	table.insert(_q, {walk.walk, {355, 11, 23}})
	table.insert(_q, {walk.walk, {355, 14, 23}})
	table.insert(_q, {walk.walk, {355, 14, 29}})
	table.insert(_q, {walk.walk, {355, 12, 29}})
	table.insert(_q, {walk.walk, {355, 12, 31}})
	table.insert(_q, {walk.walk, {nil, 21, 21}})
	table.insert(_q, {walk.walk, {nil, 21, 19}})

	-- Step Route: Lunar World Map
	for i = 1, _route[43] / 2 do
		table.insert(_q, {walk.walk, {nil, 21, 20}})
		table.insert(_q, {walk.walk, {nil, 21, 19}})
	end

	table.insert(_q, {walk.board, {}})
end

local function _sequence_fusoya()
	-- Get the Excalbur.
	table.insert(_q, {_set_healing, {_healing_fusoya}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 106, 211}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 106, 122}})
	table.insert(_q, {walk.walk, {nil, 104, 122}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 104, 123}})
	table.insert(_q, {walk.walk, {256, 6, 6}})
	table.insert(_q, {walk.walk, {258, 11, 14}})
	table.insert(_q, {walk.walk, {258, 11, 11}})
	table.insert(_q, {walk.walk, {258, 14, 11}})
	table.insert(_q, {walk.walk, {258, 14, 5}})
	table.insert(_q, {walk.walk, {259, 3, 4}})
	table.insert(_q, {walk.walk, {259, 3, 5}})
	table.insert(_q, {walk.walk, {259, 2, 5}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {menu.dialog.select, {game.ITEM.ITEM.ADAMANT}})
	table.insert(_q, {walk.walk, {259, 2, 4}})
	table.insert(_q, {walk.walk, {259, 9, 4}})
	table.insert(_q, {walk.walk, {258, 14, 10}})
	table.insert(_q, {walk.walk, {258, 11, 10}})
	table.insert(_q, {walk.walk, {258, 11, 9}})
	table.insert(_q, {walk.walk, {258, 7, 9}})
	table.insert(_q, {walk.step, {walk.DIRECTION.DOWN}})
	table.insert(_q, {walk.interact, {}})

	-- Return to the overworld and board the Big Whale.
	table.insert(_q, {walk.walk, {258, 11, 9}})
	table.insert(_q, {walk.walk, {258, 11, 14}})
	table.insert(_q, {walk.walk, {258, 7, 17, true}})
	table.insert(_q, {walk.walk, {256, 6, 12}})
	table.insert(_q, {walk.walk, {nil, 104, 122}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {nil, 112, 17}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 149, 199}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 150, 199}})
	table.insert(_q, {walk.board, {}})

	-- Fly to the Moon and head to the Hummingway Cave.
	table.insert(_q, {walk.walk, {303, 7, 13}})
	table.insert(_q, {walk.walk, {303, 7, 11}})
	table.insert(_q, {walk.interact, {}})

	-- Step Route: Hummingway or FuSoYa
	if _route[41] == 0 then
		_sequence_fusoya_hummingway()
		table.insert(_q, {walk.walk, {303, 5, 13}})
		table.insert(_q, {walk.walk, {303, 5, 7}})
		table.insert(_q, {walk.walk, {303, 7, 7}})
		table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
		table.insert(_q, {walk.interact, {}})
		_sequence_fusoya_fusoya()
	else
		_sequence_fusoya_fusoya()
		table.insert(_q, {walk.walk, {303, 5, 13}})
		table.insert(_q, {walk.walk, {303, 5, 7}})
		table.insert(_q, {walk.walk, {303, 7, 7}})
		table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
		table.insert(_q, {walk.interact, {}})
		_sequence_fusoya_hummingway()
	end
end

local function _sequence_grind_start()
	-- Board the Big Whale and return to Earth.
	table.insert(_q, {walk.walk, {303, 7, 13}})
	table.insert(_q, {walk.walk, {303, 7, 11}})
	table.insert(_q, {walk.interact, {}})

	-- Walk to the Passage.
	table.insert(_q, {walk.walk, {181, 9, 20}})
	table.insert(_q, {walk.walk, {181, 9, 16}})

	-- Step Route: Giant of Bab-il Mouth
	if _route[44] == 1 then
		table.insert(_q, {walk.walk, {181, 10, 16}})
	else
		table.insert(_q, {walk.walk, {181, 9, 15}})
	end

	table.insert(_q, {walk.walk, {181, 10, 15}})
	table.insert(_q, {walk.walk, {181, 10, 10}})
	table.insert(_q, {walk.walk, {181, 11, 10}})
	table.insert(_q, {walk.walk, {181, 11, 9}})
	table.insert(_q, {walk.walk, {181, 12, 9}})
	table.insert(_q, {walk.walk, {181, 12, 6}})
	table.insert(_q, {walk.walk, {181, 11, 6}})
	table.insert(_q, {walk.walk, {181, 11, 5}})
	table.insert(_q, {walk.walk, {181, 9, 5}})
	table.insert(_q, {walk.walk, {181, 9, 7}})
	table.insert(_q, {walk.walk, {182, 7, 7}})
	table.insert(_q, {walk.walk, {183, 14, 9}})
	table.insert(_q, {walk.walk, {183, 13, 9}})
	table.insert(_q, {walk.walk, {183, 13, 10}})
	table.insert(_q, {walk.walk, {183, 9, 10}})
	table.insert(_q, {walk.walk, {183, 9, 16}})
	table.insert(_q, {walk.walk, {183, 6, 16}})
	table.insert(_q, {walk.walk, {183, 6, 15}})
	table.insert(_q, {walk.walk, {183, 5, 15}})
	table.insert(_q, {walk.walk, {183, 5, 11}})
	table.insert(_q, {walk.walk, {183, 2, 11}})
	table.insert(_q, {walk.walk, {183, 2, 19}})
	table.insert(_q, {walk.walk, {183, 3, 19}})
	table.insert(_q, {walk.walk, {183, 3, 22}})
	table.insert(_q, {walk.walk, {183, 5, 22}})
	table.insert(_q, {walk.walk, {183, 5, 25}})
	table.insert(_q, {walk.walk, {183, 9, 25}})
	table.insert(_q, {walk.walk, {183, 9, 21}})
	table.insert(_q, {walk.walk, {183, 14, 21}})
	table.insert(_q, {walk.walk, {183, 14, 25}})
	table.insert(_q, {walk.walk, {183, 17, 25}})
	table.insert(_q, {walk.walk, {183, 17, 26}})
	table.insert(_q, {walk.walk, {183, 24, 26}})
	table.insert(_q, {walk.walk, {183, 24, 18}})
	table.insert(_q, {walk.walk, {183, 23, 18}})
	table.insert(_q, {walk.walk, {183, 23, 15}})
	table.insert(_q, {walk.walk, {183, 19, 15}})
	table.insert(_q, {walk.walk, {183, 19, 9}})
	table.insert(_q, {walk.walk, {183, 18, 9}})
	table.insert(_q, {walk.walk, {185, 22, 20}})
	table.insert(_q, {walk.walk, {185, 22, 19}})
	table.insert(_q, {walk.walk, {185, 23, 19}})
	table.insert(_q, {walk.walk, {185, 23, 6}})
	table.insert(_q, {walk.walk, {185, 21, 6}})
	table.insert(_q, {walk.walk, {185, 21, 5}})
	table.insert(_q, {walk.walk, {185, 14, 5}})
	table.insert(_q, {walk.walk, {185, 14, 8}})
	table.insert(_q, {walk.walk, {185, 11, 8}})
	table.insert(_q, {walk.walk, {185, 11, 10}})
	table.insert(_q, {walk.walk, {185, 5, 10}})
	table.insert(_q, {walk.walk, {185, 5, 6}})
	table.insert(_q, {walk.walk, {185, 3, 6}})
	table.insert(_q, {walk.walk, {185, 3, 4}})

	-- Do the pre-grind fight menu.
	table.insert(_q, {dialog.set_mash_button, {"P1 B"}})
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.EDGE] = _RESTORE.ALL, [game.CHARACTER.FUSOYA] = _RESTORE.HP, [game.CHARACTER.ROSA] = _RESTORE.HP, [game.CHARACTER.RYDIA] = _RESTORE.HP}, game.CHARACTER.FUSOYA}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.DANCING}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.FUSOYA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.CHANGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.GAEA}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.ROSA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.R_HAND, game.ITEM.WEAPON.LUNAR}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.WIZARD}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.CECIL, game.CHARACTER.EDGE}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.RYDIA, game.CHARACTER.FUSOYA}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.RYDIA, game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to just before the elements battle.
	table.insert(_q, {_set_healing, {_healing_grind_start_2}})
	table.insert(_q, {walk.walk, {186, 3, 6}})

	-- Step Route: Giant of Bab-il Passage
	for i = 1, _route[45] / 2 do
		table.insert(_q, {walk.walk, {186, 4, 6}})
		table.insert(_q, {walk.walk, {186, 3, 6}})
	end

	if _route[45] % 2 == 1 then
		table.insert(_q, {walk.walk, {186, 3, 7}})
		table.insert(_q, {walk.walk, {186, 3, 6}})
	end

	table.insert(_q, {walk.walk, {186, 3, 23}})
	table.insert(_q, {walk.walk, {186, 4, 23}})
	table.insert(_q, {walk.walk, {186, 4, 25}})
	table.insert(_q, {walk.walk, {186, 6, 25}})
	table.insert(_q, {walk.walk, {186, 6, 26}})
	table.insert(_q, {walk.walk, {186, 11, 26}})
	table.insert(_q, {walk.walk, {186, 11, 25}})
	table.insert(_q, {walk.walk, {186, 17, 25}})
	table.insert(_q, {walk.walk, {186, 17, 26}})
	table.insert(_q, {walk.walk, {186, 24, 26}})
	table.insert(_q, {walk.walk, {186, 24, 23}})
	table.insert(_q, {walk.walk, {186, 25, 23}})
	table.insert(_q, {walk.walk, {186, 25, 15}})
	table.insert(_q, {walk.walk, {186, 21, 15}})
	table.insert(_q, {walk.walk, {186, 21, 4}})
	table.insert(_q, {walk.walk, {188, 15, 16}})
end

local function _sequence_elements()
	if game.character.get_stat(game.CHARACTER.EDGE, "level") < 45 then
		table.insert(_q, {walk.walk, {188, 15, 17}})
		table.insert(_q, {walk.walk, {188, 15, 16}})
	else
		_post_grind_menu()
		table.insert(_q, {walk.walk, {188, 15, 15}})
	end
end

local function _sequence_cpu()
	table.insert(_q, {dialog.set_mash_button, {"P1 A"}})
	table.insert(_q, {_set_healing, {nil}})
	table.insert(_q, {walk.walk, {188, 15, 14}})

	-- Do the post-battle menu.
	table.insert(_q, {menu.field.open, {}})

	if game.character.get_stat(game.CHARACTER.ROSA, "level") < 20 then
		table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.FUSOYA] = _RESTORE.ALL, [game.CHARACTER.EDGE] = _RESTORE.HP, [game.CHARACTER.ROSA] = _RESTORE.HP}}})
	else
		table.insert(_q, {_restore_party, {{[game.CHARACTER.CECIL] = _RESTORE.HP, [game.CHARACTER.FUSOYA] = _RESTORE.ALL, [game.CHARACTER.EDGE] = _RESTORE.HP}}})
	end

	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.FUSOYA, game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to the CPU battle.
	table.insert(_q, {walk.walk, {188, 15, 4}})
	table.insert(_q, {walk.walk, {189, 9, 18}})
	table.insert(_q, {walk.walk, {189, 9, 17}})

	-- Step Route: Giant of Bab-il CPU
	for i = 1, _route[46] / 2 do
		table.insert(_q, {walk.walk, {189, 10, 17}})
		table.insert(_q, {walk.walk, {189, 9, 17}})
	end

	if _route[46] % 2 == 1 then
		table.insert(_q, {walk.walk, {189, 9, 16}})
		table.insert(_q, {walk.walk, {189, 9, 17}})
	end

	table.insert(_q, {walk.walk, {189, 9, 13}})
end

local function _sequence_subterrane()
	-- Fly to the Lunar Path.
	table.insert(_q, {_set_healing, {_healing_subterrane}})
	table.insert(_q, {walk.board, {}})
	table.insert(_q, {walk.walk, {303, 5, 13}})
	table.insert(_q, {walk.walk, {303, 5, 7}})
	table.insert(_q, {walk.walk, {303, 7, 7}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {nil, 21, 19}})
	table.insert(_q, {walk.interact, {}})
	table.insert(_q, {walk.walk, {303, 5, 7}})
	table.insert(_q, {walk.walk, {303, 5, 13}})
	table.insert(_q, {walk.walk, {303, 2, 13}})

	-- Walk to the Crystal Palace.
	table.insert(_q, {walk.walk, {nil, 21, 21}})
	table.insert(_q, {walk.walk, {nil, 18, 21}})
	table.insert(_q, {walk.walk, {nil, 18, 20}})
	table.insert(_q, {walk.walk, {355, 12, 29}})
	table.insert(_q, {walk.walk, {355, 14, 29}})
	table.insert(_q, {walk.walk, {355, 14, 23}})
	table.insert(_q, {walk.walk, {355, 11, 23}})
	table.insert(_q, {walk.walk, {355, 11, 15}})
	table.insert(_q, {walk.walk, {355, 14, 15}})
	table.insert(_q, {walk.walk, {355, 14, 10}})
	table.insert(_q, {walk.walk, {355, 19, 10}})
	table.insert(_q, {walk.walk, {355, 19, 4}})
	table.insert(_q, {walk.walk, {nil, 23, 15}})
	table.insert(_q, {walk.walk, {nil, 23, 14}})
	table.insert(_q, {walk.walk, {nil, 33, 14}})
	table.insert(_q, {walk.walk, {nil, 33, 16}})
	table.insert(_q, {walk.walk, {nil, 37, 16}})
	table.insert(_q, {walk.walk, {nil, 37, 25}})
	table.insert(_q, {walk.walk, {nil, 41, 25}})
	table.insert(_q, {walk.walk, {nil, 41, 24}})
	table.insert(_q, {walk.walk, {356, 14, 6}})
	table.insert(_q, {walk.walk, {356, 14, 19}})
	table.insert(_q, {walk.walk, {356, 9, 19}})
	table.insert(_q, {walk.walk, {356, 9, 26}})
	table.insert(_q, {walk.walk, {nil, 37, 29}})
	table.insert(_q, {walk.walk, {nil, 37, 30}})
	table.insert(_q, {walk.walk, {nil, 33, 30}})
	table.insert(_q, {walk.walk, {nil, 33, 28}})
	table.insert(_q, {walk.walk, {nil, 28, 28}})
	table.insert(_q, {walk.walk, {nil, 28, 25}})

	-- Walk to the teleport to the Lunar Subterrane.
	table.insert(_q, {walk.walk, {352, 16, 21}})
	table.insert(_q, {walk.walk, {352, 19, 21}})
	table.insert(_q, {walk.walk, {352, 19, 8}})
	table.insert(_q, {walk.walk, {352, 16, 8}})
	table.insert(_q, {walk.walk, {352, 16, 5}})
	table.insert(_q, {walk.walk, {353, 16, 27}})
	table.insert(_q, {walk.walk, {353, 23, 27}})
	table.insert(_q, {walk.walk, {353, 23, 23}})
	table.insert(_q, {walk.walk, {353, 26, 23}})
	table.insert(_q, {walk.walk, {353, 26, 16}})
	table.insert(_q, {walk.walk, {353, 16, 16}})
end

local function _sequence_core()
	-- Walk to the Protect ring chest.
	table.insert(_q, {bridge.split, {"Lunar Subterrane"}})
	table.insert(_q, {walk.walk, {359, 13, 8}})
	table.insert(_q, {walk.walk, {359, 17, 8}})
	table.insert(_q, {walk.walk, {359, 17, 19}})
	table.insert(_q, {walk.walk, {359, 13, 19}})
	table.insert(_q, {walk.walk, {359, 13, 25}})
	table.insert(_q, {walk.walk, {359, 16, 25}})
	table.insert(_q, {walk.walk, {359, 16, 24}})
	table.insert(_q, {walk.walk, {360, 19, 30}})
	table.insert(_q, {walk.walk, {360, 30, 30}})

	-- Step Route: Lunar Subterrane B2
	for i = 1, _route[47] / 2 do
		table.insert(_q, {walk.walk, {360, 29, 30}})
		table.insert(_q, {walk.walk, {360, 30, 30}})
	end

	if _route[47] % 2 == 1 then
		table.insert(_q, {walk.walk, {360, 31, 30}})
		table.insert(_q, {walk.walk, {360, 30, 30}})
	end

	table.insert(_q, {walk.walk, {360, 31, 30}})
	table.insert(_q, {walk.walk, {360, 31, 4}})
	table.insert(_q, {walk.walk, {360, 23, 4}})
	table.insert(_q, {walk.walk, {360, 23, 5}})
	table.insert(_q, {walk.walk, {360, 15, 5}})
	table.insert(_q, {walk.walk, {360, 15, 4}})
	table.insert(_q, {walk.walk, {361, 14, 5}})
	table.insert(_q, {walk.walk, {361, 14, 16}})
	table.insert(_q, {walk.walk, {361, 16, 16}})
	table.insert(_q, {walk.walk, {361, 16, 15}})
	table.insert(_q, {walk.walk, {362, 13, 7}})
	table.insert(_q, {walk.walk, {362, 13, 5}})
	table.insert(_q, {walk.walk, {362, 18, 5}})
	table.insert(_q, {walk.walk, {362, 18, 18}})
	table.insert(_q, {walk.walk, {362, 29, 18}})
	table.insert(_q, {walk.walk, {362, 29, 16}})
	table.insert(_q, {walk.walk, {362, 31, 16}})
	table.insert(_q, {walk.walk, {362, 31, 24}})
	table.insert(_q, {walk.walk, {362, 28, 24}})
	table.insert(_q, {walk.walk, {362, 28, 26}})
	table.insert(_q, {walk.walk, {362, 25, 26}})

	-- Step Route: Lunar Subterrane B4
	for i = 1, _route[48] / 2 do
		table.insert(_q, {walk.walk, {362, 24, 26}})
		table.insert(_q, {walk.walk, {362, 25, 26}})
	end

	table.insert(_q, {walk.walk, {362, 25, 24}})
	table.insert(_q, {walk.walk, {372, 24, 14}})
	table.insert(_q, {walk.walk, {372, 18, 14}})
	table.insert(_q, {walk.walk, {372, 18, 12}})
	table.insert(_q, {walk.walk, {372, 12, 12}})
	table.insert(_q, {walk.walk, {372, 12, 14}})
	table.insert(_q, {walk.walk, {372, 9, 14}})
	table.insert(_q, {walk.walk, {372, 9, 12}})
	table.insert(_q, {walk.walk, {372, 6, 12}})
	table.insert(_q, {walk.walk, {372, 6, 13}})
	table.insert(_q, {walk.walk, {362, 10, 27}})
	table.insert(_q, {walk.walk, {362, 16, 27}})
	table.insert(_q, {walk.walk, {362, 16, 31}})
	table.insert(_q, {walk.walk, {363, 16, 14}})
	table.insert(_q, {walk.walk, {363, 11, 14}})

	-- Step Route: Lunar Subterrane B5
	for i = 1, _route[49] / 2 do
		table.insert(_q, {walk.walk, {363, 10, 14}})
		table.insert(_q, {walk.walk, {363, 11, 14}})
	end

	table.insert(_q, {walk.walk, {363, 11, 13}})
	table.insert(_q, {walk.walk, {373, 5, 5}})
	table.insert(_q, {walk.walk, {373, 13, 5}})
	table.insert(_q, {walk.step, {walk.DIRECTION.UP}})
	table.insert(_q, {walk.interact, {}})

	-- Complete the pre-Zeromus menu.
	-- TODO: Improve inventory management so the sort is unnecessary.
	table.insert(_q, {menu.field.open, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.EDGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.NONE}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.CECIL}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.BANDANNA}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.BL_BELT}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.STRENGTH}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.KAIN}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.HEADBAND}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.KARATE}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.equip.open, {game.CHARACTER.EDGE}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.HEAD, game.ITEM.HELM.SAMURAI}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.BODY, game.ITEM.ARMOR.SAMURAI}})
	table.insert(_q, {menu.field.equip.equip, {game.EQUIP.ARMS, game.ITEM.RING.PROTECT}})
	table.insert(_q, {menu.field.equip.close, {}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.EDGE, game.CHARACTER.ROSA}})
	table.insert(_q, {menu.field.form.swap, {game.CHARACTER.KAIN, game.CHARACTER.RYDIA}})
	table.insert(_q, {menu.field.close, {}})

	-- Walk to the Lunar Core.
	table.insert(_q, {walk.walk, {373, 17, 5}})
	table.insert(_q, {walk.walk, {373, 17, 8}})
	table.insert(_q, {walk.walk, {373, 14, 8}})
	table.insert(_q, {walk.walk, {373, 14, 13}})
	table.insert(_q, {walk.walk, {373, 22, 13}})
	table.insert(_q, {walk.walk, {373, 22, 7}})
	table.insert(_q, {walk.walk, {363, 19, 22}})
	table.insert(_q, {walk.walk, {363, 19, 21}})
	table.insert(_q, {walk.walk, {363, 14, 21}})

	-- Step Route: Lunar Subterrane B5 (after room)
	for i = 1, _route[50] / 2 do
		table.insert(_q, {walk.walk, {363, 13, 21}})
		table.insert(_q, {walk.walk, {363, 14, 21}})
	end

	table.insert(_q, {walk.walk, {363, 14, 20}})
	table.insert(_q, {walk.walk, {374, 9, 6}})
	table.insert(_q, {walk.walk, {374, 6, 6}})
	table.insert(_q, {walk.walk, {374, 6, 3}})
	table.insert(_q, {walk.walk, {363, 18, 28}})
	table.insert(_q, {walk.walk, {363, 18, 26}})
	table.insert(_q, {walk.walk, {363, 20, 26}})
	table.insert(_q, {walk.walk, {363, 20, 28}})

	-- Step Route: Lunar Subterrane B5 (Pink Puff)
	if _route[51] == 1 then
		table.insert(_q, {walk.walk, {363, 23, 28}})
		table.insert(_q, {walk.walk, {363, 23, 27}})

		for i = 1, _route[52] / 2 do
			table.insert(_q, {walk.walk, {375, 3, 9}})
			table.insert(_q, {walk.walk, {375, 2, 9}})
		end

		table.insert(_q, {walk.walk, {375, 2, 10}})
		table.insert(_q, {walk.walk, {363, 23, 28}})
		table.insert(_q, {walk.walk, {363, 20, 28}})
	end

	table.insert(_q, {walk.walk, {363, 20, 31}})
	table.insert(_q, {walk.walk, {364, 20, 10}})
	table.insert(_q, {walk.walk, {364, 21, 10}})
	table.insert(_q, {walk.walk, {364, 21, 14}})
	table.insert(_q, {walk.walk, {364, 23, 14}})
	table.insert(_q, {walk.walk, {364, 23, 12}})
	table.insert(_q, {walk.walk, {364, 27, 12}})
	table.insert(_q, {walk.walk, {364, 27, 20}})
	table.insert(_q, {walk.walk, {364, 26, 20}})
	table.insert(_q, {walk.walk, {364, 26, 21}})
	table.insert(_q, {walk.walk, {364, 25, 21}})
	table.insert(_q, {walk.walk, {364, 25, 22}})
	table.insert(_q, {walk.walk, {364, 22, 22}})

	-- Step Route: Lunar Subterrane B6
	for i = 1, _route[53] / 2 do
		table.insert(_q, {walk.walk, {364, 21, 22}})
		table.insert(_q, {walk.walk, {364, 22, 22}})
	end

	table.insert(_q, {walk.walk, {364, 22, 21}})
	table.insert(_q, {walk.walk, {377, 5, 11}})
	table.insert(_q, {walk.walk, {377, 10, 11}})
	table.insert(_q, {walk.walk, {377, 10, 4}})
	table.insert(_q, {walk.walk, {365, 3, 13}})
	table.insert(_q, {walk.walk, {365, 8, 13}})
	table.insert(_q, {walk.walk, {365, 8, 21}})
	table.insert(_q, {walk.walk, {365, 13, 21}})

	-- Step Route: Lunar Subterrane B7 Save Room
	if _route[54] == 1 then
		table.insert(_q, {walk.walk, {365, 13, 20}})

		for i = 1, _route[55] / 2 do
			table.insert(_q, {walk.walk, {379, 4, 14}})
			table.insert(_q, {walk.walk, {379, 3, 14}})
		end

		table.insert(_q, {walk.walk, {379, 3, 15}})
		table.insert(_q, {walk.walk, {365, 13, 21}})
	end

	for i = 1, _route[56] / 2 do
		table.insert(_q, {walk.walk, {365, 13, 22}})
		table.insert(_q, {walk.walk, {365, 13, 21}})
	end

	table.insert(_q, {walk.walk, {365, 30, 21}})
	table.insert(_q, {walk.walk, {365, 30, 2}})
	table.insert(_q, {walk.walk, {365, 21, 2}})
	table.insert(_q, {walk.walk, {365, 21, 9}})
	table.insert(_q, {walk.walk, {365, 17, 9}})
	table.insert(_q, {walk.walk, {365, 17, 7}})
end

local function _sequence_zemus()
	-- Walk to the Zemus battle.
	table.insert(_q, {bridge.split, {"Lunar Core"}})
	table.insert(_q, {walk.walk, {366, 17, 9}})
	table.insert(_q, {walk.walk, {366, 24, 9}})
	table.insert(_q, {walk.walk, {366, 24, 12}})
	table.insert(_q, {walk.walk, {366, 26, 12}})
	table.insert(_q, {walk.walk, {366, 26, 16}})
	table.insert(_q, {walk.walk, {366, 24, 16}})
	table.insert(_q, {walk.walk, {366, 24, 15}})
	table.insert(_q, {walk.walk, {366, 23, 15}})
	table.insert(_q, {walk.walk, {366, 23, 14}})
	table.insert(_q, {walk.walk, {366, 21, 14}})
	table.insert(_q, {walk.walk, {366, 21, 13}})
	table.insert(_q, {walk.walk, {366, 13, 13}})
	table.insert(_q, {walk.walk, {366, 13, 15}})
	table.insert(_q, {walk.walk, {366, 9, 15}})
	table.insert(_q, {walk.walk, {366, 9, 20}})
	table.insert(_q, {walk.walk, {366, 12, 20}})
	table.insert(_q, {walk.walk, {366, 12, 19}})
	table.insert(_q, {walk.walk, {366, 14, 19}})
	table.insert(_q, {walk.walk, {366, 14, 20}})
	table.insert(_q, {walk.walk, {366, 15, 20}})
	table.insert(_q, {walk.walk, {366, 15, 21}})
	table.insert(_q, {walk.walk, {366, 19, 21}})
	table.insert(_q, {walk.walk, {366, 19, 20}})
	table.insert(_q, {walk.walk, {366, 20, 20}})
	table.insert(_q, {walk.walk, {366, 20, 16}})
	table.insert(_q, {walk.walk, {366, 17, 16}})
	table.insert(_q, {walk.walk, {366, 17, 19}})
	table.insert(_q, {walk.walk, {367, 15, 11}})
	table.insert(_q, {walk.walk, {367, 17, 11}})
	table.insert(_q, {walk.walk, {367, 17, 15}})
	table.insert(_q, {walk.walk, {367, 21, 15}})
	table.insert(_q, {walk.walk, {367, 21, 18}})
	table.insert(_q, {walk.walk, {367, 13, 18}})
	table.insert(_q, {walk.walk, {367, 13, 16}})
	table.insert(_q, {walk.walk, {367, 9, 16}})
	table.insert(_q, {walk.walk, {367, 9, 15}})
	table.insert(_q, {walk.walk, {367, 7, 15}})
	table.insert(_q, {walk.walk, {367, 7, 22}})
	table.insert(_q, {walk.walk, {367, 22, 22}})
	table.insert(_q, {walk.walk, {367, 22, 23}})
	table.insert(_q, {walk.walk, {368, 21, 9}})
	table.insert(_q, {walk.walk, {368, 14, 9}})
	table.insert(_q, {walk.walk, {368, 14, 12}})
	table.insert(_q, {walk.walk, {368, 17, 12}})
	table.insert(_q, {walk.walk, {368, 17, 11}})
	table.insert(_q, {walk.walk, {368, 19, 11}})
	table.insert(_q, {walk.walk, {368, 19, 12}})
	table.insert(_q, {walk.walk, {368, 22, 12}})
	table.insert(_q, {walk.walk, {368, 22, 15}})
	table.insert(_q, {walk.walk, {368, 13, 15}})
	table.insert(_q, {walk.walk, {368, 13, 18}})
	table.insert(_q, {walk.walk, {368, 14, 18}})
	table.insert(_q, {walk.walk, {368, 14, 19}})
	table.insert(_q, {walk.walk, {368, 16, 19}})
	table.insert(_q, {walk.walk, {368, 16, 20}})
	table.insert(_q, {walk.walk, {368, 23, 20}})
	table.insert(_q, {walk.walk, {368, 23, 24}})
	table.insert(_q, {walk.walk, {369, 6, 8}})
	table.insert(_q, {walk.walk, {369, 6, 15}})
	table.insert(_q, {walk.walk, {369, 25, 15}})
	table.insert(_q, {walk.walk, {369, 25, 20}})
	table.insert(_q, {walk.walk, {369, 9, 20}})
	table.insert(_q, {walk.walk, {369, 9, 19}})
	table.insert(_q, {walk.walk, {369, 7, 19}})
	table.insert(_q, {walk.walk, {369, 7, 20}})
	table.insert(_q, {walk.walk, {369, 6, 20}})
	table.insert(_q, {walk.walk, {370, 15, 15}})
end

local _sequences = {
	{title = "Prologue",      f = _sequence_prologue,      map_area = 3, map_id = 43,  map_x = 14,  map_y = 5},
	{title = "D.Mist",        f = _sequence_d_mist,        map_area = 0, map_id = nil, map_x = 102, map_y = 158},
	{title = "Mist Clip",     f = _sequence_clip,          map_area = 0, map_id = nil, map_x = 84,  map_y = 120},
	{title = "Girl",          f = _sequence_girl,          map_area = 0, map_id = nil, map_x = 96,  map_y = 119},
	{title = "Officer",       f = _sequence_officer,       map_area = 0, map_id = nil, map_x = 103, map_y = 119},
	{title = "Tellah",        f = _sequence_tellah,        map_area = 3, map_id = 16,  map_x = 14,  map_y = 12},
	{title = "Octomamm",      f = _sequence_octomamm,      map_area = 3, map_id = 111, map_x = 7,   map_y = 13},
	{title = "Edward",        f = _sequence_edward,        map_area = 0, map_id = nil, map_x = 125, map_y = 67},
	{title = "Antlion",       f = _sequence_antlion,       map_area = 0, map_id = nil, map_x = 117, map_y = 57},
	{title = "WaterHag",      f = _sequence_waterhag,      map_area = 3, map_id = 121, map_x = 14,  map_y = 20},
	{title = "MomBomb",       f = _sequence_mombomb,       map_area = 3, map_id = 18,  map_x = 4,   map_y = 5},
	{title = "Dragoon",       f = _sequence_dragoon,       map_area = 3, map_id = 127, map_x = 21,  map_y = 14},
	{title = "Twins",         f = _sequence_twins,         map_area = 3, map_id = 74,  map_x = 12,  map_y = 15},
	{title = "Milon",         f = _sequence_milon,         map_area = 3, map_id = 22,  map_x = 14,  map_y = 7},
	{title = "Milon Z.",      f = _sequence_milon_z,       map_area = 3, map_id = 135, map_x = 14,  map_y = 10},
	{title = "Paladin",       f = _sequence_paladin,       map_area = 3, map_id = 135, map_x = 9,   map_y = 10},
	{title = "Karate",        f = _sequence_karate,        map_area = 3, map_id = 135, map_x = 6,   map_y = 10},
	{title = "Baigan",        f = _sequence_baigan,        map_area = 3, map_id = 11,  map_x = 14,  map_y = 15},
	{title = "Kainazzo",      f = _sequence_kainazzo,      map_area = 3, map_id = 42,  map_x = 8,   map_y = 4},
	{title = "Dark Elf",      f = _sequence_dark_elf,      map_area = 0, map_id = nil, map_x = 102, map_y = 155},
	{title = "FlameDog",      f = _sequence_flamedog,      map_area = 3, map_id = 148, map_x = 11,  map_y = 12},
	{title = "Magus Sisters", f = _sequence_magus_sisters, map_area = 3, map_id = 153, map_x = 8,   map_y = 15},
	{title = "Valvalis",      f = _sequence_valvalis,      map_area = 3, map_id = 157, map_x = 15,  map_y = 17},
	{title = "Calbrena",      f = _sequence_calbrena,      map_area = 3, map_id = 52,  map_x = 6,   map_y = 4},
	{title = "Dr.Lugae",      f = _sequence_dr_lugae,      map_area = 3, map_id = 265, map_x = 10,  map_y = 8},
	{title = "Dark Imps",     f = _sequence_dark_imps,     map_area = 3, map_id = 296, map_x = 16,  map_y = 19},
	{title = "Edge",          f = _sequence_edge,          map_area = 3, map_id = 293, map_x = 16,  map_y = 10},
	{title = "Rubicant",      f = _sequence_rubicant,      map_area = 3, map_id = 202, map_x = 22,  map_y = 6},
	{title = "Monsters",      f = _sequence_monsters,      map_area = 3, map_id = 172, map_x = 14,  map_y = 17},
	{title = "Dark Crystal",  f = _sequence_dark_crystal,  map_area = 1, map_id = nil, map_x = 27,  map_y = 87},
	{title = "Big Whale",     f = _sequence_big_whale,     map_area = 3, map_id = 324, map_x = 4,   map_y = 8},
	{title = "FuSoYa",        f = _sequence_fusoya,        map_area = 0, map_id = nil, map_x = 153, map_y = 199},
	{title = "Grind Start",   f = _sequence_grind_start,   map_area = 3, map_id = 303, map_x = 3,   map_y = 13},
	{title = "Elements",      f = _sequence_elements,      map_area = 3, map_id = 188, map_x = 15,  map_y = 16},
	{title = "CPU",           f = _sequence_cpu,           map_area = 3, map_id = 188, map_x = 15,  map_y = 15},
	{title = "Subterrane",    f = _sequence_subterrane,    map_area = 2, map_id = nil, map_x = 19,  map_y = 39},
	{title = "Lunar Core",    f = _sequence_core,          map_area = 3, map_id = 359, map_x = 13,  map_y = 13},
	{title = "Zemus",         f = _sequence_zemus,         map_area = 3, map_id = 366, map_x = 17,  map_y = 8},
}

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _check_autoreload()
	if _state.check_autoreload and dialog.get_save_text(3) == "New" then
		if _state.auto_reload then
			_q = {}

			log.log("Load game screen detected: auto-reloading")

			table.insert(_q, {_state_set, {"check_autoreload", false}})
			table.insert(_q, {menu.wait, {132}})
			table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
			table.insert(_q, {menu.wait, {132}})
			table.insert(_q, {input.press, {{"P1 A"}, input.DELAY.MASH}})
			table.insert(_q, {menu.confirm, {}})
			table.insert(_q, {menu.wait, {132}})
			table.insert(_q, {_state_set, {"check_autoreload", true}})

			_route = {}

			for i = 0, 56 do
				_route[i] = 0
			end
		elseif FULL_RUN then
			log.log("Load game screen detected: ending run")
			_M.end_run()
		end
	end
end

local function _check_sequence()
	if #_q == 0 and walk.is_ready() and not walk.is_mid_tile() and not walk.is_transition() then
		local map_area = memory.read("walk", "map_area")
		local map_id = memory.read("walk", "map_id")
		local map_x = memory.read("walk", "x")
		local map_y = memory.read("walk", "y")

		for _, sequence in pairs(_sequences) do
			if map_area == sequence.map_area and (not sequence.map_id or map_id == sequence.map_id) and map_x == sequence.map_x and map_y == sequence.map_y then
				log.log(string.format("Sequence: %s", sequence.title))
				sequence.f()
				_state.check_healing = true
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	while true do
		_check_autoreload()
		_check_sequence()

		local command = _q[1]

		if command then
			if _state.check_healing and _state.healing and command[1] == walk.walk and not walk.is_mid_tile() and walk.is_ready() then
				_state.healing()
				_state.check_healing = false
			else
				local result = command[1](unpack(command[2]))

				if result then
					table.remove(_q, 1)
				else
					return true
				end
			end
		else
			return true
		end
	end
end

function _M.end_run()
	_state.active = false
end

function _M.is_active()
	return _state.active
end

function _M.set_healing_check()
	_state.check_healing = true
end

function _M.reset()
	_q = {}

	_state = {
		active = true,
		check_autoreload = true,
		check_healing = false,
		multi_change = false,
	}

	if FULL_RUN then
		_sequence_new_game(seed)
	end
end

return _M
