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
local sequence = require "ai.sequence"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _state = {}
local _splits = {}
local _battle_count = 0

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _is_battle()
	return memory.read("battle", "state") > 0
end

local function _check_target(mask, target)
	return (mask & (2 ^ (7 - target))) > 0
end

local function _read_damage(index)
	local value = memory.read("battle", "damage", index)

	if value >= 32768 then
		value = (value - 32768) * -1
	end

	return value
end

local function _get_damage(wall)
	local action_flags = memory.read("battle", "action_flags")
	local target_group = memory.read("battle", "target_group")
	local target_mask = memory.read("battle", "target_mask")
	local wall_active = memory.read("battle", "wall_active")

	local result = ""

	if wall then
		if (action_flags & game.battle.ACTION.MAGIC) > 0 and wall_active then
			target_group = target_group ~ 0x80
			target_mask = memory.read("battle", "wall_targets")
		else
			return ""
		end
	end

	local damage_data = {}

	if target_group == game.battle.ACTOR.ENEMY then
		for i = 0, 7 do
			if _check_target(target_mask, i) then
				table.insert(damage_data, {string.format("Enemy #%d", i), _read_damage(5 + i), game.enemy.get_stat(i, "hp")})
			end
		end
	else
		for i = 0, 5 do
			if _check_target(target_mask, i) then
				local character = game.character.get_character(i)

				if character then
					table.insert(damage_data, {game.character.get_name(character), _read_damage(i), game.character.get_stat(character, "hp", true)})
				end
			end
		end
	end

	local strings = {}

	for i = 1, #damage_data do
		local target = damage_data[i][1]
		local damage = damage_data[i][2]
		local hp = damage_data[i][3]
		local new_damage = ""

		if damage == 16384 then
			new_damage = string.format("misses %s (%d HP)", target, hp)
		elseif damage < 0 then
			new_damage = string.format("heals %s for %d damage (%d HP)", target, damage * -1, hp)
		elseif damage == 0 then
			new_damage = string.format("hits %s for no damage (%d HP)", target, hp)
		else
			new_damage = string.format("hits %s for %d damage (%d HP)", target, damage, hp)
		end

		table.insert(strings, new_damage)
	end

	for i = 1, #strings do
		local conjunction = ", "

		if i == #strings and i > 2 then
			conjunction = ", and "
		elseif i == #strings and i == 2 then
			conjunction = " and "
		elseif i == 1 then
			conjunction = ""
		end

		result = string.format("%s%s%s", result, conjunction, strings[i])
	end

	if wall and result ~= "" then
		result = string.format("it reflects and %s", result)
	end

	return result
end

-- add command queueing
-- add battle result (who lived/died/new exp)
-- rewrite whole system

local function _log_action()
	local action_flags = memory.read("battle", "action_flags")
	local actor_group = memory.read("battle", "actor_group")
	local actor_slot = memory.read("battle", "actor_slot")
	local action_index = memory.read("battle", "action_index")
	local actor

	if actor_group == game.battle.ACTOR.PARTY then
		actor = game.character.get_name(game.character.get_character(actor_slot))

		if actor == nil then
			actor = "Unknown"
		end
	else
		actor = string.format("Enemy #%d", actor_slot)
		actor_slot = actor_slot + 5
	end

	local command = memory.read_stat(actor_slot, "command", true)
	local subcommand = memory.read_stat(actor_slot, "subcommand", true)
	local target_monster = memory.read_stat(actor_slot, "target_monster", true)
	local target_party = memory.read_stat(actor_slot, "target_party", true)

	log.log(string.format("Action: (debug) Command: %02X  Subcommand: %02X  Target Party: %02X  Target Monster: %02X", command, subcommand, target_party, target_monster))

	local action
	local critical = ""

	if (action_flags & game.battle.ACTION.CRITICAL) > 0 then
		critical = "critically "
	end

	if (action_flags & game.battle.ACTION.ATTACK) > 0 then
		action = "attacks"
	elseif (action_flags & game.battle.ACTION.MAGIC) > 0 then
		if action_index == 0 then
			action = string.format("casts %s", game.magic.get_spell_description(memory.read_stat(actor_slot, "subcommand", true)))
		else
			action = string.format("casts %s", game.magic.get_spell_description(action_index))
		end
	elseif (action_flags & game.battle.ACTION.ITEM) > 0 then
		action = string.format("uses %s", game.item.get_description(action_index))
	elseif (action_flags & game.battle.ACTION.COMMAND) > 0 then
		action = string.format("uses %s", game.battle.get_command_description(action_index))
	elseif action_flags == game.battle.ACTION.MISS then
		action = "attacks"
	else
		action = string.format("does an unknown action (%02X)", action_flags)
	end

	local damage = _get_damage(false)

	if damage ~= "" then
		damage = string.format(" and %s", damage)
	end

	local wall_damage = _get_damage(true)

	if wall_damage ~= "" then
		wall_damage = string.format(" and %s", wall_damage)
	end

	log.log(string.format("Action: %s %s%s%s%s", actor, critical, action, damage, wall_damage))
end

local function _reset_state()
	_state = {
		frame = nil,
		formation = nil,
		index = nil,
		q = {},
		slot = nil,
		last_action = nil,
		queued = false,
		inventory = {},
		turns = {
			[0] = 0,
			[1] = 0,
			[2] = 0,
			[3] = 0,
			[4] = 0,
		}
	}
end

--------------------------------------------------------------------------------
-- Inventory Management
--------------------------------------------------------------------------------

local function _sort_priority(a, b)
	return a[1] > b[1]
end

local function _get_current_inventory()
	local inventory = {}

	for i = 0, 47 do
		local item = memory.read("battle_menu", "item_id", i)
		local count = memory.read("battle_menu", "item_count", i)

		if item ~= game.ITEM.NONE then
			inventory[i] = {item, count}
		end
	end

	return inventory
end

local function _get_goal_inventory(inventory_data)
	local current_inventory = _get_current_inventory()

	local fixed_map = {}
	local priority_map = {}

	for i, entry in ipairs(inventory_data) do
		local item, count, fixed, priorities = table.unpack(entry)

		if not count then
			count = "any"
		end

		for index in pairs(fixed) do
			if not fixed_map[item] then
				fixed_map[item] = {}
			end

			if fixed_map[item][count] then
				table.insert(fixed_map[item][count], fixed[index])
			else
				fixed_map[item][count] = {fixed[index]}
			end
		end

		for index in pairs(priorities) do
			if not priority_map[item] then
				priority_map[item] = {}
			end

			if priority_map[item][count] then
				table.insert(priority_map[item][count], priorities[index])
			else
				priority_map[item][count] = {priorities[index]}
			end
		end
	end

	local goal_inventory = {}
	local priority_list = {}

	for i = 0, 47 do
		if current_inventory[i] then
			local item, count = table.unpack(current_inventory[i])
			local map_count = count

			if fixed_map[item] and (fixed_map[item][map_count] or fixed_map[item]["any"]) then
				if not fixed_map[item][map_count] then
					map_count = "any"
				end

				goal_inventory[fixed_map[item][map_count][1]] = {item, count}
				current_inventory[i] = nil

				table.remove(fixed_map[item][map_count], 1)

				if #fixed_map[item][map_count] == 0 then
					fixed_map[item][map_count] = nil
				end
			elseif priority_map[item] and (priority_map[item][map_count] or priority_map[item]["any"]) then
				if not priority_map[item][map_count] then
					map_count = "any"
				end

				table.insert(priority_list, {priority_map[item][map_count][1], item, count})
				current_inventory[i] = nil

				table.remove(priority_map[item][map_count], 1)

				if #priority_map[item][map_count] == 0 then
					priority_map[item][map_count] = nil
				end
			elseif i >= 32 then
				goal_inventory[i] = current_inventory[i]
				current_inventory[i] = nil
			end
		end
	end

	table.sort(priority_list, _sort_priority)

	local priority_index = 1

	for i = 0, 47 do
		if priority_index > #priority_list then
			break
		end

		if not goal_inventory[i] then
			goal_inventory[i] = {priority_list[priority_index][2], priority_list[priority_index][3]}
		end

		priority_index = priority_index + 1
	end

	local end_index = 47

	for i = 47, 0, -1 do
		if current_inventory[i] then
			while goal_inventory[end_index] do
				end_index = end_index - 1
			end

			goal_inventory[end_index] = current_inventory[i]
		end
	end

	return goal_inventory
end

local function _compare_inventory_entry(entry1, entry2)
	if entry1 == entry2 then
		return true
	elseif entry1 and not entry2 then
		return entry1[1] == game.ITEM.NONE
	elseif entry2 and not entry1 then
		return entry2[1] == game.ITEM.NONE
	else
		return entry1[1] == entry2[1] and entry1[2] == entry2[2]
	end
end

local function _manage_inventory(limit, fixed_only, reset)
	-- Edward cannot manage the inventory if he is currently hidden.
	if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
		return false
	end

	if reset then
		_state.inventory = {}
	end

	local inventory_data = route.get_inventory(_state.index)

	if memory.read("battle", "enemies") == 0 then
		log.log("Inventory: No enemies detected. Activating unlimited inventory management.")
		limit = nil
	end

	if limit == 0 then
		return false
	end

	local menu_open = false
	local current_inventory = _get_current_inventory()
	local goal_inventory = _get_goal_inventory(inventory_data)
	local current_position = 0
	local search = true
	local flip = false

	if #_state.inventory > 0 then
		search = false
	end

	local fixed_map = {}

	if fixed_only then
		for i, entry in ipairs(inventory_data) do
			local item, count, fixed, priorities = table.unpack(entry)

			if #fixed > 0 then
				fixed_map[item] = true
			end
		end
	end

	while true do
		local best = {nil, nil, nil}

		if ((limit and limit > 0) or not limit) and #_state.inventory > 0 then
			best = {-1, _state.inventory[1][1], _state.inventory[1][2]}
			table.remove(_state.inventory, 1)
		end

		if search then
			for i = 0, 47 do
				if not _compare_inventory_entry(current_inventory[i], goal_inventory[i]) then
					for j = 0, 47 do
						if i ~= j and current_inventory[i] ~= nil and not _compare_inventory_entry(current_inventory[j], goal_inventory[j]) and _compare_inventory_entry(current_inventory[i], goal_inventory[j]) then
							local item_i = 0
							local item_j = 0

							if current_inventory[i] then
								item_i = current_inventory[i][1]
							end

							if current_inventory[j] then
								item_j = current_inventory[j][1]
							end

							local factor = 1

							if current_inventory[j] == goal_inventory[i] and current_inventory[i] == goal_inventory[j] then
								factor = 2
							end

							if not fixed_only or fixed_map[item_i] or fixed_map[item_j] then
								local distance = (math.abs(i - current_position) + math.abs(j - i)) / factor

								if not best[1] or distance < best[1] then
									best = {distance, i, j}
								end

								distance = (math.abs(j - current_position) + math.abs(i - j)) / factor

								if not best[1] or distance < best[1] then
									best = {distance, j, i}
								end
							end
						end
					end
				end
			end
		end

		if best[1] then
			if limit and limit == 0 then
				log.log(string.format("Inventory: Queueing slots %d and %d", best[2], best[3]))
				table.insert(_state.inventory, {best[2], best[3]})
			else
				log.log(string.format("Inventory: Swapping slots %d and %d", best[2], best[3]))

				if not menu_open then
					table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
					menu_open = true

					if best[3] < best [2] then
						flip = true
					end
				end

				if flip then
					table.insert(_state.q, {menu.battle.item.select, {nil, best[3]}})
					table.insert(_state.q, {menu.battle.item.select, {nil, best[2]}})
				else
					table.insert(_state.q, {menu.battle.item.select, {nil, best[2]}})
					table.insert(_state.q, {menu.battle.item.select, {nil, best[3]}})
				end
			end

			local tmp = current_inventory[best[2]]
			current_inventory[best[2]] = current_inventory[best[3]]
			current_inventory[best[3]] = tmp

			current_position = best[3]
		else
			if #_state.inventory == 0 then
				log.log("Inventory: Couldn't find anything to move")
				_state.disable_inventory = true
			end

			break
		end

		if limit and limit > 0 then
			limit = limit - 1
		end
	end

	if menu_open then
		table.insert(_state.q, {menu.battle.item.close, {}})
	end

	return menu_open
end

--------------------------------------------------------------------------------
-- Command Helpers
--------------------------------------------------------------------------------

local function _command_aim(target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.AIM}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
end

local function _command_magic(type, spell, target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {type}})
	table.insert(_state.q, {menu.battle.magic.cast, {spell, target_type, target, wait, limit}})
end

local function _command_black(spell, target_type, target, wait, limit)
	_command_magic(menu.battle.COMMAND.BLACK, spell, target_type, target, wait, limit)
end

local function _command_call(spell, target_type, target, wait, limit)
	_command_magic(menu.battle.COMMAND.CALL, spell, target_type, target, wait, limit)
end

local function _command_white(spell, target_type, target, wait, limit)
	_command_magic(menu.battle.COMMAND.WHITE, spell, target_type, target, wait, limit)
end

local function _command_ninja(spell, target_type, target, wait, limit)
	_command_magic(menu.battle.COMMAND.NINJA, spell, target_type, target, wait, limit)
end

local function _command_change()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.CHANGE}})
end

local function _command_cover(target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.COVER}})
	table.insert(_state.q, {menu.battle.target, {menu.battle.TARGET.CHARACTER, target}})
end

local function _command_dart(item, target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.DART}})
	table.insert(_state.q, {menu.battle.item.select, {item}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
end

local function _command_duplicate(hand, single, menu_open)
	if not menu_open then
		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
	end

	table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 1}})
	table.insert(_state.q, {menu.battle.equip.select, {hand}})

	if not single then
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
		table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
	end

	if not menu_open then
		table.insert(_state.q, {menu.battle.item.close, {}})
	end
end

local function _command_equip(character, target_weapon)
	local hand, current_weapon = game.character.get_weapon(character, true)

	if current_weapon ~= target_weapon then
		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
		table.insert(_state.q, {menu.battle.item.select, {target_weapon}})
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
		table.insert(_state.q, {menu.battle.item.close, {}})
	end
end

local function _command_dequip(hand)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
	table.insert(_state.q, {menu.battle.equip.select, {hand}})
	table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
	table.insert(_state.q, {menu.battle.item.close, {}})
end

local function _command_fight(target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.FIGHT}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
end

local function _command_jump(target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.JUMP}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
end

local function _command_kick(target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.KICK}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_parry()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.PARRY}})
end

local function _command_run()
	table.insert(_state.q, {input.press, {{"P1 L", "P1 R"}, input.DELAY.NONE}})
	return true
end

local function _command_run_buffer()
	table.insert(_state.q, {menu.battle.run_buffer, {}})
end

local function _command_twin()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.TWIN}})
	table.insert(_state.q, {menu.battle.target, {menu.battle.TARGET.ENEMY_ALL, nil}})
end

local function _command_use_item(item, target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
	table.insert(_state.q, {menu.battle.item.use, {item, nil, target_type, target, wait, limit}})
end

local function _command_use_weapon(character, target_weapon, target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})

	local hand, current_weapon = game.character.get_weapon(character, true)

	if current_weapon ~= target_weapon then
		table.insert(_state.q, {menu.battle.item.select, {target_weapon}})
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
	end

	table.insert(_state.q, {menu.battle.equip.use_weapon, {hand, target_type, target, wait, limit, input.DELAY.MASH}})
end

local function _command_wait_frames(frames)
	table.insert(_state.q, {menu.wait, {frames}})
end

local function _command_wait_text(text, limit)
	table.insert(_state.q, {menu.battle.dialog.wait, {text, limit}})
end

local function _command_wait_actor(target, limit)
	table.insert(_state.q, {menu.wait_actor, {target, limit}})
end

--------------------------------------------------------------------------------
-- Battles
--------------------------------------------------------------------------------

local function _battle_antlion(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 and game.character.get_stat(game.CHARACTER.RYDIA, "hp", true) == 0 and game.item.get_index(game.ITEM.ITEM.LIFE, 0, game.INVENTORY.BATTLE) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		elseif turn == 1 and game.character.get_stat(game.CHARACTER.EDWARD, "hp", true) == 0 and game.item.get_index(game.ITEM.ITEM.LIFE, 0, game.INVENTORY.BATTLE) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDWARD)
		elseif game.enemy.get_stat(0, "hp") < 40 then
			_command_fight()
		else
			if game.enemy.get_stat(0, "hp") < 320 then
				_manage_inventory(1)
			end

			_command_parry()
		end
	elseif character == game.CHARACTER.EDWARD then
		if turn == 1 then
			_command_wait_frames(45)
		elseif turn == 2 then
			_command_run_buffer()
		end

		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.RYDIA then
		if turn == 1 then
			_manage_inventory(1)
		end

		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	end
end

local function _battle_baigan(character, turn, strat)
	local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp", true)
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_cover(game.CHARACTER.TELLAH)
		elseif turn == 2 or turn == 3 then
			if yang_hp > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			elseif porom_hp > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			elseif palom_hp > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
			else
				_command_wait_text(" Meteo")
				_command_equip(character, game.ITEM.WEAPON.LEGEND)
				_manage_inventory(nil)
			end
		else
			_command_wait_text(" Meteo")
			_command_equip(character, game.ITEM.WEAPON.LEGEND)
			_manage_inventory(nil)
		end
	elseif character == game.CHARACTER.PALOM then
		if porom_hp > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
		end
	elseif character == game.CHARACTER.YANG then
		if porom_hp > 0 and (porom_hp < 50 or palom_hp == 0) then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		else
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		end
	elseif character == game.CHARACTER.TELLAH then
		_command_black(game.MAGIC.BLACK.METEO, menu.battle.TARGET.ENEMY_ALL)
	end
end

local function _battle_calbrena(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local rosa_hp = game.character.get_stat(game.CHARACTER.ROSA, "hp", true)
	local cecil_muted = game.character.is_status(game.CHARACTER.CECIL, game.STATUS.MUTE)

	if not _state.jumps then
		_state.jumps = 0
		_state.daggers = 0
	end

	if turn > 1 and game.enemy.get_stat(6, "hp") > 0 then
		_state.jumps = 0
		_state.daggers = 0
		_state.kain_target = nil

		local hp = game.enemy.get_stat(6, "hp")

		if not _state.changed then
			_command_change()
			_state.changed = true
		elseif character == game.CHARACTER.KAIN then
			if hp > 700 and hp < 1350 then
				_command_fight()
			else
				_command_jump()
			end
		elseif character == game.CHARACTER.CECIL then
			if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			end
		else
			_command_parry()
		end
	else
		local cals = 0
		local brenas = 0

		local strongest_cal = {nil, -1}
		local strongest_brena = {nil, -1}

		local weakest_cal = {nil, 65536}

		local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)

		for i = 0, 5 do
			local hp = game.enemy.get_stat(i, "hp")

			if game.enemy.get_id(i) == game.ENEMY.CAL then
				if hp > 0 then
					cals = cals + 1

					if hp > strongest_cal[2] then
						strongest_cal = {i, hp}
					end

					if hp < weakest_cal[2] then
						weakest_cal = {i, hp}
					end
				end
			else
				if hp > 0 then
					brenas = brenas + 1

					if hp > strongest_brena[2] then
						strongest_brena = {i, hp}
					end
				end
			end
		end

		if character == game.CHARACTER.CECIL then
			if _state.daggers < 2 or _state.jumps == 3 then
				if _state.jumps == 3 then
					local frames = 600 - (emu.framecount() - _state.kain_frame)

					if frames > 0 then
						_command_wait_frames(frames)
					end
				end

				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, strongest_brena[1])
				_state.daggers = _state.daggers + 1
			elseif cals == 1 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, strongest_cal[1])
			else
				local target = {nil, 1000}

				for i = 0, 2 do
					local hp = game.enemy.get_stat(i, "hp")
					local min = 0

					if yang_hp > 0 then
						min = 80
					end

					if ((hp > min and hp <= 240) or hp > 700) and i ~= _state.kain_target then
						target = {i, hp}
					end
				end

				if target[1] then
					_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, target[1])
				elseif brenas > 1 and (yang_hp == 0 or _state.yang_no_kick) then
					_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, strongest_brena[1])
				elseif cals > 1 and (yang_hp == 0 or _state.yang_no_kick) then
					_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, weakest_cal[1])
				elseif not cecil_muted and rosa_hp == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				else
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				end
			end
		elseif character == game.CHARACTER.KAIN then
			if turn == 1 then
				_command_run_buffer()
			end

			if _state.jumps == 2 and cals > 1 then
				if not cecil_muted and rosa_hp == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				else
					_command_parry()
				end

				_state.kain_target = nil
			elseif cals > 0 then
				_command_jump(menu.battle.TARGET.ENEMY, strongest_cal[1])
				_state.jumps = _state.jumps + 1
				_state.kain_target = strongest_cal[1]
				_state.kain_frame = emu.framecount()
			else
				_command_fight()
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.SLOW, menu.battle.TARGET.ENEMY_ALL)
			elseif turn == 2 or (cecil_hp > 0 and not cecil_muted) then
				_command_white(game.MAGIC.WHITE.MUTE, menu.battle.TARGET.PARTY_ALL)
			elseif cecil_hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			elseif cecil_hp < 850 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.YANG then
			if cecil_hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			elseif turn <= 3 then
				_command_kick()
			elseif cecil_hp < 600 then
				_state.yang_no_kick = true
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_state.yang_no_kick = true
				_command_parry()
			end
		end
	end
end

local function _battle_cpu(character, turn, strat)
	if ROUTE == "no64-excalbur" then
		if character == game.CHARACTER.EDGE then
			if turn == 1 then
				_command_wait_frames(20)
			end

			_command_dart(game.ITEM.WEAPON.EXCALBUR, menu.battle.TARGET.ENEMY, 0)
		elseif character == game.CHARACTER.CECIL then
			if turn == 2 then
				_command_wait_text(" Quake", 180)
				_manage_inventory(6)
			end

			_command_fight(menu.battle.TARGET.ENEMY, 0)
		elseif character == game.CHARACTER.FUSOYA then
			_command_black(game.MAGIC.BLACK.QUAKE)
		else
			_command_parry()
		end
	elseif ROUTE == "no64-rosa" then
		if character == game.CHARACTER.FUSOYA then
			if turn == 1 then
				_command_black(game.MAGIC.BLACK.METEO)
			else
				_manage_inventory(2)
				_command_black(game.MAGIC.BLACK.NUKE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			else
				_command_wait_text("Maser")
				_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end
		elseif character == game.CHARACTER.RYDIA then
			if turn == 1 or turn == 2 then
				_command_parry()
			else
				if game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
					_command_equip(character, game.ITEM.WEAPON.CHANGE)
				end
				_manage_inventory(nil)
			end
		end
	end
end

local function _battle_d_knight(character, turn, strat)
	if turn == 3 then
		_command_wait_frames(45)

		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})

		if ROUTE ~= "paladin" then
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.SHIELD.PALADIN}})
			table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.L_HAND, input.DELAY.MASH}})
		end

		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.target, {}})
	else
		_command_run_buffer()
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	end
end

local function _battle_d_mist(character, turn, strat)
	local mist_form = memory.read("battle", "monster_state") == 169

	if turn >= 7 and mist_form then
		_command_wait_text("No")
	end

	if character == game.CHARACTER.KAIN then
		if ROUTE ~= "no64-excalbur" and ((strat == "six-initial" and turn == 4) or (strat == "seven-initial" and turn == 5)) then
			table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
			table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
			table.insert(_state.q, {menu.battle.item.close, {}})
		end

		if turn == 2 or game.enemy.get_stat(0, "hp") < 48 then
			if strat == "six-initial" and turn == 2 then
				_command_jump()
			else
				_command_fight()
			end
		else
			if strat == "seven-initial" and turn == 4 then
				_command_wait_frames(390)
			elseif strat == "six-initial" and turn == 3 then
				_command_wait_frames(980)
			end

			_command_jump()
		end
	elseif character == game.CHARACTER.CECIL then
		if strat == "seven-initial" and turn == 5 then
			_command_parry()
		else
			if strat == "six-initial" then
				turn = turn + 1
			end

			if turn == 6 then
				_command_wait_text("No")
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CARROT}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 1}})

				if ROUTE ~= "no64-excalbur" then
					_command_duplicate(game.EQUIP.L_HAND, true, true)
				else
					_command_duplicate(game.EQUIP.L_HAND, false, true)
				end

				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.SHIELD.SHADOW}})
				table.insert(_state.q, {menu.battle.item.close, {}})
			end

			_command_fight()
		end
	end
end

local function _battle_dark_elf(character, turn, strat)
	local dark_elf_hp = game.enemy.get_stat(0, "hp")
	local dark_elf_max_hp = game.enemy.get_stat(0, "hp_max")

	local dragon_hp = game.enemy.get_stat(1, "hp")
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp", true)

	if not _state.cecil_damage and dark_elf_hp < dark_elf_max_hp then
		_state.cecil_damage = dark_elf_max_hp - dark_elf_hp
		log.log(string.format("Note: Cecil's initial damage at Dark Elf was %d.", _state.cecil_damage))
	end

	if character == game.CHARACTER.CECIL then
		if _state.yang_waited and game.enemy.get_stat(1, "hp") == 0 then
			_manage_inventory(nil)
		elseif dragon_hp > 50 and tellah_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif _state.tellah_weaked and dragon_hp > 50 and tellah_hp < 300 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif turn ~= 2 or _state.cecil_damage < 942 then
			_command_fight()
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 1 or turn >= 3 or _state.cecil_damage <= 684 or _state.cecil_damage >= 942 then
			if not _state.yang_waited and turn == 3 then
				_command_wait_text(" Weak", 300)

				if ROUTE ~= "nocw" then
					_command_duplicate(game.EQUIP.L_HAND)
				end

				_state.yang_waited = true
				return true
			end

			if _state.yang_waited then
				_manage_inventory(1)

				if game.enemy.get_stat(1, "hp") < 50 then
					if game.character.get_stat(game.CHARACTER.TELLAH, "hp", true) < 50 then
						_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
					else
						_command_fight()
					end
				elseif game.character.get_stat(game.CHARACTER.TELLAH, "hp", true) < 100 then
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				elseif game.character.get_stat(game.CHARACTER.TELLAH, "mp", true) < 25 then
					_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				else
					_command_parry()
				end
			else
				_command_fight()
			end
		elseif turn == 2 then
			_command_parry()
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.VIRUS, menu.battle.TARGET.CHARACTER, game.CHARACTER.CID)

			if _state.cecil_damage < 942 then
				_command_run_buffer()
				_state.flush_queue = true
			end
		elseif turn == 2 then
			_command_wait_text("Da", 300)

			if ROUTE ~= "nocw" then
				_command_equip(character, game.ITEM.WEAPON.THUNDER)
			end

			_manage_inventory(1)
			_command_black(game.MAGIC.BLACK.WEAK)
			_state.tellah_weaked = true
		elseif game.enemy.get_stat(1, "hp") > 50 then
			if game.character.get_stat(game.CHARACTER.TELLAH, "mp", true) >= 25 then
				_command_black(game.MAGIC.BLACK.WEAK)
			else
				_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			end
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.CID then
		if _state.cecil_damage >= 942 then
			_command_fight()
		else
			_command_parry()
		end
	end
end

local function _battle_dark_imp(character, turn, strat)
	if character == game.CHARACTER.RYDIA then
		_manage_inventory(1)

		if game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 5 then
			_command_black(game.MAGIC.BLACK.ICE1)
		else
			_command_fight()
		end
	else
		_command_fight()
	end
end

local function _battle_dragoon(character, turn, strat)
	_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
end

local function _battle_eblan(character, turn, strat)
	local _, kain_weapon = game.character.get_weapon(game.CHARACTER.KAIN, true)

	local kain_equipped = kain_weapon == game.ITEM.WEAPON.BLIZZARD

	if character ~= game.CHARACTER.KAIN then
		if not kain_equipped and game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif not kain_equipped then
			_command_parry()
		end
	else
		if not _state.stage then
			_command_wait_text("Edge:Da", 1200)
			_command_equip(character, game.ITEM.WEAPON.BLIZZARD)
			_manage_inventory(4)
			_state.stage = 1
			return true
		elseif _state.stage == 1 then
			_command_wait_text("Edge:It", 1200)
			_manage_inventory(2)
			_state.stage = 2
			return true
		elseif _state.stage == 2 then
			_command_wait_text("They be", 1200)
			_manage_inventory(2)
			_state.stage = 3
			return true
		elseif _state.stage == 3 then
			_command_wait_text("King:Ed", 1200)
			_manage_inventory(2)
			_state.stage = 4
			return true
		elseif _state.stage == 4 then
			_command_wait_text(" We're", 1200)
			_manage_inventory(2)
			_state.stage = 5
			return true
		elseif _state.stage == 5 then
			_command_wait_text(" We must", 1200)
			_manage_inventory(2)
			_state.stage = 6
			return true
		elseif _state.stage == 6 then
			_command_wait_text("Queen:", 600)
			_manage_inventory(4)
			_state.stage = 7
			return true
		end
	end
end

local function _battle_elements_excalbur(character, turn, strat)
	local weakest = {nil, 99999}

	for i = 0, 4 do
		local character = game.character.get_character(i)

		if character ~= game.CHARACTER.ROSA and character ~= game.CHARACTER.RYDIA then
			local hp = game.character.get_stat(character, "hp", true)

			if character == game.CHARACTER.CECIL then
				hp = hp * 2
			end

			if hp < weakest[2] then
				weakest = {i, hp}
			end
		end
	end

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			if weakest[1] ~= game.CHARACTER.CECIL and weakest[2] < 1500 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, weakest[1])
			else
				_command_cover(game.CHARACTER.ROSA)
			end
		else
			_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, weakest[1])
		end
	elseif character == game.CHARACTER.EDGE then
		if turn == 5 then
			_command_wait_text(" Ice-3")
			_manage_inventory(6)
		end

		_command_dart(game.ITEM.WEAPON.EXCALBUR)
	elseif character == game.CHARACTER.FUSOYA then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.FIRE3)
		elseif turn == 2 then
			_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
		else
			_command_black(game.MAGIC.BLACK.ICE3, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 1 and strat == 'excalbur-slow' then
			_command_white(game.MAGIC.WHITE.SLOW)
		else
			_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, weakest[1])
		end
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
	end
end

local function _battle_elements_rosa(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)
	local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)

	if character == game.CHARACTER.EDGE then
		if cecil_hp > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
		end
	elseif character == game.CHARACTER.FUSOYA then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.NUKE)
		elseif turn == 2 then
			_command_black(game.MAGIC.BLACK.FIRE3, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 3 then
			_command_black(game.MAGIC.BLACK.FIRE3, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 4 then
			if _state.rosa_queued then
				_command_black(game.MAGIC.BLACK.NUKE, menu.battle.TARGET.ENEMY, 0)
			else
				_command_black(game.MAGIC.BLACK.ICE3, menu.battle.TARGET.ENEMY, 0)
			end

			_state.fusoya_queued = true
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 1 then
			_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.ENEMY, 0)
		elseif turn == 2 then
			_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 3 or turn == 4 then
			_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif game.character.get_stat(game.CHARACTER.ROSA, "mp", true) >= 40 then
			if _state.fusoya_queued then
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.ENEMY, 0)
			else
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end

			_state.rosa_queued = true
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_cover(game.CHARACTER.RYDIA)
		elseif edge_hp == 0 and rydia_hp == 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		end
	elseif character == game.CHARACTER.RYDIA then
		if cecil_hp > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif edge_hp > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
		else
			if game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
				_command_equip(character, game.ITEM.WEAPON.CHANGE)
			end

			_command_parry()
		end
	end
end

local function _battle_elements(character, turn, strat)
	if ROUTE == "no64-rosa" then
		return _battle_elements_rosa(character, turn, strat)
	else
		return _battle_elements_excalbur(character, turn, strat)
	end
end

local function _battle_flamedog(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_cover(game.CHARACTER.TELLAH)
			_command_run_buffer()
		else
			_command_wait_text(" Ice-2")
			_command_duplicate(game.EQUIP.R_HAND, true)
			_manage_inventory(nil)
		end
	elseif character == game.CHARACTER.YANG then
		_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
	elseif character == game.CHARACTER.TELLAH then
		_command_black(game.MAGIC.BLACK.ICE2)
	end
end

local function _battle_gargoyle(character, turn, strat)
	if ROUTE ~= "nocw" then
		_state.full_inventory = true
	end

	if character == game.CHARACTER.CECIL then
		_command_fight()
	elseif character == game.CHARACTER.EDWARD then
		if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
			_command_parry()
		elseif turn == 1 then
			_command_run_buffer()
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 1 and ROUTE == "nocw" then
			table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 1}})
			table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND}})
			table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.CLAW.FIRECLAW}})
			table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.L_HAND}})
			table.insert(_state.q, {menu.battle.item.close, {}})
		end

		_command_fight()
	end
end

local function _battle_general(character, turn, strat)
	_state.full_inventory = true

	local current_map = memory.read("walk", "map_id")

	if game.enemy.get_weakest(game.ENEMY.FIGHTER) then
		if character == game.CHARACTER.CECIL then
			if not _state.yang_queued or _state.cecil_waited then
				_command_fight()
			else
				_command_wait_frames(90)
				_state.cecil_waited = true
				return true
			end
		elseif character == game.CHARACTER.EDWARD then
			if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
				_command_parry()
			elseif turn == 1 then
				_command_run_buffer()
				if game.character.get_stat(game.CHARACTER.EDWARD, "level", true) >= 10 then
					_command_fight(menu.battle.TARGET.ENEMY, 1)
				else
					_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 1)
				end
			else
				_command_fight()
			end
		elseif character == game.CHARACTER.YANG then
			local slot = game.character.get_slot(character)

			if ROUTE == "nocw" and current_map == 73 and memory.read_stat(slot, "r_hand", true) == game.ITEM.CLAW.FIRECLAW then
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 1}})
				table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND}})
				table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.CLAW.FIRECLAW}})
				table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.L_HAND}})
				table.insert(_state.q, {menu.battle.item.close, {}})
			end

			_command_fight()
			_state.yang_queued = true
		end
	else
		_command_wait_text("Retreat")
		_manage_inventory(nil)
	end
end

local function _battle_girl(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		_command_wait_text("Quake")
		_manage_inventory(nil)
		_command_change()
	end
end

local function _battle_golbez(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		local fire_count = game.item.get_count(game.ITEM.WEAPON.FIRE, game.INVENTORY.BATTLE)
		local hand, current_weapon = game.character.get_weapon(character, true)

		local target_weapon = current_weapon

		if current_weapon ~= game.ITEM.WEAPON.FIRE and fire_count > 0 then
			target_weapon = game.ITEM.WEAPON.FIRE
		elseif current_weapon ~= game.ITEM.WEAPON.FIRE and current_weapon ~= game.ITEM.WEAPON.LEGEND then
			target_weapon = game.ITEM.WEAPON.LEGEND
		end

		local fixed = ROUTE == "nocw"

		if turn == 1 then
			if not _state.stage then
				_command_wait_text("Golbez:HA", 600)
				_command_equip(character, target_weapon)
				_state.stage = 0
				return true
			end

			if _state.stage == 0 then
				_manage_inventory(2, fixed)
				_state.stage = 1
				return true
			elseif _state.stage == 1 then
				_command_wait_text(" Is t", 600)
				_manage_inventory(2, fixed)
				_state.stage = 2
				return true
			elseif _state.stage == 2 then
				_command_wait_text(" Now", 600)
				_manage_inventory(2, fixed)
				_state.stage = 3
				return true
			elseif _state.stage == 3 then
				_command_wait_text(" Wait", 600)
				_manage_inventory(1, fixed)
				_state.stage = 4
				return true
			elseif _state.stage == 4 then
				_command_wait_text(" the r", 600)
				_manage_inventory(1, fixed)
				_state.stage = 5
				return true
			elseif _state.stage == 5 then
				_command_wait_text(" Meal", 600)
				_manage_inventory(3, fixed)
				_state.stage = 6
				return true
			elseif _state.stage == 6 then
				_command_wait_text("Golbez:An", 600)
				_manage_inventory(48, fixed)
			end
		end

		_command_fight()
	elseif character == game.CHARACTER.KAIN then
		if turn == 1 then
			_command_wait_frames(10)
			_command_run_buffer()
			_command_wait_frames(30)
			_command_jump()
		elseif game.enemy.get_stat(0, "hp") < 20500 then
			if ROUTE == "nocw" then
				_manage_inventory(nil, true)
			end

			_command_fight()
		else
			if ROUTE == "nocw" then
				_manage_inventory(nil, true)
			end

			_command_jump()
		end
	elseif character == game.CHARACTER.RYDIA then
		if ROUTE == "nocw" then
			_manage_inventory(nil, true)
		end

		_command_black(game.MAGIC.BLACK.FIRE2)
	else
		_command_fight()
	end
end

local function _battle_grind(character, turn, strat)
	local grind_character = game.CHARACTER.EDGE
	local required_dragons = 15
	local cure_item = game.ITEM.ITEM.ELIXIR
	local level = game.character.get_stat(game.CHARACTER.EDGE, "level", true)

	local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)
	local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)

	if ROUTE == "no64-rosa" then
		grind_character = game.CHARACTER.ROSA
		required_dragons = 17
		cure_item = game.ITEM.ITEM.CURE2
		level = game.character.get_stat(game.CHARACTER.ROSA, "level", true)
	end

	if level > 45 then
		return _command_run()
	else
		local PHASE = {
			SETUP = 0,
			GRIND = 1,
			HEAL  = 2,
			END   = 3,
		}

		-- Initialization on first run
		if not _state.phase then
			_state.phase = PHASE.SETUP
			_state.last_character = nil
			_state.attempt_timing_fix = true
			_state.cycle = 1

			if character == game.CHARACTER.EDGE then
				_state.character_index = -2
			else
				_state.character_index = -1
			end
		end

		-- Set the character index, resetting each time we reach FuSoYa.
		if character == game.CHARACTER.FUSOYA then
			_state.character_index = 0
		elseif not _state.waited and not _state.first_waited then
			_state.character_index = _state.character_index + 1
		end

		-- Read various useful memory values.
		local dragon_kills = memory.read("enemy", "kills", 1)
		local dragon_hp = game.enemy.get_stat(1, "hp")
		local fusoya_hp = game.character.get_stat(game.CHARACTER.FUSOYA, "hp", true)

		local weakest = {nil, 99999}

		for i = 0, 4 do
			local hp = memory.read_stat(i, "hp", true)

			if hp < memory.read_stat(i, "hp_max", true) and hp < weakest[2] then
				weakest = {i, hp}
			end
		end

		if _state.character_index > 1 then
			_state.casting_weak = nil
		end

		-- Change phases on FuSoYa's turn or at the end of the cycle if he's dead.
		if dragon_kills >= required_dragons then
			_state.phase = PHASE.END
		elseif _state.phase == PHASE.SETUP and _state.character_index == 0 and _state.setup_complete then
			_state.phase = PHASE.GRIND
		elseif _state.phase == PHASE.GRIND and dragon_kills < required_dragons and (_state.character_index == 0 or _state.character_index == 4 or weakest[2] == 0) and (weakest[2] == 0 or fusoya_hp <= 760 or game.character.get_stat(game.CHARACTER.FUSOYA, "mp", true) < 25 or (ROUTE == "no64-rosa" and _state.healing_searcher)) then
			_state.phase = PHASE.HEAL
			_state.dragon_hp = dragon_hp
			_state.waited = nil
		elseif _state.phase == PHASE.HEAL and _state.character_index == 4 and _state.cured and _state.casted and game.enemy.get_stat(0, "hp") >= 600 then
			_state.cured = nil
			_state.casted = nil
			_state.phase = PHASE.GRIND
		elseif _state.phase == PHASE.GRIND and _state.character_index == 4 and dragon_hp == 0 and dragon_kills >= required_dragons then
			_state.waited = nil
			_state.phase = PHASE.END
		end

		if _state.phase == PHASE.SETUP then
			local type = game.battle.get_type()

			if type == game.battle.TYPE.NORMAL then
				if character == game.CHARACTER.FUSOYA then
					_command_black(game.MAGIC.BLACK.QUAKE)
					_state.quaked = true
				elseif _state.character_index == 1 and _state.quaked then
					if game.enemy.get_stat(2, "hp") == 0 then
						_command_parry()
					else
						_command_wait_text(" Quake", 600)
						_command_parry()
					end

					_state.setup_complete = true
				elseif character == game.CHARACTER.ROSA then
					_command_change()
				else
					_command_parry()
				end
			elseif type == game.battle.TYPE.SURPRISED or type == game.battle.TYPE.BACK_ATTACK then
				if character == game.CHARACTER.EDGE and turn == 1 then
					_command_wait_text("Beam")
					_command_wait_frames(190)
					_command_wait_text("Beam")
					_command_wait_frames(190)
					_command_parry()
				elseif character == game.CHARACTER.FUSOYA then
					_command_black(game.MAGIC.BLACK.QUAKE)
					_state.quaked = true
				elseif _state.character_index == 1 and _state.quaked then
					_command_wait_text(" Quake", 600)
					_command_parry()
					_state.setup_complete = true
				elseif character == game.CHARACTER.ROSA and type ~= game.battle.TYPE.BACK_ATTACK then
					_command_change()
				else
					_command_parry()
				end
			elseif type == game.battle.TYPE.STRIKE_FIRST then
				if character == game.CHARACTER.FUSOYA then
					if turn == 1 then
						_command_black(game.MAGIC.BLACK.LIT3, menu.battle.TARGET.ENEMY, 3)
					elseif turn == 2 then
						_command_black(game.MAGIC.BLACK.QUAKE)
					end
				elseif character == game.CHARACTER.RYDIA then
					if turn == 1 then
						_command_wait_text(" Lit-3", 600)
						_command_parry()
					elseif turn == 2 then
						_command_wait_text(" Quake", 600)
						_command_parry()
						_state.setup_complete = true
					end
				elseif character == game.CHARACTER.ROSA then
					_command_change()
				else
					_command_parry()
				end
			end
		elseif _state.phase == PHASE.GRIND then
			if _state.attacked then
				_state.attacked = nil
			end

			if _state.character_index == 0 then
				if not _state.searcher_hp or _state.waited then
					if game.enemy.get_stat(0, "hp") == _state.searcher_hp then
						_command_parry()
					else
						_command_black(game.MAGIC.BLACK.WEAK, menu.battle.TARGET.ENEMY, 1, true, 600)
						_state.casting_weak = true
					end

					_state.waited = nil
				else
					_command_wait_frames(30)
					_state.waited = true
					return true
				end
			elseif _state.character_index == 1 then
				if dragon_hp > 0 then
					if _state.cycle > 2 and _state.attempt_timing_fix and (strat == "rosa-battle-speed-1" or strat == "excalbur-battle-speed-1") then
						_command_wait_text("..Id", 30)
						table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.FIGHT, input.DELAY.NONE}})
						_command_wait_frames(30)
						table.insert(_state.q, {menu.battle.target, {nil, nil, nil, nil, input.DELAY.NONE}})
					else
						table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.FIGHT, input.DELAY.NONE}})
						table.insert(_state.q, {menu.battle.target, {nil, nil, nil, nil, input.DELAY.NONE}})
					end

					_state.dragon_hp = dragon_hp
					_state.dragon_character = character
				else
					_command_parry()
				end

				_state.cycle = _state.cycle + 1
			elseif _state.character_index == 2 then
				if dragon_kills < required_dragons - 1 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.ENEMY, 1)
				else
					_command_parry()
				end
			elseif _state.character_index == 3 then
				if dragon_hp > 50 and dragon_hp < 15000 then
					_command_fight()
				elseif dragon_kills < required_dragons - 1 then
					if ROUTE == "no64-rosa" and dragon_kills >= 15 then
						_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
					else
						_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.ENEMY, 1)
					end
				else
					_command_parry()
				end
			elseif _state.character_index == 4 then
				if _state.waited then
					_state.searcher_hp = game.enemy.get_stat(0, "hp")

					if _state.searcher_hp < 600 then
						_command_parry()
						_state.healing_searcher = true
					else
						_command_fight()
						_state.healing_searcher = nil
					end

					_state.waited = nil
					_state.attacked = true
				else
					_command_wait_text("Life", 60)
					_state.waited = true
					return true
				end
			else
				if dragon_hp > 0 and dragon_hp < 50 then
					_command_fight()
				elseif dragon_hp > 0 and fusoya_hp == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
				else
					_command_parry()
				end
			end
		elseif _state.phase == PHASE.HEAL then
			_state.attempt_timing_fix = false

			if _state.dragon_character then
				if game.character.get_stat(_state.dragon_character, "hp", true) == 0 or character == _state.dragon_character then
					_state.dragon_hp = _state.dragon_hp + 1
				end
			end

			if _state.fusoya_character then
				if game.character.get_stat(_state.fusoya_character, "hp", true) == 0 or character == _state.fusoya_character then
					_state.fusoya_character = nil
				end
			end

			if fusoya_hp > 0 then
				_state.fusoya_character = nil
			end

			if _state.casting_weak or (dragon_hp > 0 and dragon_hp < 50 and dragon_hp < _state.dragon_hp) then
				_command_fight()
				_state.dragon_hp = dragon_hp
				_state.dragon_character = character
			elseif (_state.attacked or dragon_hp > 50) and character == game.CHARACTER.FUSOYA then
				_command_black(game.MAGIC.BLACK.WEAK, menu.battle.TARGET.ENEMY, 1, true, 600)
				_state.dragon_hp = 15000
				_state.dragon_character = character
				_state.casting_weak = true
			elseif dragon_hp > 0 and fusoya_hp == 0 and (not _state.fusoya_character) then
				_command_wait_text("Fire", 300)
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
				_state.fusoya_character = character
			elseif dragon_hp > 0 and fusoya_hp < 760 then
				_command_use_item(cure_item, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
			elseif game.character.get_stat(game.CHARACTER.FUSOYA, "mp", true) < 100 then
				_command_use_item(cure_item, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
			elseif ROUTE == "no64-excalbur" and _state.healing_searcher then
				_command_use_item(cure_item, menu.battle.TARGET.ENEMY, 0)
			elseif ROUTE == "no64-rosa" and character == game.CHARACTER.FUSOYA and _state.healing_searcher then
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.ENEMY, 0)
			elseif weakest[1] and weakest[2] == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, weakest[1])
			elseif character == game.CHARACTER.FUSOYA and not _state.casted then
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.PARTY_ALL)
				_state.casted = true
			elseif not _state.cured then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
				_state.cured = true
			else
				_command_parry()
			end

			_state.attacked = nil
		elseif _state.phase == PHASE.END then
			local strongest = {nil, 0}

			for i = 0, 4 do
				if game.character.get_character(i) ~= grind_character and (ROUTE ~= "no64-rosa" or game.character.get_character(i) ~= game.CHARACTER.FUSOYA) then
					local hp = memory.read_stat(i, "hp", true)

					if hp > strongest[2] then
						strongest = {i, hp}
					end
				end
			end

			local alive = true

			for i = 0, 4 do
				if memory.read_stat(i, "hp", true) == 0 then
					alive = false
				end
			end

			if _state.waited then
				if ROUTE == "no64-excalbur" and not _state.revived and weakest[1] and weakest[2] == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, weakest[1])
				else
					_state.revived = true

					if character == game.CHARACTER.CECIL then
						if ROUTE == "no64-excalbur" then
							if not _state.duplicated then
								_command_duplicate(game.EQUIP.R_HAND)
								_state.duplicated = true
							end

							_command_parry()
						else
							if edge_hp > 0 then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
							else
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
							end
						end
					elseif character == game.CHARACTER.EDGE then
						if ROUTE == "no64-rosa" then
							_command_parry()
						else
							if strongest[1] and (_state.virus or strongest[2] > 400) then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.PARTY, strongest[1])
							elseif strongest[1] then
								_command_parry()
							else
								_command_equip(character, game.ITEM.CLAW.CATCLAW)
								_command_fight()
							end
						end
					elseif character == game.CHARACTER.FUSOYA then
						if game.character.get_stat(game.CHARACTER.FUSOYA, "mp", true) < 45 then
							if ROUTE == "no64-rosa" then
								_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
							else
								_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
							end
						elseif game.enemy.get_stat(0, "hp") > 50 then
							_command_black(game.MAGIC.BLACK.WEAK)
						elseif ROUTE == "no64-rosa" then
							if game.character.get_stat(game.CHARACTER.ROSA, "hp", true) == 0 then
								_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
							elseif strongest[1] then
								_command_black(game.MAGIC.BLACK.VIRUS, menu.battle.TARGET.PARTY, strongest[1])
							else
								_command_black(game.MAGIC.BLACK.VIRUS, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
							end
						elseif _state.duplicated and game.character.get_stat(game.CHARACTER.EDGE, "hp", true) >= 725 then
							if alive then
								_command_black(game.MAGIC.BLACK.VIRUS, menu.battle.TARGET.PARTY_ALL)
							else
								_command_parry()
							end

							_state.virus = true
						else
							_command_parry()
						end
					elseif character == game.CHARACTER.ROSA then
						if ROUTE == "no64-rosa" then
							if strongest[1] or game.character.get_stat(game.CHARACTER.FUSOYA, "hp", true) > 0 then
								_command_parry()
							else
								_command_fight()
							end
						else
							local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)

							if edge_hp == 0 then
								_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
							elseif edge_hp < 750 then
								_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
							else
								_command_parry()
							end
						end
					elseif character == game.CHARACTER.RYDIA then
						if ROUTE == "no64-rosa" then
							if edge_hp > 0 then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
							else
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
							end
						else
							if not alive then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
							else
								_command_parry()
							end
						end
					end
				end

				_state.waited = nil
			else
				_command_wait_frames(15)
				_state.waited = true
				return true
			end
		end

		_state.last_character = character
	end
end

local function _battle_guards(character, turn, strat)
	if character == game.CHARACTER.CECIL or character == game.CHARACTER.PALOM then
		if character == game.CHARACTER.CECIL and turn == 1 then
			_command_run_buffer()
		end

		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.TELLAH then
		if game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
			_command_equip(character, game.ITEM.WEAPON.CHANGE)
		end

		if game.character.get_stat(game.CHARACTER.PALOM, "hp", true) == 0 and (game.enemy.get_stat(0, "hp") > 0 or game.enemy.get_stat(1, "hp") > 0) then
			_command_black(game.MAGIC.BLACK.VIRUS)
		else
			_manage_inventory(2)
		end
	else
		_command_parry()
	end
end

local function _battle_kainazzo(character, turn, strat)
	local yang_level = game.character.get_stat(game.CHARACTER.YANG, "level", true)

	if character == game.CHARACTER.CECIL or character == game.CHARACTER.YANG then
		if character == game.CHARACTER.CECIL and turn == 1 and yang_level == 13 then
			_command_run_buffer()
		end

		if turn == 2 and not _state.waited then
			_command_wait_text(" Lit-3", 600)
			_state.waited = true
			return true
		end

		if game.enemy.get_stat(0, "hp") == 0 then
			_manage_inventory(nil)
		elseif turn == 1 or game.enemy.get_stat(0, "hp") < 150 then
			_command_fight()
		elseif game.character.get_stat(game.CHARACTER.TELLAH, "hp", true) < 200 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 or game.enemy.get_stat(0, "hp") > 300 then
			_command_black(game.MAGIC.BLACK.LIT3)
		else
			_command_black(game.MAGIC.BLACK.VIRUS)
		end
	else
		_command_parry()
	end
end

local function _battle_karate(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		_command_wait_text("Yang:S")
		_manage_inventory(2)
		_command_wait_text("Yang:A")
		_command_fight()
	else
		_command_parry()
	end
end

local function _battle_lugae1(character, turn, strat)
	if character == game.CHARACTER.KAIN then
		if turn == 1 then
			_command_run_buffer()
			_command_jump(menu.battle.TARGET.ENEMY, 0)
		else
			_command_fight(menu.battle.TARGET.ENEMY, 0)
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 2 then
			_command_wait_text("Dr.:.", 600)
			_manage_inventory(8)
		end

		_command_fight()
	elseif character == game.CHARACTER.RYDIA then
		if turn == 1 then
			_command_call(game.MAGIC.CALL.TITAN)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.CECIL then
		_command_fight(menu.battle.TARGET.ENEMY, 0)
	end
end

local function _battle_lugae2(character, turn, strat)
	local lowest = {nil, 99999}

	for i = 0, 4 do
		if game.character.get_character(i) ~= game.CHARACTER.ROSA and not game.character.is_status_by_slot(i, game.STATUS.JUMPING) then
			local hp = memory.read_stat(i, "hp", true)

			if hp < memory.read_stat(i, "hp_max", true) and hp < lowest[2] then
				lowest = {i, hp}
			end
		end
	end

	if character == game.CHARACTER.KAIN or character == game.CHARACTER.YANG then
		if turn == 1 then
			_command_run_buffer()
		end

		_command_fight()
	elseif lowest[1] and lowest[2] == 0 then
		_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
	elseif character == game.CHARACTER.RYDIA then
		if turn == 1 then
			if game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 40 then
				_command_call(game.MAGIC.CALL.TITAN)
			else
				_command_parry()
			end
		else
			if game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 25 then
				_command_black(game.MAGIC.BLACK.LIT_2)
			else
				_command_fight()
			end
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_parry()
		else
			_command_fight()
		end
	end
end

local function _battle_mages(character, turn, strat)
	if not game.character.is_status(game.CHARACTER.CID, game.STATUS.PARALYZE) then
		return _command_run()
	end
end

local function _battle_milon_carrot(character, turn, strat)
	local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp", true)
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)

	if _state.alternate then
		if game.enemy.get_stat(0, "hp") == 0 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
		else
			_state.full_inventory = true
		end

		local palom_mp = game.character.get_stat(game.CHARACTER.PALOM, "mp", true)
		local porom_mp = game.character.get_stat(game.CHARACTER.POROM, "mp", true)

		local worst_twin = nil

		if palom_hp < 70 and palom_hp < porom_hp then
			worst_twin = {twin = game.CHARACTER.PALOM, hp = palom_hp}
		elseif porom_hp < 70 and porom_hp < palom_hp then
			worst_twin = {twin = game.CHARACTER.POROM, hp = porom_hp}
		elseif palom_mp < 20 and palom_mp < porom_mp then
			worst_twin = {twin = game.CHARACTER.PALOM, mp = palom_mp}
		elseif porom_mp < 20 and porom_mp < palom_mp then
			worst_twin = {twin = game.CHARACTER.POROM, mp = porom_mp}
		end

		local ghast = game.enemy.get_strongest(game.ENEMY.GHAST)

		if _state.fixed_ghast then
			if character == game.CHARACTER.CECIL and turn == 1 then
				ghast = 4
			elseif character == game.CHARACTER.CECIL and turn == 2 then
				ghast = 1
			elseif character == game.CHARACTER.PALOM and turn == 1 then
				ghast = 2
			elseif character == game.CHARACTER.TELLAH and turn == 1 then
				ghast = 3
			end
		end

		if character == game.CHARACTER.CECIL or character == game.CHARACTER.TELLAH then
			local _, cecil_weapon = game.character.get_weapon(game.CHARACTER.CECIL, true)

			if character == game.CHARACTER.CECIL and cecil_weapon ~= game.ITEM.WEAPON.DARKNESS then
				_command_equip(character, game.ITEM.WEAPON.DARKNESS)
			end

			if character == game.CHARACTER.CECIL and game.enemy.get_stat(0, "hp") < 150 then
				_command_fight()
			elseif worst_twin and ((worst_twin.hp and worst_twin.hp < 40) or character == game.CHARACTER.TELLAH) then
				if worst_twin.hp == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
				elseif worst_twin.hp then
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, worst_twin.twin)
				else
					_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, worst_twin.twin)
				end
			elseif ghast then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, ghast)
			elseif character == game.CHARACTER.CECIL then
				_command_fight()
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.PALOM then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, ghast)
			elseif worst_twin and worst_twin.hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			else
				_command_twin()
			end
		elseif character == game.CHARACTER.POROM then
			if worst_twin and worst_twin.hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			else
				_command_twin()
			end
		end
	else
		if character == game.CHARACTER.CECIL then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 4)
			elseif turn == 2 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 2)
			elseif turn == 3 then
				if game.enemy.get_stat(3, "hp") == 0 then
					_command_run_buffer()
				else
					_command_wait_text("Cure2", 60)
				end

				_command_parry()
			elseif turn == 4 then
				_command_wait_text("Cure2", 120)
				_command_equip(character, game.ITEM.WEAPON.DARKNESS)
				_manage_inventory(5)
				_command_wait_text(" Stop")
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.wait, {30}})
				table.insert(_state.q, {input.press, {{"P1 B"}, input.DELAY.MASH}})
				table.insert(_state.q, {menu.wait, {30}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CARROT}})
				table.insert(_state.q, {menu.battle.item.close, {}})

				_command_wait_frames(600)
				_state.alternate = true

				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
			end
		elseif character == game.CHARACTER.PALOM then
			if turn == 1 then
				_command_wait_text("Cure2", 300)
				_manage_inventory(4)
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.BLACK}})
				_command_wait_frames(100)
				_command_black(game.MAGIC.BLACK.FIRE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			else
				_state.alternate = true
				return true
			end
		elseif character == game.CHARACTER.POROM then
			if turn == 1 and palom_hp > 0 then
				_command_wait_frames(3)
				_command_run_buffer()
				_command_twin()
			elseif turn == 2 then
				_command_run_buffer()
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
				_command_run_buffer()
				_state.flush_queue = true
			else
				_state.alternate = true
				return true
			end
		elseif character == game.CHARACTER.TELLAH then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			elseif turn == 2 then
				if porom_hp > 0 then
					_command_wait_frames(20)
					_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				else
					_state.alternate = true
					return true
				end
			else
				_state.alternate = true
				return true
			end
		end
	end
end

local function _battle_milon_twin(character, turn, strat)
	local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp", true)
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)

	local palom_mp = game.character.get_stat(game.CHARACTER.PALOM, "mp", true)
	local porom_mp = game.character.get_stat(game.CHARACTER.POROM, "mp", true)

	local worst_twin

	if palom_hp < 70 and palom_hp < porom_hp then
		worst_twin = {twin = game.CHARACTER.PALOM, hp = palom_hp}
	elseif porom_hp < 70 and porom_hp < palom_hp then
		worst_twin = {twin = game.CHARACTER.POROM, hp = porom_hp}
	elseif palom_mp < 20 and palom_mp < porom_mp then
		worst_twin = {twin = game.CHARACTER.PALOM, mp = palom_mp}
	elseif porom_mp < 20 and porom_mp < palom_mp then
		worst_twin = {twin = game.CHARACTER.POROM, mp = porom_mp}
	end

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 4)
		elseif turn == 2 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
		elseif game.enemy.get_stat(0, "hp") < 150 then
			_command_fight()
		elseif strat == "twin" then
			_command_fight()
		elseif worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin and worst_twin.hp then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin then
			_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.PALOM then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 2)
		elseif strat == "twin_changeless" then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		elseif worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin and worst_twin.mp then
			_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_twin()
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 3)
		elseif worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin and worst_twin.hp then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin then
			_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.POROM then
		if worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		elseif worst_twin and worst_twin.mp then
			_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_twin()
		end
	end
end

local function _battle_milon(character, turn, strat)
	if strat == "twin_changeless" or strat == "twin" then
		return _battle_milon_twin(character, turn, strat)
	else
		return _battle_milon_carrot(character, turn, strat)
	end
end

local function _battle_milon_z_trashcan(character, turn, strat)
	local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp", true)
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)

	local palom_mp = game.character.get_stat(game.CHARACTER.PALOM, "mp", true)
	local porom_mp = game.character.get_stat(game.CHARACTER.POROM, "mp", true)

	local worst_twin

	if palom_hp < 70 and palom_hp < porom_hp then
		worst_twin = {twin = game.CHARACTER.PALOM, hp = palom_hp}
	elseif porom_hp < 70 and porom_hp < palom_hp then
		worst_twin = {twin = game.CHARACTER.POROM, hp = porom_hp}
	elseif palom_mp < 20 and palom_mp < porom_mp then
		worst_twin = {twin = game.CHARACTER.PALOM, mp = palom_mp}
	elseif porom_mp < 20 and porom_mp < palom_mp then
		worst_twin = {twin = game.CHARACTER.POROM, mp = porom_mp}
	end

	local alternate = false

	if palom_hp == 0 then
		alternate = true
	elseif character == game.CHARACTER.CECIL then
		if turn >= 4 then
			alternate = true
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn >= 3 then
			alternate = true
		end
	elseif turn >= 2 then
		alternate = true
	end

	if _state.alternate or alternate then
		local count = 0
		local best = nil

		for i = 0, 4 do
			if memory.read_stat(i, "id", true) ~= 0 then
				local hp = memory.read_stat(i, "hp", true)

				if hp == 0 then
					count = count + 1
					best = i
				end
			end
		end

		if count > 0 and game.character.get_stat(character, "hp", true) < game.character.get_stat(character, "hp_max", true) * 0.5 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, character)
		elseif count > 2 or (character == game.CHARACTER.CECIL and turn == 1 and count > 0) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, best)
		else
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY)
		end
	else
		if character == game.CHARACTER.CECIL then
			if turn == 1 then
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})

				if porom_hp == 0 then
					_state.alternate = true
					_state.full_inventory = true
					return true
				elseif porom_hp < palom_hp and porom_hp < 75 then
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
				elseif palom_hp < porom_hp and palom_hp < 75 then
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
				elseif game.character.is_status(game.CHARACTER.PALOM, game.STATUS.POISON) then
					_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
				elseif game.character.is_status(game.CHARACTER.POROM, game.STATUS.POISON) then
					_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
				elseif game.character.is_status(game.CHARACTER.TELLAH, game.STATUS.POISON) then
					_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				else
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
				end
			elseif turn >= 2 then
				if palom_hp == 0 then
					_state.alternate = true
					_state.full_inventory = true
					return true
				elseif _state.palom_acted then
					if _state.switched then
						_state.alternate = true
						_state.full_inventory = true
						return true
					end

					table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.wait, {30}})
					table.insert(_state.q, {input.press, {{"P1 B"}, input.DELAY.MASH}})
					table.insert(_state.q, {menu.wait, {30}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.TRASHCAN}})
					table.insert(_state.q, {menu.battle.item.close, {}})

					_state.switched = true

					_command_wait_frames(480)
					return true
				else
					_command_parry()
				end
			end
		elseif character == game.CHARACTER.PALOM then
			_state.palom_acted = true

			if porom_hp > 0 then
				_command_black(game.MAGIC.BLACK.ICE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			else
				_state.alternate = true
				_state.full_inventory = true
				return true
			end
		elseif character == game.CHARACTER.TELLAH then
			if palom_hp > 0 then
				if turn == 1 then
					_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				else
					_command_wait_text("TrashCan", 180)

					if game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
						_command_equip(character, game.ITEM.WEAPON.CHANGE)
					end

					_manage_inventory(nil)

					_state.alternate = true
					_state.full_inventory = true
					return true
				end
			else
				_state.alternate = true
				_state.full_inventory = true
				return true
			end
		elseif character == game.CHARACTER.POROM then
			if palom_hp > 0 then
				_command_wait_frames(15)
				_command_run_buffer()
				_command_twin()
			else
				_state.alternate = true
				_state.full_inventory = true
				return true
			end
		end
	end
end

local function _battle_milon_z(character, turn, strat)
	return _battle_milon_z_trashcan(character, turn, strat)
end

local function _battle_mombomb(character, turn, strat)
	local count = 0
	local worst_index = nil
	local worst_hp = nil

	for i = 0, 4 do
		local hp = memory.read_stat(i, "hp", true)

		if hp < memory.read_stat(i, "hp_max", true) then
			if hp < 100 then
				count = count + 1
			end

			if worst_hp == nil or hp < worst_hp then
				worst_index = i
				worst_hp = hp
			end
		end
	end

	if game.enemy.get_stat(0, "hp") > 10000 then
		if character == game.CHARACTER.CECIL or character == game.CHARACTER.YANG then
			_command_fight()
		elseif character == game.CHARACTER.EDWARD or character == game.CHARACTER.RYDIA then
			if turn == 1 and character == game.CHARACTER.EDWARD then
				_command_run_buffer()
			end

			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		elseif character == game.CHARACTER.ROSA then
			if count > 0 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, worst_index)
			else
				_command_parry()
			end
		end
	elseif not _state.kicked and game.enemy.get_stat(0, "hp") > 0 then
		if character == game.CHARACTER.YANG then
			_command_wait_text("Ex", 600)
			_command_wait_frames(60)
			_command_kick()
			_state.kicked = true
		elseif character == game.CHARACTER.ROSA then
			if count > 0 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, worst_index)
			elseif worst_index ~= nil then
				if worst_hp > 0 and worst_hp < 200 then
					_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, worst_index)
				elseif worst_hp == 0 and game.item.get_count(game.ITEM.ITEM.LIFE, game.INVENTORY.BATTLE) > 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, worst_index)
				else
					_command_parry()
				end
			else
				_command_parry()
			end
		else
			_command_parry()
		end
	elseif game.enemy.get_stat(0, "hp") > 0 then
		_command_wait_frames(60)
		return true
	else
		if memory.read("battle", "enemies") <= 2 and not _state.bomb_waited then
			_command_wait_text("Dancing", 180)
			_state.bomb_waited = true
			return true
		end

		local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
		local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)
		local edward_hp = game.character.get_stat(game.CHARACTER.EDWARD, "hp", true)

		local dead_character = nil

		if edward_hp == 0 then
			dead_character = game.CHARACTER.EDWARD
		elseif yang_hp == 0 then
			dead_character = game.CHARACTER.YANG
		elseif cecil_hp == 0 then
			dead_character = game.CHARACTER.CECIL
		end

		if memory.read("battle", "enemies") <= 2 and dead_character and game.item.get_index(game.ITEM.ITEM.LIFE, 0, game.INVENTORY.BATTLE) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, dead_character)
			return false
		elseif memory.read("battle", "enemies") <= 2 then
			_manage_inventory(1)
		end

		if character == game.CHARACTER.ROSA then
			if game.enemy.get_stat(1, "hp") < game.enemy.get_stat(2, "hp") then
				_command_aim(menu.battle.TARGET.ENEMY, 1)
			else
				_command_aim(menu.battle.TARGET.ENEMY, 2)
			end
		elseif character == game.CHARACTER.EDWARD or character == game.CHARACTER.RYDIA then
			local target = 4

			if character == game.CHARACTER.EDWARD and not _state.edward_dagger then
				target = 5
				_state.edward_dagger = true
			elseif character == game.CHARACTER.RYDIA and not _state.rydia_dagger then
				target = 6
				_state.rydia_dagger = true
			end

			if not _state.dagger_wait then
				_state.dagger_wait = true
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, target, true, 120)
			else
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, target)
			end
		else
			_command_fight()
		end
	end
end

local function _battle_moon_run_check(strat)
	local type = game.battle.get_type()
	local _, kain_weapon = game.character.get_weapon(game.CHARACTER.KAIN, true)

	if kain_weapon == game.ITEM.WEAPON.GUNGNIR then
		_state.kain_dupe = true
	end

	if ROUTE == "no64-excalbur" then
		return true
	elseif type ~= game.battle.TYPE.STRIKE_FIRST then
		return true
	elseif not _state.kain_dupe then
		return true
	else
		return false
	end
end

local function _battle_moon(character, turn, strat)
	if _state.dupe_complete then
		_command_run()
		return true
	elseif character == game.CHARACTER.KAIN then
		_command_duplicate(game.EQUIP.L_HAND, false)
		_state.dupe_complete = true
		return true
	else
		_command_parry()
	end
end

local function _battle_octomamm(character, turn, strat)
	local change = false

	if strat == nil then
		strat = "staff-tellah-3"
	end

	if string.sub(strat, 1, 6) == 'change' then
		change = true
	end

	local max_tellah_turn = tonumber(string.sub(strat, -1, -1))

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_equip(character, game.ITEM.WEAPON.DARKNESS)
		elseif turn == 2 then
			table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.WEAPON.SHADOW}})
			table.insert(_state.q, {menu.battle.item.select, {nil, 6}})
			table.insert(_state.q, {menu.battle.item.select, {nil, 6}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.TRASHCAN}})
			table.insert(_state.q, {menu.battle.item.close, {}})
		elseif turn == 3 then
			_manage_inventory(2)
		end

		_command_fight()
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.TELLAH then
		if change and turn == 1 and max_tellah_turn ~= 1 and game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
			_command_equip(character, game.ITEM.WEAPON.CHANGE)
		end

		local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)
		local tellah_mp = game.character.get_stat(game.CHARACTER.TELLAH, "mp", true)

		local cure_turn = 3

		if max_tellah_turn < 3 then
			cure_turn = max_tellah_turn
		end

		if rydia_hp == 0 and tellah_mp >= 8 and turn >= cure_turn then
			_command_white(game.MAGIC.WHITE.LIFE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		elseif tellah_mp >= 9 and ((rydia_hp > 0 and rydia_hp < 15) or game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 80) and turn >= cure_turn then
			_command_white(game.MAGIC.WHITE.CURE2, menu.battle.TARGET.PARTY_ALL)
		elseif turn >= max_tellah_turn then
			if change then
				_command_equip(character, game.ITEM.WEAPON.STAFF)
			end

			if not _state.tellah_stop and tellah_mp >= 15 then
				_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				_state.tellah_stop = true
			else
				_command_parry()
			end
		else
			_command_black(game.MAGIC.BLACK.LIT1)
		end
	end
end

local function _battle_officer(character, turn, strat)
	if turn <= 3 then
		_command_run_buffer()
		_command_fight()
	end
end

local function _battle_ordeals(character, turn, strat)
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)
	local cecil_level = game.character.get_stat(game.CHARACTER.CECIL, "level", true)

	if cecil_level > 1 and porom_hp > 70 then
		if character == game.CHARACTER.PALOM then
			_command_black(game.MAGIC.BLACK.FIRE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		elseif character == game.CHARACTER.CECIL then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		else
			_command_parry()
		end
	else
		return _command_run()
	end
end

local function _battle_red_d_run_check(strat)
	if ROUTE == "no64-rosa" then
		return true
	else
		local formation = memory.read("battle", "formation")

		if route.get_value("C317500") == 0 then
			return true
		elseif formation == game.battle.FORMATION.RED_D_2 then
			return true
		elseif formation == game.battle.FORMATION.RED_D_B and route.get_value("C200001") == 0 then
			return true
		else
			return false
		end
	end
end

local function _battle_red_d(character, turn, strat)
	if character == game.CHARACTER.EDGE then
		_command_ninja(game.MAGIC.NINJA.SMOKE)
	else
		_command_parry()
	end
end

local function _battle_rubicant(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local rosa_hp = game.character.get_stat(game.CHARACTER.ROSA, "hp", true)
	local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp", true)
	local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)
	local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)

	if character == game.CHARACTER.EDGE then
		if turn == 3 and _state.glare_target ~= game.CHARACTER.KAIN and _state.glare_target ~= game.CHARACTER.EDGE then
			_command_wait_actor(game.CHARACTER.ROSA, 300)
			_command_wait_actor(game.CHARACTER.KAIN, 600)
			_command_wait_frames(60)
		end

		if turn == 3 and _state.glare_target == game.CHARACTER.KAIN then
			_command_parry()
		elseif game.character.get_stat(game.CHARACTER.EDGE, "mp", true) >= 20 then
			_command_ninja(game.MAGIC.NINJA.FLOOD)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.KAIN then
		if turn == 1 then
			_command_run_buffer()
			_command_jump()
		elseif turn == 2 or _state.glare_target == game.CHARACTER.EDGE then
			if not _state.glare_target and cecil_hp == 0 then
				_state.glare_target = game.CHARACTER.CECIL
			end

			if _state.glare_target == game.CHARACTER.KAIN then
				_command_run_buffer()
			end

			_command_jump()
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_fight()
		elseif turn == 2 then
			if _state.glare_target == game.CHARACTER.CECIL then
				if rydia_hp > 0 then
					_command_wait_text(" Ice-2", 300)
				end

				_command_fight()
			else
				if not _state.cecil_waited then
					_command_wait_text("Glare", 600)
					_command_wait_frames(60)
					_state.cecil_waited = true
					return true
				end

				if rydia_hp == 0 then
					_state.glare_target = game.CHARACTER.RYDIA
					_command_fight()
				else
					if kain_hp == 0 then
						_state.glare_target = game.CHARACTER.KAIN
					elseif rosa_hp == 0 then
						_state.glare_target = game.CHARACTER.ROSA
					elseif edge_hp == 0 then
						_state.glare_target = game.CHARACTER.EDGE
					end

					_command_cover(game.CHARACTER.RYDIA)
				end
			end
		elseif turn == 3 and _state.glare_target == game.CHARACTER.ROSA then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 3 and _state.glare_target == game.CHARACTER.EDGE then
			-- This is temporarily commented out, since it's not in my notes. If it causes problems, it can be brought back.
			--_command_wait_text(" Ice-2")
			_command_fight()
		elseif turn == 3 and _state.glare_target == game.CHARACTER.RYDIA then
			_command_cover(game.CHARACTER.RYDIA)
		else
			if _state.glare_target == game.CHARACTER.KAIN then
				_command_run_buffer()
			end

			_command_fight()
		end
	elseif character == game.CHARACTER.RYDIA then
		if turn == 2 and _state.glare_target == game.CHARACTER.KAIN then
			_command_wait_frames(15)
			_command_run_buffer()
			_command_call(game.MAGIC.CALL.SHIVA)
		elseif turn == 2 and _state.glare_target == game.CHARACTER.EDGE then
			_command_wait_actor(game.CHARACTER.KAIN, 300)
			_command_wait_frames(60)
			_command_black(game.MAGIC.BLACK.ICE2)
		else
			_command_black(game.MAGIC.BLACK.ICE2)
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 2 then
			if _state.glare_target == game.CHARACTER.CECIL then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			elseif _state.glare_target == game.CHARACTER.RYDIA then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
			elseif _state.glare_target == game.CHARACTER.KAIN then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			elseif _state.glare_target == game.CHARACTER.EDGE then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			elseif _state.glare_target == game.CHARACTER.ROSA then
				_command_parry()
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			end
		elseif turn == 3 and rydia_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		else
			_command_parry()
		end
	end
end

local function _battle_sisters(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp", true)
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)

	if character == game.CHARACTER.CECIL then
		local fire_count = game.item.get_count(game.ITEM.WEAPON.FIRE, game.INVENTORY.BATTLE)
		local hand, current_weapon = game.character.get_weapon(character, true)

		if current_weapon == game.ITEM.WEAPON.FIRE then
			fire_count = fire_count + 1
		end

		if turn == 1 then
			_command_run_buffer()
			_command_cover(game.CHARACTER.TELLAH)
		elseif turn == 2 then
			if not _state.waited then
				_command_wait_text("Magus 3:DE")
				_state.waited = true
				return true
			end

			if tellah_hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			elseif tellah_hp < 310 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			elseif yang_hp > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			elseif cecil_hp < 300 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_command_parry()
			end
		elseif turn >= 3 then
			if tellah_hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				_state.tellah_revived = true
			elseif tellah_hp < 310 and _state.tellah_revived then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			elseif cecil_hp < 300 and _state.tellah_revived then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			elseif yang_hp > 0 then
				_command_run_buffer()
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			else
				_command_wait_text(" Meteo")

				if fire_count == 1 then
					_command_duplicate(game.EQUIP.R_HAND, true)
				end

				_manage_inventory(nil)
			end
		end
	elseif character == game.CHARACTER.YANG then
		if tellah_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			_state.tellah_revived = true
		else
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		end
	else
		_command_black(game.MAGIC.BLACK.METEO)
	end
end

local function _battle_subterrane_run_check(strat)
	local _, kain_weapon = game.character.get_weapon(game.CHARACTER.KAIN, true)

	if kain_weapon == game.ITEM.WEAPON.GUNGNIR then
		_state.kain_dupe = true
	end

	if ROUTE == "no64-excalbur" then
		return true
	elseif not _state.kain_dupe then
		return true
	else
		return false
	end
end

local function _battle_subterrane(character, turn, strat)
	if _state.dupe_complete then
		_command_run()
		return true
	elseif character == game.CHARACTER.KAIN then
		_command_duplicate(game.EQUIP.L_HAND, false)
		_state.dupe_complete = true
		return true
	else
		_command_parry()
	end
end


local function _battle_valvalis(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp", true)
	local rosa_hp = game.character.get_stat(game.CHARACTER.ROSA, "hp", true)
	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)

	local cecil_stone = game.character.is_status(game.CHARACTER.CECIL, game.STATUS.STONE)
	local kain_stone = game.character.is_status(game.CHARACTER.KAIN, game.STATUS.STONE)
	local rosa_stone = game.character.is_status(game.CHARACTER.ROSA, game.STATUS.STONE)

	if character ~= game.CHARACTER.KAIN and (cecil_hp == 0 or kain_hp == 0 or rosa_hp == 0 or cecil_stone or kain_stone or rosa_stone) then
		if kain_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif cecil_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif rosa_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif kain_stone then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif cecil_stone then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		end

		return false
	end

	if character == game.CHARACTER.KAIN then
		if game.enemy.get_stat(0, "hp") < 300 then
			_command_fight()
		else
			_command_jump()
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 1 then
			if not _state.cecil_waited then
				_command_wait_text(" Weak", 300)
				_state.cecil_waited = true
				return true
			end

			_manage_inventory(1)

			if cecil_hp < 700 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_command_cover(game.CHARACTER.ROSA)
			end
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 1 then
			_command_wait_text(" Cure2", 180)
			_command_wait_actor(game.CHARACTER.KAIN, 300)
			_command_wait_frames(60)
			_command_fight()
		elseif turn == 2 or turn == 3 then
			if cecil_hp < 300 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_command_fight()
			end
		else
			_command_wait_frames(15)
			_command_fight()
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 2 then
			_command_wait_actor(game.CHARACTER.KAIN, 300)
			_command_wait_frames(30)
		end

		if turn == 3 then
			if not _state.rosa_max then
				_state.rosa_max = emu.framecount() + 300
			end

			if emu.framecount() < _state.rosa_max and game.enemy.get_stat(0, "defense_base") == 0 then
				_command_wait_frames(15)
				return true
			end

			_command_wait_frames(180)
			_state.rosa_max = nil
		end

		local yang_gradual = game.character.get_gradual_petrification(game.CHARACTER.YANG)
		local rosa_gradual = game.character.get_gradual_petrification(game.CHARACTER.ROSA)
		local cecil_gradual = game.character.get_gradual_petrification(game.CHARACTER.CECIL)
		local kain_gradual = game.character.get_gradual_petrification(game.CHARACTER.KAIN)

		if game.enemy.get_stat(0, "speed_modifier") < 32 then
			_command_white(game.MAGIC.WHITE.SLOW)
		elseif cecil_hp < 400 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif cecil_gradual >= 3 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif yang_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		elseif kain_gradual >= 3 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif yang_gradual >= 3 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		elseif cecil_hp < 700 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif cecil_gradual > 0 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif yang_gradual > 0 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		elseif rosa_gradual > 0 then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		else
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		end
	elseif character == game.CHARACTER.CID then
		if turn >= 4 then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.CID)
		else
			_command_wait_frames(15)
			_command_fight()
		end
	end
end

local function _battle_waterhag(character, turn, strat)
	_command_fight()
end

local function _battle_weeper(character, turn, strat)
	_state.full_inventory = true

	if character == game.CHARACTER.EDWARD then
		if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
			_command_parry()
		elseif turn == 1 then
			_command_run_buffer()
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 0)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.CECIL then
		_command_fight(menu.battle.TARGET.ENEMY, 2)
	else
		_command_fight()
	end
end

local function _battle_zeromus_excalbur(character, turn, strat)
	if not _state.cecil_nuke then
		if character == game.CHARACTER.CECIL then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.CRYSTAL)
			else
				_command_fight()
			end
		elseif character == game.CHARACTER.EDGE then
			if (turn == 10 or turn == 11) and game.character.get_stat(game.CHARACTER.EDGE, "hp", true) < 2000 and game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			else
				_command_dart(game.ITEM.WEAPON.EXCALBUR)
			end
		elseif character == game.CHARACTER.KAIN then
			if turn == 4 and game.character.get_stat(game.CHARACTER.ROSA, "hp", true) > 0 then
				_state.rosa_lived = true
			end

			if turn > 3 and game.character.get_stat(game.CHARACTER.EDGE, "hp", true) < 2000 and _state.rosa_lived then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			elseif turn > 3 and game.character.get_stat(game.CHARACTER.KAIN, "hp", true) < 2000 and _state.rosa_lived then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			elseif turn <= 3 or turn == 6 or turn == 7 then
				_command_fight()
			elseif turn == 4 or turn == 8 or turn >= 9 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			elseif turn == 5 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.BERSK)
			elseif turn == 2 then
				if _state.waited then
					local nuke_target = memory.read("battle", "enemy_target")
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, nuke_target)
					_state.waited = nil
					_state.cecil_nuke = nuke_target == 0
				else
					_command_wait_text(" Nuke")
					_state.waited = true
					return true
				end
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.RYDIA then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		end
	else
		if character == game.CHARACTER.EDGE then
			if turn == 7 or turn == 8 or turn == 11 then
				_command_run_buffer()
			end

			_command_dart(game.ITEM.WEAPON.EXCALBUR)
		elseif character == game.CHARACTER.KAIN then
			if turn == 3 or turn == 5 or turn == 8 or turn >= 12 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			elseif turn == 4 or turn == 6 or turn == 9 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			elseif turn == 10 then
				local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)
				local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp", true)

				if edge_hp < kain_hp then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
				else
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
				end
			elseif turn == 7 or turn == 11 then
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.FIGHT, input.DELAY.NONE}})
				table.insert(_state.q, {menu.battle.target, {nil, nil, nil, nil, input.DELAY.NONE}})
			end
		end
	end
end

local function _battle_zeromus_rosa(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ARMOR.WIZARD}})
			table.insert(_state.q, {menu.battle.item.select, {game.ITEM.WEAPON.DANCING}})
			_command_use_item(game.ITEM.ITEM.CRYSTAL)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.EDGE then
		if turn == 1 then
			_command_dart(game.ITEM.WEAPON.GUNGNIR)
		elseif turn == 2 then
			_command_dart(game.ITEM.WEAPON.DANCING)
		end
	elseif character == game.CHARACTER.KAIN then
		if turn == 1 then
			local zeromus_hp = game.enemy.get_stat(1, "hp")

			log.log(string.format("Deciding Kain's action. Current Zeromus HP: %d", zeromus_hp))

			if zeromus_hp > 19902 then
				log.log("Kain action: Fight/Fight")
				_state.extra_kain = true
				_command_fight()
			elseif zeromus_hp > 18202 then
				log.log("Kain action: Fight/Parry")
				_command_fight()
			else
				log.log("Kain action: Parry/Parry")
				_state.kain_parried = true
				_command_parry()
			end
		elseif turn == 2 then
			if _state.extra_kain then
				_command_fight()
			else
				_command_parry()
			end
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 1 then
			_command_white(game.MAGIC.WHITE.BERSK, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif turn == 2 then
			_command_white(game.MAGIC.WHITE.WHITE)
		elseif turn == 3 then
			_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.PARTY_ALL)
		elseif turn == 4 then
			_command_wait_frames(540)
			_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 5 then
			_command_wait_text("Blk.Hole")
			_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 6 then
			if _state.kain_parried then
				_command_run_buffer()
			end

			_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
		elseif turn == 7 then
			_command_white(game.MAGIC.WHITE.WHITE)
		end
	elseif character == game.CHARACTER.RYDIA then
		if turn == 1 then
			_command_parry()
		elseif turn == 2 then
			if _state.waited then
				local weak_target = memory.read("battle", "enemy_target")

				if weak_target == 1 or weak_target == 3 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, weak_target)
				else
					_command_parry()
				end

				_state.waited = nil
			else
				_command_wait_text("Weak")
				_command_wait_frames(90)
				_state.waited = true
				return true
			end
		end
	end
end

local function _battle_zeromus_nocw(character, turn, strat)
	if character == game.CHARACTER.FUSOYA then
		_command_white(game.MAGIC.WHITE.UPTCO)
	else
		_command_parry()
	end
end

local function _battle_zeromus(character, turn, strat)
	if ROUTE == "no64-excalbur" then
		return _battle_zeromus_excalbur(character, turn, strat)
	elseif ROUTE == "no64-rosa" then
		return _battle_zeromus_rosa(character, turn, strat)
	elseif ROUTE == "nocw" then
		return _battle_zeromus_nocw(character, turn, strat)
	end
end

local _formations = {
	[game.battle.FORMATION.ANTLION]       = {title = "Antlion",                               f = _battle_antlion,  split = true, presplit = true},
	[game.battle.FORMATION.BAIGAN]        = {title = "Baigan",                                f = _battle_baigan,   split = true, presplit = true},
	[game.battle.FORMATION.BARD]          = {title = "Bard",                                  f = nil,              pause = true},
	[game.battle.FORMATION.CALBRENA]      = {title = "Calbrena",                              f = _battle_calbrena, split = true, presplit = true},
	[game.battle.FORMATION.CPU]           = {title = "CPU",                                   f = _battle_cpu,      split = true, presplit = true},
	[game.battle.FORMATION.D_KNIGHT]      = {title = "D.Knight",                              f = _battle_d_knight, split = false},
	[game.battle.FORMATION.D_MIST]        = {title = "D.Mist",                                f = _battle_d_mist,   split = true, presplit = true},
	[game.battle.FORMATION.DARK_ELF]      = {title = "Dark Elf",                              f = _battle_dark_elf, split = true, presplit = true},
	[game.battle.FORMATION.DARK_IMP]      = {title = "Dark Imps",                             f = _battle_dark_imp, split = true, presplit = true},
	[game.battle.FORMATION.DRAGOON]       = {title = "Dragoon",                               f = _battle_dragoon,  split = true, presplit = true},
	[game.battle.FORMATION.EBLAN]         = {title = "K.Eblan/Q.Eblan",                       f = _battle_eblan,    split = true, presplit = true},
	[game.battle.FORMATION.ELEMENTS]      = {title = "Elements",                              f = _battle_elements, split = true, presplit = true},
	[game.battle.FORMATION.FLAMEDOG]      = {title = "FlameDog",                              f = _battle_flamedog, split = true, presplit = true},
	[game.battle.FORMATION.GARGOYLE]      = {title = "Gargoyle",                              f = _battle_gargoyle, split = false},
	[game.battle.FORMATION.GENERAL]       = {title = "General/Fighters",                      f = _battle_general,  split = false},
	[game.battle.FORMATION.GIRL]          = {title = "Girl",                                  f = _battle_girl,     split = true, presplit = true},
	[game.battle.FORMATION.GOLBEZ]        = {title = "Golbez",                                f = _battle_golbez,   split = true, presplit = true},
	[game.battle.FORMATION.GOLBEZ_TELLAH] = {title = "Golbez vs. Tellah",                     f = nil,              pause = true},
	[game.battle.FORMATION.GRIND]         = {title = "Grind Fight",                           f = _battle_grind,    split = true, presplit = true},
	[game.battle.FORMATION.GUARDS]        = {title = "Guards",                                f = _battle_guards,   split = true, presplit = true},
	[game.battle.FORMATION.KAINAZZO]      = {title = "Kainazzo",                              f = _battle_kainazzo, split = true, presplit = true},
	[game.battle.FORMATION.KARATE]        = {title = "Karate",                                f = _battle_karate,   split = true, presplit = true},
	[game.battle.FORMATION.LUGAE1]        = {title = "Dr.Lugae/Balnab",                       f = _battle_lugae1,   split = true, presplit = true},
	[game.battle.FORMATION.LUGAE2]        = {title = "Dr.Lugae",                              f = _battle_lugae2,   split = true, presplit = true},
	[game.battle.FORMATION.MAGE]          = {title = "Mages",                                 f = _battle_mages,    split = false},
	[game.battle.FORMATION.MILON]         = {title = "Milon",                                 f = _battle_milon,    split = true, presplit = true},
	[game.battle.FORMATION.MILON_Z]       = {title = "Milon Z.",                              f = _battle_milon_z,  split = true, presplit = true},
	[game.battle.FORMATION.MOMBOMB]       = {title = "MomBomb",                               f = _battle_mombomb,  split = true, presplit = true},
	[game.battle.FORMATION.MOON_1]        = {title = "MoonCell x2, Pudding x2",               f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_2]        = {title = "Juclyote x2, MoonCell x2, Grenade x1",  f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_3]        = {title = "Procyote x1, Juclyote x2",              f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_4]        = {title = "Procyote x1, Pudding x2",               f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_5]        = {title = "Juclyote x1, Procyote x2",              f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_6]        = {title = "Red Worm x1, Procyote x1, Juclyote x1", f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_7]        = {title = "Red Worm x2",                           f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_8]        = {title = "Pudding x4",                            f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_9]        = {title = "Pudding x2, Grenade x2",                f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_10]       = {title = "Balloon x2, Grenade x2",                f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_11]       = {title = "Slime x1, Tofu x1, Pudding x1",         f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.MOON_12]       = {title = "Red Worm x1, Grenade x3",               f = _battle_moon,     split = false, f_run_check = _battle_moon_run_check},
	[game.battle.FORMATION.OCTOMAMM]      = {title = "Octomamm",                              f = _battle_octomamm, split = true, presplit = true},
	[game.battle.FORMATION.OFFICER]       = {title = "Officer/Soldiers",                      f = _battle_officer,  split = true, presplit = true},
	[game.battle.FORMATION.ORDEALS1]      = {title = "Lilith x1, Red Bone x2",                f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS2]      = {title = "Ghoul x2, Soul x2",                     f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS3]      = {title = "Revenant x1, Ghoul x2",                 f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS4]      = {title = "Zombie x3, Ghoul x2, Revenant x2",      f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS5]      = {title = "Lilith x1",                             f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS6]      = {title = "Soul x2, Ghoul x2, Revenant x2",        f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS7]      = {title = "Soul x3, Ghoul x1, Revenant x1",        f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.ORDEALS8]      = {title = "Lilith x2",                             f = _battle_ordeals,  split = false},
	[game.battle.FORMATION.RED_D_1]       = {title = "Red D. x1",                             f = _battle_red_d,    split = false, f_run_check = _battle_red_d_run_check},
	[game.battle.FORMATION.RED_D_2]       = {title = "Red D. x2",                             f = _battle_red_d,    split = false, f_run_check = _battle_red_d_run_check},
	[game.battle.FORMATION.RED_D_B]       = {title = "Red D. x1, Behemoth x1",                f = _battle_red_d,    split = false, f_run_check = _battle_red_d_run_check},
	[game.battle.FORMATION.RED_D_3]       = {title = "Red D. x3",                             f = _battle_red_d,    split = false, f_run_check = _battle_red_d_run_check},
	[game.battle.FORMATION.RUBICANT]      = {title = "Rubicant",                              f = _battle_rubicant, split = true, presplit = true},
	[game.battle.FORMATION.SISTERS]       = {title = "Magus Sisters",                         f = _battle_sisters,  split = true, presplit = true},
	[game.battle.FORMATION.SUBTERRANE_1]  = {title = "Warlock x1",                            f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_2]  = {title = "Warlock x1, Kary x1",                   f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_3]  = {title = "Warlock x1, Kary x2",                   f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_4]  = {title = "RedGiant x1",                           f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_5]  = {title = "Warlock x1, Kary x1, RedGiant x1",      f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_6]  = {title = "RedGiant x2",                           f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_7]  = {title = "Warlock x2, RedGiant x1",               f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_8]  = {title = "D.Bone x1",                             f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_9]  = {title = "Ging-Ryu x1",                           f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_10] = {title = "D.Bone x1, Warlock x1",                 f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.SUBTERRANE_11] = {title = "King-Ryu x2",                           f = _battle_subterrane, split = false, f_run_check = _battle_subterrane_run_check},
	[game.battle.FORMATION.VALVALIS]      = {title = "Valvalis",                              f = _battle_valvalis, split = true, presplit = true},
	[game.battle.FORMATION.WATERHAG]      = {title = "WaterHag",                              f = _battle_waterhag, split = true, presplit = true},
	[game.battle.FORMATION.WEEPER]        = {title = "Weeper/WaterHag/Imp",                   f = _battle_weeper,   split = false},
	[game.battle.FORMATION.ZEMUS]         = {title = "Zemus",                                 f = nil,              split = false, presplit = true},
	[game.battle.FORMATION.ZEROMUS]       = {title = "Zeromus",                               f = _battle_zeromus,  split = false, presplit = true},
}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if sequence.is_active() and _is_battle() then
		local index = memory.read("battle", "formation")
		local formation = _formations[index]

		if not formation then
			formation = {title = "Unknown", f = nil, split = false}
		end

		if index ~= _state.index then
			_reset_state()
			_state.index = index
			_state.formation = formation
			_state.frame = emu.framecount()
			_state.full_inventory = false
			_state.pending_action = nil
			_state.strat = sequence.get_battle_strat(index)
			_state.last_action = nil
			_battle_count = _battle_count + 1
			log.clear()

			local attack_type = game.battle.get_type()

			local types = {
				[game.battle.TYPE.NORMAL] = "Normal",
				[game.battle.TYPE.STRIKE_FIRST] = "Strike First",
				[game.battle.TYPE.SURPRISED] = "Surprised",
				[game.battle.TYPE.BACK_ATTACK] = "Back Attack",
			}

			local party_level = memory.read("battle", "party_level")
			local stats

			if party_level > 0 then
				stats = string.format("%d/%s/%d/%d", index, types[attack_type], memory.read("battle", "party_level"), memory.read("battle", "enemy_level"))
			else
				stats = string.format("%d/%s/-/-", index, types[attack_type])
			end

			log.log(string.format("Battle Start: %s (%s)", formation.title, stats))

			if _state.strat then
				log.log(string.format("Battle Strat: %s", _state.strat))
			end

			local party_text = ""
			local party_exp_text = ""
			local party_agi_text = ""

			for i = 0, 4 do
				local character = game.character.get_character(game.character.get_slot_from_index(i))

				local delimiter = " / "

				if party_text == "" then
					delimiter = ""
				end

				local front = ""

				if memory.read("party", "formation") == game.FORMATION.TWO_FRONT then
					if i == 1 or i == 3 then
						front = "*"
					end
				else
					if i == 0 or i == 2 or i == 4 then
						front = "*"
					end
				end

				if character then
					party_text = string.format("%s%s%s%s:%d", party_text, delimiter, front, game.character.get_name(character), game.character.get_stat(character, "level"))
					party_exp_text = string.format("%s%s%s:%d", party_exp_text, delimiter, game.character.get_name(character), game.character.get_stat(character, "exp"))
					party_agi_text = string.format("%s%s%s:%d", party_agi_text, delimiter, game.character.get_name(character), game.character.get_stat(character, "agility"))
				else
					party_text = string.format("%s%s%sempty", party_text, delimiter, front)
					party_exp_text = string.format("%s%sempty", party_exp_text, delimiter)
					party_agi_text = string.format("%s%sempty", party_agi_text, delimiter)
				end
			end

			log.log(string.format("Party Formation: %s", party_text))
			log.log(string.format("Party Experience: %s", party_exp_text))
			log.log(string.format("Party Agility: %s", party_agi_text))

			local agility_text = string.format("%d", game.enemy.get_stat(0, "agility"))

			for i = 1, 7 do
				local agility = game.enemy.get_stat(i, "agility")

				if agility > 0 then
					agility_text = string.format("%s %d", agility_text, agility)
				end
			end

			log.log(string.format("Enemy Agility: %s", agility_text))

			if FULL_RUN and CONFIG.SAVESTATE and formation.f then
				savestate.save(string.format("states/%s - %03d - %010d - %03d - %s.state", ROUTE, ENCOUNTER_SEED, SEED, _battle_count, formation.title:gsub('/', '-')))
			end

			if _state.formation.presplit and not _splits[_state.index] then
				sequence.split(_state.formation.title .. " Begin")
			end
		end

		local zeromus_death = false

		if _state.zeromus_split_counter and not _state.final_split then
			if _state.zeromus_split_counter == 0 then
				zeromus_death = true
			else
				_state.zeromus_split_counter = _state.zeromus_split_counter - 1
			end
		elseif ROUTE == "nocw" and index == game.battle.FORMATION.ZEROMUS and memory.read("battle", "monster_cursor") == 0xFF then
			_state.zeromus_split_counter = 4
		elseif index == game.battle.FORMATION.ZEROMUS and memory.read("battle", "flash") == 3 and not _state.final_split then
			zeromus_death = true
		end

		if zeromus_death then
			_state.final_split = true

			sequence.split("Zeromus Death")
			log.freeze()

			if CONFIG.EXTENDED_ENDING then
				sequence.end_run(20 * 60 * 60)
			else
				sequence.end_run(65 * 60)
			end
		end

		local action_flags = memory.read("battle", "action_flags")

		if action_flags ~= game.battle.ACTION.NONE and action_flags ~= _state.last_action then
			_state.pending_action = 5
		end

		_state.last_action = action_flags

		if _state.pending_action ~= nil then
		 	if _state.pending_action == 0 and memory.read("battle", "calculations_left") == 0 then
				_state.pending_action = nil
				_log_action()
			elseif _state.pending_action > 0 then
				_state.pending_action = _state.pending_action - 1
			end
		end

		if ROUTE == "nocw" and formation.pause then
			if _state.pause_delay then
				_state.pause_delay = _state.pause_delay - 1

				if _state.pause_delay == 0 then
					_state.pause_delay = nil
				end
			else
				local paused = memory.read("battle", "paused") ~= 0
				local active = memory.read("battle", "active") == 0xFF
				local delay_counter = memory.read("battle", "delay_counter")

				if (delay_counter == 1 and paused) or (not active and not paused) then
					input.press({"P1 Start"}, input.DELAY.NONE)
					_state.pause_delay = 10
				end
			end
		end

		if formation.f then
			local open = memory.read("battle_menu", "open") > 0
			local slot = memory.read("battle_menu", "slot")

			if not _state.flush_queue then
				if slot ~= _state.slot then
					_state.q = {}
					_state.slot = slot
					_state.queued = false
					_state.turn_logged = nil
					_state.disable_inventory = nil
					menu.reset()
				elseif not open then
					_state.q = {}
					_state.slot = -1
					_state.queued = false
					_state.turn_logged = nil
					_state.disable_inventory = nil
					menu.reset()
				end
			end

			local run = false

			if index == game.battle.FORMATION.ZEROMUS then
				local final_dialog = dialog.get_battle_text(4) == " Zer"

				if final_dialog then
					_state.final_dialog = true
				end

				if _state.final_dialog and not final_dialog and not _state.run_frame then
					_state.run_frame = emu.framecount() + 240
				end

				if not _state.run_frame or emu.framecount() < _state.run_frame then
					run = true
				end
			end

			if run or (formation.f_run_check and formation.f_run_check(_state.strat)) then
				input.press({"P1 L", "P1 R"}, input.DELAY.NONE)
			elseif (open and memory.read("battle_menu", "menu") ~= menu.battle.MENU.NONE) or _state.flush_queue then
				 if #_state.q == 0 and not _state.queued then
					local inventory_limit = 0

					if (formation.full_inventory or _state.full_inventory) and memory.read("battle", "active") ~= 0xFF then
						inventory_limit = 2
					end

					if not _state.turn_logged then
						log.log(string.format("Battle Menu: %s", game.character.get_name(game.character.get_character(slot))))
						_state.turn_logged = true
					end

					if (_state.disable_inventory or not _manage_inventory(inventory_limit)) and not formation.f(game.character.get_character(slot), _state.turns[slot] + 1, _state.strat) then
						_state.turns[slot] = _state.turns[slot] + 1
						_state.queued = true
					end
				end

				if #_state.q > 0 then
					local command = _state.q[1]

					if command then
						if command[1](table.unpack(command[2])) then
							table.remove(_state.q, 1)
						end
					end

					if #_state.q == 0 then
						_state.flush_queue = nil
					end
				end
			end
		else
			input.press({"P1 L", "P1 R"}, input.DELAY.NONE)
		end

		return true
	elseif not _is_battle() then
		if _state.formation then
			local gp = 0

			if memory.read("battle", "ending") == 64 then
				gp = memory.read("battle", "dropped_gp")
			end

			if memory.read("dialog", "spoils_item", 0) ~= game.ITEM.NONE then
				dialog.set_pending_spoils()
			end

			local ending = memory.read("battle", "ending")
			local ending_text = string.format("Unknown: %02X", ending)

			if ending == 0x00 then
				ending_text = "Perished"
			elseif ending == 0x04 then
				ending_text = "Stalemate"
			elseif ending == 0x08 then
				ending_text = "Scripted Defeat"
			elseif ending == 0x20 then
				ending_text = "Victory (no spoils)"
			elseif ending == 0x30 then
				ending_text = "Victory"
			elseif ending == 0x40 then
				ending_text = "Ran Away"
			elseif ending == 0x80 then
				ending_text = "Perished (Type 2)"
			end

			local stats = string.format("%d/%d frames/%d GP dropped/%s", _state.index, emu.framecount() - _state.frame, gp, ending_text)

			log.log(string.format("Battle Complete: %s (%s)", _state.formation.title, stats))

			menu.wait_clear()

			if ending ~= 0x00 and ending ~= 0x80 and _state.formation.split and not _splits[_state.index] then
				sequence.split(_state.formation.title .. " End")
			end

			if _formations[_state.index] then
				_splits[_state.index] = true
			end

			sequence.set_healing_check()

			_reset_state()
		end

		return false
	end
end

function _M.reset()
	_reset_state()
	_battle_count = 0
	_splits = {}
end

return _M
