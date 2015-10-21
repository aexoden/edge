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
local memory = require "util.memory"
local menu = require "action.menu"
local walk = require "action.walk"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _q = {}

--------------------------------------------------------------------------------
-- Sequences
--------------------------------------------------------------------------------

local function _sequence_introduction()
	table.insert(_q, {menu.open, {}})
	table.insert(_q, {menu.close, {}})
	table.insert(_q, {walk.walk, {43, 14, 9}})
	table.insert(_q, {walk.walk, {42, 8, 10}})
	table.insert(_q, {walk.walk, {42, 14, 10}})
	table.insert(_q, {walk.walk, {42, 14, 8}})
	table.insert(_q, {walk.walk, {42, 13, 8}})
end

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _check_sequence()
	if #_q == 0 and flags.is_ready() and not flags.is_moving() then
		local map_id = memory.read("map", "id")
		local map_x = memory.read("map", "x")
		local map_y = memory.read("map", "y")

		if map_id == 43 and map_x == 14 and map_y == 5 then
			print("introduction")
			_sequence_introduction()
		end
	end
end

local function _execute_next_command()
	local command = _q[1]

	if command then
		if command[1](unpack(command[2])) then
			table.remove(_q, 1)
		end
	end
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	_check_sequence()
	_execute_next_command()
end

return _M
