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

local input = require "util.input"
local log = require "util.log"
local memory = require "util.memory"
local menu = require "action.menu"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.FORMATION = {
	D_MIST = 222,
}

local _formation_descriptions = {
	[_M.FORMATION.D_MIST] = "D.Mist"
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

local function _command_fight(target)
	table.insert(_state.q, {menu.battle.base_select, {menu.battle.COMMAND.FIGHT}})
	table.insert(_state.q, {menu.battle.target, {target}})
end

local function _command_jump(target)
	table.insert(_state.q, {menu.battle.base_select, {menu.battle.COMMAND.JUMP}})
	table.insert(_state.q, {menu.battle.target, {target}})
end

local function _command_parry()
	table.insert(_state.q, {menu.battle.base_select, {menu.battle.COMMAND.PARRY}})
end

local function _command_wait_frames(frames)
	table.insert(_state.q, {menu.battle.wait_frames, {frames}})
end

local function _command_wait_text(text)
	table.insert(_state.q, {menu.battle.wait_text, {text}})
end

--------------------------------------------------------------------------------
-- Battles
--------------------------------------------------------------------------------

local function _battle_d_mist(character, turn)
	if character == menu.battle.CHARACTER.KAIN then
		if turn == 2 or memory.read("monster", "hp", 0) < 48 then
			_command_fight()
		else
			if turn == 4 then
				-- TODO: Test this delay against audio cue
				_command_wait_frames(330)
			end

			_command_jump()
		end
	elseif character == menu.battle.CHARACTER.CECIL then
		if turn == 5 then
			_command_parry()
		else
			if turn == 6 then
				_command_wait_text("No")
				table.insert(_state.q, {menu.battle.base_select, {menu.battle.COMMAND.ITEM}})
				table.insert(_state.q, {menu.battle.item_select, {menu.battle.ITEM.NONE, 2}})
				table.insert(_state.q, {menu.battle.item_equipment_select, {1}})
				table.insert(_state.q, {menu.battle.wait_frames, {5}})
				table.insert(_state.q, {menu.battle.item_equipment_select, {1}})
				table.insert(_state.q, {menu.battle.item_select, {menu.battle.ITEM.NONE, 1}})
				table.insert(_state.q, {menu.battle.wait_frames, {5}})
				table.insert(_state.q, {menu.battle.item_close, {}})
			end

			_command_fight()
		end
	end
end

local _battle_functions = {
	[_M.FORMATION.D_MIST] = _battle_d_mist
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

			local description = _formation_descriptions[formation]

			if not description then
				description = string.format("Formation #%d", formation)
			end

			log.log(string.format("Beginning Battle: %s", description))
		end

		if battle_function then
			local slot = memory.read("battle_menu", "slot")

			if slot ~= _state.slot then
				_state.q = {}
				_state.slot = slot
				_state.queued = false
			end

			if slot >= 0 and memory.read("battle_menu", "menu") ~= menu.battle.MENU.NONE then
			 	if not _state.queued then
					_state.turns[slot] = _state.turns[slot] + 1
					battle_function(menu.battle.get_character_id(slot), _state.turns[slot])
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
			_reset_state()
		end

		return false
	end
end

function _M.reset()
	_reset_state()
end

return _M
