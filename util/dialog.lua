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
local memory = require "util.memory"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local _mash_button = "P1 A"

--------------------------------------------------------------------------------
-- Private Functions
--------------------------------------------------------------------------------

local function _is_dialog()
	local battle_dialog_state = memory.read("battle_dialog", "state")
	local dialog_height = memory.read("dialog", "height")
	local dialog_state = memory.read("dialog", "state")
	local dialog_prompt = memory.read("dialog", "prompt")

	return battle_dialog_state == 1 or dialog_height == 7 or (dialog_height > 0 and (dialog_state == 0 or dialog_prompt == 0))
end

--------------------------------------------------------------------------------
-- Public Functions
--------------------------------------------------------------------------------

function _M.cycle()
	if _is_dialog() then
		input.press({_mash_button}, input.DELAY.MASH)

		return true
	end

	return false
end

function _M.reset()
end

function _M.set_mash_button(mash_button)
	_mash_button = mash_button
	return true
end

return _M
