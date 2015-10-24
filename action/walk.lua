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

local flags = require "util.flags"
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

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.step(direction)
	if flags.is_moving() or not flags.is_ready() then
		return false
	end

	if direction == _M.DIRECTION.UP then
		input.press({"P1 Up"}, input.DELAY.NONE)
	elseif direction == _M.DIRECTION.DOWN then
		input.press({"P1 Down"}, input.DELAY.NONE)
	elseif direction == _M.DIRECTION.LEFT then
		input.press({"P1 Left"}, input.DELAY.NONE)
	else
		input.press({"P1 Right"}, input.DELAY.NONE)
	end

	return true
end

function _M.chase(target_map_id, npcs)
	local current_map_id = memory.read("map", "id")
	local current_x = memory.read("map", "x")
	local current_y = memory.read("map", "y")
	local current_direction = memory.read("map", "direction")

	if flags.is_moving() or not flags.is_ready() then
		return false
	elseif current_map_id ~= target_map_id then
		return false
	end

	local target_npc = -1
	local target_distance = 10000

	for _, i in pairs(npcs) do
		local dx = memory.read("npc", "x", i) - current_x
		local dy = memory.read("npc", "y", i) - current_y

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

			input.press({"P1 A"}, input.DELAY.MASH)
			return true
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

	if math.abs(dx) > math.abs(dy) then
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

function _M.walk(target_map_id, target_x, target_y)
	local current_map_id = memory.read("map", "id")
	local current_x = memory.read("map", "x")
	local current_y = memory.read("map", "y")

	if (not target_map_id or current_map_id == target_map_id) and current_x == target_x and current_y == target_y then
		return true
	elseif target_map_id and current_map_id ~= target_map_id then
		return false
	elseif flags.is_moving() or not flags.is_ready() then
		return false
	end

	local dx = target_x - current_x
	local dy = target_y - current_y

	if dx > 0 then
		input.press({"P1 Right"}, input.DELAY.NONE)
	elseif dx < 0 then
		input.press({"P1 Left"}, input.DELAY.NONE)
	elseif dy > 0 then
		input.press({"P1 Down"}, input.DELAY.NONE)
	elseif dy < 0 then
		input.press({"P1 Up"}, input.DELAY.NONE)
	end

	return false
end

return _M
