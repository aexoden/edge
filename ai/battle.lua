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

local game = require "util.game"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.FORMATION = {
	D_MIST = 222,
	OCTOMAMM = 223,
	GIRL = 236,
	OFFICER = 237,
}

local _formation_descriptions = {
	[_M.FORMATION.D_MIST] = "D.Mist",
	[_M.FORMATION.GIRL] = "Girl",
	[_M.FORMATION.OCTOMAMM] = "Octomamm",
	[_M.FORMATION.OFFICER] = "Officer and Soldiers",
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_state = nil

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _get_formation_description(formation)
	local description = _formation_descriptions[formation]

	if not description then
		description = string.format("Formation #%d", formation)
	end

	return description
end

local function _is_battle()
	return memory.read("battle", "state") > 0
end

local function _reset_state()
	_state = {
		frame = nil,
		formation = nil,
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

local function _command_magic(type, spell, target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {type}})
	table.insert(_state.q, {menu.battle.magic.select, {spell}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_black(spell, target_type, target)
	_command_magic(menu.battle.COMMAND.BLACK, spell, target_type, target)
end

local function _command_white(spell, target_type, target)
	_command_magic(menu.battle.COMMAND.WHITE, spell, target_type, target)
end

local function _command_change()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.CHANGE}})
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
	local hand, current_weapon = game.character.get_weapon(character)

	if current_weapon ~= target_weapon then
		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
		table.insert(_state.q, {menu.battle.item.select, {target_weapon}})
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
		table.insert(_state.q, {menu.battle.item.close, {}})
	end
end

local function _command_fight(target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.FIGHT}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_jump(target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.JUMP}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_parry()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.PARRY}})
end

local function _command_run_buffer()
	table.insert(_state.q, {menu.battle.run_buffer, {}})
end

local function _command_use_weapon(character, target_weapon, target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})

	local hand, current_weapon = game.character.get_weapon(character)

	if current_weapon ~= target_weapon then
		table.insert(_state.q, {menu.battle.item.select, {target_weapon}})
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
	end

	table.insert(_state.q, {menu.battle.equip.select, {hand}})
	table.insert(_state.q, {menu.battle.equip.select, {hand}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_wait_frames(frames)
	table.insert(_state.q, {menu.wait, {frames}})
end

local function _command_wait_text(text)
	table.insert(_state.q, {menu.battle.dialog.wait, {text}})
end

--------------------------------------------------------------------------------
-- Battles
--------------------------------------------------------------------------------

local function _battle_d_mist(character, turn)
	if character == game.CHARACTER.KAIN then
		if turn == 2 or game.enemy.get_stat(0, "hp") < 48 then
			_command_fight()
		else
			if turn == 4 then
				-- TODO: Test this delay against audio cue
				_command_wait_frames(330)
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

local function _battle_girl(character, turn)
	if character == game.CHARACTER.CECIL then
		_command_wait_frames(300)
		_command_change()
	end
end

local function _battle_octomamm(character, turn)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_equip(character, game.ITEM.WEAPON.DARKNESS)
		end

		_command_fight()
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
			_command_equip(character, game.ITEM.WEAPON.CHANGE)
		end

		local rydia_hp = game.character.get_stat(game.CHARACTER.RYDIA, "hp")

		if rydia_hp == 0 then
			_command_white(game.MAGIC.WHITE.LIFE1, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		elseif rydia_hp < 15 or game.character.get_stat(game.CHARACTER.CECIL, "hp") < 100 then
			_command_white(game.MAGIC.WHITE.CURE2, menu.battle.TARGET.PARTY_ALL)
		elseif game.enemy.get_stat(0, "hp") < 1200 then
			if not _state.duplicated_change then
				_state.duplicated_change = true

				_command_duplicate(game.EQUIP.R_HAND)
				_command_black(game.MAGIC.BLACK.STOP, menu.battle.TARGET.CHARACTER, game.CHARACTER.TELLAH)
			else
				_command_parry()
			end
		else
			_command_black(game.MAGIC.BLACK.LIT1)
		end
	end
end

local function _battle_officer(character, turn)
	-- TODO: Don't attack the Officer.
	_command_run_buffer()
	_command_fight()
end

local _battle_functions = {
	[_M.FORMATION.D_MIST] = _battle_d_mist,
	[_M.FORMATION.GIRL] = _battle_girl,
	[_M.FORMATION.OCTOMAMM] = _battle_octomamm,
	[_M.FORMATION.OFFICER] = _battle_officer,
}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if _is_battle() then
		local formation = memory.read("battle", "formation")
		local battle_function = _battle_functions[formation]

		if formation ~= _state.formation then
			_reset_state()
			_state.formation = formation
			_state.frame = emu.framecount()

			local attack_type = "Normal"
			local attack_value = memory.read("battle", "type")

			if attack_value == 1 then
				attack_type = "Strike First"
			elseif attack_value == 128 then
				if memory.read("battle", "back") == 8 then
					attack_type = "Back Attack"
				else
					attack_type = "Surprised"
				end
			end

			local party_level = memory.read("battle", "party_level")
			local stats

			if party_level > 0 then
				stats = string.format("%s/%s/%s", attack_type, memory.read("battle", "party_level"), memory.read("battle", "enemy_level"))
			else
				stats = attack_type
			end

			log.log(string.format("Beginning Battle: %s (%s)", _get_formation_description(formation), stats))
		end

		if battle_function then
			local open = memory.read("battle_menu", "open") > 0
			local slot = memory.read("battle_menu", "slot")

			if slot ~= _state.slot then
				_state.q = {}
				_state.slot = slot
				_state.queued = false
			elseif not open then
				_state.q = {}
				_state.slot = -1
				_state.queued = false
			end

			if open and memory.read("battle_menu", "menu") ~= menu.battle.MENU.NONE then
			 	if not _state.queued then
					_state.turns[slot] = _state.turns[slot] + 1
					battle_function(game.character.get_character(slot), _state.turns[slot])
					_state.queued = true
				elseif #_state.q > 0 then
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
	else
		if _state.formation then
			local gp = 0

			if memory.read("battle", "ending") == 64 then
				gp = memory.read("battle", "dropped_gp")
			end

			log.log(string.format("Ending Battle: %s (%d frames) (dropped %d GP)", _get_formation_description(_state.formation), emu.framecount() - _state.frame, gp))
			_reset_state()
		end

		return false
	end
end

function _M.reset()
	_reset_state()
end

return _M
