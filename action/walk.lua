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

local dialog = require "util.dialog"
local input = require "util.input"
local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

_M.DIRECTION = {
	UP = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 3
}

_M.VEHICLE = {
	NONE = 0,
	CHOCOBO = 1,
	BLACK_CHOCOBO = 2,
	HOVERCRAFT = 3,
	ENTERPRISE = 4,
	FALCON = 5,
	BIG_WHALE = 6,
}

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

_state = {}

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.is_mid_tile()
	local frames = 16
	local vehicle = memory.read("walk", "vehicle")

	if vehicle == _M.VEHICLE.CHOCOBO or vehicle == _M.VEHICLE.HOVERCRAFT then
		frames = 8
	elseif vehicle == _M.VEHICLE.BLACK_CHOCOBO then
		frames = 4
	elseif vehicle >= _M.VEHICLE.ENTERPRISE then
		frames = 2
	end

	return memory.read("walk", "frames") % frames ~= 0
end

function _M.is_ready()
	return memory.read("walk", "state") == 0
end

function _M.is_transition()
	local transition = memory.read("walk", "transition")
	return transition ~= 0 and transition ~= 128 and transition ~= 255 and transition ~= 120 and transition ~= 16 and transition ~= 152 and transition ~= 168 and transition ~= 21
end

function _M.step(direction)
	if _state.stepped and memory.read("walk", "direction") == direction then
		_state.stepped = nil
		return true
	elseif _M.is_mid_tile() or not _M.is_ready() then
		return false
	else
		local result

		if direction == _M.DIRECTION.UP then
			result = input.press({"P1 Up"}, input.DELAY.NONE)
		elseif direction == _M.DIRECTION.DOWN then
			result = input.press({"P1 Down"}, input.DELAY.NONE)
		elseif direction == _M.DIRECTION.LEFT then
			result = input.press({"P1 Left"}, input.DELAY.NONE)
		else
			result = input.press({"P1 Right"}, input.DELAY.NONE)
		end

		if result then
			_state.stepped = true
		end
	end

	return false
end

function _M.board()
	if _M.is_mid_tile() or not _M.is_ready() then
		return false
	end

	if not _state.vehicle then
		_state.vehicle = memory.read("walk", "vehicle")
	end

	if memory.read("walk", "vehicle") ~= _state.vehicle or memory.read("walk", "map_id") == 303 then
		_state.vehicle = nil
		return true
	else
		input.press({"P1 A"}, input.DELAY.MASH)
	end

	return false
end

function _M.chase(target_map_id, npcs, shop)
	local current_map_id = memory.read("walk", "map_id")
	local current_x = memory.read("walk", "x")
	local current_y = memory.read("walk", "y")
	local current_direction = memory.read("walk", "direction")

	if memory.read("dialog", "height") > 0 or memory.read("menu", "state") > 0 then
		return true
	end

	if _M.is_mid_tile() or not _M.is_ready() then
		return false
	elseif current_map_id ~= target_map_id then
		return false
	end

	local target_npc = -1
	local target_distance = 10000

	for _, i in pairs(npcs) do
		local dx = memory.read("npc", "x", i) - current_x
		local dy = memory.read("npc", "y", i) - current_y

		if shop then
			dy = dy + 1
		end

		if (dx == 0 and math.abs(dy) == 1) or (dy == 0 and math.abs(dx) == 1) then
			local direction = _M.DIRECTION.UP

			if dx == 0 and dy == -1 then
				direction = _M.DIRECTION.UP
			elseif dx == 0 and dy == 1 then
				direction = _M.DIRECTION.DOWN
			elseif dy == 0 and dx == -1 then
				direction = _M.DIRECTION.LEFT
			else
				direction = _M.DIRECTION.RIGHT
			end

			if current_direction ~= direction then
				_M.step(direction)
				return false
			end

			local result = input.press({"P1 A"}, input.DELAY.MASH)

			return shop and result
		else
			local distance = math.abs(dx) + math.abs(dy)

			if distance < target_distance then
				target_npc = i
				target_distance = distance
			end
		end
	end

	local dx = memory.read("npc", "x", target_npc) - current_x
	local dy = memory.read("npc", "y", target_npc) - current_y

	if shop then
		dy = dy + 1
	end

	if math.abs(dx) >= math.abs(dy) then
		if dx > 0 then
			_M.step(_M.DIRECTION.RIGHT)
		elseif dx < 0 then
			_M.step(_M.DIRECTION.LEFT)
		end
	else
		if dy > 0 then
			_M.step(_M.DIRECTION.DOWN)
		elseif dy < 0 then
			_M.step(_M.DIRECTION.UP)
		end
	end

	return false
end

function _M.interact(dialog_text)
	if dialog_text and dialog.get_text(#dialog_text) == dialog_text then
		return true
	end

	if _M.is_mid_tile() or not _M.is_ready() then
		return false
	end

	local result = input.press({"P1 A"}, input.DELAY.MASH)

	if dialog_text then
		return false
	else
		return result
	end
end

function _M.walk(target_map_id, target_x, target_y, npc_safe)
	local current_map_id = memory.read("walk", "map_id")
	local current_x = memory.read("walk", "x")
	local current_y = memory.read("walk", "y")

	if (not target_map_id or current_map_id == target_map_id) and current_x == target_x and current_y == target_y then
		return true
	elseif target_map_id and current_map_id ~= target_map_id then
		return false
	elseif _M.is_mid_tile() or not _M.is_ready() then
		return false
	end

	local dx = target_x - current_x
	local dy = target_y - current_y
	local map_area = memory.read("walk", "map_area")

	-- The current implementation of this function always moves horizontally
	-- until it is in the same column, and then moves vertically. The NPC safe
	-- walking code exploits this fact.
	if npc_safe then
		for i = 0, memory.read("npc", "count") - 1 do
			local npc_x = memory.read("npc", "x", i)
			local npc_y = memory.read("npc", "y", i)

			local npc_dx = target_x - npc_x
			local npc_dy = target_y - npc_y

			if memory.read("npc", "visible", i) > 0 then
				if npc_y == current_y and ((dx <= 0 and npc_dx <= 0 and npc_dx > dx) or (dx >= 0 and npc_dx >= 0 and npc_dx < dx)) then
					return false
				elseif npc_x == target_x and ((dy <= 0 and npc_dy <= 0 and npc_dy > dy) or (dy >= 0 and npc_dy >= 0 and npc_dy < dy)) then
					return false
				end
			end
		end
	end

	local delta_limit

	if map_area == 0 then
		delta_limit = 128
	elseif map_area == 2 then
		delta_limit = 32
	end

	if delta_limit then
		if math.abs(dx) > delta_limit then
			dx = dx * -1
		end

		if math.abs(dy) > delta_limit then
			dy = dy * -1
		end
	end

	if dx > 0 then
		input.press({"P1 Right"}, input.DELAY.NONE)
	elseif dx ~= 0 then
		input.press({"P1 Left"}, input.DELAY.NONE)
	elseif dy > 0 or (map_area == 0 and dy < -128) or (map_area == 2 and dy < -32) then
		input.press({"P1 Down"}, input.DELAY.NONE)
	elseif dy ~= 0 then
		input.press({"P1 Up"}, input.DELAY.NONE)
	end

	return false
end

function _M.reset()
	_state = {}
end

return _M
