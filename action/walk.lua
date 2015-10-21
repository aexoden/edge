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
-- Private Functions
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.walk(target_map_id, target_x, target_y)
	local current_map_id = memory.read("map", "id")
	local current_x = memory.read("map", "x")
	local current_y = memory.read("map", "y")

	if current_map_id == target_map_id and current_x == target_x and current_y == target_y then
		return true
	elseif current_map_id ~= target_map_id then
		return false
	elseif flags.is_moving() or not flags.is_ready() then
		return false
	end

	local dx = target_x - current_x
	local dy = target_y - current_y

	if dx > 0 then
		input.press({"P1 Right"}, 0)
	elseif dx < 0 then
		input.press({"P1 Left"}, 0)
	elseif dy > 0 then
		input.press({"P1 Down"}, 0)
	elseif dy < 0 then
		input.press({"P1 Up"}, 0)
	end

	return false
end

return _M
