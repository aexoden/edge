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
local game = require "util.game"
local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.FORMATION = {
	D_MIST   = 222,
	OCTOMAMM = 223,
	ANTLION  = 224,
	MOMBOMB  = 225,
	MILON    = 226,
	MILON_Z  = 227,
	GIRL     = 236,
	OFFICER  = 237,
	WATERHAG = 239,
	DRAGOON  = 241,
	D_KNIGHT = 246,
	GENERAL  = 247,
	WEEPER   = 248,
	GARGOYLE = 249,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_state = nil

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

local function _command_aim(target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.AIM}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

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

local function _command_kick(target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.KICK}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_parry()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.PARRY}})
end

local function _command_run_buffer()
	table.insert(_state.q, {menu.battle.run_buffer, {}})
end

local function _command_twin()
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.TWIN}})
	table.insert(_state.q, {menu.battle.target, {menu.battle.TARGET.ENEMY_ALL, nil}})
end

local function _command_use_item(item, target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
	table.insert(_state.q, {menu.battle.item.select, {item}})
	table.insert(_state.q, {menu.battle.item.select, {item}})
	table.insert(_state.q, {menu.battle.target, {target_type, target}})
end

local function _command_use_weapon(character, target_weapon, target_type, target)
	table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})

	local hand, current_weapon = game.character.get_weapon(character)

	if current_weapon ~= target_weapon then
		table.insert(_state.q, {menu.battle.item.select, {target_weapon}})
		table.insert(_state.q, {menu.battle.equip.select, {hand}})
	end

	table.insert(_state.q, {menu.battle.equip.select, {hand, input.DELAY.MASH}})
	table.insert(_state.q, {menu.battle.equip.select, {hand, input.DELAY.MASH}})
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

local function _battle_antlion(character, turn)
	if character == game.CHARACTER.CECIL then
		if game.character.get_stat(game.CHARACTER.RYDIA, "hp") == 0 and game.item.get_index(game.ITEM.ITEM.LIFE, 0, game.INVENTORY.BATTLE) then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, game.CHARACTER.RYDIA)
		else
			_command_parry()
		end
	elseif character == game.CHARACTER.EDWARD then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	elseif character == game.CHARACTER.RYDIA then
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	end
end

local function _battle_d_knight(character, turn)
	if turn == 3 then
		table.insert(_state.q, {menu.battle.command.select, {menu.battle.COMMAND.ITEM}})
		table.insert(_state.q, {menu.battle.item.select, {game.ITEM.SHIELD.PALADIN}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.L_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.equip.select, {game.EQUIP.R_HAND, input.DELAY.MASH}})
		table.insert(_state.q, {menu.battle.target, {}})
	else
		_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
	end
end

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

local function _battle_dragoon(character, turn)
	_command_fight(menu.battle.TARGET.CHARACTER, game.CHARACTER.CECIL)
end

local function _battle_gargoyle(character, turn)
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

local function _battle_general(character, turn)
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

local function _battle_girl(character, turn)
	if character == game.CHARACTER.CECIL then
		_command_wait_frames(300)
		_command_change()
	end
end

local function _battle_milon(character, turn)
	local palom_hp = game.character.get_stat(game.CHARACTER.PALOM, "hp")
	local porom_hp = game.character.get_stat(game.CHARACTER.POROM, "hp")

	local worst_twin = nil

	if palom_hp < 70 and palom_hp < porom_hp then
		worst_twin = {twin = game.CHARACTER.PALOM, hp = palom_hp}
	elseif porom_hp < 70 and porom_hp < palom_hp then
		worst_twin = {twin = game.CHARACTER.POROM, hp = porom_hp}
	end

	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 4)
		elseif turn == 2 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 1)
		elseif worst_twin then
			if worst_twin.hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			end
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.PALOM then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 2)
		elseif worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		end
	elseif character == game.CHARACTER.POROM then
		if worst_twin and worst_twin.hp == 0 then
			_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
		else
			_command_twin()
		end
	elseif character == game.CHARACTER.TELLAH then
		if turn == 1 then
			_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY, 3)
		elseif worst_twin then
			if worst_twin.hp == 0 then
				_command_use_item(game.ITEM.ITEM.LIFE, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			else
				_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.CHARACTER, worst_twin.twin)
			end
		else
			_command_parry()
		end
	end
end

local function _battle_milon_z(character, turn)
	if character == game.CHARACTER.CECIL then
		_command_fight()
	else
		_command_use_item(game.ITEM.ITEM.CURE2, menu.battle.TARGET.ENEMY)
	end
end

local function _battle_mombomb(character, turn)
	if memory.read("enemy", "hp", 0) > 10000 then
		if character == game.CHARACTER.CECIL or character == game.CHARACTER.YANG then
			_command_fight()
		elseif character == game.CHARACTER.EDWARD or character == game.CHARACTER.RYDIA then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING)
		elseif character == game.CHARACTER.ROSA then
			local count = 0, last

			for i = 0, 4 do
				if memory.read("character", "hp", i) < memory.read("character", "hp_max", i) * 0.8 then
					count = count + 1
					last = i
				end
			end

			if count > 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY_ALL)
			elseif count == 1 then
				_command_white(game.MAGIC.WHITE.CURE1, menu.battle.TARGET.PARTY, last)
			else
				_command_parry()
			end
		end
	elseif memory.read("enemy", "hp", 0) > 0 then
		if character == game.CHARACTER.YANG then
			_command_wait_text("Ex")
			_command_wait_frames(60)
			_command_kick()
		else
			_command_parry()
		end
	else
		if character == game.CHARACTER.CECIL then
			_command_fight()
		elseif character == game.CHARACTER.EDWARD or character == game.CHARACTER.RYDIA then
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, game.enemy.get_weakest(game.ENEMY.GRAYBOMB))
		elseif character == game.CHARACTER.ROSA then
			_command_aim(menu.battle.TARGET.ENEMY, game.enemy.get_weakest(game.ENEMY.BOMB))
		elseif character == game.CHARACTER.YANG then
			_command_kick()
		end
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
	if turn <= 3 then
		_command_run_buffer()
		_command_fight()
	end
end

local function _battle_waterhag(character, turn)
	_command_fight()
end

local function _battle_weeper(character, turn)
	if character == game.CHARACTER.CECIL then
		if turn == 1 then
			_command_run_buffer()
			_command_fight(menu.battle.TARGET.ENEMY, 2)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.EDWARD then
		if menu.battle.command.has_command(menu.battle.COMMAND.SHOW) then
			_command_parry()
		elseif turn == 1 then
			_command_run_buffer()
			_command_use_weapon(character, game.ITEM.WEAPON.DANCING, menu.battle.TARGET.ENEMY, 0)
		else
			_command_fight()
		end
	elseif character == game.CHARACTER.YANG then
		_command_fight()
	end
end

local _formations = {
	[_M.FORMATION.ANTLION]  = {title = "Antlion",             f = _battle_antlion,  split = true},
	[_M.FORMATION.D_KNIGHT] = {title = "D.Knight",            f = _battle_d_knight, split = false},
	[_M.FORMATION.D_MIST]   = {title = "D.Mist",              f = _battle_d_mist,   split = true},
	[_M.FORMATION.DRAGOON]  = {title = "Dragoon",             f = _battle_dragoon,  split = true},
	[_M.FORMATION.GARGOYLE] = {title = "Gargoyle",            f = _battle_gargoyle, split = false},
	[_M.FORMATION.GENERAL]  = {title = "General/Fighters",    f = _battle_general,  split = false},
	[_M.FORMATION.GIRL]     = {title = "Girl",                f = _battle_girl,     split = true},
	[_M.FORMATION.MILON]    = {title = "Milon",               f = _battle_milon,    split = true},
	[_M.FORMATION.MILON_Z]  = {title = "Milon Z.",            f = _battle_milon_z,  split = true},
	[_M.FORMATION.MOMBOMB]  = {title = "MomBomb",             f = _battle_mombomb,  split = true},
	[_M.FORMATION.OCTOMAMM] = {title = "Octomamm",            f = _battle_octomamm, split = true},
	[_M.FORMATION.OFFICER]  = {title = "Officer/Soldiers",    f = _battle_officer,  split = true},
	[_M.FORMATION.WATERHAG] = {title = "WaterHag",            f = _battle_waterhag, split = true},
	[_M.FORMATION.WEEPER]   = {title = "Weeper/WaterHag/Imp", f = _battle_weeper,   split = false},
}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if _is_battle() then
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
		end

		if formation.f then
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
					formation.f(game.character.get_character(slot), _state.turns[slot])
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

			local stats = string.format("%d/%d frames/%d GP dropped", _state.index, emu.framecount() - _state.frame, gp)

			log.log(string.format("Battle Complete: %s (%s)", _state.formation.title, stats))

			if _state.formation.split then
				bridge.split(_state.formation.title)
			end

			_reset_state()
		end

		return false
	end
end

function _M.reset()
	_reset_state()
end

return _M
