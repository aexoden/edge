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

local _state = nil
local _splits = {}
local _battle_count = 0

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _is_battle()
	return memory.read("battle", "state") > 0
end

local function _reset_state()
	_state = {
		frame = nil,
		formation = nil,
		index = nil,
		q = {},
		slot = nil,
		queued = false,
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
-- Command Helpers
--------------------------------------------------------------------------------

local function _command_aim(target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.AIM}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
end

local function _command_magic(type, spell, target_type, target, wait, limit)
	table.insert(_state.q, {menu.battle.command.select, {type}})
	table.insert(_state.q, {menu.battle.magic.select, {spell}})
	table.insert(_state.q, {menu.battle.target, {target_type, target, wait, limit}})
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

local function _command_duplicate(hand, single)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
	table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 1}})
	table.insert(_state.q, {menu.battle.equip.select, {hand}})
	--table.insert(_state.q, {menu.wait, {10}})

	if not single then
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
		table.insert(_state.q, {menu.battle.item.select, {game.ITEM.NONE, 0}})
		--table.insert(_state.q, {menu.wait, {10}})
	end

	table.insert(_state.q, {menu.battle.item.close, {}})
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

--------------------------------------------------------------------------------
-- Battles
--------------------------------------------------------------------------------

local function _battle_antlion(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if game.character.get_stat(game.CHARACTER.RYDIA, "hp", true) == 0 and game.item.get_index(game.ITEM.ITEM.LIFE, 0, game.INVENTORY.BATTLE) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.EDWARD then
		if turn == 2 then
			_command_run_buffer()
		end

		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	end
end

local function _battle_baigan(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_cover(game.CHARACTER.TELLAH)
		elseif turn == 2 or turn == 3 then
			if game.character.get_stat(game.CHARACTER.YANG, "hp", true) > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			elseif game.character.get_stat(game.CHARACTER.POROM, "hp", true) > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			elseif game.character.get_stat(game.CHARACTER.PALOM, "hp", true) > 0 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
			else
				_command_wait_text(" Meteo")
				_command_equip(character, game.ITEM.WEAPON.LEGEND)
			end
		else
			_command_wait_text(" Meteo")
			_command_equip(character, game.ITEM.WEAPON.LEGEND)
		end
	elseif character == game.CHARACTER.PALOM then
		if game.character.get_stat(game.CHARACTER.YANG, "hp", true) > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		elseif game.character.get_stat(game.CHARACTER.POROM, "hp", true) > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
		end
	elseif character == game.CHARACTER.YANG then
		if game.character.get_stat(game.CHARACTER.POROM, "hp", true) > 0 then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
		elseif game.character.get_stat(game.CHARACTER.PALOM, "hp", true) > 0 then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
		else
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		end
	elseif character == game.CHARACTER.TELLAH then
		if game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) < 2 then
			_command_equip(character, game.ITEM.WEAPON.THUNDER)
		end

		_command_black(game.MAGIC.BLACK.METEO, menu.battle.TARGET.ENEMY_ALL)
	else
		_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
	end
end

local function _battle_calbrena(character, turn, strat)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)

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

		for i = 0, 5 do
			local hp = game.enemy.get_stat(i, "hp")

			if game.enemy.get_id(i) == game.ENEMY.CAL then
				if hp > 0 then
					cals = cals + 1

					if hp > strongest_cal[2] then
						strongest_cal = {i, hp}
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

					if game.character.get_stat(game.CHARACTER.YANG, "hp", true) > 0 then
						min = 80
					end

					if ((hp > min and hp <= 240) or hp > 700) and i ~= _state.kain_target then
						target = {i, hp}
					end
				end

				if target[1] then
					_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, target[1])
				else
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				end
			end
		elseif character == game.CHARACTER.KAIN then
			if _state.jumps == 2 and cals > 1 then
				_command_parry()
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
			elseif turn == 2 then
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
			elseif cecil_hp < 600 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			else
				_command_kick()
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
			_command_fight(menu.battle.TARGET.ENEMY, 0)
		elseif character == game.CHARACTER.FUSOYA then
			_command_black(game.MAGIC.BLACK.QUAKE)
		else
			_command_parry()
		end
	elseif ROUTE == "no64-rosa" then
		if character == game.CHARACTER.EDGE then
			if turn == 1 then
				_command_change()
			elseif turn == 2 then
				_command_dart(game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 2)
			elseif game.item.get_count(game.ITEM.WEAPON.DANCING, game.INVENTORY.BATTLE) > 0 then
				_command_dart(game.ITEM.WEAPON.DANCING)
			elseif game.character.get_stat(game.CHARACTER.EDGE, "mp", true) >= 25 then
				_command_ninja(game.MAGIC.NINJA.BLITZ)
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.FUSOYA then
			if turn == 1 then
				_command_black(game.MAGIC.BLACK.METEO)
			else
				_command_black(game.MAGIC.BLACK.QUAKE)
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			elseif turn == 2 then
				_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			elseif game.character.get_stat(game.CHARACTER.ROSA, "mp", true) >= 46 then
				_command_white(game.MAGIC.WHITE.WHITE)
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.RYDIA then
			if game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 40 then
				_command_call(game.MAGIC.CALL.TITAN)
			else
				_command_parry()
			end
		elseif character == game.CHARACTER.CECIL then
			if turn == 2 then
				_command_equip(character, game.ITEM.WEAPON.ICEBRAND)
				_command_fight(menu.battle.TARGET.ENEMY, 0)
			else
				_command_fight()
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
	if character == game.CHARACTER.KAIN then
		if turn == 2 or game.enemy.get_stat(0, "hp") < 48 then
			_command_fight()
		else
			if turn == 4 then
				-- TODO: Test this delay against audio cue
				_command_wait_frames(340)
			end

			_command_jump()
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 5 then
			_command_parry()
		else
			if turn == 6 then
				_command_wait_text("No")
				_command_duplicate(game.EQUIP.L_HAND)
			end

			_command_fight()
		end
	end
end

local function _battle_dark_elf(character, turn, strat)
	local elf_hp = game.enemy.get_stat(0, "hp")
	local dragon_hp = game.enemy.get_stat(1, "hp")

	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp", true)
	local tellah_mp = game.character.get_stat(game.CHARACTER.TELLAH, "mp", true)

	local yang_hp = game.character.get_stat(game.CHARACTER.YANG, "hp", true)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)

	local alternate = false

	if character == game.CHARACTER.YANG and elf_hp == 0 and not _state.yang_waited then
		_state.yang_waited = true
		_command_wait_frames(120)
		return true
	end

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_fight()
		elseif elf_hp > 0 then
			_command_fight()
		else
			alternate = true
		end
	elseif character == game.CHARACTER.YANG then
		if elf_hp > 0 and turn == 1 then
			_command_fight()
		else
			alternate = true
		end
	elseif character == game.CHARACTER.CID then
		_command_fight()
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.VIRUS, menu.battle.TARGET.CHARACTER, game.CHARACTER.CID)
		elseif game.character.is_status(game.CHARACTER.TELLAH, game.STATUS.PIG) then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif turn == 2 then
			if dragon_hp == 0 then
				_command_wait_text("Da", 300)
			end

			_command_black(game.MAGIC.BLACK.WEAK)
		else
			alternate = true
		end
	end

	if alternate then
		if dragon_hp > 0 and dragon_hp < 50 then
			if character == game.CHARACTER.YANG and yang_hp > 0 and yang_hp < 50 then
				_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			elseif (cecil_hp > 0 and cecil_hp < 50) or (tellah_hp > 0 and tellah_hp < 50) then
				_command_wait_text("D.B", 600)
				_command_fight()
			else
				_command_fight()
			end
		elseif game.character.is_status(game.CHARACTER.TELLAH, game.STATUS.PIG) then
			_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif tellah_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif tellah_mp < 25 then
			_command_use_item(game.ITEM.ITEM.ETHER1, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif character == game.CHARACTER.TELLAH and dragon_hp > 50 then
			_command_black(game.MAGIC.BLACK.WEAK)
		elseif tellah_hp < 200 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif yang_hp > 0 and yang_hp < 50 then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		else
			_command_parry()
		end
	end
end

local function _battle_dark_imp(character, turn, strat)
	if character == game.CHARACTER.RYDIA and game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 5 then
		_command_black(game.MAGIC.BLACK.ICE1)
	else
		_command_fight()
	end
end

local function _battle_dragoon(character, turn, strat)
	_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
end

local function _battle_eblan(character, turn, strat)
	local _, kain_weapon = game.character.get_weapon(game.CHARACTER.KAIN, true)
	local _, cecil_weapon = game.character.get_weapon(game.CHARACTER.CECIL, true)

	local kain_equipped = kain_weapon == game.ITEM.WEAPON.BLIZZARD
	local cecil_equipped = cecil_weapon == game.ITEM.WEAPON.ICEBRAND

	if character == game.CHARACTER.KAIN and not kain_equipped then
		_command_equip(character, game.ITEM.WEAPON.BLIZZARD)
		_command_parry()
	elseif character == game.CHARACTER.CECIL and not cecil_equipped then
		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
		table.insert(_state.q, {menu.battle.item.select, {game.ITEM.SHIELD.ICE}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.L_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.item.select, {game.ITEM.WEAPON.ICEBRAND}})
		table.insert(_state.q, {menu.battle.item.close, {}})
		_command_parry()
	elseif not kain_equipped and game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
		_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
	elseif not cecil_equipped and game.character.get_stat(game.CHARACTER.CECIL, "hp", true) == 0 then
		_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
	elseif not cecil_equipped or not kain_equipped then
		_command_parry()
	else
		return true
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
		if turn == 1 then
			_command_white(game.MAGIC.WHITE.SLOW)
		else
			_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.PARTY, weakest[1])
		end
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
	end
end

local function _battle_elements_rosa(character, turn, strat)
	if character == game.CHARACTER.EDGE then
		_command_parry()
	elseif character == game.CHARACTER.FUSOYA then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.NUKE)
		elseif turn == 2 then
			_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
		elseif turn == 3 then
			_command_black(game.MAGIC.BLACK.FIRE3, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
		elseif turn == 4 then
			if game.enemy.get_stat(0, "hp") <= 9999 then
				_command_black(game.MAGIC.BLACK.FIRE3, menu.battle.TARGET.ENEMY, 0)
			else
				_command_black(game.MAGIC.BLACK.NUKE, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
				_state.nuke = true
			end
		elseif turn == 5 then
			_command_black(game.MAGIC.BLACK.ICE3)
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 1 or turn == 5 then
			if turn == 1 or _state.nuke then
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.ENEMY, 0)
			end
		elseif turn >= 6 then
			_command_parry()
		else
			_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
		end
	elseif character == game.CHARACTER.CECIL then
		if game.character.get_stat(game.CHARACTER.EDGE, "hp", true) > 0 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
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
		elseif game.character.get_stat(game.CHARACTER.YANG, "hp", true) > 0 then
			_command_run_buffer()
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		end
	elseif character == game.CHARACTER.YANG then
		_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
	elseif character == game.CHARACTER.TELLAH then
		_command_black(game.MAGIC.BLACK.ICE2)
	end
end

local function _battle_gargoyle(character, turn, strat)
	_state.full_inventory = true

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
		_command_fight()
	end
end

local function _battle_general(character, turn, strat)
	_state.full_inventory = true

	if game.enemy.get_weakest(game.ENEMY.FIGHTER) then
		if character == game.CHARACTER.CECIL then
			_command_fight()
		elseif character == game.CHARACTER.EDWARD then
			if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
				_command_parry()
			elseif turn == 1 then
				_command_run_buffer()
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 1)
			else
				_command_fight()
			end
		elseif character == game.CHARACTER.YANG then
			_command_fight()
		end
	end
end

local function _battle_girl(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		_command_wait_frames(300)
		_command_change()
	end
end

local function _battle_golbez(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_equip(character, game.ITEM.WEAPON.FIRE)
			_command_wait_text("Golbez:An")
		end

		if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.KAIN then
		if turn == 1 then
			_command_wait_frames(10)
			_command_run_buffer()
			_command_wait_frames(30)
			_command_jump()
			_state.full_inventory = true
		elseif game.enemy.get_stat(0, "hp") < 20500 then
			_command_fight()
		else
			_command_jump()
		end
	elseif character == game.CHARACTER.RYDIA then
		if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 600 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_call(game.MAGIC.CALL.TITAN)
		end
	else
		_command_fight()
	end
end

local function _battle_grind(character, turn, strat)
	local grind_character = game.CHARACTER.EDGE
	local required_dragons = 15
	local level = game.character.get_stat(game.CHARACTER.EDGE, "level", true)

	if ROUTE == "no64-rosa" then
		grind_character = game.CHARACTER.ROSA
		required_dragons = 17
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
		if _state.phase == PHASE.SETUP and _state.character_index == 0 and _state.setup_complete then
			_state.phase = PHASE.GRIND
		elseif _state.phase == PHASE.GRIND and (_state.character_index == 0 or _state.character_index == 4 or weakest[2] == 0) and (weakest[2] == 0 or fusoya_hp <= 760 or game.character.get_stat(game.CHARACTER.FUSOYA, "mp", true) < 25) then
			_state.phase = PHASE.HEAL
			_state.dragon_hp = dragon_hp
			_state.waited = nil
		elseif _state.phase == PHASE.HEAL and _state.character_index == 4 and _state.cured and _state.casted then
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
				else
					_command_parry()
				end
			elseif type == game.battle.TYPE.SURPRISED or type == game.battle.TYPE.BACK_ATTACK then
				if character == game.CHARACTER.EDGE and turn == 1 then
					_command_ninja(game.MAGIC.NINJA.FLOOD)
				elseif character == game.CHARACTER.FUSOYA then
					_command_wait_text(" Flood")
					_command_black(game.MAGIC.BLACK.QUAKE)
					_state.quaked = true
				elseif _state.character_index == 1 and _state.quaked then
					_command_wait_text(" Quake", 600)
					_command_parry()
					_state.setup_complete = true
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
					if _state.cycle > 2 and _state.attempt_timing_fix then
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
				elseif game.enemy.get_stat(0, "hp") < 800 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.ENEMY, 0)
				elseif dragon_kills < required_dragons - 1 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.ENEMY, 1)
				else
					_command_parry()
				end
			elseif _state.character_index == 4 then
				if _state.waited then
					_command_fight()
					_state.searcher_hp = game.enemy.get_stat(0, "hp")
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
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
			elseif game.character.get_stat(game.CHARACTER.FUSOYA, "mp", true) < 100 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
			elseif game.enemy.get_stat(0, "hp") < 600 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.ENEMY, 0)
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

			if _state.waited then
				if not _state.revived and weakest[1] and weakest[2] == 0 then
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
							if strongest[1] then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.PARTY, strongest[1])
							else
								_command_parry()
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
							_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.FUSOYA)
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
							local alive = true

							for i = 0, 4 do
								if memory.read_stat(i, "hp", true) == 0 then
									alive = false
								end
							end

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
							if game.battle.get_type() ~= game.battle.TYPE.BACK_ATTACK and not _state.changed then
								_command_change()
								_state.changed = true
							else
								if strongest[1] or game.character.get_stat(game.CHARACTER.FUSOYA, "hp", true) > 0 then
									_command_parry()
								else
									_command_fight()
								end
							end
						else
							if game.character.get_stat(game.CHARACTER.EDGE, "hp", true) < 750 then
								_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
							else
								_command_parry()
							end
						end
					elseif character == game.CHARACTER.RYDIA then
						if ROUTE == "no64-rosa" then
							if strongest[1] then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.PARTY, strongest[1])
							else
								_command_parry()
							end
						else
							if strongest[1] and strongest[2] > 400 then
								_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.PARTY, strongest[1])
							else
								_command_parry()
							end
						end
					end
				end

				_state.waited = nil
			else
				_command_wait_frames(60)
				_state.waited = true
				return true
			end
		end

		_state.last_character = character
	end
end

local function _battle_guards(character, turn, strat)
	if character == game.CHARACTER.CECIL or character == game.CHARACTER.PALOM then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	else
		_command_parry()
	end
end

local function _battle_kainazzo(character, turn, strat)
	if character == game.CHARACTER.CECIL or character == game.CHARACTER.YANG then
		if turn == 1 or game.enemy.get_stat(0, "hp") < 150 then
			_command_fight()
		elseif game.character.get_stat(game.CHARACTER.TELLAH, "hp", true) < 200 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
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
		_command_wait_text("Yang:A")
		_command_fight()
	else
		_command_parry()
	end
end

local function _battle_lugae1(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 2 then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 1)
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 0)
		end
	elseif character == game.CHARACTER.KAIN then
		_command_jump(menu.battle.TARGET.ENEMY, 0)
	elseif character == game.CHARACTER.ROSA then
		local index = nil
		local dead = false

		for i = 0, 4 do
			if not game.character.is_status_by_slot(i, game.STATUS.JUMPING) then
				if memory.read_stat(i, "hp", true) == 0 then
					index = i
					dead = true
				elseif memory.read_stat(i, "hp", true) < memory.read_stat(i, "hp_max", true) and bit.band(memory.read_stat(i, "status", true), game.STATUS.CRITICAL) == 0 then
					index = i
				end
			end
		end

		if index then
			if dead then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, index)
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.PARTY, index)
			end
		elseif game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 650 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.RYDIA then
		if game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 40 then
			_command_call(game.MAGIC.CALL.TITAN)
		else
			_command_parry()
		end
	else
		if turn == 2 then
			_command_fight(menu.battle.TARGET.ENEMY, 0)
		else
			_command_fight(menu.battle.TARGET.ENEMY, 1)
		end
	end
end

local function _battle_lugae2(character, turn, strat)
	local lowest = {nil, 99999}

	for i = 0, 4 do
		if not game.character.is_status_by_slot(i, game.STATUS.JUMPING) then
			local hp = memory.read_stat(i, "hp", true)

			if hp < memory.read_stat(i, "hp_max", true) and hp < lowest[2] then
				lowest = {i, hp}
			end
		end
	end

	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local rosa_hp = game.character.get_stat(game.CHARACTER.ROSA, "hp", true)

	if character == game.CHARACTER.CECIL then
		if lowest[2] == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
		elseif lowest[2] < 40 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.PARTY, lowest[1])
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		end
	elseif character == game.CHARACTER.KAIN then
		if cecil_hp == 0 and rosa_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
		else
			_command_jump()
		end
	elseif character == game.CHARACTER.ROSA then
		if turn == 1 and not _state.waited then
			_command_wait_text("Laser ", 300)
			_state.waited = true
			return true
		end

		if lowest[1] then
			if lowest[2] == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.PARTY, lowest[1])
			end
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.RYDIA then
		if cecil_hp == 0 and rosa_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
		elseif game.character.get_stat(game.CHARACTER.RYDIA, "mp", true) >= 40 then
			_command_call(game.MAGIC.CALL.TITAN)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.YANG then
		if cecil_hp == 0 and rosa_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, lowest[1])
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

	if character == game.CHARACTER.CECIL and turn == 1 and porom_hp > 100 then
		_state.alternate = true
		_state.fixed_ghast = true
	end

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
			if worst_twin and ((worst_twin.hp and worst_twin.hp < 40) or character == game.CHARACTER.TELLAH) then
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
				if game.character.get_stat(game.CHARACTER.POROM, "hp", true) > 0 then
					_state.alternate = true
					_state.full_inventory = true
					return true
				end

				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 2)
			elseif turn == 3 then
				_command_parry()
			elseif turn == 4 then
				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.wait, {30}})
				table.insert(_state.q, {input.press, {{"P1 B"}, input.DELAY.MASH}})
				table.insert(_state.q, {menu.wait, {30}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
				table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CARROT}})
				table.insert(_state.q, {menu.battle.item.close, {}})

				_command_wait_frames(480)
				_state.alternate = true

				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
			end
		elseif character == game.CHARACTER.PALOM then
			if turn == 1 then
				_command_black(game.MAGIC.BLACK.FIRE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			else
				_state.alternate = true
				return true
			end
		elseif character == game.CHARACTER.POROM then
			if turn == 1 and palom_hp > 0 then
				_command_run_buffer()
				_command_twin()
			elseif turn == 2 then
				_command_run_buffer()
				_command_fight(menu.battle.TARGET.ENEMY, 0)
			else
				_state.alternate = true
				return true
			end
		elseif character == game.CHARACTER.TELLAH then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
			elseif turn == 2 then
				if porom_hp > 0 then
					_command_wait_frames(120)
					_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				else
					_state.alternate = true
					return true
				end
			elseif turn == 3 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
			else
				_state.alternate = true
				return true
			end
		end
	end
end

local function _battle_milon_twin_changeless(character, turn, strat)
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
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
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
	if strat == "twin_changeless" then
		return _battle_milon_twin_changeless(character, turn, strat)
	elseif strat == "carrot" then
		return _battle_milon_carrot(character, turn, strat)
	end
end

local function _battle_milon_z_trashcan(character, turn, strat)
	if _state.alternate or character == game.CHARACTER.CECIL and turn > 3 or character ~= game.CHARACTER.CECIL and turn >= 2 then
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
		elseif count > 2 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.PARTY, best)
		elseif character == game.CHARACTER.CECIL then
			_command_fight()
		else
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY)
		end
	else
		if character == game.CHARACTER.CECIL then
			if turn == 1 then
				if not _state.cecil_waited then
					_command_wait_text("Poiso", 85)
					_command_wait_text(nil)
					_command_wait_frames(40 + 30)
					_state.cecil_waited = true
					return true
				else
					local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp", true)
					local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp", true)

					if porom_hp < palom_hp and porom_hp < 75 then
						_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
					elseif palom_hp < porom_hp and palom_hp < 75 then
						_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.PALOM)
					else
						_command_parry()
					end
				end
			elseif turn >= 2 then
				if _state.palom then
					table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.wait, {30}})
					table.insert(_state.q, {input.press, {{"P1 B"}, input.DELAY.MASH}})
					table.insert(_state.q, {menu.wait, {30}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.CURE2}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.TRASHCAN}})
					table.insert(_state.q, {menu.battle.item.close, {}})

					_command_wait_frames(480)
					_state.full_inventory = true

					_command_fight()
				else
					_command_run_buffer()
					_command_parry()
				end
			end
		elseif character == game.CHARACTER.PALOM then
			_state.palom = true

			if turn == 1 then
				if game.character.get_stat(game.CHARACTER.POROM, "hp", true) > 0 then
					_command_black(game.MAGIC.BLACK.ICE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.POROM)
				else
					_state.alternate = true
					_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY)
				end
			end
		elseif character == game.CHARACTER.TELLAH then
			if turn == 1 then
				_command_run_buffer()
				_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			end
		elseif character == game.CHARACTER.POROM then
			if turn == 1 and game.character.get_stat(game.CHARACTER.PALOM, "hp", true) > 0 then
				_command_wait_frames(10)
				_command_run_buffer()
				_command_twin()
			else
				_state.alternate = true
				return true
			end
		end
	end
end

local function _battle_milon_z_cure2(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		_command_fight()
	else
		_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 0)
	end
end

local function _battle_milon_z(character, turn, strat)
	if strat == "cure2" then
		return _battle_milon_z_cure2(character, turn, strat)
	elseif strat == "trashcan" then
		return _battle_milon_z_trashcan(character, turn, strat)
	end
end

local function _battle_mombomb(character, turn, strat)
	local count = 0, last

	for i = 0, 4 do
		local hp = memory.read_stat(i, "hp", true)

		if hp < memory.read_stat(i, "hp_max", true) and hp < 100 then
			count = count + 1
			last = i
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
			if count > 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY_ALL)
			elseif count == 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, last)
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
			if count > 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY_ALL)
			elseif count == 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, last)
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

local function _battle_octomamm(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_equip(character, game.ITEM.WEAPON.DARKNESS)
		end

		_command_fight()
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 and game.item.get_count(game.ITEM.WEAPON.CHANGE, game.INVENTORY.BATTLE) > 0 then
			_command_equip(character, game.ITEM.WEAPON.CHANGE)
		end

		local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)
		local tellah_mp = game.character.get_stat(game.CHARACTER.TELLAH, "mp", true)

		if rydia_hp == 0 and tellah_mp >= 8 then
			_command_white(game.MAGIC.WHITE.LIFE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		elseif tellah_mp >= 9 and (rydia_hp > 0 and rydia_hp < 15) or game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 100 then
			_command_white(game.MAGIC.WHITE.CURE2, menu.battle.TARGET.PARTY_ALL)
		elseif game.enemy.get_stat(0, "hp") < 800 then
			if not _state.duplicated_change then
				_state.duplicated_change = true

				if game.character.get_weapon(character) == game.ITEM.WEAPON.CHANGE then
					_command_duplicate(game.EQUIP.R_HAND)
				end

				if tellah_mp >= 15 then
					_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
				else
					_command_parry()
				end
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

local function _battle_red_d(character, turn, strat)
	if character == game.CHARACTER.EDGE then
		_command_ninja(game.MAGIC.NINJA.SMOKE)
	else
		_command_parry()
	end
end

local function _battle_rubicant(character, turn, strat)
	if character == game.CHARACTER.CECIL then
		if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.EDGE then
		if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif game.character.get_stat(game.CHARACTER.EDGE, "mp", true) >= 20 then
			_command_ninja(game.MAGIC.NINJA.FLOOD)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.KAIN then
		if turn == 1 then
			_command_run_buffer()
		end

		_command_jump()
	elseif character == game.CHARACTER.ROSA then
		if game.character.get_stat(game.CHARACTER.KAIN, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
		elseif game.character.get_stat(game.CHARACTER.CECIL, "hp", true) == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		elseif game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 600 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.RYDIA then
		if turn == 1 then
			_command_black(game.MAGIC.BLACK.ICE2)
		else
			_command_call(game.MAGIC.CALL.SHIVA)
		end
	end
end

local function _battle_sisters(character, turn, strat)
	local fight_yang = game.character.get_stat(game.CHARACTER.YANG, "hp", true) > 0 and game.character.get_stat(game.CHARACTER.KAIN, "exp") < 17154
	local tellah_hp = game.character.get_stat(game.CHARACTER.TELLAH, "hp", true)

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_cover(game.CHARACTER.TELLAH)
		else
			if turn == 2 and not _state.duplicated then
				_command_duplicate(game.EQUIP.R_HAND, true)
				_state.duplicated = true
				return true
			end

			if tellah_hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			elseif tellah_hp < 300 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			elseif game.character.get_stat(game.CHARACTER.CECIL, "hp", true) < 500 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
			elseif fight_yang then
				_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
			else
				return true
			end
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 1 then
			_command_duplicate(game.EQUIP.L_HAND)
		end

		if tellah_hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif tellah_hp < 200 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
		elseif fight_yang then
			_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.YANG)
		else
			_command_parry()
		end
	else
		_command_black(game.MAGIC.BLACK.METEO)
	end
end

local function _battle_valvalis_support(character)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp", true)

	if kain_hp == 0 then
		_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
	elseif cecil_hp == 0 then
		_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
	elseif game.character.is_status(game.CHARACTER.KAIN, game.STATUS.STONE) then
		_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
	elseif game.character.is_status(game.CHARACTER.CECIL, game.STATUS.STONE) then
		_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
	elseif cecil_hp < 400 then
		_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
	elseif character == game.CHARACTER.CECIL then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.ROSA then
		_command_parry()
	else
		_command_fight()
	end
end

local function _battle_valvalis(character, turn, strat)
	if character == game.CHARACTER.KAIN then
		if game.enemy.get_stat(0, "hp") < 500 then
			_command_fight()
		else
			_command_jump()
		end
	elseif character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_wait_text(" Weak ", 300)
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
		else
			_battle_valvalis_support(character)
		end
	elseif character == game.CHARACTER.YANG then
		if turn == 1 then
			_command_parry()
		else
			_battle_valvalis_support(character)
		end
	elseif character == game.CHARACTER.ROSA then
		if game.enemy.get_stat(0, "speed_modifier") < 32 then
			_command_white(game.MAGIC.WHITE.SLOW)
		else
			_battle_valvalis_support(character)
		end
	elseif character == game.CHARACTER.CID then
		_battle_valvalis_support(character)
	end
end

local function _battle_waterhag(character, turn, strat)
	_command_fight()
end

local function _battle_weeper(character, turn, strat)
	_state.full_inventory = true

	if not _state.turn_count then
		_state.turn_count = 0
	end

	_state.turn_count = _state.turn_count + 1

	if character == game.CHARACTER.EDWARD then
		if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
			_command_parry()
		elseif turn == 1 then
			_state.full_inventory = true
			_command_run_buffer()
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 0)
			_state.edward = true
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.CECIL then
		if _state.turn_count == 2 and _state.edward then
			_command_run_buffer()
		end

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
			if turn > 3 and game.character.get_stat(game.CHARACTER.EDGE, "hp", true) < 2000 then
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.EDGE)
			elseif turn > 3 and game.character.get_stat(game.CHARACTER.KAIN, "hp", true) < 2000 then
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
					_command_wait_text(" Nuke ")
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
				table.insert(_state.q, {menu.battle.target, {target_type, target, nil, nil, input.DELAY.NONE}})
			end
		end
	end
end

local function _battle_zeromus_rosa(character, turn, strat)
	-- Constants
	local MIDGAME = {
		STANDARD   = 0,
		RYDIA_NUKE = 1,
		CECIL_ONLY = 2,
		CECIL_NUKE = 3,
	}

	-- Collect some useful HP values.
	local rosa_hp = game.character.get_stat(game.CHARACTER.ROSA, "hp", true)
	local kain_hp = game.character.get_stat(game.CHARACTER.KAIN, "hp", true)
	local cecil_hp = game.character.get_stat(game.CHARACTER.CECIL, "hp", true)
	local edge_hp = game.character.get_stat(game.CHARACTER.EDGE, "hp", true)
	local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp", true)

	-- Handle the switches between phase and tracking characters' turns within those phases.
	if not _state.phase then
		_state.phase = 1
		_state.last_phase = {}
		_state.turn_base = {}
	end

	-- Switch to phase 2 when the turns get high enough.
	if _state.phase == 1 and (turn > 3 or (turn > 2 and character ~= game.CHARACTER.ROSA)) then
		_state.phase = 2

		if _state.cecil_nuke and kain_hp > 20 and rosa_hp > 20 and edge_hp > 20 then
			log.log("Cecil nuked. Using Cecil Nuke midgame.")
			_state.midgame = MIDGAME.CECIL_NUKE
		elseif kain_hp > 20 and rosa_hp > 20 and cecil_hp > 20 and edge_hp > 20 then
			log.log("Cecil and Edge alive. Using standard midgame.")
			_state.midgame = MIDGAME.STANDARD
		elseif kain_hp > 20 and rosa_hp > 20 and cecil_hp > 20 and _state.rydia_nuke then
			log.log("Cecil alive, and Rydia nuked. Using Rydia Nuke midgame.")
			_state.midgame = MIDGAME.RYDIA_NUKE
		elseif kain_hp > 20 and rosa_hp > 20 and cecil_hp > 20 then
			log.log("Cecil alive, and Rydia not nuked. Using Cecil Only midgame.")
			_state.midgame = MIDGAME.CECIL_ONLY
		else
			log.log("Do not have a midgame defined for this situation. Expect a rapid death.")
		end
	end

	if not _state.last_phase[character] then
		_state.last_phase[character] = 0
	end

	if _state.last_phase[character] ~= _state.phase then
		_state.turn_base[character] = turn - 1
		_state.last_phase[character] = _state.phase
	end

	turn = turn - _state.turn_base[character]

	if _state.phase == 1 then
		if character == game.CHARACTER.CECIL then
			if turn == 1 then
				_command_use_item(game.ITEM.ITEM.CRYSTAL)
			elseif turn == 2 then
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.BERSK, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
			elseif turn == 2 then
				_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)

				if rydia_hp == 0 then
					_state.rydia_nuke = true
					log.log("Detected Rydia Nuke.")
				elseif cecil_hp == 0 then
					_state.cecil_nuke = true
					log.log("Detected Cecil Nuke.")
				end
			elseif turn == 3 then
				_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end
		elseif character == game.CHARACTER.EDGE then
			if turn == 1 then
				_command_dart(game.ITEM.STAR.NINJA)
			elseif turn == 2 then
				if cecil_hp == 0 then
					_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
				else
					_command_parry()
				end
			end
		elseif character == game.CHARACTER.RYDIA then
			if turn == 1 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
			elseif turn == 2 then
				_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
			end
		end
	elseif _state.phase == 2 then
		if character == game.CHARACTER.CECIL then
			if _state.midgame == MIDGAME.STANDARD then
				if turn == 1 then
					_command_parry()
				elseif turn == 2 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				elseif turn == 3 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			elseif _state.midgame == MIDGAME.RYDIA_NUKE then
				if turn == 1 then
					table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
					table.insert(_state.q, {menu.wait, {60}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(_state.q, {menu.battle.target, {menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN}})
				elseif turn == 2 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				elseif turn == 3 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			elseif _state.midgame == MIDGAME.CECIL_ONLY then
				if turn == 1 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
				elseif turn == 2 then
					table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
					table.insert(_state.q, {menu.wait, {90}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(_state.q, {menu.battle.item.select, {game.ITEM.ITEM.ELIXIR}})
					table.insert(_state.q, {menu.battle.target, {menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA}})
				elseif turn == 3 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			elseif _state.midgame == MIDGAME.CECIL_NUKE then
				if turn == 1 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				elseif turn == 2 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			end
		elseif character == game.CHARACTER.EDGE then
			if _state.midgame == MIDGAME.CECIL_NUKE then
				if turn == 1 then
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
				elseif turn == 2 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			else
				if turn == 1 then
					_command_wait_text("White")
					_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.KAIN)
				elseif turn == 2 then
					_command_parry()
				else
					_state.phase = 3
					return true
				end
			end
		elseif character == game.CHARACTER.ROSA then
			if turn == 1 then
				_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			else
				_state.phase = 3
				return true
			end
		end
	else
		if character == game.CHARACTER.ROSA then
			if _state.kain_extra_turn then
				turn = turn - 1
			end

			if turn == 1 then
				if not _state.kain_extra_turn and game.enemy.get_stat(1, "hp") > 21000 then
					_state.kain_extra_turn = true
					log.log(string.format("Zeromus has %s HP, giving Kain an extra turn", game.enemy.get_stat(1, "hp")))
					_command_parry()
				else
					if not _state.kain_extra_turn then
						log.log(string.format("Zeromus has %s HP, not giving Kain an extra turn", game.enemy.get_stat(1, "hp")))
						_command_wait_text("BlkHo")
						_command_wait_frames(300)
					end

					_command_white(game.MAGIC.WHITE.WALL, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
				end
			elseif turn == 2 then
				_command_white(game.MAGIC.WHITE.WHITE, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			elseif turn == 3 then
				-- TODO: Develop a way to determine if a run buffer was successful. If so, cast White directly here.
				_command_wait_text("BlkHo", 600)
				_command_white(game.MAGIC.WHITE.CURE4, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			elseif turn == 4 then
				_command_white(game.MAGIC.WHITE.WHITE)
			end
		elseif character == game.CHARACTER.KAIN then
			if turn == 1 then
				_command_run_buffer()
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			elseif turn == 2 then
				_command_use_item(game.ITEM.ITEM.HEAL, menu.battle.TARGET.ENEMY, 0)
			elseif turn == 3 then
				_command_run_buffer()
				_command_parry()
			else
				_command_use_item(game.ITEM.ITEM.ELIXIR, menu.battle.TARGET.CHARACTER, game.CHARACTER.ROSA)
			end
		end
	end
end

local function _battle_zeromus(character, turn, strat)
	if ROUTE == "no64-excalbur" then
		return _battle_zeromus_excalbur(character, turn, strat)
	else
		return _battle_zeromus_rosa(character, turn, strat)
	end
end

local _formations = {
	[game.battle.FORMATION.ANTLION]  = {title = "Antlion",                f = _battle_antlion,  split = true,  full_inventory = true},
	[game.battle.FORMATION.BAIGAN]   = {title = "Baigan",                 f = _battle_baigan,   split = true,  full_inventory = true},
	[game.battle.FORMATION.CALBRENA] = {title = "Calbrena",               f = _battle_calbrena, split = true},
	[game.battle.FORMATION.CPU]      = {title = "CPU",                    f = _battle_cpu,      split = true},
	[game.battle.FORMATION.D_KNIGHT] = {title = "D.Knight",               f = _battle_d_knight, split = false},
	[game.battle.FORMATION.D_MIST]   = {title = "D.Mist",                 f = _battle_d_mist,   split = true},
	[game.battle.FORMATION.DARK_ELF] = {title = "Dark Elf",               f = _battle_dark_elf, split = true},
	[game.battle.FORMATION.DARK_IMP] = {title = "Dark Imps",              f = _battle_dark_imp, split = true},
	[game.battle.FORMATION.DRAGOON]  = {title = "Dragoon",                f = _battle_dragoon,  split = true},
	[game.battle.FORMATION.EBLAN]    = {title = "K.Eblan/Q.Eblan",        f = _battle_eblan,    split = true,  full_inventory = true},
	[game.battle.FORMATION.ELEMENTS] = {title = "Elements",               f = _battle_elements, split = true},
	[game.battle.FORMATION.FLAMEDOG] = {title = "FlameDog",               f = _battle_flamedog, split = true},
	[game.battle.FORMATION.GARGOYLE] = {title = "Gargoyle",               f = _battle_gargoyle, split = false},
	[game.battle.FORMATION.GENERAL]  = {title = "General/Fighters",       f = _battle_general,  split = false},
	[game.battle.FORMATION.GIRL]     = {title = "Girl",                   f = _battle_girl,     split = true,  full_inventory = true},
	[game.battle.FORMATION.GOLBEZ]   = {title = "Golbez",                 f = _battle_golbez,   split = true},
	[game.battle.FORMATION.GRIND]    = {title = "Grind Fight",            f = _battle_grind,    split = true, presplit = true},
	[game.battle.FORMATION.GUARDS]   = {title = "Guards",                 f = _battle_guards,   split = false},
	[game.battle.FORMATION.KAINAZZO] = {title = "Kainazzo",               f = _battle_kainazzo, split = true},
	[game.battle.FORMATION.KARATE]   = {title = "Karate",                 f = _battle_karate,   split = true,  full_inventory = true},
	[game.battle.FORMATION.LUGAE1]   = {title = "Dr.Lugae/Balnab",        f = _battle_lugae1,   split = true},
	[game.battle.FORMATION.LUGAE2]   = {title = "Dr.Lugae",               f = _battle_lugae2,   split = true},
	[game.battle.FORMATION.MAGE]     = {title = "Mages",                  f = _battle_mages,    split = false},
	[game.battle.FORMATION.MILON]    = {title = "Milon",                  f = _battle_milon,    split = true},
	[game.battle.FORMATION.MILON_Z]  = {title = "Milon Z.",               f = _battle_milon_z,  split = true},
	[game.battle.FORMATION.MOMBOMB]  = {title = "MomBomb",                f = _battle_mombomb,  split = true,  full_inventory = true},
	[game.battle.FORMATION.OCTOMAMM] = {title = "Octomamm",               f = _battle_octomamm, split = true,  full_inventory = true},
	[game.battle.FORMATION.OFFICER]  = {title = "Officer/Soldiers",       f = _battle_officer,  split = true},
	[game.battle.FORMATION.RED_D_1]  = {title = "Red D. x1",              f = _battle_red_d,    split = false},
	[game.battle.FORMATION.RED_D_2]  = {title = "Red D. x2",              f = _battle_red_d,    split = false},
	[game.battle.FORMATION.RED_D_B]  = {title = "Red D. x1, Behemoth x1", f = _battle_red_d,    split = false},
	[game.battle.FORMATION.RED_D_3]  = {title = "Red D. x3",              f = _battle_red_d,    split = false},
	[game.battle.FORMATION.RUBICANT] = {title = "Rubicant",               f = _battle_rubicant, split = true},
	[game.battle.FORMATION.SISTERS]  = {title = "Magus Sisters",          f = _battle_sisters,  split = true},
	[game.battle.FORMATION.VALVALIS] = {title = "Valvalis",               f = _battle_valvalis, split = true},
	[game.battle.FORMATION.WATERHAG] = {title = "WaterHag",               f = _battle_waterhag, split = true},
	[game.battle.FORMATION.WEEPER]   = {title = "Weeper/WaterHag/Imp",    f = _battle_weeper,   split = false},
	[game.battle.FORMATION.ZEMUS]    = {title = "Zemus",                  f = nil,              split = true},
	[game.battle.FORMATION.ZEROMUS]  = {title = "Zeromus",                f = _battle_zeromus,  split = false},
}

--------------------------------------------------------------------------------
-- Inventory Management
--------------------------------------------------------------------------------

function _manage_inventory(full_inventory, items)
	if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
		return false
	end

	if not items then
		items = {}
	end

	if (full_inventory and memory.read("battle", "active") == 0) or memory.read("battle", "enemies") == 0 then
		local priority_map = {}

		local item_priority = {}
		local empty_count = 48
		local empty_slots = {}

		for i = 0, 47 do
			local item = memory.read("battle_menu", "item_id", i)
			local priority

			if item ~= game.ITEM.NONE then
				local priority = 0

				if items[item] then
					priority = items[item]
				end

				if not priority_map[priority] then
					priority_map[priority] = {
						slots = {},
						count = 0
					}
				end

				item_priority[i] = priority
				table.insert(priority_map[priority].slots, i)
				priority_map[priority].count = priority_map[priority].count + 1
				empty_count = empty_count - 1
			else
				table.insert(empty_slots, i)
			end
		end

		priority_map[7] = { slots = empty_slots, count = math.min(4, empty_count) }
		empty_count = empty_count - priority_map[7].count

		priority_map[3] = { slots = empty_slots, count = math.min(4, empty_count) }
		empty_count = empty_count - priority_map[3].count

		priority_map[1] = { slots = empty_slots, count = empty_count }

		local priority = 0
		local priority_count = 0

		for i = 47, 0, -1 do
			local item = memory.read("battle_menu", "item_id", i)

			if item_priority[i] == priority or ((priority == 1 or priority == 3 or priority == 7) and item == game.ITEM.NONE) then
				priority_count = priority_count + 1

				if priority_count == priority_map[priority].count then
					repeat
						priority = priority + 1
					until (priority_map[priority] and priority_map[priority].count > 0) or priority == 64

					priority_count = 0
				end
			else
				table.sort(priority_map[priority].slots)
				local source = priority_map[priority].slots[1]

				log.log(string.format("Inventory: Swapping slots %d and %d", source, i))

				table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item.select, {nil, source}})
				table.insert(_state.q, {menu.battle.item.select, {nil, i}})
				table.insert(_state.q, {menu.battle.item.close, {}})

				return true
			end
		end

		log.log("Inventory: Couldn't find anything to move")
		_state.disable_inventory = true
	end

	return false
end

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
			_state.strat = sequence.get_battle_strat(index)
			_battle_count = _battle_count + 1

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
				else
					party_text = string.format("%s%s%sempty", party_text, delimiter, front)
				end
			end

			log.log(string.format("Party Formation: %s", party_text))

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
				sequence.split(_state.formation.title .. " (start)")
			end
		end

		if index == game.battle.FORMATION.ZEROMUS and memory.read("battle", "flash") == 3 and not _state.flash_split then
			_state.flash_split = true
			sequence.split("Zeromus Death")

			if CONFIG.EXTENDED_ENDING then
				sequence.end_run(20 * 60 * 60)
			else
				sequence.end_run(65 * 60)
			end
		end

		if formation.f then
			local open = memory.read("battle_menu", "open") > 0
			local slot = memory.read("battle_menu", "slot")

			if slot ~= _state.slot then
				_state.q = {}
				_state.slot = slot
				_state.queued = false
				_state.disable_inventory = nil
				menu.reset()
			elseif not open then
				_state.q = {}
				_state.slot = -1
				_state.queued = false
				_state.disable_inventory = nil
				menu.reset()
			end

			if open and memory.read("battle_menu", "menu") ~= menu.battle.MENU.NONE then
			 	if #_state.q == 0 and not _state.queued then
					if (_state.disable_inventory or not _manage_inventory(formation.full_inventory or _state.full_inventory, route.get_inventory(index))) and not formation.f(game.character.get_character(slot), _state.turns[slot] + 1, _state.strat) then
						_state.turns[slot] = _state.turns[slot] + 1
						_state.queued = true
					end
				end

				if #_state.q > 0 then
					local command = _state.q[1]

					if command then
						if command[1](unpack(command[2])) then
							table.remove(_state.q, 1)
						end
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
				sequence.split(_state.formation.title)
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
	_splits = {}
end

return _M
